--========================================================
-- ChilliHub | AntiCheat.lua
-- Duas camadas (independentes, combináveis):
--  A) SetupAntiCheat: namecall hook (Kick + remotes kick/ban),
--     __index spoof opt-in, hook direto no Kick, watchdog,
--     auto-rejoin no disconnect. (lógica do Load.lua §4b)
--  B) HumanoidSwap: troca o Humanoid por um clone com
--     anti-morte (lógica do bypassanticheat.lua, refatorada).
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local U = Ctx.Utils
    local LocalPlayer = S.LocalPlayer

    local AC = {}
    local hooked, hookNC, hookIdx, watchdog, rejoinHooked = false, false, false, false, false

    function AC.Setup(force)
        if hooked and not force then return true end
        local applied = {}

        -- 1) namecall hook: barra Kick + (opcional) remotes suspeitos
        if hookmetamethod and newcclosure and (not hookNC or force) then
            local ok, err = pcall(function()
                local oldNC
                oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                    local m = (getnamecallmethod and getnamecallmethod()) or ""
                    if State.AntiKick and m == "Kick" then
                        return nil
                    end
                    if State.BlockKickRemotes and (m == "FireServer" or m == "InvokeServer") then
                        local n = string.lower(tostring((self and self.Name) or ""))
                        if string.find(n, "kick") or string.find(n, "ban") or string.find(n, "cheat")
                            or string.find(n, "detect") or string.find(n, "anticheat") or string.find(n, "anti_cheat") then
                            warn("[ChilliHub] Remote bloqueado: " .. tostring(self:GetFullName()))
                            return nil
                        end
                    end
                    return oldNC(self, ...)
                end))
                hookNC = true
            end)
            if ok then table.insert(applied, "namecall")
            else warn("[ChilliHub] bypass namecall falhou: " .. tostring(err)) end
        elseif hookNC then
            table.insert(applied, "namecall")
        end

        -- 2) __index spoof opt-in (responde 16/50), com self-test
        if State.SpoofProps and hookmetamethod and newcclosure and (not hookIdx or force) then
            local ok, err = pcall(function()
                local oldIdx
                oldIdx = hookmetamethod(game, "__index", newcclosure(function(self, k)
                    if k == "WalkSpeed" or k == "JumpPower" or k == "JumpHeight" then
                        local okH, isH = pcall(function() return self:IsA("Humanoid") end)
                        if okH and isH then
                            if k == "WalkSpeed" then return 16 end
                            return 50
                        end
                    end
                    return oldIdx(self, k)
                end))
                if oldIdx == nil then error("sem cadeia anterior") end
                if game:GetService("Workspace").Name ~= "Workspace" then error("self-test falhou") end
                hookIdx = true
            end)
            if ok then
                table.insert(applied, "spoof-idx")
            else
                State.SpoofProps = false
                warn("[ChilliHub] spoof desativado (incompativel): " .. tostring(err))
            end
        elseif hookIdx then
            table.insert(applied, "spoof-idx")
        end

        -- 3) hook direto no Kick (fallback sem hookmetamethod)
        if hookfunction and newcclosure then
            pcall(function()
                hookfunction(LocalPlayer.Kick, newcclosure(function(...) return nil end))
                table.insert(applied, "kick-fn")
            end)
        end

        -- 4) watchdog: mantém nossos hooks por cima
        if not watchdog then
            watchdog = true
            task.spawn(function()
                while true do
                    task.wait(120)
                    if State.AntiKick then AC.Setup(true) end
                end
            end)
        end

        -- 5) auto-rejoin se a tela de disconnect aparecer
        if not rejoinHooked then
            rejoinHooked = true
            pcall(function()
                S.GuiService.ErrorMessageChanged:Connect(function(msg)
                    if not State.AutoRejoin then return end
                    if type(msg) == "string" and #msg > 0 then
                        warn("[ChilliHub] Disconnect detectado: " .. msg)
                        U.bootNotify("Chilli Hub", "Kick detectado, voltando ao jogo...", 5)
                        task.wait(4)
                        pcall(function() S.TeleportService:Teleport(S.PLACE_ID, LocalPlayer) end)
                    end
                end)
            end)
        end

        hooked = #applied > 0
        print("[ChilliHub] Bypass aplicado: " .. (#applied > 0 and table.concat(applied, ",") or "SEM SUPORTE no executor"))
        U.Notify("Bypass", #applied > 0
            and ("Ativo via: " .. table.concat(applied, ", "))
            or "Executor sem hook - risco maior de kick", 6)
        return hooked
    end

    --====================================================
    -- B) HumanoidSwap (ex-bypassanticheat.lua)
    -- Troca o Humanoid por clone preservando jump props,
    -- states, Animator, controles e câmera + anti-morte.
    -- GodMode aqui é local ao swap (padrão true, como antes).
    --====================================================
    function AC.HumanoidSwap(opts)
        opts = opts or {}
        local GodMode = (opts.GodMode ~= false)

        local Character = LocalPlayer.Character
        if not Character then return false, "sem character" end
        local OldHumanoid = Character:FindFirstChildOfClass("Humanoid")
        if not OldHumanoid then return false, "sem humanoid" end

        print("[ChilliHub] HumanoidSwap: inicio")

        local SavedJump = {}
        for _, prop in ipairs({ "JumpPower", "JumpHeight", "UseJumpPower" }) do
            pcall(function() SavedJump[prop] = OldHumanoid[prop] end)
        end

        local SavedEval = nil
        pcall(function() SavedEval = OldHumanoid.EvaluateStateMachine end)

        local stateTypes = {
            Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Running,
            Enum.HumanoidStateType.RunningNoPhysics, Enum.HumanoidStateType.Climbing,
            Enum.HumanoidStateType.StrafingNoPhysics, Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Flying,
            Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Dead,
            Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.Physics,
        }
        local SavedStates = {}
        for _, st in ipairs(stateTypes) do
            local ok, en = pcall(function() return OldHumanoid:GetStateEnabled(st) end)
            if ok then SavedStates[st] = en end
        end

        local NewHumanoid = OldHumanoid:Clone()
        if not NewHumanoid then return false, "clone falhou" end
        NewHumanoid.Name = OldHumanoid.Name

        for _, child in ipairs(OldHumanoid:GetChildren()) do
            local dup = NewHumanoid:FindFirstChild(child.Name)
            if dup then pcall(function() dup:Destroy() end) end
            pcall(function() child.Parent = NewHumanoid end)
        end

        OldHumanoid:Destroy()
        task.wait()
        NewHumanoid.Parent = Character
        task.wait()
        if not NewHumanoid.Parent then return false, "novo humanoid removido" end

        local function restoreProps(h)
            pcall(function() h.UseJumpPower = SavedJump.UseJumpPower end)
            pcall(function() h.JumpPower = SavedJump.JumpPower end)
            pcall(function() h.JumpHeight = SavedJump.JumpHeight end)
            pcall(function()
                if SavedEval ~= nil then h.EvaluateStateMachine = SavedEval end
            end)
            for st, en in pairs(SavedStates) do
                pcall(function() h:SetStateEnabled(st, en) end)
            end
        end
        restoreProps(NewHumanoid)

        if not NewHumanoid:FindFirstChildOfClass("Animator") then
            local an = Instance.new("Animator")
            an.Parent = NewHumanoid
        end

        local function restartAnimate()
            local animate = Character:FindFirstChild("Animate")
            if animate then
                pcall(function() animate.Disabled = true end)
                task.wait()
                pcall(function() animate.Disabled = false end)
            end
        end
        restartAnimate()
        task.wait(0.15)

        local function lockHealth()
            if GodMode and NewHumanoid and NewHumanoid.Parent then
                pcall(function()
                    NewHumanoid.MaxHealth = math.huge
                    NewHumanoid.Health = math.huge
                end)
            end
        end
        local function blockDeath()
            if not (NewHumanoid and NewHumanoid.Parent) then return end
            pcall(function() NewHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
            pcall(function() NewHumanoid.BreakJointsOnDeath = false end)
            pcall(function() NewHumanoid.RequiresNeck = false end)
        end
        lockHealth()
        blockDeath()

        NewHumanoid.HealthChanged:Connect(function(hp)
            if GodMode and NewHumanoid.Parent and hp < NewHumanoid.MaxHealth then
                pcall(function() NewHumanoid.Health = NewHumanoid.MaxHealth end)
            end
        end)
        NewHumanoid.Died:Connect(function()
            if GodMode and NewHumanoid.Parent then
                pcall(function() NewHumanoid.Health = NewHumanoid.MaxHealth end)
            end
        end)
        task.spawn(function()
            while task.wait(0.1) do
                if GodMode and NewHumanoid and NewHumanoid.Parent then
                    pcall(function()
                        if NewHumanoid.Health < NewHumanoid.MaxHealth then
                            NewHumanoid.Health = NewHumanoid.MaxHealth
                        end
                        NewHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                    end)
                end
            end
        end)

        local function refreshControls()
            local ps = LocalPlayer:FindFirstChild("PlayerScripts")
            if not ps then return end
            local pm = ps:FindFirstChild("PlayerModule")
            if not pm then return end
            local ok, mod = pcall(require, pm)
            if not (ok and mod) then return end
            local controls = nil
            pcall(function() controls = mod:GetControls() end)
            if not controls then return end
            pcall(function() controls:OnCharacterAdded(Character) end)
            task.wait()
            pcall(function() controls:UpdateActiveControlModuleEnabled() end)
        end
        refreshControls()

        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then cam.CameraSubject = NewHumanoid end
        end)

        task.wait(0.25)
        if not Character.Parent then return false, "character removido" end
        if Character:FindFirstChildOfClass("Humanoid") ~= NewHumanoid then
            return false, "humanoid substituido por outro"
        end
        restoreProps(NewHumanoid)
        lockHealth()
        blockDeath()
        refreshControls()
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then cam.CameraSubject = NewHumanoid end
        end)
        restartAnimate()

        print("[ChilliHub] HumanoidSwap: completo")
        return true
    end

    -- Liga re-hook no respawn + watchdog inicial
    function AC.BindRespawn()
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if State.AntiKick then AC.Setup() end
        end)
    end

    return AC
end
