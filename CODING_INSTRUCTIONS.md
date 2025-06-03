# 🔧 Coding Instructions: Complete IntradaySwingEA.mq5 Implementation

## 📋 **Overview**
You are working with a **scaffolded MQ5 Expert Advisor** (`IntradaySwingEA.mq5`) that follows a detailed specification in `IntradaySwingEA.md`. Your task is to **complete the placeholder functions** and **implement the missing logic** while maintaining the existing modular structure.

## 🎯 **Key Principles**
1. **DO NOT** change the existing function signatures or module structure
2. **DO NOT** modify the input parameters - they match the specification exactly  
3. **IMPLEMENT** the placeholder functions marked with comments like `// TODO:` or returning dummy values
4. **FOLLOW** the exact requirements from the markdown specification
5. **MAINTAIN** the modular approach (Module 1-10 structure)

---

## 🔍 **Current Status Analysis**

### ✅ **Already Implemented (Do Not Change)**
- All input parameters with correct defaults
- Function prototypes and signatures
- OnInit(), OnDeinit(), OnTimer() structure  
- Basic OnTick() logic flow
- Module organization and comments
- Risk management framework
- Emergency shutdown mechanism
- Daily reset functionality

### ⚠️ **Needs Implementation (Your Tasks)**

#### **Module 1: Utilities & Risk Checks**
- **`GetRollingCorrelation()`** - Currently returns `0.0` (placeholder)
  - Implement 20-bar rolling correlation calculation between symbol pairs
  - Use last 20 closing prices from M15 timeframe
  - Return correlation coefficient (-1.0 to +1.0)

#### **Module 2: Trend Filters** 
- **`GetH1TrendDirection()` & `GetH4TrendDirection()`** - Basic implementation exists but needs improvement
  - Current logic checks price vs EMAs but uses `_Symbol` instead of parameter
  - Should accept symbol parameter for multi-symbol trading
  - Add proper error handling for indicator data

#### **Module 3: Volatility & Correlation**
- **`GetRollingCorrelation()`** - Same as Module 1 (implement properly)

#### **Module 4: Entry Conditions**
- **`EntryAllowedByNews()`** - Currently returns `true` (placeholder)
  - Implement news filter logic reading from CSV or news API
  - Block trades ±10 min around high-impact news, ±5 min around medium-impact
  - Return false if within news blackout period

- **`EntryAllowedByConsecLoss()`** - Logic exists but incomplete
  - Complete the lockout duration tracking
  - Store timestamp when lockout starts
  - Return false until lockout duration expires

#### **Module 6: Trade Management**
- **`ManageOpenTrades()`** - Partial implementation, needs completion
  - Complete the trailing stop logic missing "pivot - 0.75 × ATR" trailing
  - Implement partial profit taking at 2×ATR (close 50% of position)
  - Add scaling-in logic for H1 swing high breakouts (if enabled)

#### **Module 8: Logging & Alerts**
- **File-based logging** - Currently uses `Print()` statements
  - Implement actual file writing for trade logs and diagnostics
  - Create daily summary files
  - Add proper error handling for file operations

---

## 📖 **Implementation Guide by Module**

### **Module 1: Complete GetRollingCorrelation()**
```mql5
// Reference from IntradaySwingEA.md lines 175-176:
// "Compute rolling correlation (e.g. last 20 bars) between pairs"
// Implementation should:
// 1. Get last 20 M15 closing prices for both symbols
// 2. Calculate Pearson correlation coefficient  
// 3. Return value between -1.0 and +1.0
```

### **Module 4: Complete News Filter**
```mql5
// Reference from IntradaySwingEA.md lines 91-101:
// "Use_News_Filter (boolean): If enabled, read daily CSV or news API"
// "Skip Entries: High-impact: ±10 minutes, Medium-impact: ±5 minutes"
// Implementation should:
// 1. Check current time against news events
// 2. Return false if within blackout window
// 3. Handle CSV parsing or API integration
```

### **Module 4: Complete Consecutive Loss Lockout**
```mql5
// Reference from IntradaySwingEA.md lines 131-132:
// "If ≥ 3 losses in a row, pause new entries for N minutes"
// Implementation should:
// 1. Track when lockout period started (datetime)
// 2. Check if Lockout_Duration_Minutes has elapsed
// 3. Only return true after full lockout period expires
```

### **Module 6: Complete Trade Management**
```mql5
// Reference from IntradaySwingEA.md lines 289-295:
// "Close 50% of position at 2 × ATR"
// "Trail remaining position at 'pivot – 0.75 × ATR'"
// Implementation should:
// 1. Detect when position reaches +2R profit
// 2. Close exactly 50% of position volume
// 3. Implement proper trailing logic with 0.75×ATR buffer
```

---

## 🔧 **Specific Implementation Requirements**

### **Error Handling**
- Add proper error checking for all indicator buffer copies
- Handle `INVALID_HANDLE` returns from indicator creation
- Validate all price and volume calculations before order execution

### **Multi-Symbol Support** 
- Ensure all functions work with symbol parameter (not just `_Symbol`)
- Test correlation calculations between different symbol types

### **Performance Optimization**
- Use static variables to avoid recalculating unchanged values
- Implement proper handle management for indicators
- Minimize memory allocations in OnTick()

### **Logging Enhancement**
- Replace `Print()` statements with actual file I/O
- Create structured log format matching specification
- Implement log rotation and file size management

---

## ✅ **Testing & Validation Checklist**

1. **Compile Check**: Code must compile without errors/warnings
2. **Module Testing**: Each function should be testable independently  
3. **Parameter Validation**: All 27 input parameters should work as specified
4. **Risk Management**: Drawdown limits and emergency shutdown must function
5. **Multi-Symbol**: Test with EURUSD, GBPUSD, XAUUSD, USDJPY as specified
6. **Timeframe Logic**: Verify H1 trend filter and M15 entry signals work correctly

---

## 📁 **Files to Reference**
- **`IntradaySwingEA.md`** - Complete specification (authoritative source)
- **`IntradaySwingEA.mq5`** - Current skeleton code (implement placeholders)

## 🚫 **Do NOT Modify**
- Input parameter names, types, or default values
- Function signatures in the prototypes section  
- Overall module structure (Module 1-10)
- OnInit/OnDeinit/OnTimer framework
- Existing implemented logic (unless it's clearly marked as placeholder)

Your goal is to transform the skeleton into a fully functional EA that precisely follows the markdown specification while maintaining the excellent modular structure already established. 