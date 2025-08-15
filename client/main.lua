local usingTarget = GetResourceState('ox_target') == 'started'
local mode = (Config.Interaction and Config.Interaction.mode) or 'ox_lib'
local lastOpenedShop = nil

-- ===== Utils
local function toVec3(v)
  if type(v) == 'vector3' then return v end
  if type(v) == 'vector4' then return vec3(v.x, v.y, v.z) end
  if type(v) == 'table' then
    if v.x and v.y and v.z then return vec3(v.x, v.y, v.z) end
    if v[1] and v[2] and v[3] then return vec3(v[1], v[2], v[3]) end
  end
end

local function arrow(n)
  if n > 0 then return _T('trend_up') .. math.abs(n)
  elseif n < 0 then return _T('trend_down') .. math.abs(n)
  else return _T('trend_flat') .. '0' end
end

local function nearestShop()
  local me = GetEntityCoords(cache.ped)
  local best = { id=nil, dist=math.huge, radius=4.0 }
  for id,shop in pairs(Config.Shops) do
    local r = shop.openRadius or Config.Interaction.openRadiusDefault or 4.0
    for _,loc in ipairs(shop.locations or {}) do
      local v = toVec3(loc)
      if v then
        local d = #(me - v)
        if d < best.dist then best = { id=id, dist=d, radius=r } end
      end
    end
    for _,p in ipairs(shop.peds or {}) do
      local v = vec3(p.coords.x, p.coords.y, p.coords.z)
      local d = #(me - v)
      if d < best.dist then best = { id=id, dist=d, radius=r } end
    end
  end
  return best
end

-- ===== UI (ox_lib context) =====
local function openMarket(shopId)
  lastOpenedShop = shopId
  local catalog = lib.callback.await('tq_market_lib:getCatalog', false, shopId)
  if not catalog then
    return lib.notify({ type='error', description=_T('ui_market_unavailable') })
  end

  local items = catalog.items or {}
  local cats  = catalog.categories or {}

  local buckets = {}
  for _,it in ipairs(items) do
    local key = it.category or 'misc'
    buckets[key] = buckets[key] or {}
    table.insert(buckets[key], it)
  end

  local rootId = ('tq_market_root_%s'):format(shopId)
  local rootOpts = {}
  if next(cats) then
    for key,label in pairs(cats) do
      rootOpts[#rootOpts+1] = {
        title = label,
        icon = 'fa-solid fa-tags',
        menu = ('tq_market_cat_%s_%s'):format(shopId, key),
        args = { key=key }
      }
    end
  else
    rootOpts[#rootOpts+1] = { title=_T('ui_all_items'), icon='fa-solid fa-tags', menu=('tq_market_cat_%s_all'):format(shopId), args={ key='__all' } }
    buckets['__all'] = items
  end

  lib.registerContext({ id=rootId, title=catalog.shopName, options=rootOpts })
  lib.showContext(rootId)

  local function makeItemOption(it)
    local title = it.label
    if it.onSale and it.discount and it.discount > 0 then
      title = ("%s  [%s]"):format(title, _T('sale_badge', it.discount))
    end

    -- Show both 1h and 24h arrows (compact)
    local buyLine  = ("$%d %s/%s"):format(it.buyPrice, arrow(it.buyDelta1h or 0), arrow(it.buyDelta24h or 0))
    local sellLine = ("$%d %s/%s"):format(it.sellPrice, arrow(it.sellDelta1h or 0), arrow(it.sellDelta24h or 0))

    return {
      title = title,
      description = _T('menu_stock_line', it.stock, it.buyPrice, it.sellPrice)
                    .. ("  |  B:%s  S:%s"):format(buyLine, sellLine),
      image = it.image,
      menu  = ('tq_market_item_%s_%s'):format(shopId, it.name),
      args  = it
    }
  end


  local function registerCatMenu(catKey, list)
    local opts = {}
    for _,it in ipairs(list or {}) do opts[#opts+1] = makeItemOption(it) end
    lib.registerContext({
      id   = ('tq_market_cat_%s_%s'):format(shopId, catKey),
      title = (cats[catKey] or _T('ui_all_items')),
      menu  = rootId,
      options = opts
    })
  end

  for key,list in pairs(buckets) do registerCatMenu(key, list) end

  for _,it in ipairs(items) do
    lib.registerContext({
      id = ('tq_market_item_%s_%s'):format(shopId, it.name),
      title = (it.onSale and it.discount and it.discount > 0)
                and (("%s  (stock %d)  [%s]"):format(it.label, it.stock, _T('sale_badge', it.discount)))
                or  (("%s  (stock %d)"):format(it.label, it.stock)),
      image = it.image,
      menu  = ('tq_market_cat_%s_%s'):format(shopId, it.category or 'misc'),
      options = {
        {
          title = _T('menu_buy_now', it.buyPrice),
          onSelect = function()
            local input = lib.inputDialog(_T('dialog_buy_title', it.label), { { type='number', label=_T('dialog_amount'), min=1, default=1 } })
            if input and input[1] and input[1] > 0 then
              TriggerServerEvent('tq_market_lib:buy', shopId, it.name, math.floor(input[1]))
            end
          end
        },
        {
          title = _T('menu_sell_now', it.sellPrice),
          onSelect = function()
            local input = lib.inputDialog(_T('dialog_sell_title', it.label), { { type='number', label=_T('dialog_amount'), min=1, default=1 } })
            if input and input[1] and input[1] > 0 then
              TriggerServerEvent('tq_market_lib:sell', shopId, it.name, math.floor(input[1]))
            end
          end
        },
      }
    })
  end
end

-- public export + event for CUSTOM interaction
exports('OpenMarket', openMarket)
RegisterNetEvent('tq_market_lib:open', function(shopId) openMarket(shopId) end)

-- refresh
RegisterNetEvent('tq_market_lib:refresh', function(shopId)
  if shopId then lastOpenedShop = shopId end
  if lastOpenedShop then openMarket(lastOpenedShop) end
end)

-- ===== Interaction Adapter =====
CreateThread(function()
  local chosen = mode

  for id,shop in pairs(Config.Shops) do
    local radius = shop.openRadius or Config.Interaction.openRadiusDefault or 4.0

    -- Spawn peds?
    local spawnPeds = true
    if chosen == 'custom' and (Config.Interaction.spawnPedsInCustom == false) then
      spawnPeds = false
    end

    if spawnPeds then
      for _,p in ipairs(shop.peds or {}) do
        lib.requestModel(p.model, 5000)
        local ped = CreatePed(0, p.model, p.coords.x, p.coords.y, p.coords.z - 1.0, p.coords.w, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)

        if chosen == 'ox_target' and usingTarget then
          exports.ox_target:addLocalEntity(ped, {
            { icon = Config.Interaction.targetIcon or 'fa-solid fa-shop',
              label = _T('ui_open_shop', shop.name),
              onSelect = function() openMarket(id) end
            }
          })
        elseif chosen == 'ox_lib' then
          lib.zones.sphere({
            coords = vec3(p.coords.x, p.coords.y, p.coords.z),
            radius = radius,
            inside = function()
              lib.showTextUI(_T('ui_press_open', shop.name))
              if IsControlJustPressed(0, 38) then openMarket(id) end
            end,
            onExit = function() lib.hideTextUI() end
          })
        end
        -- if 'custom', we just spawn (optional) and do not attach interactions
      end
    end

    -- Additional location points (no ped)
    for _,loc in ipairs(shop.locations or {}) do
      if chosen == 'ox_lib' then
        local v = toVec3(loc)
        lib.zones.sphere({
          coords = v,
          radius = radius,
          inside = function()
            lib.showTextUI(_T('ui_press_open', shop.name))
            if IsControlJustPressed(0, 38) then openMarket(id) end
          end,
          onExit = function() lib.hideTextUI() end
        })
      elseif chosen == 'ox_target' and usingTarget then
        -- optional: add a small prop to target; skipping to keep map clean
      end
      -- 'custom' => do nothing (you handle access in your own resource)
    end
  end
end)

--Debug: show all shops
-- Command: open nearest (still useful for testing)
--[[ RegisterCommand('market', function()
  local best = nearestShop()
  if best.id and best.dist <= (best.radius or 4.0) + 0.2 then
    openMarket(best.id)
  else
    lib.notify({ type='error', description=_T('ui_no_market_near') })
  end
end) ]]
