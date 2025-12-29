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
//| ENUM CHẾ ĐỘ GẤP THẾP LOT                                         |
//+------------------------------------------------------------------+
enum ENUM_LotScalingMode
{
   LotScale_None = 0,           // Không gấp thếp (lot cố định)
   LotScale_Multiply = 1,       // Gấp thếp NHÂN mỗi bậc
   LotScale_AddPerLevel = 2,    // Gấp thếp CỘNG mỗi bậc
   LotScale_MultiplyPerGroup = 3, // Gấp thếp NHÂN theo nhóm lưới
   LotScale_AddPerGroup = 4     // Gấp thếp CỘNG theo nhóm lưới
};

//+------------------------------------------------------------------+
//| THAM SỐ ĐẦU VÀO - INPUT PARAMETERS                               |
//+------------------------------------------------------------------+
input group "=== CẤU HÌNH CHÍNH ==="
input int    MagicNumber      = 123456;        // Mã định danh EA (Magic Number)
input string TradeComment     = "GridMatrix";  // Ghi chú lệnh

input group "=== CẤU HÌNH LƯỚI (GRID) ==="
input int    InitialOffsetPips = 20;           // Khoảng cách lệnh đầu từ giá (pips)
input int    GridGapPips      = 50;            // Khoảng cách giữa các lệnh (pips)
input int    MaxOrdersPerSide = 5;             // Số lệnh tối đa MỖI CHIỀU

input group "=== BUY LIMIT ==="
input bool   UseBuyLimit           = true;     // Bật lệnh Buy Limit
input double BuyLimitStartLot      = 0.01;     // Lot đầu tiên Buy Limit
input ENUM_LotScalingMode BuyLimitLotMode = LotScale_Multiply; // Chế độ gấp thếp lot
input double BuyLimitMultiplier    = 1.5;      // Hệ số nhân (khi chọn NHÂN)
input double BuyLimitAddition      = 0.01;     // Bước cộng lot (khi chọn CỘNG)
input int    BuyLimitGridsPerGroup = 5;        // Số lưới mỗi nhóm (khi chọn theo nhóm)
input bool   UseBuyLimitTP         = false;    // Bật TP riêng cho Buy Limit
input int    BuyLimitTPPips        = 50;       // TP Buy Limit (pips)
input bool   AutoRefillBuyLimit    = false;    // Tự động bổ sung Buy Limit khi đạt TP

input group "=== SELL LIMIT ==="
input bool   UseSellLimit          = true;     // Bật lệnh Sell Limit
input double SellLimitStartLot     = 0.01;     // Lot đầu tiên Sell Limit
input ENUM_LotScalingMode SellLimitLotMode = LotScale_Multiply; // Chế độ gấp thếp lot
input double SellLimitMultiplier   = 1.5;      // Hệ số nhân (khi chọn NHÂN)
input double SellLimitAddition     = 0.01;     // Bước cộng lot (khi chọn CỘNG)
input int    SellLimitGridsPerGroup= 5;        // Số lưới mỗi nhóm (khi chọn theo nhóm)
input bool   UseSellLimitTP        = false;    // Bật TP riêng cho Sell Limit
input int    SellLimitTPPips       = 50;       // TP Sell Limit (pips)
input bool   AutoRefillSellLimit   = false;    // Tự động bổ sung Sell Limit khi đạt TP

input group "=== BUY STOP ==="
input bool   UseBuyStop            = false;    // Bật lệnh Buy Stop
input double BuyStopStartLot       = 0.01;     // Lot đầu tiên Buy Stop
input ENUM_LotScalingMode BuyStopLotMode = LotScale_None; // Chế độ gấp thếp lot
input double BuyStopMultiplier     = 1.5;      // Hệ số nhân (khi chọn NHÂN)
input double BuyStopAddition       = 0.01;     // Bước cộng lot (khi chọn CỘNG)
input int    BuyStopGridsPerGroup  = 5;        // Số lưới mỗi nhóm (khi chọn theo nhóm)
input bool   UseBuyStopTP          = false;    // Bật TP riêng cho Buy Stop
input int    BuyStopTPPips         = 50;       // TP Buy Stop (pips)
input bool   AutoRefillBuyStop     = false;    // Tự động bổ sung Buy Stop khi đạt TP

input group "=== SELL STOP ==="
input bool   UseSellStop           = false;    // Bật lệnh Sell Stop
input double SellStopStartLot      = 0.01;     // Lot đầu tiên Sell Stop
input ENUM_LotScalingMode SellStopLotMode = LotScale_None; // Chế độ gấp thếp lot
input double SellStopMultiplier    = 1.5;      // Hệ số nhân (khi chọn NHÂN)
input double SellStopAddition      = 0.01;     // Bước cộng lot (khi chọn CỘNG)
input int    SellStopGridsPerGroup = 5;        // Số lưới mỗi nhóm (khi chọn theo nhóm)
input bool   UseSellStopTP         = false;    // Bật TP riêng cho Sell Stop
input int    SellStopTPPips        = 50;       // TP Sell Stop (pips)
input bool   AutoRefillSellStop    = false;    // Tự động bổ sung Sell Stop khi đạt TP

input group "=== CHỐT LỜI / CẮT LỖ THEO TIỀN ==="
input double TakeProfitMoney  = 100.0;         // Chốt lời khi lãi đạt (USD)
input double StopLossMoney    = 200.0;         // Cắt lỗ khi lỗ đạt (USD)

input group "=== TỰ ĐỘNG RESET EA ==="
input bool   AutoResetOnTP    = true;          // Tự động reset khi đạt TP
input bool   AutoResetOnSL    = false;         // Tự động reset khi đạt SL

input group "=== SESSION TARGET (RESET KHI ĐẠT) ==="
input bool   UseSessionTarget      = true;     // Bật Session Target
input double SessionTargetMoney    = 10.0;     // Target session (USD)

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
double         g_totalProfitAccum = 0;
bool           g_isStopped = false;
bool           g_isPaused = false;

// Session target - dem profit tu cac lenh da TP trong session hien tai
double         g_sessionClosedProfit = 0;      // Tong profit tu cac lenh da dong trong session
int            g_sessionTPCount = 0;           // So lan dat TP session

// Dem so lenh TP rieng cho tung loai
int            g_buyLimitTPCount = 0;
int            g_sellLimitTPCount = 0;
int            g_buyStopTPCount = 0;
int            g_sellStopTPCount = 0;

// Luu gia LENH (open price) de bo sung lenh Stop (AutoRefill)
double         g_lastBuyStopOrderPrice = 0;      // Gia mo lenh Buy Stop vua dat TP
double         g_lastSellStopOrderPrice = 0;     // Gia mo lenh Sell Stop vua dat TP
bool           g_pendingBuyStopRefill = false;   // Co can bo sung Buy Stop khong (AutoRefill)
bool           g_pendingSellStopRefill = false;  // Co can bo sung Sell Stop khong (AutoRefill)

// Mang luu cac level gia CO DINH cua luoi (de tu dong bo sung lenh)
double         g_gridBuyLimitLevels[100];     // Cac level gia Buy Limit
double         g_gridSellLimitLevels[100];    // Cac level gia Sell Limit
double         g_gridBuyStopLevels[100];      // Cac level gia Buy Stop
double         g_gridSellStopLevels[100];     // Cac level gia Sell Stop
int            g_gridBuyLimitCount = 0;       // So luong level Buy Limit
int            g_gridSellLimitCount = 0;      // So luong level Sell Limit
int            g_gridBuyStopCount = 0;        // So luong level Buy Stop
int            g_gridSellStopCount = 0;       // So luong level Sell Stop
bool           g_gridInitialized = false;     // Da khoi tao grid chua
double         g_gridReferencePrice = 0;      // Gia tham chieu lam goc cho luoi

// Thong ke max tu luc bat EA (KHONG reset)
double         g_maxLotUsed = 0;             // Lot lon nhat ma GIA DA CHAM (kich hoat lenh)
int            g_maxGridLevel = 0;           // Bac luoi lon nhat ma GIA DA CHAM

//+------------------------------------------------------------------+
//| Ham khoi tao EA                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   
   g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   // Tinh g_pipValue tu dong
   if(g_digits == 3 || g_digits == 5)
      g_pipValue = g_point * 10;
   else
      g_pipValue = g_point;
   
   Print(">>> 1 pip = ", DoubleToString(g_pipValue, g_digits));
   
   g_isFirstRun = true;
   
   if(ShowPanel)
      CreatePanel();
   
   g_maxDrawdown = 0;
   g_totalProfitAccum = 0;
   g_isStopped = false;
   g_isPaused = false;
   
   Print("=== GRID MATRIX EA v1.0 da khoi dong ===");
   Print("Cap tien: ", _Symbol);
   Print("Khoang cach Grid: ", GridGapPips, " pips = ", DoubleToString(GridGapPips * g_pipValue, g_digits));
   Print("Lot dau: BL=", BuyLimitStartLot, " SL=", SellLimitStartLot, " BS=", BuyStopStartLot, " SS=", SellStopStartLot);
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
   ObjectDelete(0, "GM_RefPriceLine");  // Xoa duong gia goc
   Print("=== GRID MATRIX EA da dung ===");
   Print("Tong so lan TP: ", g_tpCount);
   Print("Tong so lan SL: ", g_slCount);
}

//+------------------------------------------------------------------+
//| Xu ly su kien giao dich (dem so lan TP cho thong ke)             |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   // Chi xu ly khi vi the dong (TRADE_TRANSACTION_DEAL_ADD)
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   
   ulong dealTicket = trans.deal;
   if(dealTicket == 0) return;
   
   if(!HistoryDealSelect(dealTicket)) return;
   
   long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
   long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
   long dealReason = HistoryDealGetInteger(dealTicket, DEAL_REASON);
   double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
   string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   double dealVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
   double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
   
   // Chi xu ly lenh cua EA nay, tren symbol nay
   if(dealMagic != MagicNumber) return;
   if(dealSymbol != _Symbol) return;
   
   // XU LY KHI LENH PENDING DUOC KICH HOAT (ENTRY_IN) - Track Max Lot va Max Bac
   if(dealEntry == DEAL_ENTRY_IN && g_gridReferencePrice > 0)
   {
      // Tinh bac luoi dua tren khoang cach tu gia goc
      double distance = MathAbs(dealPrice - g_gridReferencePrice);
      double gridGap = GridGapPips * g_pipValue;
      int gridLevel = (int)MathRound(distance / gridGap);
      
      // Cap nhat Max Lot va Max Grid Level (gia da cham den)
      if(dealVolume > g_maxLotUsed)
         g_maxLotUsed = dealVolume;
      if(gridLevel > g_maxGridLevel)
         g_maxGridLevel = gridLevel;
      
      Print(">>> GIA CHAM BAC ", gridLevel, " | Lot: ", DoubleToString(dealVolume, 2), 
            " | Max Lot: ", DoubleToString(g_maxLotUsed, 2), " | Max Bac: ", g_maxGridLevel);
   }
   
   // XU LY KHI DONG VI THE (ENTRY_OUT) - Dem TP va Session profit
   if(dealEntry == DEAL_ENTRY_OUT)
   {
      // Dem so lan TP theo loai lenh (cho thong ke) va cong vao session profit
      if(dealReason == DEAL_REASON_TP && dealProfit > 0)
      {
         if(StringFind(dealComment, "_BS#") >= 0)
            g_buyStopTPCount++;
         else if(StringFind(dealComment, "_SS#") >= 0)
            g_sellStopTPCount++;
         else if(StringFind(dealComment, "_BL#") >= 0)
            g_buyLimitTPCount++;
         else if(StringFind(dealComment, "_SL#") >= 0)
            g_sellLimitTPCount++;
         
         // Cong profit vao session (cho Session Target)
         g_sessionClosedProfit += dealProfit;
         Print(">>> Lenh dat TP! Comment: ", dealComment, " Profit: ", DoubleToString(dealProfit, 2));
         Print(">>> Session da dong: ", DoubleToString(g_sessionClosedProfit, 2), " USD");
      }
   }
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
         
         // Buoc 3: Reset tat ca bien (KHONG reset g_maxDrawdown)
         g_tpCount = 0;
         g_slCount = 0;
         g_totalProfitAccum = 0;
         g_sessionClosedProfit = 0;  // Reset session profit
         g_sessionTPCount = 0;
         g_isStopped = false;
         g_isPaused = true;
         g_isFirstRun = true;
         // Reset bien dem lenh TP
         g_buyLimitTPCount = 0;
         g_sellLimitTPCount = 0;
         g_buyStopTPCount = 0;
         g_sellStopTPCount = 0;
         // Reset bien bo sung lenh Stop
         g_pendingBuyStopRefill = false;
         g_pendingSellStopRefill = false;
         g_lastBuyStopOrderPrice = 0;
         g_lastSellStopOrderPrice = 0;
         // Reset grid levels
         g_gridInitialized = false;
         
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
   
   // Chi cap nhat maxDrawdown khi EA DANG CHAY (khong pause/stop)
   if(totalProfit < g_maxDrawdown)
      g_maxDrawdown = totalProfit;
   
   if(ShowPanel)
      UpdatePanel(totalProfit, buyPositions, sellPositions, buyPending, sellPending);
   
   // === KIEM TRA SESSION TARGET ===
   // Session Target = Tong profit da dong trong session + floating profit hien tai
   if(UseSessionTarget && SessionTargetMoney > 0)
   {
      double sessionTotal = g_sessionClosedProfit + totalProfit;
      
      // Neu dat Session Target va co lenh dang mo
      if(sessionTotal >= SessionTargetMoney && totalPositions > 0)
      {
         Print(">>> SESSION TARGET DAT! Session: ", DoubleToString(sessionTotal, 2), " / ", DoubleToString(SessionTargetMoney, 2), " USD");
         Print(">>> (Da dong: ", DoubleToString(g_sessionClosedProfit, 2), " + Floating: ", DoubleToString(totalProfit, 2), ")");
         
         // Dong tat ca lenh
         CloseAllPositions();
         DeleteAllPendingOrders();
         
         // Cong vao tong tich luy
         g_totalProfitAccum += sessionTotal;
         g_sessionTPCount++;
         
         Print(">>> Session TP lan thu: ", g_sessionTPCount);
         Print(">>> Tong lai tich luy: ", DoubleToString(g_totalProfitAccum, 2), " USD");
         
         // Reset session - bat dau vong moi
         g_sessionClosedProfit = 0;
         g_buyLimitTPCount = 0;
         g_sellLimitTPCount = 0;
         g_buyStopTPCount = 0;
         g_sellStopTPCount = 0;
         g_pendingBuyStopRefill = false;
         g_pendingSellStopRefill = false;
         g_lastBuyStopOrderPrice = 0;
         g_lastSellStopOrderPrice = 0;
         g_gridInitialized = false;
         
         Sleep(1000);
         g_isFirstRun = true;
         
         Print(">>> RESET SESSION - Bat dau vong moi!");
         return;
      }
   }
   
   // Kiem tra TP tong - DUNG EA khi dat du so tien
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
      
      // Kiem tra TP tong sau khi chot loi - DUNG EA neu dat du
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
         // Reset session profit (ĐK 1 đạt → reset session)
         g_sessionClosedProfit = 0;
         // Reset bien dem lenh TP
         g_buyLimitTPCount = 0;
         g_sellLimitTPCount = 0;
         g_buyStopTPCount = 0;
         g_sellStopTPCount = 0;
         // Reset bien bo sung lenh Stop
         g_pendingBuyStopRefill = false;
         g_pendingSellStopRefill = false;
         g_lastBuyStopOrderPrice = 0;
         g_lastSellStopOrderPrice = 0;
         // Reset grid levels
         g_gridInitialized = false;
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
         // Reset session profit (SL đạt → reset session)
         g_sessionClosedProfit = 0;
         // Reset bien dem lenh TP
         g_buyLimitTPCount = 0;
         g_sellLimitTPCount = 0;
         g_buyStopTPCount = 0;
         g_sellStopTPCount = 0;
         // Reset bien bo sung lenh Stop
         g_pendingBuyStopRefill = false;
         g_pendingSellStopRefill = false;
         g_lastBuyStopOrderPrice = 0;
         g_lastSellStopOrderPrice = 0;
         // Reset grid levels
         g_gridInitialized = false;
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
   
   // TU DONG BO SUNG LENH TAI CAC LEVEL DA LUU (Auto Refill)
   // Moi tick kiem tra tat ca level va dat lai neu chua co lenh
   EnsureGridOrders();
}

//+------------------------------------------------------------------+
//| Dat tat ca lenh Grid ngay khi khoi dong                          |
//+------------------------------------------------------------------+
void PlaceAllGridOrders()
{
   Print(">>> Dat tat ca lenh Grid...");
   Print(">>> Khoang cach dau: ", InitialOffsetPips, " pips, Khoang cach luoi: ", GridGapPips, " pips");
   
   // Su dung MqlTick de lay gia chinh xac hon
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
   {
      Print(">>> CANH BAO: Chua co du lieu gia, cho tick tiep theo...");
      g_isFirstRun = true; // Thu lai o tick sau
      return;
   }
   
   double currentAsk = tick.ask;
   double currentBid = tick.bid;
   
   // Kiem tra gia hop le
   if(currentAsk <= 0 || currentBid <= 0 || currentAsk <= currentBid)
   {
      Print(">>> CANH BAO: Gia khong hop le (Ask=", DoubleToString(currentAsk, g_digits), 
            ", Bid=", DoubleToString(currentBid, g_digits), "), cho tick tiep theo...");
      g_isFirstRun = true; // Thu lai o tick sau
      return;
   }
   
   double midPrice = (currentAsk + currentBid) / 2.0;
   
   // Lam tron midPrice theo tick size (lam tron LEN)
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize > 0)
   {
      midPrice = MathCeil(midPrice / tickSize) * tickSize;
   }
   midPrice = NormalizeDouble(midPrice, g_digits);
   
   Print(">>> Gia tham chieu (lam tron): ", DoubleToString(midPrice, g_digits), 
         " (Ask=", DoubleToString(currentAsk, g_digits), 
         ", Bid=", DoubleToString(currentBid, g_digits), ")");
   Print(">>> InitialOffsetPips=", InitialOffsetPips, " (", DoubleToString(InitialOffsetPips * g_pipValue, g_digits), ")");
   Print(">>> GridGapPips=", GridGapPips, " (", DoubleToString(GridGapPips * g_pipValue, g_digits), ")");
   Print(">>> Gia lenh dau DUOI: ", DoubleToString(midPrice - (InitialOffsetPips * g_pipValue), g_digits));
   Print(">>> Gia lenh dau TREN: ", DoubleToString(midPrice + (InitialOffsetPips * g_pipValue), g_digits));
   
   // Reset cac mang level
   g_gridBuyLimitCount = 0;
   g_gridSellLimitCount = 0;
   g_gridBuyStopCount = 0;
   g_gridSellStopCount = 0;
   
   // Dat lenh phia DUOI gia hien tai (BUY LIMIT va SELL STOP)
   for(int i = 1; i <= MaxOrdersPerSide; i++)
   {
      double orderPrice;
      if(i == 1)
         orderPrice = midPrice - (InitialOffsetPips * g_pipValue);
      else
         orderPrice = midPrice - (InitialOffsetPips * g_pipValue) - (GridGapPips * g_pipValue) * (i - 1);
      
      orderPrice = NormalizeDouble(orderPrice, g_digits);
      
      // Luu level va dat BUY LIMIT neu bat
      if(UseBuyLimit)
      {
         g_gridBuyLimitLevels[g_gridBuyLimitCount] = orderPrice;
         g_gridBuyLimitCount++;
         double lot = CalculateBuyLimitLot(i);
         PlaceBuyLimit(orderPrice, lot, i);
      }
      
      // Luu level va dat SELL STOP trung vi tri
      if(UseSellStop)
      {
         g_gridSellStopLevels[g_gridSellStopCount] = orderPrice;
         g_gridSellStopCount++;
         double lot = CalculateSellStopLot(i);
         PlaceSellStop(orderPrice, lot, i);
      }
   }
   
   // Dat lenh phia TREN gia hien tai (SELL LIMIT va BUY STOP)
   for(int i = 1; i <= MaxOrdersPerSide; i++)
   {
      double orderPrice;
      if(i == 1)
         orderPrice = midPrice + (InitialOffsetPips * g_pipValue);
      else
         orderPrice = midPrice + (InitialOffsetPips * g_pipValue) + (GridGapPips * g_pipValue) * (i - 1);
      
      orderPrice = NormalizeDouble(orderPrice, g_digits);
      
      // Luu level va dat SELL LIMIT neu bat
      if(UseSellLimit)
      {
         g_gridSellLimitLevels[g_gridSellLimitCount] = orderPrice;
         g_gridSellLimitCount++;
         double lot = CalculateSellLimitLot(i);
         PlaceSellLimit(orderPrice, lot, i);
      }
      
      // Luu level va dat BUY STOP trung vi tri
      if(UseBuyStop)
      {
         g_gridBuyStopLevels[g_gridBuyStopCount] = orderPrice;
         g_gridBuyStopCount++;
         double lot = CalculateBuyStopLot(i);
         PlaceBuyStop(orderPrice, lot, i);
      }
   }
   
   g_gridInitialized = true;
   g_gridReferencePrice = midPrice;  // Luu gia tham chieu
   
   // Ve duong gia goc luoi mau vang net dut
   DrawReferencePriceLine(g_gridReferencePrice);
   
   Print(">>> Da luu ", g_gridBuyLimitCount, " level BL, ", g_gridSellLimitCount, " level SL, ", g_gridBuyStopCount, " level BS, ", g_gridSellStopCount, " level SS");
   Print(">>> Da dat xong tat ca lenh Grid!");
   Print(">>> GIA GOC LUOI: ", DoubleToString(g_gridReferencePrice, g_digits));
   Print(">>> TREN duong vang: Sell Limit + Buy Stop (hoac Sell Open + Buy Stop, Sell Limit + Buy Open)");
   Print(">>> DUOI duong vang: Buy Limit + Sell Stop (hoac Buy Open + Sell Stop, Buy Limit + Sell Open)");
}

//+------------------------------------------------------------------+
//| Dem tong so lenh (cho + mo) cua 1 loai lenh                      |
//| orderType: BUY_LIMIT, SELL_LIMIT, BUY_STOP, SELL_STOP            |
//| Tra ve: so lenh cho + so position tuong ung                       |
//+------------------------------------------------------------------+
int CountTotalOrdersOfType(ENUM_ORDER_TYPE orderType)
{
   int pendingCount = 0;
   int positionCount = 0;
   
   // Xac dinh loai position tuong ung
   bool isBuyType = (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP);
   ENUM_POSITION_TYPE posType = isBuyType ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   
   // Dem lenh cho cung loai
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(orderInfo.OrderType() == orderType)
               pendingCount++;
         }
      }
   }
   
   // Dem position tuong ung (Buy hoac Sell)
   // Position Buy = tu Buy Limit hoac Buy Stop da khop
   // Position Sell = tu Sell Limit hoac Sell Stop da khop
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            if(positionInfo.PositionType() == posType)
               positionCount++;
         }
      }
   }
   
   return pendingCount + positionCount;
}

//+------------------------------------------------------------------+
//| Kiem tra con slot trong de dat lenh moi khong                    |
//| Tong (lenh cho + position) phai < MaxOrdersPerSide               |
//+------------------------------------------------------------------+
bool CanPlaceMoreOrders(ENUM_ORDER_TYPE orderType)
{
   int totalOrders = CountTotalOrdersOfType(orderType);
   
   if(totalOrders >= MaxOrdersPerSide)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Dam bao co lenh tai tat ca cac level (Auto Refill)               |
//| Logic giong EAGridTrading: Moi tick kiem tra va dat lai lenh     |
//| Chi bo sung khi tong lenh (cho + mo) < MaxOrdersPerSide          |
//+------------------------------------------------------------------+
void EnsureGridOrders()
{
   if(!g_gridInitialized) return;
   
   // BUOC 1: Xoa cac lenh trung lap truoc (dam bao moi luoi chi 1 Buy, 1 Sell)
   CleanDuplicateOrdersAtLevels();
   
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minDistance = (GridGapPips * g_pipValue) * 0.5; // Khoang cach toi thieu de dat lenh
   
   // Buy Limit: kiem tra va bo sung tai cac level DUOI gia hien tai
   if(AutoRefillBuyLimit && UseBuyLimit && CanPlaceMoreOrders(ORDER_TYPE_BUY_LIMIT))
   {
      for(int i = 0; i < g_gridBuyLimitCount; i++)
      {
         // Kiem tra lai truoc moi lenh (vi co the da dat du trong vong lap)
         if(!CanPlaceMoreOrders(ORDER_TYPE_BUY_LIMIT)) break;
         
         double level = g_gridBuyLimitLevels[i];
         
         // Bo qua neu level qua gan gia hien tai
         if(MathAbs(level - currentAsk) < minDistance) continue;
         
         // Chi dat Buy Limit tai level DUOI gia Ask
         if(level < currentAsk)
         {
            EnsureOrderAtLevel(ORDER_TYPE_BUY_LIMIT, level);
         }
      }
   }
   
   // Sell Limit: kiem tra va bo sung tai cac level TREN gia hien tai
   if(AutoRefillSellLimit && UseSellLimit && CanPlaceMoreOrders(ORDER_TYPE_SELL_LIMIT))
   {
      for(int i = 0; i < g_gridSellLimitCount; i++)
      {
         // Kiem tra lai truoc moi lenh
         if(!CanPlaceMoreOrders(ORDER_TYPE_SELL_LIMIT)) break;
         
         double level = g_gridSellLimitLevels[i];
         
         // Bo qua neu level qua gan gia hien tai
         if(MathAbs(level - currentBid) < minDistance) continue;
         
         // Chi dat Sell Limit tai level TREN gia Bid
         if(level > currentBid)
         {
            EnsureOrderAtLevel(ORDER_TYPE_SELL_LIMIT, level);
         }
      }
   }
   
   // Buy Stop: kiem tra va bo sung tai cac level TREN gia hien tai
   // Dieu kien bo sung: gia hien tai < (level - (GridGapPips * g_pipValue))
   if(AutoRefillBuyStop && UseBuyStop && CanPlaceMoreOrders(ORDER_TYPE_BUY_STOP))
   {
      double gridDistance = (GridGapPips * g_pipValue);
      
      for(int i = 0; i < g_gridBuyStopCount; i++)
      {
         // Kiem tra lai truoc moi lenh
         if(!CanPlaceMoreOrders(ORDER_TYPE_BUY_STOP)) break;
         
         double level = g_gridBuyStopLevels[i];
         
         // Chi bo sung khi gia < (level - (GridGapPips * g_pipValue))
         // Tuc la gia phai thap hon level it nhat 1 khoang luoi
         if(currentAsk < (level - gridDistance))
         {
            EnsureOrderAtLevel(ORDER_TYPE_BUY_STOP, level);
         }
      }
   }
   
   // Sell Stop: kiem tra va bo sung tai cac level DUOI gia hien tai
   // Dieu kien bo sung: gia hien tai > (level + (GridGapPips * g_pipValue))
   if(AutoRefillSellStop && UseSellStop && CanPlaceMoreOrders(ORDER_TYPE_SELL_STOP))
   {
      double gridDistance = (GridGapPips * g_pipValue);
      
      for(int i = 0; i < g_gridSellStopCount; i++)
      {
         // Kiem tra lai truoc moi lenh
         if(!CanPlaceMoreOrders(ORDER_TYPE_SELL_STOP)) break;
         
         double level = g_gridSellStopLevels[i];
         
         // Chi bo sung khi gia > (level + (GridGapPips * g_pipValue))
         // Tuc la gia phai cao hon level it nhat 1 khoang luoi
         if(currentBid > (level + gridDistance))
         {
            EnsureOrderAtLevel(ORDER_TYPE_SELL_STOP, level);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Xoa lenh trung lap tai moi luoi - Dam bao chi 1 Buy va 1 Sell    |
//+------------------------------------------------------------------+
void CleanDuplicateOrdersAtLevels()
{
   double tolerance = g_pipValue * 2;
   
   // Kiem tra tat ca cac level Buy Limit
   for(int i = 0; i < g_gridBuyLimitCount; i++)
   {
      CleanDuplicateBuyOrdersAtLevel(g_gridBuyLimitLevels[i], tolerance);
   }
   
   // Kiem tra tat ca cac level Sell Limit
   for(int i = 0; i < g_gridSellLimitCount; i++)
   {
      CleanDuplicateSellOrdersAtLevel(g_gridSellLimitLevels[i], tolerance);
   }
   
   // Kiem tra tat ca cac level Buy Stop
   for(int i = 0; i < g_gridBuyStopCount; i++)
   {
      CleanDuplicateBuyOrdersAtLevel(g_gridBuyStopLevels[i], tolerance);
   }
   
   // Kiem tra tat ca cac level Sell Stop
   for(int i = 0; i < g_gridSellStopCount; i++)
   {
      CleanDuplicateSellOrdersAtLevel(g_gridSellStopLevels[i], tolerance);
   }
}

//+------------------------------------------------------------------+
//| Xoa lenh Buy trung lap tai 1 level - Giu lai 1 lenh duy nhat     |
//+------------------------------------------------------------------+
void CleanDuplicateBuyOrdersAtLevel(double level, double tolerance)
{
   int buyOrderCount = 0;
   ulong firstBuyTicket = 0;
   
   // Dem so lenh Buy tai level va tim lenh dau tien
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            ENUM_ORDER_TYPE ot = orderInfo.OrderType();
            if(ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP)
            {
               if(MathAbs(orderInfo.PriceOpen() - level) < tolerance)
               {
                  buyOrderCount++;
                  if(buyOrderCount == 1)
                     firstBuyTicket = orderInfo.Ticket();
                  else
                  {
                     // Xoa lenh thua (tu lenh thu 2 tro di)
                     ulong ticketToDelete = orderInfo.Ticket();
                     if(trade.OrderDelete(ticketToDelete))
                        Print(">>> XOA LENH TRUNG: Buy tai ", DoubleToString(level, g_digits), " Ticket=", ticketToDelete);
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Xoa lenh Sell trung lap tai 1 level - Giu lai 1 lenh duy nhat    |
//+------------------------------------------------------------------+
void CleanDuplicateSellOrdersAtLevel(double level, double tolerance)
{
   int sellOrderCount = 0;
   ulong firstSellTicket = 0;
   
   // Dem so lenh Sell tai level va tim lenh dau tien
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            ENUM_ORDER_TYPE ot = orderInfo.OrderType();
            if(ot == ORDER_TYPE_SELL_LIMIT || ot == ORDER_TYPE_SELL_STOP)
            {
               if(MathAbs(orderInfo.PriceOpen() - level) < tolerance)
               {
                  sellOrderCount++;
                  if(sellOrderCount == 1)
                     firstSellTicket = orderInfo.Ticket();
                  else
                  {
                     // Xoa lenh thua (tu lenh thu 2 tro di)
                     ulong ticketToDelete = orderInfo.Ticket();
                     if(trade.OrderDelete(ticketToDelete))
                        Print(">>> XOA LENH TRUNG: Sell tai ", DoubleToString(level, g_digits), " Ticket=", ticketToDelete);
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Dam bao co lenh tai level - tao neu chua co                      |
//| Moi luoi chi co 1 lenh Buy va 1 lenh Sell                        |
//| Kiem tra ky: pending order + position dang mo                    |
//+------------------------------------------------------------------+
void EnsureOrderAtLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   // Xac dinh day la lenh Buy hay Sell
   bool isBuyOrder = (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP);
   
   // KIEM TRA 0: Kiem tra cau truc dung theo vi tri so voi duong vang
   if(!IsValidOrderTypeForLevel(orderType, priceLevel))
   {
      Print(">>> CANH BAO: Loai lenh khong dung cho level nay!");
      return;
   }
   
   // KIEM TRA 1: Da co lenh cho (pending) cung chieu tai level nay chua?
   if(HasBuyOrSellOrderAtLevel(isBuyOrder, priceLevel))
      return;
   
   // KIEM TRA 2: Da co position dang mo cung chieu tai level nay chua?
   if(HasBuyOrSellPositionAtLevel(isBuyOrder, priceLevel))
      return;
   
   // KIEM TRA 3: Kiem tra cau truc tong the tai level (max 1 buy + 1 sell)
   if(!CheckGridStructureAtLevel(priceLevel, isBuyOrder))
   {
      Print(">>> KHONG DAT LENH: Da du cau truc tai level ", DoubleToString(priceLevel, g_digits));
      return;
   }
   
   // Da kiem tra ky - Chua co lenh va position, dat lenh moi
   double price = NormalizeDouble(priceLevel, g_digits);
   
   if(orderType == ORDER_TYPE_BUY_LIMIT)
   {
      if(PlaceBuyLimit(price, BuyLimitStartLot, 0))
         Print(">>> AUTO REFILL: Dat lai Buy Limit tai ", DoubleToString(price, g_digits));
   }
   else if(orderType == ORDER_TYPE_SELL_LIMIT)
   {
      if(PlaceSellLimit(price, SellLimitStartLot, 0))
         Print(">>> AUTO REFILL: Dat lai Sell Limit tai ", DoubleToString(price, g_digits));
   }
   else if(orderType == ORDER_TYPE_BUY_STOP)
   {
      if(PlaceBuyStop(price, BuyStopStartLot, 0))
         Print(">>> AUTO REFILL: Dat lai Buy Stop tai ", DoubleToString(price, g_digits));
   }
   else if(orderType == ORDER_TYPE_SELL_STOP)
   {
      if(PlaceSellStop(price, SellStopStartLot, 0))
         Print(">>> AUTO REFILL: Dat lai Sell Stop tai ", DoubleToString(price, g_digits));
   }
}

//+------------------------------------------------------------------+
//| Kiem tra da co lenh cho (pending) Buy hoac Sell tai level chua   |
//| isBuy = true: kiem tra Buy Limit + Buy Stop                      |
//| isBuy = false: kiem tra Sell Limit + Sell Stop                   |
//+------------------------------------------------------------------+
bool HasBuyOrSellOrderAtLevel(bool isBuy, double level)
{
   double tolerance = g_pipValue * 2; // Sai so 2 pips
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            ENUM_ORDER_TYPE ot = orderInfo.OrderType();
            bool isOrderBuy = (ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP);
            
            // Chi kiem tra lenh cung chieu (Buy hoac Sell)
            if(isOrderBuy == isBuy)
            {
               if(MathAbs(orderInfo.PriceOpen() - level) < tolerance)
                  return true;
            }
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Kiem tra da co position dang mo Buy hoac Sell tai level chua     |
//| isBuy = true: kiem tra position Buy                              |
//| isBuy = false: kiem tra position Sell                            |
//+------------------------------------------------------------------+
bool HasBuyOrSellPositionAtLevel(bool isBuy, double level)
{
   double tolerance = g_pipValue * 2; // Sai so 2 pips
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            ENUM_POSITION_TYPE pt = positionInfo.PositionType();
            bool isPosBuy = (pt == POSITION_TYPE_BUY);
            
            // Chi kiem tra position cung chieu (Buy hoac Sell)
            if(isPosBuy == isBuy)
            {
               if(MathAbs(positionInfo.PriceOpen() - level) < tolerance)
                  return true;
            }
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Kiem tra loai lenh co dung cho vi tri (tren/duoi duong vang) khong|
//| TREN duong vang: chi Sell Limit + Buy Stop                        |
//| DUOI duong vang: chi Buy Limit + Sell Stop                        |
//+------------------------------------------------------------------+
bool IsValidOrderTypeForLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   if(g_gridReferencePrice <= 0) return true; // Chua khoi tao, cho phep dat
   
   bool isAboveRef = (priceLevel > g_gridReferencePrice);
   bool isBelowRef = (priceLevel < g_gridReferencePrice);
   
   // TREN duong vang: chi Sell Limit + Buy Stop
   if(isAboveRef)
   {
      if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
         return true;
      else
         return false; // Buy Limit hoac Sell Stop khong dung cho phia tren
   }
   
   // DUOI duong vang: chi Buy Limit + Sell Stop
   if(isBelowRef)
   {
      if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_STOP)
         return true;
      else
         return false; // Sell Limit hoac Buy Stop khong dung cho phia duoi
   }
   
   return true; // Tai dung gia goc, cho phep
}

//+------------------------------------------------------------------+
//| Kiem tra cau truc tai level: toi da 1 buy type + 1 sell type     |
//| Dem ca pending order va position dang mo                         |
//| Tra ve true neu co the dat them lenh                             |
//+------------------------------------------------------------------+
bool CheckGridStructureAtLevel(double priceLevel, bool isBuyType)
{
   double tolerance = g_pipValue * 2;
   int buyCount = 0;  // Dem Buy Limit/Buy Stop/Buy Position
   int sellCount = 0; // Dem Sell Limit/Sell Stop/Sell Position
   
   // Dem pending orders tai level
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(MathAbs(orderInfo.PriceOpen() - priceLevel) < tolerance)
            {
               ENUM_ORDER_TYPE ot = orderInfo.OrderType();
               if(ot == ORDER_TYPE_BUY_LIMIT || ot == ORDER_TYPE_BUY_STOP)
                  buyCount++;
               else if(ot == ORDER_TYPE_SELL_LIMIT || ot == ORDER_TYPE_SELL_STOP)
                  sellCount++;
            }
         }
      }
   }
   
   // Dem positions tai level
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            if(MathAbs(positionInfo.PriceOpen() - priceLevel) < tolerance)
            {
               if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                  buyCount++;
               else
                  sellCount++;
            }
         }
      }
   }
   
   // Kiem tra cau truc: toi da 1 buy + 1 sell
   if(isBuyType)
   {
      // Muon dat lenh Buy, kiem tra da co Buy chua
      if(buyCount >= 1)
         return false; // Da co 1 Buy, khong dat them
   }
   else
   {
      // Muon dat lenh Sell, kiem tra da co Sell chua
      if(sellCount >= 1)
         return false; // Da co 1 Sell, khong dat them
   }
   
   return true; // Co the dat lenh
}

//+------------------------------------------------------------------+
//| Quan ly luoi BUY LIMIT - Bo sung lenh rieng                      |
//+------------------------------------------------------------------+
void ManageGridBuyLimit(int currentOrders)
{
   if(currentOrders >= MaxOrdersPerSide) return;
   
   double lowestPrice = GetLowestBuyLimitPrice();
   
   int ordersToPlace = MaxOrdersPerSide - currentOrders;
   double nextPrice = lowestPrice;
   
   for(int i = 0; i < ordersToPlace; i++)
   {
      nextPrice = nextPrice - (GridGapPips * g_pipValue);
      int orderNum = currentOrders + i + 1;
      double lot = CalculateBuyLimitLot(orderNum);
      PlaceBuyLimit(nextPrice, lot, orderNum);
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi SELL LIMIT - Bo sung lenh rieng                     |
//+------------------------------------------------------------------+
void ManageGridSellLimit(int currentOrders)
{
   if(currentOrders >= MaxOrdersPerSide) return;
   
   double highestPrice = GetHighestSellLimitPrice();
   
   int ordersToPlace = MaxOrdersPerSide - currentOrders;
   double nextPrice = highestPrice;
   
   for(int i = 0; i < ordersToPlace; i++)
   {
      nextPrice = nextPrice + (GridGapPips * g_pipValue);
      int orderNum = currentOrders + i + 1;
      double lot = CalculateSellLimitLot(orderNum);
      PlaceSellLimit(nextPrice, lot, orderNum);
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi BUY STOP - Bo sung lenh rieng                       |
//+------------------------------------------------------------------+
void ManageGridBuyStop(int currentOrders)
{
   if(currentOrders >= MaxOrdersPerSide) return;
   
   double highestPrice = GetHighestBuyStopPrice();
   
   int ordersToPlace = MaxOrdersPerSide - currentOrders;
   double nextPrice = highestPrice;
   
   for(int i = 0; i < ordersToPlace; i++)
   {
      nextPrice = nextPrice + (GridGapPips * g_pipValue);
      int orderNum = currentOrders + i + 1;
      double lot = CalculateBuyStopLot(orderNum);
      PlaceBuyStop(nextPrice, lot, orderNum);
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi SELL STOP - Bo sung lenh rieng                      |
//+------------------------------------------------------------------+
void ManageGridSellStop(int currentOrders)
{
   if(currentOrders >= MaxOrdersPerSide) return;
   
   double lowestPrice = GetLowestSellStopPrice();
   
   int ordersToPlace = MaxOrdersPerSide - currentOrders;
   double nextPrice = lowestPrice;
   
   for(int i = 0; i < ordersToPlace; i++)
   {
      nextPrice = nextPrice - (GridGapPips * g_pipValue);
      int orderNum = currentOrders + i + 1;
      double lot = CalculateSellStopLot(orderNum);
      PlaceSellStop(nextPrice, lot, orderNum);
   }
}

//+------------------------------------------------------------------+
//| Lay gia thap nhat cua lenh BUY LIMIT (chi lenh cho)              |
//+------------------------------------------------------------------+
double GetLowestBuyLimitPrice()
{
   double lowestPrice = DBL_MAX;
   
   // Chi kiem tra lenh cho Buy Limit
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
   
   // Neu khong co lenh cho nao, dung gia hien tai - (InitialOffsetPips * g_pipValue)
   if(lowestPrice == DBL_MAX)
   {
      double midPrice = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) + SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2.0;
      lowestPrice = midPrice - (InitialOffsetPips * g_pipValue) + (GridGapPips * g_pipValue);
   }
   
   return lowestPrice;
}

//+------------------------------------------------------------------+
//| Lay gia cao nhat cua lenh SELL LIMIT (chi lenh cho)              |
//+------------------------------------------------------------------+
double GetHighestSellLimitPrice()
{
   double highestPrice = 0;
   
   // Chi kiem tra lenh cho Sell Limit
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
   
   // Neu khong co lenh cho nao, dung gia hien tai + (InitialOffsetPips * g_pipValue)
   if(highestPrice == 0)
   {
      double midPrice = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) + SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2.0;
      highestPrice = midPrice + (InitialOffsetPips * g_pipValue) - (GridGapPips * g_pipValue);
   }
   
   return highestPrice;
}

//+------------------------------------------------------------------+
//| Lay gia cao nhat cua lenh BUY STOP (chi lenh cho)                |
//+------------------------------------------------------------------+
double GetHighestBuyStopPrice()
{
   double highestPrice = 0;
   
   // Chi kiem tra lenh cho Buy Stop
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(orderInfo.OrderType() == ORDER_TYPE_BUY_STOP)
            {
               if(orderInfo.PriceOpen() > highestPrice)
                  highestPrice = orderInfo.PriceOpen();
            }
         }
      }
   }
   
   // Neu khong co lenh cho nao, dung gia hien tai + (InitialOffsetPips * g_pipValue)
   if(highestPrice == 0)
   {
      double midPrice = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) + SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2.0;
      highestPrice = midPrice + (InitialOffsetPips * g_pipValue) - (GridGapPips * g_pipValue);
   }
   
   return highestPrice;
}

//+------------------------------------------------------------------+
//| Lay gia thap nhat cua lenh SELL STOP (chi lenh cho)              |
//+------------------------------------------------------------------+
double GetLowestSellStopPrice()
{
   double lowestPrice = DBL_MAX;
   
   // Chi kiem tra lenh cho Sell Stop
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            if(orderInfo.OrderType() == ORDER_TYPE_SELL_STOP)
            {
               if(orderInfo.PriceOpen() < lowestPrice)
                  lowestPrice = orderInfo.PriceOpen();
            }
         }
      }
   }
   
   // Neu khong co lenh cho nao, dung gia hien tai - (InitialOffsetPips * g_pipValue)
   if(lowestPrice == DBL_MAX)
   {
      double midPrice = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) + SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2.0;
      lowestPrice = midPrice - (InitialOffsetPips * g_pipValue) + (GridGapPips * g_pipValue);
   }
   
   return lowestPrice;
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
   double lot = BuyLimitStartLot;
   
   switch(BuyLimitLotMode)
   {
      case LotScale_Multiply:
         for(int i = 1; i < orderNumber; i++)
            lot = lot * BuyLimitMultiplier;
         break;
      case LotScale_AddPerLevel:
         lot = BuyLimitStartLot + ((orderNumber - 1) * BuyLimitAddition);
         break;
      case LotScale_MultiplyPerGroup:
         {
            int groupIndex = (orderNumber - 1) / BuyLimitGridsPerGroup;
            for(int i = 0; i < groupIndex; i++)
               lot = lot * BuyLimitMultiplier;
         }
         break;
      case LotScale_AddPerGroup:
         {
            int groupIndex = (orderNumber - 1) / BuyLimitGridsPerGroup;
            lot = BuyLimitStartLot + (groupIndex * BuyLimitAddition);
         }
         break;
      default: // LotScale_None
         lot = BuyLimitStartLot;
         break;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Tinh khoi luong lenh SELL LIMIT                                  |
//+------------------------------------------------------------------+
double CalculateSellLimitLot(int orderNumber)
{
   double lot = SellLimitStartLot;
   
   switch(SellLimitLotMode)
   {
      case LotScale_Multiply:
         for(int i = 1; i < orderNumber; i++)
            lot = lot * SellLimitMultiplier;
         break;
      case LotScale_AddPerLevel:
         lot = SellLimitStartLot + ((orderNumber - 1) * SellLimitAddition);
         break;
      case LotScale_MultiplyPerGroup:
         {
            int groupIndex = (orderNumber - 1) / SellLimitGridsPerGroup;
            for(int i = 0; i < groupIndex; i++)
               lot = lot * SellLimitMultiplier;
         }
         break;
      case LotScale_AddPerGroup:
         {
            int groupIndex = (orderNumber - 1) / SellLimitGridsPerGroup;
            lot = SellLimitStartLot + (groupIndex * SellLimitAddition);
         }
         break;
      default: // LotScale_None
         lot = SellLimitStartLot;
         break;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Tinh khoi luong lenh BUY STOP                                    |
//+------------------------------------------------------------------+
double CalculateBuyStopLot(int orderNumber)
{
   double lot = BuyStopStartLot;
   
   switch(BuyStopLotMode)
   {
      case LotScale_Multiply:
         for(int i = 1; i < orderNumber; i++)
            lot = lot * BuyStopMultiplier;
         break;
      case LotScale_AddPerLevel:
         lot = BuyStopStartLot + ((orderNumber - 1) * BuyStopAddition);
         break;
      case LotScale_MultiplyPerGroup:
         {
            int groupIndex = (orderNumber - 1) / BuyStopGridsPerGroup;
            for(int i = 0; i < groupIndex; i++)
               lot = lot * BuyStopMultiplier;
         }
         break;
      case LotScale_AddPerGroup:
         {
            int groupIndex = (orderNumber - 1) / BuyStopGridsPerGroup;
            lot = BuyStopStartLot + (groupIndex * BuyStopAddition);
         }
         break;
      default: // LotScale_None
         lot = BuyStopStartLot;
         break;
   }
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Tinh khoi luong lenh SELL STOP                                   |
//+------------------------------------------------------------------+
double CalculateSellStopLot(int orderNumber)
{
   double lot = SellStopStartLot;
   
   switch(SellStopLotMode)
   {
      case LotScale_Multiply:
         for(int i = 1; i < orderNumber; i++)
            lot = lot * SellStopMultiplier;
         break;
      case LotScale_AddPerLevel:
         lot = SellStopStartLot + ((orderNumber - 1) * SellStopAddition);
         break;
      case LotScale_MultiplyPerGroup:
         {
            int groupIndex = (orderNumber - 1) / SellStopGridsPerGroup;
            for(int i = 0; i < groupIndex; i++)
               lot = lot * SellStopMultiplier;
         }
         break;
      case LotScale_AddPerGroup:
         {
            int groupIndex = (orderNumber - 1) / SellStopGridsPerGroup;
            lot = SellStopStartLot + (groupIndex * SellStopAddition);
         }
         break;
      default: // LotScale_None
         lot = SellStopStartLot;
         break;
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
   
   string comment = TradeComment + "_BS#" + IntegerToString(orderNum);
   
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
   
   string comment = TradeComment + "_SS#" + IntegerToString(orderNum);
   
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
   
   string comment = TradeComment + "_BL#" + IntegerToString(orderNum);
   
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
   
   string comment = TradeComment + "_SL#" + IntegerToString(orderNum);
   
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
   
   CreateLabel("GM_Panel_RefPrice", "Giá gốc lưới: Chờ khởi tạo...", x, y, clrGold, PanelFontSize);
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
   
   CreateLabel("GM_Panel_TP", "Reset tại lãi: +" + DoubleToString(TakeProfitMoney, 2) + " USD", x, y, clrGreen, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_SL", "Reset tại lỗ: -" + DoubleToString(StopLossMoney, 2) + " USD", x, y, clrRed, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_MaxDD", "Lỗ lớn nhất: 0.00 USD", x, y, clrOrangeRed, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_TotalProfit", "Tổng đã đóng: 0.00 / " + DoubleToString(TotalTakeProfitMoney, 0) + " USD", x, y, clrDarkGreen, PanelFontSize);
   y += lineHeight;
   
   // Session Target
   string sessionText = UseSessionTarget ? "Session: 0.00 / " + DoubleToString(SessionTargetMoney, 2) + " USD" : "Session Target: TẮT";
   CreateLabel("GM_Panel_Session", sessionText, x, y, clrMagenta, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_Status", "Trạng thái: ĐANG CHẠY", x, y, clrGreen, PanelFontSize);
   y += lineHeight;
   
   string resetText = "Reset: TP=" + (AutoResetOnTP ? "BẬT" : "TẮT") + " | SL=" + (AutoResetOnSL ? "BẬT" : "TẮT");
   CreateLabel("GM_Panel_Reset", resetText, x, y, clrGray, PanelFontSize);
   y += lineHeight;
   
   CreateLabel("GM_Panel_Count", "TP: 0 lần | SL: 0 lần", x, y, clrGray, PanelFontSize);
   y += lineHeight;
   
   // Max Lot va Max Grid Level (KHONG reset)
   CreateLabel("GM_Panel_MaxLot", "Max Lot: 0.00 | Max Bậc: 0", x, y, clrDarkOrange, PanelFontSize);
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
   
   // Dem lenh cho theo tung loai - CHI DEM LENH CHO
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
   
   ObjectSetString(0, "GM_Panel_MaxDD", OBJPROP_TEXT, "Lỗ lớn nhất: " + DoubleToString(g_maxDrawdown, 2) + " USD");
   
   // Hien thi: Tong lai da dong / So tien dung EA
   ObjectSetString(0, "GM_Panel_TotalProfit", OBJPROP_TEXT, "Tổng đã đóng: " + DoubleToString(g_totalProfitAccum, 2) + " / " + DoubleToString(TotalTakeProfitMoney, 0) + " USD");
   color totalColor = g_totalProfitAccum >= 0 ? clrDarkGreen : clrRed;
   ObjectSetInteger(0, "GM_Panel_TotalProfit", OBJPROP_COLOR, totalColor);
   
   // Hien thi Session Target: (Profit da dong trong session + Floating hien tai)
   if(UseSessionTarget)
   {
      double sessionTotal = g_sessionClosedProfit + profit;
      string sessionText = "Session: " + DoubleToString(sessionTotal, 2) + " / " + DoubleToString(SessionTargetMoney, 2) + " USD";
      ObjectSetString(0, "GM_Panel_Session", OBJPROP_TEXT, sessionText);
      color sessionColor = sessionTotal >= SessionTargetMoney ? clrGreen : clrMagenta;
      ObjectSetInteger(0, "GM_Panel_Session", OBJPROP_COLOR, sessionColor);
   }
   else
   {
      ObjectSetString(0, "GM_Panel_Session", OBJPROP_TEXT, "Session Target: TẮT");
      ObjectSetInteger(0, "GM_Panel_Session", OBJPROP_COLOR, clrGray);
   }
   
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
   
   // Hien thi Max Lot va Max Grid Level (KHONG reset - chi reset khi tat/bat lai EA)
   ObjectSetString(0, "GM_Panel_MaxLot", OBJPROP_TEXT, "Max Lot: " + DoubleToString(g_maxLotUsed, 2) + " | Max Bậc: " + IntegerToString(g_maxGridLevel));
   
   // Hien thi gia tham chieu
   if(g_gridReferencePrice > 0)
   {
      ObjectSetString(0, "GM_Panel_RefPrice", OBJPROP_TEXT, "Giá gốc lưới: " + DoubleToString(g_gridReferencePrice, g_digits));
      ObjectSetInteger(0, "GM_Panel_RefPrice", OBJPROP_COLOR, clrGold);
   }
   else
   {
      ObjectSetString(0, "GM_Panel_RefPrice", OBJPROP_TEXT, "Giá gốc lưới: Chờ khởi tạo...");
      ObjectSetInteger(0, "GM_Panel_RefPrice", OBJPROP_COLOR, clrGray);
   }
}

//+------------------------------------------------------------------+
//| Ve duong gia goc luoi mau vang net dut                           |
//+------------------------------------------------------------------+
void DrawReferencePriceLine(double price)
{
   string lineName = "GM_RefPriceLine";
   
   // Xoa duong cu neu ton tai
   if(ObjectFind(0, lineName) >= 0)
      ObjectDelete(0, lineName);
   
   // Tao duong ngang moi
   if(!ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, price))
   {
      Print(">>> Loi tao duong gia goc: ", GetLastError());
      return;
   }
   
   // Thiet lap thuoc tinh duong
   ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrGold);           // Mau vang
   ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DASH);        // Net dut
   ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2);                 // Do day
   ObjectSetInteger(0, lineName, OBJPROP_BACK, true);               // Ve phia sau chart
   ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);        // Khong cho chon
   ObjectSetInteger(0, lineName, OBJPROP_SELECTED, false);
   ObjectSetString(0, lineName, OBJPROP_TEXT, "Gia goc luoi");      // Tooltip
   
   Print(">>> Da ve duong gia goc luoi tai: ", DoubleToString(price, g_digits));
}

//+------------------------------------------------------------------+
