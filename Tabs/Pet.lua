--==================================================
-- YOKUDO HUB | TAB | Pet
-- Auto Place Egg + Auto Hatch (movidos do Auto Farming)
--==================================================

local TabsManager = _G.YOKUDO_TabsManager

local PetTab, PetPage = TabsManager:RegisterTab("Pet", 6, "PET")

--==================================================
-- CONTENT
--==================================================
CreateSectionTitle(PetPage, "Pet", 1)

--==================================================
-- FEATURE 1: Auto Place Egg (entrega na base)
--==================================================
local PlaceHolder = Instance.new("Frame")
PlaceHolder.Size = UDim2.new(1, 0, 0, 44)
PlaceHolder.BackgroundColor3 = Color3.fromRGB(28, 29, 42)
PlaceHolder.BorderSizePixel = 0
PlaceHolder.LayoutOrder = 2
PlaceHolder.Parent = PetPage

local PlaceHolderCorner = Instance.new("UICorner")
PlaceHolderCorner.CornerRadius = UDim.new(0, 8)
PlaceHolderCorner.Parent = PlaceHolder

local PlaceHolderStroke = Instance.new("UIStroke")
PlaceHolderStroke.Color = Color3.fromRGB(105, 90, 190)
PlaceHolderStroke.Thickness = 1.5
PlaceHolderStroke.Transparency = 0.4
PlaceHolderStroke.Parent = PlaceHolder

local PlaceLabel = Instance.new("TextLabel")
PlaceLabel.Size = UDim2.new(1, -70, 1, 0)
PlaceLabel.Position = UDim2.new(0, 12, 0, 0)
PlaceLabel.BackgroundTransparency = 1
PlaceLabel.Text = "Auto Place Egg"
PlaceLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
PlaceLabel.TextSize = 13
PlaceLabel.TextXAlignment = Enum.TextXAlignment.Left
PlaceLabel.TextYAlignment = Enum.TextYAlignment.Center
PlaceLabel.Font = Enum.Font.GothamBold
PlaceLabel.Parent = PlaceHolder

local PlaceCheckButton = Instance.new("TextButton")
PlaceCheckButton.Size = UDim2.new(0, 30, 0, 30)
PlaceCheckButton.Position = UDim2.new(1, -40, 0.5, -15)
PlaceCheckButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PlaceCheckButton.BackgroundTransparency = 0.85
PlaceCheckButton.BorderSizePixel = 0
PlaceCheckButton.Text = ""
PlaceCheckButton.AutoButtonColor = false
PlaceCheckButton.Parent = PlaceHolder

local PlaceCorner = Instance.new("UICorner")
PlaceCorner.CornerRadius = UDim.new(0, 8)
PlaceCorner.Parent = PlaceCheckButton

local PlaceStroke = Instance.new("UIStroke")
PlaceStroke.Color = Color3.fromRGB(255, 255, 255)
PlaceStroke.Thickness = 2
PlaceStroke.Parent = PlaceCheckButton

local PlaceCheck = Instance.new("TextLabel")
PlaceCheck.Size = UDim2.new(1, 0, 1, 0)
PlaceCheck.BackgroundTransparency = 1
PlaceCheck.Text = "✓"
PlaceCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
PlaceCheck.TextSize = 20
PlaceCheck.Font = Enum.Font.GothamBold
PlaceCheck.Visible = false
PlaceCheck.Parent = PlaceCheckButton

local function UpdatePlaceUI(State)
    PlaceCheck.Visible = State
    if State then
        PlaceCheckButton.BackgroundColor3 = Color3.fromRGB(105, 90, 190)
        PlaceCheckButton.BackgroundTransparency = 0
        PlaceStroke.Color = Color3.fromRGB(135, 120, 225)
    else
        PlaceCheckButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        PlaceCheckButton.BackgroundTransparency = 0.85
        PlaceStroke.Color = Color3.fromRGB(255, 255, 255)
    end
end

local function SavePetConfig()
    pcall(function()
        if _G.YOKUDO_ConfigSystem then
            _G.YOKUDO_ConfigSystem.Save()
        end
    end)
end

local function TogglePlace()
    if not _G.YOKUDO_AutoPlaceEgg then return end
    local NewState = not _G.YOKUDO_AutoPlaceEgg.IsEnabled()
    UpdatePlaceUI(NewState)
    if NewState then
        _G.YOKUDO_AutoPlaceEgg.Enable()
    else
        _G.YOKUDO_AutoPlaceEgg.Disable()
    end
    SavePetConfig()
end

PlaceCheckButton.MouseButton1Click:Connect(function()
    TogglePlace()
end)

--==================================================
-- FEATURE 2: Auto Hatch (+ remote assist)
--==================================================
local HatchHolder = Instance.new("Frame")
HatchHolder.Size = UDim2.new(1, 0, 0, 44)
HatchHolder.BackgroundColor3 = Color3.fromRGB(28, 29, 42)
HatchHolder.BorderSizePixel = 0
HatchHolder.LayoutOrder = 3
HatchHolder.Parent = PetPage

local HatchHolderCorner = Instance.new("UICorner")
HatchHolderCorner.CornerRadius = UDim.new(0, 8)
HatchHolderCorner.Parent = HatchHolder

local HatchHolderStroke = Instance.new("UIStroke")
HatchHolderStroke.Color = Color3.fromRGB(105, 90, 190)
HatchHolderStroke.Thickness = 1.5
HatchHolderStroke.Transparency = 0.4
HatchHolderStroke.Parent = HatchHolder

local HatchLabel = Instance.new("TextLabel")
HatchLabel.Size = UDim2.new(1, -110, 1, 0)
HatchLabel.Position = UDim2.new(0, 12, 0, 0)
HatchLabel.BackgroundTransparency = 1
HatchLabel.Text = "Auto Hatch"
HatchLabel.TextColor3 = Color3.fromRGB(220, 220, 235)
HatchLabel.TextSize = 13
HatchLabel.TextXAlignment = Enum.TextXAlignment.Left
HatchLabel.TextYAlignment = Enum.TextYAlignment.Center
HatchLabel.Font = Enum.Font.GothamBold
HatchLabel.Parent = HatchHolder

local HatchRemoteButton = Instance.new("TextButton")
HatchRemoteButton.Size = UDim2.new(0, 30, 0, 30)
HatchRemoteButton.Position = UDim2.new(1, -76, 0.5, -15)
HatchRemoteButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HatchRemoteButton.BackgroundTransparency = 0.85
HatchRemoteButton.BorderSizePixel = 0
HatchRemoteButton.Text = "R"
HatchRemoteButton.TextColor3 = Color3.fromRGB(60, 60, 80)
HatchRemoteButton.TextSize = 14
HatchRemoteButton.Font = Enum.Font.GothamBold
HatchRemoteButton.AutoButtonColor = false
HatchRemoteButton.Parent = HatchHolder

local HatchRemoteCorner = Instance.new("UICorner")
HatchRemoteCorner.CornerRadius = UDim.new(0, 8)
HatchRemoteCorner.Parent = HatchRemoteButton

local HatchCheckButton = Instance.new("TextButton")
HatchCheckButton.Size = UDim2.new(0, 30, 0, 30)
HatchCheckButton.Position = UDim2.new(1, -40, 0.5, -15)
HatchCheckButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HatchCheckButton.BackgroundTransparency = 0.85
HatchCheckButton.BorderSizePixel = 0
HatchCheckButton.Text = ""
HatchCheckButton.AutoButtonColor = false
HatchCheckButton.Parent = HatchHolder

local HatchCorner = Instance.new("UICorner")
HatchCorner.CornerRadius = UDim.new(0, 8)
HatchCorner.Parent = HatchCheckButton

local HatchStroke = Instance.new("UIStroke")
HatchStroke.Color = Color3.fromRGB(255, 255, 255)
HatchStroke.Thickness = 2
HatchStroke.Parent = HatchCheckButton

local HatchCheck = Instance.new("TextLabel")
HatchCheck.Size = UDim2.new(1, 0, 1, 0)
HatchCheck.BackgroundTransparency = 1
HatchCheck.Text = "✓"
HatchCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
HatchCheck.TextSize = 20
HatchCheck.Font = Enum.Font.GothamBold
HatchCheck.Visible = false
HatchCheck.Parent = HatchCheckButton

local HatchRemoteOn = false

local function UpdateHatchUI(State)
    HatchCheck.Visible = State
    if State then
        HatchCheckButton.BackgroundColor3 = Color3.fromRGB(105, 90, 190)
        HatchCheckButton.BackgroundTransparency = 0
        HatchStroke.Color = Color3.fromRGB(135, 120, 225)
    else
        HatchCheckButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        HatchCheckButton.BackgroundTransparency = 0.85
        HatchStroke.Color = Color3.fromRGB(255, 255, 255)
    end
end

local function UpdateHatchRemoteUI(State)
    HatchRemoteOn = State
    if State then
        HatchRemoteButton.BackgroundColor3 = Color3.fromRGB(200, 120, 60)
        HatchRemoteButton.BackgroundTransparency = 0
        HatchRemoteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        HatchRemoteButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        HatchRemoteButton.BackgroundTransparency = 0.85
        HatchRemoteButton.TextColor3 = Color3.fromRGB(60, 60, 80)
    end
end

local function ToggleHatch()
    if not _G.YOKUDO_AutoHatch then return end
    local NewState = not _G.YOKUDO_AutoHatch.IsEnabled()
    UpdateHatchUI(NewState)
    if NewState then
        _G.YOKUDO_AutoHatch.SetRemoteAssist(HatchRemoteOn)
        _G.YOKUDO_AutoHatch.Enable()
    else
        _G.YOKUDO_AutoHatch.Disable()
    end
    SavePetConfig()
end

HatchCheckButton.MouseButton1Click:Connect(function()
    ToggleHatch()
end)

HatchRemoteButton.MouseButton1Click:Connect(function()
    UpdateHatchRemoteUI(not HatchRemoteOn)
    if _G.YOKUDO_AutoHatch then
        _G.YOKUDO_AutoHatch.SetRemoteAssist(HatchRemoteOn)
    end
    SavePetConfig()
end)

--==================================================
-- SYNC + REFRESH (evita UI dessincronizada)
--==================================================
task.spawn(function()
    task.wait(1)
    if _G.YOKUDO_AutoPlaceEgg then
        UpdatePlaceUI(_G.YOKUDO_AutoPlaceEgg.IsEnabled())
    end
    if _G.YOKUDO_AutoHatch then
        UpdateHatchUI(_G.YOKUDO_AutoHatch.IsEnabled())
        UpdateHatchRemoteUI(_G.YOKUDO_AutoHatch.IsRemoteAssist())
    end
end)

_G.YOKUDO_RefreshPetUI = function()
    if _G.YOKUDO_AutoPlaceEgg then
        UpdatePlaceUI(_G.YOKUDO_AutoPlaceEgg.IsEnabled())
    end
    if _G.YOKUDO_AutoHatch then
        UpdateHatchUI(_G.YOKUDO_AutoHatch.IsEnabled())
        UpdateHatchRemoteUI(_G.YOKUDO_AutoHatch.IsRemoteAssist())
    end
end

task.spawn(function()
    while task.wait(1) do
        if _G.YOKUDO_AutoPlaceEgg then
            local Current = _G.YOKUDO_AutoPlaceEgg.IsEnabled()
            if Current ~= PlaceCheck.Visible then
                UpdatePlaceUI(Current)
            end
        end
        if _G.YOKUDO_AutoHatch then
            local Current = _G.YOKUDO_AutoHatch.IsEnabled()
            if Current ~= HatchCheck.Visible then
                UpdateHatchUI(Current)
            end
        end
    end
end)

print("✅ Pet Tab Loaded")
