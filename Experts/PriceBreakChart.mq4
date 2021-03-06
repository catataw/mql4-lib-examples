//+------------------------------------------------------------------+
//| Module: Experts/PriceBreakChart.mq4                              |
//| This file is part of the mql4-lib-examples project:              |
//|     https://github.com/dingmaotu/mql4-lib-examples               |
//|                                                                  |
//| Copyright 2015-2017 Li Ding <dingmaotu@hotmail.com>              |
//|                                                                  |
//| Licensed under the Apache License, Version 2.0 (the "License");  |
//| you may not use this file except in compliance with the License. |
//| You may obtain a copy of the License at                          |
//|                                                                  |
//|     http://www.apache.org/licenses/LICENSE-2.0                   |
//|                                                                  |
//| Unless required by applicable law or agreed to in writing,       |
//| software distributed under the License is distributed on an      |
//| "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     |
//| either express or implied.                                       |
//| See the License for the specific language governing permissions  |
//| and limitations under the License.                               |
//+------------------------------------------------------------------+
#property copyright "Copyright (C) 2015-2017, Li Ding"
#property link      "dingmaotu@hotmail.com"
#property description "PriceBreak chart implementation"
#property description "Run this on any chart and any timeframe."
#property description "You can change timeframe while the EA is running and it will dynamically update the target offline chart."
#property strict

#include <Mql/UI/Chart.mqh>
#include <Mql/History/TimeSeriesData.mqh>
#include <Mql/Lang/ExpertAdvisor.mqh>
#include <Mql/Charts/PriceBreakChart.mqh>
//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
class PriceBreakChartEAParam: public AppParam
  {
   ObjectAttr(int,lookbackDistance,LookbackDistance);
   ObjectAttr(int,targetPeriod,TargetPeriod);
   ObjectAttr(bool,autoOpen,AutoOpen);
public:
   bool              check()
     {
      if(m_lookbackDistance<2)
        {
         Alert("Error: Parameter <Lookback Distance> must be larger than 2.");
         return false;
        }
      if(m_targetPeriod<1)
        {
         Alert("Error: Parameter <Target Timeframe> must be positive.");
         return false;
        }
      if(IsStandardTimeframe(m_targetPeriod))
        {
         Alert("Error: Parameter <Target Timeframe> must not be one of the standard timeframes.");
         return false;
        }
      return true;
     }
  };
//+------------------------------------------------------------------+
//| Main EA                                                          |
//+------------------------------------------------------------------+
class PriceBreakChartEA: public ExpertAdvisor
  {
private:
   PriceBreakChart   m_chart;
   TimeSeriesData    m_data;
   int               m_targetPeriod;
   MqlRates          m_lastestRates[];
protected:
   long              findTargetChartId() const
     {
      foreachchart(c)
        {
         if(c.isOffline() && c.getSymbol()==m_data.getSymbol() && c.getPeriod()==m_targetPeriod)
            return c.getId();
        }
      return 0;
     }
   void              forcePriceUpdate()
     {
      //--- as WindowHandle method has been removed in MT5,
      //--- for better compatibility we iterate through charts to find the target chart.
      foreachchart(c)
        {
         if(c.isOffline() && c.getSymbol()==m_data.getSymbol() && c.getPeriod()==m_targetPeriod)
            c.forcePriceUpdate();
        }
     }
public:
                     PriceBreakChartEA(PriceBreakChartEAParam *param);
   void              main();
  };
//+------------------------------------------------------------------+
//| Run the main method once to force update on initialization       |
//+------------------------------------------------------------------+
PriceBreakChartEA::PriceBreakChartEA(PriceBreakChartEAParam *param)
   :m_chart(param.getLookbackDistance(),param.getTargetPeriod()),
     m_data(_Symbol,PERIOD_CURRENT),
     m_targetPeriod(param.getTargetPeriod())
  {
   main();
   if(param.getAutoOpen() && findTargetChartId()==0)
     {
      ChartOpen(m_data.getSymbol(),m_targetPeriod);
     }
  }
//+------------------------------------------------------------------+
//| On the tick event, we check if new bars generate. If new bars    |
//| generate, we feed the rates to the PriceBreakChart implemention. |
//| And if there is any update for the chart, we force update for    |
//| the target offline chart.                                        |
//+------------------------------------------------------------------+
void PriceBreakChartEA::main()
  {
   m_data.updateCurrent();
   if(m_data.isNewBar())
     {
      int bars=(int)m_data.getNewBars();
      ArrayResize(m_lastestRates,bars,5);
      m_data.copyRates(1,bars,m_lastestRates);
      if(m_chart.loadHistory(m_lastestRates)>0)
         forcePriceUpdate();
     }
  }

BEGIN_INPUT(PriceBreakChartEAParam)
   INPUT(int,LookbackDistance,3);// Lookback Distance (how many bars to count before a reverse)
   INPUT(int,TargetPeriod,17);   // Target Timeframe (for offline chart)
   INPUT(bool,AutoOpen,true);    // Open the offline chart automatically
END_INPUT

DECLARE_EA(PriceBreakChartEA,true);
//+------------------------------------------------------------------+
