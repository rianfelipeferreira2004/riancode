-- ==================================================
-- YOKUDO HUB | TAB | Combat
-- ==================================================

local TabsManager = _G.YOKUDO_TabsManager

local CombatTab, CombatPage = TabsManager:RegisterTab("Combat", 3, "COMBAT")

-- ==================================================
-- CONTENT
-- ==================================================
CreateSectionTitle(CombatPage, "Combat", 1)

-- ==================================================
-- FEATURE 1: AUTO EQUIP BAT (CHECKBOX)
-- ==================================================
local AutoEquipHolder = Instance.new("Frame")
AutoEquipHolder.Size = UDim2.new(1, 0, 0, 32)
AutoEquipHolder.BackgroundTransparency = 1
AutoEquipHolder.LayoutOrder = 2
AutoEquipHolder.Parent = CombatPage

local AutoEquipLabel = Instance.new("TextLabel")
AutoEquipLabel.Size = UDim2.new(1, -50, 1, 0)
AutoEquipLabel.BackgroundTransparency = 1
AutoEquipLabel.Text = "Auto Equip Bat"
AutoEquipLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
AutoEquipLabel.TextSize = 13
AutoEquipLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoEquipLabel.TextYAlignment = Enum.TextYAlignment.Center
AutoEquipLabel.Font = Enum.Font.GothamBold
AutoEquipLabel.Parent = AutoEquipHolder

local AutoEquipCheckButton = Instance.new("TextButton")
AutoEquipCheckButton.Size = UDim2.new(0, 26, 0, 26)
AutoEquipCheckButton.Position = UDim2.new(1, -26, 0.5, -13)
AutoEquipCheckButton.BackgroundColor3 = Color3.fromRGB(28, 29, 39)
AutoEquipCheckButton.BorderSizePixel = 0
AutoEquipCheckButton.Text = ""
AutoEquipCheckButton.AutoButtonColor = false
AutoEquipCheckButton.Parent = AutoEquipHolder

local AutoEquipCorner = Instance.new("UICorner")
AutoEquipCorner.CornerRadius = UDim.new(0, 6)
AutoEquipCorner.Parent = AutoEquipCheckButton

local AutoEquipStroke = Instance.new("UIStroke")
AutoEquipStroke.Color = Color3.fromRGB(200, 200, 220)
AutoEquipStroke.Thickness = 1.5
AutoEquipStroke.Parent = AutoEquipCheckButton

local AutoEquipCheck = Instance.new("TextLabel")
AutoEquipCheck.Size = UDim2.new(1, 0, 1, 0)
AutoEquipCheck.BackgroundTransparency = 1
AutoEquipCheck.Text = "✓"
AutoEquipCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoEquipCheck.TextSize = 18
AutoEquipCheck.Font = Enum.Font.GothamBold
AutoEquipCheck.Visible = false
AutoEquipCheck.Parent = AutoEquipCheckButton

local function SaveCombatConfig()
    pcall(function()
        if _G.YOKUDO_ConfigSystem then
            _G.YOKUDO_ConfigSystem.Save()
        end
    end)
end

local function UpdateAutoEquipUI(State)
    AutoEquipCheck.Visible = State
    if State then
        AutoEquipCheckButton.BackgroundColor3 = Color3.fromRGB(105, 90, 190)
        AutoEquipStroke.Color = Color3.fromRGB(135, 120, 225)
    else
        AutoEquipCheckButton.BackgroundColor3 = Color3.fromRGB(28, 29, 39)
        AutoEquipStroke.Color = Color3.fromRGB(200, 200, 220)
    end
end

local function ToggleAutoEquip()
    local NewState = not AutoEquipCheck.Visible
    UpdateAutoEquipUI(NewState)
    if NewState then
        if _G.YOKUDO_AutoAttack then
            _G.YOKUDO_AutoAttack.EnableAutoEquip()
        end
    else
        if _G.YOKUDO_AutoAttack then
            _G.YOKUDO_AutoAttack.DisableAutoEquip()
        end
    end
    SaveCombatConfig()
end

AutoEquipCheckButton.MouseButton1Click:Connect(function()
    ToggleAutoEquip()
end)

-- ==================================================
-- FEATURE 2: AUTO HIT PLAYER (CHECKBOX)
-- ==================================================
local AutoHitHolder = Instance.new("Frame")
AutoHitHolder.Size = UDim2.new(1, 0, 0, 52)
AutoHitHolder.BackgroundTransparency = 1
AutoHitHolder.LayoutOrder = 3
AutoHitHolder.Parent = CombatPage

local AutoHitLabel = Instance.new("TextLabel")
AutoHitLabel.Size = UDim2.new(1, -50, 0, 20)
AutoHitLabel.Position = UDim2.new(0, 0, 0, 2)
AutoHitLabel.BackgroundTransparency = 1
AutoHitLabel.Text = "Auto Hit Player"
AutoHitLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
AutoHitLabel.TextSize = 13
AutoHitLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoHitLabel.TextYAlignment = Enum.TextYAlignment.Center
AutoHitLabel.Font = Enum.Font.GothamBold
AutoHitLabel.Parent = AutoHitHolder

local AutoHitTitle = Instance.new("TextLabel")
AutoHitTitle.Size = UDim2.new(1, -50, 0, 18)
AutoHitTitle.Position = UDim2.new(0, 0, 0, 24)
AutoHitTitle.BackgroundTransparency = 1
AutoHitTitle.Text = "Range: 50 studs"
AutoHitTitle.TextColor3 = Color3.fromRGB(150, 150, 170)
AutoHitTitle.TextSize = 10
AutoHitTitle.TextXAlignment = Enum.TextXAlignment.Left
AutoHitTitle.Font = Enum.Font.Gotham
AutoHitTitle.Parent = AutoHitHolder

local AutoHitCheckButton = Instance.new("TextButton")
AutoHitCheckButton.Size = UDim2.new(0, 26, 0, 26)
AutoHitCheckButton.Position = UDim2.new(1, -26, 0.5, -13)
AutoHitCheckButton.BackgroundColor3 = Color3.fromRGB(28, 29, 39)
AutoHitCheckButton.BorderSizePixel = 0
AutoHitCheckButton.Text = ""
AutoHitCheckButton.AutoButtonColor = false
AutoHitCheckButton.Parent = AutoHitHolder

local AutoHitCorner = Instance.new("UICorner")
AutoHitCorner.CornerRadius = UDim.new(0, 6)
AutoHitCorner.Parent = AutoHitCheckButton

local AutoHitStroke = Instance.new("UIStroke")
AutoHitStroke.Color = Color3.fromRGB(200, 200, 220)
AutoHitStroke.Thickness = 1.5
AutoHitStroke.Parent = AutoHitCheckButton

local AutoHitCheck = Instance.new("TextLabel")
AutoHitCheck.Size = UDim2.new(1, 0, 1, 0)
AutoHitCheck.BackgroundTransparency = 1
AutoHitCheck.Text = "✓"
AutoHitCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoHitCheck.TextSize = 18
AutoHitCheck.Font = Enum.Font.GothamBold
AutoHitCheck.Visible = false
AutoHitCheck.Parent = AutoHitCheckButton

local function UpdateAutoHitUI(State)
    AutoHitCheck.Visible = State
    if State then
        AutoHitCheckButton.BackgroundColor3 = Color3.fromRGB(105, 90, 190)
        AutoHitStroke.Color = Color3.fromRGB(135, 120, 225)
    else
        AutoHitCheckButton.BackgroundColor3 = Color3.fromRGB(28, 29, 39)
        AutoHitStroke.Color = Color3.fromRGB(200, 200, 220)
    end
end

local function ToggleAutoHit()
    local NewState = not AutoHitCheck.Visible
    UpdateAutoHitUI(NewState)
    if NewState then
        if _G.YOKUDO_AutoAttack then
            _G.YOKUDO_AutoAttack.EnableAutoHit()
        end
    else
        if _G.YOKUDO_AutoAttack then
            _G.YOKUDO_AutoAttack.DisableAutoHit()
        end
    end
    SaveCombatConfig()
end

AutoHitCheckButton.MouseButton1Click:Connect(function()
    ToggleAutoHit()
end)

-- ==================================================
-- REFRESH + SYNC (autoload / rejoin)
-- ==================================================
_G.YOKUDO_RefreshCombatUI = function()
    if _G.YOKUDO_AutoAttack then
        pcall(function() UpdateAutoEquipUI(_G.YOKUDO_AutoAttack.IsAutoEquipEnabled()) end)
        pcall(function() UpdateAutoHitUI(_G.YOKUDO_AutoAttack.IsAutoHitEnabled()) end)
    end
end

-- Sync inicial (pega o estado aplicado pelo AutoExecute)
task.spawn(function()
    task.wait(1)
    pcall(function()
        if _G.YOKUDO_RefreshCombatUI then
            _G.YOKUDO_RefreshCombatUI()
        end
    end)
end)

-- Sync periódico + status "pausado na esteira"
task.spawn(function()
    local BaseText = "Range: 50 studs"
    while task.wait(1) do
        if _G.YOKUDO_AutoAttack then
            local OkE, E = pcall(function() return _G.YOKUDO_AutoAttack.IsAutoEquipEnabled() end)
            local OkH, H = pcall(function() return _G.YOKUDO_AutoAttack.IsAutoHitEnabled() end)
            if OkE and type(E) == "boolean" and E ~= AutoEquipCheck.Visible then
                UpdateAutoEquipUI(E)
            end
            if OkH and type(H) == "boolean" and H ~= AutoHitCheck.Visible then
                UpdateAutoHitUI(H)
            end
            -- Aviso visual: bat pausado na esteira
            local Paused = false
            pcall(function()
                Paused = _G.YOKUDO_AutoAttack.IsOnTreadmill()
            end)
            if H and Paused then
                AutoHitTitle.Text = BaseText .. " • ⏸ na esteira"
            else
                if AutoHitTitle.Text ~= BaseText then
                    AutoHitTitle.Text = BaseText
                end
            end
        end
    end
end)

print("✅ Combat Tab Loaded")
