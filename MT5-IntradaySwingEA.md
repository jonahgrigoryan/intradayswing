# 📊 MT5 Intraday Swing EA — Modular Build Plan (FundingPips Evaluation Strategy)

## ✅ GOAL:
Build an intraday swing trading Expert Advisor to pass the FundingPips 2-step challenge in ~6 trading days using clean, risk-managed setups.

---

## 🔧 MODULE 1 — H1 Trend Filter

### 🧱 Stub:
```mql5
string GetTrendDirection()
  {
   // TODO: Implement H1 trend logic using EMAs
   return "neutral";
  }
```

### 💡 Prompt:
```
Add a function that checks H1 trend direction using EMA(50) and EMA(200).
Return "bullish" if price is above both EMAs, "bearish" if below both.
Return "neutral" otherwise.
Use iMA() on PERIOD_H1.
```

---

## 🔧 MODULE 2 — M15 Entry Signal (RSI + EMA Bounce or Candle Pattern)

### 🧱 Stub:
```mql5
bool IsEntrySignal(bool isBuy)
  {
   // TODO: Add RSI + EMA bounce logic for M15
   return false;
  }
```

### 💡 Prompt:
```
Create a function that checks for an entry signal on M15:
- Buy: RSI(14) crosses up from oversold (<30) AND price bounces off 50 EMA
- Sell: RSI(14) crosses down from overbought (>70) AND price bounces from 50 EMA
- Optional: add bullish/bearish engulfing filter
Return true when all conditions are met.
```

---

## 🔧 MODULE 3 — ATR-Based SL/TP Calculation

### 🧱 Stub:
```mql5
void GetSLTP(double entryPrice, bool isBuy, double &sl, double &tp)
  {
   // TODO: Use ATR(14) to calculate SL = 1.5xATR, TP = 3.0xATR
   sl = 0;
   tp = 0;
  }
```

### 💡 Prompt:
```
Create a function that uses ATR(14) on M15 to calculate SL and TP.
- SL = 1.5 × ATR
- TP = 3.0 × ATR
Output SL and TP prices based on whether it's a buy or sell.
```

---

## 🔧 MODULE 4 — Risk-Based Position Sizing

### 🧱 Stub:
```mql5
double CalculateLotSize(double slPips)
  {
   // TODO: Calculate lot size to risk 1% of account based on SL distance
   return 0.01;
  }
```

### 💡 Prompt:
```
Create a function that calculates lot size to risk 1% of account per trade.
Input: SL size in pips
Output: lot size (double), assuming standard contract size and 1:100 leverage.
```

---

## 🔧 MODULE 5 — Trading Session Filter

### 🧱 Stub:
```mql5
bool IsWithinTradingHours()
  {
   // TODO: Allow trading only between 6:00–17:00 server time
   return true;
  }
```

### 💡 Prompt:
```
Write a function that checks if current server time is between 6:00 and 17:00.
Return true if inside trading hours.
```

---

## 🔧 MODULE 6 — Daily Drawdown Guard

### 🧱 Stub:
```mql5
bool IsDailyDrawdownLimitHit()
  {
   // TODO: Block trading if current equity has fallen >4.5% from daily starting balance
   return false;
  }
```

### 💡 Prompt:
```
Create a function that blocks new trades if equity drawdown exceeds 4.5% of daily starting balance.
Assume balance is fixed for the day.
```

---

## 🔧 MODULE 7 — Trailing Stop Logic

### 🧱 Stub:
```mql5
void ManageTrailingStop()
  {
   // TODO: Trail SL once trade reaches +1R
  }
```

### 💡 Prompt:
```
Create a function that moves stop loss to break-even when profit hits +1R.
Then trail price by 0.5R increments to lock in gains.
```

---

## 🔧 MODULE 8 — Friday Trade Exit

### 🧱 Stub:
```mql5
void CloseOnFriday()
  {
   // TODO: Close all trades at 15:00 server time on Friday to avoid weekend holds
  }
```

### 💡 Prompt:
```
Write a function that closes all trades at 15:00 on Friday.
Use TimeDayOfWeek() and TimeHour().
```

---

## ✅ FINAL: Combine Modules in OnTick()

### 🧱 Stub:
```mql5
void OnTick()
  {
   // 1. Check if in trading session
   // 2. Block if daily drawdown hit
   // 3. Check trend
   // 4. Check entry signal
   // 5. Calculate SL/TP
   // 6. Calculate lot size
   // 7. Send order
   // 8. Manage trailing stop
   // 9. Close on Friday
  }
```

---

## 🧪 Part 2: How to Test Each Module

You can manually test each function in `OnTick()` or `OnInit()` using simple print statements.

### ✅ Example:
```mql5
Print("Trend Direction: ", GetTrendDirection());
Print("Within Hours: ", IsWithinTradingHours());
Print("Daily Drawdown Hit: ", IsDailyDrawdownLimitHit());
```

For functions like SL/TP or lot size:

```mql5
double sl, tp;
GetSLTP(Bid, true, sl, tp);
Print("SL: ", sl, " TP: ", tp);
```

Once tested, remove the debug code and integrate the functions into `OnTick()`.
