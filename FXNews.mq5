#property strict
#property description "Chart-only multi-symbol breakout radar. No trade execution."

input string SymbolsToScan =
"EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,NZDUSD,USDCAD,EURJPY,GBPJPY,EURGBP,EURAUD,EURNZD,EURCAD,EURCHF,GBPAUD,GBPNZD,GBPCAD,GBPCHF,AUDJPY,NZDJPY,CADJPY,CHFJPY,AUDNZD,AUDCAD,AUDCHF,NZDCAD,NZDCHF,CADCHF";
input string TimeframesToScan = "M1,M5,M15,M30,H1,H4,H8,H12,D1";

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

input bool UseStrictExecutionGate = true;
input double MaxSpreadToAtrRatio = 0.45;
input double MaxTickGapSeconds = 8.0;
input double MaxSpreadZScore = 3.0;

input int MinHoldSecondsForHighScore = 3;
input int FullHoldScoreSeconds = 12;
input double MaxOverextensionAtr = 1.8;

input double MinImpulseZForSignal = 1.25;
input double MaxExhaustionAtr = 2.2;
input bool UseTickRateScoring = true;

input bool UseRobustCurrencyStrength = true;
input double MinBasketAgreementForHighScore = 0.60;
input double MinDirectionalEdgeForHighScore = 0.20;

input bool UseEconomicCalendarContext = false;
input int CalendarLookbackMinutes = 10;
input int CalendarLookaheadMinutes = 30;
input bool CalendarHighImpactOnly = true;
input bool BlockImmediatelyBeforeHighImpactNews = false;
input int CalendarPreNewsBlockMinutes = 3;

input bool UseMultiTimeframeContextCaps = true;
input double M5RejectAtr = -0.35;
input double M15RejectAtr = -0.25;

input bool EnableSignalLogging = true;
input bool EnableOutcomeLabeling = true;
input string SignalLogFile = "FXNews_signals.csv";
input int OutcomeHorizonMinutes1 = 5;
input int OutcomeHorizonMinutes2 = 15;
input int OutcomeHorizonMinutes3 = 30;
input double OutcomeTargetAtr = 0.50;
input double OutcomeStopAtr = 0.35;

input bool UseScoreCalibrationFile = false;
input string ScoreCalibrationFile = "FXNews_calibration.csv";
input int MinCalibrationSamples = 50;

input bool DebugScoreBreakdown = false;
input bool DebugPrintToJournal = false;

#define DIR_NONE 0
#define DIR_UP 1
#define DIR_DOWN -1
#define SNAPSHOT_CAPACITY 90
#define SPREAD_HISTORY_CAPACITY 80
#define CURRENCY_COUNT 8
#define DASHBOARD_MAX_OBJECTS 40
#define SIGNAL_HISTORY_SIZE 5
#define MAX_PENDING_OUTCOMES 500
#define CALENDAR_REFRESH_SECONDS 60

enum BreakoutEventState
{
   STATE_IDLE = 0,
   STATE_WATCH = 1,
   STATE_CANDIDATE = 2,
   STATE_ACTIVE_SIGNAL = 3,
   STATE_COOLDOWN = 4
};

enum SignalBlockReason
{
   BLOCK_NONE = 0,
   BLOCK_STALE_QUOTE = 1,
   BLOCK_BAD_SPREAD = 2,
   BLOCK_ROLLOVER = 3,
   BLOCK_NO_ATR = 4,
   BLOCK_NO_RANGE = 5,
   BLOCK_NO_MOVEMENT_DATA = 6,
   BLOCK_FAKEOUT = 7,
   BLOCK_CONTEXT_CONFLICT = 8
};

struct FeatureScore
{
   double value;      // normalized 0..1
   double weight;     // composite contribution weight
   string name;
};

struct ExecutionQuality
{
   bool pass;
   double score;              // 0..1
   double spread_pips;
   double median_spread_pips;
   double spread_ratio;
   double spread_z;
   double quote_age_sec;
   double tick_gap_sec;
   double cost_to_atr;
   SignalBlockReason block_reason;
};

struct BreakoutStructure
{
   bool pass;
   double score;              // 0..1
   double compression_score;
   double distance_score;
   double close_location_score;
   double hold_score;
   double body_quality_score;
   double wick_rejection_penalty;
   double fakeout_penalty;
};

struct ImpulseQuality
{
   bool pass;
   double score;              // 0..1
   double speed_5s_z;
   double speed_10s_z;
   double speed_30s_z;
   double speed_60s_z;
   double acceleration_score;
   double atr_expansion_score;
   double tick_rate_z;
   double tick_volume_z;
   double exhaustion_penalty;
};

struct CurrencyFlowQuality
{
   bool pass;
   double score;              // 0..1
   double base_strength;
   double quote_strength;
   double directional_edge;
   double basket_agreement;
   double conflict_penalty;
};

struct RegimeContext
{
   bool pass;
   double score;              // 0..1
   double session_score;
   double mtf_alignment_score;
   double m5_context_score;
   double m15_context_score;
   double volatility_regime_score;
   double rollover_penalty;
};

struct CalendarContext
{
   bool available;
   bool relevant_event_nearby;
   bool high_impact_nearby;
   bool just_released;
   double score;              // 0..1
   double proximity_minutes;
   double importance_score;
   double surprise_score;
   double uncertainty_penalty;
};

struct CompositeSignalScore
{
   bool valid;
   int direction;
   double raw_score;          // 0..100 before calibration/caps
   double calibrated_score;   // 0..100 after optional calibration
   double displayed_score;    // rounded dashboard score source
   ExecutionQuality execution;
   BreakoutStructure breakout;
   ImpulseQuality impulse;
   CurrencyFlowQuality flow;
   RegimeContext regime;
   CalendarContext calendar;
   SignalBlockReason block_reason;
   string reason_summary;
};

struct PendingOutcome
{
   bool active;
   string signal_id;
   string symbol;
   string timeframe_label;
   int direction;
   datetime signal_server_time;
   datetime signal_local_time;
   double entry_mid;
   double atr_price;
   double pip_size;
   double mfe_pips;
   double mae_pips;
   bool horizon1_written;
   bool horizon2_written;
   bool horizon3_written;
};

struct CalibrationEntry
{
   string symbol;
   string timeframe_label;
   string session_name;
   int score_bucket;
   double calibrated_score;
   int sample_count;
};

struct CurrencyCalendarCache
{
   string currency;
   datetime refreshed_at;
   bool available;
   bool relevant_event_nearby;
   bool high_impact_nearby;
   bool just_released;
   double score;
   double proximity_minutes;
   double importance_score;
   double uncertainty_penalty;
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
   string timeframe_label;
   int direction;
   datetime local_time;
   double score;
   string text;
};

struct SymbolProfile
{
   string symbol;
   ENUM_TIMEFRAMES scan_timeframe;
   string timeframe_label;
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
   double spread_z;
   double tick_gap_sec;
   double tick_rate_per_sec;

   // M1-named fields hold the trigger timeframe data for each scan profile.
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
   CompositeSignalScore composite_up;
   CompositeSignalScore composite_down;

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
   datetime reentered_since_up;
   datetime reentered_since_down;

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
ENUM_TIMEFRAMES g_scan_timeframes[];
string g_scan_timeframe_labels[];
double g_currency_strength[CURRENCY_COUNT];
int g_currency_samples[CURRENCY_COUNT];
double g_currency_weight[CURRENCY_COUNT];
string g_currency_codes[CURRENCY_COUNT] = {"EUR","USD","GBP","JPY","CHF","AUD","NZD","CAD"};
PendingOutcome g_pending_outcomes[];
CalibrationEntry g_calibration_entries[];
CurrencyCalendarCache g_calendar_cache[CURRENCY_COUNT];
long g_signal_sequence = 0;
bool g_calibration_warning_printed = false;
bool g_signal_log_header_checked = false;

datetime g_last_dashboard_update = 0;
string g_object_prefix = "COBR_";

int OnInit()
{
   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   g_object_prefix = "COBR_" + IntegerToString((int)(ChartID() % 1000000)) + "_";

   if(ParseSymbols() <= 0)
   {
      Print("FXNews: no valid symbols were provided.");
      return INIT_PARAMETERS_INCORRECT;
   }

   InitializeCalendarCache();
   LoadScoreCalibration();
   ArrayResize(g_pending_outcomes, 0);

   AllocateHistoryBuffers();

   for(int i = 0; i < ArraySize(g_profiles); i++)
      EnsureSymbolReady(i);

   ResetLastError();
   if(!EventSetTimer(IntMax(1, ScanIntervalSeconds)))
   {
      PrintFormat("FXNews: EventSetTimer failed, error %d", GetLastError());
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
      Print("FXNews: scan, display, and quote-age inputs must be positive.");
      return false;
   }

   if(MinDisplayConfidence < 1.0 || MinDisplayConfidence > 99.0 ||
      StrongAlertConfidence < MinDisplayConfidence || StrongAlertConfidence > 100.0)
   {
      Print("FXNews: confidence inputs are inconsistent.");
      return false;
   }

   if(RangeLookbackM1 < 10 || ATRPeriod < 2 ||
      BreakoutBufferATR < 0.0 || MinBreakoutBufferPips < 0.0)
   {
      Print("FXNews: range and ATR inputs are outside supported bounds.");
      return false;
   }

   if(MaxSpreadPips <= 0.0 || MaxSpreadMedianMultiplier <= 1.0)
   {
      Print("FXNews: spread filters are outside supported bounds.");
      return false;
   }

   if(FailedSignalCooldownSeconds < 1 || ValidSignalCooldownSeconds < 1)
   {
      Print("FXNews: cooldown inputs must be positive.");
      return false;
   }

   if(MaxSpreadToAtrRatio <= 0.0 || MaxTickGapSeconds <= 0.0 || MaxSpreadZScore <= 0.0)
   {
      Print("FXNews: execution gate inputs must be positive.");
      return false;
   }

   if(MinHoldSecondsForHighScore < 0 || FullHoldScoreSeconds < 1 ||
      FullHoldScoreSeconds < MinHoldSecondsForHighScore || MaxOverextensionAtr <= 0.0)
   {
      Print("FXNews: breakout-quality inputs are outside supported bounds.");
      return false;
   }

   if(MinImpulseZForSignal < 0.0 || MaxExhaustionAtr <= 0.0 ||
      MinBasketAgreementForHighScore < 0.0 || MinBasketAgreementForHighScore > 1.0 ||
      MinDirectionalEdgeForHighScore < 0.0)
   {
      Print("FXNews: impulse or basket-quality inputs are outside supported bounds.");
      return false;
   }

   if(CalendarLookbackMinutes < 0 || CalendarLookaheadMinutes < 0 || CalendarPreNewsBlockMinutes < 0)
   {
      Print("FXNews: calendar inputs must not be negative.");
      return false;
   }

   if(OutcomeHorizonMinutes1 < 1 || OutcomeHorizonMinutes2 < OutcomeHorizonMinutes1 ||
      OutcomeHorizonMinutes3 < OutcomeHorizonMinutes2 || OutcomeTargetAtr <= 0.0 ||
      OutcomeStopAtr <= 0.0 || MinCalibrationSamples < 1)
   {
      Print("FXNews: logging/outcome inputs are inconsistent.");
      return false;
   }

   return true;
}

int ParseSymbols()
{
   ArrayResize(g_profiles, 0);
   if(ParseTimeframes() <= 0)
   {
      Print("FXNews: no valid scan timeframes were provided.");
      return 0;
   }

   string cleaned = SymbolsToScan;
   StringReplace(cleaned, ";", ",");
   StringReplace(cleaned, "\r", ",");
   StringReplace(cleaned, "\n", ",");
   StringReplace(cleaned, "\t", ",");

   string parts[];
   ushort comma = StringGetCharacter(",", 0);
   int total = StringSplit(cleaned, comma, parts);
   string symbols[];

   for(int i = 0; i < total; i++)
   {
      string token = parts[i];
      StringTrimLeft(token);
      StringTrimRight(token);
      if(token == "")
         continue;

      AddUniqueSymbol(symbols, token);
   }

   for(int symbol_index = 0; symbol_index < ArraySize(symbols); symbol_index++)
   {
      for(int timeframe_index = 0; timeframe_index < ArraySize(g_scan_timeframes); timeframe_index++)
      {
         int next = ArraySize(g_profiles);
         ArrayResize(g_profiles, next + 1);
         ResetProfile(g_profiles[next],
                      symbols[symbol_index],
                      g_scan_timeframes[timeframe_index],
                      g_scan_timeframe_labels[timeframe_index]);
      }
   }

   return ArraySize(g_profiles);
}

int ParseTimeframes()
{
   ArrayResize(g_scan_timeframes, 0);
   ArrayResize(g_scan_timeframe_labels, 0);

   string cleaned = TimeframesToScan;
   StringReplace(cleaned, ";", ",");
   StringReplace(cleaned, "\r", ",");
   StringReplace(cleaned, "\n", ",");
   StringReplace(cleaned, "\t", ",");
   StringReplace(cleaned, " ", "");

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

      ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
      string label = "";
      if(!ParseTimeframeToken(token, timeframe, label))
      {
         PrintFormat("FXNews: unsupported timeframe token '%s' skipped.", token);
         continue;
      }

      if(TimeframeAlreadyAdded(timeframe))
         continue;

      int next = ArraySize(g_scan_timeframes);
      ArrayResize(g_scan_timeframes, next + 1);
      ArrayResize(g_scan_timeframe_labels, next + 1);
      g_scan_timeframes[next] = timeframe;
      g_scan_timeframe_labels[next] = label;
   }

   return ArraySize(g_scan_timeframes);
}

bool ParseTimeframeToken(const string raw_token,
                         ENUM_TIMEFRAMES &timeframe,
                         string &label)
{
   string token = UpperAscii(raw_token);
   StringReplace(token, "_", "");
   StringReplace(token, "PERIOD", "");

   if(token == "1" || token == "M1")
   {
      timeframe = PERIOD_M1;
      label = "M1";
      return true;
   }
   if(token == "5" || token == "M5")
   {
      timeframe = PERIOD_M5;
      label = "M5";
      return true;
   }
   if(token == "15" || token == "M15")
   {
      timeframe = PERIOD_M15;
      label = "M15";
      return true;
   }
   if(token == "30" || token == "M30")
   {
      timeframe = PERIOD_M30;
      label = "M30";
      return true;
   }
   if(token == "60" || token == "H1")
   {
      timeframe = PERIOD_H1;
      label = "H1";
      return true;
   }
   if(token == "240" || token == "H4")
   {
      timeframe = PERIOD_H4;
      label = "H4";
      return true;
   }
   if(token == "480" || token == "H8")
   {
      timeframe = PERIOD_H8;
      label = "H8";
      return true;
   }
   if(token == "720" || token == "H12")
   {
      timeframe = PERIOD_H12;
      label = "H12";
      return true;
   }
   if(token == "1440" || token == "D1")
   {
      timeframe = PERIOD_D1;
      label = "D1";
      return true;
   }

   return false;
}

bool TimeframeAlreadyAdded(const ENUM_TIMEFRAMES timeframe)
{
   for(int i = 0; i < ArraySize(g_scan_timeframes); i++)
   {
      if(g_scan_timeframes[i] == timeframe)
         return true;
   }
   return false;
}

bool AddUniqueSymbol(string &symbols[], const string symbol)
{
   string candidate = UpperAscii(symbol);
   for(int i = 0; i < ArraySize(symbols); i++)
   {
      if(UpperAscii(symbols[i]) == candidate)
         return false;
   }

   int next = ArraySize(symbols);
   ArrayResize(symbols, next + 1);
   symbols[next] = symbol;
   return true;
}

void ResetProfile(SymbolProfile &profile,
                  const string symbol,
                  const ENUM_TIMEFRAMES scan_timeframe,
                  const string timeframe_label)
{
   profile.symbol = symbol;
   profile.scan_timeframe = scan_timeframe;
   profile.timeframe_label = timeframe_label;
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
   profile.spread_z = 0.0;
   profile.tick_gap_sec = 0.0;
   profile.tick_rate_per_sec = 0.0;

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
   ResetCompositeSignalScore(profile.composite_up, DIR_UP);
   ResetCompositeSignalScore(profile.composite_down, DIR_DOWN);

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
   profile.reentered_since_up = 0;
   profile.reentered_since_down = 0;

   profile.snapshot_write_index = 0;
   profile.snapshot_count = 0;
   profile.spread_write_index = 0;
   profile.spread_count = 0;

   profile.status_message = "";
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

   UpdatePendingOutcomes(now);

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
         SymbolTimeframeUsedByAnotherProfile(index, resolved_symbol, g_profiles[index].scan_timeframe))
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

   if(SymbolTimeframeUsedByAnotherProfile(index, symbol, g_profiles[index].scan_timeframe))
   {
      g_profiles[index].valid = false;
      g_profiles[index].selected = false;
      g_profiles[index].status_message = StringFormat("%s %s: duplicate resolved scan profile.",
                                                      symbol, g_profiles[index].timeframe_label);
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

bool SymbolTimeframeUsedByAnotherProfile(const int current_index,
                                         const string symbol,
                                         const ENUM_TIMEFRAMES timeframe)
{
   string target = UpperAscii(symbol);
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(i == current_index)
         continue;
      if(UpperAscii(g_profiles[i].symbol) == target &&
         g_profiles[i].scan_timeframe == timeframe &&
         g_profiles[i].selected)
      {
         return true;
      }
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

   g_profiles[index].tick_gap_sec = TickGapSeconds(index, g_profiles[index].quote_time_msc);

   g_profiles[index].quote_fresh = (now - tick.time <= MaxQuoteAgeSeconds);
   g_profiles[index].bid = tick.bid;
   g_profiles[index].ask = tick.ask;
   g_profiles[index].last_mid = g_profiles[index].mid;
   g_profiles[index].mid = (tick.bid + tick.ask) * 0.5;
   g_profiles[index].spread_pips = (tick.ask - tick.bid) / g_profiles[index].pip_size;

   AddSnapshot(index, g_profiles[index].quote_time_msc, g_profiles[index].mid);
   AddSpreadSample(index, g_profiles[index].spread_pips);
   g_profiles[index].median_spread_pips = CalculateMedianSpread(index);
   g_profiles[index].spread_z = SpreadRobustZ(index);
   g_profiles[index].tick_rate_per_sec = TickRateFromSnapshots(index, 30);

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
   g_profiles[index].tick_gap_sec = 0.0;
   g_profiles[index].tick_rate_per_sec = 0.0;
}

void UpdateRatesData(const int index)
{
   string symbol = g_profiles[index].symbol;
   int need_trigger = IntMax(RangeLookbackM1 + ATRPeriod + 20, 80);
   int min_trigger = IntMax(RangeLookbackM1 + 2, ATRPeriod + 3);

   MqlRates trigger_rates[];
   ArraySetAsSeries(trigger_rates, true);
   int copied_trigger = CopyRates(symbol, g_profiles[index].scan_timeframe, 0, need_trigger, trigger_rates);
   g_profiles[index].has_m1 = (copied_trigger >= min_trigger);

   if(g_profiles[index].has_m1)
   {
      g_profiles[index].atr_m1 = CalculateATRFromRates(trigger_rates, copied_trigger, ATRPeriod);
      BuildRangeBox(index, trigger_rates, copied_trigger);
      g_profiles[index].current_m1_open = trigger_rates[0].open;
      g_profiles[index].current_m1_high = trigger_rates[0].high;
      g_profiles[index].current_m1_low = trigger_rates[0].low;
      g_profiles[index].current_m1_close = trigger_rates[0].close;
      g_profiles[index].current_m1_tick_volume = (double)trigger_rates[0].tick_volume;
      g_profiles[index].last_completed_m1_tick_volume = (double)trigger_rates[1].tick_volume;
      g_profiles[index].average_m1_tick_volume = AverageTickVolume(trigger_rates, copied_trigger);
   }
   else
   {
      g_profiles[index].atr_m1 = 0.0;
      g_profiles[index].range_high = 0.0;
      g_profiles[index].range_low = 0.0;
      g_profiles[index].range_width = 0.0;
   }

   int context_source = FindFreshContextProfile(index);
   if(context_source >= 0)
   {
      CopyContextRatesData(index, context_source);
      return;
   }

   MqlRates short_m1[];
   ArraySetAsSeries(short_m1, true);
   int copied_short_m1 = CopyRates(symbol, PERIOD_M1, 0, 20, short_m1);
   if(copied_short_m1 > 5)
      g_profiles[index].movement_5m_pips = (g_profiles[index].mid - short_m1[5].close) / g_profiles[index].pip_size;
   else
      g_profiles[index].movement_5m_pips = 0.0;

   if(copied_short_m1 > 15)
      g_profiles[index].movement_15m_pips = (g_profiles[index].mid - short_m1[15].close) / g_profiles[index].pip_size;
   else
      g_profiles[index].movement_15m_pips = g_profiles[index].movement_5m_pips;

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

int FindFreshContextProfile(const int index)
{
   string symbol = UpperAscii(g_profiles[index].symbol);
   long quote_time_msc = g_profiles[index].quote_time_msc;
   if(quote_time_msc <= 0)
      return -1;

   for(int i = index - 1; i >= 0; i--)
   {
      if(UpperAscii(g_profiles[i].symbol) != symbol)
         continue;
      if(g_profiles[i].quote_time_msc != quote_time_msc)
         continue;
      return i;
   }

   return -1;
}

void CopyContextRatesData(const int target_index, const int source_index)
{
   g_profiles[target_index].movement_5m_pips = g_profiles[source_index].movement_5m_pips;
   g_profiles[target_index].movement_15m_pips = g_profiles[source_index].movement_15m_pips;
   g_profiles[target_index].has_m5 = g_profiles[source_index].has_m5;
   g_profiles[target_index].atr_m5 = g_profiles[source_index].atr_m5;
   g_profiles[target_index].m5_move_atr = g_profiles[source_index].m5_move_atr;
   g_profiles[target_index].has_m15 = g_profiles[source_index].has_m15;
   g_profiles[target_index].m15_move_atr = g_profiles[source_index].m15_move_atr;
}

void BuildRangeBox(const int index, MqlRates &rates[], const int copied)
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

double AverageTickVolume(MqlRates &rates[], const int copied)
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
   {
      if(g_profiles[index].outside_since_up > 0)
         g_profiles[index].reentered_since_up = now;
      g_profiles[index].outside_since_up = 0;
   }

   if(g_profiles[index].mid < down_boundary)
   {
      if(g_profiles[index].outside_since_down == 0)
         g_profiles[index].outside_since_down = now;
   }
   else
   {
      if(g_profiles[index].outside_since_down > 0)
         g_profiles[index].reentered_since_down = now;
      g_profiles[index].outside_since_down = 0;
   }
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
      g_currency_weight[i] = 0.0;
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

      if(g_profiles[i].spread_pips <= 0.0 || g_profiles[i].spread_pips > MaxSpreadPips ||
         (g_profiles[i].median_spread_pips > 0.0 &&
          g_profiles[i].spread_pips > g_profiles[i].median_spread_pips * MaxSpreadMedianMultiplier))
      {
         continue;
      }

      double atr_pips = MathMax(g_profiles[i].atr_m1 / g_profiles[i].pip_size, 0.1);
      double n30 = Clamp(g_profiles[i].speed_30s_pips / (atr_pips * 0.35), -1.5, 1.5);
      double n60 = Clamp(g_profiles[i].speed_60s_pips / (atr_pips * 0.55), -1.5, 1.5);
      double n5m = Clamp(g_profiles[i].movement_5m_pips / (atr_pips * 1.50), -1.5, 1.5);
      double pair_strength = n30 * 0.45 + n60 * 0.25 + n5m * 0.30;
      double weight = 1.0;
      if(UseRobustCurrencyStrength)
      {
         double spread_penalty = 1.0 / MathMax(1.0, g_profiles[i].spread_pips / MathMax(g_profiles[i].median_spread_pips, 0.1));
         weight = spread_penalty / MathMax(atr_pips, 0.5);
         weight = Clamp(weight, 0.05, 2.0);
      }

      int base = g_profiles[i].base_index;
      int quote = g_profiles[i].quote_index;
      g_currency_strength[base] += pair_strength * weight;
      g_currency_strength[quote] -= pair_strength * weight;
      g_currency_weight[base] += weight;
      g_currency_weight[quote] += weight;
      g_currency_samples[base]++;
      g_currency_samples[quote]++;
   }

   for(int i = 0; i < CURRENCY_COUNT; i++)
   {
      if(g_currency_weight[i] > 0.0)
         g_currency_strength[i] /= g_currency_weight[i];
      else if(g_currency_samples[i] > 0)
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
   ResetCompositeSignalScore(g_profiles[index].composite_up, DIR_UP);
   ResetCompositeSignalScore(g_profiles[index].composite_down, DIR_DOWN);

   BuildCompositeSignalScore(index, DIR_UP, now, g_profiles[index].composite_up);
   BuildCompositeSignalScore(index, DIR_DOWN, now, g_profiles[index].composite_down);

   g_profiles[index].technical_score_up = g_profiles[index].composite_up.breakout.score * 100.0;
   g_profiles[index].technical_score_down = g_profiles[index].composite_down.breakout.score * 100.0;
   g_profiles[index].impulse_score_up = g_profiles[index].composite_up.impulse.score * 100.0;
   g_profiles[index].impulse_score_down = g_profiles[index].composite_down.impulse.score * 100.0;

   if(g_profiles[index].composite_up.valid)
      g_profiles[index].final_score_up = g_profiles[index].composite_up.displayed_score;
   if(g_profiles[index].composite_down.valid)
      g_profiles[index].final_score_down = g_profiles[index].composite_down.displayed_score;

   UpdateSignalState(index, now);
}

void ResetCompositeSignalScore(CompositeSignalScore &score, const int direction)
{
   score.valid = false;
   score.direction = direction;
   score.raw_score = 0.0;
   score.calibrated_score = 0.0;
   score.displayed_score = 0.0;
   score.block_reason = BLOCK_NONE;
   score.reason_summary = "";

   score.execution.pass = false;
   score.execution.score = 0.0;
   score.execution.spread_pips = 0.0;
   score.execution.median_spread_pips = 0.0;
   score.execution.spread_ratio = 0.0;
   score.execution.spread_z = 0.0;
   score.execution.quote_age_sec = 0.0;
   score.execution.tick_gap_sec = 0.0;
   score.execution.cost_to_atr = 0.0;
   score.execution.block_reason = BLOCK_NONE;

   score.breakout.pass = false;
   score.breakout.score = 0.0;
   score.breakout.compression_score = 0.0;
   score.breakout.distance_score = 0.0;
   score.breakout.close_location_score = 0.0;
   score.breakout.hold_score = 0.0;
   score.breakout.body_quality_score = 0.0;
   score.breakout.wick_rejection_penalty = 0.0;
   score.breakout.fakeout_penalty = 0.0;

   score.impulse.pass = false;
   score.impulse.score = 0.0;
   score.impulse.speed_5s_z = 0.0;
   score.impulse.speed_10s_z = 0.0;
   score.impulse.speed_30s_z = 0.0;
   score.impulse.speed_60s_z = 0.0;
   score.impulse.acceleration_score = 0.0;
   score.impulse.atr_expansion_score = 0.0;
   score.impulse.tick_rate_z = 0.0;
   score.impulse.tick_volume_z = 0.0;
   score.impulse.exhaustion_penalty = 0.0;

   score.flow.pass = false;
   score.flow.score = 0.0;
   score.flow.base_strength = 0.0;
   score.flow.quote_strength = 0.0;
   score.flow.directional_edge = 0.0;
   score.flow.basket_agreement = 0.0;
   score.flow.conflict_penalty = 0.0;

   score.regime.pass = false;
   score.regime.score = 0.0;
   score.regime.session_score = 0.0;
   score.regime.mtf_alignment_score = 0.0;
   score.regime.m5_context_score = 0.0;
   score.regime.m15_context_score = 0.0;
   score.regime.volatility_regime_score = 0.0;
   score.regime.rollover_penalty = 0.0;

   score.calendar.available = false;
   score.calendar.relevant_event_nearby = false;
   score.calendar.high_impact_nearby = false;
   score.calendar.just_released = false;
   score.calendar.score = 0.0;
   score.calendar.proximity_minutes = 0.0;
   score.calendar.importance_score = 0.0;
   score.calendar.surprise_score = 0.0;
   score.calendar.uncertainty_penalty = 0.0;
}

void BuildCompositeSignalScore(const int index,
                               const int direction,
                               const datetime now,
                               CompositeSignalScore &score)
{
   ResetCompositeSignalScore(score, direction);

   EvaluateExecutionQuality(index, now, score.execution);
   if(!score.execution.pass)
   {
      score.block_reason = score.execution.block_reason;
      score.reason_summary = "blocked=" + BlockReasonText(score.block_reason);
      return;
   }

   EvaluateBreakoutStructure(index, direction, now, score.breakout);
   EvaluateImpulseQuality(index, direction, score.impulse);
   EvaluateCurrencyFlowQuality(index, direction, score.flow);
   EvaluateRegimeContext(index, direction, now, score.regime);
   EvaluateCalendarContext(index, direction, now, score.calendar);

   if(CalendarPreNewsBlock(score.calendar))
   {
      score.block_reason = BLOCK_CONTEXT_CONFLICT;
      score.reason_summary = "blocked=calendar_pre_news";
      return;
   }

   bool engine_pass = ((UseTechnicalBreakoutEngine && score.breakout.pass) ||
                       (UseImpulseBreakoutEngine && score.impulse.pass));
   if(!engine_pass)
   {
      score.block_reason = BLOCK_NO_MOVEMENT_DATA;
      score.reason_summary = "blocked=no_breakout_or_impulse";
      return;
   }

   if(SpreadOnlyBreakout(index, direction))
   {
      score.block_reason = BLOCK_BAD_SPREAD;
      score.reason_summary = "blocked=spread_only_breakout";
      return;
   }

   if(UseStrictExecutionGate && score.flow.conflict_penalty >= 0.80)
   {
      score.block_reason = BLOCK_CONTEXT_CONFLICT;
      score.reason_summary = "blocked=currency_flow_conflict";
      return;
   }

   double breakout_weight = (UseTechnicalBreakoutEngine ? 0.22 : 0.0);
   double impulse_weight = (UseImpulseBreakoutEngine ? 0.22 : 0.0);
   double execution_weight = 0.18;
   double flow_weight = 0.16;
   double regime_weight = 0.14;
   double calendar_weight = (UseEconomicCalendarContext && score.calendar.available ? 0.08 : 0.0);

   double total_weight = breakout_weight + impulse_weight + execution_weight +
                         flow_weight + regime_weight + calendar_weight;
   if(total_weight <= 0.0)
      total_weight = 1.0;

   double raw01 = (score.breakout.score * breakout_weight +
                   score.impulse.score * impulse_weight +
                   score.execution.score * execution_weight +
                   score.flow.score * flow_weight +
                   score.regime.score * regime_weight +
                   score.calendar.score * calendar_weight) / total_weight;

   if(score.breakout.score >= 0.45 && score.impulse.score >= 0.45)
      raw01 = Clamp01(raw01 + 0.05);

   score.raw_score = 100.0 * SmoothStep(0.35, 0.92, raw01);
   score.calibrated_score = ApplyScoreCalibration(index, score.raw_score, now);

   double capped = Clamp(score.calibrated_score, 0.0, 100.0);
   string caps = "";

   if(!UseEconomicCalendarContext || !score.calendar.available)
      capped = ApplyScoreCap(capped, 94.0, caps, "no_calendar_cap");

   if(!UseCurrencyStrength)
      capped = ApplyScoreCap(capped, 84.0, caps, "flow_disabled_cap");
   else if(!score.flow.pass && score.flow.conflict_penalty < 0.35)
      capped = ApplyScoreCap(capped, 84.0, caps, "flow_absent_cap");
   else if(score.flow.conflict_penalty >= 0.35)
      capped = ApplyScoreCap(capped, 69.0, caps, "flow_conflict_cap");

   if(score.execution.score < 0.68 ||
      score.execution.cost_to_atr > MaxSpreadToAtrRatio * 0.70 ||
      score.execution.spread_ratio > MathMax(1.30, MaxSpreadMedianMultiplier * 0.65))
   {
      capped = ApplyScoreCap(capped, 69.0, caps, "execution_mediocre_cap");
   }

   if(score.breakout.pass && score.breakout.hold_score < 0.35)
      capped = ApplyScoreCap(capped, 74.0, caps, "weak_hold_cap");
   if(score.breakout.pass && score.breakout.body_quality_score < 0.35)
      capped = ApplyScoreCap(capped, 79.0, caps, "weak_body_cap");
   if(score.breakout.fakeout_penalty >= 0.45)
      capped = ApplyScoreCap(capped, 64.0, caps, "range_snapback_cap");

   if(UseMultiTimeframeContextCaps)
   {
      if(score.regime.m5_context_score <= 0.20 || score.regime.m15_context_score <= 0.20)
         capped = ApplyScoreCap(capped, 69.0, caps, "mtf_reject_cap");
   }

   if(score.impulse.score >= 0.60 &&
      UseTickRateScoring &&
      score.impulse.tick_rate_z < 0.0 &&
      score.impulse.tick_volume_z < 0.0)
   {
      capped = ApplyScoreCap(capped, 72.0, caps, "unsupported_impulse_cap");
   }

   if(score.impulse.exhaustion_penalty >= 0.45)
      capped = ApplyScoreCap(capped, 75.0, caps, "overextended_cap");

   int age = EventAgeSeconds(index, direction, now);
   if(age > 300)
      capped = 0.0;
   else if(age > 180)
      capped = ApplyScoreCap(capped, 70.0, caps, "late_event_cap");
   else if(age > 60)
      capped = ApplyScoreCap(capped, 84.0, caps, "aging_event_cap");

   if(score.calendar.available && score.calendar.uncertainty_penalty >= 0.35)
      capped = ApplyScoreCap(capped, 88.0, caps, "calendar_uncertainty_cap");

   if(capped > 80.0 &&
      (score.execution.score < 0.78 || MathMax(score.breakout.score, score.impulse.score) < 0.58))
   {
      capped = ApplyScoreCap(capped, 79.0, caps, "single_feature_cap");
   }

   if(capped > 90.0 &&
      (score.execution.score < 0.88 || score.breakout.hold_score < 0.75 ||
       score.flow.score < 0.70 || score.regime.score < 0.65 ||
       score.calendar.uncertainty_penalty > 0.20))
   {
      capped = ApplyScoreCap(capped, 89.0, caps, "elite_score_cap");
   }

   if(capped > 95.0)
      capped = 95.0;

   score.displayed_score = Clamp(capped, 0.0, 100.0);
   score.valid = (score.displayed_score > 0.0);
   score.reason_summary = BuildReasonSummary(score, caps);

   if(DebugScoreBreakdown && DebugPrintToJournal && score.displayed_score >= MinDisplayConfidence)
   {
      PrintFormat("FXNews score %s %s %s %d%% raw=%.1f cal=%.1f %s",
                  g_profiles[index].symbol,
                  g_profiles[index].timeframe_label,
                  (direction == DIR_UP ? "UP" : "DOWN"),
                  (int)MathRound(score.displayed_score),
                  score.raw_score,
                  score.calibrated_score,
                  score.reason_summary);
   }
}

void EvaluateExecutionQuality(const int index, const datetime now, ExecutionQuality &execution)
{
   execution.pass = false;
   execution.score = 0.0;
   execution.spread_pips = g_profiles[index].spread_pips;
   execution.median_spread_pips = (g_profiles[index].median_spread_pips > 0.0 ?
                                   g_profiles[index].median_spread_pips :
                                   g_profiles[index].spread_pips);
   execution.spread_ratio = SafeDiv(execution.spread_pips, execution.median_spread_pips, 1.0);
   execution.spread_z = g_profiles[index].spread_z;
   execution.quote_age_sec = (g_profiles[index].quote_time > 0 ? (double)(now - g_profiles[index].quote_time) : 9999.0);
   execution.tick_gap_sec = g_profiles[index].tick_gap_sec;
   execution.cost_to_atr = SafeDiv(MathMax(g_profiles[index].ask - g_profiles[index].bid, 0.0),
                                   g_profiles[index].atr_m1,
                                   999.0);
   execution.block_reason = BLOCK_NONE;

   if(!g_profiles[index].valid || !g_profiles[index].selected ||
      !g_profiles[index].quote_fresh || g_profiles[index].bid <= 0.0 ||
      g_profiles[index].ask <= 0.0 || g_profiles[index].ask < g_profiles[index].bid)
   {
      execution.block_reason = BLOCK_STALE_QUOTE;
      return;
   }

   if(!g_profiles[index].has_m1 || !g_profiles[index].has_m5 || !g_profiles[index].has_m15 ||
      g_profiles[index].atr_m1 <= 0.0 ||
      SafeDiv(g_profiles[index].atr_m1, g_profiles[index].pip_size, 0.0) < 0.10)
   {
      execution.block_reason = BLOCK_NO_ATR;
      return;
   }

   if(g_profiles[index].range_width <= 0.0)
   {
      execution.block_reason = BLOCK_NO_RANGE;
      return;
   }

   if(IgnoreRolloverTime && IsRolloverTime(now))
   {
      execution.block_reason = BLOCK_ROLLOVER;
      return;
   }

   if(execution.spread_pips <= 0.0 || execution.spread_pips > MaxSpreadPips ||
      execution.spread_ratio > MaxSpreadMedianMultiplier)
   {
      execution.block_reason = BLOCK_BAD_SPREAD;
      return;
   }

   if(UseStrictExecutionGate)
   {
      if(execution.cost_to_atr > MaxSpreadToAtrRatio ||
         execution.spread_z > MaxSpreadZScore)
      {
         execution.block_reason = BLOCK_BAD_SPREAD;
         return;
      }

      if(execution.tick_gap_sec > MaxTickGapSeconds)
      {
         execution.block_reason = BLOCK_STALE_QUOTE;
         return;
      }
   }

   double spread_abs_score = 1.0 - SmoothStep(MaxSpreadPips * 0.45, MaxSpreadPips, execution.spread_pips);
   double spread_rel_score = 1.0 - SmoothStep(1.0, MaxSpreadMedianMultiplier, execution.spread_ratio);
   double cost_score = 1.0 - SmoothStep(MaxSpreadToAtrRatio * 0.45, MaxSpreadToAtrRatio, execution.cost_to_atr);
   double spread_z_score = 1.0 - SmoothStep(1.25, MaxSpreadZScore, execution.spread_z);
   double quote_fresh_score = 1.0 - SmoothStep((double)MaxQuoteAgeSeconds * 0.45,
                                               (double)MaxQuoteAgeSeconds,
                                               execution.quote_age_sec);
   double tick_gap_score = 1.0 - SmoothStep(MaxTickGapSeconds * 0.45,
                                            MaxTickGapSeconds,
                                            execution.tick_gap_sec);

   execution.score = Clamp01(spread_abs_score * 0.18 +
                             spread_rel_score * 0.20 +
                             cost_score * 0.24 +
                             spread_z_score * 0.14 +
                             quote_fresh_score * 0.12 +
                             tick_gap_score * 0.12);
   execution.pass = true;
}

void EvaluateBreakoutStructure(const int index,
                               const int direction,
                               const datetime now,
                               BreakoutStructure &breakout)
{
   breakout.pass = false;
   breakout.score = 0.0;
   breakout.compression_score = 0.0;
   breakout.distance_score = 0.0;
   breakout.close_location_score = 0.0;
   breakout.hold_score = 0.0;
   breakout.body_quality_score = 0.0;
   breakout.wick_rejection_penalty = 0.0;
   breakout.fakeout_penalty = 0.0;

   if(!UseTechnicalBreakoutEngine || g_profiles[index].atr_m1 <= 0.0 ||
      g_profiles[index].range_width <= 0.0)
   {
      return;
   }

   double atr = g_profiles[index].atr_m1;
   double range_atr = g_profiles[index].range_width / atr;
   double not_dead = SmoothStep(0.65, 1.80, range_atr);
   double not_chaotic = 1.0 - SmoothStep(7.0, 16.0, range_atr);
   breakout.compression_score = Clamp01(0.10 + 0.90 * not_dead * not_chaotic);

   double distance = BreakoutDistance(index, direction);
   double buffer = MathMax(BreakoutBufferPrice(index), g_profiles[index].point);
   double distance_units = distance / buffer;
   double distance_atr = SafeDiv(distance, atr, 0.0);
   double extension_penalty = SmoothStep(MaxOverextensionAtr, MaxOverextensionAtr * 1.80, distance_atr);
   breakout.distance_score = Clamp01(SmoothStep(0.20, 1.60, distance_units) * (1.0 - extension_penalty * 0.45));

   double candle_range = g_profiles[index].current_m1_high - g_profiles[index].current_m1_low;
   if(candle_range > 0.0)
   {
      if(direction == DIR_UP)
         breakout.close_location_score = Clamp01((g_profiles[index].current_m1_close - g_profiles[index].current_m1_low) / candle_range);
      else
         breakout.close_location_score = Clamp01((g_profiles[index].current_m1_high - g_profiles[index].current_m1_close) / candle_range);

      double body = MathAbs(g_profiles[index].current_m1_close - g_profiles[index].current_m1_open);
      double body_ratio = body / candle_range;
      double directional_body = DirectionalValue(g_profiles[index].current_m1_close - g_profiles[index].current_m1_open,
                                                 direction) / candle_range;
      breakout.body_quality_score = Clamp01(SmoothStep(0.18, 0.62, body_ratio) * 0.65 +
                                            SmoothStep(0.03, 0.38, directional_body) * 0.35);

      double rejection_wick = 0.0;
      if(direction == DIR_UP)
         rejection_wick = g_profiles[index].current_m1_high -
                          MathMax(g_profiles[index].current_m1_open, g_profiles[index].current_m1_close);
      else
         rejection_wick = MathMin(g_profiles[index].current_m1_open, g_profiles[index].current_m1_close) -
                          g_profiles[index].current_m1_low;
      breakout.wick_rejection_penalty = Clamp01(rejection_wick / candle_range);
   }

   datetime outside_since = (direction == DIR_UP ? g_profiles[index].outside_since_up :
                             g_profiles[index].outside_since_down);
   if(outside_since > 0)
   {
      double seconds = (double)MathMax(0, (int)(now - outside_since));
      breakout.hold_score = SmoothStep((double)MinHoldSecondsForHighScore,
                                       (double)FullHoldScoreSeconds,
                                       seconds);
   }

   datetime reentered_since = (direction == DIR_UP ? g_profiles[index].reentered_since_up :
                               g_profiles[index].reentered_since_down);
   if(reentered_since > 0 && now - reentered_since <= 30)
      breakout.fakeout_penalty = 1.0 - SmoothStep(0.0, 30.0, (double)(now - reentered_since));

   breakout.score = Clamp01(breakout.compression_score * 0.17 +
                            breakout.distance_score * 0.24 +
                            breakout.close_location_score * 0.17 +
                            breakout.hold_score * 0.20 +
                            breakout.body_quality_score * 0.17 -
                            breakout.wick_rejection_penalty * 0.15 -
                            breakout.fakeout_penalty * 0.25);
   breakout.pass = (distance > 0.0 && breakout.score > 0.06);
}

void EvaluateImpulseQuality(const int index, const int direction, ImpulseQuality &impulse)
{
   impulse.pass = false;
   impulse.score = 0.0;
   impulse.speed_5s_z = 0.0;
   impulse.speed_10s_z = 0.0;
   impulse.speed_30s_z = 0.0;
   impulse.speed_60s_z = 0.0;
   impulse.acceleration_score = 0.0;
   impulse.atr_expansion_score = 0.0;
   impulse.tick_rate_z = 0.0;
   impulse.tick_volume_z = 0.0;
   impulse.exhaustion_penalty = 0.0;

   if(!UseImpulseBreakoutEngine || g_profiles[index].atr_m1 <= 0.0 ||
      g_profiles[index].pip_size <= 0.0 || g_profiles[index].snapshot_count < 3)
   {
      return;
   }

   impulse.speed_5s_z = SpeedRobustZ(index, direction, 5);
   impulse.speed_10s_z = SpeedRobustZ(index, direction, 10);
   impulse.speed_30s_z = SpeedRobustZ(index, direction, 30);
   impulse.speed_60s_z = SpeedRobustZ(index, direction, 60);

   double speed_score = Clamp01(ScoreFromZ(Max3(impulse.speed_5s_z,
                                               impulse.speed_10s_z,
                                               impulse.speed_30s_z),
                                           MinImpulseZForSignal,
                                           MinImpulseZForSignal + 2.75));
   double short_rate = SafeDiv(DirectionalValue(g_profiles[index].speed_5s_pips, direction), 5.0, 0.0);
   double long_rate = SafeDiv(DirectionalValue(g_profiles[index].speed_30s_pips, direction), 30.0, 0.0);
   impulse.acceleration_score = SmoothStep(0.0, 0.10, short_rate - long_rate);

   double candle_directional_range = 0.0;
   if(direction == DIR_UP)
      candle_directional_range = g_profiles[index].current_m1_high - g_profiles[index].current_m1_open;
   else
      candle_directional_range = g_profiles[index].current_m1_open - g_profiles[index].current_m1_low;
   impulse.atr_expansion_score = SmoothStep(0.20, 1.25, SafeDiv(candle_directional_range,
                                                               g_profiles[index].atr_m1,
                                                               0.0));

   impulse.tick_rate_z = TickRateZ(index);
   impulse.tick_volume_z = TickVolumeRobustZ(index);
   double tick_rate_score = (UseTickRateScoring ? ScoreFromZ(impulse.tick_rate_z, 0.50, 2.50) : 0.65);
   double volume_score = ScoreFromZ(impulse.tick_volume_z, 0.50, 2.80);
   double continuation = ContinuationScore(index, direction) / 100.0;

   double atr_pips = MathMax(g_profiles[index].atr_m1 / g_profiles[index].pip_size, 0.1);
   double extended_atr = DirectionalValue(g_profiles[index].movement_5m_pips, direction) / atr_pips;
   impulse.exhaustion_penalty = SmoothStep(MaxExhaustionAtr, MaxExhaustionAtr * 1.70, extended_atr);

   impulse.score = Clamp01(speed_score * 0.25 +
                           impulse.atr_expansion_score * 0.20 +
                           volume_score * 0.15 +
                           tick_rate_score * 0.10 +
                           impulse.acceleration_score * 0.15 +
                           continuation * 0.15 -
                           impulse.exhaustion_penalty * 0.22);
   impulse.pass = (Max3(impulse.speed_5s_z, impulse.speed_10s_z, impulse.speed_30s_z) >= MinImpulseZForSignal ||
                   impulse.atr_expansion_score >= 0.45);
}

void EvaluateCurrencyFlowQuality(const int index,
                                 const int direction,
                                 CurrencyFlowQuality &flow)
{
   flow.pass = false;
   flow.score = 0.62;
   flow.base_strength = 0.0;
   flow.quote_strength = 0.0;
   flow.directional_edge = 0.0;
   flow.basket_agreement = 0.50;
   flow.conflict_penalty = 0.0;

   if(!UseCurrencyStrength)
      return;

   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   if(base < 0 || quote < 0)
   {
      flow.score = 0.52;
      return;
   }

   if(g_currency_samples[base] <= 0 || g_currency_samples[quote] <= 0)
   {
      flow.score = 0.62;
      flow.basket_agreement = 0.50;
      return;
   }

   flow.base_strength = g_currency_strength[base];
   flow.quote_strength = g_currency_strength[quote];
   flow.directional_edge = (flow.base_strength - flow.quote_strength) * (double)direction;
   flow.basket_agreement = CalculateBasketAgreement(index, direction);

   double edge_score = SmoothStep(MinDirectionalEdgeForHighScore * 0.20,
                                  MinDirectionalEdgeForHighScore,
                                  flow.directional_edge);
   double agreement_score = SmoothStep(0.45,
                                       MinBasketAgreementForHighScore,
                                       flow.basket_agreement);
   flow.conflict_penalty = 0.0;
   if(flow.directional_edge < -MinDirectionalEdgeForHighScore * 0.50)
      flow.conflict_penalty += 0.45;
   if(flow.basket_agreement < 0.35)
      flow.conflict_penalty += 0.45;
   flow.conflict_penalty = Clamp01(flow.conflict_penalty);

   flow.score = Clamp01(edge_score * 0.55 + agreement_score * 0.45 - flow.conflict_penalty * 0.35);
   flow.pass = (flow.conflict_penalty < 0.55);
}

void EvaluateRegimeContext(const int index,
                           const int direction,
                           const datetime now,
                           RegimeContext &regime)
{
   regime.pass = true;
   regime.session_score = SessionQualityScore(now);
   regime.m5_context_score = SmoothStep(M5RejectAtr, 0.35, g_profiles[index].m5_move_atr * (double)direction);
   regime.m15_context_score = SmoothStep(M15RejectAtr, 0.30, g_profiles[index].m15_move_atr * (double)direction);
   regime.mtf_alignment_score = Clamp01(regime.m5_context_score * 0.55 + regime.m15_context_score * 0.45);

   double range_atr = SafeDiv(g_profiles[index].range_width, g_profiles[index].atr_m1, 0.0);
   double active_enough = SmoothStep(0.70, 2.20, range_atr);
   double not_chaotic = 1.0 - SmoothStep(14.0, 24.0, range_atr);
   regime.volatility_regime_score = Clamp01(active_enough * not_chaotic);
   regime.rollover_penalty = (IgnoreRolloverTime && IsRolloverTime(now) ? 1.0 : 0.0);
   regime.score = Clamp01(regime.session_score * 0.25 +
                          regime.mtf_alignment_score * 0.42 +
                          regime.volatility_regime_score * 0.33 -
                          regime.rollover_penalty);
   if(UseMultiTimeframeContextCaps &&
      (regime.m5_context_score <= 0.10 || regime.m15_context_score <= 0.10))
   {
      regime.pass = false;
   }
}

void EvaluateCalendarContext(const int index,
                             const int direction,
                             const datetime now,
                             CalendarContext &calendar)
{
   calendar.available = false;
   calendar.relevant_event_nearby = false;
   calendar.high_impact_nearby = false;
   calendar.just_released = false;
   calendar.score = 0.65;
   calendar.proximity_minutes = 0.0;
   calendar.importance_score = 0.0;
   calendar.surprise_score = 0.0;
   calendar.uncertainty_penalty = 0.0;

   if(!UseEconomicCalendarContext)
      return;

   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   if(base < 0 || quote < 0)
      return;

   RefreshCalendarCache(base, now);
   RefreshCalendarCache(quote, now);

   CurrencyCalendarCache base_cache = g_calendar_cache[base];
   CurrencyCalendarCache quote_cache = g_calendar_cache[quote];
   calendar.available = (base_cache.available || quote_cache.available);
   if(!calendar.available)
      return;

   calendar.relevant_event_nearby = (base_cache.relevant_event_nearby || quote_cache.relevant_event_nearby);
   calendar.high_impact_nearby = (base_cache.high_impact_nearby || quote_cache.high_impact_nearby);
   calendar.just_released = (base_cache.just_released || quote_cache.just_released);
   calendar.importance_score = MathMax(base_cache.importance_score, quote_cache.importance_score);
   calendar.uncertainty_penalty = MathMax(base_cache.uncertainty_penalty, quote_cache.uncertainty_penalty);

   if(base_cache.proximity_minutes <= 0.0)
      calendar.proximity_minutes = quote_cache.proximity_minutes;
   else if(quote_cache.proximity_minutes <= 0.0)
      calendar.proximity_minutes = base_cache.proximity_minutes;
   else
      calendar.proximity_minutes = MathMin(base_cache.proximity_minutes, quote_cache.proximity_minutes);

   double release_bonus = (calendar.just_released ? 0.20 : 0.0);
   double high_bonus = (calendar.high_impact_nearby ? 0.10 : 0.0);
   calendar.score = Clamp01(0.60 + release_bonus + high_bonus -
                            calendar.uncertainty_penalty * 0.30);
}

bool CalendarPreNewsBlock(const CalendarContext &calendar)
{
   if(!UseEconomicCalendarContext || !BlockImmediatelyBeforeHighImpactNews ||
      !calendar.available || !calendar.high_impact_nearby || calendar.just_released)
   {
      return false;
   }

   return (calendar.proximity_minutes >= 0.0 &&
           calendar.proximity_minutes <= (double)CalendarPreNewsBlockMinutes);
}

double ApplyScoreCap(const double score,
                     const double cap,
                     string &cap_reasons,
                     const string reason)
{
   if(score <= cap)
      return score;

   if(cap_reasons != "")
      cap_reasons += "|";
   cap_reasons += reason;
   return cap;
}

string BuildReasonSummary(const CompositeSignalScore &score, const string caps)
{
   string names[6];
   double values[6];
   int count = 0;
   names[count] = "exec";
   values[count] = score.execution.score;
   count++;
   names[count] = "breakout";
   values[count] = score.breakout.score;
   count++;
   names[count] = "impulse";
   values[count] = score.impulse.score;
   count++;
   names[count] = "flow";
   values[count] = score.flow.score;
   count++;
   names[count] = "regime";
   values[count] = score.regime.score;
   count++;
   if(score.calendar.available)
   {
      names[count] = "calendar";
      values[count] = score.calendar.score;
      count++;
   }

   string positives = TopReasonSummary(names, values, count, 3);
   if(caps == "")
      return "positive=" + positives;
   return "positive=" + positives + "; caps=" + FirstDelimitedItems(caps, 3);
}

string TopReasonSummary(string &names[], double &values[], const int count, const int max_items)
{
   string summary = "";
   bool used[];
   ArrayResize(used, count);
   for(int i = 0; i < count; i++)
      used[i] = false;

   for(int item = 0; item < max_items; item++)
   {
      int best_index = -1;
      double best_value = -1.0;
      for(int i = 0; i < count; i++)
      {
         if(used[i])
            continue;
         if(values[i] > best_value)
         {
            best_value = values[i];
            best_index = i;
         }
      }

      if(best_index < 0 || best_value < 0.50)
         break;

      used[best_index] = true;
      if(summary != "")
         summary += "|";
      summary += StringFormat("%s=%.2f", names[best_index], best_value);
   }

   if(summary == "")
      summary = "none";
   return summary;
}

string FirstDelimitedItems(const string text, const int max_items)
{
   string parts[];
   ushort separator = StringGetCharacter("|", 0);
   int count = StringSplit(text, separator, parts);
   if(count <= 0)
      return text;

   string result = "";
   int take = IntMin(count, max_items);
   for(int i = 0; i < take; i++)
   {
      if(result != "")
         result += "|";
      result += parts[i];
   }

   return result;
}

double CalculateBasketAgreement(const int index, const int direction)
{
   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   if(base < 0 || quote < 0)
      return 0.50;

   double agreeing_weight = 0.0;
   double total_weight = 0.0;

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(i == index || !g_profiles[i].valid || !g_profiles[i].quote_fresh ||
         g_profiles[i].atr_m1 <= 0.0 || g_profiles[i].pip_size <= 0.0 ||
         g_profiles[i].base_index < 0 || g_profiles[i].quote_index < 0 ||
         g_profiles[i].spread_pips <= 0.0 || g_profiles[i].spread_pips > MaxSpreadPips)
      {
         continue;
      }

      bool relevant = (g_profiles[i].base_index == base || g_profiles[i].quote_index == base ||
                       g_profiles[i].base_index == quote || g_profiles[i].quote_index == quote);
      if(!relevant)
         continue;

      double atr_pips = MathMax(g_profiles[i].atr_m1 / g_profiles[i].pip_size, 0.1);
      double pair_move = Clamp(g_profiles[i].movement_5m_pips / (atr_pips * 1.2), -1.0, 1.0);
      double expected = 0.0;

      if(g_profiles[i].base_index == base)
         expected += (double)direction;
      if(g_profiles[i].quote_index == base)
         expected -= (double)direction;
      if(g_profiles[i].base_index == quote)
         expected -= (double)direction;
      if(g_profiles[i].quote_index == quote)
         expected += (double)direction;

      if(expected == 0.0)
         continue;

      double spread_weight = 1.0 / MathMax(1.0, SafeDiv(g_profiles[i].spread_pips,
                                                        g_profiles[i].median_spread_pips,
                                                        1.0));
      double weight = Clamp(spread_weight / MathMax(atr_pips, 0.5), 0.05, 1.50);
      total_weight += weight;

      if(pair_move * expected > 0.03)
         agreeing_weight += weight;
      else if(pair_move * expected > -0.03)
         agreeing_weight += weight * 0.50;
   }

   if(total_weight <= 0.0)
      return 0.50;

   return Clamp01(agreeing_weight / total_weight);
}

bool SpreadOnlyBreakout(const int index, const int direction)
{
   double breakout_distance = BreakoutDistance(index, direction);
   if(breakout_distance <= 0.0)
      return false;

   double spread_price = MathMax(g_profiles[index].ask - g_profiles[index].bid, 0.0);
   double directional_10s = DirectionalValue(g_profiles[index].speed_10s_pips, direction);
   double directional_30s = DirectionalValue(g_profiles[index].speed_30s_pips, direction);

   return (breakout_distance <= spread_price * 1.20 &&
           directional_10s < g_profiles[index].spread_pips * 0.60 &&
           directional_30s < g_profiles[index].spread_pips * 0.90);
}

double SessionQualityScore(const datetime now)
{
   MqlDateTime parts;
   TimeToStruct(now, parts);
   int hour = parts.hour;

   if(hour >= 7 && hour <= 16)
      return 1.00;  // London and early New York liquidity.
   if(hour >= 17 && hour <= 20)
      return 0.82;  // Late New York can still trend but liquidity decays.
   if(hour >= 1 && hour <= 6)
      return 0.72;  // Asia can move JPY/AUD/NZD but basket breakouts need confirmation.
   if(hour >= 21 && hour <= 22)
      return 0.55;
   return 0.35;
}

void InitializeCalendarCache()
{
   for(int i = 0; i < CURRENCY_COUNT; i++)
   {
      g_calendar_cache[i].currency = g_currency_codes[i];
      g_calendar_cache[i].refreshed_at = 0;
      g_calendar_cache[i].available = false;
      g_calendar_cache[i].relevant_event_nearby = false;
      g_calendar_cache[i].high_impact_nearby = false;
      g_calendar_cache[i].just_released = false;
      g_calendar_cache[i].score = 0.65;
      g_calendar_cache[i].proximity_minutes = 0.0;
      g_calendar_cache[i].importance_score = 0.0;
      g_calendar_cache[i].uncertainty_penalty = 0.0;
   }
}

void RefreshCalendarCache(const int currency_index, const datetime now)
{
   if(currency_index < 0 || currency_index >= CURRENCY_COUNT)
      return;
   if(!UseEconomicCalendarContext)
      return;
   if(g_calendar_cache[currency_index].refreshed_at > 0 &&
      now - g_calendar_cache[currency_index].refreshed_at < CALENDAR_REFRESH_SECONDS)
   {
      return;
   }

   CurrencyCalendarCache cache;
   cache.currency = g_currency_codes[currency_index];
   cache.refreshed_at = now;
   cache.available = false;
   cache.relevant_event_nearby = false;
   cache.high_impact_nearby = false;
   cache.just_released = false;
   cache.score = 0.65;
   cache.proximity_minutes = 0.0;
   cache.importance_score = 0.0;
   cache.uncertainty_penalty = 0.0;

   datetime server_now = TimeTradeServer();
   if(server_now <= 0)
      server_now = now;

   datetime from_time = server_now - CalendarLookbackMinutes * 60;
   datetime to_time = server_now + CalendarLookaheadMinutes * 60;
   MqlCalendarValue values[];
   ResetLastError();
   int count = CalendarValueHistory(values, from_time, to_time, NULL, cache.currency);
   if(count <= 0)
   {
      cache.available = false;
      g_calendar_cache[currency_index] = cache;
      return;
   }

   cache.available = true;
   double nearest_abs_minutes = 999999.0;
   for(int i = 0; i < count; i++)
   {
      MqlCalendarEvent calendar_event;
      if(!CalendarEventById(values[i].event_id, calendar_event))
         continue;

      int importance = (int)calendar_event.importance;
      bool high_impact = (importance >= 3);
      if(CalendarHighImpactOnly && !high_impact)
         continue;

      double minutes_signed = (double)(values[i].time - server_now) / 60.0;
      double abs_minutes = MathAbs(minutes_signed);
      if(abs_minutes < nearest_abs_minutes)
      {
         nearest_abs_minutes = abs_minutes;
         cache.proximity_minutes = minutes_signed;
      }

      cache.relevant_event_nearby = true;
      cache.high_impact_nearby = (cache.high_impact_nearby || high_impact);
      cache.just_released = (cache.just_released ||
                             (minutes_signed <= 0.0 &&
                              MathAbs(minutes_signed) <= (double)CalendarLookbackMinutes));
      cache.importance_score = MathMax(cache.importance_score, Clamp01((double)importance / 3.0));
      if(!cache.just_released && abs_minutes <= (double)CalendarLookaheadMinutes)
         cache.uncertainty_penalty = MathMax(cache.uncertainty_penalty, high_impact ? 0.55 : 0.25);
   }

   if(cache.relevant_event_nearby)
      cache.score = Clamp01(0.58 + (cache.high_impact_nearby ? 0.16 : 0.06) +
                            (cache.just_released ? 0.18 : 0.0) -
                            cache.uncertainty_penalty * 0.25);

   g_calendar_cache[currency_index] = cache;
}

double ApplyScoreCalibration(const int index, const double raw_score, const datetime now)
{
   if(!UseScoreCalibrationFile || ArraySize(g_calibration_entries) <= 0)
      return raw_score;

   int bucket = (int)MathFloor(Clamp(raw_score, 0.0, 100.0) / 10.0) * 10;
   string session = SessionName(now);
   string symbol = UpperAscii(g_profiles[index].symbol);
   string timeframe_label = g_profiles[index].timeframe_label;

   for(int i = 0; i < ArraySize(g_calibration_entries); i++)
   {
      if(g_calibration_entries[i].sample_count < MinCalibrationSamples)
         continue;
      if(UpperAscii(g_calibration_entries[i].symbol) != symbol)
         continue;
      if(g_calibration_entries[i].timeframe_label != timeframe_label)
         continue;
      if(g_calibration_entries[i].session_name != session)
         continue;
      if(g_calibration_entries[i].score_bucket != bucket)
         continue;

      return Clamp(g_calibration_entries[i].calibrated_score, 0.0, 100.0);
   }

   return raw_score;
}

void LoadScoreCalibration()
{
   ArrayResize(g_calibration_entries, 0);
   if(!UseScoreCalibrationFile)
      return;

   ResetLastError();
   int handle = FileOpen(ScoreCalibrationFile, FILE_READ | FILE_CSV | FILE_ANSI, ',');
   if(handle == INVALID_HANDLE)
   {
      if(!g_calibration_warning_printed)
      {
         PrintFormat("FXNews: calibration file '%s' not loaded, error %d. Raw scores will be used.",
                     ScoreCalibrationFile,
                     GetLastError());
         g_calibration_warning_printed = true;
      }
      return;
   }

   bool first_row = true;
   while(!FileIsEnding(handle))
   {
      string symbol = FileReadString(handle);
      if(FileIsEnding(handle) && symbol == "")
         break;
      string timeframe_label = FileReadString(handle);
      string session_name = FileReadString(handle);
      string bucket_text = FileReadString(handle);
      string calibrated_text = FileReadString(handle);
      string samples_text = FileReadString(handle);
      FileReadString(handle); // win_rate, kept for external analysis
      FileReadString(handle); // avg_mfe_atr
      FileReadString(handle); // avg_mae_atr

      if(first_row)
      {
         first_row = false;
         if(UpperAscii(symbol) == "SYMBOL")
            continue;
      }

      if(symbol == "" || timeframe_label == "" || session_name == "")
         continue;

      CalibrationEntry entry;
      entry.symbol = symbol;
      entry.timeframe_label = timeframe_label;
      entry.session_name = session_name;
      entry.score_bucket = (int)StringToInteger(bucket_text);
      entry.calibrated_score = StringToDouble(calibrated_text);
      entry.sample_count = (int)StringToInteger(samples_text);

      int next = ArraySize(g_calibration_entries);
      ArrayResize(g_calibration_entries, next + 1);
      g_calibration_entries[next] = entry;
   }

   FileClose(handle);
   PrintFormat("FXNews: loaded %d calibration rows from %s.",
               ArraySize(g_calibration_entries),
               ScoreCalibrationFile);
}

string SessionName(const datetime now)
{
   MqlDateTime parts;
   TimeToStruct(now, parts);
   int hour = parts.hour;
   if(hour >= 7 && hour <= 16)
      return "LONDON_NY";
   if(hour >= 17 && hour <= 20)
      return "NY_LATE";
   if(hour >= 1 && hour <= 6)
      return "ASIA";
   if(hour >= 21 && hour <= 22)
      return "POST_NY";
   return "ROLLOVER";
}

string BlockReasonText(const SignalBlockReason reason)
{
   if(reason == BLOCK_STALE_QUOTE)
      return "stale_quote";
   if(reason == BLOCK_BAD_SPREAD)
      return "bad_spread";
   if(reason == BLOCK_ROLLOVER)
      return "rollover";
   if(reason == BLOCK_NO_ATR)
      return "no_atr";
   if(reason == BLOCK_NO_RANGE)
      return "no_range";
   if(reason == BLOCK_NO_MOVEMENT_DATA)
      return "no_movement_data";
   if(reason == BLOCK_FAKEOUT)
      return "fakeout";
   if(reason == BLOCK_CONTEXT_CONFLICT)
      return "context_conflict";
   return "none";
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
      RecordDisplayedSignal(index, direction, score, now);
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

void RecordDisplayedSignal(const int index,
                           const int direction,
                           const double score,
                           const datetime now)
{
   if(!EnableSignalLogging && !EnableOutcomeLabeling)
      return;

   CompositeSignalScore composite;
   if(direction == DIR_UP)
      composite = g_profiles[index].composite_up;
   else
      composite = g_profiles[index].composite_down;

   g_signal_sequence++;
   string signal_id = StringFormat("%I64d_%s_%s_%d",
                                   (long)now,
                                   g_profiles[index].symbol,
                                   g_profiles[index].timeframe_label,
                                   (int)g_signal_sequence);

   if(EnableSignalLogging)
      AppendSignalLogRow(signal_id, index, direction, score, now, composite);

   if(EnableOutcomeLabeling && EnableSignalLogging)
      AddPendingOutcome(signal_id, index, direction, now);
}

void AddPendingOutcome(const string signal_id,
                       const int index,
                       const int direction,
                       const datetime now)
{
   int slot = -1;
   for(int i = 0; i < ArraySize(g_pending_outcomes); i++)
   {
      if(!g_pending_outcomes[i].active)
      {
         slot = i;
         break;
      }
   }

   if(slot < 0)
   {
      if(ArraySize(g_pending_outcomes) < MAX_PENDING_OUTCOMES)
      {
         slot = ArraySize(g_pending_outcomes);
         ArrayResize(g_pending_outcomes, slot + 1);
      }
      else
      {
         slot = 0;
      }
   }

   g_pending_outcomes[slot].active = true;
   g_pending_outcomes[slot].signal_id = signal_id;
   g_pending_outcomes[slot].symbol = g_profiles[index].symbol;
   g_pending_outcomes[slot].timeframe_label = g_profiles[index].timeframe_label;
   g_pending_outcomes[slot].direction = direction;
   g_pending_outcomes[slot].signal_server_time = now;
   g_pending_outcomes[slot].signal_local_time = g_profiles[index].event_local_time;
   g_pending_outcomes[slot].entry_mid = g_profiles[index].mid;
   g_pending_outcomes[slot].atr_price = g_profiles[index].atr_m1;
   g_pending_outcomes[slot].pip_size = g_profiles[index].pip_size;
   g_pending_outcomes[slot].mfe_pips = 0.0;
   g_pending_outcomes[slot].mae_pips = 0.0;
   g_pending_outcomes[slot].horizon1_written = false;
   g_pending_outcomes[slot].horizon2_written = false;
   g_pending_outcomes[slot].horizon3_written = false;
}

void UpdatePendingOutcomes(const datetime now)
{
   if(!EnableOutcomeLabeling || !EnableSignalLogging)
      return;

   for(int i = 0; i < ArraySize(g_pending_outcomes); i++)
   {
      if(!g_pending_outcomes[i].active)
         continue;

      double mid = 0.0;
      if(!FindCurrentMidForSymbol(g_pending_outcomes[i].symbol, mid))
         continue;

      double directional_move_pips = DirectionalValue(mid - g_pending_outcomes[i].entry_mid,
                                                      g_pending_outcomes[i].direction) /
                                     MathMax(g_pending_outcomes[i].pip_size, 0.00000001);
      double adverse_move_pips = -directional_move_pips;
      if(directional_move_pips > g_pending_outcomes[i].mfe_pips)
         g_pending_outcomes[i].mfe_pips = directional_move_pips;
      if(adverse_move_pips > g_pending_outcomes[i].mae_pips)
         g_pending_outcomes[i].mae_pips = adverse_move_pips;

      int age_seconds = (int)(now - g_pending_outcomes[i].signal_server_time);
      if(!g_pending_outcomes[i].horizon1_written && age_seconds >= OutcomeHorizonMinutes1 * 60)
      {
         AppendOutcomeLogRow(g_pending_outcomes[i], OutcomeHorizonMinutes1, now);
         g_pending_outcomes[i].horizon1_written = true;
      }
      if(!g_pending_outcomes[i].horizon2_written && age_seconds >= OutcomeHorizonMinutes2 * 60)
      {
         AppendOutcomeLogRow(g_pending_outcomes[i], OutcomeHorizonMinutes2, now);
         g_pending_outcomes[i].horizon2_written = true;
      }
      if(!g_pending_outcomes[i].horizon3_written && age_seconds >= OutcomeHorizonMinutes3 * 60)
      {
         AppendOutcomeLogRow(g_pending_outcomes[i], OutcomeHorizonMinutes3, now);
         g_pending_outcomes[i].horizon3_written = true;
         g_pending_outcomes[i].active = false;
      }
   }
}

bool FindCurrentMidForSymbol(const string symbol, double &mid)
{
   string target = UpperAscii(symbol);
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(UpperAscii(g_profiles[i].symbol) == target &&
         g_profiles[i].quote_fresh &&
         g_profiles[i].mid > 0.0)
      {
         mid = g_profiles[i].mid;
         return true;
      }
   }

   mid = 0.0;
   return false;
}

void AppendSignalLogRow(const string signal_id,
                        const int index,
                        const int direction,
                        const double score,
                        const datetime now,
                        const CompositeSignalScore &composite)
{
   int handle = OpenSignalLogForAppend();
   if(handle == INVALID_HANDLE)
      return;

   FileWrite(handle,
             "SIGNAL",
             signal_id,
             FormatLocalTimestamp(TimeLocal()),
             TimeToString(now, TIME_DATE | TIME_SECONDS),
             g_profiles[index].symbol,
             g_profiles[index].timeframe_label,
             DirectionText(direction),
             (int)MathRound(score),
             DoubleToString(composite.raw_score, 2),
             DoubleToString(composite.calibrated_score, 2),
             DoubleToString(composite.execution.spread_pips, 2),
             DoubleToString(composite.execution.median_spread_pips, 2),
             DoubleToString(composite.execution.spread_ratio, 3),
             DoubleToString(composite.execution.cost_to_atr, 4),
             DoubleToString(g_profiles[index].atr_m1, g_profiles[index].digits),
             DoubleToString(g_profiles[index].range_width, g_profiles[index].digits),
             DoubleToString(composite.breakout.compression_score, 3),
             DoubleToString(composite.breakout.distance_score, 3),
             DoubleToString(composite.breakout.close_location_score, 3),
             DoubleToString(composite.breakout.hold_score, 3),
             DoubleToString(composite.breakout.body_quality_score, 3),
             DoubleToString(composite.breakout.wick_rejection_penalty, 3),
             DoubleToString(composite.breakout.fakeout_penalty, 3),
             DoubleToString(composite.impulse.speed_5s_z, 3),
             DoubleToString(composite.impulse.speed_10s_z, 3),
             DoubleToString(composite.impulse.speed_30s_z, 3),
             DoubleToString(composite.impulse.speed_60s_z, 3),
             DoubleToString(composite.impulse.acceleration_score, 3),
             DoubleToString(composite.impulse.atr_expansion_score, 3),
             DoubleToString(composite.impulse.tick_rate_z, 3),
             DoubleToString(composite.impulse.tick_volume_z, 3),
             DoubleToString(composite.impulse.exhaustion_penalty, 3),
             DoubleToString(composite.flow.base_strength, 3),
             DoubleToString(composite.flow.quote_strength, 3),
             DoubleToString(composite.flow.directional_edge, 3),
             DoubleToString(composite.flow.basket_agreement, 3),
             DoubleToString(composite.flow.conflict_penalty, 3),
             DoubleToString(composite.regime.session_score, 3),
             DoubleToString(composite.regime.mtf_alignment_score, 3),
             DoubleToString(composite.regime.m5_context_score, 3),
             DoubleToString(composite.regime.m15_context_score, 3),
             DoubleToString(composite.regime.volatility_regime_score, 3),
             DoubleToString(composite.calendar.score, 3),
             DoubleToString(composite.calendar.proximity_minutes, 2),
             DoubleToString(composite.calendar.importance_score, 3),
             BlockReasonText(composite.block_reason),
             composite.reason_summary,
             DoubleToString(g_profiles[index].mid, g_profiles[index].digits),
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "");

   FileClose(handle);
}

void AppendOutcomeLogRow(const PendingOutcome &outcome,
                         const int horizon_minutes,
                         const datetime now)
{
   int handle = OpenSignalLogForAppend();
   if(handle == INVALID_HANDLE)
      return;

   double atr_pips = MathMax(outcome.atr_price / MathMax(outcome.pip_size, 0.00000001), 0.1);
   double mfe_atr = outcome.mfe_pips / atr_pips;
   double mae_atr = outcome.mae_pips / atr_pips;
   bool target_hit = (mfe_atr >= OutcomeTargetAtr && mae_atr < OutcomeStopAtr);
   double continuation_score = Clamp01((mfe_atr - mae_atr + 0.50) / 1.50);
   string label = "NEUTRAL";
   if(target_hit)
      label = "TARGET_BEFORE_STOP";
   else if(mae_atr >= OutcomeStopAtr && mfe_atr < OutcomeTargetAtr)
      label = "STOP_BEFORE_TARGET";
   else if(mfe_atr >= OutcomeTargetAtr)
      label = "TARGET_AND_STOP_UNKNOWN_ORDER";

   FileWrite(handle,
             "OUTCOME",
             outcome.signal_id,
             FormatLocalTimestamp(TimeLocal()),
             TimeToString(now, TIME_DATE | TIME_SECONDS),
             outcome.symbol,
             outcome.timeframe_label,
             DirectionText(outcome.direction),
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             "",
             DoubleToString(outcome.entry_mid, 8),
             horizon_minutes,
             DoubleToString(outcome.mfe_pips, 2),
             DoubleToString(outcome.mae_pips, 2),
             DoubleToString(mfe_atr, 3),
             DoubleToString(mae_atr, 3),
             (target_hit ? "1" : "0"),
             DoubleToString(continuation_score, 3),
             label);

   FileClose(handle);
}

int OpenSignalLogForAppend()
{
   if(SignalLogFile == "")
      return INVALID_HANDLE;

   ResetLastError();
   int handle = FileOpen(SignalLogFile,
                         FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ,
                         ',');
   if(handle == INVALID_HANDLE)
   {
      PrintFormat("FXNews: could not open signal log '%s', error %d.",
                  SignalLogFile,
                  GetLastError());
      return INVALID_HANDLE;
   }

   bool empty_file = (FileSize(handle) == 0);
   FileSeek(handle, 0, SEEK_END);
   if(empty_file || !g_signal_log_header_checked)
   {
      if(empty_file)
         WriteSignalLogHeader(handle);
      g_signal_log_header_checked = true;
   }

   return handle;
}

void WriteSignalLogHeader(const int handle)
{
   FileWrite(handle,
             "row_type",
             "signal_id",
             "local_time",
             "server_time",
             "symbol",
             "timeframe",
             "direction",
             "displayed_score",
             "raw_score",
             "calibrated_score",
             "spread_pips",
             "median_spread_pips",
             "spread_ratio",
             "cost_to_atr",
             "atr",
             "range_width",
             "breakout_compression",
             "breakout_distance",
             "breakout_close_location",
             "breakout_hold",
             "breakout_body_quality",
             "breakout_wick_penalty",
             "breakout_fakeout_penalty",
             "impulse_speed_5s_z",
             "impulse_speed_10s_z",
             "impulse_speed_30s_z",
             "impulse_speed_60s_z",
             "impulse_acceleration",
             "impulse_atr_expansion",
             "impulse_tick_rate_z",
             "impulse_tick_volume_z",
             "impulse_exhaustion_penalty",
             "flow_base_strength",
             "flow_quote_strength",
             "flow_directional_edge",
             "flow_basket_agreement",
             "flow_conflict_penalty",
             "regime_session",
             "regime_mtf_alignment",
             "regime_m5_context",
             "regime_m15_context",
             "regime_volatility",
             "calendar_score",
             "calendar_proximity_minutes",
             "calendar_importance",
             "block_reason",
             "reason_summary",
             "entry_reference_price",
             "outcome_horizon_minutes",
             "mfe_pips",
             "mae_pips",
             "mfe_atr",
             "mae_atr",
             "target_hit_before_stop",
             "continuation_score",
             "final_outcome_label");
}

string DirectionText(const int direction)
{
   if(direction == DIR_UP)
      return "UP";
   if(direction == DIR_DOWN)
      return "DOWN";
   return "NONE";
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
   g_signal_history[0].timeframe_label = g_profiles[index].timeframe_label;
   g_signal_history[0].direction = direction;
   g_signal_history[0].local_time = local_time;
   g_signal_history[0].score = score;
   g_signal_history[0].text = FormatSignalHistoryText(g_signal_history[0].symbol,
                                                      g_signal_history[0].timeframe_label,
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
         g_signal_history[i].timeframe_label == g_profiles[index].timeframe_label &&
         g_signal_history[i].direction == direction &&
         g_signal_history[i].local_time == local_time)
      {
         g_signal_history[i].score = score;
         g_signal_history[i].text = FormatSignalHistoryText(g_signal_history[i].symbol,
                                                            g_signal_history[i].timeframe_label,
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
   target.timeframe_label = source.timeframe_label;
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
            PrintFormat("FXNews: failed to create dashboard object %s, error %d",
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
   return StringFormat("%s %s %s - %d%%",
                       g_profiles[index].symbol,
                       g_profiles[index].timeframe_label,
                       direction_text,
                       confidence);
}

string FormatSignalHistoryText(const string symbol,
                               const string timeframe_label,
                               const int direction,
                               const double score,
                               const datetime local_time)
{
   string direction_text = (direction == DIR_UP ? "UP" : "DOWN");
   int confidence = (int)MathRound(Clamp(score, 0.0, 100.0));
   return StringFormat("%s - %s %s %s - %d%%",
                       FormatLocalTimestamp(local_time),
                       symbol,
                       timeframe_label,
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

double TickGapSeconds(const int index, const long time_msc)
{
   if(time_msc <= 0 || g_profiles[index].snapshot_count <= 0)
      return 0.0;

   int last_position = g_profiles[index].snapshot_write_index - 1;
   if(last_position < 0)
      last_position = SNAPSHOT_CAPACITY - 1;
   int last_index = SnapshotIndex(index, last_position);
   if(g_snapshots[last_index].time_msc <= 0)
      return 0.0;

   return MathMax(0.0, (double)(time_msc - g_snapshots[last_index].time_msc) / 1000.0);
}

double TickRateFromSnapshots(const int index, const int seconds_back)
{
   int count = g_profiles[index].snapshot_count;
   if(count < 2 || seconds_back <= 0)
      return 0.0;

   long min_time = g_profiles[index].quote_time_msc - (long)seconds_back * 1000;
   int observed = 0;
   long first_time = 0;
   long last_time = 0;

   for(int logical = 0; logical < count; logical++)
   {
      int position = LogicalSnapshotPosition(index, logical);
      int sample_index = SnapshotIndex(index, position);
      long sample_time = g_snapshots[sample_index].time_msc;
      if(sample_time < min_time || sample_time <= 0)
         continue;
      if(first_time <= 0)
         first_time = sample_time;
      last_time = sample_time;
      observed++;
   }

   if(observed < 2 || last_time <= first_time)
      return 0.0;

   return (double)(observed - 1) / MathMax(1.0, (double)(last_time - first_time) / 1000.0);
}

double SpreadRobustZ(const int index)
{
   int count = g_profiles[index].spread_count;
   if(count < 5)
      return 0.0;

   double values[];
   ArrayResize(values, count);
   for(int i = 0; i < count; i++)
   {
      int position = LogicalSpreadPosition(index, i);
      values[i] = g_spread_history[SpreadIndex(index, position)];
   }

   double median = MedianOfArray(values, count);
   double mad = MedianAbsDeviation(values, count, median);
   return RobustZ(g_profiles[index].spread_pips, median, mad);
}

double SpeedRobustZ(const int index, const int direction, const int seconds_back)
{
   if(seconds_back <= 0 || g_profiles[index].pip_size <= 0.0)
      return 0.0;

   double median_rate = 0.0;
   double mad_rate = 0.0;
   SnapshotPipRateStats(index, median_rate, mad_rate);

   double directional_rate = DirectionalValue(MovementPips(index, seconds_back), direction) / (double)seconds_back;
   double atr_pips = MathMax(g_profiles[index].atr_m1 / g_profiles[index].pip_size, 0.1);
   double fallback_mad = MathMax(atr_pips / 600.0, 0.01);
   double denominator = MathMax(mad_rate * 1.4826, fallback_mad);
   return (directional_rate - median_rate) / denominator;
}

void SnapshotPipRateStats(const int index, double &median_rate, double &mad_rate)
{
   median_rate = 0.0;
   mad_rate = 0.0;
   int count = g_profiles[index].snapshot_count;
   if(count < 3 || g_profiles[index].pip_size <= 0.0)
      return;

   double rates[];
   ArrayResize(rates, 0);
   int added = 0;
   for(int logical = 1; logical < count; logical++)
   {
      int prev_position = LogicalSnapshotPosition(index, logical - 1);
      int curr_position = LogicalSnapshotPosition(index, logical);
      int prev_index = SnapshotIndex(index, prev_position);
      int curr_index = SnapshotIndex(index, curr_position);
      long dt = g_snapshots[curr_index].time_msc - g_snapshots[prev_index].time_msc;
      if(dt <= 0)
         continue;

      double pips = MathAbs(g_snapshots[curr_index].mid - g_snapshots[prev_index].mid) /
                    g_profiles[index].pip_size;
      ArrayResize(rates, added + 1);
      rates[added] = pips / MathMax(0.001, (double)dt / 1000.0);
      added++;
   }

   if(added <= 0)
      return;

   median_rate = MedianOfArray(rates, added);
   mad_rate = MedianAbsDeviation(rates, added, median_rate);
}

double TickRateZ(const int index)
{
   double rate = g_profiles[index].tick_rate_per_sec;
   if(rate <= 0.0)
      return -1.0;

   // Snapshot-derived tick rate is deliberately conservative; FX tick feeds differ by broker.
   return (rate - 0.18) / 0.18;
}

double TickVolumeRobustZ(const int index)
{
   double average_volume = g_profiles[index].average_m1_tick_volume;
   if(average_volume <= 0.0)
      return 0.0;

   // FX has no centralized real volume, so tick_volume is the practical default.
   double active_volume = MathMax(g_profiles[index].current_m1_tick_volume,
                                  g_profiles[index].last_completed_m1_tick_volume * 0.85);
   double ratio = SafeDiv(active_volume, average_volume, 1.0);
   return (ratio - 1.0) / 0.35;
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

double Clamp01(const double value)
{
   return Clamp(value, 0.0, 1.0);
}

double SmoothStep(const double edge0, const double edge1, const double x)
{
   if(edge1 == edge0)
      return (x >= edge1 ? 1.0 : 0.0);

   double t = Clamp01((x - edge0) / (edge1 - edge0));
   return t * t * (3.0 - 2.0 * t);
}

double SafeDiv(const double numerator, const double denominator, const double fallback)
{
   if(MathAbs(denominator) <= 0.0000000001)
      return fallback;
   return numerator / denominator;
}

double MedianOfArray(double &values[], const int count)
{
   if(count <= 0)
      return 0.0;

   ArraySort(values);
   if((count % 2) == 1)
      return values[count / 2];
   return (values[count / 2 - 1] + values[count / 2]) * 0.5;
}

double MedianAbsDeviation(double &values[], const int count, const double median)
{
   if(count <= 0)
      return 0.0;

   double deviations[];
   ArrayResize(deviations, count);
   for(int i = 0; i < count; i++)
      deviations[i] = MathAbs(values[i] - median);

   return MedianOfArray(deviations, count);
}

double RobustZ(const double value, const double median, const double mad)
{
   double denominator = mad * 1.4826;
   if(denominator <= 0.0000001)
   {
      if(MathAbs(value - median) <= 0.0000001)
         return 0.0;
      return (value > median ? 4.0 : -4.0);
   }
   return (value - median) / denominator;
}

double ScoreFromZ(const double z, const double low, const double high)
{
   return SmoothStep(low, high, z);
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
