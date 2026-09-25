--========================================================
-- ChilliHub | PlayerMods.lua
-- Modificadores do personagem local: WalkSpeed/Jump,
-- Godmode, Anti-AFK e FPS Boost.
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local U = Ctx.Utils

    local P = {}

    function P.bindAntiAFK()
        S.LocalPlayer.Idled:Connect(function()
            if State.AntiAFK then
                pcall(function()
                    S.VirtualUser:CaptureController()
                    S.VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end)
    end

    function P.startStatLoop()
        task.spawn(function()
            while true do
                pcall(function()
                    local h = U.Hum()
                    if h then
                        if State.WSEnabled then h.WalkSpeed = State.WalkSpeed end
                        if State.JPEnabled then
                            h.JumpPower = State.JumpPower
                            h.UseJumpPower = true
                        end
                        if State.Godmode then
                            if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                        end
                    end
                end)
                task.wait(0.3)
            end
        end)
    end

    function P.FPSBoost()
        pcall(function()
            S.Lighting.GlobalShadows = false
            S.Lighting.FogEnd = 1e9
            for _, v in ipairs(S.Lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("Atmosphere") then v.Enabled = false end
            end
            for _, o in ipairs(S.Workspace:GetDescendants()) do
                if o:IsA("ParticleEmitter") or o:IsA("Trail") then o.Enabled = false end
            end
            U.Notify("FPS", "Boost aplicado")
        end)
    end

    function P.start()
        P.bindAntiAFK()
        P.startStatLoop()
    end

    return P
end
