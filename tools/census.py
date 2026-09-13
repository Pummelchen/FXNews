#!/usr/bin/env python3.14
"""Dead-code and placeholder census for FXNews.mq5.

The MQL5 compiler warns only about a variable that is never touched at all, so
"0 errors, 0 warnings" says nothing about code that is written and never read.
This script performs the census that the wiki's Testing-and-Validation page
describes, deterministically:

  1. functions that are declared but never called
  2. inputs, #defines, globals and enum members that are never referenced
  3. struct fields that are written but never read
  4. locals that are assigned and never read
  5. function parameters that are never used
  6. placeholder literals in user-facing format slots

Usage:
    tools/census.py [path/to/FXNews.mq5] [--allow tools/census-allow.txt] [--json]

Exit status is 0 when the census is clean, 1 when it finds something, 2 on a
usage error. Entries in the allow file (one identifier per line, '#' comments)
are reported as "allowed" and do not affect the exit status.

Requires Python 3.14 or later.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections.abc import Iterable
from dataclasses import dataclass, field
from pathlib import Path

MIN_PYTHON = (3, 14)
if sys.version_info < MIN_PYTHON:
    sys.exit(f"census: Python {MIN_PYTHON[0]}.{MIN_PYTHON[1]}+ required, "
             f"found {sys.version.split()[0]}")

# Event handlers the terminal calls; they never have an in-source call site.
ENTRY_POINTS = frozenset({"OnInit", "OnDeinit", "OnTimer", "OnCalculate",
                          "OnChartEvent", "OnTick", "OnStart"})

TYPE_WORDS = (r"(?:const\s+)?(?:static\s+)?"
              r"(?:void|int|uint|long|ulong|short|ushort|char|uchar|bool|double|"
              r"float|string|datetime|color|MqlRates|MqlTick|ENUM_[A-Za-z_]+|"
              r"[A-Z][A-Za-z0-9_]*)")
IDENT = r"[A-Za-z_][A-Za-z0-9_]*"

FUNC_DEF_RE = re.compile(rf"^(?P<type>{TYPE_WORDS})\s+(?P<name>{IDENT})\s*\((?P<params>[^)]*)\)\s*$",
                         re.MULTILINE)
INPUT_RE = re.compile(rf"^(?:input|sinput)\s+{TYPE_WORDS}\s+(?P<name>{IDENT})\s*=", re.MULTILINE)
DEFINE_RE = re.compile(rf"^#define\s+(?P<name>{IDENT})\b", re.MULTILINE)
GLOBAL_RE = re.compile(rf"^(?P<type>{TYPE_WORDS})\s+(?P<name>g_{IDENT})\s*(?:\[[^\]]*\])?\s*(?:=|;)",
                       re.MULTILINE)
STRUCT_RE = re.compile(rf"^struct\s+(?P<name>{IDENT})\s*\{{(?P<body>.*?)^\}};", re.MULTILINE | re.DOTALL)
ENUM_RE = re.compile(rf"^enum\s+(?P<name>{IDENT})\s*\{{(?P<body>.*?)^\}};", re.MULTILINE | re.DOTALL)
FIELD_RE = re.compile(rf"^\s*{TYPE_WORDS}\s+(?P<name>{IDENT})\s*(?:\[[^\]]*\])?\s*;", re.MULTILINE)
ENUM_MEMBER_RE = re.compile(rf"^\s*(?P<name>{IDENT})\s*(?:=\s*-?\d+)?\s*,?\s*$", re.MULTILINE)
LOCAL_DECL_RE = re.compile(rf"(?:^|[;{{}}]|\)\s*)\s*(?:const\s+)?(?:static\s+)?"
                           rf"(?:int|uint|long|ulong|bool|double|string|datetime|color|"
                           rf"MqlRates|MqlTick|ENUM_[A-Za-z_]+|[A-Z][A-Za-z0-9_]*)\s+"
                           rf"(?P<name>{IDENT})\s*(?:\[[^\]]*\])?\s*(?:=|;)", re.MULTILINE)
# `x = ...`, `x += ...` and a statement-level `x++;` are writes; `x++` used
# inside an expression (for example `x++ % stride`) also reads the value.
WRITE_AFTER_RE = re.compile(r"\s*(?:=(?!=)|\+=|-=|\*=|/=|(?:\+\+|--)\s*;)")
PLACEHOLDER_PATTERNS = (
    re.compile(r"\b(?:RAW|TBD|TODO|FIXME|XXX)\b"),
    re.compile(r"\b(?:n/a|lorem|placeholder|dummy|stub|not implemented)\b", re.IGNORECASE),
    re.compile(r"\?\?\?"),
)


@dataclass(slots=True)
class Finding:
    category: str
    identifier: str
    line: int
    detail: str
    allowed: bool = False

    def as_text(self) -> str:
        marker = "allowed" if self.allowed else "FINDING"
        return f"[{marker}] {self.category}: {self.identifier} (line {self.line}) - {self.detail}"


@dataclass(slots=True)
class Function:
    name: str
    line: int
    params: list[str]
    body: str
    body_offset: int


@dataclass(slots=True)
class Source:
    raw: str
    code: str                      # comments and string literals blanked
    strings: list[tuple[int, str]] = field(default_factory=list)

    def line_of(self, offset: int) -> int:
        return self.raw.count("\n", 0, offset) + 1


def blank_comments_and_strings(raw: str) -> tuple[str, list[tuple[int, str]]]:
    """Replace comments with spaces and string bodies with spaces, keeping
    offsets identical so line numbers survive. Returns the blanked text and
    the list of (offset, literal) string literals found."""
    out = list(raw)
    strings: list[tuple[int, str]] = []
    i, n = 0, len(raw)
    while i < n:
        ch = raw[i]
        nxt = raw[i + 1] if i + 1 < n else ""
        if ch == "/" and nxt == "/":
            j = raw.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
        elif ch == "/" and nxt == "*":
            j = raw.find("*/", i + 2)
            j = n if j < 0 else j + 2
            for k in range(i, j):
                if out[k] != "\n":
                    out[k] = " "
            i = j
        elif ch == '"':
            j = i + 1
            while j < n and raw[j] != '"':
                j += 2 if raw[j] == "\\" else 1
            literal = raw[i + 1:j]
            strings.append((i, literal))
            for k in range(i + 1, min(j, n)):
                out[k] = " "
            i = j + 1
        else:
            i += 1
    return "".join(out), strings


def load(path: Path) -> Source:
    raw = path.read_text(encoding="utf-8")
    code, strings = blank_comments_and_strings(raw)
    return Source(raw=raw, code=code, strings=strings)


def find_functions(src: Source) -> list[Function]:
    functions: list[Function] = []
    for match in FUNC_DEF_RE.finditer(src.code):
        name = match.group("name")
        if name in {"if", "for", "while", "switch", "return"}:
            continue
        # The opening brace is the next non-space character after the signature.
        brace = src.code.find("{", match.end())
        if brace < 0:
            continue
        between = src.code[match.end():brace]
        if between.strip():
            continue
        depth, j = 0, brace
        while j < len(src.code):
            c = src.code[j]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        body = src.code[brace + 1:j]
        params: list[str] = []
        for chunk in match.group("params").split(","):
            chunk = chunk.strip()
            if not chunk:
                continue
            ident = re.search(rf"&?\s*({IDENT})\s*(?:\[\s*\])?\s*$", chunk)
            if ident:
                params.append(ident.group(1))
        functions.append(Function(name=name, line=src.line_of(match.start()),
                                  params=params, body=body, body_offset=brace + 1))
    return functions


def count_word(text: str, word: str) -> int:
    return len(re.findall(rf"\b{re.escape(word)}\b", text))


def classify_field_uses(code: str, name: str) -> tuple[int, int]:
    """Count writes and reads of `.name` across the code."""
    writes = reads = 0
    for match in re.finditer(rf"\.{re.escape(name)}\b", code):
        tail = code[match.end():match.end() + 4]
        if WRITE_AFTER_RE.match(tail):
            writes += 1
        else:
            reads += 1
    return writes, reads


def census(src: Source, allow: set[str]) -> list[Finding]:
    findings: list[Finding] = []
    code = src.code

    def add(category: str, identifier: str, line: int, detail: str) -> None:
        findings.append(Finding(category, identifier, line, detail, identifier in allow))

    functions = find_functions(src)
    names = {f.name for f in functions}

    # 1. uncalled functions
    for fn in functions:
        if fn.name in ENTRY_POINTS:
            continue
        calls = len(re.findall(rf"\b{re.escape(fn.name)}\s*\(", code))
        if calls <= 1:  # the definition itself
            add("uncalled-function", fn.name, fn.line, "declared but never called")

    # 2. unreferenced inputs, defines, globals, enum members
    for regex, category in ((INPUT_RE, "unused-input"), (DEFINE_RE, "unused-define"),
                            (GLOBAL_RE, "unused-global")):
        for match in regex.finditer(code):
            name = match.group("name")
            if count_word(code, name) <= 1:
                add(category, name, src.line_of(match.start()), "declared but never referenced")
    for enum in ENUM_RE.finditer(code):
        for member in ENUM_MEMBER_RE.finditer(enum.group("body")):
            name = member.group("name")
            if count_word(code, name) <= 1:
                add("unused-enum-member", name, src.line_of(enum.start() + member.start()),
                    f"member of {enum.group('name')} never referenced")

    # 3. struct fields written but never read
    seen_fields: dict[str, list[str]] = {}
    for struct in STRUCT_RE.finditer(code):
        for fld in FIELD_RE.finditer(struct.group("body")):
            seen_fields.setdefault(fld.group("name"), []).append(struct.group("name"))
    for struct in STRUCT_RE.finditer(code):
        for fld in FIELD_RE.finditer(struct.group("body")):
            name = fld.group("name")
            writes, reads = classify_field_uses(code, name)
            line = src.line_of(struct.start() + fld.start())
            owners = seen_fields[name]
            shared = f" (name shared by {len(owners)} structs: counted together)" if len(owners) > 1 else ""
            if writes == 0 and reads == 0:
                add("unused-field", f"{struct.group('name')}.{name}", line, "never accessed" + shared)
            elif reads == 0:
                add("write-only-field", f"{struct.group('name')}.{name}", line,
                    f"{writes} writes, 0 reads" + shared)

    # 4. locals assigned and never read, 5. unused parameters
    for fn in functions:
        body = fn.body
        for param in fn.params:
            if fn.name in ENTRY_POINTS:
                break  # the terminal fixes these signatures
            if count_word(body, param) == 0:
                add("unused-parameter", f"{fn.name}({param})", fn.line, "parameter never used")
        declared: dict[str, int] = {}
        for match in LOCAL_DECL_RE.finditer(body):
            name = match.group("name")
            if name in names or name in declared:
                continue
            declared[name] = src.line_of(fn.body_offset + match.start("name"))
        for name, line in declared.items():
            uses = list(re.finditer(rf"\b{re.escape(name)}\b", body))
            reads = 0
            for use in uses:
                tail = body[use.end():use.end() + 4]
                head = body[max(0, use.start() - 40):use.start()]
                is_decl = bool(re.search(rf"(?:\b(?:int|uint|long|ulong|bool|double|string|datetime|color|"
                                         rf"MqlRates|MqlTick|ENUM_[A-Za-z_]+|[A-Z][A-Za-z0-9_]*)\s+)$", head))
                if WRITE_AFTER_RE.match(tail) or is_decl:
                    # `x = expr` and the declaration are writes; but `x[i] = ...`
                    # is caught as a read of x below because tail starts with '['.
                    continue
                reads += 1
            if reads == 0:
                add("write-only-local", f"{fn.name}::{name}", line, "assigned but never read")

    # 6. placeholder literals in user-facing strings
    for offset, literal in src.strings:
        for pattern in PLACEHOLDER_PATTERNS:
            hit = pattern.search(literal)
            if hit:
                add("placeholder-literal", repr(literal[:40]), src.line_of(offset),
                    f"contains placeholder token {hit.group(0)!r}")
                break
    # constant string arguments handed to StringFormat slots (a facade column)
    for match in re.finditer(r"StringFormat\s*\(", code):
        depth, j = 1, match.end()
        while j < len(code) and depth:
            depth += {"(": 1, ")": -1}.get(code[j], 0)
            j += 1
        args_code = code[match.end():j - 1]
        args_raw = src.raw[match.end():j - 1]
        parts, depth, start = [], 0, 0
        for k, c in enumerate(args_code):
            depth += {"(": 1, ")": -1, "[": 1, "]": -1}.get(c, 0)
            if c == "," and depth == 0:
                parts.append(args_raw[start:k].strip())
                start = k + 1
        parts.append(args_raw[start:].strip())
        for arg in parts[1:]:
            if re.fullmatch(r'"[^"]*"', arg):
                add("constant-format-argument", arg, src.line_of(match.start()),
                    "string literal passed into a StringFormat slot")

    findings.sort(key=lambda f: (f.allowed, f.category, f.line))
    return findings


def read_allow(path: Path | None) -> set[str]:
    if path is None or not path.exists():
        return set()
    entries: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            entries.add(line)
    return entries


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("source", nargs="?", default=None, help="path to FXNews.mq5")
    parser.add_argument("--allow", type=Path, default=None, help="allow-list file")
    parser.add_argument("--json", action="store_true", help="emit JSON instead of text")
    args = parser.parse_args(list(argv) if argv is not None else None)

    here = Path(__file__).resolve().parent
    source = Path(args.source) if args.source else here.parent / "FXNews.mq5"
    if not source.is_file():
        print(f"census: no such source file: {source}", file=sys.stderr)
        return 2
    allow_path = args.allow if args.allow else here / "census-allow.txt"
    allow = read_allow(allow_path)

    findings = census(load(source), allow)
    open_findings = [f for f in findings if not f.allowed]

    if args.json:
        print(json.dumps([f.__dict__ for f in findings], indent=2))
    else:
        for finding in findings:
            print(finding.as_text())
        print(f"census: {len(open_findings)} open finding(s), "
              f"{len(findings) - len(open_findings)} allowed, source {source.name}")
    return 1 if open_findings else 0


if __name__ == "__main__":
    sys.exit(main())
