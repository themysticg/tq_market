Locales = Locales or {}

local function getLocaleTable()
  local lang = (Config and Config.Locale) or 'en'
  return Locales[lang] or Locales['en'] or {}
end

--- Translate
--- @param key string
--- @param ... any  -- optional format args
function _T(key, ...)
  local tbl = getLocaleTable()
  local str = tbl[key] or key
  if select('#', ...) > 0 then
    return string.format(str, ...)
  end
  return str
end
