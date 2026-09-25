--========================================================
-- ChilliHub | Services.lua
-- Aquisição única de serviços (com cloneref quando houver).
-- Retorna factory: local S = require(...Services)()
--========================================================

return function()
    local cloneref = (cloneref or clonereference or function(i) return i end)

    local S = {}
    S.cloneref = cloneref
    S.Players = cloneref(game:GetService("Players"))
    S.ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
    S.Workspace = cloneref(game:GetService("Workspace"))
    S.RunService = cloneref(game:GetService("RunService"))
    S.TeleportService = cloneref(game:GetService("TeleportService"))
    S.HttpService = cloneref(game:GetService("HttpService"))
    S.UserInputService = cloneref(game:GetService("UserInputService"))
    S.VirtualUser = cloneref(game:GetService("VirtualUser"))
    S.Lighting = cloneref(game:GetService("Lighting"))
    S.PathfindingService = cloneref(game:GetService("PathfindingService"))
    S.GuiService = cloneref(game:GetService("GuiService"))
    S.TweenService = cloneref(game:GetService("TweenService"))
    S.CoreGui = nil
    pcall(function()
        S.CoreGui = cloneref(game:GetService("CoreGui"))
    end)

    S.LocalPlayer = S.Players.LocalPlayer
    S.PLACE_ID = game.PlaceId
    S.JOB_ID = game.JobId

    return S
end
