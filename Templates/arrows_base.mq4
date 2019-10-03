// Arrows base v1.7

#property copyright "Copyright © 2019, "
#property link      ""
#property version   "1.0"
#property strict
#property indicator_chart_window
//#property indicator_separate_window
#property indicator_buffers 8

enum SingalMode
{
   SingalModeLive, // Live
   SingalModeOnBarClose // On bar close
};

enum DisplayType
{
   Arrows, // Arrows
   Candles // Candles Color
};
input SingalMode signal_mode = SingalModeLive; // Signal mode
input DisplayType Type = Arrows; // Presentation Type
input double shift_arrows_pips = 0.1; // Shift arrows
input color up_color = Green; // Up color
input color down_color = Red; // Down color

string IndicatorName;
string IndicatorObjPrefix;

string GenerateIndicatorName(const string target)
{
   string name = target;
   int try = 2;
   while (WindowFind(name) != -1)
   {
      name = target + " #" + IntegerToString(try++);
   }
   return name;
}

#include <conditions/ABaseCondition.mq4>
#include <Streams/PriceStream.mq4>
#include <signaler.mq4>
#include <AlertSignal.mq4>
#include <Streams/CandleStreams.mq4>

AlertSignal* conditions[];
Signaler* mainSignaler;

int CreateAlert(int id, ICondition* upCondition, ICondition* downCondition)
{
   int size = ArraySize(conditions);
   ArrayResize(conditions, size + 2);
   conditions[size] = new AlertSignal(upCondition, mainSignaler, signal_mode == SingalModeOnBarClose);
   conditions[size + 1] = new AlertSignal(downCondition, mainSignaler, signal_mode == SingalModeOnBarClose);
      
   if (Type == Arrows)
   {
      PriceStream* highStream = new PriceStream(_Symbol, (ENUM_TIMEFRAMES)_Period, PriceHigh);
      highStream.SetShift(shift_arrows_pips);
      PriceStream* lowStream = new PriceStream(_Symbol, (ENUM_TIMEFRAMES)_Period, PriceLow);
      lowStream.SetShift(-shift_arrows_pips);
      id = conditions[size].RegisterStreams(id, "Up", 217, up_color, highStream);
      id = conditions[size + 1].RegisterStreams(id, "Down", 218, down_color, lowStream);
      lowStream.Release();
      highStream.Release();
   }
   else
   {
      id = conditions[size].RegisterStreams(id, "Up", up_color);
      id = conditions[size + 1].RegisterStreams(id, "Down", down_color);
   }
   return id;
}

class UpAlertCondition : public ABaseCondition
{
public:
   UpAlertCondition(const string symbol, ENUM_TIMEFRAMES timeframe)
      :ABaseCondition(symbol, timeframe)
   {

   }

   bool IsPass(const int period)
   {
      //TODO: implement
      return false;
   }
};

class DownAlertCondition : public ABaseCondition
{
public:
   DownAlertCondition(const string symbol, ENUM_TIMEFRAMES timeframe)
      :ABaseCondition(symbol, timeframe)
   {

   }

   bool IsPass(const int period)
   {
      //TODO: implement
      return false;
   }
};

int init()
{
   if (!IsDllsAllowed() && advanced_alert)
   {
      Print("Error: Dll calls must be allowed!");
      return INIT_FAILED;
   }
   IndicatorName = GenerateIndicatorName("...");
   IndicatorObjPrefix = "__" + IndicatorName + "__";
   IndicatorShortName(IndicatorName);
   mainSignaler = new Signaler(_Symbol, (ENUM_TIMEFRAMES)_Period);
   mainSignaler.SetMessagePrefix(_Symbol + "/" + mainSignaler.GetTimeframeStr() + ": ");

   int id = 0;

   ICondition* upCondition = new UpAlertCondition(_Symbol, (ENUM_TIMEFRAMES)_Period);
   ICondition* downCondition = new DownAlertCondition(_Symbol, (ENUM_TIMEFRAMES)_Period);
   id = CreateAlert(upCondition, downCondition);

   return 0;
}

int deinit()
{
   delete mainSignaler;
   mainSignaler = NULL;
   for (int i = 0; i < ArraySize(conditions); ++i)
   {
      delete conditions[i];
   }
   ArrayResize(conditions, 0);
   ObjectsDeleteAll(ChartID(), IndicatorObjPrefix);
   return 0;
}

int start()
{
   if (Bars <= 1) 
      return 0;
   int ExtCountedBars = IndicatorCounted();
   if (ExtCountedBars < 0) 
      return -1;
   int limit = ExtCountedBars > 1 ? Bars - ExtCountedBars - 1 : Bars - 1;
   for (int pos = limit; pos >= 0; --pos)
   {
      for (int i = 0; i < ArraySize(conditions); ++i)
      {
         AlertSignal* item = conditions[i];
         item.Update(pos);
      }
   } 
   return 0;
}