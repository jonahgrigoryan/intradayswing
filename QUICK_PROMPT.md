# 🚀 Quick Coding Prompt for IntradaySwingEA Completion

## **Your Mission**
Complete the placeholder functions in `IntradaySwingEA.mq5` following the specification in `IntradaySwingEA.md`. The skeleton is ~80% done - you need to implement the missing 20%.

## **Key Files**
- `IntradaySwingEA.md` = Complete specification (authoritative source)  
- `IntradaySwingEA.mq5` = Skeleton code (implement the placeholders)
- `CODING_INSTRUCTIONS.md` = Detailed implementation guide

## **Priority Tasks**
1. **GetRollingCorrelation()** - Calculate 20-bar correlation between symbol pairs
2. **EntryAllowedByNews()** - Implement news filter (±10min high-impact, ±5min medium)  
3. **EntryAllowedByConsecLoss()** - Complete lockout duration tracking
4. **ManageOpenTrades()** - Add partial profit (50% at 2R) + trailing logic
5. **File-based logging** - Replace Print() with actual file I/O

## **Rules**
- ✅ Keep existing function signatures and module structure  
- ✅ All 27 input parameters must remain unchanged
- ✅ Follow the markdown specification exactly
- ❌ Don't modify the OnTick() logic flow
- ❌ Don't change the risk management framework

## **Success Criteria**
- Code compiles without errors
- All placeholder functions implemented
- Follows modular structure (Module 1-10)
- Risk management and emergency shutdown work
- Multi-symbol trading capability (EURUSD, GBPUSD, XAUUSD, USDJPY)

The skeleton is excellent - your job is to fill in the gaps to make it fully functional! 