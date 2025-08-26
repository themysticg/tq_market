Config = {}

-- Locale
Config.Locale = 'pt'            -- 'en' or 'pt'

-- Images: prefer ox_inventory’s built-in icons unless you override per item.
Config.Images = {
  useOxInventoryImages = true, -- uses: nui://ox_inventory/web/images/<item>.png
}

Config.UpdateCheck = {
  enabled = true,
  url = 'https://raw.githubusercontent.com/themysticg/tq_market/main/version.json' -- raw JSON URL
}

Config.UI = Config.UI or {}

-- Mostra o ponto verde e "xN" nos itens possuídos (já tinhas pedido isto)
Config.UI.highlightOwned   = true

-- NOVO: ao vender, preencher o input com o MÁXIMO que o jogador tem
Config.UI.sellPrefillMax   = true

-- Opcional: vender imediatamente o máximo (sem abrir input)
Config.UI.sellMaxInstant   = false

-- Interaction provider:
-- 'ox_target' = use ox_target on peds; 'ox_lib' = proximity + TextUI; 'custom' = do nothing (you integrate)
Config.Interaction = {
  mode = 'ox_target',
  openRadiusDefault = 4.0,
  targetIcon = 'fa-solid fa-shop',  -- used if ox_target
  spawnPedsInCustom = false,        -- if mode='custom', still spawn peds? (false = don’t spawn)
}

-- Persistence
Config.Persistence = {
  mode   = 'mysql',              -- 'mysql' or 'json'
  table  = 'tq_market_stock',
  jsonFile = 'data/stock.json'
}

-- Global price guardrails
Config.Markup    = 0.25
Config.MinSpread = 1

-- Nightly decay/spoilage (server local time)
Config.Decay = {
  enabled = true,
  hour = 4,            -- 04:00 every day
  minute = 0,
  announce = true,     -- broadcast when decay runs
  categories = {
    -- key = categoryKey from each shop.categories
    vegetables = { percent = 0.15, minLeft = 0 },  -- remove 15% of current stock
    fruits = { percent = 0.15, minLeft = 0 },  -- remove 15% of current stock
    dairy = { percent = 0.15, minLeft = 0 },  -- remove 15% of current stock
    grain = { percent = 0.15, minLeft = 0 },  -- remove 15% of current stock
    meat = { percent = 0.15, minLeft = 0 },  -- remove 15% of current stock
    seafood = { percent = 0.15, minLeft = 0 },  -- remove 15% of current stock
    nuts = { percent = 0.15, minLeft = 0 },  -- remove 15% of current stock
  }
}

-- Limited-time sales (discount applies to BUY price, still enforces MinSpread)
-- You can mix 'weekly' and 'fixed' styles.
Config.Sales = {
  -- Weekly: Saturday 18:00 for 120 minutes (server time)
  { type='weekly', shop='ingredients', category='vegetables', discount=0.20,
    dow={5}, hour=11, minute=40, durationMin=120, title='Weekend Produce Rush', announce=true },

  -- Fixed ISO window (server interprets as local time if you omit 'Z')
  -- { type='fixed', shop='electronics', category='devices', discount=0.15,
  --   startISO='2025-08-20T18:00:00', endISO='2025-08-20T20:00:00', title='Back-to-school Sale', announce=true },
}

-- Trend snapshots (for ↑/↓ next to Buy/Sell)
Config.Trend = {
  snapshotEverySec = 300,  -- take a price snapshot every 5 minutes
  lookback1h = 3600,
  lookback24h = 86400,
  persist = false,                -- keep in RAM only; set true to write file below
  persistFile = 'data/history.json'
}

-- ========== SHOPS ==========
-- Add as many as you like. Each shop can have:
-- - name: UI title
-- - openRadius: distance to open
-- - payAccount / chargeFirst / chargeSecond: Qbox money accounts
-- - locations: vector3 list (open points)
-- - peds: list of {model, coords=vec4}
-- - categories: map key->label (for menu grouping)
-- - items: per-item config with category, prices, image override
Config.Shops = {
  ingredients = {
    id   = 'ingredients',
    name = 'Supermercado',
    openRadius = 4.0,
    payAccount    = 'cash',
    chargeFirst   = 'cash',
    chargeSecond  = 'bank',
    locations = {
      vec3(1946.48, 3843.27, 32.47),
      vec3(2555.50, 382.20, 108.62),
    },
    peds = {
      { model = `mp_m_shopkeep_01`, coords = vec4(1946.48, 3843.27, 32.47, 176) },
      { model = `a_m_m_farmer_01`,  coords = vec4(2556.50, 381.90, 108.62, 0.0) },
    },
    categories = {
      vegetables = 'Legumes',
      fruits     = 'Frutas',
      dairy      = 'Laticínios',
      grain      = 'Cereais',
      meat       = 'Carne',
      seafood    = 'Marisco',
      sweets     = 'Doces',
      condiments = 'Condimentos',
      nuts       = 'Frutos Secos',
      other      = 'Outros',
    },
    items = {
      -- Vegetables
      snr_tomato      = { label='Tomate',        category='vegetables', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_lettuce     = { label='Alface',        category='vegetables', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_onions      = { label='Cebolas',       category='vegetables', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_chilies     = { label='Malaguetas',    category='vegetables', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_mushrooms   = { label='Cogumelos',     category='vegetables', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_pickles     = { label='Pickles',       category='vegetables', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_potatos     = { label='Batatas',       category='vegetables', capStock=700,  sellAtZero=18, sellAtCap=9 },

      -- Fruits
      snr_starwberry  = { label='Morango',       category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_banana      = { label='Banana',        category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_avocado     = { label='Abacate',       category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_blueberry   = { label='Mirtilo',       category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_freshfruits = { label='Fruta Fresca',  category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_rasberry    = { label='Framboesa',     category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_mango       = { label='Manga',         category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_kiwi        = { label='Kiwi',          category='fruits',     capStock=800,  sellAtZero=22, sellAtCap=8 },

      -- Dairy
      snr_milk        = { label='Leite',         category='dairy',      capStock=600,  sellAtZero=30, sellAtCap=12 },
      snr_yogurt      = { label='Iogurte',       category='dairy',      capStock=900,  sellAtZero=16, sellAtCap=6 },
      snr_eggs        = { label='Ovos',          category='dairy',      capStock=900,  sellAtZero=16, sellAtCap=6 },
      snr_cheese      = { label='Queijo',        category='dairy',      capStock=800,  sellAtZero=22, sellAtCap=8 },

      -- Grains
      snr_riz         = { label='Arroz',         category='grain',      capStock=700,  sellAtZero=18, sellAtCap=9 },
      snr_sandwichbuns= { label='Pães de Sandes',category='grain',      capStock=700,  sellAtZero=18, sellAtCap=9 },
      snr_buns        = { label='Pães de Hambúrguer', category='grain', capStock=700,  sellAtZero=18, sellAtCap=9 },
      snr_noodle      = { label='Massa',         category='grain',      capStock=700,  sellAtZero=18, sellAtCap=9 },
      snr_pizzasbuns  = { label='Pães de Cachorro', category='grain',   capStock=700,  sellAtZero=18, sellAtCap=9 },
      snr_hotdogbuns  = { label='Pães de Pizza', category='grain',      capStock=700,  sellAtZero=18, sellAtCap=9 },

      -- Meat
      snr_meat        = { label='Carne',         category='meat',       capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_chicken     = { label='Frango',        category='meat',       capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_bacon       = { label='Bacon',         category='meat',       capStock=800,  sellAtZero=22, sellAtCap=8 },

      -- Seafood
      snr_fish        = { label='Peixe',         category='seafood',    capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_tonno       = { label='Atum',          category='seafood',    capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_thon        = { label='Atum Pedaços',  category='seafood',    capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_shrimps     = { label='Camarões',      category='seafood',    capStock=800,  sellAtZero=22, sellAtCap=8 },

      -- Sweets
      snr_cookies     = { label='Bolachas',      category='sweets',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_chocchips   = { label='Pepitas de Chocolate', category='sweets', capStock=800, sellAtZero=22, sellAtCap=8 },
      snr_chocolate   = { label='Chocolate',     category='sweets',     capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_candy       = { label='Rebuçados',     category='sweets',     capStock=800,  sellAtZero=22, sellAtCap=8 },

      -- Condiments
      snr_ketchup     = { label='Ketchup',       category='condiments', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_vanille     = { label='Baunilha',      category='condiments', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_coffee      = { label='Café',          category='condiments', capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_suggar      = { label='Açúcar',        category='condiments', capStock=800,  sellAtZero=22, sellAtCap=8 },

      -- Nuts
      snr_nuts        = { label='Amendoins',     category='nuts',       capStock=800,  sellAtZero=22, sellAtCap=8 },
      snr_pistache    = { label='Pistáchio',     category='nuts',       capStock=800,  sellAtZero=22, sellAtCap=8 },

      -- Other
      -- Add anything else that doesn't fit above
    }
  },

  materials = {
    id   = 'materials',
    name = 'Materials Depot',
    openRadius = 4.0,
    payAccount    = 'cash',
    chargeFirst   = 'cash',
    chargeSecond  = 'bank',
    locations = { vec3(1987.39, 3825.13, 32.51) },
    peds = { { model = `s_m_y_construct_02`, coords = vec4(1987.39, 3825.13, 32.51, 117) } },
    categories = {
      raw      = 'Raw',
      refined  = 'Refined',
    },
    items = {
      ring_diamond      = { label='Anel de Diamante',      category='refined', capStock=100, sellAtZero=330, sellAtCap=220 },
      necklace_diamond  = { label='Colar de Diamante',     category='refined', capStock=100, sellAtZero=352, sellAtCap=242 },
      ring_ruby         = { label='Anel de Rubi',          category='refined', capStock=100, sellAtZero=237, sellAtCap=193 },
      ring_emerald      = { label='Anel de Esmeralda',     category='refined', capStock=100, sellAtZero=165, sellAtCap=138 },
      ring_aquamarine   = { label='Anel de Água-marinha',  category='refined', capStock=100, sellAtZero=110, sellAtCap=88 },
      ring_gold         = { label='Anel de Ouro',          category='refined', capStock=100, sellAtZero=88,  sellAtCap=66 },
      aquamarine        = { label='Água-marinha',          category='refined', capStock=100, sellAtZero=83,  sellAtCap=66 },
      diamond           = { label='Diamante',              category='refined', capStock=100, sellAtZero=83,  sellAtCap=66 },
      ruby              = { label='Rubi',                  category='refined', capStock=100, sellAtZero=83,  sellAtCap=66 },
      emerald           = { label='Esmeralda',             category='refined', capStock=100, sellAtZero=83,  sellAtCap=66 },
      earring_gold      = { label='Brinco de Ouro',        category='refined', capStock=100, sellAtZero=77,  sellAtCap=55 },
      necklace_gold     = { label='Colar de Ouro',         category='refined', capStock=100, sellAtZero=99,  sellAtCap=77 },
      ring_silver       = { label='Anel de Prata',         category='refined', capStock=100, sellAtZero=50,  sellAtCap=33 },
      earring_silver    = { label='Brinco de Prata',       category='refined', capStock=100, sellAtZero=44,  sellAtCap=28 },
      necklace_silver   = { label='Colar de Prata',        category='refined', capStock=100, sellAtZero=55,  sellAtCap=39 },
      rubber            = { label='Borracha',              category='raw',     capStock=500, sellAtZero=11,  sellAtCap=6 },
      steel             = { label='Aço',                   category='refined', capStock=500, sellAtZero=15,  sellAtCap=9 },
      aluminium         = { label='Alumínio',              category='refined', capStock=500, sellAtZero=13,  sellAtCap=8 },
      plastic           = { label='Plástico',              category='raw',     capStock=500, sellAtZero=11,  sellAtCap=7 },
      metalscrap        = { label='Sucata de Metal',       category='raw',     capStock=500, sellAtZero=11,  sellAtCap=6 },
      gunpowder         = { label='Pólvora',               category='refined', capStock=300, sellAtZero=18,  sellAtCap=11 },
      kevlar            = { label='Kevlar',                category='refined', capStock=200, sellAtZero=28,  sellAtCap=17 },
      copper            = { label='Cobre',                 category='refined', capStock=500, sellAtZero=15,  sellAtCap=9 },
    }
  },

  electronics = {
    id   = 'electronics',
    name = 'Electronics Exchange',
    openRadius = 4.0,
    payAccount    = 'cash',
    chargeFirst   = 'cash',
    chargeSecond  = 'bank',
    locations = { vec3(1934.98, 3821.06, 32.47) },
    peds = { { model = `ig_ramp_mex`, coords = vec4(1934.98, 3821.06, 32.47, 304) } },
    categories = {
      parts = 'Components',
      devices = 'Devices',
    },
    items = {
      electronics = { label='Partes Eletronicas',     category='parts',   capStock=800,  sellAtZero=30, sellAtCap=18 },
      copper_wire    = { label='Fio de cobre',   category='parts',   capStock=700,  sellAtZero=25, sellAtCap= 15},
    }
  },
}
