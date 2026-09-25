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
    Ctx.BootTime = os.clock()
    -- Escape hatch p/ diagnóstico: execute com
    --   getgenv().CHILLI_SAFEBOOT = true
    -- antes do loadstring e NADA automático liga
    -- (sem hooks, sem loops). Tudo manual pela UI.
    Ctx.SafeBoot = getgenv and getgenv().CHILLI_SAFEBOOT == true or false
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

    -- 3) UI library: Orion é opt-in (State.UseOrion).
    -- Motivo: "Orion" é nome famoso e entra em blacklist de AC
    -- client-side; YokuHub usa UI própria pelo mesmo motivo.
    -- Sem Orion: zero HttpGet externo, zero GUI conhecida, boot rápido.
    local bootstrap = M.OrionBootstrap(Ctx)
    local uiMode = "Native"
    if State.UseOrion then
        uiMode = bootstrap.ensure() -- preenche Ctx.UI de verdade
    else
        Ctx.UI = {
            mode = function() return "Native" end,
            setMode = function() end,
            lib = function() return nil end,
            diag = function() return "orion desativado (UseOrion=false)" end,
            log = {},
        }
    end

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
    if Ctx.SafeBoot then
        U.Notify("Chilli Hub", "SAFEBOOT: automacao e bypass DESLIGADOS. Ligue manual.", 8)
        print("[ChilliHub] SAFEBOOT ativo - nada automatico foi iniciado")
    else
        Ctx.Automation.startAll()
        task.spawn(function()
            if State.AntiKick then Ctx.AntiCheat.Setup() end
        end)
    end
    Ctx.AntiCheat.BindRespawn()

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
            .. " | " .. tostring(Ctx.UI.diag and Ctx.UI.diag() or ""))
    end

    getgenv().ChilliHub = Ctx -- debug: getgenv().ChilliHub.State.AutoSteal = true
    return Ctx
end
