Locales = Locales or {}

local function getLocaleTable()
    local lang = (Config and Config.Locale) or 'en'
    return Locales[lang] or Locales['en'] or {}
end

--- Translate with safe formatting
--- @param key string
--- @param ... any  -- optional format args
function _T(key, ...)
    local tbl = getLocaleTable()
    local str = tbl[key] or key
    local argc = select('#', ...)

    -- Only try formatting if the string contains % and we have args
    if str:find("%%") and argc > 0 then
        local ok, out = pcall(string.format, str, ...)
        if ok then
            return out
        else
            -- Fallback: don’t crash; append args for visibility
            -- (and log once so you can fix the offending locale later)
            print(('[tq_market] WARN: locale format mismatch for key "%s" -> "%s"'):format(tostring(key), tostring(str)))
            local parts = {}
            for i = 1, argc do parts[#parts+1] = tostring(select(i, ...)) end
            return str .. ' ' .. table.concat(parts, ' ')
        end
    end

    return str
end
