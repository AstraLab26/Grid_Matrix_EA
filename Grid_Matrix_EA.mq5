//+------------------------------------------------------------------+
//|                                              Grid_Matrix_EA.mq5 |
//|                                 Expert Advisor Grid Matrix v1.0  |
//|                        4 loai lenh doc lap: BL, SL, BS, SS       |
//+------------------------------------------------------------------+
#property copyright "Grid Matrix EA"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| THAM SỐ ĐẦU VÀO - INPUT PARAMETERS                               |
//+------------------------------------------------------------------+
input group "=== CẤU HÌNH CHÍNH ==="
input int    MagicNumber      = 123456;        // Mã định danh EA (Magic Number)
input string TradeComment     = "GridMatrix";  // Ghi chú lệnh

input group "=== CẤU HÌNH LƯỚI (GRID) ==="
input double StartLot         = 0.01;          // Khối lượng lệnh đầu tiên (lots)
input int    InitialOffsetPips = 10;           // Khoảng cách lệnh đầu từ giá hiện tại (pips)
input int    GridGapPips      = 50;            // Khoảng cách giữa các lệnh (pips)
input int    MaxOrdersPerSide = 5;             // Số lệnh tối đa MỖI CHIỀU

input group "=== BUY LIMIT ==="
input bool   UseBuyLimit           = true;     // Bật lệnh Buy Limit
input bool   BuyLimitLotMultiply   = true;     // Gấp thếp NHÂN cho Buy Limit
input double BuyLimitMultiplier    = 1.5;      // Hệ số nhân Buy Limit
input bool   BuyLimitLotAdd        = false;    // Gấp thếp CỘNG cho Buy Limit
input double BuyLimitAddition      = 0.01;     // Bước cộng Buy Limit
input bool   UseBuyLimitTP         = false;    // Bật TP riêng cho Buy Limit
input int    BuyLimitTPPips        = 50;       // TP Buy Limit (pips)

input group "=== SELL LIMIT ==="
input bool   UseSellLimit          = true;     // Bật lệnh Sell Limit
input bool   SellLimitLotMultiply  = true;     // Gấp thếp NHÂN cho Sell Limit
input double SellLimitMultiplier   = 1.5;      // Hệ số nhân Sell Limit
input bool   SellLimitLotAdd       = false;    // Gấp thếp CỘNG cho Sell Limit
input double SellLimitAddition     = 0.01;     // Bước cộng Sell Limit
input bool   UseSellLimitTP        = false;    // Bật TP riêng cho Sell Limit
input int    SellLimitTPPips       = 50;       // TP Sell Limit (pips)

input group "=== BUY STOP ==="
input bool   UseBuyStop            = false;    // Bật lệnh Buy Stop
input bool   BuyStopLotMultiply    = false;    // Gấp thếp NHÂN cho Buy Stop
input double BuyStopMultiplier     = 1.5;      // Hệ số nhân Buy Stop
input bool   BuyStopLotAdd         = false;    // Gấp thếp CỘNG cho Buy Stop
input double BuyStopAddition       = 0.01;     // Bước cộng Buy Stop
input bool   UseBuyStopTP          = false;    // Bật TP riêng cho Buy Stop
input int    BuyStopTPPips         = 50;       // TP Buy Stop (pips)

input group "=== SELL STOP ==="
input bool   UseSellStop           = false;    // Bật lệnh Sell Stop
input bool   SellStopLotMultiply   = false;    // Gấp thếp NHÂN cho Sell Stop
input double SellStopMultiplier    = 1.5;      // Hệ số nhân Sell Stop
input bool   SellStopLotAdd        = false;    // Gấp thếp CỘNG cho Sell Stop
input double SellStopAddition      = 0.01;     // Bước cộng Sell Stop
input bool   UseSellStopTP         = false;    // Bật TP riêng cho Sell Stop
input int    SellStopTPPips        = 50;       // TP Sell Stop (pips)

input group "=== CHỐT LỜI / CẮT LỖ THEO TIỀN ==="
input double TakeProfitMoney  = 100.0;         // Chốt lời khi lãi đạt (USD)
input double StopLossMoney    = 200.0;         // Cắt lỗ khi lỗ đạt (USD)

input group "=== TỰ ĐỘNG RESET EA ==="
input bool   AutoResetOnTP    = true;          // Tự động reset khi đạt TP
input bool   AutoResetOnSL    = false;         // Tự động reset khi đạt SL

input group "=== TP TỔNG DỪNG EA ==="
input double TotalTakeProfitMoney = 500.0;     // TP tổng để dừng EA (USD, 0=tắt)

input group "=== CẤU HÌNH HIỂN THỊ ==="
input bool   ShowPanel        = true;          // Hiển thị panel thông tin
input color  PanelColor       = clrBlack;      // Màu chữ panel
input int    PanelFontSize    = 10;            // Cỡ chữ panel

//+------------------------------------------------------------------+
//| BIEN TOAN CUC - GLOBAL VARIABLES                                 |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  positionInfo;
COrderInfo     orderInfo;

double         g_point;
int            g_digits;
double         g_pipValue;
bool           g_isFirstRun = true;
int            g_tpCount = 0;
int            g_slCount = 0;
double         g_maxDrawdown = 0;
double         g_maxProfit = 0;
double         g_totalProfitAccum = 0;
bool           g_isStopped = false;
bool           g_isPaused = false;

// Dem so lenh TP rieng cho tung loai
int            g_buyLimitTPCount = 0;
int            g_sellLimitTPCount = 0;
int            g_buyStopTPCount = 0;
int            g_sellStopTPCount = 0;

//+------------------------------------------------------------------+
//| Ham khoi tao EA                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   
   g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   if(g_digits == 3 || g_digits == 5)
      g_pipValue = g_point * 10;
   else
      g_pipValue = g_point;
   
   g_isFirstRun = true;
   
   if(ShowPanel)
      CreatePanel();
   
   g_maxDrawdown = 0;
   g_totalProfitAccum = 0;
   g_isStopped = false;
   g_isPaused = false;
   
   Print("=== GRID MATRIX EA v1.0 da khoi dong ===");
   Print("Cap tien: ", _Symbol);
   Print("Khoang cach Grid: ", GridGapPips, " pips");
   Print("Lot dau: ", StartLot);
   Print("So lenh toi da moi chieu: ", MaxOrdersPerSide);
   Print("Buy Limit: ", UseBuyLimit ? "BAT" : "TAT", " | Sell Limit: ", UseSellLimit ? "BAT" : "TAT");
   Print("Buy Stop: ", UseBuyStop ? "BAT" : "TAT", " | Sell Stop: ", UseSellStop ? "BAT" : "TAT");
   Print("Tu dong reset khi TP: ", AutoResetOnTP ? "BAT" : "TAT");
   Print("Tu dong reset khi SL: ", AutoResetOnSL ? "BAT" : "TAT");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Ham huy EA                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, "GM_Panel_");
   ObjectsDeleteAll(0, "GM_Btn_");
   Print("=== GRID MATRIX EA da dung ===");
   Print("Tong so lan TP: ", g_tpCount);
   Print("Tong so lan SL: ", g_slCount);
}

//+------------------------------------------------------------------+
//| Xu ly su kien chart (click button)                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Debug: In ra moi su kien click
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      Print(">>> CHART EVENT: Click vao object: ", sparam);
   }
   
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == "GM_Btn_Start")
      {
         ObjectSetInteger(0, "GM_Btn_Start", OBJPROP_STATE, false);
         if(g_isPaused)
         {
            g_isPaused = false;
            g_isFirstRun = true;
            Print(">>> NUT BAT EA - EA bat dau chay lai!");
         }
         else if(g_isStopped)
         {
            Print(">>> EA da dung do dat TP tong. Nhan RESET de bat dau lai!");
         }
         else
         {
            Print(">>> EA dang chay roi!");
         }
      }
      else if(sparam == "GM_Btn_Stop")
      {
         ObjectSetInteger(0, "GM_Btn_Stop", OBJPROP_STATE, false);
         if(!g_isPaused && !g_isStopped)
         {
            g_isPaused = true;
            DeleteAllPendingOrders();
            Print(">>> NUT TAT EA - Da xoa lenh cho, EA tam dung!");
         }
         else
         {
            Print(">>> EA da dung roi!");
         }
      }
      else if(sparam == "GM_Btn_Reset")
      {
         ObjectSetInteger(0, "GM_Btn_Reset", OBJPROP_STATE, false);
         Print(">>> NUT RESET EA - Bat dau reset toan bo!");
         Print(">>> Luu y: Se dong TAT CA vi the va lenh cho tren ", _Symbol, " (khong loc Magic)");
         
         // Buoc 1: Dong TAT CA vi the tren symbol (KHONG loc Magic)
         int maxAttempts = 10;
         for(int attempt = 0; attempt < maxAttempts; attempt++)
         {
            int posCount = CountAllPositionsOnSymbol();
            if(posCount == 0) break;
            
            Print(">>> Dong vi the lan ", attempt + 1, " - Con ", posCount, " vi the tren ", _Symbol);
            CloseAllPositionsForce();
            Sleep(500);
         }
         
         // Buoc 2: Xoa TAT CA lenh cho tren symbol (KHONG loc Magic)
         for(int attempt = 0; attempt < maxAttempts; attempt++)
         {
            int orderCount = CountAllPendingOrdersOnSymbol();
            if(orderCount == 0) break;
            
            Print(">>> Xoa lenh cho lan ", attempt + 1, " - Con ", orderCount, " lenh tren ", _Symbol);
            DeleteAllPendingOrdersForce();
            Sleep(500);
         }
         
         // Buoc 3: Reset tat ca bien (KHONG reset g_maxDrawdown va g_maxProfit)
         g_tpCount = 0;
         g_slCount = 0;
         g_totalProfitAccum = 0;
         g_isStopped = false;
         g_isPaused = true;
         g_isFirstRun = true;
         // Reset bien dem lenh TP
         g_buyLimitTPCount = 0;
         g_sellLimitTPCount = 0;
         g_buyStopTPCount = 0;
         g_sellStopTPCount = 0;
         
         // Buoc 4: Cap nhat panel
         if(ShowPanel)
         {
            UpdatePanel(0, 0, 0, 0, 0);
         }
         
         // Buoc 5: Buoc redraw chart
         ChartRedraw(0);
         
         int remainPos = CountAllPositionsOnSymbol();
         int remainOrders = CountAllPendingOrdersOnSymbol();
         Print(">>> RESET HOAN TAT!");
         Print(">>> Vi the con tren ", _Symbol, ": ", remainPos);
         Print(">>> Lenh cho con tren ", _Symbol, ": ", remainOrders);
         Print(">>> g_tpCount=", g_tpCount, " g_slCount=", g_slCount);
         Print(">>> g_maxDrawdown=", g_maxDrawdown, " g_totalProfitAccum=", g_totalProfitAccum);
         Print(">>> g_isPaused=", g_isPaused, " g_isStopped=", g_isStopped);
         
         if(remainPos > 0 || remainOrders > 0)
         {
            Print(">>> CANH BAO: Van con lenh chua xoa duoc! Thu lai hoac xoa thu cong.");
         }
         else
         {
            Print(">>> Nhan BAT EA de chay lai!");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Ham xu ly moi tick gia                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   // Neu EA da dung (dat TP tong)
   if(g_isStopped)
   {
      int pendingCount = CountAllPendingOrders();
      if(pendingCount > 0)
      {
         DeleteAllPendingOrders();
         Print(">>> Da xoa het lenh cho - EA dung hoan toan");
      }
      
      // Van cap nhat panel nhung KHONG cap nhat maxDrawdown
      if(ShowPanel)
      {
         double totalProfit = CalculateTotalProfit();
         int buyPos = CountPositions(POSITION_TYPE_BUY);
         int sellPos = CountPositions(POSITION_TYPE_SELL);
         int buyPend = CountPendingOrders(ORDER_TYPE_BUY_LIMIT);
         int sellPend = CountPendingOrders(ORDER_TYPE_SELL_LIMIT);
         UpdatePanel(totalProfit, buyPos, sellPos, buyPend, sellPend);
      }
      return;
   }
   
   // Neu EA tam dung (nguoi dung nhan nut TAT hoac RESET)
   if(g_isPaused)
   {
      // Van cap nhat panel nhung KHONG cap nhat maxDrawdown
      if(ShowPanel)
      {
         double totalProfit = CalculateTotalProfit();
         int buyPos = CountPositions(POSITION_TYPE_BUY);
         int sellPos = CountPositions(POSITION_TYPE_SELL);
         int buyPend = CountPendingOrders(ORDER_TYPE_BUY_LIMIT);
         int sellPend = CountPendingOrders(ORDER_TYPE_SELL_LIMIT);
         UpdatePanel(totalProfit, buyPos, sellPos, buyPend, sellPend);
      }
      return;
   }
   
   // Chi tinh toan khi EA dang chay
   double totalProfit = CalculateTotalProfit();
   int buyPositions = CountPositions(POSITION_TYPE_BUY);
   int sellPositions = CountPositions(POSITION_TYPE_SELL);
   int buyPending = CountPendingOrders(ORDER_TYPE_BUY_LIMIT);
   int sellPending = CountPendingOrders(ORDER_TYPE_SELL_LIMIT);
   int totalPositions = buyPositions + sellPositions;
   int totalPending = buyPending + sellPending;
   int totalOrders = totalPositions + totalPending;
   
   // Chi cap nhat maxDrawdown va maxProfit khi EA DANG CHAY (khong pause/stop)
   if(totalProfit < g_maxDrawdown)
      g_maxDrawdown = totalProfit;
   if(totalProfit > g_maxProfit)
      g_maxProfit = totalProfit;
   
   if(ShowPanel)
      UpdatePanel(totalProfit, buyPositions, sellPositions, buyPending, sellPending);
   
   // Kiem tra TP tong - chi dung khi KHONG con vi the dang mo
   if(TotalTakeProfitMoney > 0 && g_totalProfitAccum >= TotalTakeProfitMoney && totalPositions == 0)
   {
      Print(">>> DA DAT TP TONG! Tong lai: ", DoubleToString(g_totalProfitAccum, 2), " USD");
      Print(">>> EA DUNG - Khong mo them lenh nao nua!");
      g_isStopped = true;
      DeleteAllPendingOrders();
      return;
   }
   
   // Kiem tra chot loi
   if(totalProfit >= TakeProfitMoney && TakeProfitMoney > 0 && totalOrders > 0)
   {
      Print(">>> CHOT LOI dat! Lai: ", DoubleToString(totalProfit, 2), " USD. Dong tat ca lenh...");
      CloseAllPositions();
      DeleteAllPendingOrders();
      g_tpCount++;
      g_totalProfitAccum += totalProfit;
      
      Print(">>> Tong lai tich luy: ", DoubleToString(g_totalProfitAccum, 2), " USD");
      
      // Kiem tra TP tong sau khi chot loi
      if(TotalTakeProfitMoney > 0 && g_totalProfitAccum >= TotalTakeProfitMoney)
      {
         Print(">>> DA DAT TP TONG! Tong lai: ", DoubleToString(g_totalProfitAccum, 2), " USD");
         Print(">>> EA DUNG - Khong mo them lenh nao nua!");
         g_isStopped = true;
         return;
      }
      
      if(AutoResetOnTP)
      {
         Print(">>> TU DONG RESET EA - Bat dau vong moi...");
         Print(">>> Max Drawdown hien tai: ", DoubleToString(g_maxDrawdown, 2), " USD");
         // Reset bien dem lenh TP
         g_buyLimitTPCount = 0;
         g_sellLimitTPCount = 0;
         g_buyStopTPCount = 0;
         g_sellStopTPCount = 0;
         Sleep(1000);
         g_isFirstRun = true;
      }
      return;
   }
   
   // Kiem tra cat lo
   if(totalProfit <= -StopLossMoney && StopLossMoney > 0 && totalOrders > 0)
   {
      Print(">>> CAT LO dat! Lo: ", DoubleToString(totalProfit, 2), " USD. Dong tat ca lenh...");
      CloseAllPositions();
      DeleteAllPendingOrders();
      g_slCount++;
      g_totalProfitAccum += totalProfit;
      
      Print(">>> Tong lai tich luy: ", DoubleToString(g_totalProfitAccum, 2), " USD");
      
      if(AutoResetOnSL)
      {
         Print(">>> TU DONG RESET EA - Bat dau vong moi...");
         Print(">>> Max Drawdown hien tai: ", DoubleToString(g_maxDrawdown, 2), " USD");
         // Reset bien dem lenh TP
         g_buyLimitTPCount = 0;
         g_sellLimitTPCount = 0;
         g_buyStopTPCount = 0;
         g_sellStopTPCount = 0;
         Sleep(1000);
         g_isFirstRun = true;
      }
      return;
   }
   
   // Lan chay dau tien hoac sau khi reset - Dat tat ca lenh LIMIT ngay
   if(g_isFirstRun)
   {
      PlaceAllGridOrders();
      g_isFirstRun = false;
      return;
   }
   
   // Quan ly luoi BUY - Bo sung lenh neu can
   if(UseBuyLimit || UseSellStop)
   {
      int totalBuy = buyPositions + buyPending;
      if(totalBuy < MaxOrdersPerSide)
      {
         ManageGridBuy(totalBuy);
      }
   }
   
   // Quan ly luoi SELL - Bo sung lenh neu can
   if(UseSellLimit || UseBuyStop)
   {
      int totalSell = sellPositions + sellPending;
      if(totalSell < MaxOrdersPerSide)
      {
         ManageGridSell(totalSell);
      }
   }
}

//+------------------------------------------------------------------+
//| Dat tat ca lenh Grid ngay khi khoi dong                          |
//+------------------------------------------------------------------+
void PlaceAllGridOrders()
{
   Print(">>> Dat tat ca lenh Grid...");
   Print(">>> Khoang cach dau: ", InitialOffsetPips, " pips, Khoang cach luoi: ", GridGapPips, " pips");
   
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Dat lenh phia DUOI gia hien tai (BUY LIMIT va SELL STOP)
   // Lenh 1: cach gia hien tai InitialOffsetPips
   // Lenh 2+: cach lenh truoc GridGapPips
   for(int i = 1; i <= MaxOrdersPerSide; i++)
   {
      double orderPrice;
      if(i == 1)
         orderPrice = currentAsk - InitialOffsetPips * g_pipValue;
      else
         orderPrice = currentAsk - InitialOffsetPips * g_pipValue - GridGapPips * g_pipValue * (i - 1);
      
      // Dat BUY LIMIT neu bat
      if(UseBuyLimit)
      {
         double lot = CalculateBuyLimitLot(i);
         PlaceBuyLimit(orderPrice, lot, i);
      }
      
      // Dat SELL STOP trung vi tri
      if(UseSellStop)
      {
         double lot = CalculateSellStopLot(i);
         PlaceSellStop(orderPrice, lot, i);
      }
   }
   
   // Dat lenh phia TREN gia hien tai (SELL LIMIT va BUY STOP)
   // Lenh 1: cach gia hien tai InitialOffsetPips
   // Lenh 2+: cach lenh truoc GridGapPips
   for(int i = 1; i <= MaxOrdersPerSide; i++)
   {
      double orderPrice;
      if(i == 1)
         orderPrice = currentBid + InitialOffsetPips * g_pipValue;
      else
         orderPrice = currentBid + InitialOffsetPips * g_pipValue + GridGapPips * g_pipValue * (i - 1);
      
      // Dat SELL LIMIT neu bat
      if(UseSellLimit)
      {
         double lot = CalculateSellLimitLot(i);
         PlaceSellLimit(orderPrice, lot, i);
      }
      
      // Dat BUY STOP trung vi tri
      if(UseBuyStop)
      {
         double lot = CalculateBuyStopLot(i);
         PlaceBuyStop(orderPrice, lot, i);
      }
   }
   
   Print(">>> Da dat xong tat ca lenh Grid!");
}

//+------------------------------------------------------------------+
//| Quan ly luoi BUY - Bo sung lenh BUY LIMIT (va SELL STOP)         |
//+------------------------------------------------------------------+
void ManageGridBuy(int currentBuyOrders)
{
   if(currentBuyOrders >= MaxOrdersPerSide) return;
   
   double lowestPrice = GetLowestBuyPrice();
   
   int ordersToPlace = MaxOrdersPerSide - currentBuyOrders;
   double nextPrice = lowestPrice;
   
   for(int i = 0; i < ordersToPlace; i++)
   {
      nextPrice = nextPrice - GridGapPips * g_pipValue;
      int orderNum = currentBuyOrders + i + 1;
      
      // Dat BUY LIMIT neu bat
      if(UseBuyLimit)
      {
         double lot = CalculateBuyLimitLot(orderNum);
         PlaceBuyLimit(nextPrice, lot, orderNum);
      }
      
      // Dat SELL STOP trung vi tri
      if(UseSellStop)
      {
         double lot = CalculateSellStopLot(orderNum);
         PlaceSellStop(nextPrice, lot, orderNum);
      }
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi SELL - Bo sung lenh SELL LIMIT (va BUY STOP)        |
//+------------------------------------------------------------------+
void ManageGridSell(int currentSellOrders)
{
   if(currentSellOrders >= MaxOrdersPerSide) return;
   
   double highestPrice = GetHighestSellPrice();
   
   int ordersToPlace = MaxOrdersPerSide - currentSellOrders;
   double nextPrice = highestPrice;
   
   for(int i = 0; i < ordersToPlace; i++)
   {
      nextPrice = nextPrice + GridGapPips * g_pipValue;
      int orderNum = currentSellOrders + i + 1;
      
      // Dat SELL LIMIT neu bat
      if(UseSellLimit)
      {
         double lot = CalculateSellLimitLot(orderNum);
         PlaceSellLimit(nextPrice, lot, orderNum);
      }
      
      // Dat BUY STOP trung vi tri
      if(UseBuyStop)
      {
         double lot = CalculateBuyStopLot(orderNum);
         PlaceBuyStop(nextPrice, lot, orderNum);
      }
   }
}

//+------------------------------------------------------------------+
//| Lay gia thap nhat cua cac lenh BUY (vi the + lenh cho)           |
//+------------------------------------------------------------------+
double GetLowestBuyPrice()
{
   double lowestPrice = DBL_MAX;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(orderInfo.OrderType() == ORDER_TYPE_BUY_LIMIT)
            {
               if(orderInfo.PriceOpen() < lowestPrice)
                  lowestPrice = orderInfo.PriceOpen();
            }
         }
      }
   }
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            if(positionInfo.PositionType() == POSITION_TYPE_BUY)
            {
               if(positionInfo.PriceOpen() < lowestPrice)
                  lowestPrice = positionInfo.PriceOpen();
            }
         }
      }
   }
   
   if(lowestPrice == DBL_MAX)
      lowestPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   return lowestPrice;
}

//+------------------------------------------------------------------+
//| Lay gia cao nhat cua cac lenh SELL (vi the + lenh cho)           |
//+------------------------------------------------------------------+
double GetHighestSellPrice()
{
   double highestPrice = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(orderInfo.OrderType() == ORDER_TYPE_SELL_LIMIT)
            {
               if(orderInfo.PriceOpen() > highestPrice)
                  highestPrice = orderInfo.PriceOpen();
            }
         }
      }
   }
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            if(positionInfo.PositionType() == POSITION_TYPE_SELL)
            {
               if(positionInfo.PriceOpen() > highestPrice)
                  highestPrice = positionInfo.PriceOpen();
            }
         }
      }
   }
   
   if(highestPrice == 0)
      highestPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   return highestPrice;
}

//+------------------------------------------------------------------+
//| Dem so lenh cho theo tung loai                                   |
//+------------------------------------------------------------------+
void CountPendingByType(int &buyLimitPending, int &sellLimitPending, int &buyStopPending, int &sellStopPending)
{
   buyLimitPending = 0;
   sellLimitPending = 0;
   buyStopPending = 0;
   sellStopPending = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            ENUM_ORDER_TYPE orderType = orderInfo.OrderType();
            if(orderType == ORDER_TYPE_BUY_LIMIT) buyLimitPending++;
            else if(orderType == ORDER_TYPE_SELL_LIMIT) sellLimitPending++;
            else if(orderType == ORDER_TYPE_BUY_STOP) buyStopPending++;
            else if(orderType == ORDER_TYPE_SELL_STOP) sellStopPending++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Dem so vi the dang mo theo tung loai                             |
//+------------------------------------------------------------------+
void CountPositionsByType(int &buyPositions, int &sellPositions)
{
   buyPositions = 0;
   sellPositions = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            if(positionInfo.PositionType() == POSITION_TYPE_BUY) buyPositions++;
            else if(positionInfo.PositionType() == POSITION_TYPE_SELL) sellPositions++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Tinh khoi luong lenh BUY LIMIT                                   |
//+------------------------------------------------------------------+
double CalculateBuyLimitLot(int orderNumber)
{
   double lot = StartLot;
   
   if(BuyLimitLotMultiply)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot * BuyLimitMultiplier;
   }
   else if(BuyLimitLotAdd)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot + BuyLimitAddition;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Tinh khoi luong lenh SELL LIMIT                                  |
//+------------------------------------------------------------------+
double CalculateSellLimitLot(int orderNumber)
{
   double lot = StartLot;
   
   if(SellLimitLotMultiply)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot * SellLimitMultiplier;
   }
   else if(SellLimitLotAdd)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot + SellLimitAddition;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Tinh khoi luong lenh BUY STOP                                    |
//+------------------------------------------------------------------+
double CalculateBuyStopLot(int orderNumber)
{
   double lot = StartLot;
   
   if(BuyStopLotMultiply)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot * BuyStopMultiplier;
   }
   else if(BuyStopLotAdd)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot + BuyStopAddition;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Tinh khoi luong lenh SELL STOP                                   |
//+------------------------------------------------------------------+
double CalculateSellStopLot(int orderNumber)
{
   double lot = StartLot;
   
   if(SellStopLotMultiply)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot * SellStopMultiplier;
   }
   else if(SellStopLotAdd)
   {
      for(int i = 1; i < orderNumber; i++)
         lot = lot + SellStopAddition;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Chuan hoa lot size                                               |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   lot = NormalizeDouble(lot, 2);
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lot = MathMax(minLot, lot);
   lot = MathMin(maxLot, lot);
   lot = MathFloor(lot / lotStep) * lotStep;
   
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Dat lenh Buy Stop                                                |
//+------------------------------------------------------------------+
bool PlaceBuyStop(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(price <= currentAsk)
   {
      return false;
   }
   
   if(IsOrderAtPrice(price, ORDER_TYPE_BUY_STOP))
   {
      return false;
   }
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseBuyStopTP && BuyStopTPPips > 0)
   {
      tp = NormalizeDouble(price + BuyStopTPPips * g_pipValue, g_digits);
   }
   
   string comment = TradeComment + "_BS" + IntegerToString(orderNum);
   
   if(trade.BuyStop(lot, price, _Symbol, 0, tp, ORDER_TIME_GTC, 0, comment))
   {
      Print("Dat BUY STOP #", orderNum, ": Gia=", DoubleToString(price, g_digits), " Lot=", DoubleToString(lot, 2), " TP=", DoubleToString(tp, g_digits));
      return true;
   }
   else
   {
      Print("Loi dat BUY STOP: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Dat lenh Sell Stop                                               |
//+------------------------------------------------------------------+
bool PlaceSellStop(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price >= currentBid)
   {
      return false;
   }
   
   if(IsOrderAtPrice(price, ORDER_TYPE_SELL_STOP))
   {
      return false;
   }
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseSellStopTP && SellStopTPPips > 0)
   {
      tp = NormalizeDouble(price - SellStopTPPips * g_pipValue, g_digits);
   }
   
   string comment = TradeComment + "_SS" + IntegerToString(orderNum);
   
   if(trade.SellStop(lot, price, _Symbol, 0, tp, ORDER_TIME_GTC, 0, comment))
   {
      Print("Dat SELL STOP #", orderNum, ": Gia=", DoubleToString(price, g_digits), " Lot=", DoubleToString(lot, 2), " TP=", DoubleToString(tp, g_digits));
      return true;
   }
   else
   {
      Print("Loi dat SELL STOP: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Dat lenh Buy Limit                                               |
//+------------------------------------------------------------------+
bool PlaceBuyLimit(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(price >= currentAsk)
   {
      return false;
   }
   
   if(IsOrderAtPrice(price, ORDER_TYPE_BUY_LIMIT))
   {
      return false;
   }
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseBuyLimitTP && BuyLimitTPPips > 0)
   {
      tp = NormalizeDouble(price + BuyLimitTPPips * g_pipValue, g_digits);
   }
   
   string comment = TradeComment + "_B" + IntegerToString(orderNum);
   
   if(trade.BuyLimit(lot, price, _Symbol, 0, tp, ORDER_TIME_GTC, 0, comment))
   {
      Print("Dat BUY LIMIT #", orderNum, ": Gia=", DoubleToString(price, g_digits), " Lot=", DoubleToString(lot, 2), " TP=", DoubleToString(tp, g_digits));
      return true;
   }
   else
   {
      Print("Loi dat BUY LIMIT: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Dat lenh Sell Limit                                              |
//+------------------------------------------------------------------+
bool PlaceSellLimit(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price <= currentBid)
   {
      return false;
   }
   
   if(IsOrderAtPrice(price, ORDER_TYPE_SELL_LIMIT))
   {
      return false;
   }
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseSellLimitTP && SellLimitTPPips > 0)
   {
      tp = NormalizeDouble(price - SellLimitTPPips * g_pipValue, g_digits);
   }
   
   string comment = TradeComment + "_S" + IntegerToString(orderNum);
   
   if(trade.SellLimit(lot, price, _Symbol, 0, tp, ORDER_TIME_GTC, 0, comment))
   {
      Print("Dat SELL LIMIT #", orderNum, ": Gia=", DoubleToString(price, g_digits), " Lot=", DoubleToString(lot, 2), " TP=", DoubleToString(tp, g_digits));
      return true;
   }
   else
   {
      Print("Loi dat SELL LIMIT: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Kiem tra da co lenh tai muc gia chua                             |
//+------------------------------------------------------------------+
bool IsOrderAtPrice(double price, ENUM_ORDER_TYPE orderType)
{
   double tolerance = g_pipValue * 2;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(orderInfo.OrderType() == orderType)
            {
               if(MathAbs(orderInfo.PriceOpen() - price) < tolerance)
                  return true;
            }
         }
      }
   }
   
   // Xac dinh loai vi the tuong ung
   ENUM_POSITION_TYPE posType;
   if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
      posType = POSITION_TYPE_BUY;
   else
      posType = POSITION_TYPE_SELL;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            if(positionInfo.PositionType() == posType)
            {
               if(MathAbs(positionInfo.PriceOpen() - price) < tolerance)
                  return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Dem tong so vi the cua EA (loc theo Magic)                       |
//+------------------------------------------------------------------+
int CountAllPositions()
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Dem TAT CA vi the tren symbol (KHONG loc Magic)                  |
//+------------------------------------------------------------------+
int CountAllPositionsOnSymbol()
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Dem tong so lenh cho cua EA (loc theo Magic)                     |
//+------------------------------------------------------------------+
int CountAllPendingOrders()
{
   int count = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Dem TAT CA lenh cho tren symbol (KHONG loc Magic)                |
//+------------------------------------------------------------------+
int CountAllPendingOrdersOnSymbol()
{
   int count = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Dem so vi the theo loai                                          |
//+------------------------------------------------------------------+
int CountPositions(ENUM_POSITION_TYPE posType)
{
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            if(positionInfo.PositionType() == posType)
               count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Dem so lenh cho theo loai                                        |
//+------------------------------------------------------------------+
int CountPendingOrders(ENUM_ORDER_TYPE orderType)
{
   int count = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(orderInfo.OrderType() == orderType)
               count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Tinh tong loi nhuan (bao gom swap va commission)                 |
//+------------------------------------------------------------------+
double CalculateTotalProfit()
{
   double totalProfit = 0;
   double totalSwap = 0;
   double totalCommission = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            totalProfit += positionInfo.Profit();
            totalSwap += positionInfo.Swap();
            totalCommission += positionInfo.Commission();
         }
      }
   }
   
   return totalProfit + totalSwap + totalCommission;
}

//+------------------------------------------------------------------+
//| Dong tat ca vi the (chi cua EA nay - theo MagicNumber)           |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            ulong ticket = positionInfo.Ticket();
            if(trade.PositionClose(ticket))
               Print("Dong vi the thanh cong: Ticket=", ticket);
            else
               Print("Loi dong vi the: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Dong TAT CA vi the tren symbol (KHONG loc Magic - dung cho RESET)|
//+------------------------------------------------------------------+
void CloseAllPositionsForce()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol)
         {
            ulong ticket = positionInfo.Ticket();
            long magic = positionInfo.Magic();
            if(trade.PositionClose(ticket))
               Print("FORCE Dong vi the: Ticket=", ticket, " Magic=", magic);
            else
               Print("Loi dong vi the: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Xoa tat ca lenh cho (chi cua EA nay - theo MagicNumber)          |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            ulong ticket = orderInfo.Ticket();
            if(trade.OrderDelete(ticket))
               Print("Xoa lenh cho thanh cong: Ticket=", ticket);
            else
               Print("Loi xoa lenh cho: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Xoa TAT CA lenh cho tren symbol (KHONG loc Magic - dung cho RESET)|
//+------------------------------------------------------------------+
void DeleteAllPendingOrdersForce()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol)
         {
            ulong ticket = orderInfo.Ticket();
            long magic = orderInfo.Magic();
            if(trade.OrderDelete(ticket))
               Print("FORCE Xoa lenh cho: Ticket=", ticket, " Magic=", magic);
            else
               Print("Loi xoa lenh cho: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Tạo panel hiển thị                                               |
//+------------------------------------------------------------------+
void CreatePanel()
{
   int x = 10;
   int y = 30;
   int lineHeight = 18;
   
   CreateLabel("GM_Panel_Title", "=== GRID MATRIX EA v1.0 ===", x, y, PanelColor, PanelFontSize + 2);
   y += lineHeight + 5;
   
   CreateLabel("GM_Panel_Symbol", "Cặp tiền: " + _Symbol, x, y, PanelColor, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_Profit", "Lợi nhuận: 0.00 USD", x, y, PanelColor, PanelFontSize);
   y += lineHeight;
   
   // Chi tiet tung loai lenh
   CreateLabel("GM_Panel_BuyLimit", "Buy Limit: 0/" + IntegerToString(MaxOrdersPerSide), x, y, clrBlue, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_SellLimit", "Sell Limit: 0/" + IntegerToString(MaxOrdersPerSide), x, y, clrRed, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_BuyStop", "Buy Stop: 0/" + IntegerToString(MaxOrdersPerSide), x, y, clrDodgerBlue, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_SellStop", "Sell Stop: 0/" + IntegerToString(MaxOrdersPerSide), x, y, clrOrangeRed, PanelFontSize);
   y += lineHeight;
   
   // Vi the dang mo
   CreateLabel("GM_Panel_OpenBuy", "Đang mở BUY: 0", x, y, clrBlue, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_OpenSell", "Đang mở SELL: 0", x, y, clrRed, PanelFontSize);
   y += lineHeight;
   
   // Tong lenh dat TP
   CreateLabel("GM_Panel_TPOrders", "Lệnh đạt TP: 0", x, y, clrGreen, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_TP", "Chốt lời: " + DoubleToString(TakeProfitMoney, 2) + " USD", x, y, clrGreen, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_SL", "Cắt lỗ: -" + DoubleToString(StopLossMoney, 2) + " USD", x, y, clrRed, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_MaxProfit", "Lãi lớn nhất: 0.00 USD", x, y, clrGreen, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_MaxDD", "Lỗ lớn nhất: 0.00 USD", x, y, clrOrangeRed, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_TotalProfit", "Tổng lãi: 0.00 / " + DoubleToString(TotalTakeProfitMoney, 0) + " USD", x, y, clrDarkGreen, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_Status", "Trạng thái: ĐANG CHẠY", x, y, clrGreen, PanelFontSize);
   y += lineHeight;
   
   string resetText = "Reset: TP=" + (AutoResetOnTP ? "BẬT" : "TẮT") + " | SL=" + (AutoResetOnSL ? "BẬT" : "TẮT");
   CreateLabel("GM_Panel_Reset", resetText, x, y, clrGray, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_Count", "TP: 0 lần | SL: 0 lần", x, y, clrGray, PanelFontSize);
   y += lineHeight + 5;
   
   CreateButton("GM_Btn_Start", "BẬT EA", x, y, 60, 22, clrWhite, clrGreen);
   CreateButton("GM_Btn_Stop", "TẮT EA", x + 65, y, 60, 22, clrWhite, clrRed);
   CreateButton("GM_Btn_Reset", "RESET", x + 130, y, 60, 22, clrWhite, clrBlue);
}

//+------------------------------------------------------------------+
//| Tao label                                                        |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Tao button                                                       |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width, int height, color textClr, color bgClr)
{
   // Xoa button cu neu ton tai
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   // Tao button moi
   if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
   {
      Print("Loi tao button ", name, ": ", GetLastError());
      return;
   }
   
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textClr);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgClr);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bgClr);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);
}

//+------------------------------------------------------------------+
//| Cập nhật panel                                                   |
//+------------------------------------------------------------------+
void UpdatePanel(double profit, int buyPos, int sellPos, int buyPending, int sellPending)
{
   color profitColor = profit >= 0 ? clrGreen : clrRed;
   
   ObjectSetString(0, "GM_Panel_Profit", OBJPROP_TEXT, "Lợi nhuận: " + DoubleToString(profit, 2) + " USD");
   ObjectSetInteger(0, "GM_Panel_Profit", OBJPROP_COLOR, profitColor);
   
   // Dem lenh cho theo tung loai
   int buyLimitPending, sellLimitPending, buyStopPending, sellStopPending;
   CountPendingByType(buyLimitPending, sellLimitPending, buyStopPending, sellStopPending);
   
   // Hien thi tung loai lenh (so lenh cho / max)
   string blText = UseBuyLimit ? "Buy Limit: " + IntegerToString(buyLimitPending) + "/" + IntegerToString(MaxOrdersPerSide) : "Buy Limit: TẮT";
   string slText = UseSellLimit ? "Sell Limit: " + IntegerToString(sellLimitPending) + "/" + IntegerToString(MaxOrdersPerSide) : "Sell Limit: TẮT";
   string bsText = UseBuyStop ? "Buy Stop: " + IntegerToString(buyStopPending) + "/" + IntegerToString(MaxOrdersPerSide) : "Buy Stop: TẮT";
   string ssText = UseSellStop ? "Sell Stop: " + IntegerToString(sellStopPending) + "/" + IntegerToString(MaxOrdersPerSide) : "Sell Stop: TẮT";
   
   ObjectSetString(0, "GM_Panel_BuyLimit", OBJPROP_TEXT, blText);
   ObjectSetString(0, "GM_Panel_SellLimit", OBJPROP_TEXT, slText);
   ObjectSetString(0, "GM_Panel_BuyStop", OBJPROP_TEXT, bsText);
   ObjectSetString(0, "GM_Panel_SellStop", OBJPROP_TEXT, ssText);
   
   // Vi the dang mo
   ObjectSetString(0, "GM_Panel_OpenBuy", OBJPROP_TEXT, "Đang mở BUY: " + IntegerToString(buyPos));
   ObjectSetString(0, "GM_Panel_OpenSell", OBJPROP_TEXT, "Đang mở SELL: " + IntegerToString(sellPos));
   
   // Tong lenh dat TP
   int totalTPOrders = g_buyLimitTPCount + g_sellLimitTPCount + g_buyStopTPCount + g_sellStopTPCount;
   ObjectSetString(0, "GM_Panel_TPOrders", OBJPROP_TEXT, "Lệnh đạt TP: " + IntegerToString(totalTPOrders));
   
   ObjectSetString(0, "GM_Panel_MaxProfit", OBJPROP_TEXT, "Lãi lớn nhất: " + DoubleToString(g_maxProfit, 2) + " USD");
   ObjectSetString(0, "GM_Panel_MaxDD", OBJPROP_TEXT, "Lỗ lớn nhất: " + DoubleToString(g_maxDrawdown, 2) + " USD");
   
   ObjectSetString(0, "GM_Panel_TotalProfit", OBJPROP_TEXT, "Tổng lãi: " + DoubleToString(g_totalProfitAccum, 2) + " / " + DoubleToString(TotalTakeProfitMoney, 0) + " USD");
   color totalColor = g_totalProfitAccum >= 0 ? clrDarkGreen : clrRed;
   ObjectSetInteger(0, "GM_Panel_TotalProfit", OBJPROP_COLOR, totalColor);
   
   if(g_isStopped)
   {
      ObjectSetString(0, "GM_Panel_Status", OBJPROP_TEXT, "Trạng thái: ĐÃ DỪNG (TP TỔNG)");
      ObjectSetInteger(0, "GM_Panel_Status", OBJPROP_COLOR, clrRed);
   }
   else if(g_isPaused)
   {
      ObjectSetString(0, "GM_Panel_Status", OBJPROP_TEXT, "Trạng thái: TẠM DỪNG");
      ObjectSetInteger(0, "GM_Panel_Status", OBJPROP_COLOR, clrOrange);
   }
   else
   {
      ObjectSetString(0, "GM_Panel_Status", OBJPROP_TEXT, "Trạng thái: ĐANG CHẠY");
      ObjectSetInteger(0, "GM_Panel_Status", OBJPROP_COLOR, clrGreen);
   }
   
   ObjectSetString(0, "GM_Panel_Count", OBJPROP_TEXT, "TP: " + IntegerToString(g_tpCount) + " lần | SL: " + IntegerToString(g_slCount) + " lần");
}

//+------------------------------------------------------------------+
