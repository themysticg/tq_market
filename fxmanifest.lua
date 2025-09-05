fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'tq_market_lib'
author 'Mystic + ChatGPT'
version '1.3.1'
description 'Multi-shop dynamic market (ox_lib UI + ox_inventory backend) with locales and pluggable interaction'

shared_scripts {
  '@ox_lib/init.lua',
  --'@lation_ui/init.lua',
  'shared/locale.lua',        -- NEW
  'locales/en.lua',           -- NEW
  'locales/pt.lua',           -- NEW (pt-PT sample)
  'config.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',   -- if mysql
  'server/main.lua',
}

client_scripts {
  'client/main.lua',
}

--[[ files {
  'web/images/*.png',
  'web/images/*.jpg',
  'web/images/*.webp',
} ]]

dependencies { 'ox_lib', 'ox_inventory', 'qbx_core' }
