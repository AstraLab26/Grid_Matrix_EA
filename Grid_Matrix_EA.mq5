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
input bool   AutoRefillBuyLimit    = true;     // Tự động bổ sung Buy Limit khi đạt TP

input group "=== SELL LIMIT ==="
input bool   UseSellLimit          = true;     // Bật lệnh Sell Limit
input double SellLimitStartLot     = 0.01;     // Lot đầu tiên Sell Limit
input ENUM_LotScalingMode SellLimitLotMode = LotScale_Multiply; // Chế độ gấp thếp lot
input double SellLimitMultiplier   = 1.5;      // Hệ số nhân (khi chọn NHÂN)
input double SellLimitAddition     = 0.01;     // Bước cộng lot (khi chọn CỘNG)
input int    SellLimitGridsPerGroup= 5;        // Số lưới mỗi nhóm (khi chọn theo nhóm)
input bool   UseSellLimitTP        = false;    // Bật TP riêng cho Sell Limit
input int    SellLimitTPPips       = 50;       // TP Sell Limit (pips)
input bool   AutoRefillSellLimit   = true;     // Tự động bổ sung Sell Limit khi đạt TP

input group "=== BUY STOP ==="
input bool   UseBuyStop            = false;    // Bật lệnh Buy Stop
input double BuyStopStartLot       = 0.01;     // Lot đầu tiên Buy Stop
input ENUM_LotScalingMode BuyStopLotMode = LotScale_None; // Chế độ gấp thếp lot
input double BuyStopMultiplier     = 1.5;      // Hệ số nhân (khi chọn NHÂN)
input double BuyStopAddition       = 0.01;     // Bước cộng lot (khi chọn CỘNG)
input int    BuyStopGridsPerGroup  = 5;        // Số lưới mỗi nhóm (khi chọn theo nhóm)
input bool   UseBuyStopTP          = false;    // Bật TP riêng cho Buy Stop
input int    BuyStopTPPips         = 50;       // TP Buy Stop (pips)
input bool   AutoRefillBuyStop     = true;     // Tự động bổ sung Buy Stop khi đạt TP

input group "=== SELL STOP ==="
input bool   UseSellStop           = false;    // Bật lệnh Sell Stop
input double SellStopStartLot      = 0.01;     // Lot đầu tiên Sell Stop
input ENUM_LotScalingMode SellStopLotMode = LotScale_None; // Chế độ gấp thếp lot
input double SellStopMultiplier    = 1.5;      // Hệ số nhân (khi chọn NHÂN)
input double SellStopAddition      = 0.01;     // Bước cộng lot (khi chọn CỘNG)
input int    SellStopGridsPerGroup = 5;        // Số lưới mỗi nhóm (khi chọn theo nhóm)
input bool   UseSellStopTP         = false;    // Bật TP riêng cho Sell Stop
input int    SellStopTPPips        = 50;       // TP Sell Stop (pips)
input bool   AutoRefillSellStop    = true;     // Tự động bổ sung Sell Stop khi đạt TP

input group "=== CHỐT LỜI / CẮT LỖ THEO TIỀN ==="
input double TakeProfitMoney  = 100.0;         // Chốt lời khi lãi đạt (USD)
input double StopLossMoney    = 200.0;         // Cắt lỗ khi lỗ đạt (USD)

input group "=== TỰ ĐỘNG RESET EA ==="
input bool   AutoResetOnTP    = true;          // Tự động reset khi đạt TP
input bool   AutoResetOnSL    = false;         // Tự động reset khi đạt SL

input group "=== THỜI GIAN CHỜ SAU KHI ĐẠT TP/SESSION ==="
input bool   UseCooldownAfterTP    = true;     // Bật chờ sau khi đạt TP/Session
input int    CooldownMinutes       = 5;        // Số phút chờ trước khi vào lệnh lại

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
//| FORWARD DECLARATIONS                                             |
//+------------------------------------------------------------------+
bool PlaceBuyLimit(double price, double lot, int orderNum);
bool PlaceSellLimit(double price, double lot, int orderNum);
bool PlaceBuyStop(double price, double lot, int orderNum);
bool PlaceSellStop(double price, double lot, int orderNum);
double CalculateBuyLimitLot(int orderNumber);
double CalculateSellLimitLot(int orderNumber);
double CalculateBuyStopLot(int orderNumber);
double CalculateSellStopLot(int orderNumber);
void PreCalculateAllGridLots();

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

// GHI NHO LOT SIZE CHO MOI BAC (tinh san tu input, khong thay doi)
// Index 0 = bac 1, Index 1 = bac 2, ...
double         g_gridBuyLimitLots[100];       // Lot tinh san cho tung bac Buy Limit
double         g_gridSellLimitLots[100];      // Lot tinh san cho tung bac Sell Limit
double         g_gridBuyStopLots[100];        // Lot tinh san cho tung bac Buy Stop
double         g_gridSellStopLots[100];       // Lot tinh san cho tung bac Sell Stop

// Thong ke max tu luc bat EA (KHONG reset)
double         g_maxLotUsed = 0;             // Lot lon nhat ma GIA DA CHAM (kich hoat lenh)
int            g_maxGridLevel = 0;           // Bac luoi lon nhat ma GIA DA CHAM

// COUNTDOWN sau khi dat TP/Session Target
bool           g_isInCooldown = false;        // Dang trong thoi gian cho
datetime       g_cooldownEndTime = 0;         // Thoi gian ket thuc countdown
int            g_cooldownSecondsRemaining = 0;// So giay con lai

// KHUNG THONG BAO BO SUNG LENH (3 dong)
string         g_refillNotify1 = "";          // Thong bao cu nhat (tren cung)
string         g_refillNotify2 = "";          // Thong bao giua
string         g_refillNotify3 = "";          // Thong bao moi nhat (duoi cung)

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
   
   // TINH TRUOC TAT CA LOT CHO MOI BAC (tu input)
   PreCalculateAllGridLots();
   
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
      // ============ NUT BAT EA ============
      // Chi bat duoc khi EA dang dung (thu cong hoac auto do TP)
      // Neu dung do TP tong -> Reset het so lieu, chay lai tu dau
      // Neu dung thu cong -> Chay lai, so lieu van nho
      if(sparam == "GM_Btn_Start")
      {
         ObjectSetInteger(0, "GM_Btn_Start", OBJPROP_STATE, false);
         
         if(!g_isPaused && !g_isStopped)
         {
            Print(">>> EA dang chay roi! Khong can bat.");
         }
         else if(g_isStopped)
         {
            // EA dung do dat TP tong -> Reset het so lieu, chay lai tu dau
            Print(">>> NUT BAT EA - EA dung do TP tong, RESET va chay lai tu dau!");
            
            // Reset tat ca so lieu
            g_tpCount = 0;
            g_slCount = 0;
            g_totalProfitAccum = 0;
            g_sessionClosedProfit = 0;
            g_sessionTPCount = 0;
            g_maxLotUsed = 0;
            g_maxGridLevel = 0;
            g_gridReferencePrice = 0;
            g_maxDrawdown = 0;
            g_isInCooldown = false;
            g_cooldownEndTime = 0;
            g_cooldownSecondsRemaining = 0;
            
            // Reset thong bao
            g_refillNotify1 = "";
            g_refillNotify2 = "";
            g_refillNotify3 = "";
            g_notifyTime1 = ""; g_notifyText1 = ""; g_notifyLot1 = "";
            g_notifyTime2 = ""; g_notifyText2 = ""; g_notifyLot2 = "";
            g_notifyTime3 = ""; g_notifyText3 = ""; g_notifyLot3 = "";
            
            g_isStopped = false;
            g_isPaused = false;
            g_isFirstRun = true;
            
            Print(">>> EA da reset va bat dau chay lai!");
         }
         else if(g_isPaused)
         {
            // EA dung thu cong -> Chay lai, so lieu van nho
            g_isPaused = false;
            g_isFirstRun = true;
            Print(">>> NUT BAT EA - EA chay lai (so lieu van nho)!");
         }
      }
      // ============ NUT TAT EA ============
      // Chi tat duoc khi EA dang chay
      // Xoa lenh cho + dong lenh mo -> dung EA
      else if(sparam == "GM_Btn_Stop")
      {
         ObjectSetInteger(0, "GM_Btn_Stop", OBJPROP_STATE, false);
         
         if(g_isPaused || g_isStopped)
         {
            Print(">>> EA da dung roi! Khong can tat.");
         }
         else
         {
            Print(">>> NUT TAT EA - Dang dong tat ca lenh...");
            
            // Dong tat ca vi the dang mo
            CloseAllPositionsForce();
            Sleep(300);
            
            // Xoa tat ca lenh cho
            DeleteAllPendingOrders();
            
            g_isPaused = true;
            g_isInCooldown = false;
            
            Print(">>> EA da dung! Da dong het lenh mo va xoa lenh cho.");
         }
      }
      // ============ NUT LAM MOI ============
      // Reset het moi thu, bo dem va bat dau chay, mo cac lenh cho
      else if(sparam == "GM_Btn_Reset")
      {
         ObjectSetInteger(0, "GM_Btn_Reset", OBJPROP_STATE, false);
         Print(">>> NUT LAM MOI - Bat dau reset toan bo va chay lai!");
         Print(">>> Luu y: Se dong TAT CA vi the va lenh cho tren ", _Symbol);
         
         // Buoc 1: Dong TAT CA vi the tren symbol
         int maxAttempts = 10;
         for(int attempt = 0; attempt < maxAttempts; attempt++)
         {
            int posCount = CountAllPositionsOnSymbol();
            if(posCount == 0) break;
            
            Print(">>> Dong vi the lan ", attempt + 1, " - Con ", posCount, " vi the tren ", _Symbol);
            CloseAllPositionsForce();
            Sleep(500);
         }
         
         // Buoc 2: Xoa TAT CA lenh cho tren symbol
         for(int attempt = 0; attempt < maxAttempts; attempt++)
         {
            int orderCount = CountAllPendingOrdersOnSymbol();
            if(orderCount == 0) break;
            
            Print(">>> Xoa lenh cho lan ", attempt + 1, " - Con ", orderCount, " lenh tren ", _Symbol);
            DeleteAllPendingOrdersForce();
            Sleep(500);
         }
         
         // Buoc 3: Reset TAT CA so lieu va bo dem
         g_tpCount = 0;
         g_slCount = 0;
         g_totalProfitAccum = 0;
         g_sessionClosedProfit = 0;
         g_sessionTPCount = 0;
         g_maxLotUsed = 0;
         g_maxGridLevel = 0;
         g_maxDrawdown = 0;
         g_gridReferencePrice = 0;
         
         // Reset cooldown
         g_isInCooldown = false;
         g_cooldownEndTime = 0;
         g_cooldownSecondsRemaining = 0;
         
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
         
         // Reset thong bao
         g_refillNotify1 = "";
         g_refillNotify2 = "";
         g_refillNotify3 = "";
         g_notifyTime1 = ""; g_notifyText1 = ""; g_notifyLot1 = "";
         g_notifyTime2 = ""; g_notifyText2 = ""; g_notifyLot2 = "";
         g_notifyTime3 = ""; g_notifyText3 = ""; g_notifyLot3 = "";
         
         // Reset grid levels
         g_gridInitialized = false;
         
         // QUAN TRONG: Khong dung, chay luon!
         g_isStopped = false;
         g_isPaused = false;  // CHAY LUON, khong dung
         g_isFirstRun = true;
         
         // Buoc 4: Cap nhat panel
         if(ShowPanel)
         {
            UpdatePanel(0, 0, 0, 0, 0);
            UpdateNotifyPanel();
         }
         
         // Buoc 5: Redraw chart
         ChartRedraw(0);
         
         int remainPos = CountAllPositionsOnSymbol();
         int remainOrders = CountAllPendingOrdersOnSymbol();
         Print(">>> LAM MOI HOAN TAT! EA bat dau chay va mo lenh cho!");
         Print(">>> Vi the con: ", remainPos, " | Lenh cho con: ", remainOrders);
         
         if(remainPos > 0 || remainOrders > 0)
         {
            Print(">>> CANH BAO: Van con lenh chua xoa duoc! Thu lai hoac xoa thu cong.");
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
   
   // === KIEM TRA COOLDOWN ===
   // Neu dang trong thoi gian cho, chi cap nhat panel va khong vao lenh moi
   if(UpdateCooldown())
   {
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
         
         // Dong tat ca lenh VA KIEM TRA LAI
         CloseAllAndVerify();
         
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
         
         // BAT DAU COOLDOWN
         StartCooldown();
         
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
      
      // Dong tat ca lenh VA KIEM TRA LAI
      CloseAllAndVerify();
      
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
         
         // BAT DAU COOLDOWN
         StartCooldown();
         
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
   
   // QUAN TRONG: Thiet lap g_gridReferencePrice TRUOC khi dat lenh
   // De GetGridLevelIndex() va CheckGridStructureAtLevel() hoat dong dung
   g_gridReferencePrice = midPrice;
   
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
      
      // Luu level va dat BUY LIMIT neu bat (lot da tinh san trong OnInit)
      if(UseBuyLimit)
      {
         double lot = g_gridBuyLimitLots[i-1];  // Lay lot da tinh san (bac 1 = index 0)
         g_gridBuyLimitLevels[g_gridBuyLimitCount] = orderPrice;
         g_gridBuyLimitCount++;
         PlaceBuyLimit(orderPrice, lot, i);
      }
      
      // Luu level va dat SELL STOP trung vi tri (lot da tinh san trong OnInit)
      if(UseSellStop)
      {
         double lot = g_gridSellStopLots[i-1];  // Lay lot da tinh san
         g_gridSellStopLevels[g_gridSellStopCount] = orderPrice;
         g_gridSellStopCount++;
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
      
      // Luu level va dat SELL LIMIT neu bat (lot da tinh san trong OnInit)
      if(UseSellLimit)
      {
         double lot = g_gridSellLimitLots[i-1];  // Lay lot da tinh san
         g_gridSellLimitLevels[g_gridSellLimitCount] = orderPrice;
         g_gridSellLimitCount++;
         PlaceSellLimit(orderPrice, lot, i);
      }
      
      // Luu level va dat BUY STOP trung vi tri (lot da tinh san trong OnInit)
      if(UseBuyStop)
      {
         double lot = g_gridBuyStopLots[i-1];  // Lay lot da tinh san
         g_gridBuyStopLevels[g_gridBuyStopCount] = orderPrice;
         g_gridBuyStopCount++;
         PlaceBuyStop(orderPrice, lot, i);
      }
   }
   
   g_gridInitialized = true;
   // g_gridReferencePrice da duoc thiet lap truoc khi dat lenh (o tren)
   
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
//| Logic:                                                           |
//| - Buy Limit / Sell Limit: Bo sung NGAY LAP TUC khi co level trong|
//| - Buy Stop / Sell Stop: Bo sung khi gia cach IT NHAT 1 bac luoi  |
//| Chi bo sung khi tong lenh (cho + mo) < MaxOrdersPerSide          |
//+------------------------------------------------------------------+
void EnsureGridOrders()
{
   if(!g_gridInitialized) return;
   
   // BUOC 1: Xoa cac lenh trung lap truoc (dam bao moi luoi chi 1 Buy, 1 Sell)
   CleanDuplicateOrdersAtLevels();
   
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double gridDistance = GridGapPips * g_pipValue; // 1 bac luoi
   
   // ============ BUY LIMIT: BO SUNG NGAY LAP TUC ============
   // Chi can level DUOI gia Ask la dat duoc (khong can khoang cach toi thieu)
   if(AutoRefillBuyLimit && UseBuyLimit)
   {
      for(int i = 0; i < g_gridBuyLimitCount; i++)
      {
         if(!CanPlaceMoreOrders(ORDER_TYPE_BUY_LIMIT)) break;
         
         double level = g_gridBuyLimitLevels[i];
         
         // Chi dat Buy Limit tai level DUOI gia Ask (dieu kien co ban cua broker)
         if(level < currentAsk)
         {
            EnsureOrderAtLevel(ORDER_TYPE_BUY_LIMIT, level);
         }
      }
   }
   
   // ============ SELL LIMIT: BO SUNG NGAY LAP TUC ============
   // Chi can level TREN gia Bid la dat duoc (khong can khoang cach toi thieu)
   if(AutoRefillSellLimit && UseSellLimit)
   {
      for(int i = 0; i < g_gridSellLimitCount; i++)
      {
         if(!CanPlaceMoreOrders(ORDER_TYPE_SELL_LIMIT)) break;
         
         double level = g_gridSellLimitLevels[i];
         
         // Chi dat Sell Limit tai level TREN gia Bid (dieu kien co ban cua broker)
         if(level > currentBid)
         {
            EnsureOrderAtLevel(ORDER_TYPE_SELL_LIMIT, level);
         }
      }
   }
   
   // ============ BUY STOP: CACH IT NHAT 1 BAC LUOI ============
   // Dieu kien: currentAsk + gridDistance < level (gia phai thap hon level it nhat 1 bac)
   if(AutoRefillBuyStop && UseBuyStop)
   {
      for(int i = 0; i < g_gridBuyStopCount; i++)
      {
         if(!CanPlaceMoreOrders(ORDER_TYPE_BUY_STOP)) break;
         
         double level = g_gridBuyStopLevels[i];
         
         // Chi bo sung khi gia hien tai THAP HON level it nhat 1 bac luoi
         // (gia + 1 bac) < level => gia < (level - 1 bac)
         if(currentAsk < (level - gridDistance))
         {
            EnsureOrderAtLevel(ORDER_TYPE_BUY_STOP, level);
         }
      }
   }
   
   // ============ SELL STOP: CACH IT NHAT 1 BAC LUOI ============
   // Dieu kien: currentBid - gridDistance > level (gia phai cao hon level it nhat 1 bac)
   if(AutoRefillSellStop && UseSellStop)
   {
      for(int i = 0; i < g_gridSellStopCount; i++)
      {
         if(!CanPlaceMoreOrders(ORDER_TYPE_SELL_STOP)) break;
         
         double level = g_gridSellStopLevels[i];
         
         // Chi bo sung khi gia hien tai CAO HON level it nhat 1 bac luoi
         // (gia - 1 bac) > level => gia > (level + 1 bac)
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
//| Tim lot da tinh san cho 1 level (dung cho auto-refill)           |
//| Chuyen price thanh bac (1,2,3...) roi tra lot tu mang da tinh san|
//+------------------------------------------------------------------+
double LookupLotForLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   // Tim bac tu danh sach level da luu
   // g_gridBuyLimitLevels[0] = level bac 1, [1] = bac 2...
   double tolerance = GridGapPips * g_pipValue * 0.3;
   int orderNum = 0; // Bac 1, 2, 3...
   
   if(orderType == ORDER_TYPE_BUY_LIMIT)
   {
      for(int i = 0; i < g_gridBuyLimitCount; i++)
      {
         if(MathAbs(g_gridBuyLimitLevels[i] - priceLevel) < tolerance)
         {
            orderNum = i + 1; // Bac = index + 1
            break;
         }
      }
      if(orderNum > 0 && orderNum <= MaxOrdersPerSide)
         return g_gridBuyLimitLots[orderNum - 1]; // Tra lot da tinh san
   }
   else if(orderType == ORDER_TYPE_SELL_LIMIT)
   {
      for(int i = 0; i < g_gridSellLimitCount; i++)
      {
         if(MathAbs(g_gridSellLimitLevels[i] - priceLevel) < tolerance)
         {
            orderNum = i + 1;
            break;
         }
      }
      if(orderNum > 0 && orderNum <= MaxOrdersPerSide)
         return g_gridSellLimitLots[orderNum - 1];
   }
   else if(orderType == ORDER_TYPE_BUY_STOP)
   {
      for(int i = 0; i < g_gridBuyStopCount; i++)
      {
         if(MathAbs(g_gridBuyStopLevels[i] - priceLevel) < tolerance)
         {
            orderNum = i + 1;
            break;
         }
      }
      if(orderNum > 0 && orderNum <= MaxOrdersPerSide)
         return g_gridBuyStopLots[orderNum - 1];
   }
   else if(orderType == ORDER_TYPE_SELL_STOP)
   {
      for(int i = 0; i < g_gridSellStopCount; i++)
      {
         if(MathAbs(g_gridSellStopLevels[i] - priceLevel) < tolerance)
         {
            orderNum = i + 1;
            break;
         }
      }
      if(orderNum > 0 && orderNum <= MaxOrdersPerSide)
         return g_gridSellStopLots[orderNum - 1];
   }
   
   return 0; // Khong tim thay
}

//+------------------------------------------------------------------+
//| Dam bao co lenh tai level - tao neu chua co (AUTO REFILL)        |
//| Chi bo sung de HOAN THANH CAP (1 Buy + 1 Sell)                   |
//| - Neu luoi co Sell (chua co Buy) -> bo sung Buy                  |
//| - Neu luoi co Buy (chua co Sell) -> bo sung Sell                 |
//| SU DUNG GRID LEVEL INDEX de xu ly slippage                       |
//| SU DUNG LOT DA GHI NHO (neu co) de dam bao dung lot gap thep     |
//+------------------------------------------------------------------+
void EnsureOrderAtLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   // Xac dinh day la lenh Buy hay Sell
   bool isBuyOrder = (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP);
   
   // KIEM TRA 1: Kiem tra cau truc dung theo vi tri so voi duong vang
   if(!IsValidOrderTypeForLevel(orderType, priceLevel))
      return;
   
   // KIEM TRA 2: AUTO REFILL chi bo sung de hoan thanh cap
   // Neu luoi co Sell -> cho phep bo sung Buy (va nguoc lai)
   // Neu luoi da du cap -> KHONG bo sung
   if(!CheckCanRefillAtLevel(priceLevel, isBuyOrder))
      return;
   
   // Da kiem tra ky - Chua co lenh va position, dat lenh moi
   double price = NormalizeDouble(priceLevel, g_digits);
   
   // TIM LOT DA GHI NHO cho level nay
   double memorizedLot = LookupLotForLevel(orderType, price);
   
   if(orderType == ORDER_TYPE_BUY_LIMIT)
   {
      double lot = (memorizedLot > 0) ? memorizedLot : BuyLimitStartLot;
      if(PlaceBuyLimit(price, lot, 0))
      {
         Print(">>> AUTO REFILL: Dat lai Buy Limit tai ", DoubleToString(price, g_digits), 
               " Lot=", DoubleToString(lot, 2), (memorizedLot > 0 ? " (GHI NHO)" : " (FALLBACK)"));
         AddRefillNotification("Buy Limit", price, lot);
      }
   }
   else if(orderType == ORDER_TYPE_SELL_LIMIT)
   {
      double lot = (memorizedLot > 0) ? memorizedLot : SellLimitStartLot;
      if(PlaceSellLimit(price, lot, 0))
      {
         Print(">>> AUTO REFILL: Dat lai Sell Limit tai ", DoubleToString(price, g_digits), 
               " Lot=", DoubleToString(lot, 2), (memorizedLot > 0 ? " (GHI NHO)" : " (FALLBACK)"));
         AddRefillNotification("Sell Limit", price, lot);
      }
   }
   else if(orderType == ORDER_TYPE_BUY_STOP)
   {
      double lot = (memorizedLot > 0) ? memorizedLot : BuyStopStartLot;
      if(PlaceBuyStop(price, lot, 0))
      {
         Print(">>> AUTO REFILL: Dat lai Buy Stop tai ", DoubleToString(price, g_digits), 
               " Lot=", DoubleToString(lot, 2), (memorizedLot > 0 ? " (GHI NHO)" : " (FALLBACK)"));
         AddRefillNotification("Buy Stop", price, lot);
      }
   }
   else if(orderType == ORDER_TYPE_SELL_STOP)
   {
      double lot = (memorizedLot > 0) ? memorizedLot : SellStopStartLot;
      if(PlaceSellStop(price, lot, 0))
      {
         Print(">>> AUTO REFILL: Dat lai Sell Stop tai ", DoubleToString(price, g_digits), 
               " Lot=", DoubleToString(lot, 2), (memorizedLot > 0 ? " (GHI NHO)" : " (FALLBACK)"));
         AddRefillNotification("Sell Stop", price, lot);
      }
   }
}

//+------------------------------------------------------------------+
//| HELPER: Chuyen gia thanh grid level index (so nguyen)            |
//| Level 0 = gia goc, Level 1 = cach 1 GridGap, Level -1 = duoi...  |
//| Dung round() de xu ly slippage                                   |
//+------------------------------------------------------------------+
int GetGridLevelIndex(double price)
{
   if(g_gridReferencePrice <= 0) return 0;
   
   double gridGap = GridGapPips * g_pipValue;
   if(gridGap <= 0) return 0;
   
   double distance = price - g_gridReferencePrice;
   int levelIndex = (int)MathRound(distance / gridGap);
   
   return levelIndex;
}

//+------------------------------------------------------------------+
//| Kiem tra loai lenh co dung cho vi tri (tren/duoi duong vang) khong|
//| TREN duong vang: chi Sell Limit + Buy Stop                        |
//| DUOI duong vang: chi Buy Limit + Sell Stop                        |
//+------------------------------------------------------------------+
bool IsValidOrderTypeForLevel(ENUM_ORDER_TYPE orderType, double priceLevel)
{
   if(g_gridReferencePrice <= 0) return true; // Chua khoi tao, cho phep dat
   
   int levelIndex = GetGridLevelIndex(priceLevel);
   
   // TREN duong vang (levelIndex > 0): chi Sell Limit + Buy Stop
   if(levelIndex > 0)
   {
      if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
         return true;
      else
         return false; // Buy Limit hoac Sell Stop khong dung cho phia tren
   }
   
   // DUOI duong vang (levelIndex < 0): chi Buy Limit + Sell Stop
   if(levelIndex < 0)
   {
      if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_STOP)
         return true;
      else
         return false; // Sell Limit hoac Buy Stop khong dung cho phia duoi
   }
   
   return true; // Tai dung gia goc (levelIndex == 0), cho phep
}

//+------------------------------------------------------------------+
//| Kiem tra cau truc tai level: toi da 1 buy type + 1 sell type     |
//| SU DUNG GRID LEVEL INDEX de xu ly slippage                       |
//| Dem ca pending order va position dang mo                         |
//| Tra ve true neu co the dat them lenh                             |
//| Dung cho DAT LENH BAN DAU: cho phep 1 Buy + 1 Sell cung level    |
//+------------------------------------------------------------------+
bool CheckGridStructureAtLevel(double priceLevel, bool isBuyType)
{
   int targetLevel = GetGridLevelIndex(priceLevel);
   int buyCount = 0;  // Dem Buy Limit/Buy Stop/Buy Position
   int sellCount = 0; // Dem Sell Limit/Sell Stop/Sell Position
   
   // Dem pending orders tai CUNG LEVEL INDEX
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            int orderLevel = GetGridLevelIndex(orderInfo.PriceOpen());
            if(orderLevel == targetLevel)
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
   
   // Dem positions tai CUNG LEVEL INDEX (xu ly slippage)
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            int posLevel = GetGridLevelIndex(positionInfo.PriceOpen());
            if(posLevel == targetLevel)
            {
               if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                  buyCount++;
               else
                  sellCount++;
            }
         }
      }
   }
   
   // LOGIC DAT LENH BAN DAU: toi da 1 buy + 1 sell cung level
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
//| Kiem tra cho AUTO REFILL: Chi bo sung de HOAN THANH CAP          |
//| - Neu luoi co Sell (chua co Buy) -> cho phep bo sung Buy         |
//| - Neu luoi co Buy (chua co Sell) -> cho phep bo sung Sell        |
//| - Neu luoi da du cap (1 Buy + 1 Sell) -> KHONG bo sung           |
//| - Neu luoi trong -> cho phep bo sung                             |
//+------------------------------------------------------------------+
bool CheckCanRefillAtLevel(double priceLevel, bool isBuyType)
{
   int targetLevel = GetGridLevelIndex(priceLevel);
   int buyCount = 0;
   int sellCount = 0;
   
   // Dem pending orders tai CUNG LEVEL INDEX
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
         {
            int orderLevel = GetGridLevelIndex(orderInfo.PriceOpen());
            if(orderLevel == targetLevel)
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
   
   // Dem positions tai CUNG LEVEL INDEX
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
         {
            int posLevel = GetGridLevelIndex(positionInfo.PriceOpen());
            if(posLevel == targetLevel)
            {
               if(positionInfo.PositionType() == POSITION_TYPE_BUY)
                  buyCount++;
               else
                  sellCount++;
            }
         }
      }
   }
   
   // LOGIC AUTO REFILL: Bo sung de HOAN THANH CAP
   if(isBuyType)
   {
      // Muon bo sung Buy:
      // - Da co Buy -> KHONG (da du)
      // - Chua co Buy, co Sell -> OK (bo sung de hoan thanh cap)
      // - Chua co Buy, chua co Sell -> OK (luoi trong)
      if(buyCount >= 1)
         return false; // Da co Buy, khong bo sung them
      // buyCount = 0 -> cho phep bo sung Buy
      return true;
   }
   else
   {
      // Muon bo sung Sell:
      // - Da co Sell -> KHONG (da du)
      // - Chua co Sell, co Buy -> OK (bo sung de hoan thanh cap)
      // - Chua co Sell, chua co Buy -> OK (luoi trong)
      if(sellCount >= 1)
         return false; // Da co Sell, khong bo sung them
      // sellCount = 0 -> cho phep bo sung Sell
      return true;
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi BUY LIMIT - Bo sung lenh rieng                      |
//| KIEM TRA KY: Moi level chi co 1 Buy + 1 Sell                     |
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
      
      // KIEM TRA 1: Loai lenh dung vi tri (Buy Limit phai DUOI duong vang)
      if(!IsValidOrderTypeForLevel(ORDER_TYPE_BUY_LIMIT, nextPrice))
         continue;
      
      // KIEM TRA 2: Cau truc tai level (max 1 Buy + 1 Sell)
      if(!CheckGridStructureAtLevel(nextPrice, true))
         continue;
      
      int orderNum = currentOrders + i + 1;
      double lot = CalculateBuyLimitLot(orderNum);
      PlaceBuyLimit(nextPrice, lot, orderNum);
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi SELL LIMIT - Bo sung lenh rieng                     |
//| KIEM TRA KY: Moi level chi co 1 Buy + 1 Sell                     |
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
      
      // KIEM TRA 1: Loai lenh dung vi tri (Sell Limit phai TREN duong vang)
      if(!IsValidOrderTypeForLevel(ORDER_TYPE_SELL_LIMIT, nextPrice))
         continue;
      
      // KIEM TRA 2: Cau truc tai level (max 1 Buy + 1 Sell)
      if(!CheckGridStructureAtLevel(nextPrice, false))
         continue;
      
      int orderNum = currentOrders + i + 1;
      double lot = CalculateSellLimitLot(orderNum);
      PlaceSellLimit(nextPrice, lot, orderNum);
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi BUY STOP - Bo sung lenh rieng                       |
//| KIEM TRA KY: Moi level chi co 1 Buy + 1 Sell                     |
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
      
      // KIEM TRA 1: Loai lenh dung vi tri (Buy Stop phai TREN duong vang)
      if(!IsValidOrderTypeForLevel(ORDER_TYPE_BUY_STOP, nextPrice))
         continue;
      
      // KIEM TRA 2: Cau truc tai level (max 1 Buy + 1 Sell)
      if(!CheckGridStructureAtLevel(nextPrice, true))
         continue;
      
      int orderNum = currentOrders + i + 1;
      double lot = CalculateBuyStopLot(orderNum);
      PlaceBuyStop(nextPrice, lot, orderNum);
   }
}

//+------------------------------------------------------------------+
//| Quan ly luoi SELL STOP - Bo sung lenh rieng                      |
//| KIEM TRA KY: Moi level chi co 1 Buy + 1 Sell                     |
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
      
      // KIEM TRA 1: Loai lenh dung vi tri (Sell Stop phai DUOI duong vang)
      if(!IsValidOrderTypeForLevel(ORDER_TYPE_SELL_STOP, nextPrice))
         continue;
      
      // KIEM TRA 2: Cau truc tai level (max 1 Buy + 1 Sell)
      if(!CheckGridStructureAtLevel(nextPrice, false))
         continue;
      
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
//| TINH TRUOC TAT CA LOT CHO MOI BAC (goi 1 lan trong OnInit)       |
//| Dua tren input: StartLot, LotMode, Multiplier, Addition, Group   |
//| Luu vao mang g_grid*Lots[] de dung khi dat lenh va auto-refill   |
//+------------------------------------------------------------------+
void PreCalculateAllGridLots()
{
   Print(">>> TINH TRUOC LOT CHO ", MaxOrdersPerSide, " BAC...");
   
   // Tinh lot cho tung bac (1 den MaxOrdersPerSide)
   for(int orderNum = 1; orderNum <= MaxOrdersPerSide; orderNum++)
   {
      int idx = orderNum - 1; // Index trong mang (bac 1 = index 0)
      
      // Buy Limit
      g_gridBuyLimitLots[idx] = CalculateBuyLimitLot(orderNum);
      
      // Sell Limit
      g_gridSellLimitLots[idx] = CalculateSellLimitLot(orderNum);
      
      // Buy Stop
      g_gridBuyStopLots[idx] = CalculateBuyStopLot(orderNum);
      
      // Sell Stop
      g_gridSellStopLots[idx] = CalculateSellStopLot(orderNum);
   }
   
   // In ra de kiem tra
   Print(">>> LOT DA TINH SAN (BAC 1-5):");
   for(int i = 0; i < MathMin(5, MaxOrdersPerSide); i++)
   {
      Print("   Bac ", i+1, ": BL=", DoubleToString(g_gridBuyLimitLots[i], 2),
            " SL=", DoubleToString(g_gridSellLimitLots[i], 2),
            " BS=", DoubleToString(g_gridBuyStopLots[i], 2),
            " SS=", DoubleToString(g_gridSellStopLots[i], 2));
   }
}

//+------------------------------------------------------------------+
//| Dat lenh Buy Stop                                                |
//| KIEM TRA CUOI CUNG truoc khi gui lenh                            |
//+------------------------------------------------------------------+
bool PlaceBuyStop(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(price <= currentAsk)
      return false;
   
   // KIEM TRA CUOI CUNG: Cau truc tai level (max 1 Buy + 1 Sell) - DUNG GRID LEVEL INDEX
   if(!CheckGridStructureAtLevel(price, true))
      return false;
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseBuyStopTP && BuyStopTPPips > 0)
      tp = NormalizeDouble(price + BuyStopTPPips * g_pipValue, g_digits);
   
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
//| KIEM TRA CUOI CUNG truoc khi gui lenh                            |
//+------------------------------------------------------------------+
bool PlaceSellStop(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price >= currentBid)
      return false;
   
   // KIEM TRA CUOI CUNG: Cau truc tai level (max 1 Buy + 1 Sell) - DUNG GRID LEVEL INDEX
   if(!CheckGridStructureAtLevel(price, false))
      return false;
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseSellStopTP && SellStopTPPips > 0)
      tp = NormalizeDouble(price - SellStopTPPips * g_pipValue, g_digits);
   
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
//| KIEM TRA CUOI CUNG truoc khi gui lenh                            |
//+------------------------------------------------------------------+
bool PlaceBuyLimit(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(price >= currentAsk)
      return false;
   
   // KIEM TRA CUOI CUNG: Cau truc tai level (max 1 Buy + 1 Sell) - DUNG GRID LEVEL INDEX
   if(!CheckGridStructureAtLevel(price, true))
      return false;
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseBuyLimitTP && BuyLimitTPPips > 0)
      tp = NormalizeDouble(price + BuyLimitTPPips * g_pipValue, g_digits);
   
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
//| KIEM TRA CUOI CUNG truoc khi gui lenh                            |
//+------------------------------------------------------------------+
bool PlaceSellLimit(double price, double lot, int orderNum)
{
   price = NormalizeDouble(price, g_digits);
   
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(price <= currentBid)
      return false;
   
   // KIEM TRA CUOI CUNG: Cau truc tai level (max 1 Buy + 1 Sell) - DUNG GRID LEVEL INDEX
   if(!CheckGridStructureAtLevel(price, false))
      return false;
   
   // Tinh TP neu bat
   double tp = 0;
   if(UseSellLimitTP && SellLimitTPPips > 0)
      tp = NormalizeDouble(price - SellLimitTPPips * g_pipValue, g_digits);
   
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
//| KIEM TRA KHONG CON LENH NAO (Verify clean state)                 |
//| Tra ve true neu khong con position va pending order nao          |
//+------------------------------------------------------------------+
bool VerifyNoOpenOrdersOrPositions()
{
   int posCount = 0;
   int ordCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == MagicNumber)
            posCount++;
      }
   }
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(orderInfo.SelectByIndex(i))
      {
         if(orderInfo.Symbol() == _Symbol && orderInfo.Magic() == MagicNumber)
            ordCount++;
      }
   }
   
   if(posCount > 0 || ordCount > 0)
   {
      Print(">>> VERIFY: Con ", posCount, " position va ", ordCount, " lenh cho!");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| DONG TAT CA LENH VA KIEM TRA LAI (CloseAll + Verify)             |
//| Dong tat ca position, xoa tat ca pending, kiem tra lai           |
//+------------------------------------------------------------------+
void CloseAllAndVerify()
{
   Print(">>> BAT DAU DONG TAT CA LENH...");
   
   CloseAllPositions();
   DeleteAllPendingOrders();
   
   Sleep(500);
   
   if(!VerifyNoOpenOrdersOrPositions())
   {
      Print(">>> CANH BAO: Con lenh chua dong! Thu dong lai...");
      CloseAllPositions();
      DeleteAllPendingOrders();
      Sleep(500);
      
      if(!VerifyNoOpenOrdersOrPositions())
      {
         Print(">>> CANH BAO: Van con lenh chua dong sau 2 lan thu!");
      }
   }
   
   Print(">>> HOAN TAT DONG TAT CA LENH!");
}

//+------------------------------------------------------------------+
//| BAT DAU COOLDOWN SAU KHI DAT TP/SESSION                          |
//+------------------------------------------------------------------+
void StartCooldown()
{
   if(!UseCooldownAfterTP || CooldownMinutes <= 0)
   {
      g_isInCooldown = false;
      return;
   }
   
   g_isInCooldown = true;
   g_cooldownEndTime = TimeCurrent() + (CooldownMinutes * 60);
   g_cooldownSecondsRemaining = CooldownMinutes * 60;
   
   Print(">>> BAT DAU COOLDOWN: ", CooldownMinutes, " phut");
   Print(">>> SE VAO LENH LAI LUC: ", TimeToString(g_cooldownEndTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS));
}

//+------------------------------------------------------------------+
//| CAP NHAT TRANG THAI COOLDOWN (goi moi tick)                      |
//| Tra ve true neu dang trong cooldown (KHONG cho vao lenh)         |
//+------------------------------------------------------------------+
bool UpdateCooldown()
{
   if(!g_isInCooldown)
      return false;
   
   datetime currentTime = TimeCurrent();
   
   if(currentTime >= g_cooldownEndTime)
   {
      g_isInCooldown = false;
      g_cooldownSecondsRemaining = 0;
      Print(">>> COOLDOWN KET THUC! Cho phep vao lenh lai.");
      return false;
   }
   
   g_cooldownSecondsRemaining = (int)(g_cooldownEndTime - currentTime);
   
   if(!VerifyNoOpenOrdersOrPositions())
   {
      Print(">>> COOLDOWN: Phat hien lenh con ton tai! Dong tat ca...");
      CloseAllAndVerify();
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| FORMAT THOI GIAN COOLDOWN THANH CHUOI (MM:SS)                    |
//+------------------------------------------------------------------+
string FormatCooldownTime()
{
   if(!g_isInCooldown || g_cooldownSecondsRemaining <= 0)
      return "";
   
   int minutes = g_cooldownSecondsRemaining / 60;
   int seconds = g_cooldownSecondsRemaining % 60;
   
   return StringFormat("%02d:%02d", minutes, seconds);
}

//+------------------------------------------------------------------+
//| Tạo panel hiển thị - GIAO DIEN TIENG VIET                        |
//+------------------------------------------------------------------+
void CreatePanel()
{
   int panelX = 10;
   int panelY = 25;
   int panelWidth = 230;
   int spacing = 5;
   int lineHeight = 16;
   int boxHeight = 18;
   
   // ============ HEADER: Symbol + Status ============
   CreateRectangle("GM_BG_Header", panelX, panelY, panelWidth, 28, C'30,35,45', C'60,65,75');
   CreateLabel("GM_Header_Symbol", _Symbol, panelX + 8, panelY + 6, clrWhite, 11);
   CreateLabel("GM_Header_TF", EnumToString((ENUM_TIMEFRAMES)Period()), panelX + 100, panelY + 8, clrGray, 9);
   CreateLabel("GM_Header_Status", "Dang chay", panelX + 155, panelY + 8, clrLime, 9);
   panelY += 33;
   
   // ============ KHUNG LOI NHUAN LON ============
   CreateRectangle("GM_BG_Profit", panelX, panelY, panelWidth, 55, C'40,45,55', C'60,65,75');
   CreateLabel("GM_Label_Profit", "Loi nhuan hien tai", panelX + 8, panelY + 5, clrGray, 8);
   CreateLabel("GM_Label_BasePrice", "Gia goc luoi", panelX + 145, panelY + 5, clrGray, 8);
   CreateLabel("GM_Value_Profit", "0.00", panelX + 8, panelY + 22, clrLime, 14);
   CreateLabel("GM_Value_ProfitUSD", "USD", panelX + 80, panelY + 28, clrGray, 10);
   CreateLabel("GM_Value_BasePrice", "0.00000", panelX + 145, panelY + 22, clrGold, 10);
   panelY += 60;
   
   // ============ LO LON NHAT va MUC CHOT LOI (2 khung nho) ============
   int halfWidth = (panelWidth - spacing) / 2;
   
   // Lo lon nhat
   CreateRectangle("GM_BG_MaxLoss", panelX, panelY, halfWidth, 42, C'50,40,40', C'80,60,60');
   CreateLabel("GM_Label_MaxLoss", "Lo lon nhat", panelX + 8, panelY + 5, clrGray, 8);
   CreateLabel("GM_Value_MaxLoss", "0.00 USD", panelX + 8, panelY + 20, clrOrangeRed, 10);
   
   // Muc chot loi dung EA
   CreateRectangle("GM_BG_Target", panelX + halfWidth + spacing, panelY, halfWidth, 42, C'40,50,40', C'60,80,60');
   CreateLabel("GM_Label_Target", "Chot loi dung EA", panelX + halfWidth + spacing + 8, panelY + 5, clrGray, 8);
   CreateLabel("GM_Value_Target", DoubleToString(TotalTakeProfitMoney, 0) + " USD", panelX + halfWidth + spacing + 8, panelY + 20, clrLime, 10);
   panelY += 47;
   
   // ============ KHUNG MUA va BAN (2 cot) ============
   // MUA
   CreateRectangle("GM_BG_Buy", panelX, panelY, halfWidth, 60, C'35,45,60', C'55,70,95');
   CreateLabel("GM_Buy_Title", "MUA", panelX + 8, panelY + 5, clrDodgerBlue, 10);
   CreateLabel("GM_Buy_Active", "0 mo", panelX + 50, panelY + 7, clrGold, 8);
   CreateLabel("GM_Buy_LimitLabel", "Limit", panelX + 8, panelY + 24, clrSilver, 9);
   CreateLabel("GM_Buy_LimitValue", "0/" + IntegerToString(MaxOrdersPerSide), panelX + 60, panelY + 24, clrWhite, 9);
   CreateLabel("GM_Buy_StopLabel", "Stop", panelX + 8, panelY + 40, clrSilver, 9);
   CreateLabel("GM_Buy_StopValue", "0/" + IntegerToString(MaxOrdersPerSide), panelX + 60, panelY + 40, clrWhite, 9);
   
   // BAN
   CreateRectangle("GM_BG_Sell", panelX + halfWidth + spacing, panelY, halfWidth, 60, C'60,40,45', C'95,55,65');
   CreateLabel("GM_Sell_Title", "BAN", panelX + halfWidth + spacing + 8, panelY + 5, clrOrangeRed, 10);
   CreateLabel("GM_Sell_Active", "0 mo", panelX + halfWidth + spacing + 55, panelY + 7, clrGold, 8);
   CreateLabel("GM_Sell_LimitLabel", "Limit", panelX + halfWidth + spacing + 8, panelY + 24, clrSilver, 9);
   CreateLabel("GM_Sell_LimitValue", "0/" + IntegerToString(MaxOrdersPerSide), panelX + halfWidth + spacing + 60, panelY + 24, clrWhite, 9);
   CreateLabel("GM_Sell_StopLabel", "Stop", panelX + halfWidth + spacing + 8, panelY + 40, clrSilver, 9);
   CreateLabel("GM_Sell_StopValue", "0/" + IntegerToString(MaxOrdersPerSide), panelX + halfWidth + spacing + 60, panelY + 40, clrWhite, 9);
   panelY += 65;
   
   // ============ KHUNG THONG BAO ============
   CreateRectangle("GM_BG_Notify", panelX, panelY, panelWidth, 72, C'45,50,60', C'65,70,80');
   CreateLabel("GM_Notify_Icon", ">>", panelX + 8, panelY + 5, clrGold, 9);
   CreateLabel("GM_Notify_Title", "THONG BAO BO SUNG LENH", panelX + 30, panelY + 5, clrWhite, 9);
   CreateLabel("GM_Notify_Time1", "", panelX + 8, panelY + 22, clrGray, 8);
   CreateLabel("GM_Notify_Text1", "", panelX + 45, panelY + 22, clrSilver, 8);
   CreateLabel("GM_Notify_Lot1", "", panelX + 175, panelY + 22, clrGray, 8);
   CreateLabel("GM_Notify_Time2", "", panelX + 8, panelY + 38, clrGray, 8);
   CreateLabel("GM_Notify_Text2", "", panelX + 45, panelY + 38, clrSilver, 8);
   CreateLabel("GM_Notify_Lot2", "", panelX + 175, panelY + 38, clrGray, 8);
   CreateLabel("GM_Notify_Time3", "", panelX + 8, panelY + 54, clrDarkGray, 8);
   CreateLabel("GM_Notify_Text3", "", panelX + 45, panelY + 54, clrLime, 8);
   CreateLabel("GM_Notify_Lot3", "", panelX + 175, panelY + 54, clrLime, 8);
   panelY += 77;
   
   // ============ KHUNG THONG SO ============
   CreateRectangle("GM_BG_Stats", panelX, panelY, panelWidth, 75, C'40,45,55', C'60,65,75');
   
   // Hang 1: Reset lai + Reset lo
   CreateLabel("GM_Label_ResetProfit", "Chot lai Reset", panelX + 8, panelY + 5, clrGray, 8);
   CreateLabel("GM_Value_ResetProfit", "+" + DoubleToString(TakeProfitMoney, 2) + " USD", panelX + 8, panelY + 18, clrLime, 9);
   CreateLabel("GM_Label_ResetLoss", "Cat lo Reset", panelX + halfWidth + spacing + 8, panelY + 5, clrGray, 8);
   CreateLabel("GM_Value_ResetLoss", "-" + DoubleToString(StopLossMoney, 2) + " USD", panelX + halfWidth + spacing + 8, panelY + 18, clrOrangeRed, 9);
   
   // Hang 2: Session + Tong da dong
   CreateLabel("GM_Label_Session", "Lai phien", panelX + 8, panelY + 35, clrGray, 8);
   string sessionInitText = "(0.00/" + DoubleToString(SessionTargetMoney, 0) + ") USD";
   CreateLabel("GM_Value_Session", sessionInitText, panelX + 8, panelY + 48, clrGold, 9);
   CreateLabel("GM_Label_TotalClosed", "Tong da dong", panelX + halfWidth + spacing + 8, panelY + 35, clrGray, 8);
   CreateLabel("GM_Value_TotalClosed", "0.00 USD", panelX + halfWidth + spacing + 8, panelY + 48, clrDodgerBlue, 9);
   panelY += 80;
   
   // ============ KHUNG COUNTDOWN + MAX LOT + TRANG THAI ============
   CreateRectangle("GM_BG_MaxLot", panelX, panelY, panelWidth, 55, C'35,40,50', C'55,60,70');
   
   // Dong 1: Cho vao lenh (countdown)
   CreateLabel("GM_Label_Countdown", "Cho vao lenh:", panelX + 8, panelY + 5, clrGray, 8);
   CreateLabel("GM_Value_Countdown", "---", panelX + 85, panelY + 5, clrLime, 9);
   
   // Dong 2: Max Lot + Max Bac + Trang thai
   CreateLabel("GM_Label_MaxLotStat", "Lot lon nhat", panelX + 8, panelY + 22, clrGray, 8);
   CreateLabel("GM_Value_MaxLot", "0.00", panelX + 8, panelY + 35, clrGold, 10);
   CreateLabel("GM_Label_MaxStep", "Bac cao nhat", panelX + 75, panelY + 22, clrGray, 8);
   CreateLabel("GM_Value_MaxStep", "0", panelX + 75, panelY + 35, clrGold, 10);
   CreateLabel("GM_Label_StatusText", "Trang thai", panelX + 145, panelY + 22, clrGray, 8);
   CreateLabel("GM_Status_Dot", "*", panelX + 145, panelY + 35, clrLime, 12);
   CreateLabel("GM_Status_Text", "CHAY", panelX + 160, panelY + 37, clrLime, 9);
   panelY += 60;
   
   // ============ BUTTONS ============
   CreateButton("GM_Btn_Start", "Bat EA", panelX, panelY, 70, 28, clrWhite, C'0,150,80');
   CreateButton("GM_Btn_Stop", "Tat EA", panelX + 75, panelY, 70, 28, clrWhite, C'180,60,60');
   CreateButton("GM_Btn_Reset", "Lam moi", panelX + 150, panelY, 60, 28, clrWhite, C'70,130,180');
}

//+------------------------------------------------------------------+
//| Cau truc luu thong bao (Time, Text, Lot)                         |
//+------------------------------------------------------------------+
string g_notifyTime1 = "", g_notifyText1 = "", g_notifyLot1 = "";
string g_notifyTime2 = "", g_notifyText2 = "", g_notifyLot2 = "";
string g_notifyTime3 = "", g_notifyText3 = "", g_notifyLot3 = "";

//+------------------------------------------------------------------+
//| THEM THONG BAO BO SUNG LENH (day len va them moi vao cuoi)       |
//| Thong bao cu nhat o tren, moi nhat o duoi                        |
//+------------------------------------------------------------------+
void AddRefillNotification(string orderType, double price, double lot)
{
   // Day thong bao len tren
   g_notifyTime1 = g_notifyTime2;
   g_notifyText1 = g_notifyText2;
   g_notifyLot1 = g_notifyLot2;
   
   g_notifyTime2 = g_notifyTime3;
   g_notifyText2 = g_notifyText3;
   g_notifyLot2 = g_notifyLot3;
   
   // Tao thong bao moi (moi nhat o cuoi)
   g_notifyTime3 = TimeToString(TimeCurrent(), TIME_MINUTES);
   g_notifyText3 = orderType + " @ " + DoubleToString(price, g_digits);
   g_notifyLot3 = "Lot " + DoubleToString(lot, 2);
   
   // Giu lai cho tuong thich
   g_refillNotify1 = g_refillNotify2;
   g_refillNotify2 = g_refillNotify3;
   g_refillNotify3 = g_notifyTime3 + " " + g_notifyText3 + " " + g_notifyLot3;
   
   // Cap nhat hien thi ngay
   UpdateNotifyPanel();
}

//+------------------------------------------------------------------+
//| CAP NHAT KHUNG THONG BAO BO SUNG - GIAO DIEN MOI                 |
//+------------------------------------------------------------------+
void UpdateNotifyPanel()
{
   // Dong 1 (cu nhat) - mau xam
   ObjectSetString(0, "GM_Notify_Time1", OBJPROP_TEXT, g_notifyTime1);
   ObjectSetString(0, "GM_Notify_Text1", OBJPROP_TEXT, g_notifyText1);
   ObjectSetString(0, "GM_Notify_Lot1", OBJPROP_TEXT, g_notifyLot1);
   ObjectSetInteger(0, "GM_Notify_Time1", OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, "GM_Notify_Text1", OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, "GM_Notify_Lot1", OBJPROP_COLOR, clrGray);
   
   // Dong 2 (giua) - mau xam nhat
   ObjectSetString(0, "GM_Notify_Time2", OBJPROP_TEXT, g_notifyTime2);
   ObjectSetString(0, "GM_Notify_Text2", OBJPROP_TEXT, g_notifyText2);
   ObjectSetString(0, "GM_Notify_Lot2", OBJPROP_TEXT, g_notifyLot2);
   ObjectSetInteger(0, "GM_Notify_Time2", OBJPROP_COLOR, clrDarkGray);
   ObjectSetInteger(0, "GM_Notify_Text2", OBJPROP_COLOR, clrSilver);
   ObjectSetInteger(0, "GM_Notify_Lot2", OBJPROP_COLOR, clrDarkGray);
   
   // Dong 3 (moi nhat) - mau xanh la/vang
   ObjectSetString(0, "GM_Notify_Time3", OBJPROP_TEXT, g_notifyTime3);
   ObjectSetString(0, "GM_Notify_Text3", OBJPROP_TEXT, g_notifyText3);
   ObjectSetString(0, "GM_Notify_Lot3", OBJPROP_TEXT, g_notifyLot3);
   ObjectSetInteger(0, "GM_Notify_Time3", OBJPROP_COLOR, clrDarkGray);
   ObjectSetInteger(0, "GM_Notify_Text3", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "GM_Notify_Lot3", OBJPROP_COLOR, clrGold);
}

//+------------------------------------------------------------------+
//| Tao Rectangle Label (nen co mau)                                 |
//+------------------------------------------------------------------+
void CreateRectangle(string name, int x, int y, int width, int height, color bgColor, color borderColor)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Tao label                                                        |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
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
//| Cập nhật panel - GIAO DIEN TIENG VIET                            |
//+------------------------------------------------------------------+
void UpdatePanel(double profit, int buyPos, int sellPos, int buyPending, int sellPending)
{
   // ============ HEADER STATUS ============
   if(g_isStopped)
   {
      ObjectSetString(0, "GM_Header_Status", OBJPROP_TEXT, "Da dung");
      ObjectSetInteger(0, "GM_Header_Status", OBJPROP_COLOR, clrRed);
   }
   else if(g_isPaused)
   {
      ObjectSetString(0, "GM_Header_Status", OBJPROP_TEXT, "Tam dung");
      ObjectSetInteger(0, "GM_Header_Status", OBJPROP_COLOR, clrOrange);
   }
   else if(g_isInCooldown)
   {
      ObjectSetString(0, "GM_Header_Status", OBJPROP_TEXT, "Cho " + FormatCooldownTime());
      ObjectSetInteger(0, "GM_Header_Status", OBJPROP_COLOR, clrOrangeRed);
   }
   else
   {
      ObjectSetString(0, "GM_Header_Status", OBJPROP_TEXT, "Dang chay");
      ObjectSetInteger(0, "GM_Header_Status", OBJPROP_COLOR, clrLime);
   }
   
   // ============ PROFIT ============
   color profitColor = profit >= 0 ? clrLime : clrOrangeRed;
   ObjectSetString(0, "GM_Value_Profit", OBJPROP_TEXT, DoubleToString(profit, 2));
   ObjectSetInteger(0, "GM_Value_Profit", OBJPROP_COLOR, profitColor);
   
   // ============ BASE PRICE ============
   if(g_gridReferencePrice > 0)
      ObjectSetString(0, "GM_Value_BasePrice", OBJPROP_TEXT, DoubleToString(g_gridReferencePrice, g_digits));
   else
      ObjectSetString(0, "GM_Value_BasePrice", OBJPROP_TEXT, "---");
   
   // ============ MAX LOSS ============
   ObjectSetString(0, "GM_Value_MaxLoss", OBJPROP_TEXT, DoubleToString(g_maxDrawdown, 2) + " USD");
   
   // ============ DEM LENH THEO LOAI ============
   int buyLimitPending, sellLimitPending, buyStopPending, sellStopPending;
   CountPendingByType(buyLimitPending, sellLimitPending, buyStopPending, sellStopPending);
   
   // MUA: Limit + Stop + Dang mo
   ObjectSetString(0, "GM_Buy_Active", OBJPROP_TEXT, IntegerToString(buyPos) + " mo");
   ObjectSetString(0, "GM_Buy_LimitValue", OBJPROP_TEXT, IntegerToString(buyLimitPending) + "/" + IntegerToString(MaxOrdersPerSide));
   ObjectSetString(0, "GM_Buy_StopValue", OBJPROP_TEXT, IntegerToString(buyStopPending) + "/" + IntegerToString(MaxOrdersPerSide));
   
   // BAN: Limit + Stop + Dang mo
   ObjectSetString(0, "GM_Sell_Active", OBJPROP_TEXT, IntegerToString(sellPos) + " mo");
   ObjectSetString(0, "GM_Sell_LimitValue", OBJPROP_TEXT, IntegerToString(sellLimitPending) + "/" + IntegerToString(MaxOrdersPerSide));
   ObjectSetString(0, "GM_Sell_StopValue", OBJPROP_TEXT, IntegerToString(sellStopPending) + "/" + IntegerToString(MaxOrdersPerSide));
   
   // ============ LAI PHIEN (Session Profit) - Hien thi (x/y) USD ============
   double sessionTotal = g_sessionClosedProfit + profit;
   string sessionText = "(" + DoubleToString(sessionTotal, 2) + "/" + DoubleToString(SessionTargetMoney, 0) + ") USD";
   ObjectSetString(0, "GM_Value_Session", OBJPROP_TEXT, sessionText);
   color sessionColor = sessionTotal >= SessionTargetMoney ? clrLime : (sessionTotal >= 0 ? clrGold : clrOrangeRed);
   ObjectSetInteger(0, "GM_Value_Session", OBJPROP_COLOR, sessionColor);
   
   // ============ TONG DA DONG ============
   ObjectSetString(0, "GM_Value_TotalClosed", OBJPROP_TEXT, DoubleToString(g_totalProfitAccum, 2) + " USD");
   color totalColor = g_totalProfitAccum >= 0 ? clrDodgerBlue : clrOrangeRed;
   ObjectSetInteger(0, "GM_Value_TotalClosed", OBJPROP_COLOR, totalColor);
   
   // ============ COUNTDOWN - CHO VAO LENH ============
   if(g_isInCooldown)
   {
      // Dang cho: hien thi phut:giay con lai
      ObjectSetString(0, "GM_Value_Countdown", OBJPROP_TEXT, FormatCooldownTime() + " con lai");
      ObjectSetInteger(0, "GM_Value_Countdown", OBJPROP_COLOR, clrOrangeRed);
   }
   else
   {
      // San sang: hien thi thoi gian cho sau TP
      string readyText = "San sang (" + IntegerToString(CooldownMinutes) + " phut)";
      ObjectSetString(0, "GM_Value_Countdown", OBJPROP_TEXT, readyText);
      ObjectSetInteger(0, "GM_Value_Countdown", OBJPROP_COLOR, clrLime);
   }
   
   // ============ MAX LOT + MAX BAC ============
   ObjectSetString(0, "GM_Value_MaxLot", OBJPROP_TEXT, DoubleToString(g_maxLotUsed, 2));
   ObjectSetString(0, "GM_Value_MaxStep", OBJPROP_TEXT, IntegerToString(g_maxGridLevel));
   
   // ============ TRANG THAI ============
   if(g_isStopped)
   {
      ObjectSetString(0, "GM_Status_Text", OBJPROP_TEXT, "DUNG");
      ObjectSetInteger(0, "GM_Status_Text", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, "GM_Status_Dot", OBJPROP_COLOR, clrRed);
   }
   else if(g_isPaused)
   {
      ObjectSetString(0, "GM_Status_Text", OBJPROP_TEXT, "TAM");
      ObjectSetInteger(0, "GM_Status_Text", OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(0, "GM_Status_Dot", OBJPROP_COLOR, clrOrange);
   }
   else if(g_isInCooldown)
   {
      ObjectSetString(0, "GM_Status_Text", OBJPROP_TEXT, "CHO");
      ObjectSetInteger(0, "GM_Status_Text", OBJPROP_COLOR, clrOrangeRed);
      ObjectSetInteger(0, "GM_Status_Dot", OBJPROP_COLOR, clrOrangeRed);
   }
   else
   {
      ObjectSetString(0, "GM_Status_Text", OBJPROP_TEXT, "CHAY");
      ObjectSetInteger(0, "GM_Status_Text", OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, "GM_Status_Dot", OBJPROP_COLOR, clrLime);
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
