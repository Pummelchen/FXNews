// FXNewsSelfTest - harness script that attaches FXNews to the current chart in
// a non-scanning mode (SELFTEST by default, or VALIDATION / AUTOTUNE over a
// small basket), waits for the verdict label, prints it to the Journal and
// removes the indicator again. Driven by tools/selftest-macos.sh; it is not a
// product component and is never distributed with the indicator.
//
// The indicator is loaded from MQL5/Indicators/FXNews-selftest/FXNews.ex5 so a
// harness build never overwrites the copy the terminal uses for live charts.
#property strict
#property version   "1.100"
#property description "Runs the FXNews self-test or a short historical run headlessly and reports to the Journal."

#define HARNESS_INDICATOR_PATH "FXNews-selftest\\FXNews"
#define HARNESS_POLL_MS 500

// FXNewsOperatingMode values: 1 VALIDATION, 2 AUTOTUNE, 3 SELFTEST.
input int HarnessMode = 3;
input string HarnessSymbols = "";      // empty: the indicator's default basket
input string HarnessTimeframes = "";   // empty: the indicator's default list
input int HarnessTimeoutSeconds = 90;

string FindVerdictLabel()
{
   const int total = ObjectsTotal(0, 0, OBJ_LABEL);
   for(int i = 0; i < total; i++)
   {
      const string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, "COBR_") != 0)
         continue;
      const string text = ObjectGetString(0, name, OBJPROP_TEXT);
      // The report header reads "... | waiting" or "... | running" until done.
      if(StringFind(text, "SELFTEST PASSED") >= 0 || StringFind(text, "SELFTEST FAILED") >= 0 ||
         StringFind(text, "VALIDATION ready") >= 0 || StringFind(text, "AUTOTUNE ready") >= 0 ||
         StringFind(text, "ABORTED") >= 0)
      {
         return text;
      }
   }
   return "";
}

void RemoveIndicators(const string short_name_fragment)
{
   const int total = ChartIndicatorsTotal(0, 0);
   for(int i = total - 1; i >= 0; i--)
   {
      const string name = ChartIndicatorName(0, 0, i);
      if(StringFind(name, short_name_fragment) >= 0)
         ChartIndicatorDelete(0, 0, name);
   }
}

void OnStart()
{
   ResetLastError();
   int handle = INVALID_HANDLE;
   if(HarnessSymbols == "" && HarnessTimeframes == "")
      handle = iCustom(_Symbol, _Period, HARNESS_INDICATOR_PATH, HarnessMode);
   else
      handle = iCustom(_Symbol, _Period, HARNESS_INDICATOR_PATH, HarnessMode, HarnessSymbols, HarnessTimeframes);
   if(handle == INVALID_HANDLE)
   {
      PrintFormat("FXNEWS_HARNESS: iCustom failed, error %d", GetLastError());
      return;
   }
   if(!ChartIndicatorAdd(0, 0, handle))
   {
      PrintFormat("FXNEWS_HARNESS: ChartIndicatorAdd failed, error %d", GetLastError());
      IndicatorRelease(handle);
      return;
   }

   string verdict = "";
   const int timeout_ms = HarnessTimeoutSeconds * 1000;
   for(int waited = 0; waited < timeout_ms && !IsStopped(); waited += HARNESS_POLL_MS)
   {
      Sleep(HARNESS_POLL_MS);
      verdict = FindVerdictLabel();
      if(verdict != "")
         break;
   }

   PrintFormat("FXNEWS_HARNESS: %s", (verdict == "" ? "TIMEOUT waiting for the verdict" : verdict));
   RemoveIndicators("FXNews");
   IndicatorRelease(handle);
}
