-- =========================
-- One-time Update Checker
-- =========================

local RESOURCE = GetCurrentResourceName()

local function parseSemver(v)
    -- Returns major, minor, patch as numbers (0 if missing)
    local a, b, c = tostring(v or ''):match('^(%d+)%.(%d+)%.(%d+)$')
    return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end

local function isNewer(remote, localv)
    local ra, rb, rc = parseSemver(remote)
    local la, lb, lc = parseSemver(localv)
    if ra ~= la then return ra > la end
    if rb ~= lb then return rb > lb end
    return rc > lc
end

local function checkForUpdateOnce()
    if not (Config.UpdateCheck and Config.UpdateCheck.enabled and Config.UpdateCheck.url) then
        return
    end

    local localVersion = GetResourceMetadata(RESOURCE, 'version', 0) or '0.0.0'
    PerformHttpRequest(Config.UpdateCheck.url, function(code, body, headers)
        if code ~= 200 or not body then
            print(('[%s] Update check failed (HTTP %s).'):format(RESOURCE, tostring(code)))
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' or not data.version then
            print(('[%s] Update check failed: invalid JSON.'):format(RESOURCE))
            return
        end

        local remote = tostring(data.version)
        if isNewer(remote, localVersion) then
            print(('\n[%s] Update available: %s → %s'):format(RESOURCE, localVersion, remote))
            if data.changelog then
                print(('[%s] Changelog: %s'):format(RESOURCE, data.changelog))
            end
        else
            print(('[%s] You are up to date (%s).'):format(RESOURCE, localVersion))
        end
    end, 'GET')
end

-- Run exactly once when THIS resource starts
AddEventHandler('onResourceStart', function(resName)
    if resName ~= RESOURCE then return end
    CreateThread(function()
        Wait(1500)           -- small delay to let everything finish booting
        checkForUpdateOnce()
    end)
end)
