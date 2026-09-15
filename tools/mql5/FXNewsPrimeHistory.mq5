//+------------------------------------------------------------------+
//| FXNewsPrimeHistory.mq5                                           |
//|                                                                  |
//| Populates M1 history for the symbols the historical modes        |
//| evaluate, then exits. Run it once before a VALIDATION or         |
//| AUTOTUNE pass whose symbols the terminal has not loaded yet.     |
//|                                                                  |
//| STATUS: it does NOT fix the chart-symbol problem. Measured: it  |
//| requested all 7 majors over 400 days and got every one of them   |
//| back (408 000 bars each, waited 0 s), and the validation run on   |
//| an M5 chart still skipped the chart symbol afterwards. What fixed |
//| that was the chart TIMEFRAME - see tools/selftest-macos.sh. This  |
//| script is kept because it is a working way to ask the terminal    |
//| for a symbol's history and to see what it actually holds, which   |
//| is what established the cause below.                              |
//|                                                                  |
//| Why the chart symbol fails (F-054, measured 2026-09-16):          |
//|   CopyRates(symbol, PERIOD_M1, from_time, to_time, rates) returns |
//|   0 with ERR_HISTORY_NOT_FOUND (4401) for WHICHEVER SYMBOL THE    |
//|   CHART IS ON, while every other symbol loads normally. With the  |
//|   chart on GBPUSD, EURUSD loaded 91 858 bars and GBPUSD failed;   |
//|   with the chart on a symbol outside the list, both loaded. The   |
//|   terminal holds no M1 series for the chart symbol and refuses a  |
//|   large first request for it, so it must be primed from a chart   |
//|   of another symbol.                                              |
//|                                                                  |
//| This is why the primer must run on a chart whose symbol is NOT in |
//| the list: a primer on EURUSD cannot fetch EURUSD.                 |
//|                                                                  |
//| It reuses no product code and writes no files; it only calls      |
//| SymbolSelect and CopyRates and prints what it got.               |
//+------------------------------------------------------------------+
#property script_show_inputs
#property strict
#property version "1.000"

input string PrimeSymbols   = "EURUSD,GBPUSD,USDJPY,USDCHF,USDCAD,AUDUSD,NZDUSD";
input int    PrimeDays      = 3000;   // calendar days back from now
input int    WaitSeconds    = 240;    // per symbol, for the on-demand download

// Splits a comma-separated list, trimming spaces and dropping empty tokens.
int SplitSymbolList(const string list, string &out[])
{
   ArrayResize(out, 0);
   string remaining = list;
   StringTrimLeft(remaining);
   StringTrimRight(remaining);
   while(StringLen(remaining) > 0)
   {
      int comma = StringFind(remaining, ",");
      string token = (comma < 0 ? remaining : StringSubstr(remaining, 0, comma));
      StringTrimLeft(token);
      StringTrimRight(token);
      if(StringLen(token) > 0)
      {
         int next = ArraySize(out);
         if(ArrayResize(out, next + 1) != next + 1)
            return ArraySize(out);
         out[next] = token;
      }
      if(comma < 0)
         break;
      remaining = StringSubstr(remaining, comma + 1);
      StringTrimLeft(remaining);
   }
   return ArraySize(out);
}

void OnStart()
{
   string symbols[];
   int count = SplitSymbolList(PrimeSymbols, symbols);
   if(count <= 0)
   {
      PrintFormat("FXNEWS_PRIME: no symbols in the input list");
      return;
   }

   PrintFormat("FXNEWS_PRIME: priming %d symbols over %d days, chart symbol is %s",
               count, PrimeDays, _Symbol);

   int ok = 0;
   int failed = 0;
   for(int i = 0; i < count; i++)
   {
      string symbol = symbols[i];
      ResetLastError();
      if(!SymbolSelect(symbol, true))
      {
         PrintFormat("FXNEWS_PRIME %s: SymbolSelect failed, error %d", symbol, GetLastError());
         failed++;
         continue;
      }

      datetime to_time = TimeCurrent();
      datetime from_time = to_time - (datetime)PrimeDays * 86400;
      MqlRates rates[];
      ArraySetAsSeries(rates, false);

      uint started = GetTickCount();
      int copied = 0;
      for(;;)
      {
         ResetLastError();
         copied = CopyRates(symbol, PERIOD_M1, from_time, to_time, rates);
         if(copied > 0)
            break;
         if(IsStopped())
         {
            PrintFormat("FXNEWS_PRIME: stopped by the terminal");
            return;
         }
         if((int)((GetTickCount() - started) / 1000) >= WaitSeconds)
            break;
         Sleep(500);
      }

      int waited = (int)((GetTickCount() - started) / 1000);
      if(copied > 0)
      {
         ok++;
         PrintFormat("FXNEWS_PRIME %s: %d M1 bars, %s -> %s, waited %d s",
                     symbol, copied, TimeToString(rates[0].time),
                     TimeToString(rates[copied - 1].time), waited);
      }
      else
      {
         failed++;
         PrintFormat("FXNEWS_PRIME %s: no M1 bars after %d s (error %d) - the broker may not offer this range",
                     symbol, waited, GetLastError());
      }
   }

   PrintFormat("FXNEWS_PRIME: done, %d primed, %d failed - the historical modes can be run now",
               ok, failed);
}
//+------------------------------------------------------------------+
