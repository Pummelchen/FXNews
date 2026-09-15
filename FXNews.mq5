// FXNews version 3.0
#property strict
#property version   "3.000"
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
   FXNEWS_MODE_AUTOTUNE = 2,
   FXNEWS_MODE_SELFTEST = 3
};

input FXNewsOperatingMode OperatingMode = FXNEWS_MODE_LIVE;
input string SymbolsToScan =
"EURUSD,GBPUSD,USDJPY,USDCHF,AUDUSD,NZDUSD,USDCAD,EURJPY,GBPJPY,EURGBP,EURAUD,EURNZD,EURCAD,EURCHF,GBPAUD,GBPNZD,GBPCAD,GBPCHF,AUDJPY,NZDJPY,CADJPY,CHFJPY,AUDNZD,AUDCAD,AUDCHF,NZDCAD,NZDCHF,CADCHF";
input string TimeframesToScan = "M1,M5,M15,M30,H1,H4,H8,H12,D1";
input string InstanceId = ""; // Optional stable namespace when multiple instances share a chart.

input int ScanIntervalSeconds = 2;
input int DisplayUpdateSeconds = 5;
input double MinDisplayConfidence = 60.0;
input double StrongAlertConfidence = 70.0;

input int RangeLookbackM1 = 30;        // Bars of the SCAN timeframe, not minutes. Name kept for preset compatibility.
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

// 1.4 recentred the speed baseline on a signed distribution, which changed the
// scale this threshold is measured on. 1.25 on the old unsigned scale
// corresponds to about 1.40 on the current one, so the default was rescaled to
// preserve the previous selectivity. That is a scale correction, not a tuning
// claim: derive your own value from a VALIDATION run on your broker's history.
input double MinImpulseZForSignal = 1.40;
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
// EWMA horizon in SAMPLES, not a hard rolling window: old samples decay, they
// never drop out. One sample accrues per scan at most, so the horizon in time is
// BaselineLookbackSamples * ScanIntervalSeconds. The old 500 default was only
// ~17 minutes at a 2s scan, which is not a session baseline in any meaningful
// sense; 1800 is about an hour. The effective horizon is reported on the
// diagnostics line so the relationship is never hidden again.
input int BaselineLookbackSamples = 1800;
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

// Default display is the timestamped recent-signal list only. Set true to get
// the detailed live rows instead (rank, session, cost, calendar, group, tags).
input bool ShowActiveSignalRows = false;
input int MaxDashboardRows = 12;
// Minimum displayed score for the recent-signal list. Alerts and the detailed
// live rows use MinDisplayConfidence; the list is a stricter record of the
// best events and must not sit below it.
input double RecentListMinScore = 75.0;
input bool ShowOnlyGroupLeaders = false;
input bool ShowBlockedSignalsDebug = false;
input int SignalTTLSeconds = 180;
input bool ExpireOldSignals = true;
input ConfirmationMode SignalConfirmationMode = CONFIRM_HYBRID;

input bool UseCopyTicksForImpulse = true;
input int CopyTicksLookbackSeconds = 60;
input int MinCopyTicksForGoodQuality = 12;

// Snapshot-derived tick activity is broker dependent. These were fixed
// constants until 1.4; they are exposed so each broker can be calibrated.
input double TickRateBaselinePerSec = 0.18;   // Expected quiet-market snapshot rate.
input double TickVolumeRatioScale = 0.35;     // Tick-volume ratio spread used as one z unit.

input bool DebugScoreBreakdown = false;
input bool DebugPrintToJournal = false;
input bool ShowDiagnosticsPanel = false;
input bool PrintDiagnosticsEveryMinute = false;

input int HistoricalLookbackDays = 90;  // Calendar days including weekends, so ~64 trading days at the default.
input int HistoricalStepMinutes = 1;
input int HistoricalWarmupBars = 500;
// Boundaries (scan-timeframe bar closes) evaluated per profile at most; denser
// history is sub-sampled uniformly and the report prints the coverage.
input int HistoricalMaxBoundariesPerProfile = 2000;
input int AutotuneMinSignals = 100;


#define DIR_NONE 0
#define DIR_UP 1
#define DIR_DOWN -1
#define SNAPSHOT_CAPACITY 90
#define SPREAD_HISTORY_CAPACITY 80
#define CURRENCY_COUNT 8
#define DASHBOARD_MAX_OBJECTS 40
#define DASHBOARD_ROW_HEIGHT 24
#define DASHBOARD_TOP_OFFSET 24
#define DASHBOARD_FONT_SIZE 11
#define DASHBOARD_FONT_NAME "Consolas"
#define DASHBOARD_X_OFFSET 12
#define DASHBOARD_RIGHT_MARGIN 16
#define DASHBOARD_MIN_TEXT_CHARS 12
// The terminal keeps only the first 63 characters of a label's text (verified
// on build 6193 by writing 120 and reading 63 back), so every row is composed
// to fit that budget and longer report lines wrap onto extra labels.
#define DASHBOARD_MAX_TEXT_CHARS 63
#define DASHBOARD_FALLBACK_TEXT_CHARS 63
#define SIGNAL_HISTORY_SIZE 10
// A row stays on the chart for at least this long after it first appears, even
// if the signal's score decays back below SIGNAL_MESSAGE_MIN_SCORE. Measured
// from the entry's activation timestamp, which is what the row displays.
#define SIGNAL_MESSAGE_MIN_VISIBLE_SECONDS 30
#define SIGNAL_MESSAGE_REFRESH_SECONDS 10
// Row 0 is spacing, 1 the status line, 2-3 the optional diagnostics, and the
// signal rows start at 4 (or at 2 when the diagnostics panel is off).
#define STATUS_ROW_INDEX 1
#define DIAGNOSTICS_ROW_INDEX 2
#define DIAGNOSTICS_ROW_COUNT 2
#define SIGNAL_FIRST_ROW_INDEX (DIAGNOSTICS_ROW_INDEX + DIAGNOSTICS_ROW_COUNT)
#define CALENDAR_REFRESH_SECONDS 60
// Score of a currency whose calendar was read and holds nothing in the window.
#define CALENDAR_QUIET_SCORE 0.65
#define SESSION_COUNT SESSION_BUCKET_COUNT
#define MAX_SYMBOL_TOKEN_LENGTH 32
#define MAX_UNIQUE_SYMBOLS 32
#define MAX_SCAN_TIMEFRAMES 9
// Longest accepted timeframe list: the longest token ("PERIOD_M15") plus a
// separator and a space for every timeframe.
#define MAX_TIMEFRAME_LIST_LENGTH (MAX_SCAN_TIMEFRAMES * 12)
// Sized to the largest configuration the inputs can actually express, so a
// legal symbol/timeframe list can never be rejected at initialisation.
#define MAX_PROFILES (MAX_UNIQUE_SYMBOLS * MAX_SCAN_TIMEFRAMES)
#define MAX_COPY_TICKS 4096
#define MAX_RANGE_LOOKBACK 500
#define MAX_ATR_PERIOD 200
#define MAX_TICK_LOOKBACK_SECONDS 300
#define MAX_CALENDAR_WINDOW_MINUTES 1440
#define MAX_HISTORICAL_LOOKBACK_DAYS 365
#define MAX_HISTORICAL_WARMUP_BARS 10000
#define MAX_HISTORICAL_BOUNDARIES_PER_PROFILE 20000
// Historical model constants: an aggregated bar or an outcome window needs
// this share of its minutes present; spread and volume baselines look back
// this far; the minute-scale acceleration proxy ramps over this ATR/minute.
#define HISTORICAL_MIN_BAR_COVERAGE 0.50
#define HISTORICAL_SPREAD_BASELINE_MINUTES 120
#define HISTORICAL_VOLUME_BASELINE_BARS 40
#define HISTORICAL_ACCELERATION_FULL_ATR_PER_MINUTE 0.10
#define HISTORICAL_SCRATCH_RESERVE 200
// Where a boundary's spread came from. Many brokers store no spread on most
// M1 bars, so the window median of the bars that carry one, and failing that
// the symbol's current spread, stand in; each is a measurement and the report
// prints the mix.
#define HISTORICAL_SPREAD_NONE 0
#define HISTORICAL_SPREAD_BAR 1
#define HISTORICAL_SPREAD_MEDIAN 2
#define HISTORICAL_SPREAD_SYMBOL 3
#define MAX_OUTCOME_HORIZON_MINUTES 240
#define MAX_BASELINE_SAMPLES 5000
// An unmeasured basket now carries no score at all: the component is dropped
// from the blend and every consumer gates on CurrencyFlowQuality.available.
// There is deliberately no neutral placeholder to mistake for a measurement.
#define FLOW_CONFIRM_THRESHOLD 0.62
#define REGIME_CONFIRM_THRESHOLD 0.62
// An engine reading at or above this level is shown as confirmed (BRK+ / IMP+)
// and lets the row lead with that engine; the single-feature cap uses the same
// level so a tag and the cap can never disagree.
#define ENGINE_CONFIRM_THRESHOLD 0.60
// Candle-shape metrics are meaningless on a bar that has barely moved; below
// this fraction of the ATR they are treated as unmeasured, not as zero.
#define CANDLE_MEASURE_MIN_ATR 0.05
// Spread median and robust z need this many ring samples before they count.
#define MIN_SPREAD_SAMPLES 5
// Acceleration ramp: difference between the 5 s and 30 s rates, in ATR per second.
#define ACCELERATION_FULL_ATR_PER_SECOND 0.012
// The forming bar's tick count is projected to a full bar once this fraction of
// the bar has elapsed; before that the last completed bar stands in.
#define TICK_VOLUME_PROJECTION_MIN_FRACTION 0.20
// Speed z-scores are measured over these windows, each against its own baseline
// of same-length window rates; a 30 s average has far less dispersion than the
// 2 s interval rates the single baseline used to be built from.
#define SPEED_WINDOW_COUNT 3
// Scale from a median absolute deviation to a normal-equivalent sigma.
#define MAD_TO_SIGMA 1.4826
// Upper edges of the multi-timeframe and basket ramps. Declared here so the
// bounds enforced in ValidateInputs() stay tied to the values actually used.
#define M5_CONTEXT_FULL_ATR 0.35
#define M15_CONTEXT_FULL_ATR 0.30
#define BASKET_AGREEMENT_SCORE_FLOOR 0.45
// Baseline plus the eight fixed candidate profiles evaluated by Autotune.
#define AUTOTUNE_CANDIDATE_COUNT 9
// Freshness caps on a running event and the age at which a decayed signal ends.
#define AGING_EVENT_SECONDS 60
#define LATE_EVENT_SECONDS 180
#define SIGNAL_DECAY_GRACE_SECONDS 5
// A confirmed signal that collapses within this many seconds is treated like a
// failed candidate and takes the shorter cooldown.
#define SIGNAL_EARLY_COLLAPSE_SECONDS 30
#define MIN_ALERT_INTERVAL_SECONDS 30
// The terminal itself limits push notifications to about ten per minute and
// two per second; the dispatcher stays inside both.
#define MAX_ALERTS_PER_MINUTE 10
#define MAX_ALERTS_PER_SCAN 2
#define MAX_ALERT_ATTEMPTS 3
#define MAX_DEBUG_LINES_PER_MINUTE 30

enum BreakoutEventState
{
   STATE_IDLE = 0,
   STATE_WATCH = 1,
   STATE_CANDIDATE = 2,
   STATE_ACTIVE_CONFIRMED = 3,
   STATE_COOLDOWN = 4
};

enum SessionBucket
{
   SESSION_ASIA = 0,
   SESSION_LONDON = 1,
   SESSION_NEW_YORK = 2,
   SESSION_LONDON_NY_OVERLAP = 3,
   SESSION_ROLLOVER = 4,
   SESSION_OTHER = 5,
   SESSION_BUCKET_COUNT = 6      // keeps SESSION_COUNT tied to this enum
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
   BLOCK_CONTEXT_CONFLICT = 7,
   BLOCK_NO_SETUP = 8,              // data present, no breakout or impulse in this direction
   BLOCK_SPREAD_ONLY_BREAKOUT = 9,  // the excursion beyond the range is smaller than the spread
   BLOCK_EXPIRED = 10               // the event outlived its age limit
};

struct ExecutionQuality
{
   bool pass;
   double score;              // 0..1
   double spread_pips;
   bool median_available;     // false until the spread ring holds MIN_SPREAD_SAMPLES
   double median_spread_pips;
   double spread_ratio;
   bool spread_z_available;
   double spread_z;
   double quote_age_sec;
   double tick_gap_sec;
   double cost_to_atr;
   SignalBlockReason block_reason;
};

struct BreakoutStructure
{
   bool pass;
   bool measured;             // engine enabled and range/ATR data present
   bool candle_measured;      // trigger bar has moved enough for shape metrics
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
   bool measured;             // engine enabled and at least one speed window ready
   double score;              // 0..1
   double speed_5s_z;
   double speed_10s_z;
   double speed_30s_z;
   double acceleration_score;
   double atr_expansion_score;
   bool tick_rate_available;
   double tick_rate_z;
   bool tick_volume_available;
   double tick_volume_z;
   double exhaustion_penalty;
   bool tick_quality_available;
   double tick_sample_quality_score;
   string tick_state;
};

struct CurrencyFlowQuality
{
   bool available;            // false when the basket produced no usable reading
   double score;              // 0..1
   double base_strength;
   double quote_strength;
   double directional_edge;
   double basket_agreement;
   double conflict_penalty;
};

struct RegimeContext
{
   double score;              // 0..1
   double session_score;
   bool m5_available;
   bool m15_available;
   double mtf_alignment_score;
   double m5_context_score;
   double m15_context_score;
   double volatility_regime_score;
};

struct CalendarContext
{
   bool available;
   bool high_impact_nearby;
   bool just_released;
   bool future_high_impact_nearby;
   double score;              // 0..1
   double future_high_impact_minutes;
   double uncertainty_penalty;
   string state_tag;
};

struct CompositeSignalScore
{
   bool valid;
   double raw_score;          // 0..100 before final caps
   double displayed_score;    // rounded dashboard score source
   double age_free_score;     // displayed score before the event-age caps
   ExecutionQuality execution;
   BreakoutStructure breakout;
   ImpulseQuality impulse;
   CurrencyFlowQuality flow;
   RegimeContext regime;
   CalendarContext calendar;
   SignalBlockReason block_reason;
   string cap_reasons;        // '|'-separated caps applied by the composer
   string reason_summary;
   string human_reason;
   string compact_tags;
};

// Readings that do not depend on the direction, evaluated once per profile
// per scan and shared by the UP and DOWN composites.
struct SharedComponents
{
   ExecutionQuality execution;
   CalendarContext calendar;
   double session_score;
   bool agreement_available;
   double basket_agreement_up;    // DOWN is exactly 1 - this
   bool tick_rate_available;
   double tick_rate_z;
   bool tick_volume_available;
   double tick_volume_z;
};

// Direction-dependent context the composer needs beyond the component structs.
// The live scanner and the historical validator both fill one of these, so
// the blend and the cap ladder exist exactly once.
struct CompositeContext
{
   int direction;
   double m5_move_directional;    // last closed M5 bar move in ATR, signed by direction
   double m15_move_directional;
   int age_seconds;               // 0 when no event is live in this direction
   int age_limit_seconds;         // 0 = no age limit
   double max_spread_to_atr;      // the execution cap threshold in force
};

struct SessionBaseline
{
   // One counter per measured series. A shared counter let a bucket report a
   // z-score as measured for a series that had never contributed a sample: the
   // tick rate is only folded when it is actually known, so a spread-only bucket
   // still reached the readiness threshold and published a neutral 0 for it.
   int spread_samples;
   int tick_rate_samples;
   int tick_volume_samples;
   double spread_mean;
   double spread_var;
   double tick_rate_mean;
   double tick_rate_var;
   double tick_volume_mean;
   double tick_volume_var;
};

struct DashboardSignal
{
   int profile_index;
   int direction;
   int age_seconds;
   bool blocked;
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
   double minute_impulse_z;      // proxy threshold for the minute-scale speed windows
};

struct HistoricalSignalScore
{
   bool valid;
   int direction;
   double displayed_score;
   double atr_price;
   double spread_price;
};

struct HistoricalOutcome
{
   bool evaluable;               // false when a horizon window lacks too many minutes
   double result_5m_R;
   bool target_5m;
   bool stop_5m;
   double result_15m_R;
   bool target_15m;
   bool stop_15m;
   double result_30m_R;
   bool target_30m;
   bool stop_30m;
};

struct HistoricalBacktestStats
{
   datetime from_time;
   datetime to_time;
   int symbols_requested;
   int symbols_loaded;
   int bars_loaded;
   int profiles_tested;          // profiles with at least one evaluated boundary
   int boundaries_total;         // boundaries in the window before sub-sampling
   int boundary_stride_max;
   int boundaries_rejected;      // boundaries without enough bar data
   int bars_scanned;             // boundaries evaluated
   int spread_from_bar;          // spread source counts over evaluated boundaries
   int spread_from_median;
   int spread_from_symbol;
   int spread_unavailable;
   int signals;
   int signals_unevaluable;      // outcome window too gapped to judge
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
   bool future_high_impact_nearby;
   double score;
   double future_high_impact_minutes;
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
   string reason;             // tooltip: human reason and tags at the last update
};

struct SymbolProfile
{
   string symbol;
   ENUM_TIMEFRAMES scan_timeframe;
   string timeframe_label;
   bool valid;
   bool selected;
   bool unsupported;                 // not an FX pair of the eight basket currencies
   bool broker_match_attempted;      // FindBrokerSymbolMatch runs once per profile
   datetime next_symbol_retry_time;
   int base_index;
   int quote_index;

   double point;
   double pip_size;
   string symbol_upper;              // interned once; avoids UpperAscii in hot loops
   bool is_first_profile_for_symbol; // recomputed only when a symbol is resolved
   int symbol_leader_index;          // the first profile of this symbol
   double m1_atr_pips;               // true M1 ATR, basket strength only
   double basket_contribution;       // this symbol's weighted strength in the basket
   double basket_weight;             // and the weight it carried (leader profile only)

   bool quote_fresh;
   datetime quote_time;
   long quote_time_msc;
   double bid;
   double ask;
   double mid;
   double spread_pips;
   double median_spread_pips;
   double spread_z;
   double tick_gap_sec;              // max(last tick interval, current quote age)
   double last_tick_interval_sec;    // seconds between the two most recent distinct ticks
   double quote_age_sec;             // wall-clock age of the last quote
   bool spread_stats_ready;          // ring holds MIN_SPREAD_SAMPLES samples
   bool tick_rate_available;
   double tick_rate_per_sec;
   double session_spread_z;
   double session_tick_rate_z;
   double session_tick_volume_z;
   bool session_spread_z_ready;      // this session bucket measured spread often enough
   bool session_tick_rate_z_ready;   // ... and likewise the tick rate
   bool session_tick_volume_z_ready; // ... and likewise the tick volume
   SessionBucket session_index;
   bool tick_quality_available;      // measured from CopyTicks this scan
   double tick_sample_quality_score;
   int valid_ticks_used;
   string tick_state;
   long tick_quality_stamp_msc;      // quote time the tick quality was measured at
   int last_market_update_scan;      // g_scan_sequence of the last successful update

   // Trigger-timeframe (scan timeframe) data. m1_atr_pips below is the only
   // genuine M1 reading and exists for the cross-symbol basket.
   bool has_trigger;
   bool has_m5;
   bool has_m15;
   double atr_trigger;
   double atr_m5;
   double range_high;
   double range_low;
   double range_width;
   datetime range_anchor_bar_time;   // trigger bar the box was last built on
   double breakout_buffer_price;     // per-scan cache, direction independent

   double current_trigger_open;
   double current_trigger_high;
   double current_trigger_low;
   double current_trigger_close;
   datetime trigger_bar_time;
   double active_trigger_tick_volume;    // forming bar projected to a full bar
   double average_trigger_tick_volume;

   // Per-scan speed baselines, one per window, direction independent.
   bool speed_baseline_ready[SPEED_WINDOW_COUNT];
   double speed_median_rate[SPEED_WINDOW_COUNT];
   double speed_mad_rate[SPEED_WINDOW_COUNT];
   int snapshot_coverage_sec;            // span of the snapshot ring

   double speed_5s_pips;
   double speed_10s_pips;
   double speed_30s_pips;
   double speed_60s_pips;
   double movement_5m_pips;
   bool has_m5_move;
   bool has_m15_move;
   double m5_move_atr;
   double m15_move_atr;

   double final_score_up;
   double final_score_down;
   CompositeSignalScore composite_up;
   CompositeSignalScore composite_down;

   int active_direction;
   BreakoutEventState event_state;
   datetime event_start_time;
   datetime event_local_time;
   datetime cooldown_end_up;
   datetime cooldown_end_down;
   datetime last_alert_attempt_time;
   int alert_attempts;               // deliveries tried for the pending request
   bool strong_alert_handled;
   datetime confidence_below_since;
   int candidate_direction;
   datetime candidate_start_time;
   datetime candidate_bar_time;
   bool pending_alert;
   bool pending_strong_upgrade;
   datetime outside_since_up;
   datetime outside_since_down;
   datetime reentered_since_up;
   datetime reentered_since_down;
   string correlated_alert_group_id; // bound when the signal activates
   bool group_leader_signal;
   int group_member_count;

   int snapshot_write_index;
   int snapshot_count;
   int spread_write_index;
   int spread_count;

   string status_message;
   string reported_status_message;
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
double g_currency_sum[CURRENCY_COUNT];       // weighted strength sum per currency
int g_currency_samples[CURRENCY_COUNT];
double g_currency_weight[CURRENCY_COUNT];
const int g_speed_window_seconds[SPEED_WINDOW_COUNT] = {5, 10, 30};
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
datetime g_alert_send_times[MAX_ALERTS_PER_MINUTE];   // sliding one-minute window
int g_alert_send_cursor = 0;
bool g_signal_history_dirty = false;                  // a new list entry awaits rendering
datetime g_debug_window_started = 0;
int g_debug_lines_in_window = 0;

datetime g_last_dashboard_update = 0;
datetime g_last_signal_message_refresh = 0;
string g_object_prefix = "COBR_";
double g_rate_scratch[];    // reused by the per-scan statistics helpers
double g_spread_scratch[];
double g_mad_scratch[];
double g_hist_scratch[];    // historical baselines
MqlRates g_rates_trigger[];  // CopyRates targets reused across profiles and scans
MqlRates g_rates_m1[];
MqlRates g_rates_m5[];
MqlRates g_rates_m15[];
MqlTick g_ticks_scratch[];
int g_scan_sequence = 0;            // increments once per ScanAll
bool g_dashboard_needs_refit = false;
double g_dashboard_char_pixels = 0.0;   // measured once per font/DPI
bool g_symbol_identity_dirty = true;
bool g_selftest_done = false;
int g_selftest_passed = 0;
int g_selftest_failed = 0;
bool g_historical_run_started = false;
bool g_historical_run_finished = false;
string g_historical_report_lines[];

// Globals survive a re-initialisation that keeps the program instance
// (parameter change, timeframe change, template load), so every piece of run
// state is reset explicitly; otherwise a second SELFTEST or backtest never
// runs and the previous parameter set's signal rows stay on the chart.
void ResetRuntimeState()
{
   g_selftest_done = false;
   g_selftest_passed = 0;
   g_selftest_failed = 0;
   g_historical_run_started = false;
   g_historical_run_finished = false;
   ClearHistoricalReport();
   ClearSignalHistory();

   g_calendar_available = false;
   g_last_diagnostics_print = 0;
   g_average_scan_ms = 0.0;
   g_max_scan_ms = 0.0;
   g_scan_count = 0;
   g_last_valid_symbols = 0;
   g_last_invalid_symbols = 0;
   g_last_active_profiles = 0;
   g_last_tick_history_ok = 0;
   for(int i = 0; i < MAX_ALERTS_PER_MINUTE; i++)
      g_alert_send_times[i] = 0;
   g_alert_send_cursor = 0;
   g_signal_history_dirty = false;
   g_debug_window_started = 0;
   g_debug_lines_in_window = 0;
   g_last_dashboard_update = 0;
   g_last_signal_message_refresh = 0;
   g_symbol_identity_dirty = true;
   g_scan_sequence = 0;
   g_dashboard_needs_refit = false;
   g_dashboard_char_pixels = 0.0;

   for(int i = 0; i < CURRENCY_COUNT; i++)
   {
      g_currency_sum[i] = 0.0;
      g_currency_samples[i] = 0;
      g_currency_weight[i] = 0.0;
   }
}

void ClearSignalHistory()
{
   for(int i = 0; i < SIGNAL_HISTORY_SIZE; i++)
   {
      ResetSignalHistoryEntry(g_signal_history[i]);
      ResetSignalHistoryEntry(g_visible_signal_history[i]);
   }
   g_signal_history_count = 0;
   g_visible_signal_history_count = 0;
}

int OnInit()
{
   ResetRuntimeState();

   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   g_object_prefix = "COBR_" + IntegerToString((int)(ChartID() % 1000000)) + "_" +
                     ObjectNamespaceToken(InstanceId) + "_";
   int stale_labels = StaleDashboardLabels();
   if(stale_labels > 0)
   {
      PrintFormat("FXNews: %d chart label(s) from another FXNews instance found (prefix COBR_). "
                  "A second instance on this chart is fine; leftovers from a terminal crash can be "
                  "removed from the chart's object list.", stale_labels);
   }

   if(IsSelfTestMode())
   {
      // Pure-helper checks need no symbols, buffers or market data.
      ResetLastError();
      if(!EventSetTimer(1))
      {
         PrintFormat("FXNews: EventSetTimer failed, error %d", GetLastError());
         return INIT_FAILED;
      }
      return INIT_SUCCEEDED;
   }

   if(ParseSymbols() <= 0)
   {
      Print("FXNews: symbol or timeframe parsing failed, see the messages above.");
      return INIT_PARAMETERS_INCORRECT;
   }

   RefreshSymbolIdentityCache();
   InitializeCalendarCache();

   if(!AllocateHistoryBuffers())
   {
      Print("FXNews: unable to allocate bounded runtime buffers.");
      return INIT_FAILED;
   }

   for(int i = 0; i < ArraySize(g_profiles); i++)
      EnsureSymbolReady(i);

   if(!IsScanningMode())
      SetHistoricalReportHeader("FXNews - " + OperatingModeText() + " | waiting");

   ResetLastError();
   if(!EventSetTimer(IntMax(1, ScanIntervalSeconds)))
   {
      PrintFormat("FXNews: EventSetTimer failed, error %d", GetLastError());
      return INIT_FAILED;
   }

   if(IsScanningMode())
      ScanAll(true);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   CleanupDashboardObjects();
   ChartRedraw(0);
}

// Labels left on the chart by another FXNews instance, past or present.
int StaleDashboardLabels()
{
   int stale = 0;
   int total = ObjectsTotal(0, 0, OBJ_LABEL);
   for(int i = 0; i < total; i++)
   {
      string name = ObjectName(0, i, 0, OBJ_LABEL);
      if(StringFind(name, "COBR_") == 0 && StringFind(name, g_object_prefix) != 0)
         stale++;
   }
   return stale;
}

// A resized chart changes how many characters fit a row; the next scan
// re-fits every row instead of waiting for the display interval.
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      g_dashboard_needs_refit = true;
      g_dashboard_char_pixels = 0.0;
   }
}

void OnTimer()
{
   if(IsSelfTestMode())
   {
      RunSelfTest();
      return;
   }

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
   if(StringLen(SymbolsToScan) <= 0 || StringLen(SymbolsToScan) > MAX_UNIQUE_SYMBOLS * (MAX_SYMBOL_TOKEN_LENGTH + 1) ||
      StringLen(TimeframesToScan) <= 0 || StringLen(TimeframesToScan) > MAX_TIMEFRAME_LIST_LENGTH ||
      StringLen(InstanceId) > 32)
   {
      PrintFormat("FXNews: SymbolsToScan (at most %d characters), TimeframesToScan (at most %d) or "
                  "InstanceId (at most 32) is outside the supported length.",
                  MAX_UNIQUE_SYMBOLS * (MAX_SYMBOL_TOKEN_LENGTH + 1), MAX_TIMEFRAME_LIST_LENGTH);
      return false;
   }

   if(ScanIntervalSeconds < 1 || DisplayUpdateSeconds < 1 || MaxQuoteAgeSeconds < 1)
   {
      Print("FXNews: scan, display, and quote-age inputs must be positive.");
      return false;
   }

   if(!MathIsValidNumber(MinDisplayConfidence) || !MathIsValidNumber(StrongAlertConfidence) ||
      MinDisplayConfidence < 1.0 || MinDisplayConfidence > 99.0 ||
      StrongAlertConfidence < MinDisplayConfidence || StrongAlertConfidence > 100.0)
   {
      Print("FXNews: confidence inputs are inconsistent.");
      return false;
   }

   if(RangeLookbackM1 < 10 || RangeLookbackM1 > MAX_RANGE_LOOKBACK ||
      ATRPeriod < 2 || ATRPeriod > MAX_ATR_PERIOD ||
      !MathIsValidNumber(BreakoutBufferATR) || !MathIsValidNumber(MinBreakoutBufferPips) ||
      BreakoutBufferATR < 0.0 || MinBreakoutBufferPips < 0.0)
   {
      Print("FXNews: range and ATR inputs are outside supported bounds.");
      return false;
   }

   if(!MathIsValidNumber(MaxSpreadPips) || !MathIsValidNumber(MaxSpreadMedianMultiplier) ||
      MaxSpreadPips <= 0.0 || MaxSpreadMedianMultiplier <= 1.0)
   {
      Print("FXNews: spread filters are outside supported bounds.");
      return false;
   }

   if(FailedSignalCooldownSeconds < 1 || ValidSignalCooldownSeconds < 1)
   {
      Print("FXNews: cooldown inputs must be positive.");
      return false;
   }

   if(!MathIsValidNumber(MaxSpreadToAtrRatio) || !MathIsValidNumber(MaxTickGapSeconds) ||
      !MathIsValidNumber(MaxSpreadZScore) || MaxSpreadToAtrRatio <= 0.0 ||
      MaxTickGapSeconds <= 0.0 || MaxSpreadZScore <= 0.0)
   {
      Print("FXNews: execution gate inputs must be positive.");
      return false;
   }

   // A zero hold requirement would let the HYBRID confirmation clause pass on
   // the first scan and silently turn it into CONFIRM_LIVE_TICK.
   if(MinHoldSecondsForHighScore < 1 || FullHoldScoreSeconds < 1 ||
      FullHoldScoreSeconds < MinHoldSecondsForHighScore || !MathIsValidNumber(MaxOverextensionAtr) ||
      MaxOverextensionAtr <= 0.0)
   {
      Print("FXNews: breakout-quality inputs are outside supported bounds "
            "(MinHoldSecondsForHighScore must be at least 1 and at most FullHoldScoreSeconds).");
      return false;
   }

   if(!UseTechnicalBreakoutEngine && !UseImpulseBreakoutEngine)
   {
      Print("FXNews: enable at least one signal engine.");
      return false;
   }

   if(!MathIsValidNumber(MinImpulseZForSignal) || !MathIsValidNumber(MaxExhaustionAtr) ||
      !MathIsValidNumber(MinBasketAgreementForHighScore) || !MathIsValidNumber(MinDirectionalEdgeForHighScore) ||
      MinImpulseZForSignal < 0.0 || MaxExhaustionAtr <= 0.0 ||
      MinBasketAgreementForHighScore <= BASKET_AGREEMENT_SCORE_FLOOR ||
      MinBasketAgreementForHighScore > 1.0 ||
      MinDirectionalEdgeForHighScore <= 0.0)
   {
      PrintFormat("FXNews: impulse or basket-quality inputs are outside supported bounds. "
                  "MinBasketAgreementForHighScore must be above %.2f and at most 1.00; "
                  "MinDirectionalEdgeForHighScore must be above 0.",
                  BASKET_AGREEMENT_SCORE_FLOOR);
      return false;
   }

   // Both reject levels are the lower edge of a rising ramp. A value at or above
   // the upper edge would score moves against the signal as confirmation.
   if(!MathIsValidNumber(M5RejectAtr) || !MathIsValidNumber(M15RejectAtr) ||
      M5RejectAtr >= M5_CONTEXT_FULL_ATR || M15RejectAtr >= M15_CONTEXT_FULL_ATR ||
      M5RejectAtr < -5.0 || M15RejectAtr < -5.0)
   {
      PrintFormat("FXNews: multi-timeframe reject levels are outside supported bounds. "
                  "M5RejectAtr must be below %.2f and M15RejectAtr below %.2f.",
                  M5_CONTEXT_FULL_ATR, M15_CONTEXT_FULL_ATR);
      return false;
   }

   if(!MathIsValidNumber(TickRateBaselinePerSec) || !MathIsValidNumber(TickVolumeRatioScale) ||
      TickRateBaselinePerSec <= 0.0 || TickRateBaselinePerSec > 100.0 ||
      TickVolumeRatioScale <= 0.0 || TickVolumeRatioScale > 10.0)
   {
      Print("FXNews: tick-activity calibration inputs must be positive and within range.");
      return false;
   }

   if(CalendarLookbackMinutes < 0 || CalendarLookbackMinutes > MAX_CALENDAR_WINDOW_MINUTES ||
      CalendarLookaheadMinutes < 0 || CalendarLookaheadMinutes > MAX_CALENDAR_WINDOW_MINUTES ||
      CalendarPreNewsBlockMinutes < 0 || CalendarPreNewsBlockMinutes > CalendarLookaheadMinutes)
   {
      PrintFormat("FXNews: calendar minutes must be between 0 and %d, and CalendarPreNewsBlockMinutes "
                  "must not exceed CalendarLookaheadMinutes.", MAX_CALENDAR_WINDOW_MINUTES);
      return false;
   }

   // Equal hours would silently disable the rollover block while the input
   // says it is on; sessions with equal hours are documented as disabled.
   if(IgnoreRolloverTime && RolloverStartHourServer == RolloverEndHourServer)
   {
      Print("FXNews: RolloverStartHourServer and RolloverEndHourServer must differ while IgnoreRolloverTime is on.");
      return false;
   }

   if(RolloverStartHourServer < 0 || RolloverStartHourServer > 23 ||
      RolloverEndHourServer < 0 || RolloverEndHourServer > 23 ||
      AsiaStartHourServer < 0 || AsiaStartHourServer > 23 || AsiaEndHourServer < 0 || AsiaEndHourServer > 23 ||
      LondonStartHourServer < 0 || LondonStartHourServer > 23 || LondonEndHourServer < 0 || LondonEndHourServer > 23 ||
      NewYorkStartHourServer < 0 || NewYorkStartHourServer > 23 || NewYorkEndHourServer < 0 || NewYorkEndHourServer > 23 ||
      LondonNYOverlapStartHourServer < 0 || LondonNYOverlapStartHourServer > 23 ||
      LondonNYOverlapEndHourServer < 0 || LondonNYOverlapEndHourServer > 23)
   {
      Print("FXNews: session and rollover hours must be between 0 and 23.");
      return false;
   }

   if(OutcomeHorizonMinutes1 < 1 || OutcomeHorizonMinutes2 < OutcomeHorizonMinutes1 ||
      OutcomeHorizonMinutes3 < OutcomeHorizonMinutes2 || OutcomeHorizonMinutes3 > MAX_OUTCOME_HORIZON_MINUTES ||
      !MathIsValidNumber(OutcomeTargetAtr) || !MathIsValidNumber(OutcomeStopAtr) ||
      OutcomeTargetAtr <= 0.0 || OutcomeStopAtr <= 0.0)
   {
      Print("FXNews: outcome inputs are inconsistent.");
      return false;
   }

   if(BaselineLookbackSamples < 50 || BaselineLookbackSamples > MAX_BASELINE_SAMPLES || MinBaselineSamples < 10 ||
      MinBaselineSamples > BaselineLookbackSamples)
   {
      Print("FXNews: session baseline inputs are inconsistent.");
      return false;
   }

   if(!MathIsValidNumber(RecentListMinScore) || RecentListMinScore < MinDisplayConfidence ||
      RecentListMinScore > 100.0)
   {
      Print("FXNews: RecentListMinScore must be between MinDisplayConfidence and 100.");
      return false;
   }

   if(MaxDashboardRows < 1 || MaxDashboardRows > DASHBOARD_MAX_OBJECTS - SIGNAL_FIRST_ROW_INDEX ||
      SignalTTLSeconds < 30 || SignalTTLSeconds > 3600 ||
      DisplayUpdateSeconds > 3600 || ScanIntervalSeconds > 3600 ||
      CopyTicksLookbackSeconds < 5 || CopyTicksLookbackSeconds > MAX_TICK_LOOKBACK_SECONDS ||
      MinCopyTicksForGoodQuality < 1 || MinCopyTicksForGoodQuality > MAX_COPY_TICKS)
   {
      Print("FXNews: dashboard, lifecycle, or tick-quality inputs are inconsistent.");
      return false;
   }

   if(HistoricalLookbackDays < 1 || HistoricalLookbackDays > MAX_HISTORICAL_LOOKBACK_DAYS ||
      HistoricalStepMinutes < 1 || HistoricalStepMinutes > 60 || HistoricalWarmupBars < 100 ||
      HistoricalWarmupBars > MAX_HISTORICAL_WARMUP_BARS || HistoricalMaxBoundariesPerProfile < 10 ||
      HistoricalMaxBoundariesPerProfile > MAX_HISTORICAL_BOUNDARIES_PER_PROFILE ||
      AutotuneMinSignals < 10)
   {
      Print("FXNews: historical validation/autotune inputs are inconsistent.");
      return false;
   }

   return true;
}

bool IsHistoricalMode()
{
   return (OperatingMode == FXNEWS_MODE_VALIDATION ||
           OperatingMode == FXNEWS_MODE_AUTOTUNE);
}

bool IsSelfTestMode()
{
   return (OperatingMode == FXNEWS_MODE_SELFTEST);
}

// Only Live drives the market scan; the other modes run once and report.
bool IsScanningMode()
{
   return (OperatingMode == FXNEWS_MODE_LIVE);
}

string OperatingModeText()
{
   if(OperatingMode == FXNEWS_MODE_VALIDATION)
      return "VALIDATION";
   if(OperatingMode == FXNEWS_MODE_AUTOTUNE)
      return "AUTOTUNE";
   if(OperatingMode == FXNEWS_MODE_SELFTEST)
      return "SELFTEST";
   return "LIVE";
}

// ---------------------------------------------------------------------------
// Self test. Exercises the pure helpers against known inputs and prints a
// pass/fail report to the Journal. Needs no market data, no symbols and no
// history, so it runs anywhere including a closed market.
//
// It exists because the MQL5 compiler warns only about variables that are never
// touched at all: a reversed score ramp, a saturating z-score on degenerate
// input and an imputed neutral constant all compile silently. Three defects of
// exactly that kind shipped before 1.4. Each is now asserted below.
// ---------------------------------------------------------------------------
void SelfTestCheck(const bool condition, const string name)
{
   if(condition)
   {
      g_selftest_passed++;
      return;
   }
   g_selftest_failed++;
   PrintFormat("FXNews SELFTEST FAIL: %s", name);
}

void SelfTestNear(const double actual, const double expected, const string name)
{
   // Relative tolerance: an absolute 0.0001 equalled some expected values
   // (PipSize on a 5-digit symbol) and let a zero pass as correct.
   double tolerance = 0.000001 + 0.00001 * MathAbs(expected);
   if(MathAbs(actual - expected) <= tolerance)
   {
      g_selftest_passed++;
      return;
   }
   g_selftest_failed++;
   PrintFormat("FXNews SELFTEST FAIL: %s (got %.6f, expected %.6f)", name, actual, expected);
}

void SelfTestGroup(const string title, const int failed_before)
{
   int failed_now = g_selftest_failed - failed_before;
   AddHistoricalReportLine(StringFormat("  %-26s %s", title,
                                        (failed_now == 0 ? "ok" : StringFormat("%d FAILED", failed_now))));
}

void SelfTestRamps()
{
   int before = g_selftest_failed;

   SelfTestNear(SmoothStep(0.0, 1.0, 0.5), 0.5, "SmoothStep midpoint");
   SelfTestNear(SmoothStep(0.0, 1.0, -1.0), 0.0, "SmoothStep below edge0");
   SelfTestNear(SmoothStep(0.0, 1.0, 2.0), 1.0, "SmoothStep above edge1");
   SelfTestNear(SmoothStep(5.0, 5.0, 5.0), 1.0, "SmoothStep equal edges at edge");
   SelfTestNear(SmoothStep(5.0, 5.0, 4.0), 0.0, "SmoothStep equal edges below");

   // Reversed edges must still rise with x. Before 1.4 this ramp ran backwards
   // and scored 1.00 for moves against the signal.
   SelfTestCheck(SmoothStep(0.50, 0.35, 0.20) < SmoothStep(0.50, 0.35, 0.60),
                 "SmoothStep reversed edges must stay monotone rising");
   SelfTestNear(SmoothStep(1.0, 0.0, 0.5), 0.5, "SmoothStep reversed edges midpoint");

   SelfTestNear(ScoreFromZ(0.5, 0.5, 2.5), 0.0, "ScoreFromZ at low edge");
   SelfTestNear(ScoreFromZ(2.5, 0.5, 2.5), 1.0, "ScoreFromZ at high edge");

   SelfTestNear(LinearScore(0.5, 0.0, 1.0), 50.0, "LinearScore midpoint");
   SelfTestNear(LinearScore(-1.0, 0.0, 1.0), 0.0, "LinearScore below zero level");
   SelfTestNear(LinearScore(2.0, 0.0, 1.0), 100.0, "LinearScore above full level");
   SelfTestNear(LinearScore(0.5, 1.0, 0.0), 0.0, "LinearScore rejects inverted levels");

   SelfTestNear(Clamp(5.0, 0.0, 1.0), 1.0, "Clamp upper");
   SelfTestNear(Clamp(-5.0, 0.0, 1.0), 0.0, "Clamp lower");
   SelfTestNear(Clamp01(2.0), 1.0, "Clamp01 upper");
   SelfTestNear(Clamp01(-2.0), 0.0, "Clamp01 lower");

   SelfTestGroup("ramps and clamps", before);
}

void SelfTestRobustStats()
{
   int before = g_selftest_failed;

   // Degenerate dispersion carries no information. Before 1.4 this returned
   // +/-4.0, which saturated every ramp that treats a high z as evidence.
   SelfTestNear(RobustZ(1.9, 1.2, 0.0), 0.0, "RobustZ zero MAD returns no signal");
   SelfTestNear(RobustZ(0.4, 1.2, 0.0), 0.0, "RobustZ zero MAD, value below median");
   SelfTestNear(RobustZ(1.2, 1.2, 0.0), 0.0, "RobustZ zero MAD, value at median");
   SelfTestNear(RobustZ(1.4826, 0.0, 1.0), 1.0, "RobustZ unit scaling");
   SelfTestCheck(RobustZ(-1.4826, 0.0, 1.0) < 0.0, "RobustZ sign below median");

   double odd[3];
   odd[0] = 3.0; odd[1] = 1.0; odd[2] = 2.0;
   SelfTestNear(MedianOfArray(odd, 3), 2.0, "MedianOfArray odd count");

   double even[4];
   even[0] = 4.0; even[1] = 1.0; even[2] = 3.0; even[3] = 2.0;
   SelfTestNear(MedianOfArray(even, 4), 2.5, "MedianOfArray even count");

   double dev[3];
   dev[0] = 1.0; dev[1] = 2.0; dev[2] = 3.0;
   SelfTestNear(MedianAbsDeviation(dev, 3, 2.0), 1.0, "MedianAbsDeviation");

   SelfTestNear(SafeDiv(1.0, 0.0, 99.0), 99.0, "SafeDiv guards zero denominator");
   SelfTestNear(SafeDiv(10.0, 2.0, 0.0), 5.0, "SafeDiv normal");

   // The cached speed baseline relies on this identity holding for the median.
   double a[5];
   double b[5];
   for(int i = 0; i < 5; i++)
   {
      a[i] = (double)(i - 2) + 0.5;
      b[i] = -a[i];
   }
   double median_a = MedianOfArray(a, 5);
   double median_b = MedianOfArray(b, 5);
   SelfTestNear(median_b, -median_a, "median(-x) == -median(x)");

   SelfTestGroup("robust statistics", before);
}

void SelfTestTimeAndSession()
{
   int before = g_selftest_failed;

   SelfTestCheck(NormalizeHour(-1) == 23, "NormalizeHour wraps negative");
   SelfTestCheck(NormalizeHour(25) == 1, "NormalizeHour wraps above 23");
   SelfTestCheck(NormalizeHour(23) == 23, "NormalizeHour identity");

   SelfTestCheck(HourInSession(10, 7, 16), "HourInSession inside daytime window");
   SelfTestCheck(!HourInSession(16, 7, 16), "HourInSession excludes end hour");
   SelfTestCheck(HourInSession(7, 7, 16), "HourInSession includes start hour");
   SelfTestCheck(HourInSession(23, 23, 1), "HourInSession overnight start");
   SelfTestCheck(HourInSession(0, 23, 1), "HourInSession overnight wrap");
   SelfTestCheck(!HourInSession(1, 23, 1), "HourInSession overnight excludes end");
   SelfTestCheck(!HourInSession(5, 5, 5), "HourInSession empty window");

   SelfTestGroup("time and session", before);
}

void SelfTestSymbolsAndTimeframes()
{
   int before = g_selftest_failed;

   SelfTestNear(PipSize(0.00001, 5), 0.0001, "PipSize 5 digit");
   SelfTestNear(PipSize(0.001, 3), 0.01, "PipSize 3 digit");
   SelfTestNear(PipSize(0.0001, 4), 0.0001, "PipSize 4 digit");
   SelfTestNear(PipSize(0.01, 2), 0.01, "PipSize 2 digit");

   SelfTestCheck(TimeframeMinutes(PERIOD_M1) == 1, "TimeframeMinutes M1");
   SelfTestCheck(TimeframeMinutes(PERIOD_M15) == 15, "TimeframeMinutes M15");
   SelfTestCheck(TimeframeMinutes(PERIOD_H4) == 240, "TimeframeMinutes H4");
   SelfTestCheck(TimeframeMinutes(PERIOD_D1) == 1440, "TimeframeMinutes D1");
   SelfTestCheck(TimeframeMinutes(PERIOD_MN1) == 0, "TimeframeMinutes rejects unsupported");

   ENUM_TIMEFRAMES parsed = PERIOD_CURRENT;
   string label = "";
   SelfTestCheck(ParseTimeframeToken("m15", parsed, label) && parsed == PERIOD_M15 && label == "M15",
                 "ParseTimeframeToken lowercase");
   SelfTestCheck(ParseTimeframeToken("PERIOD_H4", parsed, label) && parsed == PERIOD_H4 && label == "H4",
                 "ParseTimeframeToken PERIOD_ form");
   SelfTestCheck(ParseTimeframeToken("240", parsed, label) && parsed == PERIOD_H4,
                 "ParseTimeframeToken numeric form");
   SelfTestCheck(!ParseTimeframeToken("XYZ", parsed, label), "ParseTimeframeToken rejects junk");

   int base = -1;
   int quote = -1;
   SelfTestCheck(FindBaseQuoteCurrencies("EURUSD", base, quote) && base == 0 && quote == 1,
                 "FindBaseQuoteCurrencies EURUSD");
   SelfTestCheck(FindBaseQuoteCurrencies("eurusd", base, quote) && base == 0 && quote == 1,
                 "FindBaseQuoteCurrencies is case insensitive");
   SelfTestCheck(FindBaseQuoteCurrencies("GBPJPY.pro", base, quote) && base == 2 && quote == 3,
                 "FindBaseQuoteCurrencies tolerates a broker suffix");
   SelfTestCheck(!FindBaseQuoteCurrencies("NOTAPAIR", base, quote),
                 "FindBaseQuoteCurrencies rejects a non pair");

   SelfTestCheck(UpperAscii("eurusd") == "EURUSD", "UpperAscii");
   SelfTestCheck(ObjectNamespaceToken("ab-1") == "ab_1", "ObjectNamespaceToken sanitises");
   SelfTestCheck(SelfTestTokenSafe(ObjectNamespaceToken("")) && SelfTestTokenSafe(ObjectNamespaceToken("a b/c:d")),
                 "ObjectNamespaceToken yields only object-name-safe characters");

   SelfTestGroup("symbols and timeframes", before);
}

void SelfTestScoringHelpers()
{
   int before = g_selftest_failed;

   string caps = "";
   SelfTestNear(ApplyScoreCap(90.0, 80.0, caps, "over"), 80.0, "ApplyScoreCap caps");
   SelfTestCheck(caps == "over", "ApplyScoreCap records the reason");
   SelfTestNear(ApplyScoreCap(70.0, 80.0, caps, "under"), 70.0, "ApplyScoreCap leaves a lower score");
   SelfTestCheck(caps == "over", "ApplyScoreCap does not record an unused reason");

   SelfTestCheck(ScoreBucketFloor(87.0) == 85, "ScoreBucketFloor 85+");
   SelfTestCheck(ScoreBucketFloor(72.0) == 70, "ScoreBucketFloor 70s");
   SelfTestCheck(ScoreBucketFloor(10.0) == 60, "ScoreBucketFloor floor");

   SelfTestCheck(BlockStageRank(BLOCK_NONE) < 0, "BlockStageRank none");
   SelfTestCheck(BlockStageRank(BLOCK_CONTEXT_CONFLICT) > BlockStageRank(BLOCK_BAD_SPREAD),
                 "BlockStageRank orders later stages above execution");

   SelfTestNear(DirectionalValue(5.0, DIR_DOWN), -5.0, "DirectionalValue inverts for DOWN");
   SelfTestNear(DirectionalValue(5.0, DIR_UP), 5.0, "DirectionalValue passes through for UP");
   SelfTestNear(Max3(1.0, 5.0, 3.0), 5.0, "Max3");
   SelfTestCheck(IntMax(3, 7) == 7 && IntMin(3, 7) == 3 && IntAbs(-4) == 4, "integer helpers");

   SelfTestCheck(MeetsThreshold(69.6, 70.0) && !MeetsThreshold(69.4, 70.0) && DisplayPercent(94.5) == 95,
                 "MeetsThreshold rounds like the displayed percentage");

   SelfTestGroup("scoring helpers", before);
}

bool SelfTestTokenSafe(const string token)
{
   if(StringLen(token) <= 0)
      return false;
   for(int i = 0; i < StringLen(token); i++)
   {
      ushort ch = StringGetCharacter(token, i);
      bool allowed = ((ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) ||
                      (ch >= 48 && ch <= 57) || ch == 95);
      if(!allowed)
         return false;
   }
   return true;
}

void SelfTestResetExecution(ExecutionQuality &execution)
{
   execution.pass = false;
   execution.score = 0.0;
   execution.spread_pips = 1.0;
   execution.median_available = false;
   execution.median_spread_pips = 0.0;
   execution.spread_ratio = 0.0;
   execution.spread_z_available = false;
   execution.spread_z = 0.0;
   execution.quote_age_sec = 0.0;
   execution.tick_gap_sec = 0.0;
   execution.cost_to_atr = 0.05;
   execution.block_reason = BLOCK_NONE;
}

void SelfTestResetBreakout(BreakoutStructure &breakout)
{
   breakout.pass = false;
   breakout.measured = false;
   breakout.candle_measured = false;
   breakout.score = 0.0;
   breakout.compression_score = 0.0;
   breakout.distance_score = 0.0;
   breakout.close_location_score = 0.0;
   breakout.hold_score = 0.0;
   breakout.body_quality_score = 0.0;
   breakout.wick_rejection_penalty = 0.0;
   breakout.fakeout_penalty = 0.0;
}

// The exclude-don't-impute rule and the shared composer: an unmeasured term
// must not move a score, a measured one must, and the cap ladder must hold.
void SelfTestAvailabilityAndComposer()
{
   int before = g_selftest_failed;

   ExecutionQuality execution;
   SelfTestResetExecution(execution);
   execution.spread_ratio = 999.0;
   execution.spread_z = 99.0;
   double without_terms = BlendExecutionScore(execution, 0.45, true);
   execution.spread_ratio = 0.0;
   execution.spread_z = 0.0;
   SelfTestNear(BlendExecutionScore(execution, 0.45, true), without_terms,
                "BlendExecutionScore ignores unmeasured spread terms");
   execution.median_available = true;
   execution.spread_ratio = 5.0;
   SelfTestCheck(BlendExecutionScore(execution, 0.45, true) < without_terms,
                 "BlendExecutionScore counts a measured wide spread ratio");
   execution.spread_ratio = 1.0;
   execution.quote_age_sec = 9999.0;
   SelfTestCheck(BlendExecutionScore(execution, 0.45, false) > BlendExecutionScore(execution, 0.45, true),
                 "BlendExecutionScore drops the quote terms when they are unavailable");

   RegimeContext regime_none;
   RegimeContext regime_garbage;
   RegimeContext regime_adverse;
   ComposeRegimeScore(regime_none, 0.92, false, 0.0, false, 0.0, 1.5);
   ComposeRegimeScore(regime_garbage, 0.92, false, -5.0, false, -5.0, 1.5);
   ComposeRegimeScore(regime_adverse, 0.92, true, -5.0, true, -5.0, 1.5);
   SelfTestNear(regime_none.score, regime_garbage.score, "ComposeRegimeScore ignores unmeasured context moves");
   SelfTestCheck(regime_adverse.score < regime_none.score, "ComposeRegimeScore counts measured adverse context");

   CompositeSignalScore score;
   ResetCompositeSignalScore(score);
   score.execution.pass = true;
   score.execution.score = 1.0;
   score.execution.median_available = true;
   score.execution.spread_ratio = 1.0;
   score.execution.cost_to_atr = 0.05;
   score.breakout.measured = true;
   score.breakout.pass = true;
   score.breakout.score = 1.0;
   score.breakout.hold_score = 1.0;
   score.breakout.candle_measured = true;
   score.breakout.body_quality_score = 1.0;
   score.impulse.measured = true;
   score.impulse.pass = true;
   score.impulse.score = 1.0;
   score.regime.score = 1.0;
   CompositeContext context;
   context.direction = DIR_UP;
   context.m5_move_directional = 0.0;
   context.m15_move_directional = 0.0;
   context.age_seconds = 0;
   context.age_limit_seconds = 0;
   context.max_spread_to_atr = 0.45;
   ComposeSignalScore(score, context, false);
   SelfTestCheck(score.valid && score.displayed_score > 0.0 && score.displayed_score <= 84.0,
                 "ComposeSignalScore caps a basket-less score at 84");
   double full_score = score.displayed_score;
   score.impulse.measured = false;
   score.impulse.pass = false;
   score.impulse.score = 0.0;
   ComposeSignalScore(score, context, false);
   SelfTestNear(score.displayed_score, full_score, "ComposeSignalScore excludes an unmeasured impulse from the normaliser");
   context.age_seconds = 400;
   context.age_limit_seconds = 300;
   ComposeSignalScore(score, context, false);
   SelfTestCheck(!score.valid && score.block_reason == BLOCK_EXPIRED && score.age_free_score > 0.0,
                 "ComposeSignalScore expires at the age limit and keeps the age-free score");
   context.age_limit_seconds = 0;
   ComposeSignalScore(score, context, false);
   SelfTestCheck(score.valid && score.displayed_score <= 70.0,
                 "ComposeSignalScore applies late_event_cap without an age limit");
   score.regime.m5_available = true;
   context.age_seconds = 0;
   context.m5_move_directional = M5RejectAtr - 0.01;
   ComposeSignalScore(score, context, false);
   SelfTestCheck(score.displayed_score <= 69.0, "ComposeSignalScore mtf_reject_cap uses the raw reject level");

   BreakoutStructure breakout;
   SelfTestResetBreakout(breakout);
   ComputeBreakoutStructure(DIR_UP, 0.0010, 0.0015, 0.0002, 0.0001, 1.8,
                            1.1000, 1.10002, 1.1000, 1.10001, 60.0, -1.0, breakout);
   SelfTestCheck(breakout.measured && !breakout.candle_measured && breakout.hold_score > 0.99 && breakout.pass,
                 "ComputeBreakoutStructure: tiny candle unmeasured, full hold after 60 s");
   SelfTestResetBreakout(breakout);
   ComputeBreakoutStructure(DIR_UP, 0.0010, 0.0015, 0.0002, 0.0001, 1.8,
                            1.1000, 1.1008, 1.1000, 1.1007, -1.0, 5.0, breakout);
   SelfTestCheck(breakout.candle_measured && breakout.close_location_score > 0.8 &&
                 breakout.hold_score == 0.0 && breakout.fakeout_penalty > 0.5,
                 "ComputeBreakoutStructure reads a strong candle, no hold, a fresh snapback");

   SelfTestNear(RobustZ(1.0, 0.0, 0.0, 0.5), 2.0, "RobustZ uses the sigma floor on zero dispersion");
   SelfTestNear(RobustZ(1.0, 0.0, 0.0), 0.0, "RobustZ without a floor returns 0 on zero dispersion");

   SelfTestCheck(PadRight("ab", 4) == "ab  " && PadRight("abcdef", 4) == "abcdef", "PadRight pads and never truncates");
   SelfTestCheck(FormatLocalTimestamp(D'2026.09.13 08:05:09') == "2026-09-13 08:05:09", "FormatLocalTimestamp");
   string long_text = "";
   for(int i = 0; i < 26; i++)
      long_text += "word" + IntegerToString(i) + " ";
   string pieces[];
   int piece_count = WrapLabelText(long_text, pieces);
   bool pieces_fit = (piece_count >= 3);
   for(int i = 0; i < piece_count; i++)
      pieces_fit = pieces_fit && (StringLen(pieces[i]) <= DASHBOARD_MAX_TEXT_CHARS);
   SelfTestCheck(pieces_fit && StringFind(pieces[1], "  ") == 0,
                 "WrapLabelText splits at the label limit and indents continuations");

   // Regression test for a self-test assertion that could not fail. The displayed
   // score cannot distinguish exclusion from imputation here because
   // flow_absent_cap binds at 84 either way, so the assertion above passes under
   // both the correct implementation and one that folds an unmeasured component in
   // at zero.
   //
   // With every measured component at the same quality, dropping a component's
   // weight from the normaliser leaves the blended average unchanged, whereas
   // imputing 0 drags it down by the excluded weight's share. Asserting raw_score
   // (pre-cap) therefore distinguishes the two. Flow is the component under test
   // because the breakout/impulse synergy term is identical in both branches and
   // so cancels out.
   {
      CompositeSignalScore equal_score;
      CompositeContext equal_context;
      ResetCompositeSignalScore(equal_score);
      equal_score.execution.pass = true;
      equal_score.execution.score = 0.60;
      equal_score.breakout.measured = true;
      equal_score.breakout.score = 0.60;
      equal_score.impulse.measured = true;
      equal_score.impulse.score = 0.60;
      equal_score.regime.score = 0.60;
      equal_score.flow.available = true;
      equal_score.flow.score = 0.60;
      equal_context.direction = DIR_UP;
      equal_context.m5_move_directional = 0.0;
      equal_context.m15_move_directional = 0.0;
      equal_context.age_seconds = 0;
      equal_context.age_limit_seconds = 0;
      equal_context.max_spread_to_atr = 0.45;

      ComposeSignalScore(equal_score, equal_context, false);
      double flow_measured_raw = equal_score.raw_score;

      // Exactly the state ResetCompositeSignalScore leaves behind: no reading.
      equal_score.flow.available = false;
      equal_score.flow.score = 0.0;
      ComposeSignalScore(equal_score, equal_context, false);
      SelfTestNear(equal_score.raw_score, flow_measured_raw,
                   "ComposeSignalScore leaves the blend unchanged when a component is unmeasured");
   }

   SelfTestGroup("availability and composer", before);
}

// A session bucket must publish a z-score only for a series it has actually
// sampled. The three series are folded on different conditions (the tick rate
// only when it is known, the tick volume only when the trigger timeframe has
// data), so a single shared counter let a spread-only bucket report a
// measured-looking neutral 0 for the other two. Regression test for that defect.
void SelfTestSessionBaselines()
{
   int before = g_selftest_failed;

   if(ArrayResize(g_profiles, 1) != 1 ||
      ArrayResize(g_session_baselines, SESSION_COUNT) != SESSION_COUNT)
   {
      SelfTestCheck(false, "session baseline: synthetic allocation");
      SelfTestGroup("session baselines", before);
      return;
   }

   ResetProfile(g_profiles[0], "S0", PERIOD_M5, "M5");
   ResetSessionBaselines();
   g_profiles[0].session_index = SESSION_LONDON;
   g_profiles[0].spread_pips = 1.2;
   g_profiles[0].tick_rate_available = false;   // no rate reading this scan
   g_profiles[0].has_trigger = false;           // and no tick volume either
   g_profiles[0].active_trigger_tick_volume = 0.0;

   for(int i = 0; i < MinBaselineSamples + 1; i++)
      UpdateSessionBaseline(0);

   if(UseSessionAwareBaselines)
   {
      SelfTestCheck(g_profiles[0].session_spread_z_ready,
                    "session baseline: spread reaches readiness on spread samples");
      SelfTestCheck(!g_profiles[0].session_tick_rate_z_ready,
                    "session baseline: spread samples do not make the tick-rate z ready");
      SelfTestCheck(!g_profiles[0].session_tick_volume_z_ready,
                    "session baseline: spread samples do not make the tick-volume z ready");

      // The tick rate and the trigger bar appear. One sample is not a baseline:
      // a shared counter would declare both ready here and publish a neutral 0
      // for series that had contributed nothing.
      g_profiles[0].tick_rate_available = true;
      g_profiles[0].tick_rate_per_sec = 1.5;
      g_profiles[0].has_trigger = true;
      g_profiles[0].active_trigger_tick_volume = 40.0;
      UpdateSessionBaseline(0);
      SelfTestCheck(!g_profiles[0].session_tick_rate_z_ready &&
                    !g_profiles[0].session_tick_volume_z_ready,
                    "session baseline: a single rate sample is not yet a baseline");

      // Their own samples eventually reach readiness.
      for(int i = 0; i < MinBaselineSamples + 1; i++)
         UpdateSessionBaseline(0);
      SelfTestCheck(g_profiles[0].session_tick_rate_z_ready &&
                    g_profiles[0].session_tick_volume_z_ready,
                    "session baseline: rate and volume reach readiness on their own samples");
   }
   else
   {
      SelfTestCheck(!g_profiles[0].session_spread_z_ready &&
                    !g_profiles[0].session_tick_rate_z_ready &&
                    !g_profiles[0].session_tick_volume_z_ready,
                    "session baseline: disabled input publishes no readiness at all");
   }

   // Every bucket must start from a clean slate: a new session must not inherit
   // another bucket's counts.
   int london = BaselineIndex(0, SESSION_LONDON);
   int asia = BaselineIndex(0, SESSION_ASIA);
   SelfTestCheck(g_session_baselines[london].spread_samples > 0 &&
                 g_session_baselines[asia].spread_samples == 0,
                 "session baseline: counts are per session bucket");

   SelfTestGroup("session baselines", before);
}

// The spread/cost/spread-z gate must behave identically for the live scanner and
// the historical validator, and must apply the cost-to-ATR and spread-z ceilings
// only under UseStrictExecutionGate. Regression test for the validator applying
// the cost ceiling unconditionally and so rejecting boundaries live accepts.
void SelfTestExecutionGate()
{
   int before = g_selftest_failed;

   ExecutionQuality ex;
   ex.spread_pips = 1.0;
   ex.median_available = false;
   ex.median_spread_pips = 0.0;
   ex.spread_ratio = 0.0;
   ex.spread_z_available = false;
   ex.spread_z = 0.0;
   ex.cost_to_atr = 0.60;

   SelfTestCheck(ExecutionSpreadBlock(ex, 0.45, false) == BLOCK_NONE,
                 "execution gate: a high cost-to-ATR passes when the strict gate is off");
   SelfTestCheck(ExecutionSpreadBlock(ex, 0.45, true) == BLOCK_BAD_SPREAD,
                 "execution gate: the same reading is rejected when the strict gate is on");

   // The ungated ceilings apply regardless of the strict switch.
   ex.cost_to_atr = 0.10;
   ex.spread_pips = MaxSpreadPips + 1.0;
   SelfTestCheck(ExecutionSpreadBlock(ex, 0.45, false) == BLOCK_BAD_SPREAD,
                 "execution gate: the absolute spread ceiling applies without the strict gate");

   ex.spread_pips = 1.0;
   ex.median_available = true;
   ex.spread_ratio = MaxSpreadMedianMultiplier + 0.5;
   SelfTestCheck(ExecutionSpreadBlock(ex, 0.45, false) == BLOCK_BAD_SPREAD,
                 "execution gate: the median-multiple ceiling applies without the strict gate");

   ex.median_available = false;
   ex.spread_ratio = 0.0;
   ex.spread_z_available = true;
   ex.spread_z = MaxSpreadZScore + 1.0;
   SelfTestCheck(ExecutionSpreadBlock(ex, 0.45, false) == BLOCK_NONE &&
                 ExecutionSpreadBlock(ex, 0.45, true) == BLOCK_BAD_SPREAD,
                 "execution gate: the spread-z ceiling is strict-gated as well");

   SelfTestGroup("execution gate", before);
}

// An impulse term whose inputs do not exist must leave the blend and the
// normaliser, not enter them at zero. This is the shared pure blend, so the test
// pins the contract for the live scanner and the validator alike; the validator
// used to force both weights on, which made its scores incomparable with live on
// thin history.
void SelfTestImpulseAvailability()
{
   int before = g_selftest_failed;

   ImpulseQuality impulse;
   impulse.measured = true;
   impulse.atr_expansion_score = 1.0;
   impulse.acceleration_score = 0.0;      // a zero reading, but only if measured
   impulse.tick_volume_available = false;
   impulse.tick_volume_z = 0.0;
   impulse.tick_rate_available = false;
   impulse.tick_rate_z = 0.0;

   // Speed (0.25) and ATR expansion (0.20) measured at full quality, everything
   // else unavailable: the blend must be exactly 1.0, i.e. nothing was imputed.
   BlendImpulseScore(impulse, 1.0, false, false, 0.0);
   SelfTestNear(impulse.score, 1.0, "impulse blend: unavailable terms leave the normaliser");

   // With the same zero readings declared available they carry weight, so the
   // score must drop to 0.45/0.75. If the two differ, exclusion is real.
   BlendImpulseScore(impulse, 1.0, true, true, 0.0);
   SelfTestNear(impulse.score, 0.60, "impulse blend: an available zero term carries weight");

   SelfTestGroup("impulse availability", before);
}

// hold_score is a measurement, not an imputation: a price inside the buffered
// boundary has held outside for zero seconds, which is real information, and the
// weight applies to a measured-but-not-passing box on purpose. This is a
// characterisation test - no behaviour changed - so it passes both with and
// without the clarity edit that made the assignment single-valued. It exists so
// that a future change to the guard cannot silently turn the zero into a default.
void SelfTestBreakoutHold()
{
   int before = g_selftest_failed;

   BreakoutStructure inside;
   BreakoutStructure outside;
   // Inside the boundary: distance is negative, so the box has not broken and the
   // price has held outside for zero seconds.
   ComputeBreakoutStructure(DIR_UP, 0.0010, 0.0030, -0.0002, 0.0002, 1.80,
                            1.1000, 1.1030, 1.0995, 1.1025, -1.0, -1.0, inside);
   // Same bar, broken and held well past the full-hold horizon.
   ComputeBreakoutStructure(DIR_UP, 0.0010, 0.0030, 0.0006, 0.0002, 1.80,
                            1.1000, 1.1030, 1.0995, 1.1025,
                            (double)FullHoldScoreSeconds * 2.0, -1.0, outside);

   SelfTestCheck(inside.measured && !inside.pass && inside.hold_score == 0.0,
                 "ComputeBreakoutStructure: an unbroken box is measured, not passing, zero hold");
   SelfTestCheck(outside.measured && outside.pass && outside.hold_score > 0.99 &&
                 outside.score > inside.score,
                 "ComputeBreakoutStructure weights a sustained hold above a zero hold");

   SelfTestGroup("breakout hold", before);
}

// The historical engine on a synthetic minute series with a known shape and
// a deliberate ten-minute gap after bar 250.
void SelfTestHistoricalEngine()
{
   int before = g_selftest_failed;

   int total = 400;
   MqlRates rates[];
   if(ArrayResize(rates, total) != total)
   {
      SelfTestCheck(false, "historical engine: synthetic series allocation");
      SelfTestGroup("historical engine", before);
      return;
   }
   datetime t = D'2026.01.05 00:00';
   for(int i = 0; i < total; i++)
   {
      if(i == 250)
         t += 600;
      rates[i].time = t;
      rates[i].open = 1.1000 + (double)i * 0.0001;
      rates[i].high = rates[i].open + 0.0002;
      rates[i].low = rates[i].open - 0.0001;
      rates[i].close = rates[i].open + 0.0001;
      rates[i].tick_volume = 10 + (i % 3);
      rates[i].spread = ((i % 2) == 0 ? 10 : 0);
      rates[i].real_volume = 0;
      t += 60;
   }

   SelfTestCheck(IsHistoricalEvaluationBoundary(D'2026.01.05 00:05', 5) &&
                 !IsHistoricalEvaluationBoundary(D'2026.01.05 00:06', 5),
                 "IsHistoricalEvaluationBoundary on the M5 grid");
   SelfTestCheck(IsHistoricalEvaluationBoundary(D'2026.01.06 00:00', 1440) &&
                 !IsHistoricalEvaluationBoundary(D'2026.01.05 12:00', 1440),
                 "IsHistoricalEvaluationBoundary on the D1 grid");
   SelfTestCheck(HistoricalIndexAtOrBefore(rates, total, rates[100].time) == 100 &&
                 HistoricalIndexAtOrBefore(rates, total, rates[100].time + 30) == 100 &&
                 HistoricalIndexAtOrBefore(rates, total, rates[0].time - 60) == -1,
                 "HistoricalIndexAtOrBefore");

   HistoricalBar bar;
   double volume_95_99 = 0.0;
   for(int i = 95; i <= 99; i++)
      volume_95_99 += (double)rates[i].tick_volume;
   SelfTestCheck(AggregateHistoricalBarAt(rates, total, rates[99].time + 60, 300, 0, bar) && bar.valid &&
                 MathAbs(bar.open - rates[95].open) < 0.0000001 &&
                 MathAbs(bar.close - rates[99].close) < 0.0000001 &&
                 MathAbs(bar.high - rates[99].high) < 0.0000001 &&
                 MathAbs(bar.low - rates[95].low) < 0.0000001 &&
                 MathAbs(bar.volume - volume_95_99) < 0.0000001,
                 "AggregateHistoricalBarAt aggregates the five minutes ending at the boundary");
   SelfTestCheck(AggregateHistoricalBarAt(rates, total, rates[99].time + 60, 300, 1, bar) &&
                 MathAbs(bar.open - rates[90].open) < 0.0000001,
                 "AggregateHistoricalBarAt steps back whole bars");
   SelfTestCheck(!AggregateHistoricalBarAt(rates, total, rates[252].time + 60, 900, 0, bar) && !bar.valid,
                 "AggregateHistoricalBarAt rejects a bar missing most of its minutes");

   HistoricalBar bars[];
   if(ArrayResize(bars, 20) == 20)
   {
      for(int k = 0; k < 20; k++)
         AggregateHistoricalBarAt(rates, total, rates[199].time + 60, 300, k, bars[k]);
      SelfTestNear(HistoricalATRFromBars(bars, 20, 14), 0.0007, "HistoricalATRFromBars on the synthetic bars");
      double range_high = 0.0;
      double range_low = 0.0;
      SelfTestCheck(HistoricalRangeBox(bars, 10, range_high, range_low) &&
                    MathAbs(range_high - bars[1].high) < 0.0000001 &&
                    MathAbs(range_low - bars[10].low) < 0.0000001,
                    "HistoricalRangeBox spans bars 1..lookback");
      double volume_z = 0.0;
      SelfTestCheck(HistoricalTickVolumeZ(bars, 20, volume_z) && MathAbs(volume_z) < 3.0,
                    "HistoricalTickVolumeZ measures against the previous bars");
   }
   else
      SelfTestCheck(false, "historical engine: bar allocation");

   SelfTestNear(HistoricalSpreadPips(rates[0], 0.00001, 0.0001), 1.0, "HistoricalSpreadPips converts points to pips");
   SelfTestNear(HistoricalSpreadPips(rates[1], 0.00001, 0.0001), 0.0, "HistoricalSpreadPips reports a missing spread as 0");

   double result_R = 0.0;
   bool target_hit = false;
   bool stop_hit = false;
   // The excursion reaches the target in the fifth minute up to floating-point
   // rounding, so the window is six minutes to keep the assertion exact.
   SelfTestCheck(EvaluateHistoricalOutcomeAtHorizon(rates, total, 100, DIR_UP, rates[100].close, 0.0001, 0.0010, 6,
                                                    result_R, target_hit, stop_hit) &&
                 target_hit && !stop_hit && MathAbs(result_R - 0.0005 / 0.00035) < 0.000001,
                 "outcome: a rising series hits the target first, paying the spread");
   SelfTestCheck(EvaluateHistoricalOutcomeAtHorizon(rates, total, 100, DIR_DOWN, rates[100].close, 0.0001, 0.0010, 5,
                                                    result_R, target_hit, stop_hit) &&
                 stop_hit && !target_hit && MathAbs(result_R + 1.0) < 0.000001,
                 "outcome: a short against a rising series stops out at -1 R");
   SelfTestCheck(EvaluateHistoricalOutcomeAtHorizon(rates, total, 100, DIR_UP, rates[100].close, 0.0001, 0.0010, 1,
                                                    result_R, target_hit, stop_hit) &&
                 !target_hit && !stop_hit && MathAbs(result_R) < 0.000001,
                 "outcome: an undecided window closes at the exit price");
   SelfTestCheck(!EvaluateHistoricalOutcomeAtHorizon(rates, total, 249, DIR_UP, rates[249].close, 0.0001, 0.0010, 5,
                                                     result_R, target_hit, stop_hit),
                 "outcome: a gapped horizon is unevaluable");
   double saved_high = rates[300].high;
   double saved_low = rates[300].low;
   rates[300].high = rates[299].close + 0.0100;
   rates[300].low = rates[299].close - 0.0100;
   SelfTestCheck(EvaluateHistoricalOutcomeAtHorizon(rates, total, 299, DIR_UP, rates[299].close, 0.0001, 0.0010, 5,
                                                    result_R, target_hit, stop_hit) &&
                 stop_hit && !target_hit,
                 "outcome: target and stop in one minute resolve as a stop");
   rates[300].high = saved_high;
   rates[300].low = saved_low;

   HistoricalBacktestStats stats;
   ResetHistoricalStats(stats);
   AddHistoricalBucketStats(stats, 60, 1.0);
   AddHistoricalBucketStats(stats, 85, -1.0);
   AddHistoricalBucketStats(stats, 75, 0.5);
   SelfTestCheck(stats.bucket60_count == 1 && stats.bucket85_count == 1 && stats.bucket75_count == 1 &&
                 MathAbs(stats.bucket75_R - 0.5) < 0.000001,
                 "AddHistoricalBucketStats routes by bucket floor");
   stats.gross_win_R = 3.0;
   stats.gross_loss_R = 1.0;
   SelfTestNear(ProfitFactorProxy(stats), 1.5, "ProfitFactorProxy with the unit prior");
   stats.target_score_sum = 160.0;
   stats.target_score_count = 2;
   stats.stop_score_sum = 70.0;
   stats.stop_score_count = 1;
   SelfTestNear(ScoreEdge(stats), 10.0, "ScoreEdge");
   stats.signals = AutotuneMinSignals - 1;
   SelfTestCheck(AutotuneObjective(stats) < -99999.0, "AutotuneObjective floors an under-sampled candidate");
   SelfTestCheck(TimeframeMinutes(PERIOD_M5) == 5 && TimeframeMinutes(PERIOD_M30) == 30 &&
                 TimeframeMinutes(PERIOD_H1) == 60 && TimeframeMinutes(PERIOD_H8) == 480 &&
                 TimeframeMinutes(PERIOD_H12) == 720 && TimeframeMinutes(PERIOD_W1) == 0,
                 "TimeframeMinutes covers the remaining branches");

   SelfTestGroup("historical engine", before);
}

// The recent-signal list on synthetic profiles: insert, update in place,
// sub-threshold rejection, capacity eviction with the minimum dwell.
void SelfTestSignalHistory()
{
   int before = g_selftest_failed;
   int profile_count = SIGNAL_HISTORY_SIZE + 2;
   if(ArrayResize(g_profiles, profile_count) != profile_count)
   {
      SelfTestCheck(false, "signal history: profile allocation");
      SelfTestGroup("signal history", before);
      return;
   }
   for(int i = 0; i < profile_count; i++)
   {
      ResetProfile(g_profiles[i], StringFormat("S%02d", i), PERIOD_M5, "M5");
      g_profiles[i].composite_up.human_reason = "test";
      g_profiles[i].composite_up.compact_tags = "BRK+";
   }
   ClearSignalHistory();

   datetime base = D'2026.09.13 10:00:00';
   PushSignalHistory(0, DIR_UP, 80.0, base);
   SelfTestCheck(g_signal_history_count == 1 && g_signal_history[0].used &&
                 StringFind(g_signal_history[0].text, "S00") >= 0 &&
                 g_signal_history[0].reason == "test | BRK+",
                 "PushSignalHistory inserts a displayable entry with its reason");
   PushSignalHistory(0, DIR_UP, 50.0, base + 5);
   SelfTestCheck(g_signal_history_count == 1 && MathAbs(g_signal_history[0].score - 80.0) < 0.000001,
                 "PushSignalHistory ignores a sub-threshold score");
   PushSignalHistory(0, DIR_UP, 90.0, base + 5);
   SelfTestCheck(g_signal_history_count == 1 && MathAbs(g_signal_history[0].score - 90.0) < 0.000001,
                 "PushSignalHistory updates the same signal in place");

   for(int i = 1; i < SIGNAL_HISTORY_SIZE; i++)
      PushSignalHistory(i, DIR_UP, 80.0, base + i);
   SelfTestCheck(g_signal_history_count == SIGNAL_HISTORY_SIZE &&
                 g_signal_history[0].symbol == StringFormat("S%02d", SIGNAL_HISTORY_SIZE - 1) &&
                 g_signal_history[SIGNAL_HISTORY_SIZE - 1].symbol == "S00",
                 "PushSignalHistory keeps newest-first order at capacity");
   // Every slot is inside its dwell: the tail goes.
   PushSignalHistory(SIGNAL_HISTORY_SIZE, DIR_UP, 80.0, base + SIGNAL_HISTORY_SIZE);
   SelfTestCheck(g_signal_history_count == SIGNAL_HISTORY_SIZE &&
                 g_signal_history[0].symbol == StringFormat("S%02d", SIGNAL_HISTORY_SIZE) &&
                 g_signal_history[SIGNAL_HISTORY_SIZE - 1].symbol == "S01",
                 "PushSignalHistory evicts the tail when every slot is within its dwell");
   // Now every slot is past its dwell: the oldest past-dwell slot goes.
   PushSignalHistory(SIGNAL_HISTORY_SIZE + 1, DIR_UP, 80.0, base + 1000);
   SelfTestCheck(g_signal_history_count == SIGNAL_HISTORY_SIZE &&
                 g_signal_history[0].symbol == StringFormat("S%02d", SIGNAL_HISTORY_SIZE + 1) &&
                 g_signal_history[SIGNAL_HISTORY_SIZE - 1].symbol == "S02",
                 "PushSignalHistory evicts the oldest slot past its dwell");
   SelfTestCheck(!IsSignalMessageDisplayable(RecentListMinScore - 0.6) &&
                 IsSignalMessageDisplayable(RecentListMinScore - 0.4),
                 "IsSignalMessageDisplayable rounds against RecentListMinScore");

   ClearSignalHistory();
   ArrayResize(g_profiles, 0);
   SelfTestGroup("signal history", before);
}

void RunSelfTest()
{
   if(g_selftest_done)
      return;
   g_selftest_done = true;

   g_selftest_passed = 0;
   g_selftest_failed = 0;

   ClearHistoricalReport();
   AddHistoricalReportLine("FXNEWS SELF TEST | pure-function checks | no market data required");

   SelfTestRamps();
   SelfTestRobustStats();
   SelfTestTimeAndSession();
   SelfTestSymbolsAndTimeframes();
   SelfTestScoringHelpers();
   SelfTestAvailabilityAndComposer();
   SelfTestSessionBaselines();
   SelfTestExecutionGate();
   SelfTestImpulseAvailability();
   SelfTestBreakoutHold();
   SelfTestHistoricalEngine();
   SelfTestSignalHistory();

   AddHistoricalReportLine(StringFormat("RESULT: %d passed, %d failed of %d assertions",
                                        g_selftest_passed, g_selftest_failed,
                                        g_selftest_passed + g_selftest_failed));
   if(g_selftest_failed > 0)
      AddHistoricalReportLine("Failures are listed individually above in the Journal.");

   PrintHistoricalReportToJournal();
   SetHistoricalReadyMessage(StringFormat("SELFTEST %s",
                                          (g_selftest_failed == 0 ? "PASSED" : "FAILED")));
}

void RunHistoricalOperatingMode()
{
   if(g_historical_run_finished)
      return;

   if(g_historical_run_started)
      return;

   g_historical_run_started = true;
   // The backtest runs synchronously inside this timer call, so the chart
   // label below is rarely painted before the run ends; the Journal line is
   // the reliable sign that the run has started.
   PrintFormat("FXNews: %s run started over %d days of M1 history; the chart updates when it completes.",
               OperatingModeText(), HistoricalLookbackDays);
   SetHistoricalReportHeader("FXNews - " + OperatingModeText() + " | running M1 backtest");

   // Symbols that failed at initialisation get one more attempt before the
   // run, and every symbol still unavailable is named in the Journal; the live
   // scan's throttled status reporting never runs in this mode.
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      g_profiles[i].next_symbol_retry_time = 0;
      if(!EnsureSymbolReady(i) && g_profiles[i].is_first_profile_for_symbol &&
         g_profiles[i].status_message != "")
      {
         PrintFormat("FXNews profile %s: excluded from the run, %s",
                     g_profiles[i].symbol, g_profiles[i].status_message);
      }
   }

   HistoricalParams base_params;
   BuildBaseHistoricalParams(base_params);

   bool completed = false;
   if(OperatingMode == FXNEWS_MODE_VALIDATION)
   {
      HistoricalBacktestStats stats;
      completed = RunHistoricalBacktest(base_params, stats);
      if(completed)
         BuildValidationReport(stats, base_params);
   }
   else
   {
      completed = RunAutotuneBacktest(base_params);
   }

   if(!completed)
   {
      // The terminal asked us to stop mid-run; partial statistics are not a
      // report and must not read like one.
      Print("FXNews: " + OperatingModeText() + " run ABORTED before completion; no report was produced.");
      SetHistoricalReportHeader("FXNews - " + OperatingModeText() + " | ABORTED, no report");
   }

   g_historical_run_finished = true;
   UpdateHistoricalReportDashboard();
}

// ---------------------------------------------------------------------------
// Historical validation and Autotune.
//
// The validator replays closed M1 history through the SAME composer, breakout
// structure, impulse blend and regime blend as the live scanner. Only the
// feature extraction differs, and every feature that bar data cannot provide
// is left unmeasured rather than approximated:
//   - the currency basket (needs every symbol at once)  -> flow unavailable
//   - the economic calendar                            -> calendar unavailable
//   - tick rate, tick sample quality, quote age, tick gap -> unavailable
//   - the impulse speed z-scores are MINUTE-scale windows, not the live
//     second-scale ones, and carry their own proxy threshold
//     (HistoricalParams.minute_impulse_z, never MinImpulseZForSignal)
// The composite is therefore capped at flow_absent_cap (84) and
// no_calendar_cap (94) exactly as a live instance without a basket reading
// would be, and the report says so.
// ---------------------------------------------------------------------------

struct HistoricalBar
{
   bool valid;
   double open;
   double high;
   double low;
   double close;
   double volume;
};

// Everything about one evaluation boundary that no candidate parameter and no
// direction changes; computed once and reused for every candidate and both
// directions.
struct HistoricalBoundaryFeatures
{
   bool valid;
   datetime close_time;            // close of the M1 bar at the boundary
   double atr;                     // scan-timeframe ATR in price units
   double atr_pips;
   double pip_size;
   double point;
   double spread_pips;
   double spread_price;
   int spread_source;              // HISTORICAL_SPREAD_* below
   bool median_available;
   double median_spread_pips;
   double spread_ratio;
   bool spread_z_available;
   double spread_z;
   double cost_to_atr;
   bool rollover;
   double session_score;
   bool speed_ready[SPEED_WINDOW_COUNT];
   double speed_z_up[SPEED_WINDOW_COUNT];   // signed for DIR_UP; negate for DIR_DOWN
   double acceleration_up;                  // ATR per minute, signed for DIR_UP
   bool acceleration_available;             // both the 5- and the 30-minute window exist
   bool tick_volume_available;
   double tick_volume_z;
   double move5_atr_up;                     // five-minute close move in ATR, signed for DIR_UP
   bool continuation_available;             // the 5-minute window exists
   bool m5_available;
   double m5_move_up;                       // last closed 5-minute bar move / ATR5
   bool m15_available;
   double m15_move_up;
};

void BuildBaseHistoricalParams(HistoricalParams &params)
{
   params.name = "CURRENT";
   params.range_lookback = RangeLookbackM1;
   params.breakout_buffer_atr = BreakoutBufferATR;
   params.min_breakout_buffer_pips = MinBreakoutBufferPips;
   params.min_confidence = MinDisplayConfidence;
   params.max_spread_to_atr = MaxSpreadToAtrRatio;
   params.max_overextension_atr = MaxOverextensionAtr;
   params.minute_impulse_z = MinImpulseZForSignal;
}

// Eight fixed candidate profiles. Every candidate is judged on the same
// outcome definition (OutcomeTargetAtr / OutcomeStopAtr), so a candidate can
// only win on better signals, never on a more forgiving target geometry.
void BuildAutotuneCandidate(const int candidate, const HistoricalParams &base_params, HistoricalParams &params)
{
   params = base_params;
   params.name = "C" + IntegerToString(candidate);

   if(candidate == 1)
   {
      params.name = "FAST";
      params.range_lookback = 20;
      params.breakout_buffer_atr = 0.08;
      params.min_breakout_buffer_pips = 0.8;
      params.min_confidence = 58.0;
      params.max_spread_to_atr = 0.50;
      params.max_overextension_atr = 2.20;
      params.minute_impulse_z = 1.05;
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
      params.minute_impulse_z = 1.20;
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
      params.minute_impulse_z = 1.25;
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
      params.minute_impulse_z = 1.30;
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
      params.minute_impulse_z = 1.35;
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
      params.minute_impulse_z = 1.10;
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
      params.minute_impulse_z = 1.40;
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
      params.minute_impulse_z = 1.15;
   }
}

bool RunAutotuneBacktest(const HistoricalParams &base_params)
{
   HistoricalParams candidates[AUTOTUNE_CANDIDATE_COUNT];
   HistoricalBacktestStats results[AUTOTUNE_CANDIDATE_COUNT];
   candidates[0] = base_params;
   for(int candidate = 1; candidate < AUTOTUNE_CANDIDATE_COUNT; candidate++)
      BuildAutotuneCandidate(candidate, base_params, candidates[candidate]);

   if(!RunHistoricalBacktestSet(candidates, results, AUTOTUNE_CANDIDATE_COUNT))
      return false;

   int best = 0;
   double best_objective = AutotuneObjective(results[0]);
   for(int candidate = 1; candidate < AUTOTUNE_CANDIDATE_COUNT; candidate++)
   {
      double objective = AutotuneObjective(results[candidate]);
      if(objective > best_objective)
      {
         best_objective = objective;
         best = candidate;
      }
   }

   // Historical results are advisory only: the source has no holdout or
   // walk-forward control. The instance stays parked in AUTOTUNE afterwards,
   // exactly like VALIDATION: switching to LIVE here wiped the report off the
   // chart on the next scan and let alerts fire from a run the user started as
   // an analysis.
   BuildAutotuneReport(results[0], results[best], base_params, candidates[best]);
   return true;
}

bool HasSufficientAutotuneSample(const HistoricalBacktestStats &stats)
{
   return (stats.signals >= AutotuneMinSignals);
}

double AutotuneObjective(const HistoricalBacktestStats &stats)
{
   // A candidate below the sample floor is not ranked at all, so an
   // under-sampled candidate can never win on sample size alone.
   if(!HasSufficientAutotuneSample(stats))
      return -100000.0;

   return AverageR30(stats) * 100.0 +
          HitRate30(stats) * 25.0 -
          StopRate30(stats) * 15.0 +
          ProfitFactorProxy(stats) * 4.0 +
          ScoreEdge(stats) * 0.35;
}

bool RunHistoricalBacktest(const HistoricalParams &params, HistoricalBacktestStats &stats)
{
   HistoricalParams single_set[1];
   HistoricalBacktestStats single_stats[1];
   single_set[0] = params;
   bool completed = RunHistoricalBacktestSet(single_set, single_stats, 1);
   stats = single_stats[0];
   return completed;
}

// Every parameter set is scored against the same in-memory history, so a full
// Autotune sweep loads each symbol once and computes each boundary's features
// once for all candidates. Returns false when the terminal asked us to stop.
bool RunHistoricalBacktestSet(HistoricalParams &params_set[],
                              HistoricalBacktestStats &stats_set[],
                              const int set_count)
{
   for(int c = 0; c < set_count; c++)
      ResetHistoricalStats(stats_set[c]);

   string symbols[];
   int symbol_count = CollectHistoricalSymbols(symbols);
   for(int c = 0; c < set_count; c++)
      stats_set[c].symbols_requested = symbol_count;

   int total_profiles = ArraySize(g_profiles);
   for(int s = 0; s < symbol_count; s++)
   {
      if(IsStopped())
         return false;

      MqlRates rates[];
      int copied = LoadHistoricalM1Rates(symbols[s], rates);
      if(copied <= 0)
      {
         PrintFormat("FXNews %s: %s has no M1 history in the window (error %d) and is skipped; "
                     "open a chart of the symbol so the terminal downloads it, then re-run.",
                     OperatingModeText(), symbols[s], GetLastError());
         continue;
      }

      datetime first_time = rates[0].time;
      datetime last_time = rates[copied - 1].time;
      double achieved_days = (double)(last_time - first_time) / 86400.0;
      if(achieved_days < 0.5 * (double)HistoricalLookbackDays)
      {
         PrintFormat("FXNews %s: %s covers only %.1f of the requested %d days (%d M1 bars).",
                     OperatingModeText(), symbols[s], achieved_days, HistoricalLookbackDays, copied);
      }
      for(int c = 0; c < set_count; c++)
      {
         stats_set[c].symbols_loaded++;
         stats_set[c].bars_loaded += copied;
         if(stats_set[c].from_time == 0 || first_time < stats_set[c].from_time)
            stats_set[c].from_time = first_time;
         if(last_time > stats_set[c].to_time)
            stats_set[c].to_time = last_time;
      }

      string symbol_upper = UpperAscii(symbols[s]);
      for(int profile_index = 0; profile_index < total_profiles; profile_index++)
      {
         if(!g_profiles[profile_index].valid ||
            g_profiles[profile_index].symbol_upper != symbol_upper)
         {
            continue;
         }
         if(!ProcessHistoricalProfile(profile_index, rates, copied, params_set, stats_set, set_count))
            return false;
      }

      PrintFormat("FXNews %s: %d/%d symbols processed (%s, %d M1 bars, %.1f days)",
                  OperatingModeText(), s + 1, symbol_count, symbols[s], copied, achieved_days);
   }

   return true;
}

int CollectHistoricalSymbols(string &symbols[])
{
   if(ArrayResize(symbols, 0) != 0)
      return 0;

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!g_profiles[i].valid || !g_profiles[i].selected)
         continue;
      if(SymbolListContains(symbols, g_profiles[i].symbol))
         continue;

      int next = ArraySize(symbols);
      if(ArrayResize(symbols, next + 1) != next + 1)
         return ArraySize(symbols);
      symbols[next] = g_profiles[i].symbol;
   }

   return ArraySize(symbols);
}

// Oldest-first M1 history ending at the last closed bar. CopyRates into a
// fresh, non-series array always delivers index 0 as the oldest bar.
int LoadHistoricalM1Rates(const string symbol, MqlRates &rates[])
{
   if(ArrayResize(rates, 0) != 0)
      return 0;

   datetime last_closed = iTime(symbol, PERIOD_M1, 1);
   if(last_closed <= 0)
      last_closed = TimeCurrent() - 60;

   datetime from_time = last_closed - (datetime)HistoricalLookbackDays * 86400;
   ResetLastError();
   ArraySetAsSeries(rates, false);
   int copied = CopyRates(symbol, PERIOD_M1, from_time, last_closed, rates);
   if(copied <= 0)
      return 0;

   return ArraySize(rates);
}

// Largest of the candidates' range lookbacks, so the aggregated bars are built
// once per boundary and serve every candidate.
int MaxRangeLookback(HistoricalParams &params_set[], const int set_count)
{
   int longest = 1;
   for(int c = 0; c < set_count; c++)
      longest = IntMax(longest, params_set[c].range_lookback);
   return longest;
}

// Scans one symbol/timeframe profile over the loaded history for every
// candidate at once. Boundaries are sub-sampled uniformly so at most
// HistoricalMaxBoundariesPerProfile are evaluated; the report prints the
// achieved coverage. Returns false when the terminal asked us to stop.
bool ProcessHistoricalProfile(const int profile_index,
                              MqlRates &rates[],
                              const int copied,
                              HistoricalParams &params_set[],
                              HistoricalBacktestStats &stats_set[],
                              const int set_count)
{
   int tf_minutes = TimeframeMinutes(g_profiles[profile_index].scan_timeframe);
   if(tf_minutes <= 0 || set_count <= 0)
      return true;

   int max_lookback = MaxRangeLookback(params_set, set_count);
   int bars_needed = IntMax(max_lookback, IntMax(ATRPeriod + 1, HISTORICAL_VOLUME_BASELINE_BARS)) + 1;
   int required = bars_needed * tf_minutes + 70;
   required = IntMax(required, HistoricalWarmupBars);
   int last_index = copied - OutcomeHorizonMinutes3 - 2;
   if(last_index <= required)
      return true;

   int estimated_boundaries = IntMax(1, (last_index - required) / tf_minutes);
   int boundary_stride = IntMax(1, (estimated_boundaries + HistoricalMaxBoundariesPerProfile - 1) /
                                HistoricalMaxBoundariesPerProfile);
   boundary_stride = IntMax(boundary_stride, (HistoricalStepMinutes + tf_minutes - 1) / tf_minutes);
   for(int c = 0; c < set_count; c++)
   {
      stats_set[c].boundaries_total += estimated_boundaries;
      stats_set[c].boundary_stride_max = IntMax(stats_set[c].boundary_stride_max, boundary_stride);
   }

   datetime next_up_allowed[];
   datetime next_down_allowed[];
   bool profile_counted[];
   if(ArrayResize(next_up_allowed, set_count) != set_count ||
      ArrayResize(next_down_allowed, set_count) != set_count ||
      ArrayResize(profile_counted, set_count) != set_count)
   {
      return true;
   }
   for(int c = 0; c < set_count; c++)
   {
      next_up_allowed[c] = 0;
      next_down_allowed[c] = 0;
      profile_counted[c] = false;
   }

   HistoricalBar bars[];
   if(ArrayResize(bars, bars_needed) != bars_needed)
      return true;

   // Last-resort spread for bars without a spread column: the symbol's
   // current spread, read once per profile.
   double symbol_spread_pips = 0.0;
   if(g_profiles[profile_index].pip_size > 0.0)
   {
      symbol_spread_pips = (double)SymbolInfoInteger(g_profiles[profile_index].symbol, SYMBOL_SPREAD) *
                           g_profiles[profile_index].point / g_profiles[profile_index].pip_size;
   }

   int boundary_seen = 0;
   for(int i = required; i < last_index; i++)
   {
      if(IsStopped())
         return false;
      if(!IsHistoricalEvaluationBoundary(rates[i].time + 60, tf_minutes))
         continue;
      if((boundary_seen++ % boundary_stride) != 0)
         continue;

      HistoricalBoundaryFeatures features;
      if(!BuildHistoricalBoundaryFeatures(profile_index, rates, copied, i, tf_minutes, symbol_spread_pips,
                                          bars, bars_needed, features))
      {
         for(int c = 0; c < set_count; c++)
            stats_set[c].boundaries_rejected++;
         continue;
      }

      for(int c = 0; c < set_count; c++)
      {
         stats_set[c].bars_scanned++;
         if(!profile_counted[c])
         {
            stats_set[c].profiles_tested++;
            profile_counted[c] = true;
         }
         if(features.spread_source == HISTORICAL_SPREAD_BAR)
            stats_set[c].spread_from_bar++;
         else if(features.spread_source == HISTORICAL_SPREAD_MEDIAN)
            stats_set[c].spread_from_median++;
         else if(features.spread_source == HISTORICAL_SPREAD_SYMBOL)
            stats_set[c].spread_from_symbol++;
         else
            stats_set[c].spread_unavailable++;

         double range_high = 0.0;
         double range_low = 0.0;
         if(!HistoricalRangeBox(bars, params_set[c].range_lookback, range_high, range_low))
            continue;

         HistoricalSignalScore up_score;
         HistoricalSignalScore down_score;
         ScoreHistoricalBoundary(features, bars[0], range_high, range_low, DIR_UP, params_set[c], up_score);
         ScoreHistoricalBoundary(features, bars[0], range_high, range_low, DIR_DOWN, params_set[c], down_score);

         HistoricalSignalScore best_score = up_score;
         if(down_score.valid && (!up_score.valid || down_score.displayed_score > up_score.displayed_score))
            best_score = down_score;
         if(!best_score.valid || !MeetsThreshold(best_score.displayed_score, params_set[c].min_confidence))
            continue;

         if(best_score.direction == DIR_UP && features.close_time < next_up_allowed[c])
            continue;
         if(best_score.direction == DIR_DOWN && features.close_time < next_down_allowed[c])
            continue;

         HistoricalOutcome outcome;
         EvaluateHistoricalOutcome(rates, copied, i, best_score.direction, bars[0].close,
                                   best_score.spread_price, best_score.atr_price, outcome);
         if(!outcome.evaluable)
         {
            stats_set[c].signals_unevaluable++;
            continue;
         }
         AddHistoricalStats(stats_set[c], best_score, outcome);

         if(best_score.direction == DIR_UP)
            next_up_allowed[c] = features.close_time + ValidSignalCooldownSeconds;
         else
            next_down_allowed[c] = features.close_time + ValidSignalCooldownSeconds;
      }
   }

   return true;
}

// Index of the last M1 bar whose open time is at or before `time`, or -1.
int HistoricalIndexAtOrBefore(MqlRates &rates[], const int copied, const datetime time)
{
   int low = 0;
   int high = copied - 1;
   int found = -1;
   while(low <= high)
   {
      int mid = (low + high) / 2;
      if(rates[mid].time <= time)
      {
         found = mid;
         low = mid + 1;
      }
      else
         high = mid - 1;
   }
   return found;
}

// Aggregates the bar of `tf_seconds` that ends `bar_back` bars before the
// boundary closing at `close_time`, by TIME rather than by index count, so a
// missing minute inside the bar does not throw the whole bar away. The bar is
// valid when at least HISTORICAL_MIN_BAR_COVERAGE of its minutes exist.
bool AggregateHistoricalBarAt(MqlRates &rates[],
                              const int copied,
                              const datetime close_time,
                              const int tf_seconds,
                              const int bar_back,
                              HistoricalBar &bar)
{
   bar.valid = false;
   datetime bar_close = close_time - (datetime)bar_back * tf_seconds;
   datetime last_minute = bar_close - 60;
   datetime first_minute = bar_close - tf_seconds;

   int end_index = HistoricalIndexAtOrBefore(rates, copied, last_minute);
   if(end_index < 0 || rates[end_index].time < first_minute)
      return false;

   int minutes = 0;
   bar.high = rates[end_index].high;
   bar.low = rates[end_index].low;
   bar.close = rates[end_index].close;
   bar.volume = 0.0;
   int start_index = end_index;
   for(int j = end_index; j >= 0 && rates[j].time >= first_minute; j--)
   {
      bar.high = MathMax(bar.high, rates[j].high);
      bar.low = MathMin(bar.low, rates[j].low);
      bar.volume += (double)rates[j].tick_volume;
      start_index = j;
      minutes++;
   }
   bar.open = rates[start_index].open;

   double coverage = (double)minutes / (double)(tf_seconds / 60);
   bar.valid = (coverage >= HISTORICAL_MIN_BAR_COVERAGE);
   return bar.valid;
}

// ATR of the scan timeframe from the aggregated bars 1..period, with each
// bar's true range measured against the previous aggregated bar's close.
double HistoricalATRFromBars(HistoricalBar &bars[], const int bars_available, const int period)
{
   double total = 0.0;
   int counted = 0;
   for(int bar = 1; bar <= period && bar + 1 < bars_available; bar++)
   {
      if(!bars[bar].valid || !bars[bar + 1].valid)
         break;
      double previous_close = bars[bar + 1].close;
      total += Max3(bars[bar].high - bars[bar].low,
                    MathAbs(bars[bar].high - previous_close),
                    MathAbs(bars[bar].low - previous_close));
      counted++;
   }
   if(counted <= 0)
      return 0.0;
   return total / (double)counted;
}

// The range box over the aggregated bars 1..lookback, exactly as the live
// box is built from the closed bars before the trigger bar.
bool HistoricalRangeBox(HistoricalBar &bars[], const int lookback, double &range_high, double &range_low)
{
   if(lookback < 1 || lookback >= ArraySize(bars))
      return false;
   range_high = bars[1].high;
   range_low = bars[1].low;
   for(int bar = 1; bar <= lookback; bar++)
   {
      if(!bars[bar].valid)
         return false;
      range_high = MathMax(range_high, bars[bar].high);
      range_low = MathMin(range_low, bars[bar].low);
   }
   return (range_high > range_low);
}

double HistoricalSpreadPips(const MqlRates &rate, const double point, const double pip_size)
{
   if(rate.spread > 0)
      return (double)rate.spread * point / pip_size;
   return 0.0;   // no spread column: unmeasured, never an assumed value
}

// Median and robust z of the spread over the previous `lookback` M1 bars that
// carry a spread; unavailable until MIN_SPREAD_SAMPLES of them exist.
bool HistoricalSpreadStatistics(MqlRates &rates[],
                                const int index,
                                const double point,
                                const double pip_size,
                                const int lookback,
                                const double current_spread_pips,
                                double &median,
                                double &robust_z)
{
   median = 0.0;
   robust_z = 0.0;
   int count = IntMin(lookback, index);
   if(count <= 0 || !PrepareScratch(g_hist_scratch, count, HISTORICAL_SCRATCH_RESERVE))
      return false;

   int added = 0;
   for(int i = 0; i < count; i++)
   {
      double spread = HistoricalSpreadPips(rates[index - 1 - i], point, pip_size);
      if(spread <= 0.0)
         continue;
      g_hist_scratch[added] = spread;
      added++;
   }
   if(added < MIN_SPREAD_SAMPLES || !PrepareScratch(g_hist_scratch, added, HISTORICAL_SCRATCH_RESERVE))
      return false;

   median = MedianOfArray(g_hist_scratch, added);
   double mad = MedianAbsDeviationInto(g_mad_scratch, g_hist_scratch, added, median, HISTORICAL_SCRATCH_RESERVE);
   robust_z = RobustZ(current_spread_pips, median, mad);
   return true;
}

// Robust z of the current aggregated bar's tick volume against the previous
// aggregated bars, the historical stand-in for the live volume baseline.
bool HistoricalTickVolumeZ(HistoricalBar &bars[], const int bars_available, double &z)
{
   z = 0.0;
   int count = IntMin(HISTORICAL_VOLUME_BASELINE_BARS, bars_available - 1);
   if(count <= 10 || !PrepareScratch(g_hist_scratch, count, HISTORICAL_SCRATCH_RESERVE))
      return false;

   int added = 0;
   for(int bar = 1; bar <= count; bar++)
   {
      if(!bars[bar].valid)
         continue;
      g_hist_scratch[added] = bars[bar].volume;
      added++;
   }
   if(added <= 10 || !PrepareScratch(g_hist_scratch, added, HISTORICAL_SCRATCH_RESERVE))
      return false;

   double median = MedianOfArray(g_hist_scratch, added);
   double mad = MedianAbsDeviationInto(g_mad_scratch, g_hist_scratch, added, median, HISTORICAL_SCRATCH_RESERVE);
   z = RobustZ(bars[0].volume, median, mad);
   return true;
}

// Minute-scale speed z: the close move over `window_minutes` in pips per
// minute, against the distribution of the same window over the previous
// `lookback` minutes. Signed for DIR_UP. A proxy for the live second-scale
// windows, never comparable with them.
bool HistoricalSpeedZ(MqlRates &rates[],
                      const int index,
                      const int window_minutes,
                      const int lookback,
                      const double pip_size,
                      const double atr_pips,
                      double &z)
{
   z = 0.0;
   if(index <= window_minutes || pip_size <= 0.0)
      return false;

   int count = IntMin(lookback, index - window_minutes - 1);
   if(count <= 10 || !PrepareScratch(g_hist_scratch, count, HISTORICAL_SCRATCH_RESERVE))
      return false;

   int added = 0;
   for(int i = 0; i < count; i++)
   {
      int end_index = index - 1 - i;
      int start_index = end_index - window_minutes;
      // A pair spanning a gap is not a window of that length.
      if(rates[end_index].time - rates[start_index].time != (datetime)window_minutes * 60)
         continue;
      g_hist_scratch[added] = (rates[end_index].close - rates[start_index].close) / pip_size / (double)window_minutes;
      added++;
   }
   if(added <= 10 || !PrepareScratch(g_hist_scratch, added, HISTORICAL_SCRATCH_RESERVE))
      return false;

   int current_start = index - window_minutes;
   if(rates[index].time - rates[current_start].time != (datetime)window_minutes * 60)
      return false;
   double current = (rates[index].close - rates[current_start].close) / pip_size / (double)window_minutes;
   double median = MedianOfArray(g_hist_scratch, added);
   double mad = MedianAbsDeviationInto(g_mad_scratch, g_hist_scratch, added, median, HISTORICAL_SCRATCH_RESERVE);
   // The live floor is atr_pips/600 per second; per minute that is atr_pips/10.
   z = RobustZ(current, median, mad, MathMax(atr_pips / 10.0, 0.01));
   return true;
}

// Move of the last closed bar of `tf_seconds` at or before the boundary,
// against that timeframe's own ATR, signed for DIR_UP. Mirrors the live
// closed-bar M5/M15 context.
bool HistoricalContextMove(MqlRates &rates[],
                           const int copied,
                           const datetime close_time,
                           const int tf_seconds,
                           double &move_atr)
{
   move_atr = 0.0;
   datetime grid_close = close_time - (close_time % tf_seconds);
   HistoricalBar bar_last;
   HistoricalBar bar_previous;
   if(!AggregateHistoricalBarAt(rates, copied, grid_close, tf_seconds, 0, bar_last) ||
      !AggregateHistoricalBarAt(rates, copied, grid_close, tf_seconds, 1, bar_previous))
   {
      return false;
   }

   double total = 0.0;
   int counted = 0;
   HistoricalBar bar;
   HistoricalBar older;
   for(int k = 1; k <= ATRPeriod; k++)
   {
      if(!AggregateHistoricalBarAt(rates, copied, grid_close, tf_seconds, k, bar) ||
         !AggregateHistoricalBarAt(rates, copied, grid_close, tf_seconds, k + 1, older))
      {
         break;
      }
      total += Max3(bar.high - bar.low, MathAbs(bar.high - older.close), MathAbs(bar.low - older.close));
      counted++;
   }
   if(counted < ATRPeriod / 2 || total <= 0.0)
      return false;

   double atr = total / (double)counted;
   move_atr = (bar_last.close - bar_previous.close) / atr;
   return true;
}

// Everything a boundary offers that no candidate parameter changes.
bool BuildHistoricalBoundaryFeatures(const int profile_index,
                                     MqlRates &rates[],
                                     const int copied,
                                     const int index,
                                     const int tf_minutes,
                                     const double symbol_spread_pips,
                                     HistoricalBar &bars[],
                                     const int bars_needed,
                                     HistoricalBoundaryFeatures &features)
{
   features.valid = false;
   features.close_time = rates[index].time + 60;
   int tf_seconds = tf_minutes * 60;

   for(int bar = 0; bar < bars_needed; bar++)
   {
      if(!AggregateHistoricalBarAt(rates, copied, features.close_time, tf_seconds, bar, bars[bar]))
      {
         // The current bar and the ATR window are mandatory; deeper bars only
         // matter to a range lookback that reaches them.
         if(bar <= ATRPeriod + 1)
            return false;
      }
   }

   features.atr = HistoricalATRFromBars(bars, bars_needed, ATRPeriod);
   if(features.atr <= 0.0)
      return false;

   double pip_size = g_profiles[profile_index].pip_size;
   double point = g_profiles[profile_index].point;
   if(pip_size <= 0.0 || point <= 0.0)
      return false;
   features.atr_pips = MathMax(features.atr / pip_size, 0.1);
   features.pip_size = pip_size;
   features.point = point;

   double bar_spread_pips = HistoricalSpreadPips(rates[index], point, pip_size);
   features.median_available = HistoricalSpreadStatistics(rates, index, point, pip_size,
                                                          HISTORICAL_SPREAD_BASELINE_MINUTES,
                                                          bar_spread_pips,
                                                          features.median_spread_pips,
                                                          features.spread_z);
   if(bar_spread_pips > 0.0)
   {
      features.spread_pips = bar_spread_pips;
      features.spread_source = HISTORICAL_SPREAD_BAR;
   }
   else if(features.median_available)
   {
      features.spread_pips = features.median_spread_pips;
      features.spread_source = HISTORICAL_SPREAD_MEDIAN;
   }
   else if(symbol_spread_pips > 0.0)
   {
      features.spread_pips = symbol_spread_pips;
      features.spread_source = HISTORICAL_SPREAD_SYMBOL;
   }
   else
   {
      features.spread_pips = 0.0;
      features.spread_source = HISTORICAL_SPREAD_NONE;
   }
   features.spread_price = features.spread_pips * pip_size;
   // The robust z compares the bar's own spread with the window; a stand-in
   // spread has no z of its own.
   features.spread_z_available = (features.median_available && features.spread_source == HISTORICAL_SPREAD_BAR);
   if(!features.spread_z_available)
      features.spread_z = 0.0;
   features.spread_ratio = (features.median_available && features.median_spread_pips > 0.0 ?
                            features.spread_pips / features.median_spread_pips : 0.0);
   features.cost_to_atr = SafeDiv(features.spread_price, features.atr, 999.0);
   features.rollover = (IgnoreRolloverTime && IsRolloverTime(features.close_time));
   features.session_score = SessionQualityScore(features.close_time);

   for(int window = 0; window < SPEED_WINDOW_COUNT; window++)
   {
      int minutes = g_speed_window_seconds[window];
      int lookback = (minutes >= 30 ? 160 : 120);
      features.speed_ready[window] = HistoricalSpeedZ(rates, index, minutes, lookback, pip_size,
                                                      features.atr_pips, features.speed_z_up[window]);
   }

   int index5 = HistoricalIndexAtOrBefore(rates, copied, rates[index].time - 300);
   int index30 = HistoricalIndexAtOrBefore(rates, copied, rates[index].time - 1800);
   double move5_pips = (index5 >= 0 ? (rates[index].close - rates[index5].close) / pip_size : 0.0);
   double move30_pips = (index30 >= 0 ? (rates[index].close - rates[index30].close) / pip_size : 0.0);
   // A window that does not exist is unmeasured, not zero: the blend must drop
   // the term's weight rather than fold a neutral 0 in. Without these flags the
   // historical validator forced both weights on, which is why its scores were
   // not comparable with the live scanner's on thin history.
   features.continuation_available = (index5 >= 0);
   features.acceleration_available = (index5 >= 0 && index30 >= 0);
   features.move5_atr_up = (features.continuation_available ? move5_pips / features.atr_pips : 0.0);
   features.acceleration_up = (features.acceleration_available ?
                               (move5_pips / 5.0 - move30_pips / 30.0) / features.atr_pips : 0.0);

   features.tick_volume_available = HistoricalTickVolumeZ(bars, bars_needed, features.tick_volume_z);
   features.m5_available = HistoricalContextMove(rates, copied, features.close_time, 300, features.m5_move_up);
   features.m15_available = HistoricalContextMove(rates, copied, features.close_time, 900, features.m15_move_up);

   features.valid = true;
   return true;
}

// Scores one direction at a boundary through the shared composer.
void ScoreHistoricalBoundary(const HistoricalBoundaryFeatures &features,
                             const HistoricalBar &bar,
                             const double range_high,
                             const double range_low,
                             const int direction,
                             const HistoricalParams &params,
                             HistoricalSignalScore &result)
{
   ResetHistoricalSignalScore(result, direction);
   result.atr_price = features.atr;
   result.spread_price = features.spread_price;

   CompositeSignalScore score;
   ResetCompositeSignalScore(score);

   // Execution: the live gates on the spread terms bar data can measure.
   score.execution.spread_pips = features.spread_pips;
   score.execution.median_available = features.median_available;
   score.execution.median_spread_pips = features.median_spread_pips;
   score.execution.spread_ratio = features.spread_ratio;
   score.execution.spread_z_available = features.spread_z_available;
   score.execution.spread_z = features.spread_z;
   score.execution.cost_to_atr = features.cost_to_atr;
   if(features.rollover ||
      ExecutionSpreadBlock(score.execution, params.max_spread_to_atr, UseStrictExecutionGate) != BLOCK_NONE)
   {
      return;
   }
   score.execution.score = BlendExecutionScore(score.execution, params.max_spread_to_atr, false);
   score.execution.pass = true;

   double range_width = range_high - range_low;
   if(range_width <= 0.0)
      return;

   double buffer = Max3(features.spread_price * 1.20,
                        features.atr * params.breakout_buffer_atr,
                        params.min_breakout_buffer_pips * features.pip_size);
   double boundary = (direction == DIR_UP ? range_high + buffer : range_low - buffer);
   double distance = (direction == DIR_UP ? bar.close - boundary : boundary - bar.close);

   // Breakout: the bar closed outside the box, so the price has held outside
   // for at least the minute the close represents; sub-minute hold is not
   // resolvable in history and no re-entry is tracked.
   if(UseTechnicalBreakoutEngine)
   {
      ComputeBreakoutStructure(direction, features.atr, range_width, distance,
                               MathMax(buffer, features.point), params.max_overextension_atr,
                               bar.open, bar.high, bar.low, bar.close,
                               (distance > 0.0 ? 60.0 : -1.0), -1.0, score.breakout);
   }

   // Impulse: minute-scale proxies with their own threshold.
   if(UseImpulseBreakoutEngine)
   {
      double speed_max = -999.0;
      bool any_window = false;
      for(int window = 0; window < SPEED_WINDOW_COUNT; window++)
      {
         if(!features.speed_ready[window])
            continue;
         double z = features.speed_z_up[window] * (double)direction;
         if(window == 0)
            score.impulse.speed_5s_z = z;
         else if(window == 1)
            score.impulse.speed_10s_z = z;
         else
            score.impulse.speed_30s_z = z;
         speed_max = MathMax(speed_max, z);
         any_window = true;
      }
      if(any_window)
      {
         score.impulse.measured = true;
         double speed_score = Clamp01(ScoreFromZ(speed_max, params.minute_impulse_z, params.minute_impulse_z + 2.75));
         score.impulse.acceleration_score = SmoothStep(0.0, HISTORICAL_ACCELERATION_FULL_ATR_PER_MINUTE,
                                                       features.acceleration_up * (double)direction);
         double directional_range = (direction == DIR_UP ? bar.high - bar.open : bar.open - bar.low);
         score.impulse.atr_expansion_score = SmoothStep(0.20, 1.25, SafeDiv(directional_range, features.atr, 0.0));
         score.impulse.tick_volume_available = features.tick_volume_available;
         score.impulse.tick_volume_z = features.tick_volume_z;
         double move5 = features.move5_atr_up * (double)direction;
         double continuation = SmoothStep(0.0, 0.80, move5);
         score.impulse.exhaustion_penalty = SmoothStep(MaxExhaustionAtr, MaxExhaustionAtr * 1.70, move5);
         BlendImpulseScore(score.impulse, speed_score,
                           features.acceleration_available, features.continuation_available, continuation);
         score.impulse.pass = (speed_max >= params.minute_impulse_z || score.impulse.atr_expansion_score >= 0.45);
      }
   }

   if(!score.breakout.measured && !score.impulse.measured)
      return;
   bool engine_pass = ((UseTechnicalBreakoutEngine && score.breakout.pass) ||
                       (UseImpulseBreakoutEngine && score.impulse.pass));
   if(!engine_pass)
      return;

   // Flow and calendar are unavailable in history and leave the blend; the
   // composer applies the same caps a live instance without them would get.
   ComposeRegimeScore(score.regime, features.session_score,
                      features.m5_available, features.m5_move_up * (double)direction,
                      features.m15_available, features.m15_move_up * (double)direction,
                      range_width / features.atr);

   CompositeContext context;
   context.direction = direction;
   context.m5_move_directional = features.m5_move_up * (double)direction;
   context.m15_move_directional = features.m15_move_up * (double)direction;
   context.age_seconds = 0;
   context.age_limit_seconds = 0;
   context.max_spread_to_atr = params.max_spread_to_atr;
   ComposeSignalScore(score, context, false);

   result.valid = score.valid;
   result.displayed_score = score.displayed_score;
}

void ResetHistoricalSignalScore(HistoricalSignalScore &score, const int direction)
{
   score.valid = false;
   score.direction = direction;
   score.displayed_score = 0.0;
   score.atr_price = 0.0;
   score.spread_price = 0.0;
}

// Outcome at the three horizons. Entry pays the spread: a long enters at the
// ask (close + spread) and is measured against bid highs and lows; a short
// enters at the bid and its target and stop are measured against the ask.
void EvaluateHistoricalOutcome(MqlRates &rates[],
                               const int copied,
                               const int signal_index,
                               const int direction,
                               const double close,
                               const double spread_price,
                               const double atr_price,
                               HistoricalOutcome &outcome)
{
   ResetHistoricalOutcome(outcome);
   bool ok1 = EvaluateHistoricalOutcomeAtHorizon(rates, copied, signal_index, direction, close, spread_price,
                                                 atr_price, OutcomeHorizonMinutes1,
                                                 outcome.result_5m_R, outcome.target_5m, outcome.stop_5m);
   bool ok2 = EvaluateHistoricalOutcomeAtHorizon(rates, copied, signal_index, direction, close, spread_price,
                                                 atr_price, OutcomeHorizonMinutes2,
                                                 outcome.result_15m_R, outcome.target_15m, outcome.stop_15m);
   bool ok3 = EvaluateHistoricalOutcomeAtHorizon(rates, copied, signal_index, direction, close, spread_price,
                                                 atr_price, OutcomeHorizonMinutes3,
                                                 outcome.result_30m_R, outcome.target_30m, outcome.stop_30m);
   outcome.evaluable = (ok1 && ok2 && ok3);
}

void ResetHistoricalOutcome(HistoricalOutcome &outcome)
{
   outcome.evaluable = false;
   outcome.result_5m_R = 0.0;
   outcome.target_5m = false;
   outcome.stop_5m = false;
   outcome.result_15m_R = 0.0;
   outcome.target_15m = false;
   outcome.stop_15m = false;
   outcome.result_30m_R = 0.0;
   outcome.target_30m = false;
   outcome.stop_30m = false;
}

// Returns false when the horizon window is missing too many minutes to judge.
bool EvaluateHistoricalOutcomeAtHorizon(MqlRates &rates[],
                                        const int copied,
                                        const int signal_index,
                                        const int direction,
                                        const double close,
                                        const double spread_price,
                                        const double atr_price,
                                        const int horizon_minutes,
                                        double &result_R,
                                        bool &target_hit,
                                        bool &stop_hit)
{
   result_R = 0.0;
   target_hit = false;
   stop_hit = false;

   double target_price = atr_price * OutcomeTargetAtr;
   double stop_price = atr_price * OutcomeStopAtr;
   if(target_price <= 0.0 || stop_price <= 0.0)
      return false;

   datetime horizon_end = rates[signal_index].time + (datetime)horizon_minutes * 60;
   double entry = (direction == DIR_UP ? close + spread_price : close);

   // Coverage is judged over the whole window before the walk, because the
   // walk stops at the first target or stop and a decided outcome is always
   // evaluable however few minutes it took.
   int available_minutes = 0;
   for(int i = signal_index + 1; i < copied && rates[i].time <= horizon_end; i++)
      available_minutes++;
   if(available_minutes < IntMax(1, (int)MathCeil(HISTORICAL_MIN_BAR_COVERAGE * horizon_minutes)))
      return false;

   int last_index = signal_index;
   for(int i = signal_index + 1; i < copied && rates[i].time <= horizon_end; i++)
   {
      last_index = i;
      double favorable = 0.0;
      double adverse = 0.0;
      if(direction == DIR_UP)
      {
         favorable = rates[i].high - entry;
         adverse = entry - rates[i].low;
      }
      else
      {
         favorable = entry - (rates[i].low + spread_price);
         adverse = (rates[i].high + spread_price) - entry;
      }

      bool target_now = (favorable >= target_price);
      bool stop_now = (adverse >= stop_price);
      if(target_now && stop_now)
         stop_hit = true;   // pessimistic for same-minute ambiguity
      else if(target_now)
         target_hit = true;
      else if(stop_now)
         stop_hit = true;
      if(target_hit || stop_hit)
         break;
   }

   if(target_hit && !stop_hit)
      result_R = SafeDiv(target_price, stop_price, 0.0);
   else if(stop_hit && !target_hit)
      result_R = -1.0;
   else
   {
      double exit_price = (direction == DIR_UP ? rates[last_index].close : rates[last_index].close + spread_price);
      double close_move = DirectionalValue(exit_price - entry, direction);
      result_R = Clamp(SafeDiv(close_move, stop_price, 0.0), -1.0,
                       SafeDiv(target_price, stop_price, 0.0));
   }
   return true;
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
   stats.from_time = 0;
   stats.to_time = 0;
   stats.symbols_requested = 0;
   stats.symbols_loaded = 0;
   stats.bars_loaded = 0;
   stats.profiles_tested = 0;
   stats.boundaries_total = 0;
   stats.boundary_stride_max = 0;
   stats.boundaries_rejected = 0;
   stats.bars_scanned = 0;
   stats.spread_from_bar = 0;
   stats.spread_from_median = 0;
   stats.spread_from_symbol = 0;
   stats.spread_unavailable = 0;
   stats.signals = 0;
   stats.signals_unevaluable = 0;
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

void AddHistoricalCoverageLines(const HistoricalBacktestStats &stats)
{
   double achieved_days = (stats.to_time > stats.from_time ? (double)(stats.to_time - stats.from_time) / 86400.0 : 0.0);
   AddHistoricalReportLine(StringFormat("Window: %s -> %s (%.1f of %d days) | Symbols %d/%d | Profiles with data=%d | M1 bars=%d",
                                        TimeToString(stats.from_time, TIME_DATE | TIME_MINUTES),
                                        TimeToString(stats.to_time, TIME_DATE | TIME_MINUTES),
                                        achieved_days,
                                        HistoricalLookbackDays,
                                        stats.symbols_loaded,
                                        stats.symbols_requested,
                                        stats.profiles_tested,
                                        stats.bars_loaded));
   AddHistoricalReportLine(StringFormat("Boundaries: evaluated %d of ~%d (up to 1 in %d) | rejected for gaps %d | signals unevaluable (gapped horizon) %d",
                                        stats.bars_scanned,
                                        stats.boundaries_total,
                                        IntMax(1, stats.boundary_stride_max),
                                        stats.boundaries_rejected,
                                        stats.signals_unevaluable));
   AddHistoricalReportLine(StringFormat("Spread source per boundary: bar column %d | window median %d | current symbol spread %d | none %d",
                                        stats.spread_from_bar,
                                        stats.spread_from_median,
                                        stats.spread_from_symbol,
                                        stats.spread_unavailable));
}

void AddHistoricalBucketLines(const string title, const HistoricalBacktestStats &stats)
{
   AddHistoricalReportLine(title);
   AddHistoricalReportLine(FormatHistoricalBucketLine("<65 ", stats.bucket60_count, stats.bucket60_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("65-69", stats.bucket65_count, stats.bucket65_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("70-74", stats.bucket70_count, stats.bucket70_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("75-79", stats.bucket75_count, stats.bucket75_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("80-84", stats.bucket80_count, stats.bucket80_R));
   AddHistoricalReportLine(FormatHistoricalBucketLine("85+  ", stats.bucket85_count, stats.bucket85_R));
}

string FormatHistoricalParams(const HistoricalParams &params)
{
   return StringFormat("range=%d bufferATR=%.2f minPips=%.1f minScore=%.1f spreadATR=%.2f overext=%.2f minuteImpulseZ=%.2f",
                       params.range_lookback,
                       params.breakout_buffer_atr,
                       params.min_breakout_buffer_pips,
                       params.min_confidence,
                       params.max_spread_to_atr,
                       params.max_overextension_atr,
                       params.minute_impulse_z);
}

void BuildValidationReport(const HistoricalBacktestStats &stats, const HistoricalParams &params)
{
   ClearHistoricalReport();
   AddHistoricalReportLine("FXNEWS VALIDATION REPORT | M1 HISTORY BACKTEST | NO FILE OUTPUT");
   AddHistoricalCoverageLines(stats);
   AddHistoricalReportLine("Params: " + FormatHistoricalParams(params) +
                           StringFormat(" | outcome target=%.2f stop=%.2f ATR", OutcomeTargetAtr, OutcomeStopAtr));
   AddHistoricalReportLine(StringFormat("Signals=%d | Avg score=%.1f | PF=%.2f | AvgR 5/15/30m = %.3f / %.3f / %.3f",
                                        stats.signals,
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
   AddHistoricalBucketLines("Buckets by displayed score: count | avg 30m R", stats);
   AddHistoricalReportLine("Model: the live composer over bar features; no basket, calendar or tick data, so scores are capped at 84 like a live instance without a basket reading. Minute-scale impulse windows use their own threshold.");
   AddHistoricalReportLine("Interpretation: score is a ranking metric. A useful score should show better R/PF in higher buckets.");
   PrintHistoricalReportToJournal();
   SetHistoricalReadyMessage("VALIDATION");
}

void BuildAutotuneReport(const HistoricalBacktestStats &default_stats,
                         const HistoricalBacktestStats &best_stats,
                         const HistoricalParams &default_params,
                         const HistoricalParams &best_params)
{
   ClearHistoricalReport();
   AddHistoricalReportLine("FXNEWS AUTOTUNE REPORT | M1 HISTORY BACKTEST | NO FILE OUTPUT");
   AddHistoricalCoverageLines(default_stats);
   AddHistoricalReportLine(StringFormat("All candidates share outcome target=%.2f stop=%.2f ATR", OutcomeTargetAtr, OutcomeStopAtr));
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
   bool recommend = HasSufficientAutotuneSample(best_stats);
   if(!recommend)
   {
      AddHistoricalReportLine(StringFormat("NO RECOMMENDATION: best candidate produced %d signals, below the "
                                           "AutotuneMinSignals floor of %d.",
                                           best_stats.signals,
                                           AutotuneMinSignals));
      AddHistoricalReportLine("Increase HistoricalLookbackDays or HistoricalMaxBoundariesPerProfile, widen the basket, "
                              "or lower MinDisplayConfidence until the sample clears the floor. Do not change settings on this run.");
   }
   else
   {
      // Only parameters whose meaning is identical in the live scanner are
      // offered as settings; the minute-scale impulse threshold is a proxy.
      AddHistoricalReportLine(StringFormat("Recommended settings: RangeLookbackM1=%d BreakoutBufferATR=%.2f MinBreakoutBufferPips=%.1f",
                                           best_params.range_lookback,
                                           best_params.breakout_buffer_atr,
                                           best_params.min_breakout_buffer_pips));
      AddHistoricalReportLine(StringFormat("Recommended settings: MinDisplayConfidence=%.1f MaxSpreadToAtrRatio=%.2f MaxOverextensionAtr=%.2f",
                                           best_params.min_confidence,
                                           best_params.max_spread_to_atr,
                                           best_params.max_overextension_atr));
      AddHistoricalReportLine(StringFormat("Historical-only proxy (not a live input): minute-scale impulse z=%.2f; "
                                           "MinImpulseZForSignal is measured on second-scale windows and must be derived separately.",
                                           best_params.minute_impulse_z));
   }
   AddHistoricalReportLine("Current settings baseline: " + FormatHistoricalParams(default_params));
   AddHistoricalBucketLines("Best score buckets: count | avg 30m R", best_stats);
   AddHistoricalReportLine(recommend ?
                           "Applied: no runtime change; review the recommendation with an external holdout before editing inputs." :
                           "Applied: no runtime change; no recommendation was produced.");

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
   if(stats.gross_win_R <= 0.0)
      return 0.0;
   // A finite prior prevents a loss-free small sample from dominating the objective.
   return Clamp(stats.gross_win_R / (stats.gross_loss_R + 1.0), 0.0, 5.0);
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

// A boundary is the close of a scan-timeframe bar: the M1 close time falls on
// the timeframe grid (server time, days on midnight). Integer arithmetic; the
// previous TimeToStruct call ran once per M1 bar per profile.
bool IsHistoricalEvaluationBoundary(const datetime close_time, const int tf_minutes)
{
   if(tf_minutes <= 1)
      return true;
   long grid = (tf_minutes >= 1440 ? 86400 : (long)tf_minutes * 60);
   return (((long)close_time % grid) == 0);
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
   AddHistoricalReportLine("No live scan | Journal report when done");
   UpdateHistoricalReportDashboard();
}

void ClearHistoricalReport()
{
   if(ArrayResize(g_historical_report_lines, 0) != 0)
      Print("FXNews: unable to clear historical report buffer.");
}

// The buffer is unbounded so the Journal always receives the full report; only
// the chart rendering is limited to the dashboard row budget.
void AddHistoricalReportLine(const string line)
{
   int next = ArraySize(g_historical_report_lines);
   if(ArrayResize(g_historical_report_lines, next + 1) != next + 1)
      return;
   g_historical_report_lines[next] = line;
}

void PrintHistoricalReportToJournal()
{
   int rows = ArraySize(g_historical_report_lines);
   for(int row = 0; row < rows; row++)
      PrintFormat("FXNews: %s", g_historical_report_lines[row]);
}

// Prepends the ready line and keeps the report itself on the chart below it;
// clearing the buffer here used to leave only a one-line pointer to the Journal.
void SetHistoricalReadyMessage(const string mode)
{
   int rows = ArraySize(g_historical_report_lines);
   if(ArrayResize(g_historical_report_lines, rows + 1) == rows + 1)
   {
      for(int row = rows; row > 0; row--)
         g_historical_report_lines[row] = g_historical_report_lines[row - 1];
      g_historical_report_lines[0] = "FXNews - " + mode + " ready | full report in MT5 Journal";
   }
   UpdateHistoricalReportDashboard();
}

// Report rows start at STATUS_ROW_INDEX like the live dashboard; row 0 stays
// empty as spacing in every mode.
void UpdateHistoricalReportDashboard()
{
   int lines = ArraySize(g_historical_report_lines);
   int row = STATUS_ROW_INDEX;
   string pieces[];
   for(int line = 0; line < lines && row < DASHBOARD_MAX_OBJECTS; line++)
   {
      string text = g_historical_report_lines[line];
      int count = WrapLabelText(text, pieces);
      for(int piece = 0; piece < count && row < DASHBOARD_MAX_OBJECTS; piece++)
      {
         SetDashboardRow(row, pieces[piece], text, (line == 0 ? StatusLineColor() : clrWhite));
         row++;
      }
   }
   DeleteDashboardRowsFrom(row);
   ChartRedraw(0);
}

int ParseSymbols()
{
   if(ArrayResize(g_profiles, 0) != 0)
   {
      Print("FXNews: unable to allocate the profile list.");
      return 0;
   }
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
      if(StringLen(token) > MAX_SYMBOL_TOKEN_LENGTH)
      {
         Print("FXNews: a symbol token exceeds the supported length.");
         return 0;
      }

      // Resolve broker aliases now so "EURUSD" and "EURUSD.m" cannot both
      // claim the same broker symbol and then fight over its profiles.
      string resolved = ResolveRequestedSymbol(token);
      bool already_known = SymbolListContains(symbols, resolved);
      if(already_known)
         continue;
      if(ArraySize(symbols) >= MAX_UNIQUE_SYMBOLS)
      {
         PrintFormat("FXNews: at most %d unique symbols are supported.", MAX_UNIQUE_SYMBOLS);
         return 0;
      }
      if(!AddUniqueSymbol(symbols, resolved))
      {
         Print("FXNews: unable to allocate the symbol list.");
         return 0;
      }
   }

   int profile_count = ArraySize(symbols) * ArraySize(g_scan_timeframes);
   if(profile_count <= 0)
   {
      Print("FXNews: no symbols were provided.");
      return 0;
   }

   if(ArrayResize(g_profiles, profile_count) != profile_count)
   {
      PrintFormat("FXNews: unable to allocate %d symbol/timeframe profiles.", profile_count);
      return 0;
   }

   int next = 0;
   for(int symbol_index = 0; symbol_index < ArraySize(symbols); symbol_index++)
   {
      for(int timeframe_index = 0; timeframe_index < ArraySize(g_scan_timeframes); timeframe_index++)
      {
         ResetProfile(g_profiles[next],
                      symbols[symbol_index],
                      g_scan_timeframes[timeframe_index],
                      g_scan_timeframe_labels[timeframe_index]);
         next++;
      }
   }

   return ArraySize(g_profiles);
}

int ParseTimeframes()
{
   if(ArrayResize(g_scan_timeframes, 0) != 0 || ArrayResize(g_scan_timeframe_labels, 0) != 0)
      return 0;

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
      // A typo such as "H2" must not silently shrink the scan.
      if(!ParseTimeframeToken(token, timeframe, label))
      {
         PrintFormat("FXNews: unsupported timeframe token '%s'. Supported: M1 M5 M15 M30 H1 H4 H8 H12 D1, "
                     "also as minutes or PERIOD_ names.", token);
         return 0;
      }

      if(TimeframeAlreadyAdded(timeframe))
         continue;

      int next = ArraySize(g_scan_timeframes);
      if(next >= MAX_SCAN_TIMEFRAMES || ArrayResize(g_scan_timeframes, next + 1) != next + 1 ||
         ArrayResize(g_scan_timeframe_labels, next + 1) != next + 1)
      {
         Print("FXNews: unable to add another scan timeframe.");
         return 0;
      }
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
   int next = ArraySize(symbols);
   if(ArrayResize(symbols, next + 1) != next + 1)
      return false;
   symbols[next] = symbol;
   return true;
}

bool SymbolListContains(string &symbols[], const string symbol)
{
   for(int i = 0; i < ArraySize(symbols); i++)
   {
      if(StringCompare(symbols[i], symbol, false) == 0)
         return true;
   }
   return false;
}

// The broker's name for a requested symbol: the name itself when it exists,
// else the closest catalogue match, else the request unchanged so the failure
// is reported against the name the user typed.
string ResolveRequestedSymbol(const string requested)
{
   if(SymbolInfoInteger(requested, SYMBOL_EXIST) != 0)
      return requested;

   string resolved = "";
   if(FindBrokerSymbolMatch(requested, resolved))
   {
      PrintFormat("FXNews: symbol %s is listed by the broker as %s.", requested, resolved);
      return resolved;
   }
   return requested;
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
   profile.unsupported = false;
   profile.broker_match_attempted = false;
   profile.next_symbol_retry_time = 0;
   profile.base_index = -1;
   profile.quote_index = -1;
   FindBaseQuoteCurrencies(symbol, profile.base_index, profile.quote_index);

   profile.point = 0.0;
   profile.pip_size = 0.0;
   profile.symbol_upper = UpperAscii(symbol);
   profile.is_first_profile_for_symbol = false;
   profile.symbol_leader_index = -1;
   profile.m1_atr_pips = 0.0;
   profile.basket_contribution = 0.0;
   profile.basket_weight = 0.0;

   profile.quote_fresh = false;
   profile.quote_time = 0;
   profile.quote_time_msc = 0;
   profile.bid = 0.0;
   profile.ask = 0.0;
   profile.mid = 0.0;
   profile.spread_pips = 0.0;
   profile.median_spread_pips = 0.0;
   profile.spread_z = 0.0;
   profile.tick_gap_sec = 0.0;
   profile.last_tick_interval_sec = 0.0;
   profile.quote_age_sec = 0.0;
   profile.spread_stats_ready = false;
   profile.tick_rate_available = false;
   profile.tick_rate_per_sec = 0.0;
   profile.session_spread_z = 0.0;
   profile.session_tick_rate_z = 0.0;
   profile.session_tick_volume_z = 0.0;
   profile.session_spread_z_ready = false;
   profile.session_tick_rate_z_ready = false;
   profile.session_tick_volume_z_ready = false;
   profile.session_index = SESSION_OTHER;
   profile.tick_quality_available = false;
   profile.tick_sample_quality_score = 0.0;
   profile.valid_ticks_used = 0;
   profile.tick_state = "TICK_SYNCING";
   profile.tick_quality_stamp_msc = 0;
   profile.last_market_update_scan = 0;

   profile.has_trigger = false;
   profile.has_m5 = false;
   profile.has_m15 = false;
   profile.atr_trigger = 0.0;
   profile.atr_m5 = 0.0;
   profile.range_high = 0.0;
   profile.range_low = 0.0;
   profile.range_width = 0.0;
   profile.range_anchor_bar_time = 0;
   profile.breakout_buffer_price = 0.0;

   profile.current_trigger_open = 0.0;
   profile.current_trigger_high = 0.0;
   profile.current_trigger_low = 0.0;
   profile.current_trigger_close = 0.0;
   profile.trigger_bar_time = 0;
   profile.active_trigger_tick_volume = 0.0;
   profile.average_trigger_tick_volume = 0.0;

   for(int window = 0; window < SPEED_WINDOW_COUNT; window++)
   {
      profile.speed_baseline_ready[window] = false;
      profile.speed_median_rate[window] = 0.0;
      profile.speed_mad_rate[window] = 0.0;
   }
   profile.snapshot_coverage_sec = 0;

   profile.speed_5s_pips = 0.0;
   profile.speed_10s_pips = 0.0;
   profile.speed_30s_pips = 0.0;
   profile.speed_60s_pips = 0.0;
   profile.movement_5m_pips = 0.0;
   profile.has_m5_move = false;
   profile.has_m15_move = false;
   profile.m5_move_atr = 0.0;
   profile.m15_move_atr = 0.0;

   profile.final_score_up = 0.0;
   profile.final_score_down = 0.0;
   ResetCompositeSignalScore(profile.composite_up);
   ResetCompositeSignalScore(profile.composite_down);

   profile.active_direction = DIR_NONE;
   profile.event_state = STATE_IDLE;
   profile.event_start_time = 0;
   profile.event_local_time = 0;
   profile.cooldown_end_up = 0;
   profile.cooldown_end_down = 0;
   profile.last_alert_attempt_time = 0;
   profile.alert_attempts = 0;
   profile.strong_alert_handled = false;
   profile.confidence_below_since = 0;
   profile.candidate_direction = DIR_NONE;
   profile.candidate_start_time = 0;
   profile.candidate_bar_time = 0;
   profile.pending_alert = false;
   profile.pending_strong_upgrade = false;

   profile.outside_since_up = 0;
   profile.outside_since_down = 0;
   profile.reentered_since_up = 0;
   profile.reentered_since_down = 0;
   profile.correlated_alert_group_id = "";
   profile.group_leader_signal = false;
   profile.group_member_count = 0;

   profile.snapshot_write_index = 0;
   profile.snapshot_count = 0;
   profile.spread_write_index = 0;
   profile.spread_count = 0;

   profile.status_message = "";
   profile.reported_status_message = "";
}

bool AllocateHistoryBuffers()
{
   int profile_count = ArraySize(g_profiles);
   if(profile_count <= 0 || profile_count > MAX_PROFILES)
      return false;

   int snapshots_required = profile_count * SNAPSHOT_CAPACITY;
   int spreads_required = profile_count * SPREAD_HISTORY_CAPACITY;
   int baselines_required = profile_count * SESSION_COUNT;
   if(ArrayResize(g_snapshots, snapshots_required) != snapshots_required ||
      ArrayResize(g_spread_history, spreads_required) != spreads_required ||
      ArrayResize(g_session_baselines, baselines_required) != baselines_required)
   {
      return false;
   }

   for(int i = 0; i < ArraySize(g_snapshots); i++)
   {
      g_snapshots[i].time_msc = 0;
      g_snapshots[i].mid = 0.0;
   }

   int scratch_reserve = IntMax(SNAPSHOT_CAPACITY, SPREAD_HISTORY_CAPACITY);
   if(ArrayResize(g_rate_scratch, SNAPSHOT_CAPACITY, SNAPSHOT_CAPACITY) != SNAPSHOT_CAPACITY ||
      ArrayResize(g_spread_scratch, SPREAD_HISTORY_CAPACITY, SPREAD_HISTORY_CAPACITY) != SPREAD_HISTORY_CAPACITY ||
      ArrayResize(g_mad_scratch, scratch_reserve, scratch_reserve) != scratch_reserve)
   {
      return false;
   }

   ArrayInitialize(g_spread_history, 0.0);
   ResetSessionBaselines();
   return true;
}

void ScanAll(const bool force_dashboard)
{
   uint scan_start = GetTickCount();
   g_scan_sequence++;
   datetime now = TimeCurrent();
   datetime wall_clock = ScanWallClock(now);
   bool connected = (TerminalInfoInteger(TERMINAL_CONNECTED) != 0);
   if(g_symbol_identity_dirty)
      RefreshSymbolIdentityCache();
   g_last_valid_symbols = 0;
   g_last_invalid_symbols = 0;
   g_last_tick_history_ok = 0;
   g_calendar_available = false;

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(IsStopped())
         return;
      if(UpdateMarketData(i, now, wall_clock, connected))
      {
         g_last_valid_symbols++;
         if(g_profiles[i].valid_ticks_used >= MinCopyTicksForGoodQuality)
            g_last_tick_history_ok++;
         ClearProfileStatus(i);
      }
      else
      {
         g_last_invalid_symbols++;
         ReportProfileStatus(i, now);
      }
   }

   CalculateCurrencyStrength();

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(IsStopped())
         return;
      CalculateScoresAndUpdateState(i, now);
   }

   UpdateAlertGroups(now);
   DispatchPendingAlerts(now);
   UpdateScanDiagnostics(scan_start);

   // A new recent-list entry is rendered on the scan it appears; waiting for
   // the display interval let a row's dwell start before it was ever visible.
   if(force_dashboard || g_signal_history_dirty || g_dashboard_needs_refit ||
      g_last_dashboard_update == 0 || now - g_last_dashboard_update >= DisplayUpdateSeconds)
   {
      UpdateDashboard();
      g_last_dashboard_update = now;
      g_dashboard_needs_refit = false;
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
   // The retry clock is local time: server time stops with the feed and would
   // freeze the retry timer on a weekend or during an outage.
   datetime now = TimeLocal();
   if(g_profiles[index].unsupported)
      return false;
   if(g_profiles[index].valid && g_profiles[index].selected)
      return true;
   if(g_profiles[index].next_symbol_retry_time > now)
      return false;

   string symbol = g_profiles[index].symbol;

   ResetLastError();
   if(!SymbolSelect(symbol, true))
   {
      int initial_error = GetLastError();
      string resolved_symbol = "";
      // The catalogue scan is expensive and its answer does not change, so it
      // runs once per profile; later retries only re-select the name.
      bool matched = false;
      if(!g_profiles[index].broker_match_attempted)
      {
         g_profiles[index].broker_match_attempted = true;
         matched = FindBrokerSymbolMatch(symbol, resolved_symbol);
      }
      if(!matched ||
         SymbolTimeframeUsedByAnotherProfile(index, resolved_symbol, g_profiles[index].scan_timeframe))
      {
         g_profiles[index].valid = false;
         g_profiles[index].selected = false;
         g_profiles[index].next_symbol_retry_time = now + 60;
         g_profiles[index].status_message = StringFormat("%s: SymbolSelect failed, error %d", symbol, initial_error);
         return false;
      }

      ResetLastError();
      if(!SymbolSelect(resolved_symbol, true))
      {
         g_profiles[index].valid = false;
         g_profiles[index].selected = false;
         g_profiles[index].next_symbol_retry_time = now + 60;
         g_profiles[index].status_message = StringFormat("%s: fallback SymbolSelect(%s) failed, error %d",
                                                         symbol, resolved_symbol, GetLastError());
         return false;
      }

      g_profiles[index].symbol = resolved_symbol;
      g_profiles[index].symbol_upper = UpperAscii(resolved_symbol);
      FindBaseQuoteCurrencies(resolved_symbol,
                              g_profiles[index].base_index,
                              g_profiles[index].quote_index);
      ClearProfileHistory(index);
      // The identity cache feeds the basket in this very scan, so it is
      // rebuilt immediately rather than at the start of the next one.
      RefreshSymbolIdentityCache();
      symbol = resolved_symbol;
   }

   if(SymbolTimeframeUsedByAnotherProfile(index, symbol, g_profiles[index].scan_timeframe))
   {
      g_profiles[index].valid = false;
      g_profiles[index].selected = false;
      g_profiles[index].next_symbol_retry_time = now + 60;
      g_profiles[index].status_message = StringFormat("%s %s: duplicate resolved scan profile.",
                                                      symbol, g_profiles[index].timeframe_label);
      return false;
   }

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(point <= 0.0 || digits < 0)
   {
      g_profiles[index].valid = false;
      g_profiles[index].selected = false;
      g_profiles[index].next_symbol_retry_time = now + 60;
      g_profiles[index].status_message = symbol + ": invalid symbol point or digits.";
      return false;
   }

   // Pip size, spread limits and the basket all assume an FX pair of the
   // eight basket currencies; anything else would run with pips equal to
   // points and sit permanently behind the spread gate.
   if(g_profiles[index].base_index < 0 || g_profiles[index].quote_index < 0)
   {
      g_profiles[index].valid = false;
      g_profiles[index].selected = false;
      g_profiles[index].unsupported = true;
      g_profiles[index].status_message = symbol + ": not an FX pair of EUR USD GBP JPY CHF AUD NZD CAD, skipped.";
      return false;
   }

   g_profiles[index].point = point;
   g_profiles[index].pip_size = PipSize(point, digits);
   g_profiles[index].valid = true;
   g_profiles[index].selected = true;
   g_profiles[index].next_symbol_retry_time = 0;
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
      if(g_profiles[i].symbol_upper == target &&
         g_profiles[i].scan_timeframe == timeframe &&
         g_profiles[i].selected)
      {
         return true;
      }
   }
   return false;
}

// Rebuilt only when a symbol is resolved or rewritten, rather than being
// recomputed inside every scoring loop.
void RefreshSymbolIdentityCache()
{
   int total = ArraySize(g_profiles);
   for(int i = 0; i < total; i++)
   {
      g_profiles[i].symbol_upper = UpperAscii(g_profiles[i].symbol);
      g_profiles[i].is_first_profile_for_symbol = true;
      g_profiles[i].symbol_leader_index = i;
   }

   for(int i = 0; i < total; i++)
   {
      if(!g_profiles[i].is_first_profile_for_symbol)
         continue;
      for(int j = i + 1; j < total; j++)
      {
         if(g_profiles[j].symbol_upper == g_profiles[i].symbol_upper)
         {
            g_profiles[j].is_first_profile_for_symbol = false;
            g_profiles[j].symbol_leader_index = i;
         }
      }
   }

   g_symbol_identity_dirty = false;
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
   g_profiles[index].snapshot_coverage_sec = 0;
   g_profiles[index].spread_stats_ready = false;
   g_profiles[index].median_spread_pips = 0.0;
   g_profiles[index].spread_z = 0.0;
   g_profiles[index].last_tick_interval_sec = 0.0;
   g_profiles[index].tick_rate_available = false;
   g_profiles[index].tick_rate_per_sec = 0.0;
   g_profiles[index].tick_quality_available = false;
   g_profiles[index].tick_sample_quality_score = 0.0;
   g_profiles[index].valid_ticks_used = 0;
   g_profiles[index].tick_quality_stamp_msc = 0;
   for(int window = 0; window < SPEED_WINDOW_COUNT; window++)
   {
      g_profiles[index].speed_baseline_ready[window] = false;
      g_profiles[index].speed_median_rate[window] = 0.0;
      g_profiles[index].speed_mad_rate[window] = 0.0;
   }

   // The session baselines belong to the symbol the profile used to track.
   for(int session = 0; session < SESSION_COUNT; session++)
   {
      int baseline_index = BaselineIndex(index, session);
      if(baseline_index < 0 || baseline_index >= ArraySize(g_session_baselines))
         continue;
      g_session_baselines[baseline_index].spread_samples = 0;
      g_session_baselines[baseline_index].tick_rate_samples = 0;
      g_session_baselines[baseline_index].tick_volume_samples = 0;
      g_session_baselines[baseline_index].spread_mean = 0.0;
      g_session_baselines[baseline_index].spread_var = 0.0;
      g_session_baselines[baseline_index].tick_rate_mean = 0.0;
      g_session_baselines[baseline_index].tick_rate_var = 0.0;
      g_session_baselines[baseline_index].tick_volume_mean = 0.0;
      g_session_baselines[baseline_index].tick_volume_var = 0.0;
   }
   g_profiles[index].session_spread_z_ready = false;
   g_profiles[index].session_tick_rate_z_ready = false;
   g_profiles[index].session_tick_volume_z_ready = false;
   g_profiles[index].session_spread_z = 0.0;
   g_profiles[index].session_tick_rate_z = 0.0;
   g_profiles[index].session_tick_volume_z = 0.0;
}

// TimeCurrent() is the time of the last tick received on any symbol and stops
// with the feed, so quote freshness is judged against the trade-server clock,
// which keeps advancing, and against the connection state.
datetime ScanWallClock(const datetime now)
{
   datetime server_clock = TimeTradeServer();
   return (server_clock > now ? server_clock : now);
}

bool UpdateMarketData(const int index, const datetime now, const datetime wall_clock, const bool connected)
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
      // The symbol may have been removed from Market Watch; re-select it on
      // the next scan instead of failing here forever.
      g_profiles[index].selected = false;
      g_profiles[index].status_message = StringFormat("%s: SymbolInfoTick failed, error %d",
                                                      g_profiles[index].symbol, GetLastError());
      return false;
   }

   if(!MathIsValidNumber(tick.bid) || !MathIsValidNumber(tick.ask) ||
      tick.bid <= 0.0 || tick.ask <= 0.0 || tick.ask < tick.bid || tick.time <= 0)
   {
      ClearRuntimeMarketFlags(index);
      g_profiles[index].status_message = g_profiles[index].symbol + ": invalid quote.";
      return false;
   }

   g_profiles[index].quote_time = tick.time;
   g_profiles[index].quote_time_msc = (long)tick.time_msc;
   if(g_profiles[index].quote_time_msc <= 0)
      g_profiles[index].quote_time_msc = (long)tick.time * 1000;

   // TickGapSeconds is positive only when this tick is newer than the last
   // stored snapshot; on a scan without a new tick it reads zero, which used to
   // make a stalled feed look perfectly gap-free. Keep the last real interval
   // and let the current quote age dominate while nothing arrives.
   double tick_interval = TickGapSeconds(index, g_profiles[index].quote_time_msc);
   if(tick_interval > 0.0)
      g_profiles[index].last_tick_interval_sec = tick_interval;
   g_profiles[index].quote_age_sec = (double)MathMax(0, (int)(wall_clock - tick.time));
   g_profiles[index].tick_gap_sec = MathMax(g_profiles[index].last_tick_interval_sec,
                                            g_profiles[index].quote_age_sec);

   g_profiles[index].quote_fresh = (connected && g_profiles[index].quote_age_sec <= MaxQuoteAgeSeconds);
   g_profiles[index].session_index = SessionIndex(now);
   g_profiles[index].bid = tick.bid;
   g_profiles[index].ask = tick.ask;
   g_profiles[index].mid = (tick.bid + tick.ask) * 0.5;
   g_profiles[index].spread_pips = (tick.ask - tick.bid) / g_profiles[index].pip_size;

   bool new_quote_sample = AddSnapshot(index, g_profiles[index].quote_time_msc, g_profiles[index].mid);
   if(new_quote_sample)
   {
      // The rings only change with a new sample, so their statistics are
      // exactly reusable on every scan in between.
      AddSpreadSample(index, g_profiles[index].spread_pips);
      UpdateSpreadStatistics(index);
      g_profiles[index].snapshot_coverage_sec = SnapshotCoverageSeconds(index);

      // The snapshot-derived rate counts scan samples and is a coarse fallback;
      // UpdateTickQuality replaces it with the true tick rate when CopyTicks
      // delivers a usable window.
      double snapshot_rate = 0.0;
      g_profiles[index].tick_rate_available = TickRateFromSnapshots(index, 30, snapshot_rate);
      g_profiles[index].tick_rate_per_sec = (g_profiles[index].tick_rate_available ? snapshot_rate : 0.0);
      UpdateSnapshotRateStats(index);
   }
   UpdateTickQuality(index);

   UpdateRatesData(index);
   UpdateMovementData(index);
   UpdateOutsideTimers(index, now);
   if(new_quote_sample)
      UpdateSessionBaseline(index);

   g_profiles[index].last_market_update_scan = g_scan_sequence;
   return true;
}

// A profile can fail for seven different reasons and every one of them was being
// written to status_message and discarded. Print each distinct message once so a
// broker naming mismatch or a dead feed is visible in the Journal instead of only
// moving the aggregate "bad" counter.
void ReportProfileStatus(const int index, const datetime now)
{
   string message = g_profiles[index].status_message;
   if(message == "" || message == g_profiles[index].reported_status_message)
      return;
   if(!DebugLogAllowed(now))
      return;

   g_profiles[index].reported_status_message = message;
   PrintFormat("FXNews profile %s %s: %s",
               g_profiles[index].symbol,
               g_profiles[index].timeframe_label,
               message);
}

void ClearProfileStatus(const int index)
{
   g_profiles[index].status_message = "";
   g_profiles[index].reported_status_message = "";
}

// First unresolved profile, surfaced on the status-row tooltip.
string FirstProfileStatusMessage()
{
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(g_profiles[i].status_message != "")
         return g_profiles[i].status_message;
   }
   return "";
}

void ClearRuntimeMarketFlags(const int index)
{
   g_profiles[index].quote_fresh = false;
   g_profiles[index].has_trigger = false;
   g_profiles[index].has_m5 = false;
   g_profiles[index].has_m15 = false;
   g_profiles[index].tick_gap_sec = 0.0;
   g_profiles[index].tick_rate_available = false;
   g_profiles[index].tick_rate_per_sec = 0.0;
   g_profiles[index].tick_quality_available = false;
   g_profiles[index].tick_sample_quality_score = 0.0;
   g_profiles[index].valid_ticks_used = 0;
   g_profiles[index].tick_state = "TICK_STALE";
   g_profiles[index].tick_quality_stamp_msc = 0;
}

// Rates are copied into module-level arrays: the profile count is fixed after
// initialisation and a fresh dynamic array per call re-allocated up to five
// buffers per profile per scan.
void UpdateRatesData(const int index)
{
   string symbol = g_profiles[index].symbol;
   int need_trigger = IntMax(RangeLookbackM1 + ATRPeriod + 20, 80);
   int min_trigger = IntMax(RangeLookbackM1 + 2, ATRPeriod + 3);

   ArraySetAsSeries(g_rates_trigger, true);
   ResetLastError();
   int copied_trigger = CopyRates(symbol, g_profiles[index].scan_timeframe, 0, need_trigger, g_rates_trigger);
   g_profiles[index].has_trigger = (copied_trigger >= min_trigger);

   if(g_profiles[index].has_trigger)
   {
      g_profiles[index].atr_trigger = CalculateATRFromRates(g_rates_trigger, copied_trigger, ATRPeriod);
      BuildRangeBox(index, g_rates_trigger, copied_trigger);
      g_profiles[index].current_trigger_open = g_rates_trigger[0].open;
      g_profiles[index].current_trigger_high = g_rates_trigger[0].high;
      g_profiles[index].current_trigger_low = g_rates_trigger[0].low;
      g_profiles[index].current_trigger_close = g_rates_trigger[0].close;
      g_profiles[index].trigger_bar_time = g_rates_trigger[0].time;
      g_profiles[index].average_trigger_tick_volume = AverageTickVolume(g_rates_trigger, copied_trigger);

      // The forming bar's count is projected to a full bar once enough of it
      // has elapsed; earlier the last completed bar stands in. Comparing the
      // raw partial count with completed bars sagged at every bar open.
      double current_volume = (double)g_rates_trigger[0].tick_volume;
      double completed_volume = (double)g_rates_trigger[1].tick_volume;
      double bar_seconds = (double)TimeframeMinutes(g_profiles[index].scan_timeframe) * 60.0;
      double elapsed = (double)(g_profiles[index].quote_time - g_rates_trigger[0].time);
      double fraction = (bar_seconds > 0.0 ? Clamp(elapsed / bar_seconds, 0.0, 1.0) : 0.0);
      g_profiles[index].active_trigger_tick_volume = (fraction >= TICK_VOLUME_PROJECTION_MIN_FRACTION ?
                                                     current_volume / fraction : completed_volume);
   }
   else
   {
      g_profiles[index].atr_trigger = 0.0;
      g_profiles[index].range_high = 0.0;
      g_profiles[index].range_low = 0.0;
      g_profiles[index].range_width = 0.0;
      g_profiles[index].range_anchor_bar_time = 0;
      g_profiles[index].trigger_bar_time = 0;
   }

   // Context data is shared by every timeframe of a symbol: the first profile
   // copies it and the others take it over within the same scan.
   int context_source = FindFreshContextProfile(index);
   if(context_source >= 0)
   {
      CopyContextRatesData(index, context_source);
      g_profiles[index].m1_atr_pips = 0.0;   // the basket reads a symbol's first profile only
      return;
   }

   // One M1 copy serves both the five-minute movement and the basket ATR.
   ArraySetAsSeries(g_rates_m1, true);
   ResetLastError();
   int need_m1 = IntMax(ATRPeriod + 10, 40);
   int copied_m1 = CopyRates(symbol, PERIOD_M1, 0, need_m1, g_rates_m1);
   if(copied_m1 > 5)
      g_profiles[index].movement_5m_pips = (g_profiles[index].mid - g_rates_m1[5].close) / g_profiles[index].pip_size;
   else
      g_profiles[index].movement_5m_pips = 0.0;

   g_profiles[index].m1_atr_pips = 0.0;
   if(g_profiles[index].is_first_profile_for_symbol && g_profiles[index].pip_size > 0.0)
   {
      if(g_profiles[index].scan_timeframe == PERIOD_M1)
      {
         // Free when M1 is already the scan timeframe for this profile.
         g_profiles[index].m1_atr_pips = (g_profiles[index].has_trigger ?
                                          SafeDiv(g_profiles[index].atr_trigger, g_profiles[index].pip_size, 0.0) : 0.0);
      }
      else if(copied_m1 >= ATRPeriod + 3)
      {
         g_profiles[index].m1_atr_pips = SafeDiv(CalculateATRFromRates(g_rates_m1, copied_m1, ATRPeriod),
                                                 g_profiles[index].pip_size, 0.0);
      }
   }

   // Context is the last CLOSED bar's move against that timeframe's ATR. The
   // forming bar's move reset to zero at every bar open and sawtoothed the
   // regime score on a five/fifteen-minute cycle. A zero ATR leaves the reading
   // unmeasured instead of scoring as a neutral constant.
   ArraySetAsSeries(g_rates_m5, true);
   int need_m5 = IntMax(ATRPeriod + 10, 40);
   ResetLastError();
   int copied_m5 = CopyRates(symbol, PERIOD_M5, 0, need_m5, g_rates_m5);
   g_profiles[index].has_m5 = (copied_m5 >= ATRPeriod + 3);
   g_profiles[index].atr_m5 = 0.0;
   g_profiles[index].has_m5_move = false;
   g_profiles[index].m5_move_atr = 0.0;
   if(g_profiles[index].has_m5)
   {
      g_profiles[index].atr_m5 = CalculateATRFromRates(g_rates_m5, copied_m5, ATRPeriod);
      if(g_profiles[index].atr_m5 > 0.0)
      {
         g_profiles[index].has_m5_move = true;
         g_profiles[index].m5_move_atr = (g_rates_m5[1].close - g_rates_m5[2].close) / g_profiles[index].atr_m5;
      }
   }

   ArraySetAsSeries(g_rates_m15, true);
   int need_m15 = IntMax(ATRPeriod + 10, 40);
   ResetLastError();
   int copied_m15 = CopyRates(symbol, PERIOD_M15, 0, need_m15, g_rates_m15);
   g_profiles[index].has_m15 = (copied_m15 >= ATRPeriod + 3);
   g_profiles[index].has_m15_move = false;
   g_profiles[index].m15_move_atr = 0.0;
   if(g_profiles[index].has_m15)
   {
      double atr_m15 = CalculateATRFromRates(g_rates_m15, copied_m15, ATRPeriod);
      if(atr_m15 > 0.0)
      {
         g_profiles[index].has_m15_move = true;
         g_profiles[index].m15_move_atr = (g_rates_m15[1].close - g_rates_m15[2].close) / atr_m15;
      }
   }
}

// The basket normalises wall-clock moves (30s, 60s, 5m), so it needs an ATR on a
// wall-clock timeframe. Reading the trigger ATR here made basket strength depend
// on whichever timeframe happened to be listed first in TimeframesToScan.
int FindFreshContextProfile(const int index)
{
   string symbol = g_profiles[index].symbol_upper;
   long quote_time_msc = g_profiles[index].quote_time_msc;
   if(quote_time_msc <= 0)
      return -1;

   for(int i = index - 1; i >= 0; i--)
   {
      if(g_profiles[i].symbol_upper != symbol)
         continue;
      // The sibling must have completed its update in this very scan; a
      // profile that failed this scan still carries last scan's quote time.
      if(g_profiles[i].quote_time_msc != quote_time_msc ||
         g_profiles[i].last_market_update_scan != g_scan_sequence)
      {
         continue;
      }
      return i;
   }

   return -1;
}

void CopyContextRatesData(const int target_index, const int source_index)
{
   g_profiles[target_index].movement_5m_pips = g_profiles[source_index].movement_5m_pips;
   g_profiles[target_index].has_m5 = g_profiles[source_index].has_m5;
   g_profiles[target_index].atr_m5 = g_profiles[source_index].atr_m5;
   g_profiles[target_index].has_m5_move = g_profiles[source_index].has_m5_move;
   g_profiles[target_index].m5_move_atr = g_profiles[source_index].m5_move_atr;
   g_profiles[target_index].has_m15 = g_profiles[source_index].has_m15;
   g_profiles[target_index].has_m15_move = g_profiles[source_index].has_m15_move;
   g_profiles[target_index].m15_move_atr = g_profiles[source_index].m15_move_atr;
}

void BuildRangeBox(const int index, MqlRates &rates[], const int copied)
{
   int usable = IntMin(RangeLookbackM1, copied - 1);
   if(usable < RangeLookbackM1)
   {
      g_profiles[index].has_trigger = false;
      g_profiles[index].range_high = 0.0;
      g_profiles[index].range_low = 0.0;
      g_profiles[index].range_width = 0.0;
      g_profiles[index].range_anchor_bar_time = 0;
      return;
   }

   // While a candidate or confirmed event is live the box stays anchored on the
   // bars that preceded it. Rebuilding it every scan absorbed the breakout bar
   // as soon as that bar closed, which moved the boundary past the price,
   // reset the hold timers and invalidated the very event being tracked.
   bool event_live = (g_profiles[index].event_state == STATE_CANDIDATE ||
                      IsActiveState(g_profiles[index].event_state));
   if(event_live && g_profiles[index].range_anchor_bar_time > 0 && g_profiles[index].range_width > 0.0)
      return;

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
   g_profiles[index].range_anchor_bar_time = rates[0].time;
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
      g_session_baselines[i].spread_samples = 0;
      g_session_baselines[i].tick_rate_samples = 0;
      g_session_baselines[i].tick_volume_samples = 0;
      g_session_baselines[i].spread_mean = 0.0;
      g_session_baselines[i].spread_var = 0.0;
      g_session_baselines[i].tick_rate_mean = 0.0;
      g_session_baselines[i].tick_rate_var = 0.0;
      g_session_baselines[i].tick_volume_mean = 0.0;
      g_session_baselines[i].tick_volume_var = 0.0;
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
   bool tick_rate_known = g_profiles[index].tick_rate_available;
   // The projected bar volume only exists once the trigger timeframe has data.
   // Folding the initial or a stale value in would poison the tick-volume
   // baseline exactly as folding an unknown tick rate in as zero would, so both
   // series carry the same guard and each carries its own sample count.
   bool tick_volume_known = g_profiles[index].has_trigger;
   double tick_volume = g_profiles[index].active_trigger_tick_volume;

   // Readiness is taken per series from the baseline that series' z-score is
   // actually measured against, and assigned before the update, so on the sample
   // that crosses the threshold the flag and the z-score agree. One shared flag
   // published a measured-looking 0 for a series that had never contributed a
   // sample. Zeroing on the not-ready path also stops a new session bucket
   // inheriting the previous bucket's scores.
   bool spread_ready = (baseline.spread_samples >= MinBaselineSamples);
   bool tick_rate_ready = (tick_rate_known && baseline.tick_rate_samples >= MinBaselineSamples);
   bool tick_volume_ready = (tick_volume_known && baseline.tick_volume_samples >= MinBaselineSamples);
   g_profiles[index].session_spread_z_ready = spread_ready;
   g_profiles[index].session_tick_rate_z_ready = tick_rate_ready;
   g_profiles[index].session_tick_volume_z_ready = tick_volume_ready;

   g_profiles[index].session_spread_z = (spread_ready ?
                                         BaselineZ(g_profiles[index].spread_pips,
                                                   baseline.spread_mean,
                                                   baseline.spread_var) : 0.0);
   g_profiles[index].session_tick_rate_z = (tick_rate_ready ?
                                            BaselineZ(g_profiles[index].tick_rate_per_sec,
                                                      baseline.tick_rate_mean,
                                                      baseline.tick_rate_var) : 0.0);
   g_profiles[index].session_tick_volume_z = (tick_volume_ready ?
                                              BaselineZ(tick_volume,
                                                        baseline.tick_volume_mean,
                                                        baseline.tick_volume_var) : 0.0);

   UpdateRollingMeanVar(baseline.spread_mean, baseline.spread_var, baseline.spread_samples, g_profiles[index].spread_pips);
   if(baseline.spread_samples < BaselineLookbackSamples)
      baseline.spread_samples++;
   // An unmeasured tick rate or tick volume must not be folded into the baseline
   // as zero, and must not advance the other series' counters either.
   if(tick_rate_known)
   {
      UpdateRollingMeanVar(baseline.tick_rate_mean, baseline.tick_rate_var, baseline.tick_rate_samples, g_profiles[index].tick_rate_per_sec);
      if(baseline.tick_rate_samples < BaselineLookbackSamples)
         baseline.tick_rate_samples++;
   }
   if(tick_volume_known)
   {
      UpdateRollingMeanVar(baseline.tick_volume_mean, baseline.tick_volume_var, baseline.tick_volume_samples, tick_volume);
      if(baseline.tick_volume_samples < BaselineLookbackSamples)
         baseline.tick_volume_samples++;
   }

   g_session_baselines[baseline_index] = baseline;
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
   if(!g_profiles[index].has_trigger || g_profiles[index].atr_trigger <= 0.0)
   {
      g_profiles[index].outside_since_up = 0;
      g_profiles[index].outside_since_down = 0;
      g_profiles[index].reentered_since_up = 0;
      g_profiles[index].reentered_since_down = 0;
      g_profiles[index].breakout_buffer_price = 0.0;
      return;
   }

   // Direction independent and needed by four consumers per direction; computed
   // once per scan here, where every input is final.
   double spread_price = MathMax(g_profiles[index].ask - g_profiles[index].bid, 0.0);
   double atr_part = g_profiles[index].atr_trigger * BreakoutBufferATR;
   double min_part = MinBreakoutBufferPips * g_profiles[index].pip_size;
   g_profiles[index].breakout_buffer_price = Max3(spread_price * 1.20, atr_part, min_part);

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

bool AddSnapshot(const int index, const long time_msc, const double mid)
{
   if(time_msc <= 0 || mid <= 0.0)
      return false;

   if(g_profiles[index].snapshot_count > 0)
   {
      int last_position = g_profiles[index].snapshot_write_index - 1;
      if(last_position < 0)
         last_position = SNAPSHOT_CAPACITY - 1;
      int last_index = SnapshotIndex(index, last_position);
      if(g_snapshots[last_index].time_msc == time_msc &&
         MathAbs(g_snapshots[last_index].mid - mid) < g_profiles[index].point * 0.1)
      {
         return false;
      }
   }

   int position = g_profiles[index].snapshot_write_index;
   int sample_index = SnapshotIndex(index, position);
   g_snapshots[sample_index].time_msc = time_msc;
   g_snapshots[sample_index].mid = mid;

   g_profiles[index].snapshot_write_index = (position + 1) % SNAPSHOT_CAPACITY;
   if(g_profiles[index].snapshot_count < SNAPSHOT_CAPACITY)
      g_profiles[index].snapshot_count++;
   return true;
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

// Median and robust z were each building and sorting their own copy of the same
// ring. One pass now produces both.
void UpdateSpreadStatistics(const int index)
{
   int count = g_profiles[index].spread_count;
   // Until the ring holds enough samples neither the median nor the robust z
   // exists; the previous fallback of median = current spread scored every
   // fresh profile as trading at exactly its normal spread.
   g_profiles[index].spread_stats_ready = false;
   g_profiles[index].median_spread_pips = 0.0;
   g_profiles[index].spread_z = 0.0;
   if(count < MIN_SPREAD_SAMPLES || !PrepareScratch(g_spread_scratch, count, SPREAD_HISTORY_CAPACITY))
      return;

   for(int i = 0; i < count; i++)
      g_spread_scratch[i] = g_spread_history[SpreadIndex(index, LogicalSpreadPosition(index, i))];

   double median = MedianOfArray(g_spread_scratch, count);
   g_profiles[index].median_spread_pips = median;
   g_profiles[index].spread_stats_ready = true;

   // MedianOfArray sorted the scratch in place; deviations come from that.
   double mad = MedianAbsDeviationInto(g_mad_scratch, g_spread_scratch, count, median,
                                       SPREAD_HISTORY_CAPACITY);
   g_profiles[index].spread_z = RobustZ(g_profiles[index].spread_pips, median, mad);
}

void CalculateCurrencyStrength()
{
   for(int i = 0; i < CURRENCY_COUNT; i++)
   {
      g_currency_sum[i] = 0.0;
      g_currency_samples[i] = 0;
      g_currency_weight[i] = 0.0;
   }

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      g_profiles[i].basket_contribution = 0.0;
      g_profiles[i].basket_weight = 0.0;
   }

   if(!UseCurrencyStrength)
      return;

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!g_profiles[i].is_first_profile_for_symbol)
         continue;
      if(!g_profiles[i].valid || !g_profiles[i].quote_fresh ||
         g_profiles[i].base_index < 0 || g_profiles[i].quote_index < 0 ||
         g_profiles[i].m1_atr_pips <= 0.0 || g_profiles[i].pip_size <= 0.0 ||
         g_profiles[i].snapshot_coverage_sec < 60)
      {
         continue;   // the 30 s and 60 s speeds need a full minute of snapshots
      }

      if(g_profiles[i].spread_pips <= 0.0 || g_profiles[i].spread_pips > MaxSpreadPips ||
         (g_profiles[i].spread_stats_ready &&
          g_profiles[i].spread_pips > g_profiles[i].median_spread_pips * MaxSpreadMedianMultiplier))
      {
         continue;
      }

      double atr_pips = MathMax(g_profiles[i].m1_atr_pips, 0.1);
      double n30 = Clamp(g_profiles[i].speed_30s_pips / (atr_pips * 0.35), -1.5, 1.5);
      double n60 = Clamp(g_profiles[i].speed_60s_pips / (atr_pips * 0.55), -1.5, 1.5);
      double n5m = Clamp(g_profiles[i].movement_5m_pips / (atr_pips * 1.50), -1.5, 1.5);
      double pair_strength = n30 * 0.45 + n60 * 0.25 + n5m * 0.30;
      double weight = 1.0;
      if(UseRobustCurrencyStrength)
      {
         double spread_penalty = 1.0;
         if(g_profiles[i].spread_stats_ready)
            spread_penalty = 1.0 / MathMax(1.0, g_profiles[i].spread_pips / MathMax(g_profiles[i].median_spread_pips, 0.1));
         weight = spread_penalty / MathMax(atr_pips, 0.5);
         weight = Clamp(weight, 0.05, 2.0);
      }

      // The symbol's own contribution is kept so the pair can be scored against
      // the rest of the basket without confirming itself.
      g_profiles[i].basket_contribution = pair_strength * weight;
      g_profiles[i].basket_weight = weight;

      int base = g_profiles[i].base_index;
      int quote = g_profiles[i].quote_index;
      g_currency_sum[base] += pair_strength * weight;
      g_currency_sum[quote] -= pair_strength * weight;
      g_currency_weight[base] += weight;
      g_currency_weight[quote] += weight;
      g_currency_samples[base]++;
      g_currency_samples[quote]++;
   }
}

void CalculateScoresAndUpdateState(const int index, const datetime now)
{
   g_profiles[index].final_score_up = 0.0;
   g_profiles[index].final_score_down = 0.0;

   SharedComponents shared;
   EvaluateSharedComponents(index, now, shared);
   BuildCompositeSignalScore(index, DIR_UP, now, shared, g_profiles[index].composite_up);
   BuildCompositeSignalScore(index, DIR_DOWN, now, shared, g_profiles[index].composite_down);

   if(g_profiles[index].composite_up.valid)
      g_profiles[index].final_score_up = g_profiles[index].composite_up.displayed_score;
   if(g_profiles[index].composite_down.valid)
      g_profiles[index].final_score_down = g_profiles[index].composite_down.displayed_score;

   UpdateSignalState(index, now);
}

void ResetCompositeSignalScore(CompositeSignalScore &score)
{
   score.valid = false;
   score.raw_score = 0.0;
   score.displayed_score = 0.0;
   score.age_free_score = 0.0;
   score.block_reason = BLOCK_NONE;
   score.cap_reasons = "";
   score.reason_summary = "";
   score.human_reason = "";
   score.compact_tags = "";

   score.execution.pass = false;
   score.execution.score = 0.0;
   score.execution.spread_pips = 0.0;
   score.execution.median_available = false;
   score.execution.median_spread_pips = 0.0;
   score.execution.spread_ratio = 0.0;
   score.execution.spread_z_available = false;
   score.execution.spread_z = 0.0;
   score.execution.quote_age_sec = 0.0;
   score.execution.tick_gap_sec = 0.0;
   score.execution.cost_to_atr = 0.0;
   score.execution.block_reason = BLOCK_NONE;

   score.breakout.pass = false;
   score.breakout.measured = false;
   score.breakout.candle_measured = false;
   score.breakout.score = 0.0;
   score.breakout.compression_score = 0.0;
   score.breakout.distance_score = 0.0;
   score.breakout.close_location_score = 0.0;
   score.breakout.hold_score = 0.0;
   score.breakout.body_quality_score = 0.0;
   score.breakout.wick_rejection_penalty = 0.0;
   score.breakout.fakeout_penalty = 0.0;

   score.impulse.pass = false;
   score.impulse.measured = false;
   score.impulse.score = 0.0;
   score.impulse.speed_5s_z = 0.0;
   score.impulse.speed_10s_z = 0.0;
   score.impulse.speed_30s_z = 0.0;
   score.impulse.acceleration_score = 0.0;
   score.impulse.atr_expansion_score = 0.0;
   score.impulse.tick_rate_available = false;
   score.impulse.tick_rate_z = 0.0;
   score.impulse.tick_volume_available = false;
   score.impulse.tick_volume_z = 0.0;
   score.impulse.exhaustion_penalty = 0.0;
   score.impulse.tick_quality_available = false;
   score.impulse.tick_sample_quality_score = 0.0;
   score.impulse.tick_state = "TICK_SYNCING";

   score.flow.available = false;
   score.flow.score = 0.0;
   score.flow.base_strength = 0.0;
   score.flow.quote_strength = 0.0;
   score.flow.directional_edge = 0.0;
   score.flow.basket_agreement = 0.0;
   score.flow.conflict_penalty = 0.0;

   score.regime.score = 0.0;
   score.regime.session_score = 0.0;
   score.regime.m5_available = false;
   score.regime.m15_available = false;
   score.regime.mtf_alignment_score = 0.0;
   score.regime.m5_context_score = 0.0;
   score.regime.m15_context_score = 0.0;
   score.regime.volatility_regime_score = 0.0;

   score.calendar.available = false;
   score.calendar.high_impact_nearby = false;
   score.calendar.just_released = false;
   score.calendar.future_high_impact_nearby = false;
   score.calendar.score = 0.0;
   score.calendar.future_high_impact_minutes = 0.0;
   score.calendar.uncertainty_penalty = 0.0;
   score.calendar.state_tag = "NEWS_UNAVAILABLE";
}

// Execution, calendar, session, basket agreement and the tick deviations do
// not depend on the direction; evaluating them per direction did every one of
// them twice per profile per scan.
void EvaluateSharedComponents(const int index, const datetime now, SharedComponents &shared)
{
   EvaluateExecutionQuality(index, now, shared.execution);
   EvaluateCalendarContext(index, now, shared.calendar);
   shared.session_score = SessionQualityScore(now);
   shared.agreement_available = false;
   shared.basket_agreement_up = 0.0;
   if(UseCurrencyStrength && shared.execution.pass)
      shared.basket_agreement_up = CalculateBasketAgreement(index, DIR_UP, shared.agreement_available);
   shared.tick_rate_available = false;
   shared.tick_rate_z = TickRateZ(index, shared.tick_rate_available);
   shared.tick_volume_available = false;
   shared.tick_volume_z = TickVolumeDeviation(index, shared.tick_volume_available);
}

void BuildCompositeSignalScore(const int index,
                               const int direction,
                               const datetime now,
                               const SharedComponents &shared,
                               CompositeSignalScore &score)
{
   ResetCompositeSignalScore(score);

   score.execution = shared.execution;
   if(!score.execution.pass)
   {
      FinishBlockedScore(score, score.execution.block_reason, "");
      return;
   }

   EvaluateBreakoutStructure(index, direction, now, score.breakout);
   EvaluateImpulseQuality(index, direction, shared, score.impulse);
   EvaluateCurrencyFlowQuality(index, direction, shared, score.flow);
   EvaluateRegimeContext(index, direction, shared.session_score, score.regime);
   score.calendar = shared.calendar;

   if(CalendarPreNewsBlock(score.calendar))
   {
      FinishBlockedScore(score, BLOCK_CONTEXT_CONFLICT, "calendar_pre_news");
      return;
   }

   // An engine that could not measure is not an engine that found nothing.
   if(!score.breakout.measured && !score.impulse.measured)
   {
      FinishBlockedScore(score, BLOCK_NO_MOVEMENT_DATA, "");
      return;
   }

   bool engine_pass = ((UseTechnicalBreakoutEngine && score.breakout.pass) ||
                       (UseImpulseBreakoutEngine && score.impulse.pass));
   if(!engine_pass)
   {
      FinishBlockedScore(score, BLOCK_NO_SETUP, "");
      return;
   }

   if(SpreadOnlyBreakout(index, direction))
   {
      FinishBlockedScore(score, BLOCK_SPREAD_ONLY_BREAKOUT, "");
      return;
   }

   if(UseStrictExecutionGate && score.flow.conflict_penalty >= 0.80)
   {
      FinishBlockedScore(score, BLOCK_CONTEXT_CONFLICT, "currency_flow_conflict");
      return;
   }

   CompositeContext context;
   context.direction = direction;
   context.m5_move_directional = g_profiles[index].m5_move_atr * (double)direction;
   context.m15_move_directional = g_profiles[index].m15_move_atr * (double)direction;
   context.age_seconds = EventAgeSeconds(index, direction, now);
   context.age_limit_seconds = EventAgeLimitSeconds(index);
   context.max_spread_to_atr = MaxSpreadToAtrRatio;
   ComposeSignalScore(score, context, false);
   // Text is only consumed by displayed rows, alerts, the history and the
   // debug output; building it for every sub-threshold profile was the most
   // expensive string work of the scan.
   if(ShowBlockedSignalsDebug || DebugScoreBreakdown || MeetsThreshold(score.displayed_score, MinDisplayConfidence))
      BuildScoreText(score);

   if(DebugScoreBreakdown && DebugPrintToJournal &&
      MeetsThreshold(score.displayed_score, MinDisplayConfidence) &&
      DebugLogAllowed(now))
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

// Blends the measured components and applies the cap ladder. Pure over the
// component structs and the context, so the live scanner and the historical
// validator share one definition of the composite score.
void ComposeSignalScore(CompositeSignalScore &score, const CompositeContext &context, const bool build_text = true)
{
   // An unmeasured component contributes nothing and leaves the normaliser,
   // instead of being imputed at a neutral constant that compresses every
   // score toward that constant. This applies to every component alike.
   double breakout_weight = (UseTechnicalBreakoutEngine && score.breakout.measured ? 0.22 : 0.0);
   double impulse_weight = (UseImpulseBreakoutEngine && score.impulse.measured ? 0.22 : 0.0);
   double execution_weight = 0.18;
   double flow_weight = (UseCurrencyStrength && score.flow.available ? 0.16 : 0.0);
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

   double capped = Clamp(score.raw_score, 0.0, 100.0);
   string caps = "";

   if(!UseEconomicCalendarContext || !score.calendar.available)
      capped = ApplyScoreCap(capped, 94.0, caps, "no_calendar_cap");

   if(!UseCurrencyStrength)
      capped = ApplyScoreCap(capped, 84.0, caps, "flow_disabled_cap");
   else if(!score.flow.available)
      capped = ApplyScoreCap(capped, 84.0, caps, "flow_absent_cap");
   else if(score.flow.conflict_penalty >= 0.35)
      capped = ApplyScoreCap(capped, 69.0, caps, "flow_conflict_cap");

   if(score.execution.score < 0.68 ||
      score.execution.cost_to_atr > context.max_spread_to_atr * 0.70 ||
      (score.execution.median_available &&
       score.execution.spread_ratio > MathMax(1.30, MaxSpreadMedianMultiplier * 0.65)))
   {
      capped = ApplyScoreCap(capped, 69.0, caps, "execution_mediocre_cap");
   }

   if(score.breakout.pass && score.breakout.hold_score < 0.35)
      capped = ApplyScoreCap(capped, 74.0, caps, "weak_hold_cap");
   if(score.breakout.pass && score.breakout.candle_measured && score.breakout.body_quality_score < 0.35)
      capped = ApplyScoreCap(capped, 79.0, caps, "weak_body_cap");
   if(score.breakout.fakeout_penalty >= 0.45)
      capped = ApplyScoreCap(capped, 64.0, caps, "range_snapback_cap");

   // The reject levels are the raw closed-bar moves the inputs describe, not a
   // point on the context ramp that happened to sit elsewhere.
   if(UseMultiTimeframeContextCaps)
   {
      bool m5_reject = (score.regime.m5_available && context.m5_move_directional <= M5RejectAtr);
      bool m15_reject = (score.regime.m15_available && context.m15_move_directional <= M15RejectAtr);
      if(m5_reject || m15_reject)
         capped = ApplyScoreCap(capped, 69.0, caps, "mtf_reject_cap");
   }

   if(score.impulse.measured && score.impulse.score >= ENGINE_CONFIRM_THRESHOLD &&
      UseTickRateScoring &&
      score.impulse.tick_rate_available && score.impulse.tick_rate_z < 0.0 &&
      score.impulse.tick_volume_available && score.impulse.tick_volume_z < 0.0)
   {
      capped = ApplyScoreCap(capped, 72.0, caps, "unsupported_impulse_cap");
   }

   if(score.impulse.exhaustion_penalty >= 0.45)
      capped = ApplyScoreCap(capped, 75.0, caps, "overextended_cap");

   score.age_free_score = Clamp(capped, 0.0, 100.0);
   if(context.age_limit_seconds > 0 && context.age_seconds > context.age_limit_seconds)
   {
      capped = ApplyScoreCap(capped, 0.0, caps, "expired_event_cap");
      score.block_reason = BLOCK_EXPIRED;
   }
   else if(context.age_seconds > LATE_EVENT_SECONDS)
      capped = ApplyScoreCap(capped, 70.0, caps, "late_event_cap");
   else if(context.age_seconds > AGING_EVENT_SECONDS)
      capped = ApplyScoreCap(capped, 84.0, caps, "aging_event_cap");

   if(score.calendar.available && score.calendar.uncertainty_penalty >= 0.35)
      capped = ApplyScoreCap(capped, 88.0, caps, "calendar_uncertainty_cap");

   if(capped > 80.0 &&
      (score.execution.score < 0.78 ||
       MathMax(score.breakout.score, score.impulse.score) < ENGINE_CONFIRM_THRESHOLD))
   {
      capped = ApplyScoreCap(capped, 79.0, caps, "single_feature_cap");
   }

   // Each elite term is judged only where it was measured; a disabled
   // technical engine has no hold to veto with.
   bool weak_hold = (UseTechnicalBreakoutEngine && score.breakout.pass && score.breakout.hold_score < 0.75);
   bool weak_flow = (UseCurrencyStrength && score.flow.available && score.flow.score < 0.70);
   if(capped > 90.0 &&
      (score.execution.score < 0.88 || weak_hold || weak_flow || score.regime.score < 0.65 ||
       score.calendar.uncertainty_penalty > 0.20))
   {
      capped = ApplyScoreCap(capped, 89.0, caps, "elite_score_cap");
   }

   if(capped > 95.0)
      capped = 95.0;

   score.displayed_score = Clamp(capped, 0.0, 100.0);
   score.valid = (score.displayed_score > 0.0);
   score.cap_reasons = caps;
   if(build_text)
      BuildScoreText(score);
}

// The three text fields of a composed score, from its components and caps.
void BuildScoreText(CompositeSignalScore &score)
{
   score.reason_summary = BuildReasonSummary(score, score.cap_reasons);
   score.compact_tags = BuildCompactTags(score);
   score.human_reason = BuildHumanReadableReason(score);
}

// Every block path leaves the same fields filled so a blocked row's tooltip
// reads like an active one; the tags and human text exist only when blocked
// rows or debug output can show them.
void FinishBlockedScore(CompositeSignalScore &score, const SignalBlockReason reason, const string detail)
{
   score.block_reason = reason;
   score.reason_summary = "blocked=" + (detail == "" ? BlockReasonText(reason) : detail);
   if(ShowBlockedSignalsDebug || DebugScoreBreakdown)
   {
      score.compact_tags = BuildCompactTags(score);
      score.human_reason = BuildHumanReadableReason(score);
   }
}

// The dashboard prints a rounded percentage, so every threshold comparison
// rounds the same way: a 69.6 that reads "70%" meets a threshold of 70.
int DisplayPercent(const double score)
{
   return (int)MathRound(Clamp(score, 0.0, 100.0));
}

bool MeetsThreshold(const double score, const double threshold)
{
   return (DisplayPercent(score) >= (int)MathRound(threshold));
}

bool DebugLogAllowed(const datetime now)
{
   if(g_debug_window_started == 0 || now - g_debug_window_started >= 60)
   {
      g_debug_window_started = now;
      g_debug_lines_in_window = 0;
   }
   if(g_debug_lines_in_window >= MAX_DEBUG_LINES_PER_MINUTE)
      return false;
   g_debug_lines_in_window++;
   return true;
}

void EvaluateExecutionQuality(const int index, const datetime now, ExecutionQuality &execution)
{
   execution.pass = false;
   execution.score = 0.0;
   execution.spread_pips = g_profiles[index].spread_pips;
   // Spread statistics exist only once the ring has enough samples. Before
   // that the ratio and the robust z are unmeasured: they leave the gates and
   // the blend rather than scoring the profile as trading at its normal spread.
   execution.median_available = g_profiles[index].spread_stats_ready;
   execution.median_spread_pips = (execution.median_available ? g_profiles[index].median_spread_pips : 0.0);
   execution.spread_ratio = (execution.median_available && execution.median_spread_pips > 0.0 ?
                             execution.spread_pips / execution.median_spread_pips : 0.0);
   bool session_z_ready = (UseSessionAwareBaselines && g_profiles[index].session_spread_z_ready);
   execution.spread_z_available = (session_z_ready || execution.median_available);
   execution.spread_z = (session_z_ready ? g_profiles[index].session_spread_z :
                         (execution.median_available ? g_profiles[index].spread_z : 0.0));
   execution.quote_age_sec = (g_profiles[index].quote_time > 0 ? g_profiles[index].quote_age_sec : 9999.0);
   execution.tick_gap_sec = g_profiles[index].tick_gap_sec;
   execution.cost_to_atr = SafeDiv(MathMax(g_profiles[index].ask - g_profiles[index].bid, 0.0),
                                   g_profiles[index].atr_trigger,
                                   999.0);
   execution.block_reason = BLOCK_NONE;

   if(!g_profiles[index].valid || !g_profiles[index].selected ||
      !g_profiles[index].quote_fresh || g_profiles[index].bid <= 0.0 ||
      g_profiles[index].ask <= 0.0 || g_profiles[index].ask < g_profiles[index].bid)
   {
      execution.block_reason = BLOCK_STALE_QUOTE;
      return;
   }

   if(!g_profiles[index].has_trigger || !g_profiles[index].has_m5 || !g_profiles[index].has_m15 ||
      g_profiles[index].atr_trigger <= 0.0 ||
      SafeDiv(g_profiles[index].atr_trigger, g_profiles[index].pip_size, 0.0) < 0.10)
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

   if(ExecutionSpreadBlock(execution, MaxSpreadToAtrRatio, UseStrictExecutionGate) != BLOCK_NONE)
   {
      execution.block_reason = BLOCK_BAD_SPREAD;
      return;
   }

   if(UseStrictExecutionGate)
   {
      if(execution.tick_gap_sec > MaxTickGapSeconds)
      {
         execution.block_reason = BLOCK_STALE_QUOTE;
         return;
      }
   }

   execution.score = BlendExecutionScore(execution, MaxSpreadToAtrRatio, true);
   execution.pass = true;
}

// The spread, cost-to-ATR and spread-z ceilings as one predicate over the terms
// that bar history can also measure. The live scanner and the historical
// validator both call it, so the UseStrictExecutionGate switch cannot drift
// between the strategy that runs live and the strategy the reports describe:
// the validator used to apply the cost-to-ATR ceiling unconditionally, which
// rejected boundaries the live scanner accepts. Returns BLOCK_NONE to accept.
SignalBlockReason ExecutionSpreadBlock(const ExecutionQuality &execution,
                                       const double max_spread_to_atr,
                                       const bool strict)
{
   if(execution.spread_pips <= 0.0 || execution.spread_pips > MaxSpreadPips ||
      (execution.median_available && execution.spread_ratio > MaxSpreadMedianMultiplier))
   {
      return BLOCK_BAD_SPREAD;
   }

   if(!strict)
      return BLOCK_NONE;

   if(execution.cost_to_atr > max_spread_to_atr)
      return BLOCK_BAD_SPREAD;
   if(execution.spread_z_available && execution.spread_z > MaxSpreadZScore)
      return BLOCK_BAD_SPREAD;

   return BLOCK_NONE;
}

// Execution quality from the measured terms only. The quote-age and tick-gap
// terms exist for live data; bar history has neither and leaves them out.
double BlendExecutionScore(const ExecutionQuality &execution,
                           const double max_spread_to_atr,
                           const bool quote_terms_available)
{
   double spread_abs_score = 1.0 - SmoothStep(MaxSpreadPips * 0.45, MaxSpreadPips, execution.spread_pips);
   double cost_score = 1.0 - SmoothStep(max_spread_to_atr * 0.45, max_spread_to_atr, execution.cost_to_atr);
   double weighted = spread_abs_score * 0.18 + cost_score * 0.24;
   double total_weight = 0.18 + 0.24;
   if(execution.median_available)
   {
      weighted += (1.0 - SmoothStep(1.0, MaxSpreadMedianMultiplier, execution.spread_ratio)) * 0.20;
      total_weight += 0.20;
   }
   if(execution.spread_z_available)
   {
      weighted += (1.0 - SmoothStep(1.25, MaxSpreadZScore, execution.spread_z)) * 0.14;
      total_weight += 0.14;
   }
   if(quote_terms_available)
   {
      weighted += (1.0 - SmoothStep((double)MaxQuoteAgeSeconds * 0.45, (double)MaxQuoteAgeSeconds,
                                    execution.quote_age_sec)) * 0.12;
      weighted += (1.0 - SmoothStep(MaxTickGapSeconds * 0.45, MaxTickGapSeconds,
                                    execution.tick_gap_sec)) * 0.12;
      total_weight += 0.24;
   }
   return Clamp01(weighted / total_weight);
}

void EvaluateBreakoutStructure(const int index,
                               const int direction,
                               const datetime now,
                               BreakoutStructure &breakout)
{
   breakout.pass = false;
   breakout.measured = false;
   breakout.candle_measured = false;
   breakout.score = 0.0;
   breakout.compression_score = 0.0;
   breakout.distance_score = 0.0;
   breakout.close_location_score = 0.0;
   breakout.hold_score = 0.0;
   breakout.body_quality_score = 0.0;
   breakout.wick_rejection_penalty = 0.0;
   breakout.fakeout_penalty = 0.0;

   if(!UseTechnicalBreakoutEngine || g_profiles[index].atr_trigger <= 0.0 ||
      g_profiles[index].range_width <= 0.0)
   {
      return;
   }

   datetime outside_since = (direction == DIR_UP ? g_profiles[index].outside_since_up :
                             g_profiles[index].outside_since_down);
   datetime reentered_since = (direction == DIR_UP ? g_profiles[index].reentered_since_up :
                               g_profiles[index].reentered_since_down);
   double outside_seconds = (outside_since > 0 ? (double)MathMax(0, (int)(now - outside_since)) : -1.0);
   double reentered_seconds = (reentered_since > 0 ? (double)MathMax(0, (int)(now - reentered_since)) : -1.0);

   ComputeBreakoutStructure(direction,
                            g_profiles[index].atr_trigger,
                            g_profiles[index].range_width,
                            BreakoutDistance(index, direction),
                            MathMax(BreakoutBufferPrice(index), g_profiles[index].point),
                            MaxOverextensionAtr,
                            g_profiles[index].current_trigger_open,
                            g_profiles[index].current_trigger_high,
                            g_profiles[index].current_trigger_low,
                            g_profiles[index].current_trigger_close,
                            outside_seconds,
                            reentered_seconds,
                            breakout);
}

// The breakout structure from its raw inputs: range and ATR, the excursion
// beyond the buffered boundary, the trigger bar's shape, and how long the
// price has held outside (negative = not outside) or since it re-entered
// (negative = never). Shared by the live scanner and the historical validator.
void ComputeBreakoutStructure(const int direction,
                              const double atr,
                              const double range_width,
                              const double distance,
                              const double buffer,
                              const double max_overextension_atr,
                              const double bar_open,
                              const double bar_high,
                              const double bar_low,
                              const double bar_close,
                              const double outside_seconds,
                              const double reentered_seconds,
                              BreakoutStructure &breakout)
{
   // Fully initialise the output so this is a pure function of its arguments.
   // It used to set only 'measured' and rely on every caller having reset the
   // struct first: MQL5 does not zero the caller's struct, so a direct caller got
   // whatever the memory held, and the "pure functions shared by the live scanner
   // and the historical modes" promise in CLAUDE.md was not actually true. The
   // self-test group "breakout hold" fails against the caller-dependent form.
   breakout.pass = false;
   breakout.measured = true;
   breakout.candle_measured = false;
   breakout.score = 0.0;
   breakout.compression_score = 0.0;
   breakout.distance_score = 0.0;
   breakout.close_location_score = 0.0;
   breakout.hold_score = 0.0;
   breakout.body_quality_score = 0.0;
   breakout.wick_rejection_penalty = 0.0;
   breakout.fakeout_penalty = 0.0;

   double range_atr = range_width / atr;
   double not_dead = SmoothStep(0.65, 1.80, range_atr);
   double not_chaotic = 1.0 - SmoothStep(7.0, 16.0, range_atr);
   breakout.compression_score = Clamp01(0.10 + 0.90 * not_dead * not_chaotic);

   double distance_units = SafeDiv(distance, buffer, 0.0);
   double distance_atr = SafeDiv(distance, atr, 0.0);
   double extension_penalty = SmoothStep(max_overextension_atr, max_overextension_atr * 1.80, distance_atr);
   breakout.distance_score = Clamp01(SmoothStep(0.20, 1.60, distance_units) * (1.0 - extension_penalty * 0.45));

   // A bar that has barely moved has no shape to read: on the first ticks of
   // every new bar these ratios were noise that scored as a weak body.
   double candle_range = bar_high - bar_low;
   breakout.candle_measured = (candle_range >= CANDLE_MEASURE_MIN_ATR * atr);
   if(breakout.candle_measured)
   {
      if(direction == DIR_UP)
         breakout.close_location_score = Clamp01((bar_close - bar_low) / candle_range);
      else
         breakout.close_location_score = Clamp01((bar_high - bar_close) / candle_range);

      double body = MathAbs(bar_close - bar_open);
      double body_ratio = body / candle_range;
      double directional_body = DirectionalValue(bar_close - bar_open, direction) / candle_range;
      breakout.body_quality_score = Clamp01(SmoothStep(0.18, 0.62, body_ratio) * 0.65 +
                                            SmoothStep(0.03, 0.38, directional_body) * 0.35);

      double rejection_wick = 0.0;
      if(direction == DIR_UP)
         rejection_wick = bar_high - MathMax(bar_open, bar_close);
      else
         rejection_wick = MathMin(bar_open, bar_close) - bar_low;
      breakout.wick_rejection_penalty = Clamp01(rejection_wick / candle_range);
   }

   // A negative outside_seconds means the price is inside the buffered boundary,
   // which is a measurement of "held outside for zero seconds", not missing data:
   // UpdateOutsideTimers only reaches its classification when the trigger data
   // exists, and EvaluateBreakoutStructure requires atr_trigger > 0 to get here.
   // The zero is therefore weighted deliberately, and the branch is written out in
   // full so the weight below and the value here are visibly one decision rather
   // than a default that a future guard change could silently alter.
   breakout.hold_score = (outside_seconds >= 0.0 ?
                          SmoothStep((double)MinHoldSecondsForHighScore,
                                     (double)FullHoldScoreSeconds,
                                     outside_seconds) : 0.0);

   if(reentered_seconds >= 0.0 && reentered_seconds <= 30.0)
      breakout.fakeout_penalty = 1.0 - SmoothStep(0.0, 30.0, reentered_seconds);

   // The snapback (fakeout) penalty acts once, through range_snapback_cap in
   // the composite, rather than being subtracted here as well.
   double weighted = breakout.compression_score * 0.17 +
                     breakout.distance_score * 0.24 +
                     breakout.hold_score * 0.20;
   double total_weight = 0.17 + 0.24 + 0.20;
   if(breakout.candle_measured)
   {
      weighted += breakout.close_location_score * 0.17 +
                  breakout.body_quality_score * 0.17 -
                  breakout.wick_rejection_penalty * 0.15;
      total_weight += 0.17 + 0.17;
   }
   breakout.score = Clamp01(weighted / total_weight);
   breakout.pass = (distance > 0.0 && breakout.score > 0.06);
}

void EvaluateImpulseQuality(const int index,
                            const int direction,
                            const SharedComponents &shared,
                            ImpulseQuality &impulse)
{
   impulse.pass = false;
   impulse.measured = false;
   impulse.score = 0.0;
   impulse.speed_5s_z = 0.0;
   impulse.speed_10s_z = 0.0;
   impulse.speed_30s_z = 0.0;
   impulse.acceleration_score = 0.0;
   impulse.atr_expansion_score = 0.0;
   impulse.tick_rate_available = false;
   impulse.tick_rate_z = 0.0;
   impulse.tick_volume_available = false;
   impulse.tick_volume_z = 0.0;
   impulse.exhaustion_penalty = 0.0;

   // The tick state is a profile-level reading and stays visible on the row
   // even when the impulse engine is off or cannot measure yet.
   impulse.tick_quality_available = g_profiles[index].tick_quality_available;
   impulse.tick_sample_quality_score = g_profiles[index].tick_sample_quality_score;
   impulse.tick_state = g_profiles[index].tick_state;

   if(!UseImpulseBreakoutEngine || g_profiles[index].atr_trigger <= 0.0 ||
      g_profiles[index].pip_size <= 0.0 || g_profiles[index].snapshot_count < 3)
   {
      return;
   }

   bool z5_ready = SpeedWindowReady(index, 5);
   bool z10_ready = SpeedWindowReady(index, 10);
   bool z30_ready = SpeedWindowReady(index, 30);
   if(!z5_ready && !z10_ready && !z30_ready)
      return;   // no window has a baseline yet: unmeasured, not zero
   impulse.measured = true;

   impulse.speed_5s_z = (z5_ready ? SpeedRobustZ(index, direction, 5) : 0.0);
   impulse.speed_10s_z = (z10_ready ? SpeedRobustZ(index, direction, 10) : 0.0);
   impulse.speed_30s_z = (z30_ready ? SpeedRobustZ(index, direction, 30) : 0.0);
   double speed_max = -999.0;
   if(z5_ready)
      speed_max = MathMax(speed_max, impulse.speed_5s_z);
   if(z10_ready)
      speed_max = MathMax(speed_max, impulse.speed_10s_z);
   if(z30_ready)
      speed_max = MathMax(speed_max, impulse.speed_30s_z);

   double speed_score = Clamp01(ScoreFromZ(speed_max,
                                           MinImpulseZForSignal,
                                           MinImpulseZForSignal + 2.75));

   double atr_pips = MathMax(g_profiles[index].atr_trigger / g_profiles[index].pip_size, 0.1);
   // Acceleration compares the 5 s and 30 s rates in ATR per second so the
   // ramp means the same thing on a 6-pip and a 20-pip ATR.
   bool acceleration_available = SnapshotWindowCovered(index, 30);
   if(acceleration_available)
   {
      double short_rate = DirectionalValue(g_profiles[index].speed_5s_pips, direction) / 5.0;
      double long_rate = DirectionalValue(g_profiles[index].speed_30s_pips, direction) / 30.0;
      impulse.acceleration_score = SmoothStep(0.0, ACCELERATION_FULL_ATR_PER_SECOND,
                                              (short_rate - long_rate) / atr_pips);
   }

   double candle_directional_range = 0.0;
   if(direction == DIR_UP)
      candle_directional_range = g_profiles[index].current_trigger_high - g_profiles[index].current_trigger_open;
   else
      candle_directional_range = g_profiles[index].current_trigger_open - g_profiles[index].current_trigger_low;
   impulse.atr_expansion_score = SmoothStep(0.20, 1.25, SafeDiv(candle_directional_range,
                                                               g_profiles[index].atr_trigger,
                                                               0.0));

   impulse.tick_rate_available = shared.tick_rate_available;
   impulse.tick_rate_z = shared.tick_rate_z;
   impulse.tick_volume_available = shared.tick_volume_available;
   impulse.tick_volume_z = shared.tick_volume_z;
   bool continuation_available = false;
   double continuation = ContinuationScore(index, direction, continuation_available) / 100.0;

   double extended_atr = DirectionalValue(g_profiles[index].movement_5m_pips, direction) / atr_pips;
   impulse.exhaustion_penalty = SmoothStep(MaxExhaustionAtr, MaxExhaustionAtr * 1.70, extended_atr);

   BlendImpulseScore(impulse, speed_score, acceleration_available, continuation_available, continuation);
   // Sample quality scales the reading only when it was actually measured.
   if(UseCopyTicksForImpulse && impulse.tick_quality_available)
      impulse.score = Clamp01(impulse.score * (0.75 + impulse.tick_sample_quality_score * 0.25));
   impulse.pass = (speed_max >= MinImpulseZForSignal || impulse.atr_expansion_score >= 0.45);
}

// Impulse blend from the measured terms only. Components that could not be
// measured are dropped from the blend and from its normaliser, rather than
// being imputed with a constant that would drag every score toward that
// constant. Exhaustion acts once, through overextended_cap in the composite.
void BlendImpulseScore(ImpulseQuality &impulse,
                       const double speed_score,
                       const bool acceleration_available,
                       const bool continuation_available,
                       const double continuation01)
{
   double impulse_weighted = speed_score * 0.25 + impulse.atr_expansion_score * 0.20;
   double impulse_weight_total = 0.25 + 0.20;
   if(impulse.tick_volume_available)
   {
      impulse_weighted += ScoreFromZ(impulse.tick_volume_z, 0.50, 2.80) * 0.15;
      impulse_weight_total += 0.15;
   }
   if(acceleration_available)
   {
      impulse_weighted += impulse.acceleration_score * 0.15;
      impulse_weight_total += 0.15;
   }
   if(UseTickRateScoring && impulse.tick_rate_available)
   {
      impulse_weighted += ScoreFromZ(impulse.tick_rate_z, 0.50, 2.50) * 0.10;
      impulse_weight_total += 0.10;
   }
   if(continuation_available)
   {
      impulse_weighted += continuation01 * 0.15;
      impulse_weight_total += 0.15;
   }
   impulse.score = Clamp01(impulse_weighted / impulse_weight_total);
}

void EvaluateCurrencyFlowQuality(const int index,
                                 const int direction,
                                 const SharedComponents &shared,
                                 CurrencyFlowQuality &flow)
{
   flow.available = false;
   flow.score = 0.0;
   flow.base_strength = 0.0;
   flow.quote_strength = 0.0;
   flow.directional_edge = 0.0;
   flow.basket_agreement = 0.0;
   flow.conflict_penalty = 0.0;

   if(!UseCurrencyStrength)
      return;

   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   if(base < 0 || quote < 0)
   {
      return;   // unknown pair: no basket reading exists
   }

   // Leave-one-out: the pair's own move is removed from both of its currencies
   // before the edge is formed, otherwise a lone mover confirmed itself with
   // every peer flat. With nothing left after removal there is no reading.
   double own_contribution = 0.0;
   double own_weight = 0.0;
   int leader = g_profiles[index].symbol_leader_index;
   if(leader >= 0 && leader < ArraySize(g_profiles))
   {
      own_contribution = g_profiles[leader].basket_contribution;
      own_weight = g_profiles[leader].basket_weight;
   }
   double base_weight = g_currency_weight[base] - own_weight;
   double quote_weight = g_currency_weight[quote] - own_weight;
   if(base_weight <= 0.000001 || quote_weight <= 0.000001)
      return;   // no peer sample for one of the currencies this scan

   flow.available = true;
   flow.base_strength = (g_currency_sum[base] - own_contribution) / base_weight;
   flow.quote_strength = (g_currency_sum[quote] + own_contribution) / quote_weight;
   flow.directional_edge = (flow.base_strength - flow.quote_strength) * (double)direction;
   // Every peer contributes to exactly one side, or half to both, so the DOWN
   // agreement is exactly one minus the UP agreement.
   bool agreement_available = shared.agreement_available;
   flow.basket_agreement = (agreement_available ?
                            (direction == DIR_UP ? shared.basket_agreement_up : 1.0 - shared.basket_agreement_up) :
                            0.0);

   double edge_score = SmoothStep(MinDirectionalEdgeForHighScore * 0.20,
                                  MinDirectionalEdgeForHighScore,
                                  flow.directional_edge);

   flow.conflict_penalty = 0.0;
   if(flow.directional_edge < -MinDirectionalEdgeForHighScore * 0.50)
      flow.conflict_penalty += 0.45;
   // Only a measured disagreement is a conflict. An unmeasurable one is not.
   if(agreement_available && flow.basket_agreement < 0.35)
      flow.conflict_penalty += 0.45;
   flow.conflict_penalty = Clamp01(flow.conflict_penalty);

   double flow_weighted = edge_score * 0.55;
   double flow_weight_total = 0.55;
   if(agreement_available)
   {
      flow_weighted += SmoothStep(BASKET_AGREEMENT_SCORE_FLOOR,
                                  MinBasketAgreementForHighScore,
                                  flow.basket_agreement) * 0.45;
      flow_weight_total += 0.45;
   }

   // The conflict penalty acts through flow_conflict_cap and the strict-gate
   // block in the composite, not a third time inside the blend.
   flow.score = Clamp01(flow_weighted / flow_weight_total);
}

void EvaluateRegimeContext(const int index,
                           const int direction,
                           const double session_score,
                           RegimeContext &regime)
{
   ComposeRegimeScore(regime,
                      session_score,
                      g_profiles[index].has_m5_move,
                      g_profiles[index].m5_move_atr * (double)direction,
                      g_profiles[index].has_m15_move,
                      g_profiles[index].m15_move_atr * (double)direction,
                      SafeDiv(g_profiles[index].range_width, g_profiles[index].atr_trigger, 0.0));
}

// Regime context from its raw inputs: the session, the closed-bar context
// moves (signed by direction, each with its availability) and the range in
// ATR units. Shared by the live scanner and the historical validator.
void ComposeRegimeScore(RegimeContext &regime,
                        const double session_score,
                        const bool m5_available,
                        const double m5_move_directional,
                        const bool m15_available,
                        const double m15_move_directional,
                        const double range_atr)
{
   regime.session_score = session_score;
   regime.m5_available = m5_available;
   regime.m15_available = m15_available;
   regime.m5_context_score = (m5_available ?
                              SmoothStep(M5RejectAtr, M5_CONTEXT_FULL_ATR, m5_move_directional) : 0.0);
   regime.m15_context_score = (m15_available ?
                               SmoothStep(M15RejectAtr, M15_CONTEXT_FULL_ATR, m15_move_directional) : 0.0);

   double mtf_weighted = 0.0;
   double mtf_weight = 0.0;
   if(regime.m5_available)
   {
      mtf_weighted += regime.m5_context_score * 0.55;
      mtf_weight += 0.55;
   }
   if(regime.m15_available)
   {
      mtf_weighted += regime.m15_context_score * 0.45;
      mtf_weight += 0.45;
   }
   bool mtf_available = (mtf_weight > 0.0);
   regime.mtf_alignment_score = (mtf_available ? Clamp01(mtf_weighted / mtf_weight) : 0.0);

   double active_enough = SmoothStep(0.70, 2.20, range_atr);
   double not_chaotic = 1.0 - SmoothStep(14.0, 24.0, range_atr);
   regime.volatility_regime_score = Clamp01(active_enough * not_chaotic);

   // Rollover is a hard execution gate that runs before this evaluator, so a
   // penalty here could never apply. Unmeasured context leaves the blend.
   double weighted = regime.session_score * 0.25 + regime.volatility_regime_score * 0.33;
   double total_weight = 0.25 + 0.33;
   if(mtf_available)
   {
      weighted += regime.mtf_alignment_score * 0.42;
      total_weight += 0.42;
   }
   regime.score = Clamp01(weighted / total_weight);
}

void EvaluateCalendarContext(const int index,
                             const datetime now,
                             CalendarContext &calendar)
{
   calendar.available = false;
   calendar.high_impact_nearby = false;
   calendar.just_released = false;
   calendar.future_high_impact_nearby = false;
   calendar.score = 0.0;
   calendar.future_high_impact_minutes = 0.0;
   calendar.uncertainty_penalty = 0.0;
   calendar.state_tag = "NEWS_UNAVAILABLE";

   if(!UseEconomicCalendarContext)
   {
      // Distinct from NEWS_NONE, which means "calendar read, nothing nearby".
      calendar.state_tag = "NEWS_OFF";
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

   calendar.high_impact_nearby = (base_cache.high_impact_nearby || quote_cache.high_impact_nearby);
   calendar.just_released = (base_cache.just_released || quote_cache.just_released);
   calendar.future_high_impact_nearby = (base_cache.future_high_impact_nearby || quote_cache.future_high_impact_nearby);
   calendar.uncertainty_penalty = MathMax(base_cache.uncertainty_penalty, quote_cache.uncertainty_penalty);

   // future_high_impact_minutes is non-negative by construction, so the nearest
   // upcoming event is the smaller value on whichever sides reported one.
   bool base_has_future = base_cache.future_high_impact_nearby;
   bool quote_has_future = quote_cache.future_high_impact_nearby;
   if(base_has_future && quote_has_future)
   {
      calendar.future_high_impact_minutes = MathMin(base_cache.future_high_impact_minutes,
                                                    quote_cache.future_high_impact_minutes);
   }
   else if(base_has_future)
      calendar.future_high_impact_minutes = base_cache.future_high_impact_minutes;
   else if(quote_has_future)
      calendar.future_high_impact_minutes = quote_cache.future_high_impact_minutes;

   double high_bonus = (calendar.high_impact_nearby ? 0.05 : 0.0);
   calendar.score = Clamp01(0.60 + high_bonus -
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
      !calendar.available || !calendar.future_high_impact_nearby)
   {
      return false;
   }

   return (calendar.future_high_impact_minutes >= 0.0 &&
           calendar.future_high_impact_minutes <= (double)CalendarPreNewsBlockMinutes);
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
   if(UseTechnicalBreakoutEngine && score.breakout.measured)
   {
      names[count] = "breakout";
      values[count] = score.breakout.score;
      count++;
   }
   if(UseImpulseBreakoutEngine && score.impulse.measured)
   {
      names[count] = "impulse";
      values[count] = score.impulse.score;
      count++;
   }
   if(score.flow.available)
   {
      names[count] = "flow";
      values[count] = score.flow.score;
      count++;
   }
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
   if(count <= 0 || ArrayResize(used, count) != count)
      return summary;
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
   // Engine tags assert a passed engine, never a blend that drifted high on
   // secondary terms; every "not available" tag is gated on the component
   // having been enabled, so a switched-off basket reads FLOW_OFF not FLOW?.
   AddTag(tags, score.breakout.pass && score.breakout.score >= ENGINE_CONFIRM_THRESHOLD, "BRK+");
   AddTag(tags, score.impulse.pass && score.impulse.score >= ENGINE_CONFIRM_THRESHOLD, "IMP+");
   AddTag(tags, score.flow.available && score.flow.score >= FLOW_CONFIRM_THRESHOLD, "FLOW+");
   AddTag(tags, UseCurrencyStrength && !score.flow.available, "FLOW?");
   AddTag(tags, !UseCurrencyStrength, "FLOW_OFF");
   AddTag(tags, score.execution.score >= 0.75, "EXEC+");
   AddTag(tags, score.regime.score >= REGIME_CONFIRM_THRESHOLD, "REG+");
   AddTag(tags, (score.regime.m5_available || score.regime.m15_available) &&
                score.regime.mtf_alignment_score < 0.35, "MTF-");
   AddTag(tags, score.calendar.high_impact_nearby || score.calendar.just_released, "NEWS!");
   AddTag(tags, score.execution.block_reason == BLOCK_BAD_SPREAD ||
                score.execution.cost_to_atr > MaxSpreadToAtrRatio * 0.70, "SPREAD!");
   AddTag(tags, score.execution.block_reason == BLOCK_STALE_QUOTE ||
                score.impulse.tick_state == "TICK_STALE", "STALE!");
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

string BuildHumanReadableReason(const CompositeSignalScore &score)
{
   if(score.block_reason != BLOCK_NONE)
      return "Blocked: " + BlockReasonText(score.block_reason) + " | " + score.reason_summary;

   // The lead names the engine that passed and reached the same level the
   // BRK+/IMP+ tags use, so the text and the tags always agree.
   string lead = "Alert quality: ";
   bool breakout_confirmed = (score.breakout.pass && score.breakout.score >= ENGINE_CONFIRM_THRESHOLD);
   bool impulse_confirmed = (score.impulse.pass && score.impulse.score >= ENGINE_CONFIRM_THRESHOLD);
   if(breakout_confirmed && score.breakout.score >= score.impulse.score)
      lead = "Clean directional breakout: ";
   else if(impulse_confirmed)
      lead = "News-like impulse: ";

   string details = "";
   if(score.impulse.measured &&
      Max3(score.impulse.speed_5s_z, score.impulse.speed_10s_z, score.impulse.speed_30s_z) >= MinImpulseZForSignal)
   {
      details += "impulse above the signal threshold, ";
   }

   // Never assert a basket verdict that was not computed.
   if(!score.flow.available)
      details += "currency basket not evaluated, ";
   else if(score.flow.score >= FLOW_CONFIRM_THRESHOLD)
      details += "currency basket confirms, ";
   else if(score.flow.conflict_penalty >= 0.35)
      details += "currency basket conflicts, ";
   else
      details += "currency basket neutral, ";

   if(score.execution.score >= 0.75)
      details += "execution normal, ";
   else
      details += "execution mediocre, ";

   // Likewise, only claim the news is clear when the calendar was actually read.
   if(!score.calendar.available)
      details += "calendar not evaluated, ";
   else if(score.calendar.state_tag == "NEWS_NONE")
      details += "no high-impact news nearby, ";
   else
      details += score.calendar.state_tag + ", ";

   if(StringLen(details) > 2)
      details = StringSubstr(details, 0, StringLen(details) - 2);
   return lead + details;
}

double CalculateBasketAgreement(const int index, const int direction, bool &available)
{
   available = false;
   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   if(base < 0 || quote < 0)
      return 0.0;

   double agreeing_weight = 0.0;
   double total_weight = 0.0;

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      // Other timeframes of the same symbol carry the same move and would let
      // the pair agree with itself; peers without spread statistics have no
      // weight yet.
      if(!g_profiles[i].is_first_profile_for_symbol || !g_profiles[i].valid || !g_profiles[i].quote_fresh ||
         g_profiles[i].symbol_upper == g_profiles[index].symbol_upper ||
         !g_profiles[i].spread_stats_ready ||
         g_profiles[i].m1_atr_pips <= 0.0 || g_profiles[i].pip_size <= 0.0 ||
         g_profiles[i].base_index < 0 || g_profiles[i].quote_index < 0 ||
         g_profiles[i].spread_pips <= 0.0 || g_profiles[i].spread_pips > MaxSpreadPips)
      {
         continue;
      }

      bool relevant = (g_profiles[i].base_index == base || g_profiles[i].quote_index == base ||
                       g_profiles[i].base_index == quote || g_profiles[i].quote_index == quote);
      if(!relevant)
         continue;

      double atr_pips = MathMax(g_profiles[i].m1_atr_pips, 0.1);
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

      double spread_weight = 1.0 / MathMax(1.0, g_profiles[i].spread_pips /
                                                MathMax(g_profiles[i].median_spread_pips, 0.1));
      double weight = Clamp(spread_weight / MathMax(atr_pips, 0.5), 0.05, 1.50);
      total_weight += weight;

      if(pair_move * expected > 0.03)
         agreeing_weight += weight;
      else if(pair_move * expected > -0.03)
         agreeing_weight += weight * 0.50;
   }

   if(total_weight <= 0.0)
      return 0.0;   // no peer pairs; the caller drops the component

   available = true;
   return Clamp01(agreeing_weight / total_weight);
}

bool SpreadOnlyBreakout(const int index, const int direction)
{
   double breakout_distance = BreakoutDistance(index, direction);
   // Without a 30 s snapshot window the speeds read zero and every breakout
   // would look spread-only; the check needs the measurement to exist.
   if(breakout_distance <= 0.0 || !SnapshotWindowCovered(index, 30))
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
   SessionBucket session_index = SessionIndex(now);
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
      g_calendar_cache[i].future_high_impact_nearby = false;
      g_calendar_cache[i].score = 0.0;
      g_calendar_cache[i].future_high_impact_minutes = 0.0;
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
      if(g_calendar_cache[currency_index].available)
         g_calendar_available = true;
      return;
   }

   CurrencyCalendarCache cache;
   cache.currency = g_currency_codes[currency_index];
   cache.refreshed_at = now;
   cache.available = false;
   cache.relevant_event_nearby = false;
   cache.high_impact_nearby = false;
   cache.just_released = false;
   cache.future_high_impact_nearby = false;
   cache.score = 0.0;
   cache.future_high_impact_minutes = 0.0;
   cache.uncertainty_penalty = 0.0;

   // Session and rollover classification run off the same server clock, so a
   // signal is scored and its calendar context resolved in one session.
   datetime from_time = now - CalendarLookbackMinutes * 60;
   datetime to_time = now + CalendarLookaheadMinutes * 60;
   MqlCalendarValue values[];
   ResetLastError();
   // CalendarValueHistory returns a success flag, not a count. A successful
   // call with an empty result means the calendar was read and nothing is
   // scheduled in the window; only a failed call means it is unavailable.
   if(!CalendarValueHistory(values, from_time, to_time, NULL, cache.currency))
   {
      cache.available = false;
      cache.score = 0.0;
      g_calendar_cache[currency_index] = cache;
      return;
   }

   int count = ArraySize(values);
   cache.available = true;
   cache.score = CALENDAR_QUIET_SCORE;
   g_calendar_available = true;
   for(int i = 0; i < count; i++)
   {
      MqlCalendarEvent calendar_event;
      if(!CalendarEventById(values[i].event_id, calendar_event))
         continue;
      // Date-only, tentative and undated entries carry a midnight timestamp
      // that says nothing about the release minute.
      if(calendar_event.time_mode != CALENDAR_TIMEMODE_DATETIME)
         continue;

      int importance = (int)calendar_event.importance;
      bool high_impact = (importance >= 3);
      if(CalendarHighImpactOnly && !high_impact)
         continue;

      double minutes_signed = (double)(values[i].time - now) / 60.0;
      double abs_minutes = MathAbs(minutes_signed);

      cache.relevant_event_nearby = true;
      cache.high_impact_nearby = (cache.high_impact_nearby || high_impact);
      bool just_released = (minutes_signed <= 0.0 &&
                            MathAbs(minutes_signed) <= (double)CalendarLookbackMinutes);
      cache.just_released = (cache.just_released || just_released);
      if(high_impact && minutes_signed >= 0.0 &&
         minutes_signed <= (double)CalendarLookaheadMinutes)
      {
         if(!cache.future_high_impact_nearby || minutes_signed < cache.future_high_impact_minutes)
            cache.future_high_impact_minutes = minutes_signed;
         cache.future_high_impact_nearby = true;
      }
      if(minutes_signed >= 0.0 && abs_minutes <= (double)CalendarLookaheadMinutes)
         cache.uncertainty_penalty = MathMax(cache.uncertainty_penalty, high_impact ? 0.55 : 0.25);
   }

   if(cache.relevant_event_nearby)
      cache.score = Clamp01(0.58 + (cache.high_impact_nearby ? 0.16 : 0.06) -
                            cache.uncertainty_penalty * 0.25);

   g_calendar_cache[currency_index] = cache;
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

SessionBucket SessionIndex(const datetime now)
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
   if(reason == BLOCK_NO_SETUP)
      return "no_breakout_or_impulse";
   if(reason == BLOCK_SPREAD_ONLY_BREAKOUT)
      return "spread_only_breakout";
   if(reason == BLOCK_EXPIRED)
      return "event_expired";
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
   if(reason == BLOCK_CONTEXT_CONFLICT)
      return "context_conflict";
   return "none";
}

bool IsActiveState(const BreakoutEventState state)
{
   return (state == STATE_ACTIVE_CONFIRMED);
}

bool IsConfirmedSignal(const int index,
                       const int direction,
                       const double score,
                       const datetime now)
{
   if(SignalConfirmationMode == CONFIRM_LIVE_TICK)
      return true;
   if(SignalConfirmationMode == CONFIRM_BAR_CLOSE)
   {
      return (g_profiles[index].candidate_bar_time > 0 &&
              g_profiles[index].trigger_bar_time > g_profiles[index].candidate_bar_time &&
              MeetsThreshold(score, MinDisplayConfidence));
   }

   double hold = (direction == DIR_UP ?
                  g_profiles[index].composite_up.breakout.hold_score :
                  g_profiles[index].composite_down.breakout.hold_score);

   // The hold-time clause needs a candidate start; without one it was
   // trivially true and silently turned HYBRID into LIVE_TICK.
   return (hold >= 0.35 ||
           MeetsThreshold(score, StrongAlertConfidence) ||
           (g_profiles[index].candidate_start_time > 0 &&
            now - g_profiles[index].candidate_start_time >= MinHoldSecondsForHighScore));
}

// Age after which an event's score is zeroed. A candidate waiting for a bar
// close must outlive that bar; an active signal follows SignalTTLSeconds, or has
// no age limit at all when ExpireOldSignals is off (returned as 0).
int EventAgeLimitSeconds(const int index)
{
   if(g_profiles[index].event_state == STATE_CANDIDATE)
   {
      int limit = SignalTTLSeconds;
      if(SignalConfirmationMode == CONFIRM_BAR_CLOSE)
      {
         int bar_seconds = TimeframeMinutes(g_profiles[index].scan_timeframe) * 60;
         limit = IntMax(limit, bar_seconds + 2 * ScanIntervalSeconds);
      }
      return limit;
   }
   return (ExpireOldSignals ? SignalTTLSeconds : 0);
}

double AgeFreeScore(const int index, const int direction)
{
   if(direction == DIR_UP)
      return g_profiles[index].composite_up.age_free_score;
   if(direction == DIR_DOWN)
      return g_profiles[index].composite_down.age_free_score;
   return 0.0;
}

bool SignalExpiredByContext(const int index, const int direction)
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

bool CanDispatchAlert(const int index)
{
   if(g_profiles[index].correlated_alert_group_id == "")
      return true;
   return g_profiles[index].group_leader_signal;
}

// A signal's group is bound once, when it activates, and kept until it ends.
// Re-deriving it every scan from the instantaneous basket let membership flap
// between scans, which released held alerts and re-elected leaders at random.
void UpdateAlertGroups(const datetime now)
{
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      g_profiles[i].group_leader_signal = false;
      g_profiles[i].group_member_count = 0;
      if(!IsActiveState(g_profiles[i].event_state) || g_profiles[i].active_direction == DIR_NONE)
      {
         g_profiles[i].correlated_alert_group_id = "";
         continue;
      }
      if(g_profiles[i].correlated_alert_group_id == "")
         g_profiles[i].correlated_alert_group_id = DominantCurrencyFlow(i, g_profiles[i].active_direction);
   }

   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(g_profiles[i].correlated_alert_group_id == "")
         continue;

      string group_id = g_profiles[i].correlated_alert_group_id;
      bool already_processed = false;
      for(int prior = 0; prior < i; prior++)
      {
         if(g_profiles[prior].correlated_alert_group_id == group_id)
         {
            already_processed = true;
            break;
         }
      }
      if(already_processed)
         continue;

      int leader = -1;
      double leader_score = -999999.0;
      int members = 0;

      for(int j = 0; j < ArraySize(g_profiles); j++)
      {
         if(g_profiles[j].correlated_alert_group_id != group_id)
            continue;
         members++;
         int member_direction = g_profiles[j].active_direction;
         double candidate = DirectionSortScore(j, member_direction,
                                               EventAgeSeconds(j, member_direction, now));
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

// Group id of a signal: the currency whose basket flow carries the move, in
// the direction it flows. Without a basket reading, or when neither currency
// supports the move, the signal groups only with itself.
string DominantCurrencyFlow(const int index, const int direction)
{
   int base = g_profiles[index].base_index;
   int quote = g_profiles[index].quote_index;
   string own_group = g_profiles[index].symbol + "_" + DirectionText(direction);
   if(!UseCurrencyStrength || base < 0 || quote < 0)
      return own_group;

   bool available = (direction == DIR_UP ?
                     g_profiles[index].composite_up.flow.available :
                     g_profiles[index].composite_down.flow.available);
   if(!available)
      return own_group;

   double base_strength = (direction == DIR_UP ?
                           g_profiles[index].composite_up.flow.base_strength :
                           g_profiles[index].composite_down.flow.base_strength);
   double quote_strength = (direction == DIR_UP ?
                            g_profiles[index].composite_up.flow.quote_strength :
                            g_profiles[index].composite_down.flow.quote_strength);
   // Positive means the currency's own flow pushes the pair in this direction.
   double base_component = base_strength * (double)direction;
   double quote_component = -quote_strength * (double)direction;
   if(base_component <= 0.0 && quote_component <= 0.0)
      return own_group;

   if(base_component >= quote_component)
      return g_currency_codes[base] + (direction == DIR_UP ? "+" : "-");
   return g_currency_codes[quote] + (direction == DIR_UP ? "-" : "+");
}

void UpdateSignalState(const int index, const datetime now)
{
   if(IsActiveState(g_profiles[index].event_state) &&
      g_profiles[index].active_direction != DIR_NONE)
   {
      int current_direction = g_profiles[index].active_direction;
      double current_score = DirectionScore(index, current_direction);
      int opposite_direction = -current_direction;
      double opposite_score = DirectionScore(index, opposite_direction);
      int current_age = EventAgeSeconds(index, current_direction, now);
      bool context_expired = SignalExpiredByContext(index, current_direction);

      bool opposite_allowed = (opposite_direction == DIR_UP ?
                               now >= g_profiles[index].cooldown_end_up :
                               now >= g_profiles[index].cooldown_end_down);
      // A reversal is judged against the running direction's age-free score so
      // the freshness caps on the current event cannot manufacture a flip, and
      // it enters through the normal candidate path so every confirmation mode
      // applies its own rule to it.
      if(opposite_allowed && MeetsThreshold(opposite_score, StrongAlertConfidence) &&
         opposite_score > AgeFreeScore(index, current_direction) + 8.0)
      {
         EndActiveSignal(index, current_direction, now, ValidSignalCooldownSeconds);
         StartCandidate(index, opposite_direction, opposite_score, now);
         return;
      }

      if(ExpireOldSignals && current_age > SignalTTLSeconds)
      {
         EndActiveSignal(index, current_direction, now, ValidSignalCooldownSeconds);
         return;
      }

      if(MeetsThreshold(current_score, MinDisplayConfidence) && !context_expired)
      {
         g_profiles[index].confidence_below_since = 0;
         ActivateSignal(index, current_direction, current_score, now);
         return;
      }

      if(g_profiles[index].confidence_below_since == 0)
         g_profiles[index].confidence_below_since = now;

      if(context_expired ||
         now - g_profiles[index].confidence_below_since >= SIGNAL_DECAY_GRACE_SECONDS)
      {
         int cooldown = (current_age <= SIGNAL_EARLY_COLLAPSE_SECONDS ?
                         FailedSignalCooldownSeconds : ValidSignalCooldownSeconds);
         EndActiveSignal(index, current_direction, now, cooldown);
      }

      return;
   }

   int best_direction = DIR_NONE;
   double best_score = 0.0;
   PickBestDirection(index, now, best_direction, best_score);

   if(best_direction != DIR_NONE && MeetsThreshold(best_score, MinDisplayConfidence))
   {
      if(g_profiles[index].event_state == STATE_CANDIDATE &&
         g_profiles[index].candidate_direction == best_direction)
      {
         if(IsConfirmedSignal(index, best_direction, best_score, now))
         {
            ActivateSignal(index, best_direction, best_score, now);
         }
         return;
      }

      // A candidate abandoned for the other direction failed, and cools down
      // like any other failed candidate before the new one starts.
      if(g_profiles[index].event_state == STATE_CANDIDATE &&
         g_profiles[index].candidate_direction != DIR_NONE &&
         g_profiles[index].candidate_direction != best_direction)
      {
         StartCooldown(index, g_profiles[index].candidate_direction, now, FailedSignalCooldownSeconds);
      }

      StartCandidate(index, best_direction, best_score, now);
      return;
   }

   if(g_profiles[index].event_state == STATE_CANDIDATE &&
      g_profiles[index].candidate_direction != DIR_NONE)
   {
      StartCooldown(index, g_profiles[index].candidate_direction, now, FailedSignalCooldownSeconds);
      g_profiles[index].candidate_direction = DIR_NONE;
      g_profiles[index].candidate_start_time = 0;
      g_profiles[index].candidate_bar_time = 0;
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

   bool up_allowed = (now >= g_profiles[index].cooldown_end_up);
   bool down_allowed = (now >= g_profiles[index].cooldown_end_down);

   if(up_allowed && MeetsThreshold(g_profiles[index].final_score_up, MinDisplayConfidence))
   {
      best_direction = DIR_UP;
      best_score = g_profiles[index].final_score_up;
   }

   if(down_allowed && MeetsThreshold(g_profiles[index].final_score_down, MinDisplayConfidence) &&
      g_profiles[index].final_score_down > best_score)
   {
      best_direction = DIR_DOWN;
      best_score = g_profiles[index].final_score_down;
   }
}

void StartCandidate(const int index,
                    const int direction,
                    const double score,
                    const datetime now)
{
   g_profiles[index].event_state = STATE_CANDIDATE;
   g_profiles[index].candidate_direction = direction;
   g_profiles[index].candidate_start_time = now;
   g_profiles[index].candidate_bar_time = g_profiles[index].trigger_bar_time;

   if(SignalConfirmationMode == CONFIRM_LIVE_TICK)
      ActivateSignal(index, direction, score, now);
}

void ActivateSignal(const int index,
                    const int direction,
                    const double score,
                    const datetime now)
{
   // Confirmation gates entry into the active state. A running signal is
   // re-activated every scan to refresh its score, history row and alerts, and
   // must not be re-gated: its candidate fields were cleared on activation.
   bool new_signal = (!IsActiveState(g_profiles[index].event_state) ||
                      g_profiles[index].active_direction != direction);
   if(new_signal && !IsConfirmedSignal(index, direction, score, now))
      return;

   if(new_signal)
   {
      g_profiles[index].event_start_time = now;
      g_profiles[index].event_local_time = TimeLocal();
      g_profiles[index].strong_alert_handled = false;
      g_profiles[index].correlated_alert_group_id = "";   // bound by UpdateAlertGroups this scan
      PushSignalHistory(index, direction, score, g_profiles[index].event_local_time);
      g_profiles[index].pending_alert = true;
      g_profiles[index].pending_strong_upgrade = MeetsThreshold(score, StrongAlertConfidence);
      g_profiles[index].alert_attempts = 0;
   }
   else if(MeetsThreshold(score, StrongAlertConfidence) && !g_profiles[index].strong_alert_handled)
   {
      UpdateSignalHistory(index, direction, score);
      if(!g_profiles[index].pending_alert)
         g_profiles[index].alert_attempts = 0;
      g_profiles[index].pending_alert = true;
      g_profiles[index].pending_strong_upgrade = true;
   }
   else
   {
      UpdateSignalHistory(index, direction, score);
   }

   g_profiles[index].active_direction = direction;
   g_profiles[index].event_state = STATE_ACTIVE_CONFIRMED;
   g_profiles[index].candidate_direction = DIR_NONE;
   g_profiles[index].candidate_start_time = 0;
   g_profiles[index].candidate_bar_time = 0;
   g_profiles[index].confidence_below_since = 0;
}

void EndActiveSignal(const int index, const int direction, const datetime now, const int cooldown_seconds)
{
   StartCooldown(index, direction, now, cooldown_seconds);
   g_profiles[index].active_direction = DIR_NONE;
   g_profiles[index].event_state = STATE_COOLDOWN;
   g_profiles[index].event_start_time = 0;
   g_profiles[index].event_local_time = 0;
   g_profiles[index].confidence_below_since = 0;
   g_profiles[index].strong_alert_handled = false;
   g_profiles[index].correlated_alert_group_id = "";
   ClearPendingAlert(index);
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

// Returns true only when a channel actually fired, so the rate limiter counts
// deliveries rather than attempts.
bool SendOptionalAlert(const int index,
                       const int direction,
                       const double score,
                       const bool strong_upgrade)
{
   if(!EnableSoundAlert && !EnablePushNotification)
      return false;

   string text = FormatSignalText(index, direction, score);
   string prefix = (strong_upgrade ? "Strong breakout: " : "Breakout radar: ");
   bool delivered = false;

   if(EnableSoundAlert)
   {
      ResetLastError();
      if(PlaySound("alert.wav"))
         delivered = true;
      else
         PrintFormat("FXNews: PlaySound failed, error %d", GetLastError());
   }

   if(EnablePushNotification)
   {
      ResetLastError();
      if(SendNotification(prefix + text))
         delivered = true;
      else
      {
         PrintFormat("FXNews: SendNotification failed for %s %s, error %d",
                     g_profiles[index].symbol,
                     g_profiles[index].timeframe_label,
                     GetLastError());
      }
   }

   return delivered;
}

// Per-profile spacing plus a sliding one-minute window over the last sends.
bool AlertRateLimitAllows(const int index, const datetime now)
{
   if(g_profiles[index].last_alert_attempt_time > 0 &&
      now - g_profiles[index].last_alert_attempt_time < MIN_ALERT_INTERVAL_SECONDS)
   {
      return false;
   }

   int recent = 0;
   for(int i = 0; i < MAX_ALERTS_PER_MINUTE; i++)
   {
      if(g_alert_send_times[i] > 0 && now - g_alert_send_times[i] < 60)
         recent++;
   }
   return (recent < MAX_ALERTS_PER_MINUTE);
}

void RecordAlertSend(const datetime now)
{
   g_alert_send_times[g_alert_send_cursor] = now;
   g_alert_send_cursor = (g_alert_send_cursor + 1) % MAX_ALERTS_PER_MINUTE;
}

void DispatchPendingAlerts(const datetime now)
{
   int sent_this_scan = 0;
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!g_profiles[i].pending_alert)
         continue;
      if(sent_this_scan >= MAX_ALERTS_PER_SCAN)
         break;

      // Defensive: a pending request only exists on an active signal.
      int direction = g_profiles[i].active_direction;
      if(direction == DIR_NONE || !IsActiveState(g_profiles[i].event_state))
      {
         ClearPendingAlert(i);
         continue;
      }

      if(!CanDispatchAlert(i) || !AlertRateLimitAllows(i, now))
      {
         // Rate limited or not the group leader yet. Leave the request pending
         // so the next scan can retry instead of losing the notification.
         continue;
      }

      // The text carries the score at delivery time, and a strong upgrade that
      // has since faded below the strong threshold goes out as a plain alert.
      double current_score = DirectionScore(i, direction);
      bool strong = (g_profiles[i].pending_strong_upgrade &&
                     MeetsThreshold(current_score, StrongAlertConfidence));
      g_profiles[i].alert_attempts++;
      g_profiles[i].last_alert_attempt_time = now;

      if(!SendOptionalAlert(i, direction, current_score, strong))
      {
         if(!EnableSoundAlert && !EnablePushNotification)
         {
            ClearPendingAlert(i);   // no channel: nothing to retry
            continue;
         }
         // Delivery failed: retry after the per-profile interval, a bounded
         // number of times, then give up on this request for good.
         if(g_profiles[i].alert_attempts >= MAX_ALERT_ATTEMPTS)
         {
            PrintFormat("FXNews: giving up on the alert for %s %s after %d failed attempts",
                        g_profiles[i].symbol, g_profiles[i].timeframe_label, g_profiles[i].alert_attempts);
            if(g_profiles[i].pending_strong_upgrade)
               g_profiles[i].strong_alert_handled = true;
            ClearPendingAlert(i);
         }
         continue;
      }

      RecordAlertSend(now);
      sent_this_scan++;
      if(strong)
         g_profiles[i].strong_alert_handled = true;
      ClearPendingAlert(i);
   }
}

void ClearPendingAlert(const int index)
{
   g_profiles[index].pending_alert = false;
   g_profiles[index].pending_strong_upgrade = false;
   g_profiles[index].alert_attempts = 0;
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

// Two label-sized lines: profile and feed counts first, timing second. Every
// slot is a measurement or the state of a switch; "off" means the feature is
// disabled, "no" that it was tried and unavailable.
void BuildDiagnosticsLines(string &line1, string &line2)
{
   string tick_text = (UseCopyTicksForImpulse ? IntegerToString(g_last_tick_history_ok) : "off");
   string calendar_text = (!UseEconomicCalendarContext ? "off" : (g_calendar_available ? "yes" : "no"));
   line1 = StringFormat("DIAG valid=%d invalid=%d profiles=%d active=%d tick_ok=%s cal=%s",
                        g_last_valid_symbols,
                        g_last_invalid_symbols,
                        ArraySize(g_profiles),
                        g_last_active_profiles,
                        tick_text,
                        calendar_text);
   line2 = StringFormat("scan_ewma=%.1fms scan_max=%.1fms baseline=%dmin objects=%d/%d",
                        g_average_scan_ms,
                        g_max_scan_ms,
                        BaselineHorizonMinutes(),
                        CountDashboardObjects(),
                        DASHBOARD_MAX_OBJECTS);
}

string DiagnosticsText()
{
   string line1 = "";
   string line2 = "";
   BuildDiagnosticsLines(line1, line2);
   return line1 + " " + line2;
}

// The baseline is configured in samples but experienced as a duration.
int BaselineHorizonMinutes()
{
   return IntMax(1, (BaselineLookbackSamples * IntMax(1, ScanIntervalSeconds)) / 60);
}

int CountDashboardObjects()
{
   int total = 0;
   for(int row = 0; row < DASHBOARD_MAX_OBJECTS; row++)
   {
      if(ObjectFind(0, DashboardName(row)) >= 0)
         total++;
   }
   return total;
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

int FirstSignalRow()
{
   return (ShowDiagnosticsPanel ? DIAGNOSTICS_ROW_INDEX + DIAGNOSTICS_ROW_COUNT : DIAGNOSTICS_ROW_INDEX);
}

void UpdateDashboard()
{
   string diag_line1 = "";
   string diag_line2 = "";
   BuildDiagnosticsLines(diag_line1, diag_line2);
   SetActivityStatusRow(diag_line1 + " " + diag_line2);
   SetDiagnosticsRows(diag_line1, diag_line2);

   int row = FirstSignalRow();
   int first_row = row;
   int max_row = DashboardSignalRowLimit();

   if(ShowActiveSignalRows)
   {
      DashboardSignal signals[];
      CollectDashboardSignals(signals);
      int ranked = SortDashboardSignalsTopN(signals, max_row - first_row);
      for(int i = 0; i < ranked && row < max_row; i++)
      {
         SetDashboardRow(row, DashboardRowText(signals[i], i + 1), DashboardRowTooltip(signals[i]), clrWhite);
         row++;
      }
   }

   // With active rows disabled this is the only signal display, so it always runs.
   if(row == first_row)
   {
      RefreshVisibleSignalHistoryIfDue();
      for(int i = 0; i < g_visible_signal_history_count && row < max_row; i++)
      {
         SetDashboardRow(row, g_visible_signal_history[i].text, g_visible_signal_history[i].reason, clrWhite);
         row++;
      }
   }

   DeleteDashboardRowsFrom(row);

   ChartRedraw(0);
}

void UpdateActivityStatusLine()
{
   string diag_line1 = "";
   string diag_line2 = "";
   BuildDiagnosticsLines(diag_line1, diag_line2);
   SetActivityStatusRow(diag_line1 + " " + diag_line2);
   SetDiagnosticsRows(diag_line1, diag_line2);
   ChartRedraw(0);
}

void SetActivityStatusRow(const string diagnostics)
{
   string tooltip = diagnostics;
   string status = FirstProfileStatusMessage();
   if(status != "")
      tooltip += "\n" + status;
   SetDashboardRow(STATUS_ROW_INDEX, ActivityStatusText(), tooltip, StatusLineColor());
}

// The diagnostics rows are only ever written while the panel is on; with it
// off the signal rows start at DIAGNOSTICS_ROW_INDEX and overwrite them.
void SetDiagnosticsRows(const string line1, const string line2)
{
   if(!ShowDiagnosticsPanel)
      return;
   SetDashboardRow(DIAGNOSTICS_ROW_INDEX, line1, line1 + " " + line2, clrSilver);
   SetDashboardRow(DIAGNOSTICS_ROW_INDEX + 1, line2, line1 + " " + line2, clrSilver);
}

int DashboardSignalRowLimit()
{
   return IntMin(DASHBOARD_MAX_OBJECTS, FirstSignalRow() + MaxDashboardRows);
}

color StatusLineColor()
{
   long chart_line_color = 0;
   ResetLastError();
   if(ChartGetInteger(0, CHART_COLOR_CHART_LINE, 0, chart_line_color))
      return (color)chart_line_color;
   return clrLime;
}

// The scan counters were permanent clutter on a line the user cannot dismiss.
// They are still available on demand: the full set lives in the status-row
// tooltip and, when ShowDiagnosticsPanel is enabled, on its own row. The only
// thing that surfaces here unprompted is a symbol that failed to refresh,
// because silently hiding that would put the operator back in the dark.
string ActivityStatusText()
{
   string warning = "";
   if(g_last_invalid_symbols > 0)
      warning = StringFormat(" | %d unavailable", g_last_invalid_symbols);

   return StringFormat("FXNews - %s%s | %s",
                       OperatingModeText(),
                       warning,
                       TimeToString(TimeLocal(), TIME_SECONDS));
}

void CollectDashboardSignals(DashboardSignal &signals[])
{
   if(ArrayResize(signals, 0) != 0)
      return;
   datetime now = TimeCurrent();
   for(int i = 0; i < ArraySize(g_profiles); i++)
   {
      if(!IsActiveState(g_profiles[i].event_state) || g_profiles[i].active_direction == DIR_NONE)
      {
         if(!ShowBlockedSignalsDebug)
            continue;
         AddBlockedDebugSignal(i, signals);
         continue;
      }

      if(ShowOnlyGroupLeaders && !g_profiles[i].group_leader_signal)
         continue;

      int direction = g_profiles[i].active_direction;
      if(!MeetsThreshold(DirectionDisplayedScore(i, direction), MinDisplayConfidence))
         continue;

      DashboardSignal signal;
      signal.profile_index = i;
      signal.direction = direction;
      signal.blocked = false;
      signal.age_seconds = EventAgeSeconds(i, direction, now);
      signal.sort_score = DirectionSortScore(i, direction, signal.age_seconds);

      int next = ArraySize(signals);
      if(ArrayResize(signals, next + 1) != next + 1)
         return;
      signals[next] = signal;
   }
}

void AddBlockedDebugSignal(const int index, DashboardSignal &signals[])
{
   int direction = BlockedDebugDirection(index);
   if(direction == DIR_NONE)
      return;

   DashboardSignal signal;
   signal.profile_index = index;
   signal.direction = direction;
   signal.blocked = true;
   signal.age_seconds = 0;
   signal.sort_score = -1000.0;

   int next = ArraySize(signals);
   if(ArrayResize(signals, next + 1) != next + 1)
      return;
   signals[next] = signal;
}

// Both composites carry raw_score 0 while blocked, so the old comparison always
// selected UP and the DOWN block reason was unreachable. Prefer whichever
// direction was actually rejected, and when both were, prefer the one rejected
// later in the pipeline because that reason is the more informative of the two.
int BlockedDebugDirection(const int index)
{
   SignalBlockReason up_reason = g_profiles[index].composite_up.block_reason;
   SignalBlockReason down_reason = g_profiles[index].composite_down.block_reason;
   bool up_blocked = (up_reason != BLOCK_NONE);
   bool down_blocked = (down_reason != BLOCK_NONE);

   if(up_blocked && down_blocked)
      return (BlockStageRank(down_reason) > BlockStageRank(up_reason) ? DIR_DOWN : DIR_UP);
   if(up_blocked)
      return DIR_UP;
   if(down_blocked)
      return DIR_DOWN;
   return DIR_NONE;
}

// Execution-gate rejections are direction independent; the later stages are not.
int BlockStageRank(const SignalBlockReason reason)
{
   if(reason == BLOCK_NONE)
      return -1;
   // Reasons raised after the engines ran are more informative than the
   // direction-independent execution gates that precede them.
   if(reason == BLOCK_NO_MOVEMENT_DATA || reason == BLOCK_CONTEXT_CONFLICT ||
      reason == BLOCK_NO_SETUP || reason == BLOCK_SPREAD_ONLY_BREAKOUT ||
      reason == BLOCK_EXPIRED)
   {
      return 1;
   }
   return 0;
}

// Only the rows that will be drawn need to be ordered, so this selects the top
// `wanted` entries instead of fully sorting every candidate. Returns how many
// leading entries are now in rank order.
int SortDashboardSignalsTopN(DashboardSignal &signals[], const int wanted)
{
   int total = ArraySize(signals);
   int ranked = IntMin(total, IntMax(0, wanted));

   for(int i = 0; i < ranked; i++)
   {
      int best = i;
      for(int j = i + 1; j < total; j++)
      {
         // Ties resolve on the profile index so equal scores keep a stable rank.
         if(signals[j].sort_score > signals[best].sort_score ||
            (signals[j].sort_score == signals[best].sort_score &&
             signals[j].profile_index < signals[best].profile_index))
         {
            best = j;
         }
      }
      if(best != i)
      {
         DashboardSignal tmp = signals[i];
         signals[i] = signals[best];
         signals[best] = tmp;
      }
   }

   return ranked;
}

string DashboardRowText(const DashboardSignal &signal, const int rank)
{
   if(signal.blocked)
      return FormatBlockedDashboardSignalText(signal.profile_index, signal.direction);
   if(signal.direction == DIR_UP)
      return FormatDashboardSignalText(rank, signal.profile_index, signal.direction,
                                       g_profiles[signal.profile_index].composite_up, signal.age_seconds);
   return FormatDashboardSignalText(rank, signal.profile_index, signal.direction,
                                    g_profiles[signal.profile_index].composite_down, signal.age_seconds);
}

string DashboardRowTooltip(const DashboardSignal &signal)
{
   if(signal.direction == DIR_UP)
      return DashboardTooltipFor(signal.profile_index, g_profiles[signal.profile_index].composite_up, signal.blocked);
   return DashboardTooltipFor(signal.profile_index, g_profiles[signal.profile_index].composite_down, signal.blocked);
}

string DashboardTooltipFor(const int index, const CompositeSignalScore &score, const bool blocked)
{
   if(blocked)
      return score.human_reason + "\n" + score.compact_tags;
   return score.human_reason + "\n" + DashboardTooltip(score) +
          "\nsession " + SessionNameFromIndex(g_profiles[index].session_index) +
          " | group " + GroupTagText(index) + " | " + score.compact_tags;
}

double DirectionDisplayedScore(const int index, const int direction)
{
   if(direction == DIR_UP)
      return g_profiles[index].composite_up.displayed_score;
   if(direction == DIR_DOWN)
      return g_profiles[index].composite_down.displayed_score;
   return 0.0;
}

double DirectionSortScore(const int index, const int direction, const int age_seconds)
{
   if(direction == DIR_UP)
      return DashboardSortScore(index, g_profiles[index].composite_up, age_seconds);
   if(direction == DIR_DOWN)
      return DashboardSortScore(index, g_profiles[index].composite_down, age_seconds);
   return 0.0;
}

double DashboardSortScore(const int index,
                          const CompositeSignalScore &score,
                          const int age_seconds)
{
   double leader_bonus = (g_profiles[index].group_leader_signal ? 8.0 : -5.0);
   double freshness = 10.0 * (1.0 - SmoothStep(0.0, (double)SignalTTLSeconds, (double)age_seconds));
   return score.displayed_score + leader_bonus +
          score.execution.score * 8.0 + freshness -
          score.execution.cost_to_atr * 6.0;
}

// Fits the 63-character label budget: rank (with a leader mark), symbol,
// timeframe, direction, score, age, session and tags. Cost, calendar state and
// the correlation group live in the tooltip.
string FormatDashboardSignalText(const int rank,
                                 const int index,
                                 const int direction,
                                 const CompositeSignalScore &score,
                                 const int age_seconds)
{
   string leader_mark = (g_profiles[index].correlated_alert_group_id != "" &&
                         g_profiles[index].group_leader_signal ? "*" : " ");
   string session_text = (ShowSessionOnDashboard ? " " + SessionShortName(g_profiles[index].session_index) : "");
   return StringFormat("%02d%s%-7s %-3s %-4s %3d%% %3ds%s %s",
                       rank,
                       leader_mark,
                       g_profiles[index].symbol,
                       g_profiles[index].timeframe_label,
                       DirectionText(direction),
                       DisplayPercent(score.displayed_score),
                       age_seconds,
                       session_text,
                       score.compact_tags);
}

string GroupTagText(const int index)
{
   if(g_profiles[index].correlated_alert_group_id == "")
      return "none";
   string group_tag = (g_profiles[index].group_leader_signal ? "LEAD:" : "MEM:") +
                      g_profiles[index].correlated_alert_group_id;
   if(g_profiles[index].group_member_count > 1)
      group_tag += "(" + IntegerToString(g_profiles[index].group_member_count) + ")";
   return group_tag;
}

string SessionShortName(const int session_index)
{
   if(session_index == SESSION_ASIA)
      return "ASI";
   if(session_index == SESSION_LONDON)
      return "LON";
   if(session_index == SESSION_NEW_YORK)
      return "NY ";
   if(session_index == SESSION_LONDON_NY_OVERLAP)
      return "OVL";
   if(session_index == SESSION_ROLLOVER)
      return "ROL";
   return "OTH";
}

string FormatBlockedDashboardSignalText(const int index, const int direction)
{
   string session_text = (ShowSessionOnDashboard ? " " + SessionShortName(g_profiles[index].session_index) : "");
   SignalBlockReason reason = (direction == DIR_UP ?
                               g_profiles[index].composite_up.block_reason :
                               g_profiles[index].composite_down.block_reason);
   return StringFormat("-- %-7s %-3s %-4s BLOCKED%s %s",
                       g_profiles[index].symbol,
                       g_profiles[index].timeframe_label,
                       DirectionText(direction),
                       session_text,
                       BlockReasonText(reason));
}

string DashboardTooltip(const CompositeSignalScore &score)
{
   string breakout_text = (score.breakout.measured ? StringFormat("%.2f", score.breakout.score) : "not evaluated");
   string impulse_text = (score.impulse.measured ? StringFormat("%.2f", score.impulse.score) : "not evaluated");
   string flow_text = (score.flow.available ? StringFormat("%.2f", score.flow.score) : "not evaluated");
   return StringFormat("BRK %s | IMP %s | FLOW %s | EXEC %.2f | REG %.2f | cost/ATR %.2f | %s",
                       breakout_text,
                       impulse_text,
                       flow_text,
                       score.execution.score,
                       score.regime.score,
                       score.execution.cost_to_atr,
                       score.calendar.state_tag);
}

void RefreshVisibleSignalHistoryIfDue()
{
   datetime now = TimeLocal();
   if(g_signal_history_dirty ||
      g_last_signal_message_refresh == 0 ||
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
   g_signal_history_dirty = false;
}

bool IsSignalMessageDisplayable(const double score)
{
   return MeetsThreshold(score, RecentListMinScore);
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
   string reason = SignalHistoryReason(index, direction);
   int existing = FindSignalHistoryEntry(symbol, timeframe_label, direction);
   if(existing >= 0)
   {
      MoveSignalHistoryEntryToTop(existing);
      SetSignalHistoryEntry(g_signal_history[0], symbol, timeframe_label, direction, score, local_time, reason);
      g_signal_history_dirty = true;
      return;
   }

   // Entries are held newest-first. Drop the oldest slot that has already met
   // its minimum dwell rather than always dropping the tail, so a burst of new
   // signals cannot sweep a row off the chart seconds after it appeared. If
   // every slot is still within its dwell the tail goes anyway: capacity is a
   // hard bound. Removing a slot from the tail region preserves newest-first
   // order for everything that stays.
   int evict = SIGNAL_HISTORY_SIZE - 1;
   for(int i = SIGNAL_HISTORY_SIZE - 1; i >= 0; i--)
   {
      if(!g_signal_history[i].used ||
         local_time - g_signal_history[i].local_time >= SIGNAL_MESSAGE_MIN_VISIBLE_SECONDS)
      {
         evict = i;
         break;
      }
   }

   for(int i = evict; i > 0; i--)
      CopySignalHistoryEntry(g_signal_history[i - 1], g_signal_history[i]);

   SetSignalHistoryEntry(g_signal_history[0], symbol, timeframe_label, direction, score, local_time, reason);
   g_signal_history_dirty = true;

   if(g_signal_history_count < SIGNAL_HISTORY_SIZE)
      g_signal_history_count++;
}

// The list is a record of events that reached RecentListMinScore. An entry is
// refreshed while its signal stays above that level and keeps its last
// displayable score when the signal fades; it leaves the list only when
// capacity is needed. Removing faded rows and re-inserting them on the next
// displayable scan made rows flicker and broke the newest-first order.
void UpdateSignalHistory(const int index, const int direction, const double score)
{
   datetime local_time = g_profiles[index].event_local_time;
   if(local_time <= 0)
      return;
   if(!IsSignalMessageDisplayable(score))
      return;

   string symbol = g_profiles[index].symbol;
   string timeframe_label = g_profiles[index].timeframe_label;
   int existing = FindSignalHistoryEntry(symbol, timeframe_label, direction);
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
                         g_signal_history[existing].local_time,
                         SignalHistoryReason(index, direction));
}

string SignalHistoryReason(const int index, const int direction)
{
   if(direction == DIR_UP)
      return g_profiles[index].composite_up.human_reason + " | " + g_profiles[index].composite_up.compact_tags;
   return g_profiles[index].composite_down.human_reason + " | " + g_profiles[index].composite_down.compact_tags;
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
   target.reason = source.reason;
}

void SetSignalHistoryEntry(SignalHistoryEntry &entry,
                           const string symbol,
                           const string timeframe_label,
                           const int direction,
                           const double score,
                           const datetime local_time,
                           const string reason)
{
   entry.used = true;
   entry.symbol = symbol;
   entry.timeframe_label = timeframe_label;
   entry.direction = direction;
   entry.local_time = local_time;
   entry.score = score;
   entry.text = FormatSignalHistoryText(symbol, timeframe_label, direction, score, local_time);
   entry.reason = reason;
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
   entry.reason = "";
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

// Creates the label with its static properties once; later updates only touch
// text, tooltip and colour.
bool EnsureDashboardObject(const int row)
{
   if(row < 0 || row >= DASHBOARD_MAX_OBJECTS)
      return false;

   string name = DashboardName(row);
   if(ObjectFind(0, name) >= 0)
      return true;

   ResetLastError();
   if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
   {
      PrintFormat("FXNews: failed to create dashboard object %s, error %d", name, GetLastError());
      return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, DASHBOARD_X_OFFSET);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, DASHBOARD_TOP_OFFSET + row * DASHBOARD_ROW_HEIGHT);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, DASHBOARD_FONT_SIZE);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_FONT, DASHBOARD_FONT_NAME);
   return true;
}

void SetDashboardRow(const int row,
                     const string text,
                     const string tooltip,
                     const color text_color)
{
   if(!EnsureDashboardObject(row))
      return;

   string name = DashboardName(row);
   ResetLastError();
   if(!ObjectSetString(0, name, OBJPROP_TEXT, FitDashboardText(text)))
   {
      if(DebugLogAllowed(TimeCurrent()))
         PrintFormat("FXNews: failed to write dashboard row %d, error %d", row, GetLastError());
      return;
   }
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
}

// Average advance of one character in the dashboard font, measured once from
// the terminal's own text metrics; a fixed fraction of the point size was off
// by about eight percent for Consolas.
double DashboardCharPixels()
{
   if(g_dashboard_char_pixels > 0.0)
      return g_dashboard_char_pixels;

   uint width = 0;
   uint height = 0;
   if(TextSetFont(DASHBOARD_FONT_NAME, -DASHBOARD_FONT_SIZE * 10) &&
      TextGetSize("0123456789", width, height) && width > 0)
   {
      g_dashboard_char_pixels = (double)width / 10.0;
   }
   else
      g_dashboard_char_pixels = (double)DASHBOARD_FONT_SIZE * 0.68;
   return g_dashboard_char_pixels;
}

int DashboardTextLimit()
{
   long chart_width = 0;
   ResetLastError();
   if(!ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0, chart_width) || chart_width <= 0)
      return DASHBOARD_FALLBACK_TEXT_CHARS;

   int available_pixels = (int)chart_width - DASHBOARD_X_OFFSET - DASHBOARD_RIGHT_MARGIN;
   if(available_pixels <= 0)
      return DASHBOARD_MIN_TEXT_CHARS;

   int limit = (int)MathFloor((double)available_pixels / DashboardCharPixels());
   return (int)Clamp((double)limit,
                     (double)DASHBOARD_MIN_TEXT_CHARS,
                     (double)DASHBOARD_MAX_TEXT_CHARS);
}

// The limit is at least DASHBOARD_MIN_TEXT_CHARS, so the ellipsis always fits.
string FitDashboardText(const string text)
{
   int limit = DashboardTextLimit();
   if(StringLen(text) <= limit)
      return text;
   return StringSubstr(text, 0, limit - 3) + "...";
}

// Splits a report line into label-sized pieces at word boundaries; the
// continuation pieces are indented.
int WrapLabelText(const string text, string &pieces[])
{
   if(ArrayResize(pieces, 0) != 0)
      return 0;
   string remaining = text;
   while(StringLen(remaining) > DASHBOARD_MAX_TEXT_CHARS)
   {
      int cut = -1;
      for(int i = DASHBOARD_MAX_TEXT_CHARS; i >= DASHBOARD_MAX_TEXT_CHARS / 2; i--)
      {
         if(StringGetCharacter(remaining, i) == ' ')
         {
            cut = i;
            break;
         }
      }
      if(cut < 0)
         cut = DASHBOARD_MAX_TEXT_CHARS;

      int next = ArraySize(pieces);
      if(ArrayResize(pieces, next + 1) != next + 1)
         return next;
      pieces[next] = StringSubstr(remaining, 0, cut);
      string rest = StringSubstr(remaining, cut);
      StringTrimLeft(rest);
      remaining = "  " + rest;
   }
   int last = ArraySize(pieces);
   if(ArrayResize(pieces, last + 1) == last + 1)
      pieces[last] = remaining;
   return ArraySize(pieces);
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
   int confidence = (int)MathRound(Clamp(score, 0.0, 100.0));
   string tags = (direction == DIR_UP ?
                  g_profiles[index].composite_up.compact_tags :
                  g_profiles[index].composite_down.compact_tags);
   return StringFormat("%s %s %s %d%% %s",
                       g_profiles[index].symbol,
                       g_profiles[index].timeframe_label,
                       DirectionText(direction),
                       confidence,
                       tags);
}

string FormatSignalHistoryText(const string symbol,
                               const string timeframe_label,
                               const int direction,
                               const double score,
                               const datetime local_time)
{
   return StringFormat("%s - %s %s %s %3d%%",
                       FormatLocalTimestamp(local_time),
                       PadRight(symbol, 10),
                       PadRight(timeframe_label, 3),
                       PadRight(DirectionText(direction), 4),
                       DisplayPercent(score));
}

string PadRight(const string value, const int width)
{
   string result = value;
   while(StringLen(result) < width)
      result += " ";
   return result;
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
   return g_profiles[index].breakout_buffer_price;
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

double ContinuationScore(const int index, const int direction, bool &available)
{
   available = false;
   if(g_profiles[index].snapshot_count < 3 || !SnapshotWindowCovered(index, 30))
      return 0.0;

   double old_mid = ReferenceMid(index, 30);
   if(old_mid <= 0.0)
      return 0.0;

   available = true;

   double extreme = RecentExtremeMid(index, 30, direction);
   double move_to_extreme = (extreme - old_mid) * (double)direction;
   double retrace = (extreme - g_profiles[index].mid) * (double)direction;

   if(move_to_extreme <= 0.0)
      return 0.0;

   double retained = 1.0 - retrace / move_to_extreme;
   double retention_score = LinearScore(retained, 0.35, 0.90);
   double short_push = LinearScore(DirectionalValue(g_profiles[index].speed_5s_pips, direction), 0.0,
                                  MathMax(g_profiles[index].atr_trigger / g_profiles[index].pip_size * 0.12, 0.4));
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

// Sample quality is a measurement of the CopyTicks window; on every path that
// cannot measure it the profile is left unmeasured (tick_quality_available
// false) instead of carrying an assumed quality into the impulse score.
void UpdateTickQuality(const int index)
{
   // The reading is a pure function of the tick window ending at the current
   // quote, so it is recomputed only when a new quote has arrived.
   if(g_profiles[index].tick_quality_stamp_msc > 0 &&
      g_profiles[index].tick_quality_stamp_msc == g_profiles[index].quote_time_msc)
   {
      return;
   }
   g_profiles[index].tick_quality_stamp_msc = g_profiles[index].quote_time_msc;

   g_profiles[index].tick_quality_available = false;
   g_profiles[index].tick_sample_quality_score = 0.0;
   g_profiles[index].valid_ticks_used = 0;
   g_profiles[index].tick_state = "TICK_SYNCING";

   if(!UseCopyTicksForImpulse)
   {
      g_profiles[index].tick_state = (g_profiles[index].quote_fresh ? "TICK_OK" : "TICK_STALE");
      return;
   }

   if(g_profiles[index].quote_time_msc <= 0)
   {
      g_profiles[index].tick_state = "TICK_STALE";
      return;
   }

   if(ReuseTickQualityFromSibling(index))
      return;

   long from_msc = MathMax(0, g_profiles[index].quote_time_msc - (long)CopyTicksLookbackSeconds * 1000);
   ResetLastError();
   // With a non-zero start time CopyTicks returns the OLDEST ticks after it, so
   // a burst denser than MAX_COPY_TICKS per window would drop the newest ticks
   // and read as stale exactly when activity peaks. Request the newest ticks
   // and discard the ones that fall before the window instead.
   int copied = CopyTicks(g_profiles[index].symbol, g_ticks_scratch, COPY_TICKS_INFO, 0, MAX_COPY_TICKS);
   if(copied <= 0)
   {
      g_profiles[index].tick_state = "TICK_SYNCING";
      return;
   }

   int valid = 0;
   long newest = 0;
   long oldest = 0;
   for(int i = 0; i < copied; i++)
   {
      if(g_ticks_scratch[i].bid <= 0.0 || g_ticks_scratch[i].ask <= 0.0 ||
         g_ticks_scratch[i].ask < g_ticks_scratch[i].bid)
      {
         continue;
      }
      if((g_ticks_scratch[i].flags & (TICK_FLAG_BID | TICK_FLAG_ASK | TICK_FLAG_LAST)) == 0)
         continue;
      long tick_time = (long)g_ticks_scratch[i].time_msc;
      if(tick_time <= 0)
         tick_time = (long)g_ticks_scratch[i].time * 1000;
      if(tick_time <= 0 || tick_time < from_msc)
         continue;
      if(oldest <= 0)
         oldest = tick_time;
      newest = tick_time;
      valid++;
   }

   g_profiles[index].valid_ticks_used = valid;
   if(valid <= 0)
   {
      g_profiles[index].tick_state = "TICK_STALE";
      return;
   }

   double age_sec = MathMax(0.0, (double)(g_profiles[index].quote_time_msc - newest) / 1000.0);
   double coverage_sec = MathMax(1.0, (double)(newest - oldest) / 1000.0);
   // The true tick rate replaces the coarse snapshot-count fallback.
   if(valid >= 2)
   {
      g_profiles[index].tick_rate_per_sec = (double)valid / coverage_sec;
      g_profiles[index].tick_rate_available = true;
   }
   g_profiles[index].tick_quality_available = true;
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
   string target = g_profiles[index].symbol_upper;
   for(int i = index - 1; i >= 0; i--)
   {
      if(g_profiles[i].symbol_upper != target)
         continue;
      if(g_profiles[i].quote_time_msc <= 0 ||
         g_profiles[i].quote_time_msc != g_profiles[index].quote_time_msc ||
         g_profiles[i].tick_quality_stamp_msc != g_profiles[index].quote_time_msc)
      {
         continue;
      }

      g_profiles[index].tick_quality_available = g_profiles[i].tick_quality_available;
      g_profiles[index].tick_sample_quality_score = g_profiles[i].tick_sample_quality_score;
      g_profiles[index].valid_ticks_used = g_profiles[i].valid_ticks_used;
      g_profiles[index].tick_state = g_profiles[i].tick_state;
      if(g_profiles[i].tick_rate_available)
      {
         g_profiles[index].tick_rate_available = true;
         g_profiles[index].tick_rate_per_sec = g_profiles[i].tick_rate_per_sec;
      }
      return true;
   }

   return false;
}

// Coarse fallback: new snapshots per second over a covered window. It counts
// scan samples, so it is capped by the scan interval and only stands in until
// CopyTicks provides the true rate.
bool TickRateFromSnapshots(const int index, const int seconds_back, double &rate)
{
   rate = 0.0;
   int count = g_profiles[index].snapshot_count;
   if(count < 2 || seconds_back <= 0 || !SnapshotWindowCovered(index, seconds_back))
      return false;

   long min_time = g_profiles[index].quote_time_msc - (long)seconds_back * 1000;
   int observed = 0;
   for(int logical = 0; logical < count; logical++)
   {
      int position = LogicalSnapshotPosition(index, logical);
      int sample_index = SnapshotIndex(index, position);
      long sample_time = g_snapshots[sample_index].time_msc;
      if(sample_time < min_time || sample_time <= 0)
         continue;
      observed++;
   }

   if(observed < 2)
      return false;

   rate = (double)(observed - 1) / (double)seconds_back;
   return true;
}

int SpeedWindowSlot(const int seconds_back)
{
   for(int window = 0; window < SPEED_WINDOW_COUNT; window++)
   {
      if(g_speed_window_seconds[window] == seconds_back)
         return window;
   }
   return -1;
}

bool SpeedWindowReady(const int index, const int seconds_back)
{
   int window = SpeedWindowSlot(seconds_back);
   return (window >= 0 && g_profiles[index].speed_baseline_ready[window] &&
           SnapshotWindowCovered(index, seconds_back));
}

// Seconds spanned by the snapshot ring; a window longer than this has no
// reference sample and is unmeasured.
int SnapshotCoverageSeconds(const int index)
{
   if(g_profiles[index].snapshot_count <= 0)
      return 0;
   int oldest = SnapshotIndex(index, LogicalSnapshotPosition(index, 0));
   if(g_snapshots[oldest].time_msc <= 0)
      return 0;
   long span_msc = g_profiles[index].quote_time_msc - g_snapshots[oldest].time_msc;
   return (int)MathMax(0, span_msc / 1000);
}

bool SnapshotWindowCovered(const int index, const int seconds_back)
{
   return (g_profiles[index].snapshot_coverage_sec >= seconds_back);
}

double SpeedRobustZ(const int index, const int direction, const int seconds_back)
{
   int window = SpeedWindowSlot(seconds_back);
   if(window < 0 || g_profiles[index].pip_size <= 0.0 || !SpeedWindowReady(index, seconds_back))
      return 0.0;

   double directional_rate = DirectionalValue(MovementPips(index, seconds_back), direction) / (double)seconds_back;
   double atr_pips = MathMax(g_profiles[index].atr_trigger / g_profiles[index].pip_size, 0.1);
   // A quiet ring can have zero dispersion; the ATR-based floor keeps a sudden
   // move measurable without letting a degenerate MAD saturate the z.
   double sigma_floor = MathMax(atr_pips / 600.0, 0.01);

   // The baseline is the SIGNED window-rate distribution. Flipping its median
   // by the direction is exact, because median(-x) == -median(x) and the
   // absolute deviation is unchanged by the sign flip.
   double directional_median = (double)direction * g_profiles[index].speed_median_rate[window];
   return RobustZ(directional_rate, directional_median, g_profiles[index].speed_mad_rate[window], sigma_floor);
}

// Direction independent and identical for every lookback, so this runs once per
// profile per scan instead of once per speed per direction.
// One robust baseline per speed window, built from the rates of every
// same-length window the ring holds, so a 30 s measurement is scored against
// 30 s window rates rather than against 2 s interval rates.
void UpdateSnapshotRateStats(const int index)
{
   for(int window = 0; window < SPEED_WINDOW_COUNT; window++)
   {
      g_profiles[index].speed_baseline_ready[window] = false;
      g_profiles[index].speed_median_rate[window] = 0.0;
      g_profiles[index].speed_mad_rate[window] = 0.0;
   }

   int count = g_profiles[index].snapshot_count;
   if(count < 3 || g_profiles[index].pip_size <= 0.0)
      return;

   for(int window = 0; window < SPEED_WINDOW_COUNT; window++)
   {
      int window_seconds = g_speed_window_seconds[window];
      long window_msc = (long)window_seconds * 1000;
      if(!PrepareScratch(g_rate_scratch, count, SNAPSHOT_CAPACITY))
         return;

      int added = 0;
      int reference = 0;
      for(int logical = 1; logical < count; logical++)
      {
         int curr_index = SnapshotIndex(index, LogicalSnapshotPosition(index, logical));
         long target = g_snapshots[curr_index].time_msc - window_msc;
         // Advance to the latest sample at or before the window start.
         while(reference + 1 < logical &&
               g_snapshots[SnapshotIndex(index, LogicalSnapshotPosition(index, reference + 1))].time_msc <= target)
         {
            reference++;
         }
         int ref_index = SnapshotIndex(index, LogicalSnapshotPosition(index, reference));
         if(g_snapshots[ref_index].time_msc > target || g_snapshots[ref_index].time_msc <= 0)
            continue;   // the ring does not reach back a full window here yet

         double pips = (g_snapshots[curr_index].mid - g_snapshots[ref_index].mid) /
                       g_profiles[index].pip_size;
         g_rate_scratch[added] = pips / (double)window_seconds;
         added++;
      }

      if(added < 3 || !PrepareScratch(g_rate_scratch, added, SNAPSHOT_CAPACITY))
         continue;

      double median = MedianOfArray(g_rate_scratch, added);
      g_profiles[index].speed_median_rate[window] = median;
      g_profiles[index].speed_mad_rate[window] = MedianAbsDeviationInto(g_mad_scratch, g_rate_scratch,
                                                                       added, median, SNAPSHOT_CAPACITY);
      g_profiles[index].speed_baseline_ready[window] = true;
   }
}

// Tick-rate deviation: the session baseline z where one exists, else the
// deviation from TickRateBaselinePerSec. An unmeasured rate reports
// unavailable rather than a sentinel that reads as negative evidence.
double TickRateZ(const int index, bool &available)
{
   available = false;
   if(!g_profiles[index].tick_rate_available)
      return 0.0;

   available = true;
   if(UseSessionAwareBaselines && g_profiles[index].session_tick_rate_z_ready)
      return g_profiles[index].session_tick_rate_z;

   // FX tick feeds differ by broker, so the flat baseline is configurable.
   return (g_profiles[index].tick_rate_per_sec - TickRateBaselinePerSec) / TickRateBaselinePerSec;
}

// Tick-volume deviation: the session baseline z where one exists, else the
// projected bar volume's ratio to the recent average, scaled by
// TickVolumeRatioScale. It is a scaled ratio, not a robust z.
double TickVolumeDeviation(const int index, bool &available)
{
   available = false;
   if(UseSessionAwareBaselines && g_profiles[index].session_tick_volume_z_ready)
   {
      available = true;
      return g_profiles[index].session_tick_volume_z;
   }

   double average_volume = g_profiles[index].average_trigger_tick_volume;
   double active_volume = g_profiles[index].active_trigger_tick_volume;
   if(average_volume <= 0.0 || active_volume <= 0.0)
      return 0.0;

   // FX has no centralized real volume, so tick_volume is the practical default.
   available = true;
   return (active_volume / average_volume - 1.0) / TickVolumeRatioScale;
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

   // No sample at or before the window start means the window is not covered;
   // reporting the oldest sample instead measured a shorter span than asked for.
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

string ObjectNamespaceToken(const string requested)
{
   string token = requested;
   if(token == "")
      token = StringFormat("%u", GetTickCount());
   for(int i = 0; i < StringLen(token); i++)
   {
      ushort ch = StringGetCharacter(token, i);
      bool allowed = ((ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) ||
                      (ch >= 48 && ch <= 57) || ch == 95);
      if(!allowed)
         StringSetCharacter(token, i, '_');
   }
   return token;
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

   // A reversed pair would silently invert the ramp and reward evidence against
   // the signal, so orient the edges before interpolating.
   double low = MathMin(edge0, edge1);
   double high = MathMax(edge0, edge1);
   double t = Clamp01((x - low) / (high - low));
   return t * t * (3.0 - 2.0 * t);
}

double SafeDiv(const double numerator, const double denominator, const double fallback)
{
   if(MathAbs(denominator) <= 0.0000000001)
      return fallback;
   return numerator / denominator;
}

// ArraySort orders an entire array, so a scratch buffer is resized to exactly the
// working set before sorting. ArrayResize keeps the reserve it was allocated with,
// so shrinking and regrowing between scans does not reallocate.
bool PrepareScratch(double &buffer[], const int count, const int reserve)
{
   return (count > 0 && count <= reserve && ArrayResize(buffer, count, reserve) == count);
}

double MedianAbsDeviationInto(double &deviations[],
                              double &values[],
                              const int count,
                              const double median,
                              const int reserve)
{
   if(!PrepareScratch(deviations, count, reserve))
      return 0.0;
   for(int i = 0; i < count; i++)
      deviations[i] = MathAbs(values[i] - median);
   return MedianOfArray(deviations, count);
}

// Sorts the caller's array in place; the array must hold exactly count values
// because ArraySort orders the whole array.
double MedianOfArray(double &values[], const int count)
{
   if(count <= 0)
      return 0.0;
   if(ArraySize(values) != count)
   {
      PrintFormat("FXNews: MedianOfArray called with %d values for a count of %d", ArraySize(values), count);
      return 0.0;
   }

   ArraySort(values);
   if((count % 2) == 1)
      return values[count / 2];
   return (values[count / 2 - 1] + values[count / 2]) * 0.5;
}

double MedianAbsDeviation(double &values[], const int count, const double median)
{
   return MedianAbsDeviationInto(g_mad_scratch, values, count, median, IntMax(count, SNAPSHOT_CAPACITY));
}

// Robust z-score. sigma_floor lets a caller that knows the natural scale of its
// measurement (the speed windows use the ATR) keep a sudden move measurable on a
// ring whose dispersion happens to be zero; without a floor, degenerate
// dispersion carries no information and the z is 0, never a saturating value.
double RobustZ(const double value, const double median, const double mad, const double sigma_floor = 0.0)
{
   double denominator = MathMax(mad * MAD_TO_SIGMA, sigma_floor);
   if(denominator <= 0.0000001)
      return 0.0;

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
