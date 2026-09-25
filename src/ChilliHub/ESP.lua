--========================================================
-- ChilliHub | ESP.lua
-- Egg ESP (billboards + highlight do melhor) + Player ESP.
-- Uso: local esp = require(...ESP)(Ctx); esp.start()
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local U = Ctx.Utils
    local W = Ctx.World

    local E = {}
    E.Folder = nil

    function E.ensureFolder()
        if E.Folder and E.Folder.Parent then return E.Folder end
        local f = Instance.new("Folder")
        f.Name = "ChilliHubESP"
        pcall(function()
            if gethui then f.Parent = gethui()
            elseif get_hidden_gui then f.Parent = get_hidden_gui()
            else f.Parent = S.CoreGui end
        end)
        if not f.Parent then f.Parent = S.Workspace end
        E.Folder = f
        return f
    end

    function E.Clear(prefix)
        E.ensureFolder()
        for _, g in ipairs(E.Folder:GetChildren()) do
            if string.sub(g.Name, 1, #prefix) == prefix then g:Destroy() end
        end
    end

    function E.ClearAll()
        E.Clear("EGG_") E.Clear("BEST_") E.Clear("PLR_")
    end

    local function eggBillboard(info, isBest)
        local m = info.Model
        local adornee = m:IsA("Model")
            and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true))
            or m
        if not adornee then return end
        local gui = Instance.new("BillboardGui")
        gui.Name = "EGG_" .. tostring(m:GetDebugId())
        gui.Adornee = adornee
        gui.Size = UDim2.new(0, 200, 0, 50)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.AlwaysOnTop = true
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.fromScale(1, 1)
        tl.BackgroundTransparency = 1
        tl.TextStrokeTransparency = 0.2
        tl.TextScaled = false
        tl.TextSize = 13
        tl.Font = Enum.FontWeight.Bold
        local hrp = U.HRP()
        local dist = hrp and math.floor((hrp.Position - info.Position).Magnitude) or 0
        tl.Text = ("%s\n%s | %s [%dm]"):format(info.Name, info.Rarity, info.Mutation, dist)
        tl.TextColor3 = isBest and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 255, 160)
        tl.Parent = gui
        gui.Parent = E.Folder
        if isBest then
            local hl = Instance.new("Highlight")
            hl.Name = "BEST_" .. tostring(m:GetDebugId())
            hl.Adornee = m:IsA("Model") and m or adornee
            hl.FillColor = Color3.fromRGB(255, 200, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.6
            hl.Parent = E.Folder
        end
    end

    function E.startEggLoop()
        task.spawn(function()
            while true do
                if State.EggESP then
                    pcall(function()
                        E.Clear("EGG_") E.Clear("BEST_")
                        local eggs = W.SortEggs(W.FindEggs())
                        local hrp = U.HRP()
                        local hp = hrp and hrp.Position or Vector3.new()
                        local best = eggs[1]
                        local shown = 0
                        for _, e in ipairs(eggs) do
                            if shown >= 40 then break end
                            if (e.Position - hp).Magnitude <= State.ESPMaxDist then
                                eggBillboard(e, State.HighlightBest and e == best)
                                shown = shown + 1
                            end
                        end
                    end)
                    task.wait(1.2)
                else
                    E.Clear("EGG_") E.Clear("BEST_")
                    task.wait(0.5)
                end
            end
        end)
    end

    function E.startPlayerLoop()
        task.spawn(function()
            while true do
                if State.PlayerESP then
                    pcall(function()
                        E.Clear("PLR_")
                        for _, p in ipairs(S.Players:GetPlayers()) do
                            if p ~= S.LocalPlayer and p.Character then
                                local h = p.Character:FindFirstChild("HumanoidRootPart")
                                local head = p.Character:FindFirstChild("Head")
                                if h then
                                    local gui = Instance.new("BillboardGui")
                                    gui.Name = "PLR_" .. p.Name
                                    gui.Adornee = head or h
                                    gui.Size = UDim2.new(0, 180, 0, 40)
                                    gui.StudsOffset = Vector3.new(0, 2.5, 0)
                                    gui.AlwaysOnTop = true
                                    local tl = Instance.new("TextLabel")
                                    tl.Size = UDim2.fromScale(1, 1)
                                    tl.BackgroundTransparency = 1
                                    tl.TextSize = 13
                                    tl.Font = Enum.FontWeight.Bold
                                    tl.TextStrokeTransparency = 0.2
                                    local hrp = U.HRP()
                                    local d = hrp and math.floor((hrp.Position - h.Position).Magnitude) or 0
                                    local spd = "?"
                                    pcall(function()
                                        local ls = p:FindFirstChild("leaderstats")
                                        if ls then
                                            for _, v in ipairs(ls:GetChildren()) do
                                                if string.find(string.lower(v.Name), "speed") then
                                                    spd = tostring(v.Value) break
                                                end
                                            end
                                        end
                                    end)
                                    tl.Text = ("%s [%dm] Speed:%s"):format(p.DisplayName, d, tostring(spd))
                                    tl.TextColor3 = Color3.fromRGB(255, 120, 120)
                                    tl.Parent = gui
                                    gui.Parent = E.Folder
                                end
                            end
                        end
                    end)
                    task.wait(1.5)
                else
                    E.Clear("PLR_")
                    task.wait(0.5)
                end
            end
        end)
    end

    function E.start()
        E.ensureFolder()
        E.startEggLoop()
        E.startPlayerLoop()
    end

    return E
end
