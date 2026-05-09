#property strict
#property description "Chart-only multi-symbol breakout radar. No trade execution."

input string SymbolsToScan =
"EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,NZDUSD,USDCAD,EURJPY,GBPJPY,EURGBP,EURAUD,EURNZD,EURCAD,EURCHF,GBPAUD,GBPNZD,GBPCAD,GBPCHF,AUDJPY,NZDJPY,CADJPY,CHFJPY,AUDNZD,AUDCAD,AUDCHF,NZDCAD,NZDCHF,CADCHF";

input int ScanIntervalSeconds = 1;
input int DisplayUpdateSeconds = 5;
input double MinDisplayConfidence = 60.0;
input double StrongAlertConfidence = 70.0;

input int RangeLookbackM1 = 30;
input int ATRPeriod = 14;
input double BreakoutBufferATR = 0.10;
input double MinBreakoutBufferPips = 1.0;

input double MaxSpreadPips = 5.0;
input double MaxSpreadMedianMultiplier = 2.5;

input bool UseTechnicalBreakoutEngine = true;
input bool UseImpulseBreakoutEngine = true;
input bool UseCurrencyStrength = true;

input int FailedSignalCooldownSeconds = 120;
input int ValidSignalCooldownSeconds = 180;

input bool IgnoreRolloverTime = true;
input int RolloverStartHourServer = 23;
input int RolloverEndHourServer = 1;

input bool EnableSoundAlert = false;
input bool EnablePushNotification = false;

input int MaxQuoteAgeSeconds = 15;

#define DIR_NONE 0
#define DIR_UP 1
#define DIR_DOWN -1
#define SNAPSHOT_CAPACITY 90
#define SPREAD_HISTORY_CAPACITY 80
#define CURRENCY_COUNT 8
#define DASHBOARD_MAX_OBJECTS 40
#define SIGNAL_HISTORY_SIZE 5

enum BreakoutEventState
{
   STATE_IDLE = 0,
   STATE_WATCH = 1,
   STATE_CANDIDATE = 2,
   STATE_ACTIVE_SIGNAL = 3,
   STATE_COOLDOWN = 4
};

struct PriceSnapshot
{
   long time_msc;
   double mid;
};

struct SignalHistoryEntry
{
   bool used;
   string symbol;
   int direction;
   datetime local_time;
   double score;
   string text;
};

struct SymbolProfile
{
   string symbol;
   bool valid;
   bool selected;
   int base_index;
   int quote_index;

   int digits;
   double point;
   double pip_size;

   bool quote_fresh;
   datetime quote_time;
   long quote_time_msc;
   double bid;
   double ask;
   double mid;
   double last_mid;
   double spread_pips;
   double median_spread_pips;

   bool has_m1;
   bool has_m5;
   bool has_m15;
   double atr_m1;
   double atr_m5;
   double range_high;
   double range_low;
   double range_width;

   double current_m1_open;
   double current_m1_high;
   double current_m1_low;
   double current_m1_close;
   double current_m1_tick_volume;
   double last_completed_m1_tick_volume;
   double average_m1_tick_volume;

   double speed_5s_pips;
   double speed_10s_pips;
   double speed_30s_pips;
   double speed_60s_pips;
   double movement_5m_pips;
   double movement_15m_pips;
   double m5_move_atr;
   double m15_move_atr;

   double technical_score_up;
   double technical_score_down;
   double impulse_score_up;
   double impulse_score_down;
   double final_score_up;
   double final_score_down;

   int active_direction;
   BreakoutEventState event_state;
   datetime event_start_time;
   datetime event_local_time;
   datetime last_display_update_time;
   datetime cooldown_end_up;
   datetime cooldown_end_down;
   datetime last_alert_sent_time;
   bool strong_alert_sent;
   bool active_displayed;
   datetime confidence_below_since;
   int candidate_direction;
   datetime candidate_start_time;

   datetime outside_since_up;
   datetime outside_since_down;

   int snapshot_write_index;
   int snapshot_count;
   int spread_write_index;
   int spread_count;

   string status_message;
};

SymbolProfile g_profiles[];
PriceSnapshot g_snapshots[];
double g_spread_history[];
SignalHistoryEntry g_signal_history[SIGNAL_HISTORY_SIZE];
int g_signal_history_count = 0;
double g_currency_strength[CURRENCY_COUNT];
int g_currency_samples[CURRENCY_COUNT];
string g_currency_codes[CURRENCY_COUNT] = {"EUR","USD","GBP","JPY","CHF","AUD","NZD","CAD"};

datetime g_last_dashboard_update = 0;
string g_object_prefix = "COBR_";

int OnInit()
{
   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   g_object_prefix = "COBR_" + IntegerToString((int)(ChartID() % 1000000)) + "_";

   if(ParseSymbols() <= 0)
   {
      Print("ChartOnlyBreakoutRadarEA: no valid symbols were provided.");
      return INIT_PARAMETERS_INCORRECT;
   }

   AllocateHistoryBuffers();

   for(int i = 0; i < ArraySize(g_profiles); i++)
      EnsureSymbolReady(i);

   ResetLastError();
   if(!EventSetTimer(IntMax(1, ScanIntervalSeconds)))
   {
      PrintFormat("ChartOnlyBreakoutRadarEA: EventSetTimer failed, error %d", GetLastError());
      return INIT_FAILED;
   }

   ScanAll(true);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   CleanupDashboardObjects();
}

void OnTimer()
{
   ScanAll(false);
}

bool ValidateInputs()
{
   if(ScanIntervalSeconds < 1 || DisplayUpdateSeconds < 1 || MaxQuoteAgeSeconds < 1)
   {
      Print("ChartOnlyBreakoutRadarEA: scan, display, and quote-age inputs must be positive.");
      return false;
   }

   if(MinDisplayConfidence < 1.0 || MinDisplayConfidence > 99.0 ||
      StrongAlertConfidence < MinDisplayConfidence || StrongAlertConfidence > 100.0)
   {
      Print("ChartOnlyBreakoutRadarEA: confidence inputs are inconsistent.");
      return false;
   }

   if(RangeLookbackM1 < 10 || ATRPeriod < 2 ||
      BreakoutBufferATR < 0.0 || MinBreakoutBufferPips < 0.0)
   {
      Print("ChartOnlyBreakoutRadarEA: range and ATR inputs are outside supported bounds.");
      return false;
   }

   if(MaxSpreadPips <= 0.0 || MaxSpreadMedianMultiplier <= 1.0)
   {
      Print("ChartOnlyBreakoutRadarEA: spread filters are outside supported bounds.");
      return false;
   }

   if(FailedSignalCooldownSeconds < 1 || ValidSignalCooldownSeconds < 1)
   {
      Print("ChartOnlyBreakoutRadarEA: cooldown inputs must be positive.");
      return false;
   }

   return true;
}

int ParseSymbols()
{
   ArrayResize(g_profiles, 0);

   string cleaned = SymbolsToScan;
   StringReplace(cleaned, ";", ",");
   StringReplace(cleaned, "\r", ",");
   StringReplace(cleaned, "\n", ",");
   StringReplace(cleaned, "\t", ",");

   string parts[];
   ushort comma = StringGetCharacter(",", 0);
   int total = StringSplit(cleaned, comma, parts);

   for(int i = 0; i < total; i++)
   {
      string token = parts[i];
      StringTrimLeft(token);
      StringTrimRight(token);
      if(token == "")
         continue;

      if(SymbolAlreadyAdded(token))
         continue;

      int next = ArraySize(g_profiles);
      ArrayResize(g_profiles, next + 1);
      ResetProfile(g_profiles[next], token);
   }

   return ArraySize(g_profiles);
}

void ResetProfile(SymbolProfile &profile, const string symbol)
{
   profile.symbol = symbol;
   profile.valid = false;
   profile.selected = false;
   profile.base_index = -1;
   profile.quote_index = -1;
   FindBaseQuoteCurrencies(symbol, profile.base_index, profile.quote_index);

   profile.digits = 0;
   profile.point = 0.0;
   profile.pip_size = 0.0;

   profile.quote_fresh = false;
   profile.quote_time = 0;
   profile.quote_time_msc = 0;
   profile.bid = 0.0;
   profile.ask = 0.0;
   profile.mid = 0.0;
   profile.last_mid = 0.0;
   profile.spread_pips = 0.0;
   profile.median_spread_pips = 0.0;

   profile.has_m1 = false;
   profile.has_m5 = false;
   profile.has_m15 = false;
   profile.atr_m1 = 0.0;
   profile.atr_m5 = 0.0;
   profile.range_high = 0.0;
   profile.range_low = 0.0;
   profile.range_width = 0.0;

   profile.current_m1_open = 0.0;
   profile.current_m1_high = 0.0;
   profile.current_m1_low = 0.0;
   profile.current_m1_close = 0.0;
   profile.current_m1_tick_volume = 0.0;
   profile.last_completed_m1_tick_volume = 0.0;
   profile.average_m1_tick_volume = 0.0;

   profile.speed_5s_pips = 0.0;
   profile.speed_10s_pips = 0.0;
   profile.speed_30s_pips = 0.0;
   profile.speed_60s_pips = 0.0;
   profile.movement_5m_pips = 0.0;
   profile.movement_15m_pips = 0.0;
   profile.m5_move_atr = 0.0;
   profile.m15_move_atr = 0.0;

   profile.technical_score_up = 0.0;
   profile.technical_score_down = 0.0;
   profile.impulse_score_up = 0.0;
   profile.impulse_score_down = 0.0;
   profile.final_score_up = 0.0;
   profile.final_score_down = 0.0;

   profile.active_direction = DIR_NONE;
   profile.event_state = STATE_IDLE;
   profile.event_start_time = 0;
   profile.event_local_time = 0;
   profile.last_display_update_time = 0;
   profile.cooldown_end_up = 0;
   profile.cooldown_end_down = 0;
   profile.last_alert_sent_time = 0;
   profile.strong_alert_sent = false;
   profile.active_displayed = false;
   profile.confidence_below_since = 0;
   profile.candidate_direction = DIR_NONE;
   profile.candidate_start_time = 0;

   profile.outside_since_up = 0;
   profile.outside_since_down = 0;

   profile.snapshot_write_index = 0;
   profile.snapshot_count = 0;
   profile.spread_write_index = 0;
   profile.spread_count = 0;

   profile.status_message = "";
}

bool SymbolAlreadyAdded(const string symbol)
{
   string candidate = UpperAscii(symbol);
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(UpperAscii(g_profiles[i].symbol) == candidate)
         return true;
   }
   return false;
}

void AllocateHistoryBuffers()
{
   int symbol_count = ArraySize(g_profiles);
   ArrayResize(g_snapshots, symbol_count * SNAPSHOT_CAPACITY);
   ArrayResize(g_spread_history, symbol_count * SPREAD_HISTORY_CAPACITY);

   for(int i = 0; i < ArraySize(g_snapshots); i++)
   {
      g_snapshots[i].time_msc = 0;
      g_snapshots[i].mid = 0.0;
   }

   ArrayInitialize(g_spread_history, 0.0);
}

void ScanAll(const bool force_dashboard)
{
   datetime now = TimeCurrent();

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(IsStopped())
         return;
      UpdateMarketData(i, now);
   }

   CalculateCurrencyStrength();

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(IsStopped())
         return;
      CalculateScoresAndUpdateState(i, now);
   }

   if(force_dashboard || g_last_dashboard_update == 0 ||
      now - g_last_dashboard_update >= DisplayUpdateSeconds)
   {
      UpdateDashboard();
      g_last_dashboard_update = now;
   }
}

bool EnsureSymbolReady(const int index)
{
   string symbol = g_profiles[index].symbol;

   ResetLastError();
   if(!SymbolSelect(symbol, true))
   {
      int initial_error = GetLastError();
      string resolved_symbol = "";
      if(!FindBrokerSymbolMatch(symbol, resolved_symbol) ||
         SymbolUsedByAnotherProfile(index, resolved_symbol))
      {
         g_profiles[index].valid = false;
         g_profiles[index].selected = false;
         g_profiles[index].status_message = StringFormat("%s: SymbolSelect failed, error %d", symbol, initial_error);
         return false;
      }

      ResetLastError();
      if(!SymbolSelect(resolved_symbol, true))
      {
         g_profiles[index].valid = false;
         g_profiles[index].selected = false;
         g_profiles[index].status_message = StringFormat("%s: fallback SymbolSelect(%s) failed, error %d",
                                                         symbol, resolved_symbol, GetLastError());
         return false;
      }

      g_profiles[index].symbol = resolved_symbol;
      FindBaseQuoteCurrencies(resolved_symbol,
                              g_profiles[index].base_index,
                              g_profiles[index].quote_index);
      ClearProfileHistory(index);
      symbol = resolved_symbol;
   }

   if(SymbolUsedByAnotherProfile(index, symbol))
   {
      g_profiles[index].valid = false;
      g_profiles[index].selected = false;
      g_profiles[index].status_message = symbol + ": duplicate resolved symbol.";
      return false;
   }

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(point <= 0.0 || digits <= 0)
   {
      g_profiles[index].valid = false;
      g_profiles[index].selected = false;
      g_profiles[index].status_message = symbol + ": invalid symbol point or digits.";
      return false;
   }

   g_profiles[index].point = point;
   g_profiles[index].digits = digits;
   g_profiles[index].pip_size = PipSize(point, digits);
   g_profiles[index].valid = true;
   g_profiles[index].selected = true;
   return true;
}

bool FindBrokerSymbolMatch(const string requested_symbol, string &resolved_symbol)
{
   int requested_base = -1;
   int requested_quote = -1;
   if(!FindBaseQuoteCurrencies(requested_symbol, requested_base, requested_quote))
      return false;

   int total = SymbolsTotal(false);
   int best_score = 1000000;
   string best_symbol = "";
   string requested_upper = UpperAscii(requested_symbol);
   string pair_code = g_currency_codes[requested_base] + g_currency_codes[requested_quote];

   for(int i = 0; i < total; i++)
   {
      string candidate = SymbolName(i, false);
      if(candidate == "")
         continue;

      int candidate_base = -1;
      int candidate_quote = -1;
      if(!FindBaseQuoteCurrencies(candidate, candidate_base, candidate_quote))
         continue;

      if(candidate_base != requested_base || candidate_quote != requested_quote)
         continue;

      string candidate_upper = UpperAscii(candidate);
      int score = 1000;
      if(candidate_upper == requested_upper)
         score = 0;
      else
      {
         int pair_pos = StringFind(candidate_upper, pair_code);
         if(pair_pos >= 0)
            score = 10 + pair_pos + IntAbs(StringLen(candidate_upper) - 6);
         else
            score = 100 + IntAbs(StringLen(candidate_upper) - StringLen(requested_upper));
      }

      if(score < best_score)
      {
         best_score = score;
         best_symbol = candidate;
      }
   }

   if(best_symbol == "")
      return false;

   resolved_symbol = best_symbol;
   return true;
}

bool SymbolUsedByAnotherProfile(const int current_index, const string symbol)
{
   string target = UpperAscii(symbol);
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(i == current_index)
         continue;
      if(UpperAscii(g_profiles[i].symbol) == target && g_profiles[i].selected)
         return true;
   }
   return false;
}

void ClearProfileHistory(const int index)
{
   for(int i = 0; i < SNAPSHOT_CAPACITY; i++)
   {
      int sample_index = SnapshotIndex(index, i);
      g_snapshots[sample_index].time_msc = 0;
      g_snapshots[sample_index].mid = 0.0;
   }

   for(int i = 0; i < SPREAD_HISTORY_CAPACITY; i++)
      g_spread_history[SpreadIndex(index, i)] = 0.0;

   g_profiles[index].snapshot_write_index = 0;
   g_profiles[index].snapshot_count = 0;
   g_profiles[index].spread_write_index = 0;
   g_profiles[index].spread_count = 0;
   g_profiles[index].median_spread_pips = 0.0;
   g_profiles[index].last_mid = 0.0;
}

bool UpdateMarketData(const int index, const datetime now)
{
   if(!EnsureSymbolReady(index))
   {
      ClearRuntimeMarketFlags(index);
      return false;
   }

   MqlTick tick;
   ResetLastError();
   if(!SymbolInfoTick(g_profiles[index].symbol, tick))
   {
      ClearRuntimeMarketFlags(index);
      g_profiles[index].status_message = StringFormat("%s: SymbolInfoTick failed, error %d",
                                                      g_profiles[index].symbol, GetLastError());
      return false;
   }

   if(tick.bid <= 0.0 || tick.ask <= 0.0 || tick.ask < tick.bid || tick.time <= 0)
   {
      ClearRuntimeMarketFlags(index);
      g_profiles[index].status_message = g_profiles[index].symbol + ": invalid quote.";
      return false;
   }

   g_profiles[index].quote_time = tick.time;
   g_profiles[index].quote_time_msc = (long)tick.time_msc;
   if(g_profiles[index].quote_time_msc <= 0)
      g_profiles[index].quote_time_msc = (long)tick.time * 1000;

   g_profiles[index].quote_fresh = (now - tick.time <= MaxQuoteAgeSeconds);
   g_profiles[index].bid = tick.bid;
   g_profiles[index].ask = tick.ask;
   g_profiles[index].last_mid = g_profiles[index].mid;
   g_profiles[index].mid = (tick.bid + tick.ask) * 0.5;
   g_profiles[index].spread_pips = (tick.ask - tick.bid) / g_profiles[index].pip_size;

   AddSnapshot(index, g_profiles[index].quote_time_msc, g_profiles[index].mid);
   AddSpreadSample(index, g_profiles[index].spread_pips);
   g_profiles[index].median_spread_pips = CalculateMedianSpread(index);

   UpdateRatesData(index);
   UpdateMovementData(index);
   UpdateOutsideTimers(index, now);

   return true;
}

void ClearRuntimeMarketFlags(const int index)
{
   g_profiles[index].quote_fresh = false;
   g_profiles[index].has_m1 = false;
   g_profiles[index].has_m5 = false;
   g_profiles[index].has_m15 = false;
}

void UpdateRatesData(const int index)
{
   string symbol = g_profiles[index].symbol;
   int need_m1 = IntMax(RangeLookbackM1 + ATRPeriod + 20, 80);
   int min_m1 = IntMax(RangeLookbackM1 + 2, ATRPeriod + 3);

   MqlRates m1[];
   ArraySetAsSeries(m1, true);
   int copied_m1 = CopyRates(symbol, PERIOD_M1, 0, need_m1, m1);
   g_profiles[index].has_m1 = (copied_m1 >= min_m1);

   if(g_profiles[index].has_m1)
   {
      g_profiles[index].atr_m1 = CalculateATRFromRates(m1, copied_m1, ATRPeriod);
      BuildM1RangeBox(index, m1, copied_m1);
      g_profiles[index].current_m1_open = m1[0].open;
      g_profiles[index].current_m1_high = m1[0].high;
      g_profiles[index].current_m1_low = m1[0].low;
      g_profiles[index].current_m1_close = m1[0].close;
      g_profiles[index].current_m1_tick_volume = (double)m1[0].tick_volume;
      g_profiles[index].last_completed_m1_tick_volume = (double)m1[1].tick_volume;
      g_profiles[index].average_m1_tick_volume = AverageM1TickVolume(m1, copied_m1);

      if(copied_m1 > 5)
         g_profiles[index].movement_5m_pips = (g_profiles[index].mid - m1[5].close) / g_profiles[index].pip_size;
      else
         g_profiles[index].movement_5m_pips = 0.0;

      if(copied_m1 > 15)
         g_profiles[index].movement_15m_pips = (g_profiles[index].mid - m1[15].close) / g_profiles[index].pip_size;
      else
         g_profiles[index].movement_15m_pips = g_profiles[index].movement_5m_pips;
   }
   else
   {
      g_profiles[index].atr_m1 = 0.0;
      g_profiles[index].range_high = 0.0;
      g_profiles[index].range_low = 0.0;
      g_profiles[index].range_width = 0.0;
   }

   MqlRates m5[];
   ArraySetAsSeries(m5, true);
   int need_m5 = IntMax(ATRPeriod + 10, 40);
   int copied_m5 = CopyRates(symbol, PERIOD_M5, 0, need_m5, m5);
   g_profiles[index].has_m5 = (copied_m5 >= ATRPeriod + 3);

   if(g_profiles[index].has_m5)
   {
      g_profiles[index].atr_m5 = CalculateATRFromRates(m5, copied_m5, ATRPeriod);
      if(g_profiles[index].atr_m5 > 0.0)
         g_profiles[index].m5_move_atr = (m5[0].close - m5[1].close) / g_profiles[index].atr_m5;
      else
         g_profiles[index].m5_move_atr = 0.0;
   }
   else
   {
      g_profiles[index].atr_m5 = 0.0;
      g_profiles[index].m5_move_atr = 0.0;
   }

   MqlRates m15[];
   ArraySetAsSeries(m15, true);
   int copied_m15 = CopyRates(symbol, PERIOD_M15, 0, 8, m15);
   g_profiles[index].has_m15 = (copied_m15 >= 4);

   if(g_profiles[index].has_m15 && g_profiles[index].atr_m5 > 0.0)
      g_profiles[index].m15_move_atr = (m15[0].close - m15[1].close) / g_profiles[index].atr_m5;
   else
      g_profiles[index].m15_move_atr = 0.0;
}

void BuildM1RangeBox(const int index, MqlRates &rates[], const int copied)
{
   int usable = IntMin(RangeLookbackM1, copied - 1);
   if(usable < RangeLookbackM1)
   {
      g_profiles[index].has_m1 = false;
      return;
   }

   double high = rates[1].high;
   double low = rates[1].low;
   for(int i = 2; i <= usable; i++)
   {
      high = MathMax(high, rates[i].high);
      low = MathMin(low, rates[i].low);
   }

   g_profiles[index].range_high = high;
   g_profiles[index].range_low = low;
   g_profiles[index].range_width = high - low;
}

double CalculateATRFromRates(MqlRates &rates[], const int copied, const int period)
{
   if(copied <= period + 1 || period <= 0)
      return 0.0;

   double total = 0.0;
   int counted = 0;

   for(int i = 1; i <= period && i + 1 < copied; i++)
   {
      double high = rates[i].high;
      double low = rates[i].low;
      double previous_close = rates[i + 1].close;
      double true_range = Max3(high - low,
                               MathAbs(high - previous_close),
                               MathAbs(low - previous_close));
      total += true_range;
      counted++;
   }

   if(counted <= 0)
      return 0.0;

   return total / (double)counted;
}

double AverageM1TickVolume(MqlRates &rates[], const int copied)
{
   int lookback = IntMin(20, copied - 2);
   if(lookback <= 0)
      return 0.0;

   double total = 0.0;
   for(int i = 1; i <= lookback; i++)
      total += (double)rates[i].tick_volume;

   return total / (double)lookback;
}

void UpdateMovementData(const int index)
{
   g_profiles[index].speed_5s_pips = MovementPips(index, 5);
   g_profiles[index].speed_10s_pips = MovementPips(index, 10);
   g_profiles[index].speed_30s_pips = MovementPips(index, 30);
   g_profiles[index].speed_60s_pips = MovementPips(index, 60);
}

void UpdateOutsideTimers(const int index, const datetime now)
{
   if(!g_profiles[index].has_m1 || g_profiles[index].atr_m1 <= 0.0)
   {
      g_profiles[index].outside_since_up = 0;
      g_profiles[index].outside_since_down = 0;
      return;
   }

   double buffer = BreakoutBufferPrice(index);
   double up_boundary = g_profiles[index].range_high + buffer;
   double down_boundary = g_profiles[index].range_low - buffer;

   if(g_profiles[index].mid > up_boundary)
   {
      if(g_profiles[index].outside_since_up == 0)
         g_profiles[index].outside_since_up = now;
   }
   else
      g_profiles[index].outside_since_up = 0;

   if(g_profiles[index].mid < down_boundary)
   {
      if(g_profiles[index].outside_since_down == 0)
         g_profiles[index].outside_since_down = now;
   }
   else
      g_profiles[index].outside_since_down = 0;
}

void AddSnapshot(const int index, const long time_msc, const double mid)
{
   if(time_msc <= 0 || mid <= 0.0)
      return;

   if(g_profiles[index].snapshot_count > 0)
   {
      int last_position = g_profiles[index].snapshot_write_index - 1;
      if(last_position < 0)
         last_position = SNAPSHOT_CAPACITY - 1;
      int last_index = SnapshotIndex(index, last_position);
      if(g_snapshots[last_index].time_msc == time_msc &&
         MathAbs(g_snapshots[last_index].mid - mid) < g_profiles[index].point * 0.1)
      {
         return;
      }
   }

   int position = g_profiles[index].snapshot_write_index;
   int sample_index = SnapshotIndex(index, position);
   g_snapshots[sample_index].time_msc = time_msc;
   g_snapshots[sample_index].mid = mid;

   g_profiles[index].snapshot_write_index = (position + 1) % SNAPSHOT_CAPACITY;
   if(g_profiles[index].snapshot_count < SNAPSHOT_CAPACITY)
      g_profiles[index].snapshot_count++;
}

void AddSpreadSample(const int index, const double spread_pips)
{
   if(spread_pips <= 0.0)
      return;

   int position = g_profiles[index].spread_write_index;
   g_spread_history[SpreadIndex(index, position)] = spread_pips;
   g_profiles[index].spread_write_index = (position + 1) % SPREAD_HISTORY_CAPACITY;
   if(g_profiles[index].spread_count < SPREAD_HISTORY_CAPACITY)
      g_profiles[index].spread_count++;
}

double CalculateMedianSpread(const int index)
{
   int count = g_profiles[index].spread_count;
   if(count <= 0)
      return g_profiles[index].spread_pips;

   double values[];
   ArrayResize(values, count);
   for(int i = 0; i < count; i++)
   {
      int position = LogicalSpreadPosition(index, i);
      values[i] = g_spread_history[SpreadIndex(index, position)];
   }

   ArraySort(values);
   if((count % 2) == 1)
      return values[count / 2];

   return (values[count / 2 - 1] + values[count / 2]) * 0.5;
}

void CalculateCurrencyStrength()
{
   for(int i = 0; i < CURRENCY_COUNT; i++)
   {
      g_currency_strength[i] = 0.0;
      g_currency_samples[i] = 0;
   }

   if(!UseCurrencyStrength)
      return;

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!g_profiles[i].valid || !g_profiles[i].quote_fresh ||
         g_profiles[i].base_index < 0 || g_profiles[i].quote_index < 0 ||
         g_profiles[i].atr_m1 <= 0.0 || g_profiles[i].pip_size <= 0.0)
      {
         continue;
      }

      double atr_pips = MathMax(g_profiles[i].atr_m1 / g_profiles[i].pip_size, 0.1);
      double n30 = Clamp(g_profiles[i].speed_30s_pips / (atr_pips * 0.35), -1.5, 1.5);
      double n60 = Clamp(g_profiles[i].speed_60s_pips / (atr_pips * 0.55), -1.5, 1.5);
      double n5m = Clamp(g_profiles[i].movement_5m_pips / (atr_pips * 1.50), -1.5, 1.5);
      double pair_strength = n30 * 0.45 + n60 * 0.25 + n5m * 0.30;

      int base = g_profiles[i].base_index;
      int quote = g_profiles[i].quote_index;
      g_currency_strength[base] += pair_strength;
      g_currency_strength[quote] -= pair_strength;
      g_currency_samples[base]++;
      g_currency_samples[quote]++;
   }

   for(int i = 0; i < CURRENCY_COUNT; i++)
   {
      if(g_currency_samples[i] > 0)
         g_currency_strength[i] /= (double)g_currency_samples[i];
   }
}

void CalculateScoresAndUpdateState(const int index, const datetime now)
{
   g_profiles[index].technical_score_up = 0.0;
   g_profiles[index].technical_score_down = 0.0;
   g_profiles[index].impulse_score_up = 0.0;
   g_profiles[index].impulse_score_down = 0.0;
   g_profiles[index].final_score_up = 0.0;
   g_profiles[index].final_score_down = 0.0;

   if(!HardRejectProfile(index, now))
   {
      g_profiles[index].technical_score_up = CalculateTechnicalScore(index, DIR_UP);
      g_profiles[index].technical_score_down = CalculateTechnicalScore(index, DIR_DOWN);
      g_profiles[index].impulse_score_up = CalculateImpulseScore(index, DIR_UP);
      g_profiles[index].impulse_score_down = CalculateImpulseScore(index, DIR_DOWN);

      double raw_up = CombineEngineScores(g_profiles[index].technical_score_up,
                                          g_profiles[index].impulse_score_up);
      double raw_down = CombineEngineScores(g_profiles[index].technical_score_down,
                                            g_profiles[index].impulse_score_down);

      if(!HardRejectDirection(index, DIR_UP, raw_up))
      {
         double penalties_up = ApplyFakeoutPenalties(index, DIR_UP, now, raw_up);
         g_profiles[index].final_score_up = Clamp(raw_up - penalties_up, 0.0, 100.0);
      }

      if(!HardRejectDirection(index, DIR_DOWN, raw_down))
      {
         double penalties_down = ApplyFakeoutPenalties(index, DIR_DOWN, now, raw_down);
         g_profiles[index].final_score_down = Clamp(raw_down - penalties_down, 0.0, 100.0);
      }
   }

   UpdateSignalState(index, now);
}

double CalculateTechnicalScore(const int index, const int direction)
{
   if(!UseTechnicalBreakoutEngine)
      return 0.0;

   double breakout_distance = BreakoutDistance(index, direction);
   if(breakout_distance <= 0.0)
      return 0.0;

   double buffer = BreakoutBufferPrice(index);
   double compression = RangeCompressionScore(index);
   double clean_break = LinearScore(breakout_distance / MathMax(buffer, g_profiles[index].point),
                                    0.05, 2.00);
   double momentum = DirectionalMovementScore(index, direction);
   double volume = TickVolumeScore(index);
   double hold = OutsideHoldScore(index, direction);
   double currency = CurrencyConfirmationScore(index, direction);
   double spread = SpreadQualityScore(index);

   return compression * 0.15 +
          clean_break * 0.20 +
          momentum * 0.20 +
          volume * 0.10 +
          hold * 0.15 +
          currency * 0.15 +
          spread * 0.05;
}

double CalculateImpulseScore(const int index, const int direction)
{
   if(!UseImpulseBreakoutEngine)
      return 0.0;

   double speed = DirectionalMovementScore(index, direction);
   double candle = CandleExpansionScore(index, direction);
   if(speed < 22.0 && candle < 25.0)
      return 0.0;

   double volume = TickVolumeScore(index);
   double currency = CurrencyConfirmationScore(index, direction);
   double continuation = ContinuationScore(index, direction);
   double spread = SpreadQualityScore(index);

   return speed * 0.25 +
          candle * 0.20 +
          volume * 0.15 +
          currency * 0.20 +
          continuation * 0.15 +
          spread * 0.05;
}

double CombineEngineScores(const double technical_score, const double impulse_score)
{
   double raw = MathMax(technical_score, impulse_score);
   if(technical_score >= 40.0 && impulse_score >= 40.0)
      raw += 7.0;
   return Clamp(raw, 0.0, 100.0);
}

bool HardRejectProfile(const int index, const datetime now)
{
   if(!g_profiles[index].valid || !g_profiles[index].selected)
      return true;

   if(!g_profiles[index].quote_fresh)
      return true;

   if(!g_profiles[index].has_m1 || !g_profiles[index].has_m5 || !g_profiles[index].has_m15)
      return true;

   if(g_profiles[index].spread_pips <= 0.0 || g_profiles[index].spread_pips > MaxSpreadPips)
      return true;

   if(g_profiles[index].median_spread_pips > 0.0 &&
      g_profiles[index].spread_pips > g_profiles[index].median_spread_pips * MaxSpreadMedianMultiplier)
   {
      return true;
   }

   if(g_profiles[index].atr_m1 <= 0.0 ||
      g_profiles[index].atr_m1 / g_profiles[index].pip_size < 0.10)
   {
      return true;
   }

   if(IgnoreRolloverTime && IsRolloverTime(now))
      return true;

   return false;
}

bool HardRejectDirection(const int index, const int direction, const double raw_score)
{
   if(raw_score <= 0.0)
      return true;

   double breakout_distance = BreakoutDistance(index, direction);
   double spread_price = g_profiles[index].ask - g_profiles[index].bid;
   double directional_10s = DirectionalValue(g_profiles[index].speed_10s_pips, direction);

   if(breakout_distance > 0.0 && breakout_distance <= spread_price * 1.20 &&
      directional_10s < g_profiles[index].spread_pips * 0.60)
   {
      return true;
   }

   return false;
}

double ApplyFakeoutPenalties(const int index,
                             const int direction,
                             const datetime now,
                             const double raw_score)
{
   if(raw_score <= 0.0)
      return 100.0;

   double penalties = 0.0;
   double buffer = BreakoutBufferPrice(index);

   if(direction == DIR_UP && g_profiles[index].mid <= g_profiles[index].range_high)
      penalties += (g_profiles[index].mid < g_profiles[index].range_high - buffer ? 35.0 : 22.0);
   else if(direction == DIR_DOWN && g_profiles[index].mid >= g_profiles[index].range_low)
      penalties += (g_profiles[index].mid > g_profiles[index].range_low + buffer ? 35.0 : 22.0);

   double candle_range = g_profiles[index].current_m1_high - g_profiles[index].current_m1_low;
   double body = MathAbs(g_profiles[index].current_m1_close - g_profiles[index].current_m1_open);
   if(candle_range > 0.0)
   {
      double against_wick = 0.0;
      if(direction == DIR_UP)
         against_wick = g_profiles[index].current_m1_high -
                        MathMax(g_profiles[index].current_m1_open, g_profiles[index].current_m1_close);
      else
         against_wick = MathMin(g_profiles[index].current_m1_open, g_profiles[index].current_m1_close) -
                        g_profiles[index].current_m1_low;

      double wick_ratio = against_wick / candle_range;
      if(wick_ratio > 0.65)
         penalties += 25.0;
      else if(wick_ratio > 0.45)
         penalties += 14.0;

      double body_ratio = body / candle_range;
      if(body_ratio < 0.15)
         penalties += 15.0;
      else if(body_ratio < 0.28)
         penalties += 8.0;
   }

   double volume_score = TickVolumeScore(index);
   if(volume_score < 25.0)
      penalties += 15.0;
   else if(volume_score < 45.0)
      penalties += 7.0;

   double currency_score = CurrencyConfirmationScore(index, direction);
   if(currency_score < 25.0)
      penalties += 25.0;
   else if(currency_score < 45.0)
      penalties += 12.0;

   double m5_context = g_profiles[index].m5_move_atr * (double)direction;
   if(m5_context < -0.70)
      penalties += 15.0;
   else if(m5_context < -0.35)
      penalties += 8.0;

   double m15_context = g_profiles[index].m15_move_atr * (double)direction;
   if(m15_context < -0.60)
      penalties += 20.0;
   else if(m15_context < -0.25)
      penalties += 9.0;

   int age_seconds = EventAgeSeconds(index, direction, now);
   if(age_seconds > 300)
      penalties += 100.0;
   else if(age_seconds > 180)
      penalties += 10.0 + (double)(age_seconds - 180) / 120.0 * 20.0;
   else if(age_seconds > 60)
      penalties += (double)(age_seconds - 60) / 120.0 * 10.0;

   double atr_pips = MathMax(g_profiles[index].atr_m1 / g_profiles[index].pip_size, 0.1);
   double extended = DirectionalValue(g_profiles[index].movement_5m_pips, direction) / atr_pips;
   if(extended > 4.0)
      penalties += 25.0;
   else if(extended > 2.5)
      penalties += (extended - 2.5) / 1.5 * 18.0;

   double spread_quality = SpreadQualityScore(index);
   if(spread_quality < 70.0)
      penalties += (70.0 - spread_quality) / 70.0 * 20.0;

   return Clamp(penalties, 0.0, 100.0);
}

void UpdateSignalState(const int index, const datetime now)
{
   int best_direction = DIR_NONE;
   double best_score = 0.0;
   PickBestDirection(index, now, best_direction, best_score);

   if(g_profiles[index].event_state == STATE_ACTIVE_SIGNAL &&
      g_profiles[index].active_direction != DIR_NONE)
   {
      int current_direction = g_profiles[index].active_direction;
      double current_score = DirectionScore(index, current_direction);
      int opposite_direction = -current_direction;
      double opposite_score = DirectionScore(index, opposite_direction);

      if(opposite_score >= StrongAlertConfidence && opposite_score > current_score + 8.0)
      {
         StartCooldown(index, current_direction, now, ValidSignalCooldownSeconds);
         ActivateSignal(index, opposite_direction, opposite_score, now);
         return;
      }

      if(current_score >= MinDisplayConfidence && EventAgeSeconds(index, current_direction, now) <= 300)
      {
         g_profiles[index].confidence_below_since = 0;
         ActivateSignal(index, current_direction, current_score, now);
         return;
      }

      if(g_profiles[index].confidence_below_since == 0)
         g_profiles[index].confidence_below_since = now;

      if(now - g_profiles[index].confidence_below_since >= DisplayUpdateSeconds ||
         EventAgeSeconds(index, current_direction, now) > 300)
      {
         EndActiveSignal(index, current_direction, now);
      }

      return;
   }

   if(best_direction != DIR_NONE && best_score >= MinDisplayConfidence)
   {
      if(g_profiles[index].event_state == STATE_CANDIDATE &&
         g_profiles[index].candidate_direction == best_direction)
      {
         if(now - g_profiles[index].candidate_start_time >= 2 ||
            best_score >= StrongAlertConfidence)
         {
            ActivateSignal(index, best_direction, best_score, now);
         }
         return;
      }

      g_profiles[index].event_state = STATE_CANDIDATE;
      g_profiles[index].candidate_direction = best_direction;
      g_profiles[index].candidate_start_time = now;

      if(best_score >= StrongAlertConfidence)
         ActivateSignal(index, best_direction, best_score, now);

      return;
   }

   if(g_profiles[index].event_state == STATE_CANDIDATE &&
      g_profiles[index].candidate_direction != DIR_NONE)
   {
      StartCooldown(index, g_profiles[index].candidate_direction, now, FailedSignalCooldownSeconds);
      g_profiles[index].candidate_direction = DIR_NONE;
      g_profiles[index].candidate_start_time = 0;
      g_profiles[index].event_state = STATE_COOLDOWN;
      return;
   }

   if(now >= g_profiles[index].cooldown_end_up && now >= g_profiles[index].cooldown_end_down)
      g_profiles[index].event_state = STATE_WATCH;
   else
      g_profiles[index].event_state = STATE_COOLDOWN;
}

void PickBestDirection(const int index,
                       const datetime now,
                       int &best_direction,
                       double &best_score)
{
   best_direction = DIR_NONE;
   best_score = 0.0;

   bool up_allowed = (now >= g_profiles[index].cooldown_end_up ||
                      g_profiles[index].final_score_up >= StrongAlertConfidence);
   bool down_allowed = (now >= g_profiles[index].cooldown_end_down ||
                        g_profiles[index].final_score_down >= StrongAlertConfidence);

   if(up_allowed && g_profiles[index].final_score_up >= MinDisplayConfidence)
   {
      best_direction = DIR_UP;
      best_score = g_profiles[index].final_score_up;
   }

   if(down_allowed && g_profiles[index].final_score_down >= MinDisplayConfidence &&
      g_profiles[index].final_score_down > best_score)
   {
      best_direction = DIR_DOWN;
      best_score = g_profiles[index].final_score_down;
   }
}

void ActivateSignal(const int index,
                    const int direction,
                    const double score,
                    const datetime now)
{
   bool new_signal = (g_profiles[index].event_state != STATE_ACTIVE_SIGNAL ||
                      g_profiles[index].active_direction != direction);

   if(new_signal)
   {
      g_profiles[index].event_start_time = now;
      g_profiles[index].event_local_time = TimeLocal();
      g_profiles[index].strong_alert_sent = false;
      g_profiles[index].active_displayed = true;
      PushSignalHistory(index, direction, score, g_profiles[index].event_local_time);
      SendOptionalAlert(index, direction, score, now, false);
   }
   else if(score >= StrongAlertConfidence && !g_profiles[index].strong_alert_sent)
   {
      UpdateSignalHistory(index, direction, score);
      SendOptionalAlert(index, direction, score, now, true);
   }
   else
   {
      UpdateSignalHistory(index, direction, score);
   }

   g_profiles[index].active_direction = direction;
   g_profiles[index].event_state = STATE_ACTIVE_SIGNAL;
   g_profiles[index].candidate_direction = DIR_NONE;
   g_profiles[index].candidate_start_time = 0;
   g_profiles[index].confidence_below_since = 0;

   if(score >= StrongAlertConfidence)
      g_profiles[index].strong_alert_sent = true;
}

void EndActiveSignal(const int index, const int direction, const datetime now)
{
   StartCooldown(index, direction, now, ValidSignalCooldownSeconds);
   g_profiles[index].active_direction = DIR_NONE;
   g_profiles[index].event_state = STATE_COOLDOWN;
   g_profiles[index].event_start_time = 0;
   g_profiles[index].event_local_time = 0;
   g_profiles[index].confidence_below_since = 0;
   g_profiles[index].strong_alert_sent = false;
   g_profiles[index].active_displayed = false;
}

void StartCooldown(const int index,
                   const int direction,
                   const datetime now,
                   const int seconds)
{
   if(direction == DIR_UP)
      g_profiles[index].cooldown_end_up = now + seconds;
   else if(direction == DIR_DOWN)
      g_profiles[index].cooldown_end_down = now + seconds;
}

void SendOptionalAlert(const int index,
                       const int direction,
                       const double score,
                       const datetime now,
                       const bool strong_upgrade)
{
   string text = FormatSignalText(index, direction, score);
   string prefix = (strong_upgrade ? "Strong breakout: " : "Breakout radar: ");

   if(EnableSoundAlert)
      PlaySound("alert.wav");

   if(EnablePushNotification)
      SendNotification(prefix + text);

   g_profiles[index].last_alert_sent_time = now;
}

void UpdateDashboard()
{
   EnsureDashboardObjects();

   ObjectSetString(0, DashboardName(0), OBJPROP_TEXT, "BREAKOUT RADAR");
   ObjectSetInteger(0, DashboardName(0), OBJPROP_COLOR, clrRed);

   for(int row = 0; row < SIGNAL_HISTORY_SIZE; row++)
   {
      int object_row = row + 1;
      if(row < g_signal_history_count && g_signal_history[row].used)
      {
         ObjectSetString(0, DashboardName(object_row), OBJPROP_TEXT, g_signal_history[row].text);
         ObjectSetInteger(0, DashboardName(object_row), OBJPROP_COLOR, clrRed);
      }
      else
      {
         ObjectSetString(0, DashboardName(object_row), OBJPROP_TEXT, "");
      }
   }

   for(int row = SIGNAL_HISTORY_SIZE + 1; row < DASHBOARD_MAX_OBJECTS; row++)
      ObjectSetString(0, DashboardName(row), OBJPROP_TEXT, "");

   ChartRedraw(0);
}

void PushSignalHistory(const int index,
                       const int direction,
                       const double score,
                       const datetime local_time)
{
   for(int i = SIGNAL_HISTORY_SIZE - 1; i > 0; i--)
      CopySignalHistoryEntry(g_signal_history[i - 1], g_signal_history[i]);

   g_signal_history[0].used = true;
   g_signal_history[0].symbol = g_profiles[index].symbol;
   g_signal_history[0].direction = direction;
   g_signal_history[0].local_time = local_time;
   g_signal_history[0].score = score;
   g_signal_history[0].text = FormatSignalHistoryText(g_signal_history[0].symbol,
                                                      direction,
                                                      score,
                                                      local_time);

   if(g_signal_history_count < SIGNAL_HISTORY_SIZE)
      g_signal_history_count++;
}

void UpdateSignalHistory(const int index, const int direction, const double score)
{
   datetime local_time = g_profiles[index].event_local_time;
   if(local_time <= 0)
      return;

   for(int i = 0; i < g_signal_history_count; i++)
   {
      if(!g_signal_history[i].used)
         continue;

      if(g_signal_history[i].symbol == g_profiles[index].symbol &&
         g_signal_history[i].direction == direction &&
         g_signal_history[i].local_time == local_time)
      {
         g_signal_history[i].score = score;
         g_signal_history[i].text = FormatSignalHistoryText(g_signal_history[i].symbol,
                                                            direction,
                                                            score,
                                                            local_time);
         return;
      }
   }
}

void CopySignalHistoryEntry(const SignalHistoryEntry &source, SignalHistoryEntry &target)
{
   target.used = source.used;
   target.symbol = source.symbol;
   target.direction = source.direction;
   target.local_time = source.local_time;
   target.score = source.score;
   target.text = source.text;
}

void EnsureDashboardObjects()
{
   for(int i = 0; i < DASHBOARD_MAX_OBJECTS; i++)
   {
      string name = DashboardName(i);
      if(ObjectFind(0, name) < 0)
      {
         ResetLastError();
         if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         {
            PrintFormat("ChartOnlyBreakoutRadarEA: failed to create dashboard object %s, error %d",
                        name, GetLastError());
            continue;
         }
      }

      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 12);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 24 + i * 18);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   }
}

void CleanupDashboardObjects()
{
   for(int i = 0; i < DASHBOARD_MAX_OBJECTS; i++)
      ObjectDelete(0, DashboardName(i));
}

string DashboardName(const int row)
{
   return g_object_prefix + IntegerToString(row);
}

string FormatSignalText(const int index, const int direction, const double score)
{
   string direction_text = (direction == DIR_UP ? "UP" : "DOWN");
   int confidence = (int)MathRound(Clamp(score, 0.0, 100.0));
   return StringFormat("%s %s - %d%%", g_profiles[index].symbol, direction_text, confidence);
}

string FormatSignalHistoryText(const string symbol,
                               const int direction,
                               const double score,
                               const datetime local_time)
{
   string direction_text = (direction == DIR_UP ? "UP" : "DOWN");
   int confidence = (int)MathRound(Clamp(score, 0.0, 100.0));
   return StringFormat("%s - %s %s - %d%%",
                       FormatLocalTimestamp(local_time),
                       symbol,
                       direction_text,
                       confidence);
}

string FormatLocalTimestamp(const datetime local_time)
{
   MqlDateTime parts;
   TimeToStruct(local_time, parts);
   return StringFormat("%04d-%02d-%02d %02d:%02d:%02d",
                       parts.year,
                       parts.mon,
                       parts.day,
                       parts.hour,
                       parts.min,
                       parts.sec);
}

double DirectionScore(const int index, const int direction)
{
   if(direction == DIR_UP)
      return g_profiles[index].final_score_up;
   if(direction == DIR_DOWN)
      return g_profiles[index].final_score_down;
   return 0.0;
}

int EventAgeSeconds(const int index, const int direction, const datetime now)
{
   datetime start_time = 0;
   if(g_profiles[index].event_state == STATE_ACTIVE_SIGNAL &&
      g_profiles[index].active_direction == direction &&
      g_profiles[index].event_start_time > 0)
   {
      start_time = g_profiles[index].event_start_time;
   }
   else if(g_profiles[index].event_state == STATE_CANDIDATE &&
           g_profiles[index].candidate_direction == direction &&
           g_profiles[index].candidate_start_time > 0)
   {
      start_time = g_profiles[index].candidate_start_time;
   }

   if(start_time <= 0)
      return 0;

   int age = (int)(now - start_time);
   if(age < 0)
      age = 0;
   return age;
}

double BreakoutBufferPrice(const int index)
{
   double spread_price = MathMax(g_profiles[index].ask - g_profiles[index].bid, 0.0);
   double atr_part = g_profiles[index].atr_m1 * BreakoutBufferATR;
   double min_part = MinBreakoutBufferPips * g_profiles[index].pip_size;
   return Max3(spread_price * 1.20, atr_part, min_part);
}

double BreakoutDistance(const int index, const int direction)
{
   double buffer = BreakoutBufferPrice(index);
   if(direction == DIR_UP)
      return g_profiles[index].mid - (g_profiles[index].range_high + buffer);
   if(direction == DIR_DOWN)
      return (g_profiles[index].range_low - buffer) - g_profiles[index].mid;
   return 0.0;
}

double RangeCompressionScore(const int index)
{
   if(g_profiles[index].atr_m1 <= 0.0 || g_profiles[index].range_width <= 0.0)
      return 0.0;

   double range_atr = g_profiles[index].range_width / g_profiles[index].atr_m1;
   if(range_atr <= 2.0)
      return 100.0;
   if(range_atr <= 5.0)
      return 100.0 - (range_atr - 2.0) / 3.0 * 45.0;
   if(range_atr <= 8.0)
      return 55.0 - (range_atr - 5.0) / 3.0 * 40.0;
   if(range_atr <= 10.0)
      return 10.0;
   return 0.0;
}

double DirectionalMovementScore(const int index, const int direction)
{
   double atr_pips = MathMax(g_profiles[index].atr_m1 / g_profiles[index].pip_size, 0.1);

   double m5 = DirectionalValue(g_profiles[index].speed_5s_pips, direction);
   double m10 = DirectionalValue(g_profiles[index].speed_10s_pips, direction);
   double m30 = DirectionalValue(g_profiles[index].speed_30s_pips, direction);

   double s5 = LinearScore(m5 / atr_pips, 0.02, 0.16);
   double s10 = LinearScore(m10 / atr_pips, 0.04, 0.28);
   double s30 = LinearScore(m30 / atr_pips, 0.08, 0.55);

   return Clamp(s5 * 0.35 + s10 * 0.35 + s30 * 0.30, 0.0, 100.0);
}

double TickVolumeScore(const int index)
{
   double average_volume = g_profiles[index].average_m1_tick_volume;
   if(average_volume <= 0.0)
      return 45.0;

   double active_volume = MathMax(g_profiles[index].current_m1_tick_volume,
                                  g_profiles[index].last_completed_m1_tick_volume * 0.85);
   double ratio = active_volume / average_volume;
   return LinearScore(ratio, 0.70, 2.20);
}

double OutsideHoldScore(const int index, const int direction)
{
   datetime outside_since = (direction == DIR_UP ?
                             g_profiles[index].outside_since_up :
                             g_profiles[index].outside_since_down);
   if(outside_since <= 0)
      return 0.0;

   int seconds = (int)(TimeCurrent() - outside_since);
   if(seconds >= 8)
      return 100.0;
   if(seconds >= 4)
      return 75.0;
   if(seconds >= 2)
      return 45.0;
   return 20.0;
}

double CurrencyConfirmationScore(const int index, const int direction)
{
   if(!UseCurrencyStrength)
      return 65.0;

   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   if(base < 0 || quote < 0)
      return 55.0;

   double delta = (g_currency_strength[base] - g_currency_strength[quote]) * (double)direction;
   return Clamp(55.0 + delta * 35.0, 0.0, 100.0);
}

double SpreadQualityScore(const int index)
{
   double spread = g_profiles[index].spread_pips;
   if(spread <= 0.0 || spread > MaxSpreadPips)
      return 0.0;

   double median = g_profiles[index].median_spread_pips;
   if(median <= 0.0)
      median = spread;

   double absolute_score = 100.0 - LinearScore(spread, MaxSpreadPips * 0.45, MaxSpreadPips) * 0.85;
   double relative_score = 100.0 - LinearScore(spread / MathMax(median, 0.1), 1.0,
                                               MaxSpreadMedianMultiplier) * 0.80;
   return Clamp(MathMin(absolute_score, relative_score), 0.0, 100.0);
}

double CandleExpansionScore(const int index, const int direction)
{
   if(g_profiles[index].atr_m1 <= 0.0)
      return 0.0;

   double body_move = (g_profiles[index].current_m1_close - g_profiles[index].current_m1_open) *
                      (double)direction;
   double full_push = 0.0;

   if(direction == DIR_UP)
      full_push = g_profiles[index].current_m1_high - g_profiles[index].current_m1_open;
   else
      full_push = g_profiles[index].current_m1_open - g_profiles[index].current_m1_low;

   double body_score = LinearScore(body_move / g_profiles[index].atr_m1, 0.05, 0.85);
   double push_score = LinearScore(full_push / g_profiles[index].atr_m1, 0.10, 1.10);
   return Clamp(body_score * 0.55 + push_score * 0.45, 0.0, 100.0);
}

double ContinuationScore(const int index, const int direction)
{
   if(g_profiles[index].snapshot_count < 3)
      return 35.0;

   double old_mid = ReferenceMid(index, 30);
   if(old_mid <= 0.0)
      return 35.0;

   double extreme = RecentExtremeMid(index, 30, direction);
   double move_to_extreme = (extreme - old_mid) * (double)direction;
   double retrace = (extreme - g_profiles[index].mid) * (double)direction;

   if(move_to_extreme <= 0.0)
      return 0.0;

   double retained = 1.0 - retrace / move_to_extreme;
   double retention_score = LinearScore(retained, 0.35, 0.90);
   double short_push = LinearScore(DirectionalValue(g_profiles[index].speed_5s_pips, direction), 0.0,
                                  MathMax(g_profiles[index].atr_m1 / g_profiles[index].pip_size * 0.12, 0.4));
   return Clamp(retention_score * 0.70 + short_push * 0.30, 0.0, 100.0);
}

double MovementPips(const int index, const int seconds_back)
{
   if(g_profiles[index].snapshot_count <= 0 || g_profiles[index].pip_size <= 0.0)
      return 0.0;

   double reference_mid = ReferenceMid(index, seconds_back);
   if(reference_mid <= 0.0)
      return 0.0;

   return (g_profiles[index].mid - reference_mid) / g_profiles[index].pip_size;
}

double ReferenceMid(const int index, const int seconds_back)
{
   int count = g_profiles[index].snapshot_count;
   if(count <= 0)
      return 0.0;

   long target = g_profiles[index].quote_time_msc - (long)seconds_back * 1000;
   double reference_mid = 0.0;

   for(int logical = 0; logical < count; logical++)
   {
      int position = LogicalSnapshotPosition(index, logical);
      int sample_index = SnapshotIndex(index, position);
      if(g_snapshots[sample_index].time_msc <= 0)
         continue;

      if(g_snapshots[sample_index].time_msc <= target)
         reference_mid = g_snapshots[sample_index].mid;
      else
         break;
   }

   if(reference_mid <= 0.0)
   {
      int oldest = SnapshotIndex(index, LogicalSnapshotPosition(index, 0));
      reference_mid = g_snapshots[oldest].mid;
   }

   return reference_mid;
}

double RecentExtremeMid(const int index, const int seconds_back, const int direction)
{
   int count = g_profiles[index].snapshot_count;
   if(count <= 0)
      return g_profiles[index].mid;

   long min_time = g_profiles[index].quote_time_msc - (long)seconds_back * 1000;
   double extreme = g_profiles[index].mid;

   for(int logical = 0; logical < count; logical++)
   {
      int position = LogicalSnapshotPosition(index, logical);
      int sample_index = SnapshotIndex(index, position);
      if(g_snapshots[sample_index].time_msc < min_time)
         continue;

      if(direction == DIR_UP)
         extreme = MathMax(extreme, g_snapshots[sample_index].mid);
      else
         extreme = MathMin(extreme, g_snapshots[sample_index].mid);
   }

   return extreme;
}

int SnapshotIndex(const int symbol_index, const int position)
{
   return symbol_index * SNAPSHOT_CAPACITY + position;
}

int SpreadIndex(const int symbol_index, const int position)
{
   return symbol_index * SPREAD_HISTORY_CAPACITY + position;
}

int LogicalSnapshotPosition(const int symbol_index, const int logical_index)
{
   int count = g_profiles[symbol_index].snapshot_count;
   int start = g_profiles[symbol_index].snapshot_write_index - count;
   while(start < 0)
      start += SNAPSHOT_CAPACITY;
   return (start + logical_index) % SNAPSHOT_CAPACITY;
}

int LogicalSpreadPosition(const int symbol_index, const int logical_index)
{
   int count = g_profiles[symbol_index].spread_count;
   int start = g_profiles[symbol_index].spread_write_index - count;
   while(start < 0)
      start += SPREAD_HISTORY_CAPACITY;
   return (start + logical_index) % SPREAD_HISTORY_CAPACITY;
}

bool FindBaseQuoteCurrencies(const string symbol, int &base_index, int &quote_index)
{
   string upper = UpperAscii(symbol);
   int best_base = -1;
   int best_quote = -1;
   int best_base_pos = 100000;
   int best_quote_pos = 100000;

   for(int base = 0; base < CURRENCY_COUNT; base++)
   {
      int base_pos = StringFind(upper, g_currency_codes[base]);
      if(base_pos < 0)
         continue;

      for(int quote = 0; quote < CURRENCY_COUNT; quote++)
      {
         if(quote == base)
            continue;

         int quote_pos = StringFind(upper, g_currency_codes[quote], base_pos + 3);
         if(quote_pos < 0)
            continue;

         if(base_pos < best_base_pos ||
            (base_pos == best_base_pos && quote_pos < best_quote_pos))
         {
            best_base = base;
            best_quote = quote;
            best_base_pos = base_pos;
            best_quote_pos = quote_pos;
         }
      }
   }

   base_index = best_base;
   quote_index = best_quote;
   return (base_index >= 0 && quote_index >= 0);
}

string UpperAscii(string value)
{
   int length = StringLen(value);
   for(int i = 0; i < length; i++)
   {
      ushort ch = StringGetCharacter(value, i);
      if(ch >= 97 && ch <= 122)
         StringSetCharacter(value, i, (ushort)(ch - 32));
   }
   return value;
}

bool IsRolloverTime(const datetime now)
{
   int start_hour = NormalizeHour(RolloverStartHourServer);
   int end_hour = NormalizeHour(RolloverEndHourServer);

   MqlDateTime parts;
   TimeToStruct(now, parts);
   int hour = parts.hour;

   if(start_hour == end_hour)
      return false;

   if(start_hour < end_hour)
      return (hour >= start_hour && hour < end_hour);

   return (hour >= start_hour || hour < end_hour);
}

int NormalizeHour(const int hour)
{
   int normalized = hour % 24;
   if(normalized < 0)
      normalized += 24;
   return normalized;
}

double PipSize(const double point, const int digits)
{
   if(digits == 3 || digits == 5)
      return point * 10.0;
   return point;
}

double DirectionalValue(const double value, const int direction)
{
   return value * (double)direction;
}

double LinearScore(const double value, const double zero_level, const double full_level)
{
   if(full_level <= zero_level)
      return 0.0;
   if(value <= zero_level)
      return 0.0;
   if(value >= full_level)
      return 100.0;
   return (value - zero_level) / (full_level - zero_level) * 100.0;
}

double Clamp(const double value, const double min_value, const double max_value)
{
   if(value < min_value)
      return min_value;
   if(value > max_value)
      return max_value;
   return value;
}

double Max3(const double a, const double b, const double c)
{
   return MathMax(a, MathMax(b, c));
}

int IntMax(const int a, const int b)
{
   return (a > b ? a : b);
}

int IntMin(const int a, const int b)
{
   return (a < b ? a : b);
}

int IntAbs(const int value)
{
   return (value < 0 ? -value : value);
}
