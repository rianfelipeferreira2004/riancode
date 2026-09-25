--========================================================
-- ChilliHub | UI/Orion.lua
-- Janela OrionLib: Farm / Pets / Treino / Visual /
-- Jogador / Proteção / Diagnóstico. (extraído do Load §9)
-- Uso: require(...Orion)(Ctx).build() -> true/false
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local U = Ctx.Utils

    local O = {}

    function O.build()
        local OrionLib = Ctx.UI and Ctx.UI.lib and Ctx.UI.lib() or nil
        if not OrionLib then return false end

        local Window = OrionLib:MakeWindow({
            Name = "Chilli Hub | Steal an Egg",
            HidePremium = false,
            SaveConfig = true,
            ConfigFolder = "ChilliHub_StealAnEgg",
            IntroEnabled = false,
        })

        local FarmTab = Window:MakeTab({ Name = "Farm", Icon = "rbxassetid://4483362458", PremiumOnly = false })
        local PetsTab = Window:MakeTab({ Name = "Pets", Icon = "rbxassetid://4483362458", PremiumOnly = false })
        local TreinoTab = Window:MakeTab({ Name = "Treino", Icon = "rbxassetid://4483362458", PremiumOnly = false })
        local VisualTab = Window:MakeTab({ Name = "Visual", Icon = "rbxassetid://4483362458", PremiumOnly = false })
        local JogadorTab = Window:MakeTab({ Name = "Jogador", Icon = "rbxassetid://4483362458", PremiumOnly = false })
        local DiagTab = Window:MakeTab({ Name = "Diagnostico", Icon = "rbxassetid://4483362458", PremiumOnly = false })
        local ProtTab = Window:MakeTab({ Name = "Protecao", Icon = "rbxassetid://4483362458", PremiumOnly = false })

        local Blue = Color3.fromRGB(0, 170, 255)
        local W, Mv, Rm, AC, ESP, Auto, PMs =
            Ctx.World, Ctx.Movement, Ctx.Remotes, Ctx.AntiCheat, Ctx.ESP, Ctx.Automation, Ctx.PlayerMods

        --========== FARM ==========
        FarmTab:AddSection({ Name = "Roubo automatico" })
        FarmTab:AddToggle({ Name = "Auto Steal (filtros)", Default = false, Save = true, Flag = "AutoSteal",
            Callback = function(v) State.AutoSteal = v end })
        FarmTab:AddToggle({ Name = "Auto Steal TUDO", Default = false, Save = true, Flag = "AutoStealAll",
            Callback = function(v) State.AutoStealAll = v end })
        FarmTab:AddToggle({ Name = "Auto Voltar pra Base", Default = true, Save = true, Flag = "AutoReturn",
            Callback = function(v) State.AutoReturn = v end })
        FarmTab:AddToggle({ Name = "Snipe Raros (Golden/Rainbow/Secret+)", Default = false, Save = true, Flag = "AutoSnipe",
            Callback = function(v) State.AutoSnipe = v end })
        FarmTab:AddToggle({ Name = "Smart Tween + NoClip", Default = true, Save = true, Flag = "SmartTween",
            Callback = function(v) State.SmartTween = v end })
        FarmTab:AddSlider({ Name = "Tween Speed", Min = 60, Max = 600, Default = 150, Color = Blue,
            Increment = 5, ValueName = "studs/s", Save = true, Flag = "TweenSpeed",
            Callback = function(v) State.TweenSpeed = v end })
        FarmTab:AddSlider({ Name = "Delay roubos", Min = 0.1, Max = 2, Default = 0.35, Color = Blue,
            Increment = 0.05, ValueName = "s", Save = true, Flag = "StealDelay",
            Callback = function(v) State.StealDelay = v end })
        FarmTab:AddSection({ Name = "Filtros (vazio = todas)" })
        FarmTab:AddTextbox({ Name = "Zonas (ex: Cosmic,Secret)", Default = "", TextDisappear = false,
            Save = true, Flag = "FilterZones",
            Callback = function(v) State.FilterZones = U.ParseList(v) end })
        FarmTab:AddTextbox({ Name = "Raridades (ex: Secret,Eternal)", Default = "", TextDisappear = false,
            Save = true, Flag = "FilterRarities",
            Callback = function(v) State.FilterRarities = U.ParseList(v) end })
        FarmTab:AddTextbox({ Name = "Mutacoes (ex: Golden,Rainbow)", Default = "", TextDisappear = false,
            Save = true, Flag = "FilterMutations",
            Callback = function(v) State.FilterMutations = U.ParseList(v) end })
        FarmTab:AddDropdown({ Name = "Prioridade do alvo", Default = "Mais Raro",
            Options = { "Mais Raro", "Mais Proximo", "Mais Distante", "Maior Tamanho" },
            Save = true, Flag = "Priority",
            Callback = function(v) State.Priority = v end })
        FarmTab:AddSection({ Name = "Acoes rapidas" })
        FarmTab:AddButton({ Name = "Roubar melhor ovo AGORA", Callback = function() Auto.stealBestNow() end })
        FarmTab:AddButton({ Name = "Voltar pra Base AGORA", Callback = function() Auto.returnBaseNow() end })

        --========== PETS ==========
        PetsTab:AddSection({ Name = "Chocar ovos" })
        PetsTab:AddToggle({ Name = "Auto Hatch", Default = false, Save = true, Flag = "AutoHatch",
            Callback = function(v) State.AutoHatch = v end })
        PetsTab:AddToggle({ Name = "Auto Equipar Melhor", Default = false, Save = true, Flag = "AutoEquipBest",
            Callback = function(v) State.AutoEquipBest = v end })
        PetsTab:AddSlider({ Name = "Delay Hatch", Min = 0.2, Max = 5, Default = 0.5, Color = Blue,
            Increment = 0.1, ValueName = "s", Save = true, Flag = "HatchDelay",
            Callback = function(v) State.HatchDelay = v end })
        PetsTab:AddTextbox({ Name = "Ovo p/ Hatch (ou All)", Default = "All", TextDisappear = false,
            Save = true, Flag = "HatchEgg",
            Callback = function(v) State.HatchEgg = (v == "" and "All" or v) end })
        PetsTab:AddButton({ Name = "Equipar Melhor AGORA", Callback = function()
            local eq = Rm.Get("equip", { "equipbest", "equip_best", "equip", "bestpet" })
            if eq then Rm.SafeFire(eq, "Best") U.Notify("Pets", "Equip Best disparado")
            else U.Notify("Pets", "Remote nao achado") end
        end })
        PetsTab:AddButton({ Name = "Chocar 1x AGORA", Callback = function()
            local h = Rm.Get("hatch", { "hatch", "openegg", "open_egg", "unbox" })
            if h then
                Rm.SafeFire(h, State.HatchEgg)
                U.Notify("Hatch", "Disparado: " .. tostring(State.HatchEgg))
            else
                local cf = W.GetHatchCFrame()
                if cf then Mv.TweenTo(cf) Ctx.Interaction.FirePromptsInRadius(cf.Position, 20) end
            end
        end })

        --========== TREINO ==========
        TreinoTab:AddSection({ Name = "Speed + Upgrades + Renda" })
        TreinoTab:AddToggle({ Name = "Auto Treinar (treadmill)", Default = false, Save = true, Flag = "AutoTrain",
            Callback = function(v) State.AutoTrain = v end })
        TreinoTab:AddToggle({ Name = "Auto Upgrade Treadmill", Default = false, Save = true, Flag = "AutoUpTread",
            Callback = function(v) State.AutoUpgradeTreadmill = v end })
        TreinoTab:AddToggle({ Name = "Auto Upgrade Base", Default = false, Save = true, Flag = "AutoUpBase",
            Callback = function(v) State.AutoUpgradeBase = v end })
        TreinoTab:AddToggle({ Name = "Auto Coletar Dinheiro", Default = false, Save = true, Flag = "AutoCollect",
            Callback = function(v) State.AutoCollect = v end })
        TreinoTab:AddSlider({ Name = "Delay coleta", Min = 1, Max = 30, Default = 2, Color = Blue,
            Increment = 0.5, ValueName = "s", Save = true, Flag = "CollectDelay",
            Callback = function(v) State.CollectDelay = v end })
        TreinoTab:AddButton({ Name = "Ir pra Treadmill", Callback = function()
            local cf = W.GetTreadmillCFrame()
            if cf then Mv.TweenTo(cf)
            else U.Notify("Treino", "Treadmill nao achada - use Diagnostico") end
        end })

        --========== VISUAL ==========
        VisualTab:AddSection({ Name = "ESP" })
        VisualTab:AddToggle({ Name = "Egg ESP", Default = false, Save = true, Flag = "EggESP",
            Callback = function(v) State.EggESP = v end })
        VisualTab:AddToggle({ Name = "Destacar melhor ovo", Default = true, Save = true, Flag = "HighlightBest",
            Callback = function(v) State.HighlightBest = v end })
        VisualTab:AddToggle({ Name = "Player ESP", Default = false, Save = true, Flag = "PlayerESP",
            Callback = function(v) State.PlayerESP = v end })
        VisualTab:AddSlider({ Name = "Distancia max ESP", Min = 200, Max = 5000, Default = 1500,
            Color = Blue, Increment = 50, ValueName = "studs", Save = true, Flag = "ESPMaxDist",
            Callback = function(v) State.ESPMaxDist = v end })
        VisualTab:AddButton({ Name = "Limpar ESP", Callback = function() ESP.ClearAll() end })

        --========== JOGADOR ==========
        JogadorTab:AddSection({ Name = "Movimento" })
        JogadorTab:AddToggle({ Name = "WalkSpeed custom", Default = false, Save = true, Flag = "WSEnabled",
            Callback = function(v) State.WSEnabled = v end })
        JogadorTab:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 250, Default = 16, Color = Blue,
            Increment = 1, ValueName = "", Save = true, Flag = "WalkSpeed",
            Callback = function(v) State.WalkSpeed = v end })
        JogadorTab:AddToggle({ Name = "Jump custom", Default = false, Save = true, Flag = "JPEnabled",
            Callback = function(v) State.JPEnabled = v end })
        JogadorTab:AddSlider({ Name = "JumpPower", Min = 50, Max = 400, Default = 50, Color = Blue,
            Increment = 1, ValueName = "", Save = true, Flag = "JumpPower",
            Callback = function(v) State.JumpPower = v end })
        JogadorTab:AddToggle({ Name = "NoClip", Default = false, Save = true, Flag = "NoclipT",
            Callback = function(v) Mv.SetNoclip(v) end })
        JogadorTab:AddToggle({ Name = "Godmode (anti-catch)", Default = false, Save = true, Flag = "Godmode",
            Callback = function(v) State.Godmode = v end })
        JogadorTab:AddToggle({ Name = "Anti-AFK", Default = true, Save = true, Flag = "AntiAFK",
            Callback = function(v) State.AntiAFK = v end })
        JogadorTab:AddSection({ Name = "Servidor / Performance" })
        JogadorTab:AddButton({ Name = "Server Hop (servidor vazio)", Callback = function() Mv.ServerHop() end })
        JogadorTab:AddButton({ Name = "Reentrar (Rejoin)", Callback = function()
            S.TeleportService:Teleport(S.PLACE_ID, S.LocalPlayer)
        end })
        JogadorTab:AddButton({ Name = "FPS Boost", Callback = function() PMs.FPSBoost() end })

        --========== PROTECAO ==========
        ProtTab:AddSection({ Name = "Bypass Anti-Cheat" })
        ProtTab:AddParagraph("Como funciona",
            "Anti-Kick via hook + Modo Humano com delays aleatorios. Sem bypass 100% contra checagem server-side: mantenha Tween Speed e WalkSpeed moderados.")
        ProtTab:AddToggle({ Name = "Anti-Kick", Default = true, Save = true, Flag = "AntiKick",
            Callback = function(v) State.AntiKick = v if v then AC.Setup() end end })
        ProtTab:AddToggle({ Name = "Modo Humano (delays aleatorios)", Default = false, Save = true, Flag = "Humanized",
            Callback = function(v) State.Humanized = v end })
        ProtTab:AddToggle({ Name = "Bloquear remotes Kick/Ban (agressivo)", Default = false, Save = true, Flag = "BlockKickRemotes",
            Callback = function(v) State.BlockKickRemotes = v end })
        ProtTab:AddToggle({ Name = "Modo Seguro (tween 150 + jitter)", Default = true, Save = true, Flag = "SafeMode",
            Callback = function(v) State.SafeMode = v end })
        ProtTab:AddToggle({ Name = "Usar Remotes no steal", Default = true, Save = true, Flag = "UseRemotes",
            Callback = function(v) State.UseRemotes = v end })
        ProtTab:AddToggle({ Name = "Pathfinding (anti-TP)", Default = false, Save = true, Flag = "UsePathfind",
            Callback = function(v) State.UsePathfind = v end })
        ProtTab:AddToggle({ Name = "Spoof WalkSpeed (opt-in, teste)", Default = false, Save = true, Flag = "SpoofProps",
            Callback = function(v) State.SpoofProps = v if v then AC.Setup() end end })
        ProtTab:AddToggle({ Name = "Auto-Rejoin no kick", Default = true, Save = true, Flag = "AutoRejoin",
            Callback = function(v) State.AutoRejoin = v end })
        ProtTab:AddButton({ Name = "Reaplicar Bypass agora", Callback = function() AC.Setup(true) end })
        ProtTab:AddButton({ Name = "Humanoid Swap (anti-morte)", Callback = function()
            task.spawn(function()
                local ok, err = AC.HumanoidSwap()
                U.Notify("Swap", ok and "Humanoid trocado" or ("Falhou: " .. tostring(err)))
            end)
        end })

        --========== DIAGNOSTICO ==========
        DiagTab:AddSection({ Name = "Autodescoberta" })
        DiagTab:AddParagraph("Scanners",
            "Se algo nao funcionar, rode os scanners. Fallback fisico (tween + prompt + touch) sobrevive a rename de Remote.")
        DiagTab:AddButton({ Name = "Escanear Remotes", Callback = function()
            local n = Rm.Refresh()
            print("===== [ChilliHub] REMOTES (" .. n .. ") =====")
            for _, r in ipairs(Rm.Cache.list) do print(r.ClassName, r:GetFullName()) end
            print("===== FIM =====")
            U.Notify("Remotes", "Achados: " .. n, 6)
        end })
        DiagTab:AddButton({ Name = "Escanear Mapa", Callback = function()
            local eggs = W.FindEggs()
            local bcf = W.GetMyBaseCFrame()
            local tcf = W.GetTreadmillCFrame()
            U.Notify("Mapa", ("Ovos: %d | Base: %s | Treadmill: %s")
                :format(#eggs, bcf and "OK" or "NAO", tcf and "OK" or "NAO"), 6)
        end })
        DiagTab:AddButton({ Name = "Copiar lista de Remotes", Callback = function()
            Rm.Refresh()
            local t = {}
            for _, r in ipairs(Rm.Cache.list) do
                table.insert(t, r.ClassName .. " | " .. r:GetFullName())
            end
            if setclipboard then
                setclipboard(table.concat(t, "\n"))
                U.Notify("Clipboard", "Lista copiada (" .. #t .. ")")
            end
        end })

        Rm.Refresh()
        U.Notify("Chilli Hub", "Carregado! Config salva em ChilliHub_StealAnEgg.", 5)
        print("[ChilliHub] OrionLib + SaveConfig carregado. PlaceId:", S.PLACE_ID)
        OrionLib:Init()
        return true
    end

    return O
end
