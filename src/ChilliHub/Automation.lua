--========================================================
-- ChilliHub | Automation.lua
-- Loops principais: farm/snipe/hatch/treino.
-- Um único ponto de partida: Automation.startAll(Ctx).
--========================================================

return function(Ctx)
    local State = Ctx.State
    local U = Ctx.Utils
    local W = Ctx.World
    local Mv = Ctx.Movement
    local Ix = Ctx.Interaction
    local Rm = Ctx.Remotes

    local A = {}

    -- Espera o boot assentar antes de qualquer ação no mundo.
    -- Evita delta de posição logo no execute (config salva pode
    -- religar AutoSteal e o servidor mede o primeiro delta).
    local function bootGrace()
        local t0 = Ctx.BootTime or os.clock()
        local waitLeft = 10 - (os.clock() - t0)
        if waitLeft > 0 then task.wait(waitLeft) end
    end

    -- Dispara variações do MESMO remote com intervalo.
    -- Rajada FireServer no mesmo tick = assinatura clássica de exploit.
    -- variants: lista de listas de args. Ex: { {"All"}, {1}, {"Hatch"} }
    local function staggered(remote, variants, gap)
        if not remote then return end
        gap = gap or 0.25
        for i, args in ipairs(variants) do
            if i > 1 then task.wait(gap) end
            Rm.SafeFire(remote, table.unpack(args))
        end
    end

    function A.startFarm()
        task.spawn(function()
            bootGrace()
            while true do
                if State.AutoSteal or State.AutoStealAll then
                    local ok = pcall(function()
                        if W.GetCarryingEgg() and State.AutoReturn then
                            local cf = W.GetMyBaseCFrame()
                            if cf then
                                Mv.TweenPathTo(cf + Vector3.new(0, 4, 0))
                                task.wait(0.3)
                                Ix.FirePromptsInRadius(cf.Position, 20)
                            end
                            task.wait(U.HDelay(State.StealDelay))
                        else
                            local eggs = W.FindEggs()
                            if not State.AutoStealAll then
                                local f = {}
                                for _, e in ipairs(eggs) do
                                    if W.PassFilters(e) then table.insert(f, e) end
                                end
                                eggs = f
                            end
                            eggs = W.SortEggs(eggs)
                            local target = eggs[1]
                            if target and target.Position then
                                local hrp = U.HRP()
                                local dist = hrp and (hrp.Position - target.Position).Magnitude or 9999
                                if dist > 10 then
                                    Mv.TweenPathTo(CFrame.new(target.Position + Vector3.new(0, 4, 0)))
                                else
                                    W.TryStealEgg(target)
                                    task.wait(U.HDelay(State.StealDelay))
                                end
                            else
                                task.wait(0.5)
                            end
                        end
                    end)
                    if not ok then task.wait(1) end
                else
                    task.wait(0.25)
                end
                task.wait(0.05)
            end
        end)
    end

    function A.startSnipe()
        task.spawn(function()
            bootGrace()
            while true do
                if State.AutoSnipe then
                    pcall(function()
                        local eggs = W.SortEggs(W.FindEggs())
                        for _, e in ipairs(eggs) do
                            local rs = W.RarityScore(e.Rarity)
                            local lm = string.lower(e.Mutation)
                            if rs >= 5 or lm == "golden" or lm == "rainbow" then
                                if not W.GetCarryingEgg() then
                                    Mv.TweenPathTo(CFrame.new(e.Position + Vector3.new(0, 4, 0)))
                                    W.TryStealEgg(e)
                                    break
                                end
                            end
                        end
                    end)
                    task.wait(0.4)
                else
                    task.wait(0.5)
                end
            end
        end)
    end

    function A.startHatch()
        task.spawn(function()
            bootGrace()
            while true do
                if State.AutoHatch then
                    pcall(function()
                        local hatchR = Rm.Get("hatch", { "hatch", "openegg", "open_egg", "unbox", "eggopen" })
                        local targetEgg = State.HatchEgg
                        if hatchR then
                            if targetEgg == "All" then
                                staggered(hatchR, { { "All" }, { 1 }, { "Hatch" } })
                            else
                                staggered(hatchR, {
                                    { targetEgg },
                                    { targetEgg, 1 },
                                    { { Egg = targetEgg } },
                                })
                            end
                        else
                            local cf = W.GetHatchCFrame()
                            if cf then
                                local hrp = U.HRP()
                                if hrp and (hrp.Position - cf.Position).Magnitude > 12 then
                                    Mv.TweenTo(cf)
                                else
                                    Ix.FirePromptsInRadius(cf.Position, 20)
                                end
                            end
                        end
                        if State.AutoEquipBest then
                            local eq = Rm.Get("equip", { "equipbest", "equip_best", "equip", "bestpet" })
                            if eq then staggered(eq, { { "Best" }, { true } }) end
                        end
                    end)
                    task.wait(U.HDelay(math.clamp(State.HatchDelay, 0.1, 5)))
                else
                    task.wait(0.5)
                end
            end
        end)
    end

    function A.startTrain()
        task.spawn(function()
            bootGrace()
            while true do
                if State.AutoTrain then
                    pcall(function()
                        local trainR = Rm.Get("train", { "train", "treadmill", "speed", "workout", "run" })
                        if trainR then
                            staggered(trainR, { {}, { 1 }, { "Train" } })
                        end
                        local cf = W.GetTreadmillCFrame()
                        if cf then
                            local hrp = U.HRP()
                            if hrp and (hrp.Position - cf.Position).Magnitude > 10 then
                                Mv.TweenTo(cf)
                            else
                                Ix.FirePromptsInRadius(cf.Position, 16)
                                Ix.TouchAllInRadius(cf.Position, 12)
                            end
                        end
                    end)
                    task.wait(0.5)
                else
                    task.wait(0.5)
                end
                if State.AutoUpgradeTreadmill then
                    pcall(function()
                        local up = Rm.Get("upT", { "upgradetreadmill", "treadmillupgrade", "buy treadmill", "treadmill" })
                        if up then staggered(up, { {}, { 1 }, { "Treadmill" } }) end
                        local gen = Rm.Get("upgrade", { "upgrade", "buy", "purchase" })
                        if gen and not up then staggered(gen, { { "Treadmill" }, { "treadmill", 1 } }) end
                    end)
                    task.wait(2)
                end
                if State.AutoUpgradeBase then
                    pcall(function()
                        local gen = Rm.Get("upgradeB", { "upgrade", "buy", "purchase", "base" })
                        if gen then staggered(gen, { { "Base" }, { "base", 1 } }) end
                    end)
                    task.wait(2)
                end
                if State.AutoCollect then
                    pcall(function()
                        local c = Rm.Get("collect",
                            { "collect", "claim", "income", "money", "cash", "reward", "index" })
                        if c then staggered(c, { {}, { "All" }, { "Collect" } }) end
                        local cf = W.GetMyBaseCFrame()
                        if cf then Ix.FirePromptsInRadius(cf.Position, 25) end
                    end)
                    task.wait(U.HDelay(math.clamp(State.CollectDelay, 0.5, 30)))
                end
                task.wait(0.2)
            end
        end)
    end

    function A.startAll()
        A.startFarm()
        A.startSnipe()
        A.startHatch()
        A.startTrain()
    end

    -- Ações rápidas (usadas pelos botões da UI)
    function A.stealBestNow()
        task.spawn(function()
            local eggs = W.SortEggs(W.FindEggs())
            local t = eggs[1]
            if t then
                Mv.TweenTo(CFrame.new(t.Position + Vector3.new(0, 4, 0)))
                W.TryStealEgg(t)
                U.Notify("Steal", t.Name .. " | " .. t.Rarity)
            else
                U.Notify("Steal", "Nenhum ovo encontrado")
            end
        end)
    end

    function A.returnBaseNow()
        task.spawn(function()
            local cf = W.GetMyBaseCFrame()
            if cf then
                Mv.TweenTo(cf + Vector3.new(0, 5, 0))
                Ix.FirePromptsInRadius(cf.Position, 20)
                U.Notify("Base", "Entregue / prompt ativado")
            else
                U.Notify("Base", "Base nao encontrada - use Diagnostico")
            end
        end)
    end

    return A
end
