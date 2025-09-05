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
Config.UI.highlightOwned = true
Config.UI.sellPrefillMax = true
Config.UI.sellMaxInstant = false

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
  announce = true,     -- default announce; can be overridden per schedule

  -- Run multiple schedules per day. Each schedule has its own categories+percents.
  schedules = {
    -- 04:00 — full wipe for perishables
    {
      times = { { hour = 4, minute = 0 } },
      announce = true, -- override (optional)
      categories = {
        vegetables = { percent = 1.00, minLeft = 0 },
        fruits     = { percent = 1.00, minLeft = 0 },
        dairy      = { percent = 1.00, minLeft = 0 },
        meat       = { percent = 1.00, minLeft = 0 },
        seafood    = { percent = 1.00, minLeft = 0 },
      }
    },

    -- 16:00 — partial decay for grains/nuts (keep some on shelves)
    {
      times = { { hour = 16, minute = 0 } },
      announce = true,
      categories = {
        grain = { percent = 0.25, minLeft = 10 },
        nuts  = { percent = 0.25, minLeft = 10 },
      }
    },

    -- Example: add more windows if you want
    -- {
    --   times = { { hour = 12, minute = 0 }, { hour = 20, minute = 0 } },
    --   categories = { sweets = { percent = 0.50, minLeft = 0 } }
    -- },
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
      --other      = 'Outros',
    },
    items = {
      -- Vegetables
      snr_tomato      = { label='Tomate',        category='vegetables', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_lettuce     = { label='Alface',        category='vegetables', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_onions      = { label='Cebolas',       category='vegetables', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_chilies     = { label='Malaguetas',    category='vegetables', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_mushrooms   = { label='Cogumelos',     category='vegetables', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_pickles     = { label='Pickles',       category='vegetables', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_potatos     = { label='Batatas',       category='vegetables', capStock=700,  sellAtZero=126, sellAtCap=63 },

      -- Fruits
      snr_starwberry  = { label='Morango',       category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_banana      = { label='Banana',        category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_avocado     = { label='Abacate',       category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_blueberry   = { label='Mirtilo',       category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_freshfruits = { label='Fruta Fresca',  category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_rasberry    = { label='Framboesa',     category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_mango       = { label='Manga',         category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_kiwi        = { label='Kiwi',          category='fruits',     capStock=800,  sellAtZero=154, sellAtCap=56 },

      -- Dairy
      snr_milk        = { label='Leite',         category='dairy',      capStock=600,  sellAtZero=210, sellAtCap=84 },
      snr_yogurt      = { label='Iogurte',       category='dairy',      capStock=900,  sellAtZero=112, sellAtCap=42 },
      snr_eggs        = { label='Ovos',          category='dairy',      capStock=900,  sellAtZero=112, sellAtCap=42 },
      snr_cheese      = { label='Queijo',        category='dairy',      capStock=800,  sellAtZero=154, sellAtCap=56 },

      -- Grains
      snr_riz         = { label='Arroz',              category='grain',       capStock=700,  sellAtZero=126, sellAtCap=63 },
      snr_sandwichbuns= { label='Pães de Sandes',     category='grain',       capStock=700,  sellAtZero=126, sellAtCap=63 },
      snr_buns        = { label='Pães de Hambúrguer', category='grain',       capStock=700,  sellAtZero=126, sellAtCap=63 },
      snr_noodle      = { label='Massa',              category='grain',       capStock=700,  sellAtZero=126, sellAtCap=63 },
      snr_pizzasbuns  = { label='Pães de Cachorro',   category='grain',       capStock=700,  sellAtZero=126, sellAtCap=63 },
      snr_hotdogbuns  = { label='Pães de Pizza',      category='grain',       capStock=700,  sellAtZero=126, sellAtCap=63 },
      snr_tacosbuns   = { label='Pães de Tacos',      category='grain',       capStock=700, sellAtZero=126, sellAtCap=63 },
      snr_tortillabuns= { label='Pães de Tortilha',   category='grain',       capStock=700, sellAtZero=126, sellAtCap=63 },

      -- Meat
      snr_meat        = { label='Carne',         category='meat',       capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_chicken     = { label='Frango',        category='meat',       capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_bacon       = { label='Bacon',         category='meat',       capStock=800,  sellAtZero=154, sellAtCap=56 },

      -- Seafood
      snr_fish        = { label='Peixe',         category='seafood',    capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_tonno       = { label='Atum',          category='seafood',    capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_thon        = { label='Atum Pedaços',  category='seafood',    capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_shrimps     = { label='Camarões',      category='seafood',    capStock=800,  sellAtZero=154, sellAtCap=56 },

      -- Sweets
      snr_cookies     = { label='Bolachas',      category='sweets',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_chocchips   = { label='Pepitas de Chocolate', category='sweets', capStock=800, sellAtZero=154, sellAtCap=56 },
      snr_chocolate   = { label='Chocolate',     category='sweets',     capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_candy       = { label='Rebuçados',     category='sweets',     capStock=800,  sellAtZero=154, sellAtCap=56 },

      -- Condiments
      snr_ketchup     = { label='Ketchup',       category='condiments', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_vanille     = { label='Baunilha',      category='condiments', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_coffee      = { label='Café',          category='condiments', capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_suggar      = { label='Açúcar',        category='condiments', capStock=800,  sellAtZero=154, sellAtCap=56 },

      -- Nuts
      snr_nuts        = { label='Amendoins',     category='nuts',       capStock=800,  sellAtZero=154, sellAtCap=56 },
      snr_pistache    = { label='Pistáchio',     category='nuts',       capStock=800,  sellAtZero=154, sellAtCap=56 },

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
      raw      = 'Crus',
      refined  = 'Refinados',
    },
    items = {
      aquamarine                = { label='Água-marinha',                       category='refined', capStock=100, sellAtZero=112,  sellAtCap=89 },
      emerald                   = { label='Esmeralda',                          category='refined', capStock=100, sellAtZero=136,  sellAtCap=108 },
      ruby                      = { label='Rubi',                               category='refined', capStock=100, sellAtZero=160,  sellAtCap=128 },
      diamond                   = { label='Diamante',                           category='refined', capStock=100, sellAtZero=200,  sellAtCap=160 },
      rubber                    = { label='Borracha',                           category='raw',     capStock=500, sellAtZero=33,   sellAtCap=18 },
      steel                     = { label='Aço',                                category='refined', capStock=500, sellAtZero=45,   sellAtCap=27 },
      aluminium                 = { label='Alumínio',                           category='refined', capStock=500, sellAtZero=39,   sellAtCap=24 },
      plastic                   = { label='Plástico',                           category='raw',     capStock=500, sellAtZero=33,   sellAtCap=21 },
      metalscrap                = { label='Sucata de Metal',                    category='raw',     capStock=500, sellAtZero=33,   sellAtCap=18 },
      gunpowder                 = { label='Pólvora',                            category='refined', capStock=300, sellAtZero=54,   sellAtCap=33 },
      kevlar                    = { label='Kevlar',                             category='refined', capStock=200, sellAtZero=84,   sellAtCap=51 },
      copper                    = { label='Cobre',                              category='raw',     capStock=500, sellAtZero=45,   sellAtCap=27 },
      gold                      = { label='Ouro',                               category='raw',     capStock=200, sellAtZero=100,  sellAtCap=75 },
      silver                    = { label='Prata',                              category='raw',     capStock=300, sellAtZero=60,   sellAtCap=45 },
      ring_silver               = { label='Anel de Prata',                      category='refined', capStock=50, sellAtZero=72,   sellAtCap=54 },
      earring_silver            = { label='Brinco de Prata',                    category='refined', capStock=50, sellAtZero=72,   sellAtCap=54 },
      necklace_silver           = { label='Colar de Prata',                     category='refined', capStock=50, sellAtZero=108,  sellAtCap=81 },
      ring_gold                 = { label='Anel de Ouro',                       category='refined', capStock=30, sellAtZero=120,  sellAtCap=90 },
      earring_gold              = { label='Brinco de Ouro',                     category='refined', capStock=30, sellAtZero=120,  sellAtCap=90 },
      necklace_gold             = { label='Colar de Ouro',                      category='refined', capStock=30, sellAtZero=180,  sellAtCap=135 },
      ring_silver_emerald       = { label='Anel de Prata com Esmeralda',        category='refined', capStock=20, sellAtZero=185,  sellAtCap=146 },
      ring_silver_ruby          = { label='Anel de Prata com Rubi',             category='refined', capStock=20, sellAtZero=205,  sellAtCap=162 },
      ring_silver_aquamarine    = { label='Anel de Prata com Água-marinha',     category='refined', capStock=20, sellAtZero=165,  sellAtCap=130 },
      ring_silver_diamond       = { label='Anel de Prata com Diamante',         category='refined', capStock=20, sellAtZero=245,  sellAtCap=196 },
      earring_silver_emerald    = { label='Brinco de Prata com Esmeralda',      category='refined', capStock=20, sellAtZero=185,  sellAtCap=146 },
      earring_silver_ruby       = { label='Brinco de Prata com Rubi',           category='refined', capStock=20, sellAtZero=205,  sellAtCap=162 },
      earring_silver_aquamarine = { label='Brinco de Prata com Água-marinha',   category='refined', capStock=20, sellAtZero=165,  sellAtCap=130 },
      earring_silver_diamond    = { label='Brinco de Prata com Diamante',       category='refined', capStock=20, sellAtZero=245,  sellAtCap=196 },
      necklace_silver_emerald   = { label='Colar de Prata com Esmeralda',       category='refined', capStock=15, sellAtZero=278,  sellAtCap=219 },
      necklace_silver_ruby      = { label='Colar de Prata com Rubi',            category='refined', capStock=15, sellAtZero=308,  sellAtCap=243 },
      necklace_silver_aquamarine= { label='Colar de Prata com Água-marinha',    category='refined', capStock=15, sellAtZero=248,  sellAtCap=196 },
      necklace_silver_diamond   = { label='Colar de Prata com Diamante',        category='refined', capStock=15, sellAtZero=368,  sellAtCap=294 },
      ring_gold_emerald         = { label='Anel de Ouro com Esmeralda',         category='refined', capStock=10, sellAtZero=235,  sellAtCap=185 },
      ring_gold_ruby            = { label='Anel de Ouro com Rubi',              category='refined', capStock=10, sellAtZero=255,  sellAtCap=202 },
      ring_gold_aquamarine      = { label='Anel de Ouro com Água-marinha',      category='refined', capStock=10, sellAtZero=215,  sellAtCap=171 },
      ring_gold_diamond         = { label='Anel de Ouro com Diamante',          category='refined', capStock=10, sellAtZero=295,  sellAtCap=236 },
      earring_gold_emerald      = { label='Brinco de Ouro com Esmeralda',       category='refined', capStock=10, sellAtZero=235,  sellAtCap=185 },
      earring_gold_ruby         = { label='Brinco de Ouro com Rubi',            category='refined', capStock=10, sellAtZero=255,  sellAtCap=202 },
      earring_gold_aquamarine   = { label='Brinco de Ouro com Água-marinha',    category='refined', capStock=10, sellAtZero=215,  sellAtCap=171 },
      earring_gold_diamond      = { label='Brinco de Ouro com Diamante',        category='refined', capStock=10, sellAtZero=295,  sellAtCap=236 },
      necklace_gold_emerald     = { label='Colar de Ouro com Esmeralda',        category='refined', capStock=8, sellAtZero=353,  sellAtCap=278 },
      necklace_gold_ruby        = { label='Colar de Ouro com Rubi',             category='refined', capStock=8, sellAtZero=383,  sellAtCap=302 },
      necklace_gold_aquamarine  = { label='Colar de Ouro com Água-marinha',     category='refined', capStock=8, sellAtZero=323,  sellAtCap=255 },
      necklace_gold_diamond     = { label='Colar de Ouro com Diamante',         category='refined', capStock=8, sellAtZero=443,  sellAtCap=354 },
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
      parts = 'Componentes',
      devices = 'Dispositivos',
      tools = 'Ferramentas',
    },
    items = {
      electronics = { label='Partes Eletronicas',     category='parts',   capStock=800,  sellAtZero=210, sellAtCap=126 },
      copper_wire    = { label='Fio de cobre',   category='parts',   capStock=700,  sellAtZero=175, sellAtCap= 105 },
      radio    = { label='Radio',   category='devices',   capStock=700,  sellAtZero=175, sellAtCap= 105 },
      burner_phone    = { label='Televovél Descartável',   category='devices',   capStock=700,  sellAtZero=175, sellAtCap= 105 },
      phone    = { label='Telemovél',   category='devices',   capStock=700,  sellAtZero=175, sellAtCap= 105 },
    }
  },

  --[[ drugshop = {
    id   = 'drugshop',
    name = 'Loja de Droguinhas',
    openRadius = 4.0,
    payAccount    = 'cash',
    chargeFirst   = 'cash',
    chargeSecond  = 'bank',
    locations = { vec3(1132.50, -990.83, 46.11) },
    peds = { { model = `a_m_m_salton_03`, coords = vec4(1132.50, -990.83, 46.11, 281) } },
    categories = {
      seeds = 'Sementes',
      products = 'Produtos',
      tools2 = 'Ferramentas',
      drogas = 'Drogas',
    },
    items = {
      -- Seeds
      weed_seed        = { label='Semente de Marijuana', category='seeds',    capStock=200,  sellAtZero=2500, sellAtCap=1500 },
      coke_seed        = { label='Semente de Coca',      category='seeds',    capStock=100,  sellAtZero=4000, sellAtCap=2500 },
      poppy_seeds      = { label='Sementes de Papoula',  category='seeds',    capStock=80,   sellAtZero=5000, sellAtCap=3500 },

      -- Products (precursors, reagents, consumables)
      ammonia          = { label='Amónia',               category='products', capStock=400,  sellAtZero=1250, sellAtCap=600 },
      sodium_benzoate  = { label='Benzoato de Sódio',    category='products', capStock=300,  sellAtZero=1500, sellAtCap=750 },
      safrole_oil      = { label='Óleo de Safrol',       category='products', capStock=100,  sellAtZero=3500, sellAtCap=2000 },
      npp_chemical     = { label='NPP Químico',          category='products', capStock=80,   sellAtZero=4500, sellAtCap=3000 },
      ergot_fungus     = { label='Fungo Ergot',          category='products', capStock=60,   sellAtZero=6000, sellAtCap=4000 },
      baking_soda      = { label='Bicarbonato de Sódio', category='products', capStock=500,  sellAtZero=400,  sellAtCap=200 },
      fertilizer       = { label='Fertilizante',         category='products', capStock=500,  sellAtZero=500,  sellAtCap=250 },
      art_papers       = { label='Papel de Seda',        category='products', capStock=600,  sellAtZero=300,  sellAtCap=150 },
      weed_papers      = { label='Papel de Marijuana',   category='products', capStock=400,  sellAtZero=600,  sellAtCap=300 },
      plastic_bag      = { label='Saco Plástico',        category='products', capStock=800,  sellAtZero=150,  sellAtCap=50 },

      -- Finished drugs
      meth             = { label='Metanfetamina',        category='drogas',   capStock=60,   sellAtZero=12500, sellAtCap=9000 },
      coke_brick       = { label='Tijolo de Cocaína',    category='drogas',   capStock=30,   sellAtZero=20000, sellAtCap=15000 },

      -- Tools
      trowel           = { label='Pá Pequena',           category='tools2',   capStock=100,  sellAtZero=5000, sellAtCap=2500 },
      syringe          = { label='Seringa',              category='tools2',   capStock=200,  sellAtZero=2000, sellAtCap=1000 },
      weed_pot         = { label='Vaso de Plantação',    category='tools2',   capStock=150,  sellAtZero=3000, sellAtCap=1500 },
      water_can        = { label='Regador',              category='tools2',   capStock=100,  sellAtZero=2250, sellAtCap=1125 },
      light1           = { label='Luz de Cultivo (Fraca)', category='tools2', capStock=60,   sellAtZero=37500, sellAtCap=25000 },
      light2           = { label='Luz de Cultivo (Forte)', category='tools2', capStock=30,   sellAtZero=75000, sellAtCap=50000 },
    }
  }, ]]
}
