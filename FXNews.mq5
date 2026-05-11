#property strict
#property indicator_chart_window
#property indicator_plots 0
#property description "Chart-only multi-symbol breakout radar indicator. No trade execution. No disk I/O."

enum ConfirmationMode
{
   CONFIRM_LIVE_TICK = 0,
   CONFIRM_BAR_CLOSE = 1,
   CONFIRM_HYBRID = 2
};

enum FXNewsOperatingMode
{
   FXNEWS_MODE_LIVE = 0,
   FXNEWS_MODE_VALIDATION = 1,
   FXNEWS_MODE_AUTOTUNE = 2
};

input FXNewsOperatingMode OperatingMode = FXNEWS_MODE_LIVE;
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

input int OutcomeHorizonMinutes1 = 5;
input int OutcomeHorizonMinutes2 = 15;
input int OutcomeHorizonMinutes3 = 30;
input double OutcomeTargetAtr = 0.50;
input double OutcomeStopAtr = 0.35;

input bool UseSessionAwareBaselines = true;
input int BaselineLookbackSamples = 500;
input int MinBaselineSamples = 50;
input bool ShowSessionOnDashboard = true;
input int AsiaStartHourServer = 0;
input int AsiaEndHourServer = 7;
input int LondonStartHourServer = 7;
input int LondonEndHourServer = 16;
input int NewYorkStartHourServer = 13;
input int NewYorkEndHourServer = 22;
input int LondonNYOverlapStartHourServer = 13;
input int LondonNYOverlapEndHourServer = 16;

input int MaxDashboardRows = 12;
input bool ShowOnlyGroupLeaders = false;
input bool ShowBlockedSignalsDebug = false;
input int SignalTTLSeconds = 180;
input bool ExpireOldSignals = true;
input ConfirmationMode SignalConfirmationMode = CONFIRM_HYBRID;

input bool UseCopyTicksForImpulse = true;
input int CopyTicksLookbackSeconds = 60;
input int MinCopyTicksForGoodQuality = 12;

input bool DebugScoreBreakdown = false;
input bool DebugPrintToJournal = false;
input bool ShowDiagnosticsPanel = false;
input bool PrintDiagnosticsEveryMinute = false;

input int HistoricalLookbackDays = 90;
input int HistoricalStepMinutes = 1;
input int HistoricalWarmupBars = 500;
input int HistoricalMaxSignalsPerProfile = 250;
input int AutotuneMinSignals = 100;

FXNewsOperatingMode g_runtime_operating_mode = FXNEWS_MODE_LIVE;
double g_min_display_confidence = 0.0;
double g_strong_alert_confidence = 0.0;
int g_range_lookback_m1 = 0;
double g_breakout_buffer_atr = 0.0;
double g_min_breakout_buffer_pips = 0.0;
double g_max_spread_to_atr = 0.0;
double g_min_impulse_z_for_signal = 0.0;
double g_max_overextension_atr = 0.0;
double g_outcome_target_atr = 0.0;
double g_outcome_stop_atr = 0.0;

#define DIR_NONE 0
#define DIR_UP 1
#define DIR_DOWN -1
#define SNAPSHOT_CAPACITY 90
#define SPREAD_HISTORY_CAPACITY 80
#define CURRENCY_COUNT 8
#define DASHBOARD_MAX_OBJECTS 40
#define DASHBOARD_ROW_HEIGHT 24
#define DASHBOARD_FONT_SIZE 11
#define SIGNAL_HISTORY_SIZE 5
#define SIGNAL_MESSAGE_REFRESH_SECONDS 10
#define SIGNAL_MESSAGE_MIN_SCORE 75.0
#define STATUS_ROW_INDEX 1
#define SIGNAL_FIRST_ROW_INDEX 3
#define CALENDAR_REFRESH_SECONDS 60
#define SESSION_COUNT 6

enum BreakoutEventState
{
   STATE_IDLE = 0,
   STATE_WATCH = 1,
   STATE_CANDIDATE = 2,
   STATE_ACTIVE_UNCONFIRMED = 3,
   STATE_ACTIVE_CONFIRMED = 4,
   STATE_ACTIVE_SIGNAL = 5,
   STATE_EXPIRED = 6,
   STATE_FAILED_FAST = 7,
   STATE_COOLDOWN = 8
};

enum ScoreStatus
{
   SCORE_RAW = 0
};

enum SessionBucket
{
   SESSION_ASIA = 0,
   SESSION_LONDON = 1,
   SESSION_NEW_YORK = 2,
   SESSION_LONDON_NY_OVERLAP = 3,
   SESSION_ROLLOVER = 4,
   SESSION_OTHER = 5
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
   double tick_sample_quality_score;
   int valid_ticks_used;
   string tick_state;
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
   string state_tag;
};

struct CompositeSignalScore
{
   bool valid;
   int direction;
   double raw_score;          // 0..100 before final caps
   double displayed_score;    // rounded dashboard score source
   ScoreStatus score_status;
   int score_bucket;
   ExecutionQuality execution;
   BreakoutStructure breakout;
   ImpulseQuality impulse;
   CurrencyFlowQuality flow;
   RegimeContext regime;
   CalendarContext calendar;
   SignalBlockReason block_reason;
   string reason_summary;
   string human_reason;
   string compact_tags;
};

struct SessionBaseline
{
   int sample_count;
   double spread_mean;
   double spread_var;
   double tick_rate_mean;
   double tick_rate_var;
   double tick_volume_mean;
   double tick_volume_var;
   double atr_mean;
   double atr_var;
   double speed_mean;
   double speed_var;
   double range_width_mean;
   double range_width_var;
   int breakout_count;
};

struct DashboardSignal
{
   int profile_index;
   int direction;
   double score;
   double raw_score;
   ScoreStatus score_status;
   datetime start_time;
   int age_seconds;
   string text;
   string tooltip;
   string group_id;
   bool group_leader;
   double sort_score;
};

struct HistoricalParams
{
   string name;
   int range_lookback;
   double breakout_buffer_atr;
   double min_breakout_buffer_pips;
   double min_confidence;
   double max_spread_to_atr;
   double max_overextension_atr;
   double min_impulse_z;
   double outcome_target_atr;
   double outcome_stop_atr;
};

struct HistoricalSignalScore
{
   bool valid;
   int direction;
   double displayed_score;
   double raw_score;
   double execution_score;
   double breakout_score;
   double impulse_score;
   double flow_score;
   double regime_score;
   double atr_price;
   double spread_pips;
   double spread_to_atr;
   double range_width_pips;
   double breakout_distance_atr;
   string reason;
};

struct HistoricalOutcome
{
   double mfe_5m_pips;
   double mae_5m_pips;
   double result_5m_R;
   bool target_5m;
   bool stop_5m;
   double mfe_15m_pips;
   double mae_15m_pips;
   double result_15m_R;
   bool target_15m;
   bool stop_15m;
   double mfe_30m_pips;
   double mae_30m_pips;
   double result_30m_R;
   bool target_30m;
   bool stop_30m;
};

struct HistoricalBacktestStats
{
   string params_name;
   datetime from_time;
   datetime to_time;
   int symbols_requested;
   int symbols_loaded;
   int profiles_tested;
   int bars_scanned;
   int signals;
   int target_5m;
   int stop_5m;
   int target_15m;
   int stop_15m;
   int target_30m;
   int stop_30m;
   double sum_score;
   double sum_result_5m_R;
   double sum_result_15m_R;
   double sum_result_30m_R;
   double gross_win_R;
   double gross_loss_R;
   double target_score_sum;
   int target_score_count;
   double stop_score_sum;
   int stop_score_count;
   int bucket60_count;
   int bucket65_count;
   int bucket70_count;
   int bucket75_count;
   int bucket80_count;
   int bucket85_count;
   double bucket60_R;
   double bucket65_R;
   double bucket70_R;
   double bucket75_R;
   double bucket80_R;
   double bucket85_R;
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
   double session_spread_z;
   double session_tick_rate_z;
   double session_tick_volume_z;
   double session_atr_z;
   double session_speed_z;
   double session_range_z;
   bool session_baseline_ready;
   int session_index;
   string session_name;
   double tick_sample_quality_score;
   int valid_ticks_used;
   string tick_state;

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
   BreakoutEventState previous_event_state;
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
   datetime last_inside_range_time;
   datetime last_confirmed_time;
   string dominant_currency_flow;
   string correlated_alert_group_id;
   bool group_leader_signal;
   int group_member_count;
   bool blocked_debug_visible;

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
SignalHistoryEntry g_visible_signal_history[SIGNAL_HISTORY_SIZE];
int g_signal_history_count = 0;
int g_visible_signal_history_count = 0;
ENUM_TIMEFRAMES g_scan_timeframes[];
string g_scan_timeframe_labels[];
double g_currency_strength[CURRENCY_COUNT];
int g_currency_samples[CURRENCY_COUNT];
double g_currency_weight[CURRENCY_COUNT];
string g_currency_codes[CURRENCY_COUNT] = {"EUR","USD","GBP","JPY","CHF","AUD","NZD","CAD"};
SessionBaseline g_session_baselines[];
CurrencyCalendarCache g_calendar_cache[CURRENCY_COUNT];
bool g_calendar_available = false;
datetime g_last_diagnostics_print = 0;
double g_average_scan_ms = 0.0;
double g_max_scan_ms = 0.0;
int g_scan_count = 0;
int g_last_valid_symbols = 0;
int g_last_invalid_symbols = 0;
int g_last_active_profiles = 0;
int g_last_tick_history_ok = 0;

datetime g_last_dashboard_update = 0;
datetime g_last_signal_message_refresh = 0;
string g_object_prefix = "COBR_";
bool g_historical_run_started = false;
bool g_historical_run_finished = false;
string g_historical_report_lines[];

void InitializeRuntimeSettings()
{
   g_runtime_operating_mode = OperatingMode;
   g_min_display_confidence = MinDisplayConfidence;
   g_strong_alert_confidence = StrongAlertConfidence;
   g_range_lookback_m1 = RangeLookbackM1;
   g_breakout_buffer_atr = BreakoutBufferATR;
   g_min_breakout_buffer_pips = MinBreakoutBufferPips;
   g_max_spread_to_atr = MaxSpreadToAtrRatio;
   g_min_impulse_z_for_signal = MinImpulseZForSignal;
   g_max_overextension_atr = MaxOverextensionAtr;
   g_outcome_target_atr = OutcomeTargetAtr;
   g_outcome_stop_atr = OutcomeStopAtr;
}

int OnInit()
{
   InitializeRuntimeSettings();

   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   g_object_prefix = "COBR_" + IntegerToString((int)(ChartID() % 1000000)) + "_";

   if(ParseSymbols() <= 0)
   {
      Print("FXNews: no valid symbols were provided.");
      return INIT_PARAMETERS_INCORRECT;
   }

   InitializeCalendarCache();

   AllocateHistoryBuffers();

   for(int i = 0; i < ArraySize(g_profiles); i++)
      EnsureSymbolReady(i);

   if(IsHistoricalMode())
      SetHistoricalReportHeader("FXNEWS " + OperatingModeText() + " | waiting to start historical run");

   ResetLastError();
   if(!EventSetTimer(IntMax(1, ScanIntervalSeconds)))
   {
      PrintFormat("FXNews: EventSetTimer failed, error %d", GetLastError());
      return INIT_FAILED;
   }

   if(!IsHistoricalMode())
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
   if(IsHistoricalMode())
   {
      RunHistoricalOperatingMode();
      return;
   }

   ScanAll(false);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return rates_total;
}

bool ValidateInputs()
{
   if(ScanIntervalSeconds < 1 || DisplayUpdateSeconds < 1 || MaxQuoteAgeSeconds < 1)
   {
      Print("FXNews: scan, display, and quote-age inputs must be positive.");
      return false;
   }

   if(g_min_display_confidence < 1.0 || g_min_display_confidence > 99.0 ||
      g_strong_alert_confidence < g_min_display_confidence || g_strong_alert_confidence > 100.0)
   {
      Print("FXNews: confidence inputs are inconsistent.");
      return false;
   }

   if(g_range_lookback_m1 < 10 || ATRPeriod < 2 ||
      g_breakout_buffer_atr < 0.0 || g_min_breakout_buffer_pips < 0.0)
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

   if(g_max_spread_to_atr <= 0.0 || MaxTickGapSeconds <= 0.0 || MaxSpreadZScore <= 0.0)
   {
      Print("FXNews: execution gate inputs must be positive.");
      return false;
   }

   if(MinHoldSecondsForHighScore < 0 || FullHoldScoreSeconds < 1 ||
      FullHoldScoreSeconds < MinHoldSecondsForHighScore || g_max_overextension_atr <= 0.0)
   {
      Print("FXNews: breakout-quality inputs are outside supported bounds.");
      return false;
   }

   if(g_min_impulse_z_for_signal < 0.0 || MaxExhaustionAtr <= 0.0 ||
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
      OutcomeHorizonMinutes3 < OutcomeHorizonMinutes2 || g_outcome_target_atr <= 0.0 ||
      g_outcome_stop_atr <= 0.0)
   {
      Print("FXNews: outcome inputs are inconsistent.");
      return false;
   }

   if(BaselineLookbackSamples < 50 || MinBaselineSamples < 10 ||
      MinBaselineSamples > BaselineLookbackSamples)
   {
      Print("FXNews: session baseline inputs are inconsistent.");
      return false;
   }

   if(MaxDashboardRows < 1 || MaxDashboardRows > DASHBOARD_MAX_OBJECTS - 2 ||
      SignalTTLSeconds < 30 || CopyTicksLookbackSeconds < 5 ||
      MinCopyTicksForGoodQuality < 1)
   {
      Print("FXNews: dashboard, lifecycle, or tick-quality inputs are inconsistent.");
      return false;
   }

   if(HistoricalLookbackDays < 1 || HistoricalStepMinutes < 1 ||
      HistoricalWarmupBars < 100 || HistoricalMaxSignalsPerProfile < 10 ||
      AutotuneMinSignals < 10)
   {
      Print("FXNews: historical validation/autotune inputs are inconsistent.");
      return false;
   }

   return true;
}

bool IsHistoricalMode()
{
   return (g_runtime_operating_mode == FXNEWS_MODE_VALIDATION ||
           g_runtime_operating_mode == FXNEWS_MODE_AUTOTUNE);
}

string OperatingModeText()
{
   if(g_runtime_operating_mode == FXNEWS_MODE_VALIDATION)
      return "VALIDATION";
   if(g_runtime_operating_mode == FXNEWS_MODE_AUTOTUNE)
      return "AUTOTUNE";
   return "LIVE";
}

void RunHistoricalOperatingMode()
{
   if(g_historical_run_finished)
      return;

   if(g_historical_run_started)
      return;

   g_historical_run_started = true;
   SetHistoricalReportHeader("FXNEWS " + OperatingModeText() + " | running M1 history simulation...");

   HistoricalParams base_params;
   BuildBaseHistoricalParams(base_params);

   if(g_runtime_operating_mode == FXNEWS_MODE_VALIDATION)
   {
      HistoricalBacktestStats stats;
      RunHistoricalBacktest(base_params, stats);
      BuildValidationReport(stats, base_params);
   }
   else
   {
      RunAutotuneBacktest(base_params);
   }

   g_historical_run_finished = true;
   UpdateHistoricalReportDashboard();
}

void BuildBaseHistoricalParams(HistoricalParams &params)
{
   params.name = "CURRENT";
   params.range_lookback = g_range_lookback_m1;
   params.breakout_buffer_atr = g_breakout_buffer_atr;
   params.min_breakout_buffer_pips = g_min_breakout_buffer_pips;
   params.min_confidence = g_min_display_confidence;
   params.max_spread_to_atr = g_max_spread_to_atr;
   params.max_overextension_atr = g_max_overextension_atr;
   params.min_impulse_z = g_min_impulse_z_for_signal;
   params.outcome_target_atr = g_outcome_target_atr;
   params.outcome_stop_atr = g_outcome_stop_atr;
}

void BuildAutotuneCandidate(const int candidate, const HistoricalParams &base_params, HistoricalParams &params)
{
   params = base_params;
   params.name = "C" + IntegerToString(candidate);

   if(candidate == 0)
   {
      params.name = "CURRENT";
      return;
   }

   if(candidate == 1)
   {
      params.name = "FAST";
      params.range_lookback = 20;
      params.breakout_buffer_atr = 0.08;
      params.min_breakout_buffer_pips = 0.8;
      params.min_confidence = 58.0;
      params.max_spread_to_atr = 0.50;
      params.max_overextension_atr = 2.20;
      params.min_impulse_z = 1.05;
      params.outcome_target_atr = 0.45;
      params.outcome_stop_atr = 0.30;
   }
   else if(candidate == 2)
   {
      params.name = "BALANCED";
      params.range_lookback = 30;
      params.breakout_buffer_atr = 0.12;
      params.min_breakout_buffer_pips = 1.0;
      params.min_confidence = 60.0;
      params.max_spread_to_atr = 0.45;
      params.max_overextension_atr = 2.00;
      params.min_impulse_z = 1.20;
      params.outcome_target_atr = 0.50;
      params.outcome_stop_atr = 0.35;
   }
   else if(candidate == 3)
   {
      params.name = "STRICT_EXEC";
      params.range_lookback = 30;
      params.breakout_buffer_atr = 0.12;
      params.min_breakout_buffer_pips = 1.2;
      params.min_confidence = 62.0;
      params.max_spread_to_atr = 0.35;
      params.max_overextension_atr = 1.80;
      params.min_impulse_z = 1.25;
      params.outcome_target_atr = 0.50;
      params.outcome_stop_atr = 0.35;
   }
   else if(candidate == 4)
   {
      params.name = "STRUCTURE";
      params.range_lookback = 45;
      params.breakout_buffer_atr = 0.15;
      params.min_breakout_buffer_pips = 1.2;
      params.min_confidence = 62.0;
      params.max_spread_to_atr = 0.45;
      params.max_overextension_atr = 1.80;
      params.min_impulse_z = 1.30;
      params.outcome_target_atr = 0.55;
      params.outcome_stop_atr = 0.35;
   }
   else if(candidate == 5)
   {
      params.name = "ANTI_FAKEOUT";
      params.range_lookback = 45;
      params.breakout_buffer_atr = 0.18;
      params.min_breakout_buffer_pips = 1.4;
      params.min_confidence = 64.0;
      params.max_spread_to_atr = 0.40;
      params.max_overextension_atr = 1.60;
      params.min_impulse_z = 1.35;
      params.outcome_target_atr = 0.55;
      params.outcome_stop_atr = 0.40;
   }
   else if(candidate == 6)
   {
      params.name = "MOMENTUM";
      params.range_lookback = 25;
      params.breakout_buffer_atr = 0.08;
      params.min_breakout_buffer_pips = 0.9;
      params.min_confidence = 64.0;
      params.max_spread_to_atr = 0.45;
      params.max_overextension_atr = 2.20;
      params.min_impulse_z = 1.10;
      params.outcome_target_atr = 0.60;
      params.outcome_stop_atr = 0.35;
   }
   else if(candidate == 7)
   {
      params.name = "QUALITY";
      params.range_lookback = 45;
      params.breakout_buffer_atr = 0.12;
      params.min_breakout_buffer_pips = 1.2;
      params.min_confidence = 66.0;
      params.max_spread_to_atr = 0.35;
      params.max_overextension_atr = 1.80;
      params.min_impulse_z = 1.40;
      params.outcome_target_atr = 0.60;
      params.outcome_stop_atr = 0.40;
   }
   else
   {
      params.name = "WIDE_FLOW";
      params.range_lookback = 35;
      params.breakout_buffer_atr = 0.10;
      params.min_breakout_buffer_pips = 1.0;
      params.min_confidence = 60.0;
      params.max_spread_to_atr = 0.55;
      params.max_overextension_atr = 2.10;
      params.min_impulse_z = 1.15;
      params.outcome_target_atr = 0.50;
      params.outcome_stop_atr = 0.30;
   }
}

void RunAutotuneBacktest(const HistoricalParams &base_params)
{
   HistoricalBacktestStats default_stats;
   RunHistoricalBacktest(base_params, default_stats);

   HistoricalBacktestStats best_stats = default_stats;
   HistoricalParams best_params = base_params;
   double default_objective = AutotuneObjective(default_stats);
   double best_objective = default_objective;

   for(int candidate = 1; candidate <= 8; candidate++)
   {
      if(IsStopped())
         break;

      HistoricalParams candidate_params;
      BuildAutotuneCandidate(candidate, base_params, candidate_params);

      HistoricalBacktestStats candidate_stats;
      RunHistoricalBacktest(candidate_params, candidate_stats);
      double objective = AutotuneObjective(candidate_stats);
      if(objective > best_objective)
      {
         best_objective = objective;
         best_stats = candidate_stats;
         best_params = candidate_params;
      }
   }

   bool applied = ApplyAutotuneParamsToRuntime(best_params, best_stats, default_objective, best_objective);
   BuildAutotuneReport(default_stats, best_stats, base_params, best_params, applied);

   g_runtime_operating_mode = FXNEWS_MODE_LIVE;
}

bool ApplyAutotuneParamsToRuntime(const HistoricalParams &params,
                                  const HistoricalBacktestStats &stats,
                                  const double default_objective,
                                  const double best_objective)
{
   if(stats.signals < AutotuneMinSignals)
      return false;
   if(best_objective <= default_objective + 0.01)
      return false;

   g_range_lookback_m1 = params.range_lookback;
   g_breakout_buffer_atr = params.breakout_buffer_atr;
   g_min_breakout_buffer_pips = params.min_breakout_buffer_pips;
   g_min_display_confidence = params.min_confidence;
   g_max_spread_to_atr = params.max_spread_to_atr;
   g_max_overextension_atr = params.max_overextension_atr;
   g_min_impulse_z_for_signal = params.min_impulse_z;
   g_outcome_target_atr = params.outcome_target_atr;
   g_outcome_stop_atr = params.outcome_stop_atr;

   if(g_strong_alert_confidence < g_min_display_confidence)
      g_strong_alert_confidence = MathMin(100.0, g_min_display_confidence + 5.0);

   return true;
}

double AutotuneObjective(const HistoricalBacktestStats &stats)
{
   if(stats.signals < AutotuneMinSignals)
      return -100000.0 + (double)stats.signals;

   return AverageR30(stats) * 100.0 +
          HitRate30(stats) * 25.0 -
          StopRate30(stats) * 15.0 +
          ProfitFactorProxy(stats) * 4.0 +
          ScoreEdge(stats) * 0.35;
}

void RunHistoricalBacktest(const HistoricalParams &params, HistoricalBacktestStats &stats)
{
   ResetHistoricalStats(stats);
   stats.params_name = params.name;

   string symbols[];
   int first_profile_indices[];
   int symbol_count = CollectHistoricalSymbols(symbols, first_profile_indices);
   stats.symbols_requested = symbol_count;

   for(int s = 0; s < symbol_count; s++)
   {
      if(IsStopped())
         return;

      MqlRates rates[];
      int copied = LoadHistoricalM1Rates(symbols[s], rates);
      if(copied <= 0)
         continue;

      stats.symbols_loaded++;
      if(stats.from_time == 0 || rates[0].time < stats.from_time)
         stats.from_time = rates[0].time;
      if(rates[copied - 1].time > stats.to_time)
         stats.to_time = rates[copied - 1].time;

      for(int profile_index = 0; profile_index < ArraySize(g_profiles); profile_index++)
      {
         if(!g_profiles[profile_index].valid ||
            UpperAscii(g_profiles[profile_index].symbol) != UpperAscii(symbols[s]))
         {
            continue;
         }

         ProcessHistoricalProfile(profile_index, rates, copied, params, stats);
      }
   }
}

int CollectHistoricalSymbols(string &symbols[], int &first_profile_indices[])
{
   ArrayResize(symbols, 0);
   ArrayResize(first_profile_indices, 0);

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!g_profiles[i].valid || !g_profiles[i].selected)
         continue;

      string candidate = UpperAscii(g_profiles[i].symbol);
      bool exists = false;
      for(int j = 0; j < ArraySize(symbols); j++)
      {
         if(UpperAscii(symbols[j]) == candidate)
         {
            exists = true;
            break;
         }
      }

      if(exists)
         continue;

      int next = ArraySize(symbols);
      ArrayResize(symbols, next + 1);
      ArrayResize(first_profile_indices, next + 1);
      symbols[next] = g_profiles[i].symbol;
      first_profile_indices[next] = i;
   }

   return ArraySize(symbols);
}

int LoadHistoricalM1Rates(const string symbol, MqlRates &rates[])
{
   ArrayResize(rates, 0);

   datetime last_closed = iTime(symbol, PERIOD_M1, 1);
   if(last_closed <= 0)
      last_closed = TimeCurrent() - 60;

   datetime from_time = last_closed - (datetime)HistoricalLookbackDays * 86400;
   ResetLastError();
   int copied = CopyRates(symbol, PERIOD_M1, from_time, last_closed, rates);
   if(copied <= 0)
      return 0;

   ArraySetAsSeries(rates, false);
   if(copied > 1 && rates[0].time > rates[copied - 1].time)
      ReverseRates(rates);

   return ArraySize(rates);
}

void ReverseRates(MqlRates &rates[])
{
   int total = ArraySize(rates);
   for(int i = 0; i < total / 2; i++)
   {
      MqlRates tmp = rates[i];
      rates[i] = rates[total - 1 - i];
      rates[total - 1 - i] = tmp;
   }
}

void ProcessHistoricalProfile(const int profile_index,
                              MqlRates &rates[],
                              const int copied,
                              const HistoricalParams &params,
                              HistoricalBacktestStats &stats)
{
   int tf_minutes = TimeframeMinutes(g_profiles[profile_index].scan_timeframe);
   if(tf_minutes <= 0)
      return;

   int required = (params.range_lookback + ATRPeriod + 4) * tf_minutes + 70;
   required = IntMax(required, HistoricalWarmupBars);
   int last_index = copied - OutcomeHorizonMinutes3 - 2;
   if(last_index <= required)
      return;

   stats.profiles_tested++;
   int step = IntMax(1, HistoricalStepMinutes);
   int cooldown_bars = IntMax(1, ValidSignalCooldownSeconds / 60);
   int next_up_allowed = -1000000;
   int next_down_allowed = -1000000;
   int profile_signals = 0;

   for(int i = required; i < last_index; i += step)
   {
      if(IsStopped())
         return;
      if(!IsHistoricalEvaluationBoundary(rates[i].time + 60, tf_minutes))
         continue;

      stats.bars_scanned++;

      HistoricalSignalScore up_score;
      HistoricalSignalScore down_score;
      BuildHistoricalSignalScore(profile_index, rates, copied, i, DIR_UP, params, up_score);
      BuildHistoricalSignalScore(profile_index, rates, copied, i, DIR_DOWN, params, down_score);

      HistoricalSignalScore best_score = up_score;
      if(down_score.valid && (!up_score.valid || down_score.displayed_score > up_score.displayed_score))
         best_score = down_score;

      if(!best_score.valid || best_score.displayed_score < params.min_confidence)
         continue;

      if(best_score.direction == DIR_UP && i < next_up_allowed)
         continue;
      if(best_score.direction == DIR_DOWN && i < next_down_allowed)
         continue;

      HistoricalOutcome outcome;
      EvaluateHistoricalOutcome(rates, copied, i, best_score.direction,
                                rates[i].close, best_score.atr_price,
                                g_profiles[profile_index].pip_size,
                                params,
                                outcome);
      AddHistoricalStats(stats, best_score, outcome);

      if(best_score.direction == DIR_UP)
         next_up_allowed = i + cooldown_bars;
      else
         next_down_allowed = i + cooldown_bars;

      profile_signals++;
      if(profile_signals >= HistoricalMaxSignalsPerProfile)
         break;
   }
}

void BuildHistoricalSignalScore(const int profile_index,
                                MqlRates &rates[],
                                const int copied,
                                const int index,
                                const int direction,
                                const HistoricalParams &params,
                                HistoricalSignalScore &score)
{
   ResetHistoricalSignalScore(score, direction);

   int tf_minutes = TimeframeMinutes(g_profiles[profile_index].scan_timeframe);
   if(tf_minutes <= 0 || index <= 0 || index >= copied)
      return;

   double current_open = 0.0;
   double current_high = 0.0;
   double current_low = 0.0;
   double current_close = 0.0;
   double current_volume = 0.0;
   if(!AggregateHistoricalTfBar(rates, index, tf_minutes,
                                current_open, current_high, current_low,
                                current_close, current_volume))
   {
      return;
   }

   double atr = HistoricalATR(rates, index, tf_minutes, ATRPeriod);
   if(atr <= 0.0)
      return;

   double range_high = 0.0;
   double range_low = 0.0;
   if(!HistoricalRangeBox(rates, index, tf_minutes, params.range_lookback, range_high, range_low))
      return;

   double range_width = range_high - range_low;
   if(range_width <= 0.0)
      return;

   double pip_size = g_profiles[profile_index].pip_size;
   double point = g_profiles[profile_index].point;
   if(pip_size <= 0.0 || point <= 0.0)
      return;

   double spread_pips = HistoricalSpreadPips(rates[index], point, pip_size);
   double median_spread_pips = HistoricalMedianSpreadPips(rates, index, point, pip_size, 120);
   double spread_price = spread_pips * pip_size;
   double spread_ratio = SafeDiv(spread_pips, MathMax(median_spread_pips, 0.1), 1.0);
   double spread_to_atr = SafeDiv(spread_price, atr, 999.0);

   if(IgnoreRolloverTime && IsRolloverTime(rates[index].time + 60))
      return;
   if(spread_pips <= 0.0 || spread_pips > MaxSpreadPips ||
      spread_ratio > MaxSpreadMedianMultiplier ||
      spread_to_atr > params.max_spread_to_atr)
   {
      return;
   }

   double buffer = Max3(spread_price * 1.20,
                        atr * params.breakout_buffer_atr,
                        params.min_breakout_buffer_pips * pip_size);
   double boundary = (direction == DIR_UP ? range_high + buffer : range_low - buffer);
   double breakout_distance = (direction == DIR_UP ? current_close - boundary : boundary - current_close);
   bool breakout_candidate = (breakout_distance > 0.0);

   double speed5 = HistoricalSpeedZ(rates, index, 5, 120, direction, pip_size);
   double speed10 = HistoricalSpeedZ(rates, index, 10, 120, direction, pip_size);
   double speed30 = HistoricalSpeedZ(rates, index, 30, 160, direction, pip_size);
   double speed60 = HistoricalSpeedZ(rates, index, 60, 200, direction, pip_size);
   double impulse_z = Max3(speed5, speed10, speed30);
   bool impulse_candidate = (impulse_z >= params.min_impulse_z);
   if(!breakout_candidate && !impulse_candidate)
      return;

   double execution_score = Clamp01(1.0 -
                                    SmoothStep(params.max_spread_to_atr * 0.45,
                                               params.max_spread_to_atr,
                                               spread_to_atr));
   execution_score = Clamp01(execution_score * 0.55 +
                             (1.0 - SmoothStep(1.0, MaxSpreadMedianMultiplier, spread_ratio)) * 0.45);

   double range_atr = range_width / atr;
   double compression = Clamp01(0.10 + 0.90 *
                                SmoothStep(0.65, 1.80, range_atr) *
                                (1.0 - SmoothStep(7.0, 16.0, range_atr)));
   double distance_units = SafeDiv(MathMax(breakout_distance, 0.0), buffer, 0.0);
   double distance_atr = SafeDiv(MathMax(breakout_distance, 0.0), atr, 0.0);
   double extension_penalty = SmoothStep(params.max_overextension_atr,
                                         params.max_overextension_atr * 1.80,
                                         distance_atr);
   double distance_score = Clamp01(SmoothStep(0.20, 1.60, distance_units) *
                                   (1.0 - extension_penalty * 0.45));
   double candle_range = current_high - current_low;
   double close_location = 0.50;
   double body_quality = 0.50;
   double wick_penalty = 0.0;
   if(candle_range > 0.0)
   {
      close_location = (direction == DIR_UP ?
                        Clamp01((current_close - current_low) / candle_range) :
                        Clamp01((current_high - current_close) / candle_range));
      double body = MathAbs(current_close - current_open);
      double body_ratio = body / candle_range;
      double directional_body = DirectionalValue(current_close - current_open, direction) / candle_range;
      body_quality = Clamp01(SmoothStep(0.18, 0.62, body_ratio) * 0.65 +
                             SmoothStep(0.03, 0.38, directional_body) * 0.35);
      double rejection_wick = (direction == DIR_UP ?
                               current_high - MathMax(current_open, current_close) :
                               MathMin(current_open, current_close) - current_low);
      wick_penalty = Clamp01(rejection_wick / candle_range);
   }

   double hold_score = HistoricalHoldScore(rates, index, direction, boundary);
   double breakout_score = Clamp01(compression * 0.17 +
                                   distance_score * 0.24 +
                                   close_location * 0.17 +
                                   hold_score * 0.20 +
                                   body_quality * 0.17 -
                                   wick_penalty * 0.15);

   double speed_score = ScoreFromZ(impulse_z, params.min_impulse_z, params.min_impulse_z + 2.75);
   double acceleration = SmoothStep(0.0, 0.10,
                                    SafeDiv(DirectionalValue(rates[index].close - rates[index - 5].close, direction) / pip_size, 5.0, 0.0) -
                                    SafeDiv(DirectionalValue(rates[index].close - rates[index - 30].close, direction) / pip_size, 30.0, 0.0));
   double atr_expansion = SmoothStep(0.20, 1.25,
                                     SafeDiv(DirectionalValue((direction == DIR_UP ?
                                                              current_high - current_open :
                                                              current_open - current_low),
                                                             DIR_UP),
                                             atr,
                                             0.0));
   double volume_score = ScoreFromZ(HistoricalTickVolumeZ(rates, index, 160), 0.50, 2.80);
   double continuation = SmoothStep(0.0, 0.80,
                                    SafeDiv(DirectionalValue(rates[index].close - rates[index - 5].close, direction),
                                            atr,
                                            0.0));
   double extended_atr = SafeDiv(DirectionalValue(rates[index].close - rates[index - 30].close, direction),
                                 atr,
                                 0.0);
   double exhaustion = SmoothStep(params.max_overextension_atr, params.max_overextension_atr * 1.70, extended_atr);
   double impulse_score = Clamp01(speed_score * 0.30 +
                                  atr_expansion * 0.20 +
                                  volume_score * 0.15 +
                                  acceleration * 0.15 +
                                  continuation * 0.20 -
                                  exhaustion * 0.22);

   double flow_score = HistoricalLocalFlowScore(rates, index, direction, atr);
   double m5_context = SmoothStep(-0.10, 0.55,
                                  SafeDiv(DirectionalValue(rates[index].close - rates[index - 5].close, direction),
                                          atr,
                                          0.0));
   double m15_context = SmoothStep(-0.10, 0.45,
                                   SafeDiv(DirectionalValue(rates[index].close - rates[index - 15].close, direction),
                                           atr,
                                           0.0));
   double regime_score = Clamp01(SessionQualityScore(rates[index].time) * 0.35 +
                                 m5_context * 0.30 +
                                 m15_context * 0.25 +
                                 (1.0 - SmoothStep(0.0, 4.5, MathAbs(range_atr - 3.0))) * 0.10);

   double raw01 = breakout_score * 0.26 +
                  impulse_score * 0.26 +
                  execution_score * 0.18 +
                  flow_score * 0.16 +
                  regime_score * 0.14;
   double final_score = 100.0 * SmoothStep(0.35, 0.92, raw01);

   string caps = "";
   if(hold_score < 0.35 && breakout_candidate)
      final_score = ApplyHistoricalCap(final_score, 74.0, caps, "weak_hold");
   if(body_quality < 0.35)
      final_score = ApplyHistoricalCap(final_score, 79.0, caps, "weak_body");
   if(flow_score < 0.35)
      final_score = ApplyHistoricalCap(final_score, 69.0, caps, "flow_conflict");
   if(UseMultiTimeframeContextCaps && (m5_context < 0.20 || m15_context < 0.20))
      final_score = ApplyHistoricalCap(final_score, 69.0, caps, "mtf_reject");
   if(exhaustion >= 0.45)
      final_score = ApplyHistoricalCap(final_score, 75.0, caps, "overextended");
   if(final_score > 95.0)
      final_score = 95.0;

   score.valid = (final_score >= params.min_confidence);
   score.displayed_score = Clamp(final_score, 0.0, 100.0);
   score.raw_score = score.displayed_score;
   score.execution_score = execution_score;
   score.breakout_score = breakout_score;
   score.impulse_score = impulse_score;
   score.flow_score = flow_score;
   score.regime_score = regime_score;
   score.atr_price = atr;
   score.spread_pips = spread_pips;
   score.spread_to_atr = spread_to_atr;
   score.range_width_pips = range_width / pip_size;
   score.breakout_distance_atr = SafeDiv(MathMax(breakout_distance, 0.0), atr, 0.0);
   score.reason = StringFormat("BRK %.2f IMP %.2f FLOW %.2f EXEC %.2f %s",
                               breakout_score,
                               impulse_score,
                               flow_score,
                               execution_score,
                               caps);
}

void ResetHistoricalSignalScore(HistoricalSignalScore &score, const int direction)
{
   score.valid = false;
   score.direction = direction;
   score.displayed_score = 0.0;
   score.raw_score = 0.0;
   score.execution_score = 0.0;
   score.breakout_score = 0.0;
   score.impulse_score = 0.0;
   score.flow_score = 0.0;
   score.regime_score = 0.0;
   score.atr_price = 0.0;
   score.spread_pips = 0.0;
   score.spread_to_atr = 0.0;
   score.range_width_pips = 0.0;
   score.breakout_distance_atr = 0.0;
   score.reason = "";
}

bool AggregateHistoricalTfBar(MqlRates &rates[],
                              const int end_index,
                              const int tf_minutes,
                              double &open,
                              double &high,
                              double &low,
                              double &close,
                              double &tick_volume)
{
   int start_index = end_index - tf_minutes + 1;
   if(start_index < 0 || end_index >= ArraySize(rates))
      return false;

   open = rates[start_index].open;
   high = rates[start_index].high;
   low = rates[start_index].low;
   close = rates[end_index].close;
   tick_volume = 0.0;

   for(int i = start_index; i <= end_index; i++)
   {
      high = MathMax(high, rates[i].high);
      low = MathMin(low, rates[i].low);
      tick_volume += (double)rates[i].tick_volume;
   }

   return true;
}

double HistoricalATR(MqlRates &rates[], const int current_index, const int tf_minutes, const int period)
{
   double total = 0.0;
   int counted = 0;
   for(int bar = 1; bar <= period; bar++)
   {
      int end_index = current_index - bar * tf_minutes;
      int previous_end = current_index - (bar + 1) * tf_minutes;
      if(end_index < 0 || previous_end < 0)
         break;

      double open = 0.0;
      double high = 0.0;
      double low = 0.0;
      double close = 0.0;
      double volume = 0.0;
      if(!AggregateHistoricalTfBar(rates, end_index, tf_minutes, open, high, low, close, volume))
         break;

      double previous_close = rates[previous_end].close;
      total += Max3(high - low, MathAbs(high - previous_close), MathAbs(low - previous_close));
      counted++;
   }

   if(counted <= 0)
      return 0.0;
   return total / (double)counted;
}

bool HistoricalRangeBox(MqlRates &rates[],
                        const int current_index,
                        const int tf_minutes,
                        const int lookback,
                        double &range_high,
                        double &range_low)
{
   bool initialized = false;
   for(int bar = 1; bar <= lookback; bar++)
   {
      int end_index = current_index - bar * tf_minutes;
      if(end_index < 0)
         return false;

      double open = 0.0;
      double high = 0.0;
      double low = 0.0;
      double close = 0.0;
      double volume = 0.0;
      if(!AggregateHistoricalTfBar(rates, end_index, tf_minutes, open, high, low, close, volume))
         return false;

      if(!initialized)
      {
         range_high = high;
         range_low = low;
         initialized = true;
      }
      else
      {
         range_high = MathMax(range_high, high);
         range_low = MathMin(range_low, low);
      }
   }

   return initialized;
}

double HistoricalSpreadPips(const MqlRates &rate, const double point, const double pip_size)
{
   if(rate.spread > 0)
      return (double)rate.spread * point / pip_size;
   return MathMin(MaxSpreadPips * 0.50, 1.0);
}

double HistoricalMedianSpreadPips(MqlRates &rates[],
                                  const int index,
                                  const double point,
                                  const double pip_size,
                                  const int lookback)
{
   int count = IntMin(lookback, index);
   if(count <= 0)
      return HistoricalSpreadPips(rates[index], point, pip_size);

   double values[];
   ArrayResize(values, count);
   for(int i = 0; i < count; i++)
      values[i] = HistoricalSpreadPips(rates[index - 1 - i], point, pip_size);

   return MedianOfArray(values, count);
}

double HistoricalTickVolumeZ(MqlRates &rates[], const int index, const int lookback)
{
   int count = IntMin(lookback, index);
   if(count <= 10)
      return 0.0;

   double values[];
   ArrayResize(values, count);
   for(int i = 0; i < count; i++)
      values[i] = (double)rates[index - 1 - i].tick_volume;

   double median = MedianOfArray(values, count);
   double mad = MedianAbsDeviation(values, count, median);
   return RobustZ((double)rates[index].tick_volume, median, mad);
}

double HistoricalSpeedZ(MqlRates &rates[],
                        const int index,
                        const int window_minutes,
                        const int lookback,
                        const int direction,
                        const double pip_size)
{
   if(index <= window_minutes || pip_size <= 0.0)
      return 0.0;

   int count = IntMin(lookback, index - window_minutes - 1);
   if(count <= 10)
      return 0.0;

   double values[];
   ArrayResize(values, count);
   for(int i = 0; i < count; i++)
   {
      int end_index = index - 1 - i;
      values[i] = MathAbs(rates[end_index].close - rates[end_index - window_minutes].close) / pip_size;
   }

   double current = DirectionalValue(rates[index].close - rates[index - window_minutes].close, direction) / pip_size;
   double median = MedianOfArray(values, count);
   double mad = MedianAbsDeviation(values, count, median);
   return RobustZ(current, median, mad);
}

double HistoricalHoldScore(MqlRates &rates[],
                           const int index,
                           const int direction,
                           const double boundary)
{
   int outside = 0;
   for(int i = index; i >= 0 && i > index - 4; i--)
   {
      bool is_outside = (direction == DIR_UP ? rates[i].close > boundary : rates[i].close < boundary);
      if(!is_outside)
         break;
      outside++;
   }

   if(outside <= 0)
      return 0.0;
   if(outside == 1)
      return 0.50;
   if(outside == 2)
      return 0.75;
   return 1.0;
}

double HistoricalLocalFlowScore(MqlRates &rates[], const int index, const int direction, const double atr)
{
   if(index < 60 || atr <= 0.0)
      return 0.50;

   double move30 = SafeDiv(DirectionalValue(rates[index].close - rates[index - 30].close, direction), atr, 0.0);
   double move60 = SafeDiv(DirectionalValue(rates[index].close - rates[index - 60].close, direction), atr, 0.0);
   double edge = move30 * 0.60 + move60 * 0.40;
   return SmoothStep(-0.10, 0.70, edge);
}

void EvaluateHistoricalOutcome(MqlRates &rates[],
                               const int copied,
                               const int signal_index,
                               const int direction,
                               const double entry,
                               const double atr_price,
                               const double pip_size,
                               const HistoricalParams &params,
                               HistoricalOutcome &outcome)
{
   ResetHistoricalOutcome(outcome);
   EvaluateHistoricalOutcomeAtHorizon(rates, copied, signal_index, direction, entry,
                                      atr_price, pip_size, params.outcome_target_atr,
                                      params.outcome_stop_atr, OutcomeHorizonMinutes1,
                                      outcome.mfe_5m_pips, outcome.mae_5m_pips,
                                      outcome.result_5m_R, outcome.target_5m, outcome.stop_5m);
   EvaluateHistoricalOutcomeAtHorizon(rates, copied, signal_index, direction, entry,
                                      atr_price, pip_size, params.outcome_target_atr,
                                      params.outcome_stop_atr, OutcomeHorizonMinutes2,
                                      outcome.mfe_15m_pips, outcome.mae_15m_pips,
                                      outcome.result_15m_R, outcome.target_15m, outcome.stop_15m);
   EvaluateHistoricalOutcomeAtHorizon(rates, copied, signal_index, direction, entry,
                                      atr_price, pip_size, params.outcome_target_atr,
                                      params.outcome_stop_atr, OutcomeHorizonMinutes3,
                                      outcome.mfe_30m_pips, outcome.mae_30m_pips,
                                      outcome.result_30m_R, outcome.target_30m, outcome.stop_30m);
}

void ResetHistoricalOutcome(HistoricalOutcome &outcome)
{
   outcome.mfe_5m_pips = 0.0;
   outcome.mae_5m_pips = 0.0;
   outcome.result_5m_R = 0.0;
   outcome.target_5m = false;
   outcome.stop_5m = false;
   outcome.mfe_15m_pips = 0.0;
   outcome.mae_15m_pips = 0.0;
   outcome.result_15m_R = 0.0;
   outcome.target_15m = false;
   outcome.stop_15m = false;
   outcome.mfe_30m_pips = 0.0;
   outcome.mae_30m_pips = 0.0;
   outcome.result_30m_R = 0.0;
   outcome.target_30m = false;
   outcome.stop_30m = false;
}

void EvaluateHistoricalOutcomeAtHorizon(MqlRates &rates[],
                                        const int copied,
                                        const int signal_index,
                                        const int direction,
                                        const double entry,
                                        const double atr_price,
                                        const double pip_size,
                                        const double target_atr,
                                        const double stop_atr,
                                        const int horizon_minutes,
                                        double &mfe_pips,
                                        double &mae_pips,
                                        double &result_R,
                                        bool &target_hit,
                                        bool &stop_hit)
{
   mfe_pips = 0.0;
   mae_pips = 0.0;
   result_R = 0.0;
   target_hit = false;
   stop_hit = false;

   double target_price = atr_price * target_atr;
   double stop_price = atr_price * stop_atr;
   if(target_price <= 0.0 || stop_price <= 0.0 || pip_size <= 0.0)
      return;

   int last_index = IntMin(copied - 1, signal_index + horizon_minutes);
   for(int i = signal_index + 1; i <= last_index; i++)
   {
      double favorable = 0.0;
      double adverse = 0.0;
      if(direction == DIR_UP)
      {
         favorable = rates[i].high - entry;
         adverse = entry - rates[i].low;
      }
      else
      {
         favorable = entry - rates[i].low;
         adverse = rates[i].high - entry;
      }

      mfe_pips = MathMax(mfe_pips, favorable / pip_size);
      mae_pips = MathMax(mae_pips, adverse / pip_size);

      bool target_now = (favorable >= target_price);
      bool stop_now = (adverse >= stop_price);
      if(!target_hit && !stop_hit)
      {
         if(target_now && stop_now)
            stop_hit = true; // pessimistic for same-M1 ambiguity.
         else if(target_now)
            target_hit = true;
         else if(stop_now)
            stop_hit = true;
      }
   }

   if(target_hit && !stop_hit)
      result_R = 1.0;
   else if(stop_hit && !target_hit)
      result_R = -1.0;
   else
   {
      double close_move = DirectionalValue(rates[last_index].close - entry, direction);
      result_R = Clamp(SafeDiv(close_move, target_price, 0.0), -1.0, 1.0);
   }
}

void AddHistoricalStats(HistoricalBacktestStats &stats,
                        const HistoricalSignalScore &score,
                        const HistoricalOutcome &outcome)
{
   stats.signals++;
   stats.sum_score += score.displayed_score;
   stats.sum_result_5m_R += outcome.result_5m_R;
   stats.sum_result_15m_R += outcome.result_15m_R;
   stats.sum_result_30m_R += outcome.result_30m_R;

   if(outcome.target_5m)
      stats.target_5m++;
   if(outcome.stop_5m)
      stats.stop_5m++;
   if(outcome.target_15m)
      stats.target_15m++;
   if(outcome.stop_15m)
      stats.stop_15m++;
   if(outcome.target_30m)
   {
      stats.target_30m++;
      stats.target_score_sum += score.displayed_score;
      stats.target_score_count++;
   }
   if(outcome.stop_30m)
   {
      stats.stop_30m++;
      stats.stop_score_sum += score.displayed_score;
      stats.stop_score_count++;
   }

   if(outcome.result_30m_R > 0.0)
      stats.gross_win_R += outcome.result_30m_R;
   else if(outcome.result_30m_R < 0.0)
      stats.gross_loss_R += MathAbs(outcome.result_30m_R);

   AddHistoricalBucketStats(stats, ScoreBucketFloor(score.displayed_score), outcome.result_30m_R);
}

void AddHistoricalBucketStats(HistoricalBacktestStats &stats, const int bucket, const double result_R)
{
   if(bucket >= 85)
   {
      stats.bucket85_count++;
      stats.bucket85_R += result_R;
   }
   else if(bucket >= 80)
   {
      stats.bucket80_count++;
      stats.bucket80_R += result_R;
   }
   else if(bucket >= 75)
   {
      stats.bucket75_count++;
      stats.bucket75_R += result_R;
   }
   else if(bucket >= 70)
   {
      stats.bucket70_count++;
      stats.bucket70_R += result_R;
   }
   else if(bucket >= 65)
   {
      stats.bucket65_count++;
      stats.bucket65_R += result_R;
   }
   else
   {
      stats.bucket60_count++;
      stats.bucket60_R += result_R;
   }
}

void ResetHistoricalStats(HistoricalBacktestStats &stats)
{
   stats.params_name = "";
   stats.from_time = 0;
   stats.to_time = 0;
   stats.symbols_requested = 0;
   stats.symbols_loaded = 0;
   stats.profiles_tested = 0;
   stats.bars_scanned = 0;
   stats.signals = 0;
   stats.target_5m = 0;
   stats.stop_5m = 0;
   stats.target_15m = 0;
   stats.stop_15m = 0;
   stats.target_30m = 0;
   stats.stop_30m = 0;
   stats.sum_score = 0.0;
   stats.sum_result_5m_R = 0.0;
   stats.sum_result_15m_R = 0.0;
   stats.sum_result_30m_R = 0.0;
   stats.gross_win_R = 0.0;
   stats.gross_loss_R = 0.0;
   stats.target_score_sum = 0.0;
   stats.target_score_count = 0;
   stats.stop_score_sum = 0.0;
   stats.stop_score_count = 0;
   stats.bucket60_count = 0;
   stats.bucket65_count = 0;
   stats.bucket70_count = 0;
   stats.bucket75_count = 0;
   stats.bucket80_count = 0;
   stats.bucket85_count = 0;
   stats.bucket60_R = 0.0;
   stats.bucket65_R = 0.0;
   stats.bucket70_R = 0.0;
   stats.bucket75_R = 0.0;
   stats.bucket80_R = 0.0;
   stats.bucket85_R = 0.0;
}

void BuildValidationReport(const HistoricalBacktestStats &stats, const HistoricalParams &params)
{
   ClearHistoricalReport();
   AddHistoricalReportLine("FXNEWS VALIDATION REPORT | M1 HISTORY BACKTEST | NO FILE OUTPUT");
   AddHistoricalReportLine(StringFormat("Window: %s -> %s | Lookback=%d days | Symbols %d/%d | Profiles=%d",
                                        TimeToString(stats.from_time, TIME_DATE | TIME_MINUTES),
                                        TimeToString(stats.to_time, TIME_DATE | TIME_MINUTES),
                                        HistoricalLookbackDays,
                                        stats.symbols_loaded,
                                        stats.symbols_requested,
                                        stats.profiles_tested));
   AddHistoricalReportLine(StringFormat("Params: range=%d bufferATR=%.2f minPips=%.1f minScore=%.1f spreadATR=%.2f overext=%.2f impulseZ=%.2f target=%.2f stop=%.2f",
                                        params.range_lookback,
                                        params.breakout_buffer_atr,
                                        params.min_breakout_buffer_pips,
                                        params.min_confidence,
                                        params.max_spread_to_atr,
                                        params.max_overextension_atr,
                                        params.min_impulse_z,
                                        params.outcome_target_atr,
                                        params.outcome_stop_atr));
   AddHistoricalReportLine(StringFormat("Signals=%d | Bars scanned=%d | Avg score=%.1f | PF=%.2f | AvgR 5/15/30m = %.3f / %.3f / %.3f",
                                        stats.signals,
                                        stats.bars_scanned,
                                        AverageScore(stats),
                                        ProfitFactorProxy(stats),
                                        AverageR5(stats),
                                        AverageR15(stats),
                                        AverageR30(stats)));
   AddHistoricalReportLine(StringFormat("Target-first 5/15/30m = %.1f%% / %.1f%% / %.1f%% | Stop-first 5/15/30m = %.1f%% / %.1f%% / %.1f%%",
                                        HitRate5(stats) * 100.0,
                                        HitRate15(stats) * 100.0,
                                        HitRate30(stats) * 100.0,
                                        StopRate5(stats) * 100.0,
                                        StopRate15(stats) * 100.0,
                                        StopRate30(stats) * 100.0));
   AddHistoricalReportLine(StringFormat("Score edge: target-first avg %.1f%% vs stop-first avg %.1f%% = %+0.1f pts",
                                        AverageTargetScore(stats),
                                        AverageStopScore(stats),
                                        ScoreEdge(stats)));
   AddHistoricalReportLine("Buckets by displayed score: count | avg 30m R");
   AddHistoricalReportLine(FormatHistoricalBucketLine("60-64", stats.bucket60_count, stats.bucket60_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("65-69", stats.bucket65_count, stats.bucket65_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("70-74", stats.bucket70_count, stats.bucket70_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("75-79", stats.bucket75_count, stats.bucket75_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("80-84", stats.bucket80_count, stats.bucket80_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("85+", stats.bucket85_count, stats.bucket85_R));
   AddHistoricalReportLine("Interpretation: score is a ranking metric. A useful score should show better R/PF in higher buckets.");
   PrintHistoricalReportToJournal();
   SetHistoricalReadyMessage("VALIDATION");
}

void BuildAutotuneReport(const HistoricalBacktestStats &default_stats,
                         const HistoricalBacktestStats &best_stats,
                         const HistoricalParams &default_params,
                         const HistoricalParams &best_params,
                         const bool applied)
{
   ClearHistoricalReport();
   AddHistoricalReportLine("FXNEWS AUTOTUNE REPORT | M1 HISTORY BACKTEST | NO FILE OUTPUT");
   AddHistoricalReportLine(StringFormat("Window: %s -> %s | Lookback=%d days | Symbols %d/%d | Profiles=%d",
                                        TimeToString(default_stats.from_time, TIME_DATE | TIME_MINUTES),
                                        TimeToString(default_stats.to_time, TIME_DATE | TIME_MINUTES),
                                        HistoricalLookbackDays,
                                        default_stats.symbols_loaded,
                                        default_stats.symbols_requested,
                                        default_stats.profiles_tested));
   AddHistoricalReportLine(StringFormat("Current: signals=%d avgScore=%.1f PF=%.2f AvgR30=%.3f Hit30=%.1f%% Edge=%+.1f pts",
                                        default_stats.signals,
                                        AverageScore(default_stats),
                                        ProfitFactorProxy(default_stats),
                                        AverageR30(default_stats),
                                        HitRate30(default_stats) * 100.0,
                                        ScoreEdge(default_stats)));
   AddHistoricalReportLine(StringFormat("Best %s: signals=%d avgScore=%.1f PF=%.2f AvgR30=%.3f Hit30=%.1f%% Edge=%+.1f pts",
                                        best_params.name,
                                        best_stats.signals,
                                        AverageScore(best_stats),
                                        ProfitFactorProxy(best_stats),
                                        AverageR30(best_stats),
                                        HitRate30(best_stats) * 100.0,
                                        ScoreEdge(best_stats)));
   AddHistoricalReportLine(StringFormat("Improvement: AvgR30 %+0.3f | Hit30 %+0.1f pts | PF %+0.2f | score edge %+0.1f pts",
                                        AverageR30(best_stats) - AverageR30(default_stats),
                                        (HitRate30(best_stats) - HitRate30(default_stats)) * 100.0,
                                        ProfitFactorProxy(best_stats) - ProfitFactorProxy(default_stats),
                                        ScoreEdge(best_stats) - ScoreEdge(default_stats)));
   AddHistoricalReportLine(StringFormat("Recommended effective settings: RangeLookbackM1=%d BreakoutBufferATR=%.2f MinBreakoutBufferPips=%.1f",
                                        best_params.range_lookback,
                                        best_params.breakout_buffer_atr,
                                        best_params.min_breakout_buffer_pips));
   AddHistoricalReportLine(StringFormat("Recommended effective settings: MinDisplayConfidence=%.1f MaxSpreadToAtrRatio=%.2f MaxOverextensionAtr=%.2f",
                                        best_params.min_confidence,
                                        best_params.max_spread_to_atr,
                                        best_params.max_overextension_atr));
   AddHistoricalReportLine(StringFormat("Recommended effective settings: MinImpulseZForSignal=%.2f OutcomeTargetAtr=%.2f OutcomeStopAtr=%.2f",
                                        best_params.min_impulse_z,
                                        best_params.outcome_target_atr,
                                        best_params.outcome_stop_atr));
   AddHistoricalReportLine(StringFormat("Current settings baseline: Range=%d BufferATR=%.2f MinPips=%.1f MinScore=%.1f SpreadATR=%.2f Overext=%.2f ImpulseZ=%.2f Target=%.2f Stop=%.2f",
                                        default_params.range_lookback,
                                        default_params.breakout_buffer_atr,
                                        default_params.min_breakout_buffer_pips,
                                        default_params.min_confidence,
                                        default_params.max_spread_to_atr,
                                        default_params.max_overextension_atr,
                                        default_params.min_impulse_z,
                                        default_params.outcome_target_atr,
                                        default_params.outcome_stop_atr));
   AddHistoricalReportLine("Best score buckets: count | avg 30m R");
   AddHistoricalReportLine(FormatHistoricalBucketLine("60-64", best_stats.bucket60_count, best_stats.bucket60_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("65-69", best_stats.bucket65_count, best_stats.bucket65_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("70-74", best_stats.bucket70_count, best_stats.bucket70_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("75-79", best_stats.bucket75_count, best_stats.bucket75_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("80-84", best_stats.bucket80_count, best_stats.bucket80_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("85+", best_stats.bucket85_count, best_stats.bucket85_R));
   if(best_stats.signals < AutotuneMinSignals)
      AddHistoricalReportLine("Applied: no change; low sample count, current session will continue in LIVE mode.");
   else if(applied)
      AddHistoricalReportLine("Applied: runtime settings updated and current session will continue in LIVE mode.");
   else
      AddHistoricalReportLine("Applied: no change; current runtime settings already ranked best and LIVE mode will continue.");

   PrintHistoricalReportToJournal();
   SetHistoricalReadyMessage("AUTOTUNE");
}

string FormatHistoricalBucketLine(const string label, const int count, const double sum_R)
{
   return StringFormat("  %s : %5d | %+0.3f R", label, count, SafeDiv(sum_R, (double)count, 0.0));
}

double AverageScore(const HistoricalBacktestStats &stats)
{
   return SafeDiv(stats.sum_score, (double)stats.signals, 0.0);
}

double AverageR5(const HistoricalBacktestStats &stats)
{
   return SafeDiv(stats.sum_result_5m_R, (double)stats.signals, 0.0);
}

double AverageR15(const HistoricalBacktestStats &stats)
{
   return SafeDiv(stats.sum_result_15m_R, (double)stats.signals, 0.0);
}

double AverageR30(const HistoricalBacktestStats &stats)
{
   return SafeDiv(stats.sum_result_30m_R, (double)stats.signals, 0.0);
}

double HitRate5(const HistoricalBacktestStats &stats)
{
   return SafeDiv((double)stats.target_5m, (double)stats.signals, 0.0);
}

double HitRate15(const HistoricalBacktestStats &stats)
{
   return SafeDiv((double)stats.target_15m, (double)stats.signals, 0.0);
}

double HitRate30(const HistoricalBacktestStats &stats)
{
   return SafeDiv((double)stats.target_30m, (double)stats.signals, 0.0);
}

double StopRate5(const HistoricalBacktestStats &stats)
{
   return SafeDiv((double)stats.stop_5m, (double)stats.signals, 0.0);
}

double StopRate15(const HistoricalBacktestStats &stats)
{
   return SafeDiv((double)stats.stop_15m, (double)stats.signals, 0.0);
}

double StopRate30(const HistoricalBacktestStats &stats)
{
   return SafeDiv((double)stats.stop_30m, (double)stats.signals, 0.0);
}

double ProfitFactorProxy(const HistoricalBacktestStats &stats)
{
   return SafeDiv(stats.gross_win_R, stats.gross_loss_R, stats.gross_win_R > 0.0 ? 99.0 : 0.0);
}

double AverageTargetScore(const HistoricalBacktestStats &stats)
{
   return SafeDiv(stats.target_score_sum, (double)stats.target_score_count, 0.0);
}

double AverageStopScore(const HistoricalBacktestStats &stats)
{
   return SafeDiv(stats.stop_score_sum, (double)stats.stop_score_count, 0.0);
}

double ScoreEdge(const HistoricalBacktestStats &stats)
{
   if(stats.target_score_count <= 0 || stats.stop_score_count <= 0)
      return 0.0;
   return AverageTargetScore(stats) - AverageStopScore(stats);
}

double ApplyHistoricalCap(const double score, const double cap, string &caps, const string reason)
{
   if(score <= cap)
      return score;
   if(caps != "")
      caps += "|";
   caps += reason;
   return cap;
}

bool IsHistoricalEvaluationBoundary(const datetime close_time, const int tf_minutes)
{
   if(tf_minutes <= 1)
      return true;

   MqlDateTime parts;
   TimeToStruct(close_time, parts);
   int minute_of_day = parts.hour * 60 + parts.min;
   if(tf_minutes >= 1440)
      return (parts.hour == 0 && parts.min == 0);

   return ((minute_of_day % tf_minutes) == 0);
}

int TimeframeMinutes(const ENUM_TIMEFRAMES timeframe)
{
   if(timeframe == PERIOD_M1)
      return 1;
   if(timeframe == PERIOD_M5)
      return 5;
   if(timeframe == PERIOD_M15)
      return 15;
   if(timeframe == PERIOD_M30)
      return 30;
   if(timeframe == PERIOD_H1)
      return 60;
   if(timeframe == PERIOD_H4)
      return 240;
   if(timeframe == PERIOD_H8)
      return 480;
   if(timeframe == PERIOD_H12)
      return 720;
   if(timeframe == PERIOD_D1)
      return 1440;
   return 0;
}

void SetHistoricalReportHeader(const string text)
{
   ClearHistoricalReport();
   AddHistoricalReportLine(text);
   AddHistoricalReportLine("The indicator is not live-scanning in this mode and does not write validation files.");
   UpdateHistoricalReportDashboard();
}

void ClearHistoricalReport()
{
   ArrayResize(g_historical_report_lines, 0);
}

void AddHistoricalReportLine(const string line)
{
   int next = ArraySize(g_historical_report_lines);
   if(next >= DASHBOARD_MAX_OBJECTS)
      return;
   ArrayResize(g_historical_report_lines, next + 1);
   g_historical_report_lines[next] = line;
}

void PrintHistoricalReportToJournal()
{
   int rows = ArraySize(g_historical_report_lines);
   for(int row = 0; row < rows; row++)
      PrintFormat("FXNews: %s", g_historical_report_lines[row]);
}

void SetHistoricalReadyMessage(const string mode)
{
   ClearHistoricalReport();
   AddHistoricalReportLine("FXNews - " + mode + " ready. Results written to MT5 Journal.");
   UpdateHistoricalReportDashboard();
}

void UpdateHistoricalReportDashboard()
{
   int rows = ArraySize(g_historical_report_lines);
   for(int row = 0; row < rows && row < DASHBOARD_MAX_OBJECTS; row++)
   {
      string text = g_historical_report_lines[row];
      SetDashboardRow(row, text, text, (row == 0 ? StatusLineColor() : clrWhite));
   }
   DeleteDashboardRowsFrom(rows);
   ChartRedraw(0);
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
   profile.session_spread_z = 0.0;
   profile.session_tick_rate_z = 0.0;
   profile.session_tick_volume_z = 0.0;
   profile.session_atr_z = 0.0;
   profile.session_speed_z = 0.0;
   profile.session_range_z = 0.0;
   profile.session_baseline_ready = false;
   profile.session_index = SESSION_OTHER;
   profile.session_name = "OTHER";
   profile.tick_sample_quality_score = 0.0;
   profile.valid_ticks_used = 0;
   profile.tick_state = "TICK_SYNCING";

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
   profile.previous_event_state = STATE_IDLE;
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
   profile.last_inside_range_time = 0;
   profile.last_confirmed_time = 0;
   profile.dominant_currency_flow = "";
   profile.correlated_alert_group_id = "";
   profile.group_leader_signal = false;
   profile.group_member_count = 0;
   profile.blocked_debug_visible = false;

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
   ArrayResize(g_session_baselines, symbol_count * SESSION_COUNT);

   for(int i = 0; i < ArraySize(g_snapshots); i++)
   {
      g_snapshots[i].time_msc = 0;
      g_snapshots[i].mid = 0.0;
   }

   ArrayInitialize(g_spread_history, 0.0);
   ResetSessionBaselines();
}

void ScanAll(const bool force_dashboard)
{
   uint scan_start = GetTickCount();
   datetime now = TimeCurrent();
   g_last_valid_symbols = 0;
   g_last_invalid_symbols = 0;
   g_last_active_profiles = 0;
   g_last_tick_history_ok = 0;

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(IsStopped())
         return;
      if(UpdateMarketData(i, now))
      {
         g_last_valid_symbols++;
         if(g_profiles[i].valid_ticks_used >= MinCopyTicksForGoodQuality)
            g_last_tick_history_ok++;
      }
      else
         g_last_invalid_symbols++;
   }

   CalculateCurrencyStrength();

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(IsStopped())
         return;
      CalculateScoresAndUpdateState(i, now);
   }

   UpdateAlertGroups(now);
   UpdateScanDiagnostics(scan_start);

   if(force_dashboard || g_last_dashboard_update == 0 ||
      now - g_last_dashboard_update >= DisplayUpdateSeconds)
   {
      UpdateDashboard();
      g_last_dashboard_update = now;
   }
   else
      UpdateActivityStatusLine();

   if(PrintDiagnosticsEveryMinute && (g_last_diagnostics_print == 0 || now - g_last_diagnostics_print >= 60))
   {
      PrintDiagnosticsSummary();
      g_last_diagnostics_print = now;
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
   g_profiles[index].session_index = SessionIndex(now);
   g_profiles[index].session_name = SessionNameFromIndex(g_profiles[index].session_index);
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
   UpdateTickQuality(index);

   UpdateRatesData(index);
   UpdateMovementData(index);
   UpdateOutsideTimers(index, now);
   UpdateSessionBaseline(index);

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
   g_profiles[index].tick_sample_quality_score = 0.0;
   g_profiles[index].valid_ticks_used = 0;
   g_profiles[index].tick_state = "TICK_STALE";
}

void UpdateRatesData(const int index)
{
   string symbol = g_profiles[index].symbol;
   int need_trigger = IntMax(g_range_lookback_m1 + ATRPeriod + 20, 80);
   int min_trigger = IntMax(g_range_lookback_m1 + 2, ATRPeriod + 3);

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
   int usable = IntMin(g_range_lookback_m1, copied - 1);
   if(usable < g_range_lookback_m1)
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

void ResetSessionBaselines()
{
   for(int i = 0; i < ArraySize(g_session_baselines); i++)
   {
      g_session_baselines[i].sample_count = 0;
      g_session_baselines[i].spread_mean = 0.0;
      g_session_baselines[i].spread_var = 0.0;
      g_session_baselines[i].tick_rate_mean = 0.0;
      g_session_baselines[i].tick_rate_var = 0.0;
      g_session_baselines[i].tick_volume_mean = 0.0;
      g_session_baselines[i].tick_volume_var = 0.0;
      g_session_baselines[i].atr_mean = 0.0;
      g_session_baselines[i].atr_var = 0.0;
      g_session_baselines[i].speed_mean = 0.0;
      g_session_baselines[i].speed_var = 0.0;
      g_session_baselines[i].range_width_mean = 0.0;
      g_session_baselines[i].range_width_var = 0.0;
      g_session_baselines[i].breakout_count = 0;
   }
}

void UpdateSessionBaseline(const int index)
{
   if(!UseSessionAwareBaselines || index < 0 || index >= ArraySize(g_profiles))
      return;

   int session_index = g_profiles[index].session_index;
   if(session_index < 0 || session_index >= SESSION_COUNT)
      session_index = SESSION_OTHER;

   int baseline_index = BaselineIndex(index, session_index);
   if(baseline_index < 0 || baseline_index >= ArraySize(g_session_baselines))
      return;

   SessionBaseline baseline = g_session_baselines[baseline_index];
   double tick_volume = MathMax(g_profiles[index].current_m1_tick_volume,
                                g_profiles[index].last_completed_m1_tick_volume);
   double atr_pips = (g_profiles[index].pip_size > 0.0 ?
                      g_profiles[index].atr_m1 / g_profiles[index].pip_size :
                      0.0);
   double speed_abs = MathMax(MathAbs(g_profiles[index].speed_10s_pips),
                              MathAbs(g_profiles[index].speed_30s_pips));
   double range_pips = (g_profiles[index].pip_size > 0.0 ?
                        g_profiles[index].range_width / g_profiles[index].pip_size :
                        0.0);

   UpdateRollingMeanVar(baseline.spread_mean, baseline.spread_var, baseline.sample_count, g_profiles[index].spread_pips);
   UpdateRollingMeanVar(baseline.tick_rate_mean, baseline.tick_rate_var, baseline.sample_count, g_profiles[index].tick_rate_per_sec);
   UpdateRollingMeanVar(baseline.tick_volume_mean, baseline.tick_volume_var, baseline.sample_count, tick_volume);
   UpdateRollingMeanVar(baseline.atr_mean, baseline.atr_var, baseline.sample_count, atr_pips);
   UpdateRollingMeanVar(baseline.speed_mean, baseline.speed_var, baseline.sample_count, speed_abs);
   UpdateRollingMeanVar(baseline.range_width_mean, baseline.range_width_var, baseline.sample_count, range_pips);
   if(BreakoutDistance(index, DIR_UP) > 0.0 || BreakoutDistance(index, DIR_DOWN) > 0.0)
      baseline.breakout_count++;
   if(baseline.sample_count < BaselineLookbackSamples)
      baseline.sample_count++;

   g_session_baselines[baseline_index] = baseline;
   g_profiles[index].session_baseline_ready = (baseline.sample_count >= MinBaselineSamples);
   if(!g_profiles[index].session_baseline_ready)
      return;

   g_profiles[index].session_spread_z = BaselineZ(g_profiles[index].spread_pips,
                                                  baseline.spread_mean,
                                                  baseline.spread_var);
   g_profiles[index].session_tick_rate_z = BaselineZ(g_profiles[index].tick_rate_per_sec,
                                                     baseline.tick_rate_mean,
                                                     baseline.tick_rate_var);
   g_profiles[index].session_tick_volume_z = BaselineZ(tick_volume,
                                                       baseline.tick_volume_mean,
                                                       baseline.tick_volume_var);
   g_profiles[index].session_atr_z = BaselineZ(atr_pips,
                                               baseline.atr_mean,
                                               baseline.atr_var);
   g_profiles[index].session_speed_z = BaselineZ(speed_abs,
                                                 baseline.speed_mean,
                                                 baseline.speed_var);
   g_profiles[index].session_range_z = BaselineZ(range_pips,
                                                 baseline.range_width_mean,
                                                 baseline.range_width_var);
}

void UpdateRollingMeanVar(double &mean,
                          double &variance,
                          const int sample_count,
                          const double value)
{
   if(sample_count <= 0)
   {
      mean = value;
      variance = 0.0;
      return;
   }

   double alpha = 2.0 / (double)(IntMin(BaselineLookbackSamples, sample_count) + 1);
   double delta = value - mean;
   mean += alpha * delta;
   variance = (1.0 - alpha) * (variance + alpha * delta * delta);
}

double BaselineZ(const double value, const double mean, const double variance)
{
   double sd = MathSqrt(MathMax(variance, 0.0));
   if(sd <= 0.0000001)
      return 0.0;
   return (value - mean) / sd;
}

int BaselineIndex(const int profile_index, const int session_index)
{
   return profile_index * SESSION_COUNT + session_index;
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
   score.displayed_score = 0.0;
   score.score_status = SCORE_RAW;
   score.score_bucket = 0;
   score.block_reason = BLOCK_NONE;
   score.reason_summary = "";
   score.human_reason = "";
   score.compact_tags = "";

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
   score.impulse.tick_sample_quality_score = 0.0;
   score.impulse.valid_ticks_used = 0;
   score.impulse.tick_state = "TICK_SYNCING";

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
   score.calendar.state_tag = "NEWS_UNAVAILABLE";
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
   ApplyRawScoreStatusToComposite(score);

   double capped = Clamp(score.raw_score, 0.0, 100.0);
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
      score.execution.cost_to_atr > g_max_spread_to_atr * 0.70 ||
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
   score.compact_tags = BuildCompactTags(score);
   score.human_reason = BuildHumanReadableReason(score, g_profiles[index]);

   if(DebugScoreBreakdown && DebugPrintToJournal && score.displayed_score >= g_min_display_confidence)
   {
      PrintFormat("FXNews score %s %s %s %d%% raw=%.1f %s",
                  g_profiles[index].symbol,
                  g_profiles[index].timeframe_label,
                  (direction == DIR_UP ? "UP" : "DOWN"),
                  (int)MathRound(score.displayed_score),
                  score.raw_score,
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
   execution.spread_z = (UseSessionAwareBaselines && g_profiles[index].session_baseline_ready ?
                         g_profiles[index].session_spread_z :
                         g_profiles[index].spread_z);
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
      if(execution.cost_to_atr > g_max_spread_to_atr ||
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
   double cost_score = 1.0 - SmoothStep(g_max_spread_to_atr * 0.45, g_max_spread_to_atr, execution.cost_to_atr);
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
   double extension_penalty = SmoothStep(g_max_overextension_atr, g_max_overextension_atr * 1.80, distance_atr);
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
                                           g_min_impulse_z_for_signal,
                                           g_min_impulse_z_for_signal + 2.75));
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
   impulse.tick_sample_quality_score = g_profiles[index].tick_sample_quality_score;
   impulse.valid_ticks_used = g_profiles[index].valid_ticks_used;
   impulse.tick_state = g_profiles[index].tick_state;
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
   if(UseCopyTicksForImpulse)
      impulse.score = Clamp01(impulse.score * (0.75 + impulse.tick_sample_quality_score * 0.25));
   impulse.pass = (Max3(impulse.speed_5s_z, impulse.speed_10s_z, impulse.speed_30s_z) >= g_min_impulse_z_for_signal ||
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
   calendar.state_tag = "NEWS_UNAVAILABLE";

   if(!UseEconomicCalendarContext)
   {
      calendar.state_tag = "NEWS_NONE";
      return;
   }

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
   {
      calendar.state_tag = "NEWS_UNAVAILABLE";
      return;
   }

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
   if(CalendarPreNewsBlock(calendar))
      calendar.state_tag = "NEWS_PRE_BLOCK";
   else if(calendar.just_released)
      calendar.state_tag = "NEWS_JUST_RELEASED";
   else if(calendar.high_impact_nearby)
      calendar.state_tag = "NEWS_HIGH_IMPACT_NEAR";
   else
      calendar.state_tag = "NEWS_NONE";
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

string BuildCompactTags(const CompositeSignalScore &score)
{
   string tags = "";
   AddTag(tags, score.breakout.score >= 0.60, "BRK+");
   AddTag(tags, score.impulse.score >= 0.60, "IMP+");
   AddTag(tags, score.flow.score >= 0.62, "FLOW+");
   AddTag(tags, score.execution.score >= 0.75, "EXEC+");
   AddTag(tags, score.regime.score >= 0.62, "REG+");
   AddTag(tags, score.regime.mtf_alignment_score < 0.35, "MTF-");
   AddTag(tags, score.calendar.high_impact_nearby || score.calendar.just_released, "NEWS!");
   AddTag(tags, score.execution.block_reason == BLOCK_BAD_SPREAD || score.execution.cost_to_atr > g_max_spread_to_atr * 0.70, "SPREAD!");
   AddTag(tags, score.execution.block_reason == BLOCK_STALE_QUOTE || score.impulse.tick_state == "TICK_STALE", "STALE!");
   AddTag(tags, score.score_status == SCORE_RAW, "RAW");
   AddTag(tags, score.impulse.tick_state == "TICK_OK", "TICK_OK");
   AddTag(tags, score.impulse.tick_state == "TICK_THIN", "TICK_THIN");
   if(tags == "")
      tags = "WATCH";
   return tags;
}

void AddTag(string &tags, const bool condition, const string tag)
{
   if(!condition)
      return;
   if(tags != "")
      tags += " ";
   tags += tag;
}

string BuildHumanReadableReason(const CompositeSignalScore &score, const SymbolProfile &profile)
{
   if(score.block_reason != BLOCK_NONE)
      return "Blocked: " + BlockReasonText(score.block_reason) + " | " + score.reason_summary;

   string lead = "Alert quality: ";
   if(score.breakout.score >= score.impulse.score && score.breakout.score >= 0.55)
      lead = "Clean directional breakout: ";
   else if(score.impulse.score >= 0.55)
      lead = "News-like impulse: ";

   string details = "";
   if(score.impulse.speed_10s_z > 1.0 || score.impulse.speed_30s_z > 1.0)
      details += "strong 10s/30s impulse, ";
   if(score.flow.score >= 0.62)
      details += "currency basket confirms, ";
   else if(score.flow.conflict_penalty >= 0.35)
      details += "currency basket conflicts, ";
   if(score.execution.score >= 0.75)
      details += "execution normal, ";
   else
      details += "execution mediocre, ";
   if(score.calendar.state_tag == "NEWS_NONE")
      details += "no high-impact news nearby, ";
   else
      details += score.calendar.state_tag + ", ";
   details += "raw chart-only score, ";

   if(StringLen(details) > 2)
      details = StringSubstr(details, 0, StringLen(details) - 2);
   return lead + details;
}

string ScoreStatusText(const ScoreStatus status)
{
   if(status == SCORE_RAW)
      return "RAW";
   return "RAW";
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
   int session_index = SessionIndex(now);
   if(session_index == SESSION_LONDON_NY_OVERLAP)
      return 1.00;
   if(session_index == SESSION_LONDON)
      return 0.92;
   if(session_index == SESSION_NEW_YORK)
      return 0.84;
   if(session_index == SESSION_ASIA)
      return 0.72;
   if(session_index == SESSION_ROLLOVER)
      return 0.15;
   return 0.45;
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
   g_calendar_available = true;
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

void ApplyRawScoreStatusToComposite(CompositeSignalScore &score)
{
   score.score_bucket = ScoreBucketFloor(score.raw_score);
   score.displayed_score = score.raw_score;
   score.score_status = SCORE_RAW;
}

int ScoreBucketFloor(const double score)
{
   if(score >= 85.0)
      return 85;
   if(score >= 80.0)
      return 80;
   if(score >= 75.0)
      return 75;
   if(score >= 70.0)
      return 70;
   if(score >= 65.0)
      return 65;
   return 60;
}

string SessionName(const datetime now)
{
   return SessionNameFromIndex(SessionIndex(now));
}

int SessionIndex(const datetime now)
{
   MqlDateTime parts;
   TimeToStruct(now, parts);
   int hour = parts.hour;

   if(IgnoreRolloverTime && IsRolloverTime(now))
      return SESSION_ROLLOVER;
   if(HourInSession(hour, LondonNYOverlapStartHourServer, LondonNYOverlapEndHourServer))
      return SESSION_LONDON_NY_OVERLAP;
   if(HourInSession(hour, LondonStartHourServer, LondonEndHourServer))
      return SESSION_LONDON;
   if(HourInSession(hour, NewYorkStartHourServer, NewYorkEndHourServer))
      return SESSION_NEW_YORK;
   if(HourInSession(hour, AsiaStartHourServer, AsiaEndHourServer))
      return SESSION_ASIA;
   return SESSION_OTHER;
}

bool HourInSession(const int hour, const int raw_start, const int raw_end)
{
   int start = NormalizeHour(raw_start);
   int end = NormalizeHour(raw_end);
   int normalized = NormalizeHour(hour);
   if(start == end)
      return false;
   if(start < end)
      return (normalized >= start && normalized < end);
   return (normalized >= start || normalized < end);
}

string SessionNameFromIndex(const int session_index)
{
   if(session_index == SESSION_ASIA)
      return "ASIA";
   if(session_index == SESSION_LONDON)
      return "LONDON";
   if(session_index == SESSION_NEW_YORK)
      return "NEW_YORK";
   if(session_index == SESSION_LONDON_NY_OVERLAP)
      return "LONDON_NY_OVERLAP";
   if(session_index == SESSION_ROLLOVER)
      return "ROLLOVER";
   return "OTHER";
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

bool IsActiveState(const BreakoutEventState state)
{
   return (state == STATE_ACTIVE_SIGNAL ||
           state == STATE_ACTIVE_UNCONFIRMED ||
           state == STATE_ACTIVE_CONFIRMED);
}

bool IsConfirmedSignal(const int index,
                       const int direction,
                       const double score,
                       const datetime now)
{
   double hold = (direction == DIR_UP ?
                  g_profiles[index].composite_up.breakout.hold_score :
                  g_profiles[index].composite_down.breakout.hold_score);

   if(SignalConfirmationMode == CONFIRM_LIVE_TICK)
      return true;
   if(SignalConfirmationMode == CONFIRM_BAR_CLOSE)
      return (hold >= 0.70 && score >= g_min_display_confidence);

   return (hold >= 0.35 ||
           score >= g_strong_alert_confidence ||
           now - g_profiles[index].candidate_start_time >= MinHoldSecondsForHighScore);
}

bool SignalExpiredByContext(const int index, const int direction, const datetime now)
{
   if(g_profiles[index].spread_pips > MaxSpreadPips ||
      g_profiles[index].tick_gap_sec > MaxTickGapSeconds * 1.50)
   {
      return true;
   }

   double buffer = BreakoutBufferPrice(index);
   if(direction == DIR_UP && g_profiles[index].mid <= g_profiles[index].range_high - buffer * 0.25)
      return true;
   if(direction == DIR_DOWN && g_profiles[index].mid >= g_profiles[index].range_low + buffer * 0.25)
      return true;

   return false;
}

bool CanPromoteStrongAlert(const int index, const int direction)
{
   return true;
}

void UpdateAlertGroups(const datetime now)
{
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      g_profiles[i].dominant_currency_flow = "";
      g_profiles[i].correlated_alert_group_id = "";
      g_profiles[i].group_leader_signal = false;
      g_profiles[i].group_member_count = 0;
   }

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!IsActiveState(g_profiles[i].event_state) || g_profiles[i].active_direction == DIR_NONE)
         continue;
      g_profiles[i].dominant_currency_flow = DominantCurrencyFlow(i, g_profiles[i].active_direction);
      g_profiles[i].correlated_alert_group_id = g_profiles[i].dominant_currency_flow;
   }

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(g_profiles[i].correlated_alert_group_id == "")
         continue;

      string group_id = g_profiles[i].correlated_alert_group_id;
      int leader = -1;
      double leader_score = -999999.0;
      int members = 0;

      for(int j = 0; j < ArraySize(g_profiles); j++)
      {
         if(g_profiles[j].correlated_alert_group_id != group_id)
            continue;
         members++;
         CompositeSignalScore score = (g_profiles[j].active_direction == DIR_UP ?
                                       g_profiles[j].composite_up :
                                       g_profiles[j].composite_down);
         double candidate = DashboardSortScore(j,
                                               g_profiles[j].active_direction,
                                               score,
                                               EventAgeSeconds(j, g_profiles[j].active_direction, now));
         if(candidate > leader_score)
         {
            leader_score = candidate;
            leader = j;
         }
      }

      for(int j = 0; j < ArraySize(g_profiles); j++)
      {
         if(g_profiles[j].correlated_alert_group_id != group_id)
            continue;
         g_profiles[j].group_member_count = members;
         g_profiles[j].group_leader_signal = (j == leader);
      }
   }
}

string DominantCurrencyFlow(const int index, const int direction)
{
   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   if(base < 0 || quote < 0)
      return g_profiles[index].symbol;

   CompositeSignalScore score = (direction == DIR_UP ?
                                 g_profiles[index].composite_up :
                                 g_profiles[index].composite_down);
   double base_component = score.flow.base_strength * (double)direction;
   double quote_component = -score.flow.quote_strength * (double)direction;

   if(MathAbs(base_component) >= MathAbs(quote_component))
      return g_currency_codes[base] + (direction == DIR_UP ? "+" : "-");
   return g_currency_codes[quote] + (direction == DIR_UP ? "-" : "+");
}

void UpdateSignalState(const int index, const datetime now)
{
   int best_direction = DIR_NONE;
   double best_score = 0.0;
   PickBestDirection(index, now, best_direction, best_score);

   if(IsActiveState(g_profiles[index].event_state) &&
      g_profiles[index].active_direction != DIR_NONE)
   {
      int current_direction = g_profiles[index].active_direction;
      double current_score = DirectionScore(index, current_direction);
      int opposite_direction = -current_direction;
      double opposite_score = DirectionScore(index, opposite_direction);
      int current_age = EventAgeSeconds(index, current_direction, now);

      if(opposite_score >= g_strong_alert_confidence && opposite_score > current_score + 8.0)
      {
         StartCooldown(index, current_direction, now, ValidSignalCooldownSeconds);
         ActivateSignal(index, opposite_direction, opposite_score, now);
         return;
      }

      if(ExpireOldSignals && current_age > SignalTTLSeconds)
      {
         g_profiles[index].previous_event_state = STATE_EXPIRED;
         EndActiveSignal(index, current_direction, now);
         return;
      }

      if(current_score >= g_min_display_confidence && current_age <= 300 &&
         !SignalExpiredByContext(index, current_direction, now))
      {
         g_profiles[index].confidence_below_since = 0;
         ActivateSignal(index, current_direction, current_score, now);
         return;
      }

      if(g_profiles[index].confidence_below_since == 0)
         g_profiles[index].confidence_below_since = now;

      if(now - g_profiles[index].confidence_below_since >= DisplayUpdateSeconds ||
         current_age > 300 ||
         SignalExpiredByContext(index, current_direction, now))
      {
         EndActiveSignal(index, current_direction, now);
      }

      return;
   }

   if(best_direction != DIR_NONE && best_score >= g_min_display_confidence)
   {
      if(g_profiles[index].event_state == STATE_CANDIDATE &&
         g_profiles[index].candidate_direction == best_direction)
      {
         if(SignalConfirmationMode == CONFIRM_LIVE_TICK ||
            IsConfirmedSignal(index, best_direction, best_score, now) ||
            best_score >= g_strong_alert_confidence)
         {
            ActivateSignal(index, best_direction, best_score, now);
         }
         return;
      }

      g_profiles[index].event_state = STATE_CANDIDATE;
      g_profiles[index].candidate_direction = best_direction;
      g_profiles[index].candidate_start_time = now;

      if(SignalConfirmationMode == CONFIRM_LIVE_TICK && best_score >= g_strong_alert_confidence)
         ActivateSignal(index, best_direction, best_score, now);

      return;
   }

   if(g_profiles[index].event_state == STATE_CANDIDATE &&
      g_profiles[index].candidate_direction != DIR_NONE)
   {
      StartCooldown(index, g_profiles[index].candidate_direction, now, FailedSignalCooldownSeconds);
      g_profiles[index].candidate_direction = DIR_NONE;
      g_profiles[index].candidate_start_time = 0;
      g_profiles[index].previous_event_state = STATE_FAILED_FAST;
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
                      g_profiles[index].final_score_up >= g_strong_alert_confidence);
   bool down_allowed = (now >= g_profiles[index].cooldown_end_down ||
                        g_profiles[index].final_score_down >= g_strong_alert_confidence);

   if(up_allowed && g_profiles[index].final_score_up >= g_min_display_confidence)
   {
      best_direction = DIR_UP;
      best_score = g_profiles[index].final_score_up;
   }

   if(down_allowed && g_profiles[index].final_score_down >= g_min_display_confidence &&
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
   bool new_signal = (!IsActiveState(g_profiles[index].event_state) ||
                      g_profiles[index].active_direction != direction);
   BreakoutEventState active_state = (IsConfirmedSignal(index, direction, score, now) ?
                                      STATE_ACTIVE_CONFIRMED :
                                      STATE_ACTIVE_UNCONFIRMED);

   if(new_signal)
   {
      g_profiles[index].event_start_time = now;
      g_profiles[index].event_local_time = TimeLocal();
      g_profiles[index].strong_alert_sent = false;
      g_profiles[index].active_displayed = true;
      PushSignalHistory(index, direction, score, g_profiles[index].event_local_time);
      SendOptionalAlert(index, direction, score, now, false);
   }
   else if(score >= g_strong_alert_confidence && !g_profiles[index].strong_alert_sent)
   {
      UpdateSignalHistory(index, direction, score);
      if(CanPromoteStrongAlert(index, direction))
         SendOptionalAlert(index, direction, score, now, true);
   }
   else
   {
      UpdateSignalHistory(index, direction, score);
   }

   g_profiles[index].active_direction = direction;
   g_profiles[index].event_state = active_state;
   if(active_state == STATE_ACTIVE_CONFIRMED)
      g_profiles[index].last_confirmed_time = now;
   g_profiles[index].candidate_direction = DIR_NONE;
   g_profiles[index].candidate_start_time = 0;
   g_profiles[index].confidence_below_since = 0;

   if(score >= g_strong_alert_confidence && CanPromoteStrongAlert(index, direction))
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

void UpdateScanDiagnostics(const uint scan_start)
{
   uint elapsed = GetTickCount() - scan_start;
   g_scan_count++;
   if(g_scan_count <= 1)
      g_average_scan_ms = (double)elapsed;
   else
      g_average_scan_ms = g_average_scan_ms * 0.90 + (double)elapsed * 0.10;
   if((double)elapsed > g_max_scan_ms)
      g_max_scan_ms = (double)elapsed;

   g_last_active_profiles = 0;
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(IsActiveState(g_profiles[i].event_state))
         g_last_active_profiles++;
   }
}

string DiagnosticsText()
{
   return StringFormat("DIAG valid=%d invalid=%d profiles=%d active=%d tick_ok=%d calendar=%s disk_io=disabled scan_avg=%.1fms scan_max=%.1fms objects=%d",
                       g_last_valid_symbols,
                       g_last_invalid_symbols,
                       ArraySize(g_profiles),
                       g_last_active_profiles,
                       g_last_tick_history_ok,
                       (g_calendar_available ? "yes" : "no"),
                       g_average_scan_ms,
                       g_max_scan_ms,
                       DASHBOARD_MAX_OBJECTS);
}

void PrintDiagnosticsSummary()
{
   Print("FXNews ", DiagnosticsText());
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
   ObjectDelete(0, DashboardName(0));
   SetActivityStatusRow(STATUS_ROW_INDEX);
   ObjectDelete(0, DashboardName(2));

   RefreshVisibleSignalHistoryIfDue();

   int row = SIGNAL_FIRST_ROW_INDEX;
   int max_row = SIGNAL_FIRST_ROW_INDEX + SIGNAL_HISTORY_SIZE;
   for(int i = 0; i < g_visible_signal_history_count && row < max_row; i++)
   {
      if(!g_visible_signal_history[i].used || g_visible_signal_history[i].text == "")
         continue;
      SetDashboardRow(row, g_visible_signal_history[i].text, g_visible_signal_history[i].text, clrWhite);
      row++;
   }

   DeleteDashboardRowsFrom(row);

   ChartRedraw(0);
}

void UpdateActivityStatusLine()
{
   ObjectDelete(0, DashboardName(0));
   SetActivityStatusRow(STATUS_ROW_INDEX);
   ObjectDelete(0, DashboardName(2));
   ChartRedraw(0);
}

void SetActivityStatusRow(const int row)
{
   SetDashboardRow(row, ActivityStatusText(), DiagnosticsText(), StatusLineColor());
}

color StatusLineColor()
{
   long chart_line_color = 0;
   ResetLastError();
   if(ChartGetInteger(0, CHART_COLOR_CHART_LINE, 0, chart_line_color))
      return (color)chart_line_color;
   return clrLime;
}

string ActivityStatusText()
{
   return StringFormat("FXNews - BREAKOUT RADAR | %s scanning %d profiles | valid=%d invalid=%d active=%d | scan %.1fms | %s",
                       OperatingModeText(),
                       ArraySize(g_profiles),
                       g_last_valid_symbols,
                       g_last_invalid_symbols,
                       g_last_active_profiles,
                       g_average_scan_ms,
                       FormatLocalTimestamp(TimeLocal()));
}

void CollectDashboardSignals(DashboardSignal &signals[])
{
   ArrayResize(signals, 0);
   datetime now = TimeCurrent();
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!IsActiveState(g_profiles[i].event_state) || g_profiles[i].active_direction == DIR_NONE)
      {
         if(!ShowBlockedSignalsDebug)
            continue;
         AddBlockedDebugSignal(i, signals, now);
         continue;
      }

      if(ShowOnlyGroupLeaders && !g_profiles[i].group_leader_signal)
         continue;

      int direction = g_profiles[i].active_direction;
      CompositeSignalScore score = (direction == DIR_UP ?
                                    g_profiles[i].composite_up :
                                    g_profiles[i].composite_down);
      if(score.displayed_score < g_min_display_confidence)
         continue;

      DashboardSignal signal;
      signal.profile_index = i;
      signal.direction = direction;
      signal.score = score.displayed_score;
      signal.raw_score = score.raw_score;
      signal.score_status = score.score_status;
      signal.start_time = g_profiles[i].event_start_time;
      signal.age_seconds = EventAgeSeconds(i, direction, now);
      signal.group_id = g_profiles[i].correlated_alert_group_id;
      signal.group_leader = g_profiles[i].group_leader_signal;
      signal.sort_score = DashboardSortScore(i, direction, score, signal.age_seconds);
      signal.text = FormatDashboardSignalText(ArraySize(signals) + 1, i, direction, score, signal.age_seconds);
      signal.tooltip = score.human_reason + "\n" + DashboardTooltip(score);

      int next = ArraySize(signals);
      ArrayResize(signals, next + 1);
      signals[next] = signal;
   }
}

void AddBlockedDebugSignal(const int index, DashboardSignal &signals[], const datetime now)
{
   CompositeSignalScore score = (g_profiles[index].composite_up.raw_score >= g_profiles[index].composite_down.raw_score ?
                                 g_profiles[index].composite_up :
                                 g_profiles[index].composite_down);
   if(score.block_reason == BLOCK_NONE)
      return;

   DashboardSignal signal;
   signal.profile_index = index;
   signal.direction = score.direction;
   signal.score = 0.0;
   signal.raw_score = score.raw_score;
   signal.score_status = score.score_status;
   signal.start_time = now;
   signal.age_seconds = 0;
   signal.group_id = "BLOCKED";
   signal.group_leader = false;
   signal.sort_score = -1000.0;
   signal.text = StringFormat("-- %-10s %-4s %-4s BLOCKED %-7s %-10s %s",
                              g_profiles[index].symbol,
                              g_profiles[index].timeframe_label,
                              DirectionText(score.direction),
                              ScoreStatusText(score.score_status),
                              g_profiles[index].session_name,
                              BlockReasonText(score.block_reason));
   signal.tooltip = score.reason_summary;

   int next = ArraySize(signals);
   ArrayResize(signals, next + 1);
   signals[next] = signal;
}

void SortDashboardSignals(DashboardSignal &signals[])
{
   int total = ArraySize(signals);
   for(int i = 0; i < total - 1; i++)
   {
      for(int j = i + 1; j < total; j++)
      {
         if(signals[j].sort_score > signals[i].sort_score)
         {
            DashboardSignal tmp = signals[i];
            signals[i] = signals[j];
            signals[j] = tmp;
         }
      }
   }

   for(int i = 0; i < total; i++)
   {
      int index = signals[i].profile_index;
      int direction = signals[i].direction;
      CompositeSignalScore score = (direction == DIR_UP ?
                                    g_profiles[index].composite_up :
                                    g_profiles[index].composite_down);
      signals[i].text = FormatDashboardSignalText(i + 1, index, direction, score, signals[i].age_seconds);
   }
}

double DashboardSortScore(const int index,
                          const int direction,
                          const CompositeSignalScore &score,
                          const int age_seconds)
{
   double leader_bonus = (g_profiles[index].group_leader_signal ? 8.0 : -5.0);
   double freshness = 10.0 * (1.0 - SmoothStep(0.0, (double)SignalTTLSeconds, (double)age_seconds));
   return score.displayed_score + leader_bonus +
          score.execution.score * 8.0 + freshness -
          score.execution.cost_to_atr * 6.0;
}

string FormatDashboardSignalText(const int rank,
                                 const int index,
                                 const int direction,
                                 const CompositeSignalScore &score,
                                 const int age_seconds)
{
   string group_tag = (g_profiles[index].group_leader_signal ? "LEAD" : "MEM");
   if(g_profiles[index].correlated_alert_group_id != "")
      group_tag += ":" + g_profiles[index].correlated_alert_group_id;

   string session_text = (ShowSessionOnDashboard ? g_profiles[index].session_name : "-");
   return StringFormat("%02d %-10s %-4s %-4s %3d%% %-6s %-10s %3ds %.2f %-18s %-24s %s",
                       rank,
                       g_profiles[index].symbol,
                       g_profiles[index].timeframe_label,
                       DirectionText(direction),
                       (int)MathRound(score.displayed_score),
                       ScoreStatusText(score.score_status),
                       session_text,
                       age_seconds,
                       score.execution.cost_to_atr,
                       score.calendar.state_tag,
                       group_tag,
                       score.compact_tags);
}

string DashboardTooltip(const CompositeSignalScore &score)
{
   return StringFormat("BRK %.2f | IMP %.2f | FLOW %.2f | EXEC %.2f | REG %.2f | %s | disk_io=off",
                       score.breakout.score,
                       score.impulse.score,
                       score.flow.score,
                       score.execution.score,
                       score.regime.score,
                       score.calendar.state_tag);
}

void RefreshVisibleSignalHistoryIfDue()
{
   datetime now = TimeLocal();
   if(g_last_signal_message_refresh == 0 ||
      now - g_last_signal_message_refresh >= SIGNAL_MESSAGE_REFRESH_SECONDS ||
      (g_visible_signal_history_count == 0 && HasDisplayableSignalHistory()))
   {
      RefreshVisibleSignalHistory(now);
   }
}

bool HasDisplayableSignalHistory()
{
   for(int i = 0; i < g_signal_history_count; i++)
   {
      if(g_signal_history[i].used &&
         g_signal_history[i].text != "" &&
         IsSignalMessageDisplayable(g_signal_history[i].score))
      {
         return true;
      }
   }
   return false;
}

void RefreshVisibleSignalHistory(const datetime now)
{
   for(int i = 0; i < SIGNAL_HISTORY_SIZE; i++)
      ResetSignalHistoryEntry(g_visible_signal_history[i]);

   g_visible_signal_history_count = 0;
   for(int i = 0; i < g_signal_history_count && g_visible_signal_history_count < SIGNAL_HISTORY_SIZE; i++)
   {
      if(!g_signal_history[i].used ||
         g_signal_history[i].text == "" ||
         !IsSignalMessageDisplayable(g_signal_history[i].score))
      {
         continue;
      }

      CopySignalHistoryEntry(g_signal_history[i], g_visible_signal_history[g_visible_signal_history_count]);
      g_visible_signal_history_count++;
   }

   SortVisibleSignalHistoryByScore();
   g_last_signal_message_refresh = now;
}

bool IsSignalMessageDisplayable(const double score)
{
   return ((int)MathRound(Clamp(score, 0.0, 100.0)) >= (int)SIGNAL_MESSAGE_MIN_SCORE);
}

void SortVisibleSignalHistoryByScore()
{
   for(int i = 0; i < g_visible_signal_history_count - 1; i++)
   {
      for(int j = i + 1; j < g_visible_signal_history_count; j++)
      {
         if(SignalHistorySortsBefore(g_visible_signal_history[j], g_visible_signal_history[i]))
         {
            SignalHistoryEntry tmp;
            CopySignalHistoryEntry(g_visible_signal_history[i], tmp);
            CopySignalHistoryEntry(g_visible_signal_history[j], g_visible_signal_history[i]);
            CopySignalHistoryEntry(tmp, g_visible_signal_history[j]);
         }
      }
   }
}

bool SignalHistorySortsBefore(const SignalHistoryEntry &left,
                              const SignalHistoryEntry &right)
{
   int left_percent = SignalHistoryScorePercent(left.score);
   int right_percent = SignalHistoryScorePercent(right.score);
   if(left_percent != right_percent)
      return (left_percent > right_percent);
   if(left.score != right.score)
      return (left.score > right.score);
   return (left.local_time > right.local_time);
}

int SignalHistoryScorePercent(const double score)
{
   return (int)MathRound(Clamp(score, 0.0, 100.0));
}

void PushSignalHistory(const int index,
                       const int direction,
                       const double score,
                       const datetime local_time)
{
   if(!IsSignalMessageDisplayable(score))
      return;

   string symbol = g_profiles[index].symbol;
   string timeframe_label = g_profiles[index].timeframe_label;
   int existing = FindSignalHistoryEntry(symbol, timeframe_label, direction);
   if(existing >= 0)
   {
      MoveSignalHistoryEntryToTop(existing);
      SetSignalHistoryEntry(g_signal_history[0], symbol, timeframe_label, direction, score, local_time);
      return;
   }

   for(int i = SIGNAL_HISTORY_SIZE - 1; i > 0; i--)
      CopySignalHistoryEntry(g_signal_history[i - 1], g_signal_history[i]);

   SetSignalHistoryEntry(g_signal_history[0], symbol, timeframe_label, direction, score, local_time);

   if(g_signal_history_count < SIGNAL_HISTORY_SIZE)
      g_signal_history_count++;
}

void UpdateSignalHistory(const int index, const int direction, const double score)
{
   datetime local_time = g_profiles[index].event_local_time;
   if(local_time <= 0)
      return;

   string symbol = g_profiles[index].symbol;
   string timeframe_label = g_profiles[index].timeframe_label;
   int existing = FindSignalHistoryEntry(symbol, timeframe_label, direction);

   if(!IsSignalMessageDisplayable(score))
   {
      if(existing >= 0)
         RemoveSignalHistoryEntry(existing);
      return;
   }

   if(existing < 0)
   {
      PushSignalHistory(index, direction, score, local_time);
      return;
   }

   SetSignalHistoryEntry(g_signal_history[existing],
                         symbol,
                         timeframe_label,
                         direction,
                         score,
                         g_signal_history[existing].local_time);
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

void SetSignalHistoryEntry(SignalHistoryEntry &entry,
                           const string symbol,
                           const string timeframe_label,
                           const int direction,
                           const double score,
                           const datetime local_time)
{
   entry.used = true;
   entry.symbol = symbol;
   entry.timeframe_label = timeframe_label;
   entry.direction = direction;
   entry.local_time = local_time;
   entry.score = score;
   entry.text = FormatSignalHistoryText(symbol, timeframe_label, direction, score, local_time);
}

void ResetSignalHistoryEntry(SignalHistoryEntry &entry)
{
   entry.used = false;
   entry.symbol = "";
   entry.timeframe_label = "";
   entry.direction = DIR_NONE;
   entry.local_time = 0;
   entry.score = 0.0;
   entry.text = "";
}

int FindSignalHistoryEntry(const string symbol,
                           const string timeframe_label,
                           const int direction)
{
   for(int i = 0; i < g_signal_history_count; i++)
   {
      if(g_signal_history[i].used &&
         g_signal_history[i].symbol == symbol &&
         g_signal_history[i].timeframe_label == timeframe_label &&
         g_signal_history[i].direction == direction)
      {
         return i;
      }
   }
   return -1;
}

void MoveSignalHistoryEntryToTop(const int entry_index)
{
   if(entry_index <= 0 || entry_index >= g_signal_history_count)
      return;

   SignalHistoryEntry moved;
   CopySignalHistoryEntry(g_signal_history[entry_index], moved);
   for(int i = entry_index; i > 0; i--)
      CopySignalHistoryEntry(g_signal_history[i - 1], g_signal_history[i]);
   CopySignalHistoryEntry(moved, g_signal_history[0]);
}

void RemoveSignalHistoryEntry(const int entry_index)
{
   if(entry_index < 0 || entry_index >= g_signal_history_count)
      return;

   for(int i = entry_index; i < g_signal_history_count - 1; i++)
      CopySignalHistoryEntry(g_signal_history[i + 1], g_signal_history[i]);

   g_signal_history_count--;
   if(g_signal_history_count < 0)
      g_signal_history_count = 0;
   ResetSignalHistoryEntry(g_signal_history[g_signal_history_count]);
}

void EnsureDashboardObjects()
{
   for(int i = 0; i < DASHBOARD_MAX_OBJECTS; i++)
      EnsureDashboardObject(i);
}

void EnsureDashboardObject(const int row)
{
   if(row < 0 || row >= DASHBOARD_MAX_OBJECTS)
      return;

   string name = DashboardName(row);
   if(ObjectFind(0, name) < 0)
   {
      ResetLastError();
      if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
      {
         PrintFormat("FXNews: failed to create dashboard object %s, error %d",
                     name, GetLastError());
         return;
      }
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 12);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 24 + row * DASHBOARD_ROW_HEIGHT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, DASHBOARD_FONT_SIZE);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
}

void SetDashboardRow(const int row,
                     const string text,
                     const string tooltip,
                     const color text_color)
{
   EnsureDashboardObject(row);
   string name = DashboardName(row);
   if(ObjectFind(0, name) < 0)
      return;

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
}

void DeleteDashboardRowsFrom(const int first_row)
{
   int start = first_row;
   if(start < 0)
      start = 0;
   for(int row = start; row < DASHBOARD_MAX_OBJECTS; row++)
      ObjectDelete(0, DashboardName(row));
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
   string direction_text = DirectionText(direction);
   CompositeSignalScore composite = (direction == DIR_UP ?
                                     g_profiles[index].composite_up :
                                     g_profiles[index].composite_down);
   int confidence = (int)MathRound(Clamp(score, 0.0, 100.0));
   return StringFormat("%s %s %s %d%% %s",
                       g_profiles[index].symbol,
                       g_profiles[index].timeframe_label,
                       direction_text,
                       confidence,
                       ScoreStatusText(composite.score_status));
}

string FormatSignalHistoryText(const string symbol,
                               const string timeframe_label,
                               const int direction,
                               const double score,
                               const datetime local_time)
{
   int confidence = (int)MathRound(Clamp(score, 0.0, 100.0));
   return StringFormat("%s - %s %s %s - %d%%",
                       FormatLocalTimestamp(local_time),
                       symbol,
                       timeframe_label,
                       DirectionText(direction),
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
   if(IsActiveState(g_profiles[index].event_state) &&
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
   double atr_part = g_profiles[index].atr_m1 * g_breakout_buffer_atr;
   double min_part = g_min_breakout_buffer_pips * g_profiles[index].pip_size;
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

void UpdateTickQuality(const int index)
{
   g_profiles[index].tick_sample_quality_score = 0.50;
   g_profiles[index].valid_ticks_used = 0;
   g_profiles[index].tick_state = "TICK_SYNCING";

   if(!UseCopyTicksForImpulse)
   {
      g_profiles[index].tick_sample_quality_score = 0.65;
      g_profiles[index].valid_ticks_used = g_profiles[index].snapshot_count;
      g_profiles[index].tick_state = (g_profiles[index].quote_fresh ? "TICK_OK" : "TICK_STALE");
      return;
   }

   if(g_profiles[index].quote_time_msc <= 0)
   {
      g_profiles[index].tick_sample_quality_score = 0.0;
      g_profiles[index].tick_state = "TICK_STALE";
      return;
   }

   if(ReuseTickQualityFromSibling(index))
      return;

   MqlTick ticks[];
   ulong from_msc = (ulong)MathMax(0, g_profiles[index].quote_time_msc - (long)CopyTicksLookbackSeconds * 1000);
   ResetLastError();
   int copied = CopyTicks(g_profiles[index].symbol, ticks, COPY_TICKS_INFO, from_msc, 0);
   if(copied <= 0)
   {
      g_profiles[index].tick_sample_quality_score = 0.25;
      g_profiles[index].tick_state = "TICK_SYNCING";
      return;
   }

   int valid = 0;
   long newest = 0;
   long oldest = 0;
   for(int i = 0; i < copied; i++)
   {
      if(ticks[i].bid <= 0.0 || ticks[i].ask <= 0.0 || ticks[i].ask < ticks[i].bid)
         continue;
      if((ticks[i].flags & (TICK_FLAG_BID | TICK_FLAG_ASK | TICK_FLAG_LAST)) == 0)
         continue;
      long tick_time = (long)ticks[i].time_msc;
      if(tick_time <= 0)
         tick_time = (long)ticks[i].time * 1000;
      if(tick_time <= 0)
         continue;
      if(oldest <= 0)
         oldest = tick_time;
      newest = tick_time;
      valid++;
   }

   g_profiles[index].valid_ticks_used = valid;
   if(valid <= 0)
   {
      g_profiles[index].tick_sample_quality_score = 0.15;
      g_profiles[index].tick_state = "TICK_STALE";
      return;
   }

   double age_sec = MathMax(0.0, (double)(g_profiles[index].quote_time_msc - newest) / 1000.0);
   double coverage_sec = MathMax(1.0, (double)(newest - oldest) / 1000.0);
   double count_score = SmoothStep((double)MinCopyTicksForGoodQuality * 0.35,
                                  (double)MinCopyTicksForGoodQuality,
                                  (double)valid);
   double freshness_score = 1.0 - SmoothStep(MaxTickGapSeconds * 0.50,
                                             MaxTickGapSeconds,
                                             age_sec);
   double coverage_score = SmoothStep((double)CopyTicksLookbackSeconds * 0.25,
                                      (double)CopyTicksLookbackSeconds * 0.75,
                                      coverage_sec);
   g_profiles[index].tick_sample_quality_score = Clamp01(count_score * 0.45 +
                                                         freshness_score * 0.35 +
                                                         coverage_score * 0.20);

   if(age_sec > MaxTickGapSeconds)
      g_profiles[index].tick_state = "TICK_STALE";
   else if(valid < MinCopyTicksForGoodQuality)
      g_profiles[index].tick_state = "TICK_THIN";
   else
      g_profiles[index].tick_state = "TICK_OK";
}

bool ReuseTickQualityFromSibling(const int index)
{
   string target = UpperAscii(g_profiles[index].symbol);
   for(int i = index - 1; i >= 0; i--)
   {
      if(UpperAscii(g_profiles[i].symbol) != target)
         continue;
      if(g_profiles[i].quote_time_msc <= 0 ||
         g_profiles[i].quote_time_msc != g_profiles[index].quote_time_msc)
      {
         continue;
      }
      if(g_profiles[i].tick_state == "")
         continue;

      g_profiles[index].tick_sample_quality_score = g_profiles[i].tick_sample_quality_score;
      g_profiles[index].valid_ticks_used = g_profiles[i].valid_ticks_used;
      g_profiles[index].tick_state = g_profiles[i].tick_state;
      return true;
   }

   return false;
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
   if(UseSessionAwareBaselines && g_profiles[index].session_baseline_ready)
      return g_profiles[index].session_tick_rate_z;

   double rate = g_profiles[index].tick_rate_per_sec;
   if(rate <= 0.0)
      return -1.0;

   // Snapshot-derived tick rate is deliberately conservative; FX tick feeds differ by broker.
   return (rate - 0.18) / 0.18;
}

double TickVolumeRobustZ(const int index)
{
   if(UseSessionAwareBaselines && g_profiles[index].session_baseline_ready)
      return g_profiles[index].session_tick_volume_z;

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
