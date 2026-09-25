--========================================================
-- ChilliHub | Utils.lua
-- Helpers puros de personagem + notificação + delays.
-- Uso: local Utils = require(...Utils)(Ctx)
-- Ctx esperado: { Services, State, UI = { mode(), lib() } }
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local LocalPlayer = S.LocalPlayer

    local U = {}

    function U.bootNotify(title, text, dur)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = tostring(title),
                Text = tostring(text),
                Duration = dur or 6,
            })
        end)
    end

    -- Roteia para Orion quando ativo, senão StarterGui
    function U.Notify(title, content, dur)
        dur = dur or 4
        local mode = Ctx.UI and Ctx.UI.mode and Ctx.UI.mode() or "Native"
        local lib = Ctx.UI and Ctx.UI.lib and Ctx.UI.lib() or nil
        if mode == "Orion" and lib then
            pcall(function()
                lib:MakeNotification({
                    Name = tostring(title),
                    Content = tostring(content),
                    Image = "rbxassetid://4483362458",
                    Time = dur,
                })
            end)
        else
            U.bootNotify(title, content, dur)
        end
    end

    function U.HRP()
        local c = LocalPlayer.Character
        if c then return c:FindFirstChild("HumanoidRootPart") end
        return nil
    end

    function U.Hum()
        local c = LocalPlayer.Character
        if c then return c:FindFirstChildOfClass("Humanoid") end
        return nil
    end

    -- Delay com jitter quando Modo Humano está ligado
    function U.HDelay(base)
        if State.Humanized and type(base) == "number" then
            return base * (0.7 + math.random() * 0.6)
        end
        return base
    end

    function U.ParseList(s)
        local out = {}
        if type(s) ~= "string" then return out end
        for part in string.gmatch(s, "([^,]+)") do
            part = string.match(part, "^%s*(.-)%s*$")
            if part ~= "" then table.insert(out, part) end
        end
        return out
    end

    function U.clampNum(v, min, max, fallback)
        v = tonumber(v)
        if not v then return fallback end
        return math.clamp(v, min, max)
    end

    return U
end
