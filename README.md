# Grid Matrix EA v1.0 - Expert Advisor cho MetaTrader 5

## Tong quan

Grid Matrix EA la mot Expert Advisor giao dich theo chien luoc LUOI (Grid Trading) tren MetaTrader 5. EA ho tro 4 loai lenh doc lap: Buy Limit, Sell Limit, Buy Stop, Sell Stop voi kha nang tu dong bo sung lenh khi dat TP.

---

## Chien luoc giao dich

### Nguyen ly hoat dong

Grid Trading la chien luoc dat nhieu lenh cho (pending orders) tai cac muc gia cach deu nhau (goi la "luoi"). Khi gia cham vao cac muc nay, lenh se duoc kich hoat va EA quan ly lai/lo theo tong so tien.

```
         SELL LIMIT 5  ──────────  (Xa nhat tren)
         SELL LIMIT 4  ──────────
         SELL LIMIT 3  ──────────
         SELL LIMIT 2  ──────────
         SELL LIMIT 1  ──────────  (Gan gia nhat)
              ↑
    ═══════ GIA HIEN TAI ═══════  (Duong vang tham chieu)
              ↓
         BUY LIMIT 1   ──────────  (Gan gia nhat)
         BUY LIMIT 2   ──────────
         BUY LIMIT 3   ──────────
         BUY LIMIT 4   ──────────
         BUY LIMIT 5   ──────────  (Xa nhat duoi)
```

### 4 Loai lenh doc lap

| Loai lenh | Vi tri | Mo ta |
|-----------|--------|-------|
| **Buy Limit** | DUOI gia hien tai | Mua khi gia giam xuong |
| **Sell Limit** | TREN gia hien tai | Ban khi gia tang len |
| **Buy Stop** | TREN gia hien tai | Mua khi gia breakout len |
| **Sell Stop** | DUOI gia hien tai | Ban khi gia breakout xuong |

**Quy tac tai moi level:** Toi da 2 lenh - 1 Buy type (Buy Limit HOAC Buy Stop) + 1 Sell type (Sell Limit HOAC Sell Stop)

### Chien luoc gap thep (Lot Scaling)

EA ho tro 5 che do gap thep cho TUNG LOAI lenh:

| Che do | Cong thuc | Vi du (StartLot=0.01) |
|--------|-----------|----------------------|
| **Lot co dinh** | lot = StartLot | 0.01 → 0.01 → 0.01 → 0.01 |
| **Nhan moi bac** | lot = StartLot × Multiplier^(n-1) | 0.01 → 0.015 → 0.023 → 0.034 (x1.5) |
| **Cong moi bac** | lot = StartLot + (n-1) × Addition | 0.01 → 0.02 → 0.03 → 0.04 (+0.01) |
| **Nhan theo nhom** | lot = StartLot × Multiplier^(groupIndex) | Nhom 5 luoi: 0.01×5 → 0.015×5 → 0.023×5 |
| **Cong theo nhom** | lot = StartLot + floor((n-1)/GridsPerGroup) × Addition | Nhom 5 luoi: 0.01×5 → 0.02×5 → 0.03×5 |

---

## Tinh nang chinh

- **4 loai lenh doc lap:** Bat/Tat rieng tung loai (Buy Limit, Sell Limit, Buy Stop, Sell Stop)
- **MaxOrdersPerSide ap dung TUNG LOAI:** 50 lenh = 50 BL + 50 SL + 50 BS + 50 SS
- **Gap thep rieng cho tung loai:** Moi loai co che do gap thep va tham so rieng
- **TP rieng cho tung loai lenh:** Theo pips, bat/tat duoc
- **Tu dong bo sung lenh:** Khi lenh dat TP, EA tu dong dat lai lenh moi tai level do
- **TP/SL theo tong tien:** Dong tat ca lenh khi dat muc lai/lo
- **Session Target:** Muc loi nhuan phien, khi dat se vao Cooldown
- **Cooldown Timer:** Cho X phut truoc khi giao dich lai
- **Panel hien thi chi tiet:** Giao dien tieng Viet, dark theme

---

## Mo ta Panel hien thi

Panel duoc thiet ke voi giao dien dark theme, hien thi day du thong tin:

```
┌─────────────────────────────────────────┐
│ BTCUSD         PERIOD: Dang chay        │  ← Header: Symbol, Timeframe, Trang thai
│ -60.40 USD     Gia goc: 96501.67        │  ← Lai/Lo hien tai, Gia tham chieu luoi
├─────────────────────────────────────────┤
│ Lo lon nhat        Muc TP               │
│ -694.54 USD        10000 USD            │  ← Max Drawdown va Target TP tong
├─────────────────────────────────────────┤
│ MUA         1m     BAN                  │
│ Limit: 39/40       Limit: 36/40         │  ← So lenh Limit (dang mo/tong)
│ Stop:  35/40       Stop:  37/40         │  ← So lenh Stop (dang mo/tong)
├─────────────────────────────────────────┤
│ >>> THONG BAO BO SUNG LENH <<<          │
│ 21:01  Buy Limit @ 96461.67   Lot 0.01  │  ← 3 dong thong bao gan nhat
│ 21:02  Sell Limit @ 96551.67  Lot 0.05  │
│ 21:22  Buy Stop @ 96601.67    Lot 0.02  │
├─────────────────────────────────────────┤
│ Cot lo Reset        Cat lo Reset        │
│ CHO: 00 USD         -300 USD            │  ← Muc TP/SL de reset
│ Lai phien           Tong da dong        │
│ (4.67/20) USD       82.93 USD           │  ← Session profit / Total closed
├─────────────────────────────────────────┤
│ Cho vao lenh   San sang (1 phut)        │  ← Countdown hoac trang thai
│ Lot cao nhat   Bac cao nhat   Trang thai│
│ 0.32           32              CHAY     │  ← Max lot, Max level, Status
├─────────────────────────────────────────┤
│ [Bat EA]    [Tat EA]    [Lam moi]       │  ← 3 nut dieu khien
└─────────────────────────────────────────┘
```

### Giai thich cac phan Panel

| Phan | Mo ta |
|------|-------|
| **Header** | Symbol, Timeframe, Trang thai EA (Dang chay/Tam dung/Da dung) |
| **Lai/Lo** | Tong lai/lo cua cac vi the dang mo (realtime) |
| **Gia goc** | Gia tham chieu de tinh cac level luoi |
| **Lo lon nhat** | Max Drawdown - So tien lo lon nhat da ghi nhan |
| **Muc TP** | TotalTakeProfitMoney - Muc TP tong de dung EA |
| **MUA/BAN** | So lenh tung loai: Limit va Stop rieng biet |
| **Thong bao** | 3 dong gan nhat ve viec bo sung lenh (thoi gian, loai, gia, lot) |
| **Cot lo Reset** | TakeProfitMoney - Muc lai de reset phien |
| **Cat lo Reset** | StopLossMoney - Muc lo de reset phien |
| **Lai phien** | (Current/Target) - Lai da chot trong phien / Session Target |
| **Tong da dong** | Tong lai/lo tu cac lenh da dong |
| **Cho vao lenh** | Countdown khi dang cooldown, hoac "San sang" |
| **Lot cao nhat** | Lot lon nhat dang su dung |
| **Bac cao nhat** | Level xa nhat da dat lenh |
| **Trang thai** | CHAY / DUNG / CHO |

### 3 Nut dieu khien

| Nut | Mau | Chuc nang |
|-----|-----|-----------|
| **Bat EA** | Xanh la | Bat EA tiep tuc giao dich. Neu dung do TP tong → Reset het. Neu dung thu cong → Giu so lieu |
| **Tat EA** | Do | Dong tat ca lenh mo + Xoa lenh cho + Tam dung EA |
| **Lam moi** | Xanh duong | Reset HOAN TOAN (xoa lenh, reset so lieu, bat dau chay ngay) |

---

## Tham so cau hinh

### Cau hinh chinh
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| MagicNumber | ID rieng cua EA | 123456 |
| TradeComment | Ghi chu lenh | "Grid_Matrix" |
| ShowPanel | Hien thi panel | true |

### Cau hinh Grid
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| InitialOffsetPips | Khoang cach tu gia hien tai den lenh dau | 50 |
| GridGapPips | Khoang cach giua cac lenh | 50 |
| MaxOrdersPerSide | So lenh toi da MOI LOAI | 40 |

### Buy Limit
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| UseBuyLimit | Bat/Tat lenh Buy Limit | true |
| BuyLimitStartLot | Lot dau tien | 0.01 |
| BuyLimitLotMode | Che do gap thep (enum) | LotScale_None |
| BuyLimitMultiplier | He so nhan | 1.5 |
| BuyLimitAddition | Buoc cong lot | 0.01 |
| BuyLimitGridsPerGroup | So luoi moi nhom | 5 |
| UseBuyLimitTP | Bat TP rieng | false |
| BuyLimitTPPips | TP (pips) | 50 |
| AutoRefillBuyLimit | Tu dong bo sung | true |

### Sell Limit
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| UseSellLimit | Bat/Tat lenh Sell Limit | true |
| SellLimitStartLot | Lot dau tien | 0.01 |
| SellLimitLotMode | Che do gap thep (enum) | LotScale_None |
| SellLimitMultiplier | He so nhan | 1.5 |
| SellLimitAddition | Buoc cong lot | 0.01 |
| SellLimitGridsPerGroup | So luoi moi nhom | 5 |
| UseSellLimitTP | Bat TP rieng | false |
| SellLimitTPPips | TP (pips) | 50 |
| AutoRefillSellLimit | Tu dong bo sung | true |

### Buy Stop
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| UseBuyStop | Bat/Tat lenh Buy Stop | false |
| BuyStopStartLot | Lot dau tien | 0.01 |
| BuyStopLotMode | Che do gap thep (enum) | LotScale_None |
| BuyStopMultiplier | He so nhan | 1.5 |
| BuyStopAddition | Buoc cong lot | 0.01 |
| BuyStopGridsPerGroup | So luoi moi nhom | 5 |
| UseBuyStopTP | Bat TP rieng | false |
| BuyStopTPPips | TP (pips) | 50 |
| AutoRefillBuyStop | Tu dong bo sung | true |

### Sell Stop
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| UseSellStop | Bat/Tat lenh Sell Stop | false |
| SellStopStartLot | Lot dau tien | 0.01 |
| SellStopLotMode | Che do gap thep (enum) | LotScale_None |
| SellStopMultiplier | He so nhan | 1.5 |
| SellStopAddition | Buoc cong lot | 0.01 |
| SellStopGridsPerGroup | So luoi moi nhom | 5 |
| UseSellStopTP | Bat TP rieng | false |
| SellStopTPPips | TP (pips) | 50 |
| AutoRefillSellStop | Tu dong bo sung | true |

### Chot loi / Cat lo
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| TakeProfitMoney | Muc lai de reset phien (USD) | 100 |
| StopLossMoney | Muc lo de reset phien (USD) | 200 |
| AutoResetOnTP | Tu dong reset khi dat TP | true |
| AutoResetOnSL | Tu dong reset khi dat SL | false |

### Session & Cooldown
| Tham so | Mo ta | Mac dinh |
|---------|-------|----------|
| SessionTargetMoney | Muc lai phien (USD) | 0 (tat) |
| CooldownMinutes | Thoi gian cho sau khi dat target (phut) | 1 |
| TotalTakeProfitMoney | TP tong de DUNG EA (USD) | 0 (tat) |

---

## Logic hoat dong

### Khi bat EA:
1. EA dat NGAY LAP TUC tat ca lenh Grid tai cac level
2. Moi level co the co 1 Buy type + 1 Sell type

### Khi lenh dat TP rieng (neu bat):
1. Vi the dong va ghi nhan lai
2. Neu AutoRefill = true: EA tu dong dat lai lenh tai level do
3. Dieu kien bo sung:
   - Buy Limit / Sell Limit: Bo sung NGAY LAP TUC
   - Buy Stop / Sell Stop: Bo sung khi gia cach IT NHAT 1 bac luoi

### Khi dat Session Target:
1. Dong tat ca vi the
2. Xoa tat ca lenh cho
3. Vao che do Cooldown (dem nguoc X phut)
4. Sau cooldown, bat dau phien moi

### Khi dat TakeProfitMoney (reset):
1. Dong tat ca vi the
2. Xoa tat ca lenh cho
3. Neu AutoResetOnTP = true: Bat dau vong moi ngay

### Khi dat TotalTakeProfitMoney:
1. Dong tat ca vi the
2. Xoa tat ca lenh cho
3. EA DUNG hoan toan (can nhan Bat EA de chay lai)

---

## Cai dat

### Buoc 1: Copy file EA
1. Mo MetaTrader 5
2. Vao menu **File > Open Data Folder**
3. Mo thu muc `MQL5/Experts`
4. Copy file `Grid_Matrix_EA.mq5` vao day

### Buoc 2: Bien dich EA
1. Trong MT5, nhan **F4** de mo MetaEditor
2. Mo file `Grid_Matrix_EA.mq5`
3. Nhan **F7** de Compile
4. Dam bao khong co loi (0 errors)

### Buoc 3: Chay EA
1. Quay lai MT5
2. Nhan **Ctrl+N** de mo Navigator
3. Keo `Grid_Matrix_EA` vao chart
4. Cau hinh tham so va nhan **OK**

---

## Canh bao rui ro

- **Backtest truoc khi su dung thuc**
- **Quan ly von** - Dam bao du margin cho so lenh toi da
- **Gap thep NHAN** - Rui ro cao, lot tang nhanh
- **Gap thep theo NHOM** - Can theo doi ky de tranh lot qua lon

Giao dich Forex/CFD co rui ro cao. EA nay chi la cong cu ho tro, khong dam bao loi nhuan. Ban co the mat toan bo von dau tu.

---

## Phien ban

- **v1.0** - Grid Matrix EA voi 4 loai lenh doc lap, gap thep theo nhom, session target, cooldown timer, panel tieng Viet dark theme
