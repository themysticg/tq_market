local INV = exports.ox_inventory

-- ================= Utils =================
local function clamp(n, a, b) return (n<a) and a or ((n>b) and b or n) end
local function round(n) return math.floor(n + 0.5) end

-- State: State[shopId][itemName] = { stock = number }
local State = {}

local ActiveSales = {}     -- ActiveSales[shopId][category] = { discount=0.2, endsAt=os.time(), title='...' }
local History = {}         -- History[shopId][itemName] = { {ts, buy, sell}, ... }
local MAX_POINTS = math.ceil((Config.Trend.lookback24h or 86400) / (Config.Trend.snapshotEverySec or 300)) + 4

local function ensureShopTables(shopId)
  State[shopId] = State[shopId] or {}
  ActiveSales[shopId] = ActiveSales[shopId] or {}
  History[shopId] = History[shopId] or {}
end

local function getCategory(shopId, itemName)
  local shop = Config.Shops[shopId]; if not shop then return nil end
  local item = shop.items[itemName]; if not item then return nil end
  return item.category
end

local function getActiveDiscount(shopId, itemName)
  local cat = getCategory(shopId, itemName)
  if not cat then return 0 end
  local entry = ActiveSales[shopId] and ActiveSales[shopId][cat]
  if entry and entry.endsAt and os.time() < entry.endsAt then
    return entry.discount or 0
  end
  return 0
end

-- buy price with current sale discount applied (and MinSpread guard)
local function unitBuyPriceCurrent(shopId, itemName, sellPriceNow)
  local buy = math.ceil(sellPriceNow * (1 + (Config.Markup or 0.25)))
  if Config.MinSpread and buy < sellPriceNow + Config.MinSpread then
    buy = sellPriceNow + Config.MinSpread
  end
  local disc = getActiveDiscount(shopId, itemName)
  if disc > 0 then
    buy = math.floor(buy * (1 - disc) + 0.0001)
    if Config.MinSpread and buy < sellPriceNow + Config.MinSpread then
      buy = sellPriceNow + Config.MinSpread
    end
  end
  return buy
end

-- trend snapshots
local function pushSnapshot(shopId, itemName, buy, sell)
  History[shopId][itemName] = History[shopId][itemName] or {}
  local list = History[shopId][itemName]
  list[#list+1] = { ts = os.time(), buy = buy, sell = sell }
  if #list > MAX_POINTS then
    local remove = #list - MAX_POINTS
    for i=1, remove do table.remove(list, 1) end
  end
end

local function findPriceAt(shopId, itemName, secondsAgo)
  local target = os.time() - secondsAgo
  local list = History[shopId][itemName] or {}
  local last = nil
  for i = #list, 1, -1 do
    if list[i].ts <= target then last = list[i]; break end
  end
  return last -- {ts, buy, sell} or nil
end

-- Resolve image URL for UI
local function resolveImage(shopId, itemName)
  local shop = Config.Shops[shopId]; if not shop then return nil end
  local item = shop.items[itemName]
  if item and item.image then
    return ('nui://%s/web/images/%s'):format(GetCurrentResourceName(), item.image)
  end
  if Config.Images and Config.Images.useOxInventoryImages then
    return ('nui://ox_inventory/web/images/%s.png'):format(itemName)
  end
  return ('nui://%s/web/images/%s.png'):format(GetCurrentResourceName(), itemName)
end

-- Linear sell price (NPC pays)
local function unitSellPrice(shopId, itemName, stock)
  local shop = Config.Shops[shopId]; if not shop then return 0 end
  local cfg = shop.items[itemName]; if not cfg then return 0 end
  local s0, sCap = cfg.sellAtZero, cfg.sellAtCap
  local cap = math.max(1, cfg.capStock or 1000)
  if stock <= 0 then return s0 end
  if stock >= cap then return sCap end
  local t = stock / cap
  local p = s0 - (s0 - sCap) * t
  return round(p)
end

-- Marginal total (prevents chunking exploits)
local function totalSellPayout(shopId, itemName, startStock, qty)
  local tot = 0
  for i=0, qty-1 do
    tot = tot + unitSellPrice(shopId, itemName, startStock + i)
  end
  return tot
end

-- Buy price from sell (guarded)
local function unitBuyFromSell(sell)
  local buy = math.ceil(sell * (1 + (Config.Markup or 0.25)))
  if Config.MinSpread and buy < sell + Config.MinSpread then
    buy = sell + Config.MinSpread
  end
  return buy
end

-- total cost for buying qty with discount + marginal pricing (stock moves during buy)
local function totalBuyCost(shopId, itemName, startStock, qty)
  local tot = 0
  local disc = getActiveDiscount(shopId, itemName)
  for i=0, qty-1 do
    local s = unitSellPrice(shopId, itemName, startStock - i)     -- sell at pre-removal stock
    local buy = math.ceil(s * (1 + (Config.Markup or 0.25)))
    if Config.MinSpread and buy < s + Config.MinSpread then buy = s + Config.MinSpread end
    if disc > 0 then
      buy = math.floor(buy * (1 - disc) + 0.0001)
      if Config.MinSpread and buy < s + Config.MinSpread then buy = s + Config.MinSpread end
    end
    tot = tot + buy
  end
  return tot
end

-- ================= Persistence =================
local function ensureAllItems(shopId)
  State[shopId] = State[shopId] or {}
  for name,_ in pairs(Config.Shops[shopId].items) do
    if not State[shopId][name] then State[shopId][name] = { stock = 0 } end
  end
end

local function loadShop(shopId)
  State[shopId] = {}
  if Config.Persistence.mode == 'mysql' then
    local rows = MySQL.query.await(('SELECT item, stock FROM %s WHERE shop = ?'):format(Config.Persistence.table), { shopId })
    for _,r in ipairs(rows or {}) do
      State[shopId][r.item] = { stock = tonumber(r.stock) or 0 }
    end
  else
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.Persistence.jsonFile) or '{}'
    local blob = json.decode(raw) or {}
    State = blob -- blob is map of shop->item->stock
    State[shopId] = State[shopId] or {}
  end
  ensureAllItems(shopId)
end

local function saveStateItem(shopId, itemName)
  local stock = clamp(State[shopId][itemName].stock or 0, 0, 10^9)
  if Config.Persistence.mode == 'mysql' then
    MySQL.prepare.await(
      ('INSERT INTO %s (shop,item,stock) VALUES (?,?,?) ON DUPLICATE KEY UPDATE stock = VALUES(stock)')
      :format(Config.Persistence.table),
      { shopId, itemName, stock }
    )
  else
    -- write whole blob (small table)
    SaveResourceFile(GetCurrentResourceName(), Config.Persistence.jsonFile, json.encode(State), -1)
  end
end

-- ================= Catalog for UI =================
lib.callback.register('tq_market_lib:getCatalog', function(src, shopId)
  local shop = Config.Shops[shopId]
  if not shop then return nil end
  ensureShopTables(shopId)

  local list = {}
  for name, data in pairs(State[shopId]) do
    local sell = unitSellPrice(shopId, name, data.stock)
    local buy  = unitBuyPriceCurrent(shopId, name, sell)
    local disc = getActiveDiscount(shopId, name)
    local sale = (disc > 0)

    -- trends
    local h1 = findPriceAt(shopId, name, Config.Trend.lookback1h or 3600)
    local d1 = findPriceAt(shopId, name, Config.Trend.lookback24h or 86400)
    local buyDelta1h  = h1 and (buy - h1.buy) or 0
    local sellDelta1h = h1 and (sell - h1.sell) or 0
    local buyDelta24h  = d1 and (buy - d1.buy) or 0
    local sellDelta24h = d1 and (sell - d1.sell) or 0

    list[#list+1] = {
      name      = name,
      label     = shop.items[name].label,
      category  = shop.items[name].category,
      stock     = data.stock,
      sellPrice = sell,
      buyPrice  = buy,
      image     = resolveImage(shopId, name),
      onSale    = sale,
      discount  = sale and math.floor(disc * 100) or 0,
      saleEnds  = (ActiveSales[shopId][getCategory(shopId, name)] or {}).endsAt,

      buyDelta1h = buyDelta1h,   sellDelta1h = sellDelta1h,
      buyDelta24h = buyDelta24h, sellDelta24h = sellDelta24h,
    }
  end

  return { shopId = shopId, shopName = shop.name, categories = shop.categories or {}, items = list }
end)


-- ================= Sell (player -> shop) =================
RegisterNetEvent('tq_market_lib:sell', function(shopId, itemName, amount)
  local src = source
  local shop = Config.Shops[shopId]
  if not shop then return end
  local qty = tonumber(amount or 0) or 0
  if qty <= 0 then return end
  if not shop.items[itemName] then
    return TriggerClientEvent('ox_lib:notify', src, { type='error', description=_T('notify_not_bought_here') })
  end

  local have = INV:GetItemCount(src, itemName)
  if (have or 0) < qty then
    return TriggerClientEvent('ox_lib:notify', src, { type='error', description=_T('notify_not_enough_items') })
  end

  local before = State[shopId][itemName].stock
  local payout = totalSellPayout(shopId, itemName, before, qty)

  if not INV:RemoveItem(src, itemName, qty) then
    return TriggerClientEvent('ox_lib:notify', src, { type='error', description=_T('notify_could_not_remove') })
  end

  local Player = exports.qbx_core:GetPlayer(src); if not Player then return end
  Player.Functions.AddMoney(shop.payAccount or 'cash', payout, ('%s-sell'):format(shopId))

  State[shopId][itemName].stock = before + qty
  saveStateItem(shopId, itemName)

  TriggerClientEvent('ox_lib:notify', src, { type='success', description = _T('notify_sold_line', qty, shop.items[itemName].label, payout) })

  TriggerClientEvent('tq_market_lib:refresh', src, shopId)
end)

-- ================= Buy (shop -> player) =================
RegisterNetEvent('tq_market_lib:buy', function(shopId, itemName, amount)
  local src = source
  local shop = Config.Shops[shopId]
  if not shop then return end
  local qty = tonumber(amount or 0) or 0
  if qty <= 0 then return end
  if not shop.items[itemName] then
    return TriggerClientEvent('ox_lib:notify', src, { type='error', description=_T('notify_not_sold_here') })
  end

  if State[shopId][itemName].stock < qty then
    return TriggerClientEvent('ox_lib:notify', src, { type='error', description=_T('notify_not_enough_stock') })
  end

  local before = State[shopId][itemName].stock
  local cost   = totalBuyCost(shopId, itemName, before, qty)

  local Player = exports.qbx_core:GetPlayer(src); if not Player then return end
  local function tryCharge(acc, amt)
    if not acc or amt <= 0 then return false end
    local bal = Player.Functions.GetMoney(acc)
    if (bal or 0) >= amt then Player.Functions.RemoveMoney(acc, amt, ('%s-buy'):format(shopId)); return true end
    return false
  end

  local paid = tryCharge(shop.chargeFirst, cost) or tryCharge(shop.chargeSecond, cost)
  if not paid then
    return TriggerClientEvent('ox_lib:notify', src, { type='error', description=_T('notify_not_enough_funds') })
  end

  if not INV:AddItem(src, itemName, qty) then
    -- refund to first account
    Player.Functions.AddMoney(shop.chargeFirst or 'cash', cost, ('%s-buy-refund'):format(shopId))
    return TriggerClientEvent('ox_lib:notify', src, { type='error', description=_T('notify_could_not_add') })
  end

  State[shopId][itemName].stock = before - qty
  saveStateItem(shopId, itemName)

  TriggerClientEvent('ox_lib:notify', src, { type='success', description = _T('notify_bought_line', qty, shop.items[itemName].label, cost) })

  TriggerClientEvent('tq_market_lib:refresh', src, shopId)
end)

-- ================= Init =================
AddEventHandler('onResourceStart', function(res)
  if res ~= GetCurrentResourceName() then return end
  for id,_ in pairs(Config.Shops) do loadShop(id) end
end)

local function secondsUntil(hour, minute)
  local now = os.date('*t')
  local run = { year=now.year, month=now.month, day=now.day, hour=hour, min=minute, sec=0, isdst=now.isdst }
  local tRun = os.time(run)
  if tRun <= os.time() then
    run.day = run.day + 1
    tRun = os.time(run)
  end
  return tRun - os.time()
end

local function doNightlyDecay()
  if not (Config.Decay and Config.Decay.enabled) then return end
  for shopId, shop in pairs(Config.Shops) do
    ensureShopTables(shopId)
    local touchedCats = {}
    for itemName, entry in pairs(State[shopId]) do
      local cat = getCategory(shopId, itemName)
      local rule = cat and Config.Decay.categories and Config.Decay.categories[cat]
      if rule and entry.stock > 0 then
        local remove = math.floor(entry.stock * (rule.percent or 0))
        local newStock = math.max((entry.stock - remove), rule.minLeft or 0)
        if newStock ~= entry.stock then
          State[shopId][itemName].stock = newStock
          saveStateItem(shopId, itemName)
          touchedCats[cat] = true
        end
      end
    end
    if Config.Decay.announce and next(touchedCats) then
      local catList = {}
      for k,_ in pairs(touchedCats) do table.insert(catList, shop.categories[k] or k) end
      TriggerClientEvent('ox_lib:notify', -1, {
        type = 'info',
        description = _T('decay_broadcast', shop.name .. ' (' .. table.concat(catList, ', ') .. ')')
      })
    end
  end
end

CreateThread(function()
  if Config.Decay and Config.Decay.enabled then
    while true do
      local wait = secondsUntil(Config.Decay.hour or 4, Config.Decay.minute or 0)
      Wait((wait + 1) * 1000)
      doNightlyDecay()
    end
  end
end)

local function isoToTime(iso)
  -- very simple parser: "YYYY-MM-DDTHH:MM:SS" (assumes server local time)
  local y, m, d, H, M, S = iso:match('^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)')
  if not y then return nil end
  return os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=tonumber(H), min=tonumber(M), sec=tonumber(S)})
end

local function isSaleActive(def, now)
  if def.type == 'fixed' then
    local s = def._start or isoToTime(def.startISO or '') or 0
    local e = def._end   or isoToTime(def.endISO or '')   or 0
    return now >= s and now <= e, e
  elseif def.type == 'weekly' then
    -- any listed DOW today? if so, window from today @ hour:minute for duration
    local t = os.date('*t', now)
    local dow = t.wday - 1  -- Lua: 1=Sunday … 7=Saturday; make 0..6
    for _,d in ipairs(def.dow or {}) do
      if d == dow then
        local startToday = os.time({year=t.year, month=t.month, day=t.day, hour=def.hour or 0, min=def.minute or 0, sec=0, isdst=t.isdst})
        local ends = startToday + (60 * (def.durationMin or 60))
        return now >= startToday and now <= ends, ends
      end
    end
  end
  return false, nil
end

CreateThread(function()
  if not (Config.Sales and #Config.Sales > 0) then return end
  while true do
    local now = os.time()
    for _,def in ipairs(Config.Sales) do
      local shopId, cat = def.shop, def.category
      if Config.Shops[shopId] and cat then
        ActiveSales[shopId] = ActiveSales[shopId] or {}
        local active, endsAt = isSaleActive(def, now)
        local cur = ActiveSales[shopId][cat]
        if active and (not cur or not cur.endsAt or endsAt ~= cur.endsAt) then
          ActiveSales[shopId][cat] = { discount = def.discount or 0, endsAt = endsAt, title = def.title or 'Sale' }
          if def.announce then
            TriggerClientEvent('ox_lib:notify', -1, {
              type='success',
              description = _T('sale_started_broadcast', Config.Shops[shopId].name, def.title or 'Sale', math.floor((def.discount or 0)*100), (Config.Shops[shopId].categories[cat] or cat), math.floor(((endsAt - now)/60)+0.5))
            })
          end
        elseif (not active) and cur then
          ActiveSales[shopId][cat] = nil
            if def.announce then
            TriggerClientEvent('ox_lib:notify', -1, {
              type = 'inform',
              description = _T('sale_ended_broadcast', Config.Shops[shopId].name, def.title or 'Sale', (Config.Shops[shopId].categories[cat] or cat)),
              position = 'center',
              duration = 20000
            })
          end
        end
      end
    end
    Wait(15000) -- check every 15s
  end
end)

CreateThread(function()
  local every = (Config.Trend.snapshotEverySec or 300)
  while true do
    for shopId, shop in pairs(Config.Shops) do
      ensureShopTables(shopId)
      for itemName, data in pairs(State[shopId]) do
        local sell = unitSellPrice(shopId, itemName, data.stock)
        local buy  = unitBuyPriceCurrent(shopId, itemName, sell)
        pushSnapshot(shopId, itemName, buy, sell)
      end
    end
    if Config.Trend.persist then
      SaveResourceFile(GetCurrentResourceName(), Config.Trend.persistFile, json.encode(History), -1)
    end
    Wait(every * 1000)
  end
end)
