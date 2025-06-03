# 📊 Expert Advisor (EA) Development Prompt for MT5

You are helping me code an Expert Advisor (EA) in MQL5 for MetaTrader 5 designed specifically to pass a proprietary trading firm evaluation—FundingPips' 2-Step Evaluation on a $10,000 account.

## 🎯 Goal:

Create an EA that executes an Intraday Swing Trading Strategy using price action, technical filters, and enhanced risk controls to achieve:

- Phase 1 target: +8%
- Phase 2 target: +5%
- Within 2 weeks (ideally 6 trading days total)
- Staying within drawdown rules:
  - Max daily loss: 5%
  - Max total loss: 10%
  - No weekend holds (overnight is allowed)
  - Minimum 3 trading days per phase

## 📊 Strategy Overview:

- Trading Style: Intraday swing trading (30 minutes → 4 hours), not scalping
- Primary Timeframe: M15 for entry signals
- Trend Filter Timeframe: H1 for primary trend; optional H4/D1 confirmation

## ✅ Trading Conditions:

### 1. Trade Only in H1 Trend Direction

Use EMA(50) and EMA(200) on H1:
- Bullish if price > both EMAs → only long entries
- Bearish if price < both EMAs → only short entries
- H4 (optional): Check H4 EMA(50)/EMA(200) alignment. If H4 trend ≠ H1 trend, skip or reduce lot size.

### 2. Entry Rules on M15

Primary Entry Conditions (choose one):

**RSI(14) Filter**
- RSI crosses up from oversold (< 30) → buy, OR
- RSI crosses down from overbought (> 70) → sell
- AND price recently bounced off M15 EMA(50).

**Engulfing Candle Filter**
- A bullish (for longs) or bearish (for shorts) engulfing candle forms near M15 EMA(50), with H1 trend alignment.

**Volatility Filter:**
- Don't trade if M15 ATR(14) falls below a configurable floor (e.g. < 5 pips).
- After any major spike (e.g. news), wait until ATR returns above "normal" band before resuming entries.

### 3. Spread/Slippage Filter

Before sending any order:
- Spread must be ≤ (ATR_multiplier × ATR_in_pips). For example, skip trade if spread > 2 × M15 ATR.
- Log and monitor actual slippage on fills; if slippage exceeds a threshold (e.g. > 2 pips), flag in logs.

### 4. Dynamic SL/TP Using ATR

ATR(14) on M15 for sizing:

**Default:**
- SL = 1.5 × ATR
- TP = 3.0 × ATR (2:1 Reward : Risk)

**Adaptive TP/SL (if Use_Adaptive_TP_SL = true):**
- During strong momentum (e.g. M15 RSI > 80 or price acceleration), allow TP = 4.0 × ATR and SL = 1.0 × ATR.

**Break-Even & Trailing:**
- After reaching +1 R (equal to SL distance), move SL to entry + (0.5 × ATR) instead of hard break-even to give room.
- Once profit > 2 × ATR, activate trailing stop at "pivot – 0.75 × ATR" for longs (inverse for shorts).

### 5. Partial-Profit & Scaling Out

**Tiered TP:**
- Close 50% of position at 2 × ATR.
- Let remainder run to 3.0 (or 4.0) × ATR with trailing.

**Scaling In (Optional):**
- On breakout above prior H1 swing high (for longs), add a second 0.5 × lot (if Use_Multi_Entry = true).

### 6. News & Economic-Calendar Integration

**Use_News_Filter (boolean):**
- If enabled, the EA reads a daily CSV (or uses a news API) for high/medium/low impact events.

**Skip Entries:**
- High-impact: ±10 minutes
- Medium-impact: ±5 minutes
- Low-impact: no block (unless user adjusts)

**Post-News Volatility Timeout:**
- After any high-impact event, suspend new entries for 30 minutes or until ATR returns to normal.

### 7. Trading Sessions & Time Filters

**Server Time (London & NY overlap):**
- TradingSession_Start = 06:00
- TradingSession_End = 17:00
- Skip trades outside those hours.

**Friday Close:**
- Automatically close all open positions by Friday 15:00 to avoid weekend exposure.

### 8. Risk Management

**Position Sizing (each trade):**
- Risk ≤ 1% of current equity.
- Lot size = (Equity × Risk_Per_Trade / 100) / (SL_pips × PipValue).
- If Equity has grown > 10% above starting, optionally reduce Risk_Per_Trade to 0.8%.

**Free-Margin & Margin-Level Checks:**
- If Free Margin < (required margin + buffer), block new entries.
- If Account Margin Level < 150%, stop new entries.

**Day-Level Drawdown Guards:**
- Floating_Drawdown_LimitPct = 4% (stop entries if current unrealized drawdown ≥ 4%).
- Daily_Loss_LimitPct = 5% (stop entries if realized daily drawdown ≥ 5%).

**Consecutive-Loss Lockout (optional):**
- If ≥ 3 losses in a row, pause new entries for N minutes (user-configurable) or until daily drawdown recovers.

**Daily Trade Count Cap (optional):**
- Limit to max 5 trades per day to avoid overtrading.

### 9. Emergency Shutdown Mechanism

**Trigger:**
- If daily equity drawdown ≥ 5%, or total equity drawdown ≥ 10%, automatically disable new entries.

**Reset:**
- At the start of each new trading day, reset shutdown flag.

**Logging & Alerts:**
- Log timestamp of shutdown activation in "Diagnostics" file.
- Send MetaTrader email/push notification when triggered.

### 10. Multi-Symbol Correlation Check (When Running on Multiple Pairs)

- Compute rolling correlation (e.g. last 20 bars) between pairs (EURUSD↔GBPUSD, USDJPY↔EURUSD, etc.).
- If correlation ≥ 0.80 and one position is open, block new positions on correlated symbols to limit aggregated exposure.

## 📈 Additional Features:

**No Stacking/Martingale:**
- Only single-lot entry per signal (unless scaling-in is explicitly enabled with partial lots).

**Enhanced Logging (explicit):**
- Trade Events: Entry, exit, sl modifier, trailing activation, partial-profit execution.

**Session Summaries:**
- End-of-day report: number of trades, gross/net P/L, highest drawdown, open positions.

**Diagnostics File:**
- MQL5 error codes if order fails (e.g. ERR_BROKER_BUSY, ERR_REQUOTE).
- Unhandled exceptions in OnTick().

**Email/Push Alerts:**
- Emergency shutdown activation.
- When a trade hits TP or SL.
- End-of-day summary (if enabled).

**Parameter-Optimization Hooks:**
- Include commented placeholders to allow Strategy Tester to run over:
  - FastEMA = 20 → 60
  - SlowEMA = 100 → 240
  - ATR_Multiplier (SL/TP) = 1.0 → 2.0
- Provide two input profiles: "Conservative" (slightly wider SL, tighter RL) vs. "Aggressive" (narrow SL, wider TP).

**Forward-Test vs. Live-Run Mode:**
- Input flag Mode = LIVE or TEST:
  - In TEST, enable all logging, Monte Carlo hooks, and skip email pushes.
  - In LIVE, minimize overhead (only critical logs, alerts).

**Monte Carlo / Walk-Forward Stubs:**
- Code stubs to package trade sequence IDs so that you can randomize slippage or order of signals in backtests.

## 🧠 EA Inputs (Parameters):

| Parameter | Default | Description |
|-----------|---------|-------------|
| FastEMA | 50 | Fast EMA period for trend filter (H1 and H4 if enabled) |
| SlowEMA | 200 | Slow EMA period for trend filter (H1 and H4 if enabled) |
| RSI_Period | 14 | RSI length on M15 |
| RSI_Overbought | 70 | RSI overbought threshold |
| RSI_Oversold | 30 | RSI oversold threshold |
| ATR_Period | 14 | ATR length on M15 |
| SL_ATR_Mult | 1.5 | Standard SL = ATR × multiplier |
| TP_ATR_Mult | 3.0 | Standard TP = ATR × multiplier |
| TP_ATR_Mult_HighMomentum | 4.0 | High-momentum TP multiplier |
| Risk_Per_Trade | 1.0 | % of equity risked per trade |
| Max_Concurrent_Trades | 1 | Max number of open trades per symbol |
| TradingSession_Start | 6 | Start hour (server time) |
| TradingSession_End | 17 | End hour (server time) |
| Daily_Loss_LimitPct | 5.0 | Max realized drawdown (%) per day |
| Floating_Drawdown_LimitPct | 4.0 | Max unrealized drawdown (%) per day |
| Use_H1_Trend_Filter | true | Enable H1 EMA(50/200) filter |
| Use_H4_Trend_Filter | false | Enable H4 EMA(50/200) filter (optional) |
| Use_News_Filter | false | Block entries around high/medium/low impact news |
| Use_Adaptive_TP_SL | true | Enable dynamic TP/SL adjustments based on momentum |
| Use_Partial_Profit | true | Enable closing partial position at first TP tier |
| Use_Consecutive_Loss_Lockout | true | Pause trading after N consecutive losses |
| Consec_Loss_Limit | 3 | Number of consecutive losses before lockout |
| Lockout_Duration_Minutes | 30 | Duration (minutes) of lockout period |
| Max_Daily_Trades | 5 | Maximum trades allowed per day |
| Max_Correlation | 0.80 | If two symbols correlation > this, second trade is blocked |
| Spread_Limit_Mult | 2.0 | Max allowed spread relative to ATR (e.g. Spread ≤ ATR×Spread_Limit_Mult) |
| Mode | "LIVE" | "LIVE" or "TEST" (enables/disables extended logging, Monte Carlo stubs) |

## ✅ Deliverables:

**Expert Advisor .mq5 File**
- Fully coded with all filters, position sizing, and enhanced risk controls.
- Clearly commented "Optimization" placeholders.

**Backtest-Ready for Multiple Symbols**
- EURUSD, GBPUSD, XAUUSD, USDJPY on M15 (and M1 if you want a micro-scalping adaptation).
- Strategy Tester templates (.tpl) showing default vs. "Conservative" vs. "Aggressive" input profiles.

**Adjustable Input Parameters**
- All items listed above under EA Inputs.

**Comprehensive Built-In Logging**
- Trade Logs: Timestamp, symbol, direction, lot size, entry price, SL/TP, exit price, profit, drawdown at entry.
- Diagnostics: MQL5 error codes, exceptional cases, and emergency shutdown triggers.
- Daily Summaries: Number of trades, gross/net P/L, highest intraday drawdown, open positions at cutoff.
- Alerts: Email/push notifications for critical events (shutdowns, errors, end-of-day summary).

**Optimization & Forward-Test Hooks**
- Sample Monte Carlo seed generator for backtests.
- Compile-time flags or input "Mode" selector to switch between LIVE and TEST modes.

## Notes on Implementation Sequence (Suggested)

### Module 1: Utilities & Risk Checks

**Functions:**
- `double GetATR(string symbol, ENUM_TIMEFRAMES tf, int period)`
- `bool IsSpreadAcceptable(string symbol)`
- `bool HasSufficientMargin(double lotSize, double slPips)`
- `bool IsCorrelatedTradeAllowed(string symbol)`

**Logging stubs:**
- `void LogTradeEvent(...)`
- `void LogDiagnosticEvent(string message)`

### Module 2: Trend Filters

- `string GetH1TrendDirection()` (EMA50/200)
- `string GetH4TrendDirection()` (EMA50/200, if Use_H4_Trend_Filter)

### Module 3: Volatility & Correlation

- `bool IsVolatilityNormal()` (checks ATR floor)
- `double GetRollingCorrelation(string symA, string symB)`

### Module 4: Entry Conditions

- `bool M15RSISignal()`
- `bool M15EngulfingSignal()`
- `bool EntryAllowedByTime()` (session & day filters)
- `bool EntryAllowedByNews()` (if Use_News_Filter)
- `bool EntryAllowedByDrawdown()` (floating & realized)
- `bool EntryAllowedByConsecLoss()` (if Use_Consecutive_Loss_Lockout)

### Module 5: Position Sizing & Order Execution

- `double CalculateLotSize(double riskPct, double slPips)`
- `void ExecuteMarketOrder(string symbol, ENUM_ORDER_TYPE type, double lotSize, double slPrice, double tpPrice)`
- Slippage check after order: if slippage > threshold, flag in logs.

### Module 6: Trade Management (Trailing, Breakeven, Partial Profit)

`void ManageOpenTrades()` called in OnTimer() or at each tick:
- Check if price ≥ entry + 1 × ATR → move SL to entry + (0.5 × ATR).
- If price ≥ entry + 2 × ATR:
  - Close 50%.
  - Trail remaining position at "pivot – 0.75 × ATR."
  - Final TP on remaining = 3.0 or 4.0 × ATR.

### Module 7: Emergency Shutdown & Daily Reset

`void CheckDailyDrawdown()` in OnTimer() every minute:
- If realized drawdown ≥ Daily_Loss_LimitPct OR unrealized ≥ Floating_Drawdown_LimitPct → set shutdownFlag=true, log, alert.

`void ResetAtNewDay()` (set shutdownFlag=false, reset counters).

### Module 8: Logging & Alerts

- `void SendEmailPush(string subject, string body)`
- `void WriteDailySummary()` at New York close (server 21:00 if London server).

### Module 9: Optimization & Monte Carlo

- Comments in code to enable Strategy Tester optimization on key inputs.
- Stub `void MonteCarloSeedGenerator()` that logs a random seed with each backtest run.

### Module 10: OnTick() & OnTimer()

**In OnTick():**
- If shutdownFlag: return.
- If new tick on M15 boundary: evaluate EntryConditions → ExecuteMarketOrder.
- For existing positions, call ManageOpenTrades().

**In OnTimer() (every minute):**
- CheckDailyDrawdown()
- ResetAtNewDay() if server date changed.

