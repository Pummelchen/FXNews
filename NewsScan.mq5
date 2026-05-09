#property strict
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0
#property description "Multi-currency news impact outbreak scanner for manual MT5 trading."

input string InpSymbols = "EURUSD,GBPUSD,USDJPY,USDCHF,USDCAD,AUDUSD,NZDUSD,EURGBP,EURJPY,EURCHF,EURCAD,EURAUD,EURNZD,GBPJPY,GBPCHF,GBPCAD,GBPAUD,GBPNZD,AUDJPY,AUDCHF,AUDCAD,AUDNZD,NZDJPY,NZDCHF,NZDCAD,CADJPY,CADCHF,CHFJPY,USDSEK,USDNOK,USDDKK,USDPLN,USDHUF,USDCZK,USDTRY,USDZAR,USDMXN,USDSGD,USDHKD,USDTHB,USDCNH,EURSEK,EURNOK,EURDKK,EURPLN,EURHUF,EURCZK,EURTRY,EURZAR,GBPSEK,GBPNOK,GBPPLN,GBPTRY,GBPZAR,AUDSGD";
input string InpSymbolSuffix = "";
input int InpScanMilliseconds = 250;
input int InpLookbackSeconds = 12;
input int InpMinimumWindowSeconds = 4;
input int InpMinimumSamples = 6;
input ENUM_TIMEFRAMES InpAtrTimeframe = PERIOD_M1;
input int InpAtrPeriod = 14;
input int InpAtrRefreshSeconds = 10;
input double InpFallbackAtrPoints = 80.0;
input double InpMinimumMovePoints = 25.0;
input double InpMoveAtrFraction = 0.32;
input double InpBreakoutAtrFraction = 0.12;
input double InpMinimumBreakoutPoints = 8.0;
input double InpVelocityAtrFractionPerSecond = 0.018;
input double InpMinimumVelocityPointsPerSecond = 2.0;
input double InpNoiseMoveMultiplier = 9.0;
input double InpNoiseStepMultiplier = 4.0;
input double InpMinimumStepPoints = 5.0;
input double InpSpreadMoveMultiplier = 4.0;
input double InpSpreadBreakoutMultiplier = 1.5;
input double InpMaximumSpreadAtrFraction = 0.55;
input double InpMaximumSpreadPoints = 120.0;
input bool InpRejectExtremeSpread = true;
input double InpMinimumDirectionRatio = 0.58;
input double InpScoreTrigger = 1.20;
input int InpSignalHoldSeconds = 90;
input bool InpUseTerminalAlert = false;
input int InpTerminalAlertCooldownSeconds = 30;
input int InpMaxRowsDisplayed = 8;
input ENUM_BASE_CORNER InpCorner = CORNER_LEFT_UPPER;
input int InpXOffset = 12;
input int InpYOffset = 24;
input int InpRowSpacing = 18;
input int InpFontSize = 10;
input string InpFontName = "Consolas";
input color InpAlertColor = clrRed;
input color InpNeutralColor = clrSilver;
input color InpWarningColor = clrTomato;

struct TickSample
{
   long time_msc;
   double mid;
};

struct SymbolState
{
   string symbol;
   bool enabled;
   int atr_handle;
   double point;
   int digits;
   double atr_points;
   datetime last_atr_refresh;
   long last_tick_msc;
   double last_mid;
   double noise_step_ema;
   int write_index;
   int sample_count;
   datetime alert_until;
   int alert_direction;
   double alert_score;
   double alert_move_points;
   double alert_spread_points;
   double alert_window_seconds;
   string alert_message;
   datetime last_terminal_alert;
   string status_message;
};

SymbolState g_states[];
TickSample g_samples[];
int g_sample_capacity = 0;
int g_labels_allocated = 0;
uint g_last_scan_tick = 0;
datetime g_last_render = 0;
string g_prefix = "NIS_";

int OnInit()
{
   g_prefix = "NIS_" + IntegerToString((long)GetTickCount()) + "_";

   if(InpScanMilliseconds < 50)
   {
      Print("NewsScan: InpScanMilliseconds must be at least 50.");
      return INIT_PARAMETERS_INCORRECT;
   }

   if(InpLookbackSeconds < 2 || InpMinimumWindowSeconds < 1 || InpMinimumSamples < 2 ||
      InpAtrPeriod < 1 || InpAtrRefreshSeconds < 1 || InpSignalHoldSeconds < 1)
   {
      Print("NewsScan: lookback/window/sample/ATR/hold inputs are outside the supported range.");
      return INIT_PARAMETERS_INCORRECT;
   }

   if(InpFontSize < 6 || InpRowSpacing < InpFontSize + 2)
   {
      Print("NewsScan: display font size and row spacing would overlap.");
      return INIT_PARAMETERS_INCORRECT;
   }

   ArrayResize(g_states, 0);
   if(ParseSymbols() <= 0)
   {
      Print("NewsScan: no valid symbols were provided.");
      return INIT_PARAMETERS_INCORRECT;
   }

   g_sample_capacity = IntMax(16, IntMin(512, (InpLookbackSeconds * 1000) / InpScanMilliseconds + 8));
   ArrayResize(g_samples, ArraySize(g_states) * g_sample_capacity);
   ClearSamples();

   PrepareSymbols();
   if(CountEnabledSymbols() <= 0)
   {
      Print("NewsScan: none of the configured symbols could be enabled.");
      return INIT_FAILED;
   }

   RenderPanel(true);

   ResetLastError();
   if(!EventSetMillisecondTimer(InpScanMilliseconds))
   {
      int error_code = GetLastError();
      PrintFormat("NewsScan: EventSetMillisecondTimer(%d) failed, falling back to 1 second timer. Error %d",
                  InpScanMilliseconds, error_code);
      EventSetTimer(1);
   }

   ScanAll(true);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();

   for(int i = 0; i < ArraySize(g_states); i++)
   {
      if(g_states[i].atr_handle != INVALID_HANDLE)
         IndicatorRelease(g_states[i].atr_handle);
   }

   DeletePanelObjects();
}

void OnTimer()
{
   ScanAll(true);
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
   ScanAll(false);
   return rates_total;
}

int ParseSymbols()
{
   string cleaned = InpSymbols;
   StringReplace(cleaned, ";", ",");
   StringReplace(cleaned, "\r", ",");
   StringReplace(cleaned, "\n", ",");

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

      string symbol = token;
      if(InpSymbolSuffix != "" && !StringEndsWith(symbol, InpSymbolSuffix))
         symbol += InpSymbolSuffix;

      if(SymbolAlreadyAdded(symbol))
         continue;

      int next = ArraySize(g_states);
      ArrayResize(g_states, next + 1);
      ResetSymbolState(next, symbol);
   }

   return ArraySize(g_states);
}

void ResetSymbolState(const int index, const string symbol)
{
   g_states[index].symbol = symbol;
   g_states[index].enabled = false;
   g_states[index].atr_handle = INVALID_HANDLE;
   g_states[index].point = 0.0;
   g_states[index].digits = 0;
   g_states[index].atr_points = 0.0;
   g_states[index].last_atr_refresh = 0;
   g_states[index].last_tick_msc = 0;
   g_states[index].last_mid = 0.0;
   g_states[index].noise_step_ema = 0.0;
   g_states[index].write_index = 0;
   g_states[index].sample_count = 0;
   g_states[index].alert_until = 0;
   g_states[index].alert_direction = 0;
   g_states[index].alert_score = 0.0;
   g_states[index].alert_move_points = 0.0;
   g_states[index].alert_spread_points = 0.0;
   g_states[index].alert_window_seconds = 0.0;
   g_states[index].alert_message = "";
   g_states[index].last_terminal_alert = 0;
   g_states[index].status_message = "";
}

bool SymbolAlreadyAdded(const string symbol)
{
   for(int i = 0; i < ArraySize(g_states); i++)
   {
      if(g_states[i].symbol == symbol)
         return true;
   }
   return false;
}

bool StringEndsWith(const string value, const string suffix)
{
   int value_len = StringLen(value);
   int suffix_len = StringLen(suffix);
   if(suffix_len <= 0)
      return true;
   if(value_len < suffix_len)
      return false;
   return StringSubstr(value, value_len - suffix_len, suffix_len) == suffix;
}

void PrepareSymbols()
{
   for(int i = 0; i < ArraySize(g_states); i++)
   {
      string symbol = g_states[i].symbol;

      ResetLastError();
      if(!SymbolSelect(symbol, true))
      {
         g_states[i].status_message = StringFormat("%s unavailable, SymbolSelect error %d", symbol, GetLastError());
         Print("NewsScan: " + g_states[i].status_message);
         continue;
      }

      g_states[i].point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      g_states[i].digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      if(g_states[i].point <= 0.0)
      {
         g_states[i].status_message = symbol + " has invalid point size.";
         Print("NewsScan: " + g_states[i].status_message);
         continue;
      }

      g_states[i].atr_handle = iATR(symbol, InpAtrTimeframe, InpAtrPeriod);
      if(g_states[i].atr_handle == INVALID_HANDLE)
      {
         g_states[i].status_message = StringFormat("%s ATR handle failed, using fallback thresholds. Error %d",
                                                   symbol, GetLastError());
         Print("NewsScan: " + g_states[i].status_message);
      }

      g_states[i].enabled = true;
      RefreshAtr(i, true);
   }
}

void ClearSamples()
{
   for(int i = 0; i < ArraySize(g_samples); i++)
   {
      g_samples[i].time_msc = 0;
      g_samples[i].mid = 0.0;
   }
}

void ScanAll(const bool force)
{
   uint now_tick = GetTickCount();
   uint min_gap = (uint)IntMax(25, InpScanMilliseconds / 2);
   if(!force && g_last_scan_tick != 0 && now_tick - g_last_scan_tick < min_gap)
      return;

   g_last_scan_tick = now_tick;

   datetime now = TimeCurrent();
   for(int i = 0; i < ArraySize(g_states); i++)
   {
      if(IsStopped())
         break;
      ScanSymbol(i, now);
   }

   RenderPanel(false);
}

void ScanSymbol(const int index, const datetime now)
{
   if(!g_states[index].enabled)
      return;

   string symbol = g_states[index].symbol;
   MqlTick tick;
   ResetLastError();
   if(!SymbolInfoTick(symbol, tick))
   {
      g_states[index].status_message = StringFormat("%s tick read failed, error %d", symbol, GetLastError());
      return;
   }

   if(tick.bid <= 0.0 || tick.ask <= 0.0 || tick.ask < tick.bid)
      return;

   long tick_msc = (long)tick.time_msc;
   if(tick_msc <= 0)
      tick_msc = (long)tick.time * 1000;

   if(g_states[index].last_tick_msc == tick_msc)
      return;

   double mid = (tick.bid + tick.ask) * 0.5;
   double spread_points = (tick.ask - tick.bid) / g_states[index].point;
   double step_points = 0.0;
   bool has_previous_tick = (g_states[index].last_tick_msc > 0 && g_states[index].last_mid > 0.0);
   if(has_previous_tick)
      step_points = MathAbs(mid - g_states[index].last_mid) / g_states[index].point;

   AddSample(index, tick_msc, mid);
   RefreshAtr(index, false);

   if(has_previous_tick)
      EvaluateOutbreak(index, tick_msc, mid, spread_points, step_points, now);

   UpdateNoise(index, step_points);
   g_states[index].last_tick_msc = tick_msc;
   g_states[index].last_mid = mid;
}

void AddSample(const int index, const long time_msc, const double mid)
{
   int position = g_states[index].write_index;
   int sample_index = SampleIndex(index, position);
   g_samples[sample_index].time_msc = time_msc;
   g_samples[sample_index].mid = mid;

   g_states[index].write_index = (position + 1) % g_sample_capacity;
   if(g_states[index].sample_count < g_sample_capacity)
      g_states[index].sample_count++;
}

int SampleIndex(const int symbol_index, const int position)
{
   return symbol_index * g_sample_capacity + position;
}

int LogicalSamplePosition(const int symbol_index, const int logical_index)
{
   int count = g_states[symbol_index].sample_count;
   int start = g_states[symbol_index].write_index - count;
   while(start < 0)
      start += g_sample_capacity;
   return (start + logical_index) % g_sample_capacity;
}

void RefreshAtr(const int index, const bool force)
{
   if(g_states[index].atr_handle == INVALID_HANDLE)
      return;

   datetime now = TimeCurrent();
   if(!force && g_states[index].atr_points > 0.0 && now - g_states[index].last_atr_refresh < InpAtrRefreshSeconds)
      return;

   double atr_buffer[];
   ArrayResize(atr_buffer, 1);
   ResetLastError();
   int copied = CopyBuffer(g_states[index].atr_handle, 0, 1, 1, atr_buffer);
   if(copied != 1 || atr_buffer[0] <= 0.0)
      copied = CopyBuffer(g_states[index].atr_handle, 0, 0, 1, atr_buffer);

   if(copied == 1 && atr_buffer[0] > 0.0)
   {
      g_states[index].atr_points = atr_buffer[0] / g_states[index].point;
      g_states[index].last_atr_refresh = now;
   }
}

void UpdateNoise(const int index, const double step_points)
{
   if(step_points <= 0.0)
      return;

   double current_noise = g_states[index].noise_step_ema;
   if(current_noise <= 0.0)
   {
      g_states[index].noise_step_ema = step_points;
      return;
   }

   double capped_step = MathMin(step_points, current_noise * 4.0 + 1.0);
   g_states[index].noise_step_ema = current_noise * 0.97 + capped_step * 0.03;
}

void EvaluateOutbreak(const int index,
                      const long now_msc,
                      const double mid,
                      const double spread_points,
                      const double step_points,
                      const datetime now)
{
   double old_mid = 0.0;
   long old_msc = 0;
   double previous_high = 0.0;
   double previous_low = 0.0;
   int samples = 0;
   int up_changes = 0;
   int down_changes = 0;
   int changing_ticks = 0;

   if(!BuildWindowStats(index, now_msc, old_mid, old_msc, previous_high, previous_low,
                        samples, up_changes, down_changes, changing_ticks))
      return;

   double window_seconds = (double)(now_msc - old_msc) / 1000.0;
   if(window_seconds < (double)InpMinimumWindowSeconds)
      return;

   double point = g_states[index].point;
   double move_points = (mid - old_mid) / point;
   double abs_move_points = MathAbs(move_points);
   int direction = (move_points > 0.0 ? 1 : -1);
   double velocity_points = abs_move_points / window_seconds;
   double atr_points = EffectiveAtrPoints(index, spread_points);
   double noise_points = MathMax(g_states[index].noise_step_ema, 0.5);

   double move_threshold = Max3(InpMinimumMovePoints,
                                atr_points * InpMoveAtrFraction,
                                spread_points * InpSpreadMoveMultiplier);
   move_threshold = MathMax(move_threshold, noise_points * InpNoiseMoveMultiplier);

   double breakout_threshold = Max3(InpMinimumBreakoutPoints,
                                    atr_points * InpBreakoutAtrFraction,
                                    spread_points * InpSpreadBreakoutMultiplier);

   double velocity_threshold = MathMax(InpMinimumVelocityPointsPerSecond,
                                       atr_points * InpVelocityAtrFractionPerSecond);

   double breakout_points = 0.0;
   if(direction > 0)
      breakout_points = (mid - previous_high) / point;
   else
      breakout_points = (previous_low - mid) / point;
   breakout_points = MathMax(0.0, breakout_points);

   double direction_ratio = 1.0;
   if(changing_ticks > 0)
   {
      int directional_ticks = (direction > 0 ? up_changes : down_changes);
      direction_ratio = (double)directional_ticks / (double)changing_ticks;
   }

   bool spread_extreme = (spread_points > MathMax(InpMaximumSpreadPoints, atr_points * InpMaximumSpreadAtrFraction));
   bool enough_move = (abs_move_points >= move_threshold);
   bool enough_velocity = (velocity_points >= velocity_threshold);
   bool enough_direction = (direction_ratio >= InpMinimumDirectionRatio || changing_ticks <= 2);
   bool breakout = (breakout_points >= breakout_threshold);
   bool step_shock = (step_points >= MathMax(InpMinimumStepPoints, noise_points * InpNoiseStepMultiplier));

   double move_score = SafeRatio(abs_move_points, move_threshold);
   double velocity_score = SafeRatio(velocity_points, velocity_threshold);
   double breakout_score = SafeRatio(breakout_points, breakout_threshold);
   double direction_score = SafeRatio(direction_ratio, InpMinimumDirectionRatio);
   double score = move_score * 0.45 + velocity_score * 0.25 + breakout_score * 0.20 + direction_score * 0.10;
   if(spread_extreme)
      score *= 0.85;

   bool signal = enough_move && enough_velocity && enough_direction &&
                 (breakout || step_shock || score >= InpScoreTrigger);

   if(InpRejectExtremeSpread && spread_extreme && score < InpScoreTrigger * 1.35)
      signal = false;

   if(!signal)
      return;

   StoreAlert(index, direction, score, abs_move_points, spread_points, window_seconds, now);
}

bool BuildWindowStats(const int index,
                      const long now_msc,
                      double &old_mid,
                      long &old_msc,
                      double &previous_high,
                      double &previous_low,
                      int &samples,
                      int &up_changes,
                      int &down_changes,
                      int &changing_ticks)
{
   int count = g_states[index].sample_count;
   if(count < InpMinimumSamples)
      return false;

   long min_msc = now_msc - (long)InpLookbackSeconds * 1000;
   bool have_previous = false;
   double last_mid = 0.0;
   bool have_prior_range = false;

   samples = 0;
   up_changes = 0;
   down_changes = 0;
   changing_ticks = 0;

   for(int logical = 0; logical < count; logical++)
   {
      int position = LogicalSamplePosition(index, logical);
      int sample_index = SampleIndex(index, position);
      long sample_msc = g_samples[sample_index].time_msc;
      if(sample_msc <= 0 || sample_msc < min_msc)
         continue;

      double sample_mid = g_samples[sample_index].mid;
      if(samples == 0)
      {
         old_mid = sample_mid;
         old_msc = sample_msc;
      }

      if(sample_msc != now_msc)
      {
         if(!have_prior_range)
         {
            previous_high = sample_mid;
            previous_low = sample_mid;
            have_prior_range = true;
         }
         else
         {
            previous_high = MathMax(previous_high, sample_mid);
            previous_low = MathMin(previous_low, sample_mid);
         }
      }

      if(have_previous)
      {
         double delta = sample_mid - last_mid;
         if(delta > 0.0)
         {
            up_changes++;
            changing_ticks++;
         }
         else if(delta < 0.0)
         {
            down_changes++;
            changing_ticks++;
         }
      }

      last_mid = sample_mid;
      have_previous = true;
      samples++;
   }

   if(samples < InpMinimumSamples || old_msc <= 0 || old_mid <= 0.0)
      return false;

   if(!have_prior_range)
   {
      previous_high = old_mid;
      previous_low = old_mid;
   }

   return true;
}

double EffectiveAtrPoints(const int index, const double spread_points)
{
   double atr_points = g_states[index].atr_points;
   if(atr_points <= 0.0)
      atr_points = MathMax(InpFallbackAtrPoints, spread_points * 8.0);
   return MathMax(atr_points, 1.0);
}

void StoreAlert(const int index,
                const int direction,
                const double score,
                const double move_points,
                const double spread_points,
                const double window_seconds,
                const datetime now)
{
   g_states[index].alert_until = now + InpSignalHoldSeconds;
   g_states[index].alert_direction = direction;
   g_states[index].alert_score = score;
   g_states[index].alert_move_points = move_points;
   g_states[index].alert_spread_points = spread_points;
   g_states[index].alert_window_seconds = window_seconds;
   g_last_render = 0;

   string direction_text = (direction > 0 ? "UP" : "DOWN");
   int confidence_percent = ScoreToConfidencePercent(score);
   string text = StringFormat("%s %s - %d%%",
                              g_states[index].symbol,
                              direction_text,
                              confidence_percent);
   g_states[index].alert_message = text;

   if(InpUseTerminalAlert && now - g_states[index].last_terminal_alert >= InpTerminalAlertCooldownSeconds)
   {
      Alert("NewsScan: " + text);
      g_states[index].last_terminal_alert = now;
   }
}

void RenderPanel(const bool force)
{
   datetime now = TimeCurrent();
   if(!force && now == g_last_render)
      return;

   g_last_render = now;
   int visible_rows = IntMax(1, InpMaxRowsDisplayed);
   int required_labels = visible_rows + 3;
   EnsureLabelAllocation(required_labels);

   int enabled_count = CountEnabledSymbols();
   int disabled_count = ArraySize(g_states) - enabled_count;
   int alert_count = CountActiveAlerts(now);
   string pressure = CurrencyPressureText(now);

   string header;
   color header_color;
   if(alert_count > 0)
   {
      header = StringFormat("NEWSSCAN - %d ACTIVE OUTBREAK%s",
                            alert_count,
                            (alert_count == 1 ? "" : "S"));
      if(pressure != "")
         header += " | " + pressure;
      header_color = InpAlertColor;
   }
   else
   {
      header = StringFormat("NewsScan - quiet | %d/%d symbols active | %s",
                            enabled_count,
                            ArraySize(g_states),
                            TimeToString(now, TIME_SECONDS));
      header_color = InpNeutralColor;
   }

   SetLabel(0, header, header_color);

   if(alert_count <= 0)
   {
      string quiet_text = "Watching fast multi-currency price shocks. No current outbreak.";
      color quiet_color = InpNeutralColor;
      if(disabled_count > 0)
      {
         quiet_text = StringFormat("%s %d configured symbol%s unavailable.",
                                   quiet_text,
                                   disabled_count,
                                   (disabled_count == 1 ? "" : "s"));
         quiet_color = InpWarningColor;
      }

      SetLabel(1, quiet_text, quiet_color);
      ClearLabelsFrom(2);
      ChartRedraw(0);
      return;
   }

   int used[];
   ArrayResize(used, ArraySize(g_states));
   ArrayInitialize(used, 0);

   int row = 1;
   for(int displayed = 0; displayed < visible_rows; displayed++)
   {
      int best = BestUnusedAlert(used, now);
      if(best < 0)
         break;

      used[best] = 1;
      SetLabel(row, g_states[best].alert_message, InpAlertColor);
      row++;
   }

   ClearLabelsFrom(row);
   ChartRedraw(0);
}

void EnsureLabelAllocation(const int required_labels)
{
   if(g_labels_allocated >= required_labels)
      return;

   for(int i = g_labels_allocated; i < required_labels; i++)
   {
      string name = LabelName(i);
      if(ObjectFind(0, name) < 0)
      {
         if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         {
            PrintFormat("NewsScan: failed to create chart label %s, error %d", name, GetLastError());
            continue;
         }
      }

      ObjectSetInteger(0, name, OBJPROP_CORNER, InpCorner);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, InpXOffset);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, InpYOffset + i * InpRowSpacing);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, InpNeutralColor);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetString(0, name, OBJPROP_FONT, InpFontName);
      ObjectSetString(0, name, OBJPROP_TEXT, "");
   }

   g_labels_allocated = required_labels;
}

void SetLabel(const int row, const string text, const color row_color)
{
   string name = LabelName(row);
   if(ObjectFind(0, name) < 0)
      EnsureLabelAllocation(row + 1);

   ObjectSetInteger(0, name, OBJPROP_COLOR, row_color);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void ClearLabelsFrom(const int first_row)
{
   for(int i = first_row; i < g_labels_allocated; i++)
      SetLabel(i, "", InpNeutralColor);
}

void DeletePanelObjects()
{
   for(int i = 0; i < g_labels_allocated + 10; i++)
      ObjectDelete(0, LabelName(i));
}

string LabelName(const int row)
{
   return g_prefix + IntegerToString(row);
}

int CountEnabledSymbols()
{
   int count = 0;
   for(int i = 0; i < ArraySize(g_states); i++)
   {
      if(g_states[i].enabled)
         count++;
   }
   return count;
}

int CountActiveAlerts(const datetime now)
{
   int count = 0;
   for(int i = 0; i < ArraySize(g_states); i++)
   {
      if(IsAlertActive(i, now))
         count++;
   }
   return count;
}

bool IsAlertActive(const int index, const datetime now)
{
   return g_states[index].enabled && g_states[index].alert_until >= now && g_states[index].alert_score > 0.0;
}

int BestUnusedAlert(const int &used[], const datetime now)
{
   int best = -1;
   double best_score = -1.0;

   for(int i = 0; i < ArraySize(g_states); i++)
   {
      if(used[i] != 0 || !IsAlertActive(i, now))
         continue;

      if(g_states[i].alert_score > best_score)
      {
         best = i;
         best_score = g_states[i].alert_score;
      }
   }

   return best;
}

string CurrencyPressureText(const datetime now)
{
   string ccy[8];
   ccy[0] = "USD";
   ccy[1] = "EUR";
   ccy[2] = "GBP";
   ccy[3] = "JPY";
   ccy[4] = "CHF";
   ccy[5] = "CAD";
   ccy[6] = "AUD";
   ccy[7] = "NZD";

   double score[8];
   ArrayInitialize(score, 0.0);

   for(int i = 0; i < ArraySize(g_states); i++)
   {
      if(!IsAlertActive(i, now) || StringLen(g_states[i].symbol) < 6)
         continue;

      string base = StringSubstr(g_states[i].symbol, 0, 3);
      string quote = StringSubstr(g_states[i].symbol, 3, 3);
      int base_index = CurrencyIndex(ccy, base);
      int quote_index = CurrencyIndex(ccy, quote);
      double signed_score = g_states[i].alert_score * (double)g_states[i].alert_direction;

      if(base_index >= 0)
         score[base_index] += signed_score;
      if(quote_index >= 0)
         score[quote_index] -= signed_score;
   }

   int strongest = -1;
   double strongest_abs = 0.0;
   for(int i = 0; i < 8; i++)
   {
      double abs_score = MathAbs(score[i]);
      if(abs_score > strongest_abs)
      {
         strongest_abs = abs_score;
         strongest = i;
      }
   }

   if(strongest < 0 || strongest_abs < InpScoreTrigger)
      return "";

   string bias = (score[strongest] > 0.0 ? "BUY" : "SELL");
   return StringFormat("%s %s pressure %.1f", ccy[strongest], bias, strongest_abs);
}

int CurrencyIndex(const string &currencies[], const string currency)
{
   for(int i = 0; i < ArraySize(currencies); i++)
   {
      if(currencies[i] == currency)
         return i;
   }
   return -1;
}

int ScoreToConfidencePercent(const double score)
{
   double trigger = MathMax(InpScoreTrigger, 0.01);
   double percent = score / trigger * 60.0;
   percent = MathMax(1.0, MathMin(99.0, percent));
   return (int)MathRound(percent);
}

double SafeRatio(const double numerator, const double denominator)
{
   if(denominator <= 0.0)
      return 0.0;
   return numerator / denominator;
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
