//+------------------------------------------------------------------+
//|                                                       EA_Scaffold.mq5 |
//|                     Intraday Swing EA for FundingPips Evaluation  |
//|                                  (Scaffolding with Module Numbers) |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters (EA Inputs)
input int      FastEMA                    = 50;    // Module 2: Fast EMA period
input int      SlowEMA                    = 200;   // Module 2: Slow EMA period
input int      RSI_Period                 = 14;    // Module 4: RSI length on M15
input int      RSI_Overbought             = 70;    // Module 4: RSI overbought threshold
input int      RSI_Oversold               = 30;    // Module 4: RSI oversold threshold
input int      ATR_Period                 = 14;    // Module 3: ATR length on M15
input double   SL_ATR_Mult                = 1.5;   // Module 3: SL = ATR × multiplier
input double   TP_ATR_Mult                = 3.0;   // Module 3: TP = ATR × multiplier
input double   TP_ATR_Mult_HighMomentum   = 4.0;   // Module 3: High‐momentum TP multiplier
input double   Risk_Per_Trade             = 1.0;   // Module 8: % of equity risked per trade
input int      Max_Concurrent_Trades      = 1;     // Module 8: Max open trades per symbol
input int      TradingSession_Start       = 6;     // Module 7: Start hour (server time)
input int      TradingSession_End         = 17;    // Module 7: End hour (server time)
input double   Daily_Loss_LimitPct        = 5.0;   // Module 8: Max realized drawdown % per day
input double   Floating_Drawdown_LimitPct = 4.0;   // Module 8: Max unrealized drawdown % per day
input bool     Use_H1_Trend_Filter        = true;  // Module 2: Enable H1 EMA filter
input bool     Use_H4_Trend_Filter        = false; // Module 2: Enable H4 EMA filter (optional)
input bool     Use_News_Filter            = false; // Module 6: Enable news block
input bool     Use_Adaptive_TP_SL         = true;  // Module 3: Enable dynamic TP/SL
input bool     Use_Partial_Profit         = true;  // Module 5: Enable partial close
input bool     Use_Consecutive_Loss_Lockout = true; // Module 8: Pause after N losses
input int      Consec_Loss_Limit          = 3;     // Module 8: Consecutive-loss limit
input int      Lockout_Duration_Minutes   = 30;    // Module 8: Lockout duration (minutes)
input int      Max_Daily_Trades           = 5;     // Module 8: Max trades per day
input double   Max_Correlation            = 0.80;  // Module 3: Correlation threshold
input double   Spread_Limit_Mult          = 2.0;   // Module 3: Max spread relative to ATR
input string   Mode                       = "LIVE"; // Module 9: "LIVE" or "TEST"

//--- Global Variables
CTrade          trade;                       // Trade object

bool            shutdownFlag        = false; // Module 9: Emergency shutdown flag
datetime        lastDay             = 0;     // Module 9: Track last trading day
int             consecutiveLosses   = 0;     // Module 8: Consecutive losses counter
int             dailyTradeCount     = 0;     // Module 8: Trades taken today
double          dailyStartEquity    = 0.0;   // Module 8: Equity at start of day
double          highestIntradayEquity = 0.0; // Module 8: Highest intraday equity
double          lowestIntradayEquity  = 0.0; // Module 8: Lowest intraday equity

//--- Function Prototypes

// Module 1: Utilities & Risk Checks
double  GetATR(string symbol, ENUM_TIMEFRAMES tf, int period);
bool    IsSpreadAcceptable(string symbol);
bool    HasSufficientMargin(string symbol, double lotSize, double slPips);
bool    IsCorrelatedTradeAllowed(string symbol);

// Module 2: Trend Filters
string  GetH1TrendDirection();
string  GetH4TrendDirection();

// Module 3: Volatility & Correlation
bool    IsVolatilityNormal(string symbol);
double  GetRollingCorrelation(string symA, string symB);

// Module 4: Entry Conditions
bool    M15RSISignal(string symbol);
bool    M15EngulfingSignal(string symbol);
bool    EntryAllowedByTime();
bool    EntryAllowedByNews();
bool    EntryAllowedByDrawdown(string symbol);
bool    EntryAllowedByConsecLoss();

// Module 5: Position Sizing & Order Execution
double  CalculateLotSize(string symbol, double riskPct, double slPips);
void    ExecuteMarketOrder(string symbol, ENUM_ORDER_TYPE type, double lotSize, double slPrice, double tpPrice);

// Module 6: Trade Management (Trailing, Breakeven, Partial Profit)
void    ManageOpenTrades();

// Module 7: Emergency Shutdown & Daily Reset
void    CheckDailyDrawdown();
void    ResetAtNewDay();

// Module 8: Logging & Alerts
void    LogTradeEvent(string eventType, string symbol, double lotSize, double price, double sl, double tp, double profit);
void    LogDiagnosticEvent(string message);
void    SendEmailPush(string subject, string body);
void    WriteDailySummary();

// Module 9: Optimization & Monte Carlo
void    MonteCarloSeedGenerator();

//--- Initialization
int OnInit()
  {
   // Record the equity at EA start (for daily calculations)
   dailyStartEquity      = AccountInfoDouble(ACCOUNT_EQUITY);
   highestIntradayEquity = dailyStartEquity;
   lowestIntradayEquity  = dailyStartEquity;
   lastDay               = TimeTradeServer();

   // Set timer to 60 seconds for OnTimer execution
   EventSetTimer(60);

   // In TEST mode, you may disable alerts or extra logging
   if(StringCompare(Mode, "TEST") == 0)
     {
      // Example: disable email pushes during testing
     }

   return(INIT_SUCCEEDED);
  }

//--- Deinitialization
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

//--- Timer Event (Every 60 Seconds)
void OnTimer()
  {
   CheckDailyDrawdown();
   ResetAtNewDay();
  }

//--- Main Tick Handler
void OnTick()
  {
   // Update intraday equity peaks/troughs
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(currentEquity > highestIntradayEquity) highestIntradayEquity = currentEquity;
   if(currentEquity < lowestIntradayEquity)  lowestIntradayEquity  = currentEquity;

   // If emergency shutdown is active, do nothing
   if(shutdownFlag) return;

   // For each symbol you wish to trade, e.g., EURUSD, GBPUSD, etc.
   string symbols[] = {"EURUSD","GBPUSD","XAUUSD","USDJPY"};
   for(int i=0; i<ArraySize(symbols); i++)
     {
      string sym = symbols[i];

      // Module 4: Check if entry conditions are met
      if(EntryAllowedByTime() &&
         !shutdownFlag &&
         EntryAllowedByDrawdown(sym) &&
         EntryAllowedByConsecLoss() &&
         (!Use_News_Filter || EntryAllowedByNews()) &&
         ( !Use_H1_Trend_Filter  || GetH1TrendDirection() == (M15RSISignal(sym)? "bullish":"bearish") ) &&
         ( !Use_H4_Trend_Filter  || GetH4TrendDirection() == GetH1TrendDirection() ) &&
         IsVolatilityNormal(sym) &&
         IsSpreadAcceptable(sym) &&
         IsCorrelatedTradeAllowed(sym))
        {
         // Determine direction
         bool isLong = M15RSISignal(sym) && GetH1TrendDirection() == "bullish";
         bool isShort = M15RSISignal(sym) && GetH1TrendDirection() == "bearish";
         if(!M15RSISignal(sym)) // If RSI signal didn’t fire, try engulfing
           {
            isLong  = M15EngulfingSignal(sym) && GetH1TrendDirection() == "bullish";
            isShort = M15EngulfingSignal(sym) && GetH1TrendDirection() == "bearish";
           }

         if(isLong || isShort)
           {
            // Module 3: Calculate SL/TP
            double atr    = GetATR(sym, PERIOD_M15, ATR_Period);
            double slPips = SL_ATR_Mult * atr;
            double tpPips = Use_Adaptive_TP_SL && (iRSI(sym, PERIOD_M15, RSI_Period, PRICE_CLOSE, 0) > 80) 
                            ? TP_ATR_Mult_HighMomentum * atr 
                            : TP_ATR_Mult * atr;

            // Module 5: Calculate lot size by risk
            double lotSize = CalculateLotSize(sym, Risk_Per_Trade, slPips);
            if(lotSize <= 0) continue;

            // Module 5: Determine entry price, SL, TP
            double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
            double bid = SymbolInfoDouble(sym, SYMBOL_BID);
            double entryPrice = isLong ? ask : bid;
            double slPrice = isLong ? entryPrice - slPips * SymbolInfoDouble(sym, SYMBOL_POINT)
                                     : entryPrice + slPips * SymbolInfoDouble(sym, SYMBOL_POINT);
            double tpPrice = isLong ? entryPrice + tpPips * SymbolInfoDouble(sym, SYMBOL_POINT)
                                     : entryPrice - tpPips * SymbolInfoDouble(sym, SYMBOL_POINT);

            // Module 5: Execute the trade
            ExecuteMarketOrder(sym, isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, lotSize, slPrice, tpPrice);

            // Increment daily trade count
            dailyTradeCount++;
            if(dailyTradeCount >= Max_Daily_Trades) shutdownFlag = true; // Prevent further trades today
           }
        }

      // Module 6: Manage existing trades for this symbol
      ManageOpenTrades();
     }
  }

//+------------------------------------------------------------------+
//|                             Module 1: Utilities & Risk Checks   |
//+------------------------------------------------------------------+
double GetATR(string symbol, ENUM_TIMEFRAMES tf, int period)
  {
   //--- Retrieve the most recent ATR value for the given symbol/timeframe
   int    handle = iATR(symbol, tf, period);
   if(handle == INVALID_HANDLE) return 0.0;
   double atrArray[];
   if(CopyBuffer(handle, 0, 0, 1, atrArray) == 1) return atrArray[0];
   return 0.0;
  }

bool IsSpreadAcceptable(string symbol)
  {
   double spread = (SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID)) / SymbolInfoDouble(symbol, SYMBOL_POINT);
   double atr    = GetATR(symbol, PERIOD_M15, ATR_Period);
   if(atr <= 0) return true; // No ATR data → allow for now
   if(spread > atr * Spread_Limit_Mult)
     {
      LogDiagnosticEvent("Spread too wide on " + symbol);
      return false;
     }
   return true;
  }

bool HasSufficientMargin(string symbol, double lotSize, double slPips)
  {
   double marginRequired = 0.0;
   double freeMargin     = AccountInfoDouble(ACCOUNT_FREEMARGIN);
   // Estimate margin for lotSize; use symbol info
   if(!SymbolInfoDouble(symbol, SYMBOL_MARGIN_REQUIRED, marginRequired))
     marginRequired = 0.0;
   // Apply buffer equal to SL distance in account currency
   double buffer = slPips * lotSize * SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   if(freeMargin < (marginRequired + buffer))
     {
      LogDiagnosticEvent("Insufficient margin for " + symbol);
      return false;
     }
   // Margin level check
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   if(marginLevel > 0 && marginLevel < 150.0)
     {
      LogDiagnosticEvent("Margin level too low for new trade: " + (string)marginLevel);
      return false;
     }
   return true;
  }

bool IsCorrelatedTradeAllowed(string symbol)
  {
   // If only one pair is open, allow. If multiple, check correlation.
   if(ArraySize(trade.OrdersTotal()) <= 1) return true;

   // Example: Check EURUSD vs. GBPUSD. In practice, loop through open symbols.
   string otherSymbols[][2] = { {"EURUSD","GBPUSD"}, {"EURUSD","USDJPY"}, {"GBPUSD","XAUUSD"} };
   for(int i=0; i<ArraySize(otherSymbols); i++)
     {
      string symA = otherSymbols[i][0];
      string symB = otherSymbols[i][1];
      if(symbol == symA || symbol == symB)
        {
         double corr = GetRollingCorrelation(symA, symB);
         if(corr >= Max_Correlation && (PositionSelect(symA) || PositionSelect(symB)))
           {
            LogDiagnosticEvent("Correlation block: " + symA + " & " + symB + " corr=" + DoubleToString(corr,2));
            return false;
           }
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                             Module 2: Trend Filters              |
//+------------------------------------------------------------------+
string GetH1TrendDirection()
  {
   double emaFast = iMA(_Symbol, PERIOD_H1, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaSlow = iMA(_Symbol, PERIOD_H1, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double price   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price > emaFast && price > emaSlow) return "bullish";
   if(price < emaFast && price < emaSlow) return "bearish";
   return "neutral";
  }

string GetH4TrendDirection()
  {
   double emaFast = iMA(_Symbol, PERIOD_H4, FastEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double emaSlow = iMA(_Symbol, PERIOD_H4, SlowEMA, 0, MODE_EMA, PRICE_CLOSE, 0);
   double price   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price > emaFast && price > emaSlow) return "bullish";
   if(price < emaFast && price < emaSlow) return "bearish";
   return "neutral";
  }

//+------------------------------------------------------------------+
//|                        Module 3: Volatility & Correlation         |
//+------------------------------------------------------------------+
bool IsVolatilityNormal(string symbol)
  {
   double atr = GetATR(symbol, PERIOD_M15, ATR_Period);
   if(atr <= 0) return true; // No ATR data yet
   // Example: If ATR < 5 pips, treat as too low volatility
   if(atr < 5.0)
     {
      LogDiagnosticEvent("Volatility too low on " + symbol + ": ATR=" + DoubleToString(atr,2));
      return false;
     }
   return true;
  }

double GetRollingCorrelation(string symA, string symB)
  {
   // Placeholder: return 0.0. In practice, pull 20‐bar closing prices and compute correlation.
   return 0.0;
  }

//+------------------------------------------------------------------+
//|                        Module 4: Entry Conditions                |
//+------------------------------------------------------------------+
bool M15RSISignal(string symbol)
  {
   double rsiCurrent = iRSI(symbol, PERIOD_M15, RSI_Period, PRICE_CLOSE, 0);
   double rsiPrev    = iRSI(symbol, PERIOD_M15, RSI_Period, PRICE_CLOSE, 1);
   if(rsiPrev < RSI_Oversold && rsiCurrent > RSI_Oversold)
     return true; // Bullish cross from oversold
   if(rsiPrev > RSI_Overbought && rsiCurrent < RSI_Overbought)
     return true; // Bearish cross from overbought
   return false;
  }

bool M15EngulfingSignal(string symbol)
  {
   MqlRates  prevCandle, lastCandle;
   if(CopyRates(symbol, PERIOD_M15, 1, 2, &prevCandle) < 2) return false;
   if(CopyRates(symbol, PERIOD_M15, 0, 1, &lastCandle) < 1) return false;
   bool bullishEngulf = lastCandle.open < prevCandle.open && lastCandle.close > prevCandle.close && lastCandle.close > lastCandle.open;
   bool bearishEngulf = lastCandle.open > prevCandle.open && lastCandle.close < prevCandle.close && lastCandle.close < lastCandle.open;
   // Only accept near EMA(50)
   double ema50 = iMA(symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE, 1);
   if(bullishEngulf && lastCandle.low <= ema50 * (1 + SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE)/10000))
     return true;
   if(bearishEngulf && lastCandle.high >= ema50 * (1 - SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE)/10000))
     return true;
   return false;
  }

bool EntryAllowedByTime()
  {
   int hour = TimeHour(TimeTradeServer());
   int dayOfWeek = TimeDayOfWeek(TimeTradeServer());
   // Allow Mon–Fri only, between session hours
   if(dayOfWeek == 0 || dayOfWeek == 6) return false; // Sunday=0, Saturday=6
   if(hour < TradingSession_Start || hour >= TradingSession_End) return false;
   // Friday forced close by 15:00
   if(dayOfWeek == 5 && hour >= 15) return false;
   return true;
  }

bool EntryAllowedByNews()
  {
   // Placeholder: read from CSV or news API. Return true if no high/medium news in window.
   return true;
  }

bool EntryAllowedByDrawdown(string symbol)
  {
   double unrealDD = (dailyStartEquity - lowestIntradayEquity) / dailyStartEquity * 100.0;
   double realizedDD = (dailyStartEquity - AccountInfoDouble(ACCOUNT_EQUITY)) / dailyStartEquity * 100.0;
   if(unrealDD >= Floating_Drawdown_LimitPct || realizedDD >= Daily_Loss_LimitPct)
     {
      shutdownFlag = true;
      LogDiagnosticEvent("Drawdown limit reached: UnrealDD=" + DoubleToString(unrealDD,2) + "%, RealizedDD=" + DoubleToString(realizedDD,2) + "%");
      return false;
     }
   return true;
  }

bool EntryAllowedByConsecLoss()
  {
   if(Use_Consecutive_Loss_Lockout && consecutiveLosses >= Consec_Loss_Limit)
     {
      // Check if lockout duration has passed (store timestamp when lockout started if needed)
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//|                   Module 5: Position Sizing & Execution           |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol, double riskPct, double slPips)
  {
   double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskAmount = equity * riskPct / 100.0;
   double pipValue   = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotSize    = (pipValue > 0 ? (riskAmount / (slPips * pipValue)) : 0.0);
   // Adjust to minimal lot step
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   lotSize = MathMax(step, MathFloor(lotSize / step) * step);
   if(!HasSufficientMargin(symbol, lotSize, slPips)) return 0.0;
   return lotSize;
  }

void ExecuteMarketOrder(string symbol, ENUM_ORDER_TYPE type, double lotSize, double slPrice, double tpPrice)
  {
   MqlTradeRequest  request;
   MqlTradeResult   result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = symbol;
   request.volume   = lotSize;
   request.type     = type;
   request.price    = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   request.sl       = slPrice;
   request.tp       = tpPrice;
   request.deviation = 5; // Max slippage in points
   request.magic    = 123456;
   request.comment  = "IntradaySwingEA";

   if(!OrderSend(request, result))
     {
      LogDiagnosticEvent("OrderSend failed: " + result.comment);
     }
   else if(result.retcode != TRADE_RETCODE_DONE)
     {
      LogDiagnosticEvent("OrderSend retcode: " + (string)result.retcode);
     }
   else
     {
      LogTradeEvent("ENTRY", symbol, lotSize, result.price, slPrice, tpPrice, 0.0);
     }
  }

//+------------------------------------------------------------------+
//|                Module 6: Trade Management (Trailing, BE, Partial) |
//+------------------------------------------------------------------+
void ManageOpenTrades()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong  ticket    = PositionGetTicket(i);
      string symbol    = PositionGetString(POSITION_SYMBOL);
      double entryPrice= PositionGetDouble(POSITION_PRICE_OPEN);
      double sl        = PositionGetDouble(POSITION_SL);
      double tp        = PositionGetDouble(POSITION_TP);
      double volume    = PositionGetDouble(POSITION_VOLUME);
      double currentPrice = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                             ? SymbolInfoDouble(symbol, SYMBOL_BID)
                             : SymbolInfoDouble(symbol, SYMBOL_ASK);
      double atrPips   = GetATR(symbol, PERIOD_M15, ATR_Period);
      double atrPoints = atrPips * SymbolInfoDouble(symbol, SYMBOL_POINT);

      // Calculate unrealized profit in pips
      double profitPips = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                           ? (currentPrice - entryPrice) / SymbolInfoDouble(symbol, SYMBOL_POINT)
                           : (entryPrice - currentPrice) / SymbolInfoDouble(symbol, SYMBOL_POINT);

      // Break-even move at +1 R: move SL to entry ± (0.5×ATR)
      double oneR = SL_ATR_Mult * atrPips;
      if(profitPips >= oneR)
        {
         double newSL = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                          ? entryPrice + 0.5 * atrPoints
                          : entryPrice - 0.5 * atrPoints;
         if((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && newSL > sl) ||
            (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && newSL < sl))
           {
            trade.PositionModify(ticket, newSL, tp);
            LogTradeEvent("BREAKEVEN", symbol, volume, currentPrice, newSL, tp, 0.0);
           }
        }

      // Partial close at 2×ATR
      double twoR = 2.0 * atrPips;
      if(Use_Partial_Profit && profitPips >= twoR && volume > SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP))
        {
         double partialLots = volume / 2.0;
         if(partialLots < SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP)) partialLots = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

         trade.PositionClosePartial(ticket, partialLots);
         LogTradeEvent("PARTIAL_CLOSE", symbol, partialLots, currentPrice, sl, tp, 0.0);
        }

      // Final trailing to 3×ATR or 4×ATR
      double finalTPpips = Use_Adaptive_TP_SL && profitPips >= twoR ? TP_ATR_Mult_HighMomentum * atrPips : TP_ATR_Mult * atrPips;
      double finalTPpoints = finalTPpips * SymbolInfoDouble(symbol, SYMBOL_POINT);
      double newTP = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                       ? entryPrice + finalTPpoints
                       : entryPrice - finalTPpoints;

      if((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && newTP > tp) ||
         (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && newTP < tp))
        {
         trade.PositionModify(ticket, sl, newTP);
         LogTradeEvent("TP_MODIFY", symbol, volume, currentPrice, sl, newTP, 0.0);
        }
     }
  }

//+------------------------------------------------------------------+
//|                 Module 7: Emergency Shutdown & Daily Reset       |
//+------------------------------------------------------------------+
void CheckDailyDrawdown()
  {
   datetime now = TimeTradeServer();
   int      today = TimeDay(now);
   // Recalculate highest/lowest intraday equity
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > highestIntradayEquity) highestIntradayEquity = equity;
   if(equity < lowestIntradayEquity)  lowestIntradayEquity  = equity;

   double unrealDD   = (dailyStartEquity - lowestIntradayEquity) / dailyStartEquity * 100.0;
   double realizedDD = (dailyStartEquity - equity) / dailyStartEquity * 100.0;

   if(unrealDD >= Floating_Drawdown_LimitPct || realizedDD >= Daily_Loss_LimitPct)
     {
      shutdownFlag = true;
      LogDiagnosticEvent("Emergency shutdown triggered: UnrealDD=" + DoubleToString(unrealDD,2) +
                         "%, RealizedDD=" + DoubleToString(realizedDD,2) + "%");
      if(StringCompare(Mode, "LIVE") == 0)
         SendEmailPush("EA Shutdown", "Drawdown breach: Unreal=" + DoubleToString(unrealDD,2) +
                       "%, Realized=" + DoubleToString(realizedDD,2) + "%");
     }
  }

void ResetAtNewDay()
  {
   datetime now   = TimeTradeServer();
   int      day   = TimeDay(now);
   if(day != TimeDay(lastDay))
     {
      // New trading day actions
      lastDay            = now;
      shutdownFlag       = false;
      consecutiveLosses  = 0;
      dailyTradeCount    = 0;
      dailyStartEquity   = AccountInfoDouble(ACCOUNT_EQUITY);
      highestIntradayEquity = dailyStartEquity;
      lowestIntradayEquity  = dailyStartEquity;
      WriteDailySummary();
     }
  }

//+------------------------------------------------------------------+
//|                     Module 8: Logging & Alerts                   |
//+------------------------------------------------------------------+
void LogTradeEvent(string eventType, string symbol, double lotSize, double price, double sl, double tp, double profit)
  {
   // Example: Print to Experts tab; in practice, write to file
   string msg = TimeToString(TimeTradeServer(), TIME_DATE|TIME_SECONDS) + " | " +
                eventType + " | " + symbol + " | Lot=" + DoubleToString(lotSize,2) +
                " | Price=" + DoubleToString(price, _Digits) +
                " | SL=" + DoubleToString(sl, _Digits) +
                " | TP=" + DoubleToString(tp, _Digits) +
                " | Profit=" + DoubleToString(profit,2);
   Print(msg);
  }

void LogDiagnosticEvent(string message)
  {
   // Example: Print to Experts tab with [DIAG] prefix
   string msg = TimeToString(TimeTradeServer(), TIME_DATE|TIME_SECONDS) + " | [DIAG] " + message;
   Print(msg);
  }

void SendEmailPush(string subject, string body)
  {
   // SendMail or PushNotification based on user setup
   if(!StringIsEmpty(subject) && !StringIsEmpty(body))
     {
      SendNotification(subject + ": " + body);
     }
  }

void WriteDailySummary()
  {
   // Compose a summary of the previous day’s trading
   string summary;
   summary  = "Daily Summary for " + TimeToString(lastDay, TIME_DATE) + "\n";
   summary += "Trades Taken: "   + IntegerToString(dailyTradeCount) + "\n";
   summary += "Start Equity: "   + DoubleToString(dailyStartEquity,2) + "\n";
   summary += "End Equity: "     + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2) + "\n";
   summary += "High Equity: "    + DoubleToString(highestIntradayEquity,2) + "\n";
   summary += "Low Equity: "     + DoubleToString(lowestIntradayEquity,2) + "\n";
   summary += "Consec Losses: "  + IntegerToString(consecutiveLosses) + "\n";
   Print(summary);

   if(StringCompare(Mode, "LIVE") == 0)
      SendEmailPush("Daily EA Summary", summary);
  }

//+------------------------------------------------------------------+
//|                    Module 9: Optimization / Monte Carlo          |
//+------------------------------------------------------------------+
void MonteCarloSeedGenerator()
  {
   // Placeholder: In Strategy Tester, you can randomize slippage or order delays.
   // For now, just log a random seed.
   int seed = MathRand();
   LogDiagnosticEvent("Monte Carlo Seed: " + IntegerToString(seed));
  }
//+------------------------------------------------------------------+
