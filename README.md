# tq\_market — Player-Driven Dynamic Market (ox\_lib UI • Qbox • ox\_inventory)

> **Author’s Note**
> This is the first script I’ve ever made. All the ideas, design decisions, and gameplay vision are mine. AI was used to help structure code, tighten logic, and correct small mistakes — not to invent features. 🙏

---

## ✨ What it does

`tq_market` creates **player-driven shops** with **live supply & demand pricing**. Players **sell** items to NPC shops (stock goes up → price goes down) and **buy** items back (stock goes down → price goes up). It supports **multiple shops**, **categories** (Ingredients, Materials, Electronics, etc.), **nightly decay/spoilage**, **scheduled sales events** with global announcements, and **trend arrows** showing price movement over time.

* UI built with **ox\_lib** (no ox\_inventory shop UI).
* Items are still stored/managed by **ox\_inventory** (add/remove/check).
* Money handled by **Qbox (qbx\_core)** accounts.
* Persistence via **MySQL** or **JSON**.
* Localized strings (**en**, **pt-PT**) and **pluggable interaction** (ox\_target, ox\_lib proximity/TextUI, or your own).

---

## 🧩 Features

* **Linear supply ↔ demand** pricing (smooth, per-unit marginal math — no chunking exploits).
* **Multi-shop**: custom ped(s), map locations, categories, money accounts per shop.
* **Nightly decay/spoilage** per category (e.g., produce loses 15% at 04:00).
* **Sales events** (weekly or fixed time windows) with discounts on **buy** price and server-wide announcements.
* **Trend arrows** (↑/↓/→) for **1h** and **24h** price deltas in the menu.
* **Images**: use ox\_inventory item icons, or ship your own PNG/JPG/WEBP per item.
* **Locale system**: all UI/notifications come from `locales/`.
* **Interaction adapter**: choose **ox\_target**, **ox\_lib** TextUI, or **custom** and call an export/event yourself.
* **Anti-flip**: buy price is always ≥ sell price + spread (`Config.MinSpread`).

---

## 🧱 Requirements

* \[ox\_lib]
* \[ox\_inventory]
* \[qbx\_core] (Qbox)
* \[oxmysql] (only if you use MySQL persistence)
* (Optional) \[ox\_target] if you pick target-based interaction

> Tested on **fxmanifest `cerulean`**, Lua 5.4.

---

## 📁 File Tree (trimmed)

```
tq_market/
  ├─ fxmanifest.lua
  ├─ config.lua
  ├─ shared/
  │   └─ locale.lua
  ├─ locales/
  │   ├─ en.lua
  │   └─ pt.lua
  ├─ server/
  │   └─ main.lua
  ├─ client/
  │   └─ main.lua
  └─ web/
      └─ images/   # optional custom item images (png/jpg/webp)
```

---

## ⚙️ Install

1. Drop `tq_market` into `resources/`.
2. If using MySQL:

   ```sql
   CREATE TABLE IF NOT EXISTS `tq_market_stock` (
     `shop`  varchar(64) NOT NULL,
     `item`  varchar(64) NOT NULL,
     `stock` int NOT NULL DEFAULT 0,
     PRIMARY KEY (`shop`,`item`)
   );
   ```
3. Ensure start order (after qbx\_core, ox\_lib, ox\_inventory, oxmysql):

   ```
   ensure qbx_core
   ensure ox_lib
   ensure ox_inventory
   ensure oxmysql
   ensure tq_market
   ```
4. Make sure every item you sell/buy exists in **ox\_inventory** items config (labels, weights, etc.).
5. (Optional) Put custom item images in `web/images/` and reference them in `Config.Shops[...].items[name].image`.

---

## 🔧 Configuration (high-level)

Open `config.lua`. Key sections:

### Locale & Interaction

```lua
Config.Locale = 'en'  -- or 'pt'

Config.Interaction = {
  mode = 'ox_lib',    -- 'ox_target' | 'ox_lib' | 'custom'
  openRadiusDefault = 4.0,
  targetIcon = 'fa-solid fa-shop',
  spawnPedsInCustom = false, -- if 'custom', spawn peds or not
}
```

### Images & Persistence

```lua
Config.Images = { useOxInventoryImages = true }   -- uses nui://ox_inventory/web/images/<item>.png
Config.Persistence = {
  mode = 'mysql',           -- 'mysql' or 'json'
  table = 'tq_market_stock',
  jsonFile = 'data/stock.json'
}
```

### Pricing Guardrails

```lua
Config.Markup    = 0.25     -- buy = ceil(sell * (1 + Markup))
Config.MinSpread = 1        -- buy >= sell + MinSpread (anti-flip)
```

### Shops (example)

```lua
Config.Shops = {
  ingredients = {
    id='ingredients',
    name='Ingredients Market',
    openRadius=4.0,
    payAccount='cash',       -- SELL payout account
    chargeFirst='cash',      -- BUY charge order: cash → bank
    chargeSecond='bank',
    locations = { vec3(373.80,325.90,103.60) },     -- open points
    peds = { { model=`mp_m_shopkeep_01`, coords=vec4(372.90,326.50,103.56,255.0) } },
    categories = { produce='Produce', dairy='Dairy' },
    items = {
      tomato = { label='Tomato', category='produce', capStock=1000, sellAtZero=25, sellAtCap=7, image='tomato.png' },
      milk   = { label='Milk',   category='dairy',   capStock=600,  sellAtZero=30, sellAtCap=12 },
    }
  },
  -- materials, electronics, etc...
}
```

> **Linear pricing** per item:
> `sell(stock) = lerp(sellAtZero → sellAtCap over 0..capStock)`
> `buy(now) = ceil( sell(now) * (1 + Markup) )`, then forced to `≥ sell + MinSpread`.

### Nightly Decay / Spoilage

```lua
Config.Decay = {
  enabled = true,
  hour = 4, minute = 0,  -- server local time
  announce = true,
  categories = {
    produce = { percent = 0.15, minLeft = 0 },
    dairy   = { percent = 0.10, minLeft = 0 },
  }
}
```

### Sales Events (weekly or fixed)

```lua
Config.Sales = {
  { type='weekly', shop='ingredients', category='produce',
    discount=0.20, dow={6}, hour=18, minute=0, durationMin=120,
    title='Weekend Produce Rush', announce=true },

  -- { type='fixed', shop='electronics', category='devices',
  --   discount=0.15, startISO='2025-08-20T18:00:00', endISO='2025-08-20T20:00:00',
  --   title='Back-to-school Sale', announce=true },
}
```

> Discounts apply to **buy** price only and still respect **MinSpread**.

### Trends (price deltas & snapshots)

```lua
Config.Trend = {
  snapshotEverySec = 300,  -- take a snapshot every 5 minutes
  lookback1h  = 3600,
  lookback24h = 86400,
  persist = false,                   -- if true, writes to data/history.json
  persistFile = 'data/history.json'
}
```

---

## 🎮 How to use (in-game)

* Walk up to a shop ped or location and press **E** (or use target if configured).
* Pick a **category**, choose an **item**, then **Buy** or **Sell**.
* The menu shows **current stock**, **prices**, **sale badge** (if any), and **trend arrows**:

  * `↑` price increased vs lookback window
  * `↓` price decreased
  * `→` no change

**Command (testing):**

```
/market      -- opens the nearest shop if you’re within range
```

---

## 🔌 API (exports & events)

**Open a shop from another resource (your custom interaction):**

```lua
-- Event
TriggerEvent('tq_market:open', 'ingredients')

-- Export
exports['tq_market']:OpenMarket('ingredients')
```

**Server events (client → server):**

```lua
-- Buy from a shop
TriggerServerEvent('tq_market:buy',  shopId, itemName, amount)

-- Sell to a shop
TriggerServerEvent('tq_market:sell', shopId, itemName, amount)
```

**Callback (client → server via ox\_lib):**

```lua
local catalog = lib.callback.await('tq_market:getCatalog', false, shopId)
-- returns { shopId, shopName, categories, items = [...] }
```

---

## 🖼️ Images

* Default: `nui://ox_inventory/web/images/<item>.png` (toggle via `Config.Images.useOxInventoryImages`).
* Custom: put files in `web/images/` and set `image='filename.ext'` per item.
* Supported: `.png`, `.jpg`, `.webp`.

---

## 🌍 Localization

All strings live in `locales/`. Switch language via:

```lua
Config.Locale = 'en'  -- 'pt' included as pt-PT
```

Add new languages by creating `locales/<lang>.lua` and registering `Locales['<lang>'] = { ... }`.

---

## 🛡️ Anti-Exploit Notes

* **Marginal pricing:** large buys/sells are summed **per unit**, so players can’t “chunk” orders to cheat the curve.
* **MinSpread:** `buy >= sell + MinSpread` ensures there’s no instant arbitrage.
* All prices recompute after every transaction and refresh the UI immediately.

---

## 🧪 Troubleshooting

* **“No market nearby.”** Your ped/locations might be off; increase `openRadius` or fix coords/floors.
* **Images not showing.** Check the image path. If using ox\_inventory icons, ensure the item name matches the filename.
* **“Item not sold/bought here.”** Add it to the shop’s `items` list and ensure it exists in ox\_inventory.
* **MySQL not saving.** Verify `oxmysql` is running and the table name in `Config.Persistence.table` matches the SQL.
* **Prices feel too volatile.** Increase `capStock` or reduce decay percentages. For slower movement, raise snapshot interval or ignore trends.

---

## 🗺️ Roadmap (nice-to-haves)

* Player-run shop ownership & commissions.
* City treasury tax / government funds integration.
* Delivery/trucking jobs that inject stock (and pay wages).
* Per-player purchase limits on rare items.

---

## 🙌 Credits

* **Concept, design, and code ownership:** me. and i got ideas from @FraserChambers
* **Assistance:** AI was used to help with refactors, docs, and small bug fixes.

> If you use this in your own servers and like it, star the repo and drop feedback. I’m always down to iterate. 💚

---

## 📜 License

tq_market Non-Commercial License v1.0
Copyright (c) 2025 Jose Garrido (TheMysticG). All rights reserved.

Permission is granted to use and modify this software on your own FiveM/RedM servers and to create private forks for the purpose of contributing fixes or improvements back to the original repository.

Restrictions:
1) You may NOT sell, rent, sublicense, escrow, repackage, or otherwise monetize this software or any derivative, whether alone or as part of a bundle (including Tebex or similar storefronts).
2) You may NOT publicly redistribute this software or derivatives. Sharing must be done by linking to the original repository.
3) You may NOT remove or alter copyright, attribution, or this license text. Rebranding or claiming authorship is prohibited.
4) Distribution of compiled/obfuscated/escrowed copies is prohibited.

Commercial servers:
Running this software on a server that accepts donations or sells in-game perks is permitted, provided you do not charge for this software itself and you comply with CFX/CFX.re terms.

Attribution:
Keep the copyright and a link to the original repository in the README and resource manifest.

Termination:
Any breach of these terms terminates this license automatically. Upon termination you must cease all use and remove the software from your servers.

Warranty:
THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND. THE AUTHOR IS NOT LIABLE FOR ANY DAMAGES OR CLAIMS ARISING FROM USE OF THE SOFTWARE.
