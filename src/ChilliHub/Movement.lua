--========================================================
-- ChilliHub | Movement.lua
-- Noclip + Tween robusto + Pathfinding + ServerHop.
-- Uso: local Mv = require(...Movement)(Ctx)
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local U = Ctx.Utils

    local Mv = {}
    local NoclipConn = nil
    local ActiveTween = nil

    function Mv.SetNoclip(on)
        State.NoClip = on
        if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
        if on then
            NoclipConn = S.RunService.Stepped:Connect(function()
                local c = S.LocalPlayer.Character
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
                        end
                    end
                end
            end)
        end
    end

    function Mv.IsNoclip()
        return NoclipConn ~= nil
    end

    -- Tween robusto: cancela tween anterior, respeita SafeMode,
    -- mantém noclip só durante o trajeto e restaura depois.
    function Mv.TweenTo(cf, speed)
        local hrp = U.HRP()
        if not hrp then return false end
        speed = speed or State.TweenSpeed
        if speed <= 0 then speed = 220 end
        if State.SafeMode then
            speed = math.min(speed, 150)
            cf = cf + Vector3.new((math.random() - 0.5) * 6, 0, (math.random() - 0.5) * 6)
        end
        local dist = (hrp.Position - cf.Position).Magnitude
        if dist < 4 then return true end
        local t = math.clamp(dist / speed, 0.05, 12)
        if ActiveTween then pcall(function() ActiveTween:Cancel() end) ActiveTween = nil end
        local tw = S.TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = cf })
        ActiveTween = tw
        local wasNoclip = State.NoClip
        if State.SmartTween then Mv.SetNoclip(true) end
        tw:Play()
        local done = false
        local conn
        conn = tw.Completed:Connect(function() done = true end)
        local start = os.clock()
        while not done and os.clock() - start < (t + 2) do
            if not U.HRP() then break end
            task.wait()
        end
        if conn then conn:Disconnect() end
        if State.SmartTween and not wasNoclip and not State.NoClip then
            if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
            State.NoClip = wasNoclip
        end
        return done
    end

    -- Caminho por waypoints (parece movimento legítimo).
    -- Cai para tween direto se não achar rota.
    function Mv.TweenPathTo(targetCF)
        if not State.UsePathfind then return Mv.TweenTo(targetCF) end
        local hrp = U.HRP()
        if not hrp then return false end
        local ok, path = pcall(function()
            local p = S.PathfindingService:CreatePath({
                AgentRadius = 2, AgentHeight = 5, AgentCanJump = true,
            })
            p:ComputeAsync(hrp.Position, targetCF.Position)
            return p
        end)
        if not ok or not path or path.Status ~= Enum.PathStatus.Success then
            return Mv.TweenTo(targetCF)
        end
        for _, wp in ipairs(path:GetWaypoints()) do
            if not U.HRP() then return false end
            Mv.TweenTo(CFrame.new(wp.Position + Vector3.new(0, 3, 0)))
            if wp.Action == Enum.PathWaypointAction.Jump then
                local h = U.Hum()
                if h then h.Jump = true end
            end
        end
        return Mv.TweenTo(targetCF)
    end

    function Mv.ServerHop()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(S.PLACE_ID)
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and res then
            local data = S.HttpService:JSONDecode(res)
            for _, s in ipairs(data.data or {}) do
                if s.playing < s.maxPlayers and s.id ~= S.JOB_ID then
                    S.TeleportService:TeleportToPlaceInstance(S.PLACE_ID, s.id, S.LocalPlayer)
                    return
                end
            end
        end
        S.TeleportService:Teleport(S.PLACE_ID, S.LocalPlayer)
    end

    function Mv.CancelTween()
        if ActiveTween then pcall(function() ActiveTween:Cancel() end) ActiveTween = nil end
    end

    return Mv
end
