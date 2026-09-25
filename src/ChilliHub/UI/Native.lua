--========================================================
-- ChilliHub | UI/Native.lua
-- Fallback zero-dependência (ScreenGui direto).
-- Mesmos toggles da Orion, sem SaveConfig.
-- Uso: require(...Native)(Ctx).build()
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local U = Ctx.Utils

    local N = {}

    function N.build()
        local parent = nil
        pcall(function()
            if gethui then parent = gethui()
            elseif game:GetService("CoreGui") then parent = game:GetService("CoreGui") end
        end)
        if not parent then parent = S.LocalPlayer:WaitForChild("PlayerGui") end

        local W, Mv, Rm, AC, Auto =
            Ctx.World, Ctx.Movement, Ctx.Remotes, Ctx.AntiCheat, Ctx.Automation

        local gui = Instance.new("ScreenGui")
        gui.Name = "ChilliHubNative"
        gui.ResetOnSpawn = false
        gui.Parent = parent

        local main = Instance.new("Frame")
        main.Name = "Main"
        main.Size = UDim2.new(0, 420, 0, 360)
        main.Position = UDim2.new(0.5, -210, 0.5, -180)
        main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        main.BorderSizePixel = 0
        main.Active = true
        main.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = main

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -40, 0, 32)
        title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        title.Text = "Chilli Hub | Steal an Egg (NATIVA)"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.FontWeight.Bold
        title.TextSize = 14
        title.Parent = main

        do -- arrastar pela barra
            local drag, start, pos0 = false, nil, nil
            title.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                    drag, start, pos0 = true, i.Position, main.Position
                end
            end)
            S.UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then drag = false end
            end)
            S.UserInputService.InputChanged:Connect(function(i)
                if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = i.Position - start
                    main.Position = UDim2.new(pos0.X.Scale, pos0.X.Offset + d.X,
                        pos0.Y.Scale, pos0.Y.Offset + d.Y)
                end
            end)
        end

        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 40, 0, 32)
        close.Position = UDim2.new(1, -40, 0, 0)
        close.Text = "X"
        close.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        close.TextColor3 = Color3.fromRGB(255, 255, 255)
        close.Font = Enum.FontWeight.Bold
        close.TextSize = 14
        close.Parent = main
        close.MouseButton1Click:Connect(function() gui:Destroy() end)

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -10, 1, -42)
        scroll.Position = UDim2.new(0, 5, 0, 37)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 5
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = main
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = scroll

        local function header(t)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -6, 0, 22)
            l.BackgroundTransparency = 1
            l.Text = "== " .. t .. " =="
            l.TextColor3 = Color3.fromRGB(90, 200, 255)
            l.Font = Enum.FontWeight.Bold
            l.TextSize = 13
            l.Parent = scroll
        end
        local function toggle(name, get, set)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -6, 0, 28)
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.Font = Enum.FontWeight.Medium
            b.TextSize = 13
            b.Parent = scroll
            local function paint() b.Text = (get() and "[ON] " or "[OFF] ") .. name end
            paint()
            b.MouseButton1Click:Connect(function() set(not get()) paint() end)
            return b
        end
        local function button(name, cb)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -6, 0, 28)
            b.BackgroundColor3 = Color3.fromRGB(40, 90, 140)
            b.Text = name
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.Font = Enum.FontWeight.Medium
            b.TextSize = 13
            b.Parent = scroll
            b.MouseButton1Click:Connect(function() task.spawn(cb) end)
        end
        local function numbox(name, get, set)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -6, 0, 28)
            f.BackgroundTransparency = 1
            f.Parent = scroll
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(0.55, 0, 1, 0)
            l.BackgroundTransparency = 1
            l.Text = name
            l.TextColor3 = Color3.fromRGB(220, 220, 220)
            l.TextSize = 13
            l.Font = Enum.FontWeight.Medium
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = f
            local t = Instance.new("TextBox")
            t.Size = UDim2.new(0.45, 0, 1, 0)
            t.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            t.Text = tostring(get())
            t.TextColor3 = Color3.fromRGB(255, 255, 255)
            t.TextSize = 13
            t.ClearTextOnFocus = false
            t.Parent = f
            t.FocusLost:Connect(function(enter)
                if enter then
                    local v = tonumber(t.Text)
                    if v then set(v) end
                    t.Text = tostring(get())
                end
            end)
        end
        local function cycle(name, options, get, set)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -6, 0, 28)
            b.BackgroundColor3 = Color3.fromRGB(70, 60, 30)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.Font = Enum.FontWeight.Medium
            b.TextSize = 13
            b.Parent = scroll
            local function paint() b.Text = name .. ": " .. tostring(get()) end
            paint()
            b.MouseButton1Click:Connect(function()
                local cur, idx = get(), 1
                for i, v in ipairs(options) do if v == cur then idx = i break end end
                set(options[(idx % #options) + 1]) paint()
            end)
        end

        header("FARM")
        toggle("Auto Steal (filtros)", function() return State.AutoSteal end, function(v) State.AutoSteal = v end)
        toggle("Auto Steal TUDO", function() return State.AutoStealAll end, function(v) State.AutoStealAll = v end)
        toggle("Auto Voltar Base", function() return State.AutoReturn end, function(v) State.AutoReturn = v end)
        toggle("Snipe Raros", function() return State.AutoSnipe end, function(v) State.AutoSnipe = v end)
        numbox("Tween Speed", function() return State.TweenSpeed end, function(v) State.TweenSpeed = v end)
        numbox("Delay roubos", function() return State.StealDelay end, function(v) State.StealDelay = v end)
        cycle("Prioridade", { "Mais Raro", "Mais Proximo", "Mais Distante", "Maior Tamanho" },
            function() return State.Priority end, function(v) State.Priority = v end)
        button("Roubar melhor ovo AGORA", function() Auto.stealBestNow() end)
        button("Voltar pra Base AGORA", function() Auto.returnBaseNow() end)

        header("PETS")
        toggle("Auto Hatch", function() return State.AutoHatch end, function(v) State.AutoHatch = v end)
        toggle("Auto Equipar Melhor", function() return State.AutoEquipBest end, function(v) State.AutoEquipBest = v end)
        numbox("Delay Hatch", function() return State.HatchDelay end, function(v) State.HatchDelay = v end)
        button("Chocar 1x AGORA", function()
            local h = Rm.Get("hatch", { "hatch", "openegg", "open_egg", "unbox" })
            if h then Rm.SafeFire(h, State.HatchEgg) U.Notify("Hatch", "Disparado") end
        end)
        button("Equipar Melhor AGORA", function()
            local eq = Rm.Get("equip", { "equipbest", "equip_best", "equip", "bestpet" })
            if eq then Rm.SafeFire(eq, "Best") end
        end)

        header("TREINO")
        toggle("Auto Treinar", function() return State.AutoTrain end, function(v) State.AutoTrain = v end)
        toggle("Auto Up Treadmill", function() return State.AutoUpgradeTreadmill end, function(v) State.AutoUpgradeTreadmill = v end)
        toggle("Auto Up Base", function() return State.AutoUpgradeBase end, function(v) State.AutoUpgradeBase = v end)
        toggle("Auto Coletar", function() return State.AutoCollect end, function(v) State.AutoCollect = v end)
        button("Ir pra Treadmill", function()
            local cf = W.GetTreadmillCFrame()
            if cf then Mv.TweenTo(cf) end
        end)

        header("VISUAL / JOGADOR")
        toggle("Egg ESP", function() return State.EggESP end, function(v) State.EggESP = v end)
        toggle("Player ESP", function() return State.PlayerESP end, function(v) State.PlayerESP = v end)
        toggle("WalkSpeed custom", function() return State.WSEnabled end, function(v) State.WSEnabled = v end)
        numbox("WalkSpeed", function() return State.WalkSpeed end, function(v) State.WalkSpeed = v end)
        toggle("NoClip", function() return State.NoClip end, function(v) Mv.SetNoclip(v) end)
        toggle("Godmode", function() return State.Godmode end, function(v) State.Godmode = v end)
        button("Server Hop", function() Mv.ServerHop() end)
        button("Rejoin", function() S.TeleportService:Teleport(S.PLACE_ID, S.LocalPlayer) end)

        header("PROTECAO")
        toggle("Anti-Kick (hook, pode detectar)", function() return State.AntiKick end,
            function(v) State.AntiKick = v if v then AC.Setup() end end)
        toggle("Modo Humano", function() return State.Humanized end, function(v) State.Humanized = v end)
        toggle("Block Kick/Ban", function() return State.BlockKickRemotes end, function(v) State.BlockKickRemotes = v end)
        toggle("Modo Seguro", function() return State.SafeMode end, function(v) State.SafeMode = v end)
        toggle("Usar Remotes", function() return State.UseRemotes end, function(v) State.UseRemotes = v end)
        toggle("Pathfinding", function() return State.UsePathfind end, function(v) State.UsePathfind = v end)
        toggle("Spoof WS", function() return State.SpoofProps end,
            function(v) State.SpoofProps = v if v then AC.Setup() end end)
        toggle("Auto-Rejoin", function() return State.AutoRejoin end, function(v) State.AutoRejoin = v end)
        button("Humanoid Swap", function()
            task.spawn(function() AC.HumanoidSwap() end)
        end)

        header("DIAGNOSTICO")
        button("Escanear Remotes", function()
            local n = Rm.Refresh()
            U.Notify("Remotes", "Achados: " .. n, 6)
        end)
        button("Escanear Mapa", function()
            local eggs = W.FindEggs()
            U.Notify("Mapa", "Ovos: " .. #eggs, 6)
        end)

        Rm.Refresh()
        U.Notify("Chilli Hub", "Carregado na UI NATIVA (fallback).", 5)
        print("[ChilliHub] UI nativa carregada. PlaceId:", S.PLACE_ID)
        return true
    end

    return N
end
