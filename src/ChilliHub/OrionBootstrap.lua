--========================================================
-- ChilliHub | OrionBootstrap.lua
-- Baixa/compila a OrionLib com fallback para UI nativa.
-- Preenche Ctx.UI = { mode(), lib(), diag() }.
--========================================================

return function(Ctx)
    local B = {}
    B.DiagLog = {}

    local function tryFetch(url)
        local ok, res = pcall(game.HttpGet, game, url)
        if not ok then return nil, "http-FAIL" end
        if type(res) ~= "string" or #res < 10000 then
            return nil, "http-curto(" .. tostring(res and #res) .. "b)"
        end
        return res, "http-ok(" .. #res .. "b)"
    end

    local function tryChunk(res, name)
        local fn, cerr = loadstring(res, name)
        if not fn then
            return nil, "compile-FAIL: " .. string.sub(tostring(cerr), 1, 100)
        end
        local ok, lib = pcall(fn)
        if ok and lib then return lib, "OK" end
        return nil, "run-FAIL: " .. string.sub(tostring(lib), 1, 110)
    end

    function B.ensure()
        local mode, lib = "Native", nil
        local urls = {
            { "gh", "https://raw.githubusercontent.com/jensonhirst/Orion/main/source" },
            { "jsdelivr", "https://cdn.jsdelivr.net/gh/jensonhirst/Orion@main/source" },
        }
        for _, pair in ipairs(urls) do
            local tag, u = pair[1], pair[2]
            local res, st = tryFetch(u)
            if not res then
                table.insert(B.DiagLog, "orion/" .. tag .. " " .. st)
            else
                local got, st2 = tryChunk(res, "Orion")
                table.insert(B.DiagLog, "orion/" .. tag .. " " .. st .. " " .. st2)
                if got then lib, mode = got, "Orion" break end
            end
        end

        local full = "ChilliHub diag | " .. table.concat(B.DiagLog, " || ")
        print("[ChilliHub] " .. full)

        Ctx.UI = {
            mode = function() return mode end,
            setMode = function(m) mode = m end,
            lib = function() return lib end,
            diag = function() return full end,
            log = B.DiagLog,
        }

        if mode == "Native" then
            pcall(function() if setclipboard then setclipboard(full) end end)
            Ctx.Utils.bootNotify("Chilli Hub", "Orion falhou: usando UI NATIVA (diag copiado).", 8)
        end
        return mode, lib
    end

    return B
end
