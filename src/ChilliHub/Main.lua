--========================================================
-- ChilliHub | Main.lua
-- Orquestrador: monta o Ctx na ordem de dependência,
-- sobe loops/serviços e escolhe a UI (Orion -> Nativa).
--
-- Entrada M (tabela de factories, uma por módulo):
--   Config, Services, Utils, OrionBootstrap, Movement,
--   Interaction, Remotes, World, AntiCheat, Automation,
--   ESP, PlayerMods, OrionUI, NativeUI
-- Retorna o Ctx montado (útil p/ debug no console).
--========================================================

return function(M)
    assert(M and M.Config and M.Services, "[ChilliHub] Main: factories incompletas")

    -- 1) Estado + serviços (sem dependências)
    local Ctx = {}
    Ctx.Config = M.Config
    Ctx.State = M.Config.newState()
    Ctx.Services = M.Services()
    local S = Ctx.Services
    local State = Ctx.State

    -- UI placeholder (Utils.Notify consulta antes do bootstrap)
    Ctx.UI = { mode = function() return "Native" end, lib = function() return nil end }

    -- 2) Utils (precisa de Services + State)
    Ctx.Utils = M.Utils(Ctx)
    local U = Ctx.Utils
    U.bootNotify("Chilli Hub", "Iniciando... carregando UI", 4)

    -- 3) Orion (pode levar segundos — antes dos loops)
    local bootstrap = M.OrionBootstrap(Ctx)
    local uiMode = bootstrap.ensure() -- preenche Ctx.UI de verdade

    -- 4) Domínio (ordem respeita dependências lazy via Ctx)
    Ctx.Movement = M.Movement(Ctx)
    Ctx.Interaction = M.Interaction(Ctx)
    Ctx.Remotes = M.Remotes(Ctx)
    Ctx.World = M.World(Ctx)
    Ctx.AntiCheat = M.AntiCheat(Ctx)
    Ctx.ESP = M.ESP(Ctx)
    Ctx.Automation = M.Automation(Ctx)
    Ctx.PlayerMods = M.PlayerMods(Ctx)

    -- 5) Serviços de fundo (sem UI)
    Ctx.Remotes.Refresh()
    Ctx.PlayerMods.start()
    Ctx.ESP.start()
    Ctx.Automation.startAll()
    Ctx.AntiCheat.BindRespawn()
    task.spawn(function()
        if State.AntiKick then Ctx.AntiCheat.Setup() end
    end)

    -- 6) UI (Orion primeiro, Nativa como fallback)
    Ctx.OrionUI = M.OrionUI(Ctx)
    Ctx.NativeUI = M.NativeUI(Ctx)
    do
        local built = false
        if uiMode == "Orion" then
            built = pcall(function() return Ctx.OrionUI.build() end)
            if not built then
                Ctx.UI.setMode("Native")
                uiMode = "Native"
            end
        end
        if uiMode == "Native" then
            pcall(function() Ctx.NativeUI.build() end)
        end
        print("[ChilliHub] UI ativa: " .. tostring(uiMode)
            .. " | " .. table.concat(bootstrap.DiagLog, " || "))
    end

    getgenv().ChilliHub = Ctx -- debug: getgenv().ChilliHub.State.AutoSteal = true
    return Ctx
end
