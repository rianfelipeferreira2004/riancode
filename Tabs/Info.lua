--==================================================
-- Asthetic | TAB | Info
--==================================================

local TabsManager = _G.YOKUDO_TabsManager

local InfoTab, InfoPage = TabsManager:RegisterTab("Info", 1, "INFO")

--==================================================
-- INFO CONTENT
--==================================================
CreateSectionTitle(InfoPage, "Welcome", 1)

--==================================================
-- HERO CARD
--==================================================
local HeroCard = Instance.new("Frame")
HeroCard.Size = UDim2.new(1, 0, 0, 88)
HeroCard.BackgroundColor3 = Color3.fromRGB(26, 27, 38)
HeroCard.BorderSizePixel = 0
HeroCard.LayoutOrder = 2
HeroCard.Parent = InfoPage

local HeroCorner = Instance.new("UICorner")
HeroCorner.CornerRadius = UDim.new(0, 12)
HeroCorner.Parent = HeroCard

local HeroStroke = Instance.new("UIStroke")
HeroStroke.Color = Color3.fromRGB(135, 120, 225)
HeroStroke.Thickness = 1
HeroStroke.Transparency = 0.5
HeroStroke.Parent = HeroCard

local HeroBadge = Instance.new("Frame")
HeroBadge.Size = UDim2.new(0, 46, 0, 46)
HeroBadge.Position = UDim2.new(0, 14, 0.5, -23)
HeroBadge.BackgroundColor3 = Color3.fromRGB(105, 90, 190)
HeroBadge.BorderSizePixel = 0
HeroBadge.Parent = HeroCard

local HeroBadgeCorner = Instance.new("UICorner")
HeroBadgeCorner.CornerRadius = UDim.new(0, 13)
HeroBadgeCorner.Parent = HeroBadge

local HeroBadgeText = Instance.new("TextLabel")
HeroBadgeText.Size = UDim2.new(1, 0, 1, 0)
HeroBadgeText.BackgroundTransparency = 1
HeroBadgeText.Text = "A"
HeroBadgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
HeroBadgeText.TextSize = 24
HeroBadgeText.Font = Enum.Font.MontserratBlack
HeroBadgeText.Parent = HeroBadge

local HeroTitle = Instance.new("TextLabel")
HeroTitle.Size = UDim2.new(1, -80, 0, 26)
HeroTitle.Position = UDim2.new(0, 70, 0, 16)
HeroTitle.BackgroundTransparency = 1
HeroTitle.Text = "ASTHETIC"
HeroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HeroTitle.TextSize = 20
HeroTitle.TextXAlignment = Enum.TextXAlignment.Left
HeroTitle.Font = Enum.Font.MontserratBlack
HeroTitle.LayoutOrder = 2
HeroTitle.Parent = HeroCard

local HeroSub = Instance.new("TextLabel")
HeroSub.Size = UDim2.new(1, -80, 0, 18)
HeroSub.Position = UDim2.new(0, 70, 0, 44)
HeroSub.BackgroundTransparency = 1
HeroSub.Text = "Steal An Egg"
HeroSub.TextColor3 = Color3.fromRGB(150, 150, 175)
HeroSub.TextSize = 11
HeroSub.TextXAlignment = Enum.TextXAlignment.Left
HeroSub.Font = Enum.Font.GothamMedium
HeroSub.Parent = HeroCard

--==================================================
-- STATUS CARD
--==================================================
local StatusCard = Instance.new("Frame")
StatusCard.Size = UDim2.new(1, 0, 0, 92)
StatusCard.BackgroundColor3 = Color3.fromRGB(26, 27, 38)
StatusCard.BorderSizePixel = 0
StatusCard.LayoutOrder = 3
StatusCard.Parent = InfoPage

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 12)
StatusCorner.Parent = StatusCard

local StatusStroke = Instance.new("UIStroke")
StatusStroke.Color = Color3.fromRGB(200, 200, 220)
StatusStroke.Thickness = 1
StatusStroke.Transparency = 0.85
StatusStroke.Parent = StatusCard

local StatusPadding = Instance.new("UIPadding")
StatusPadding.PaddingTop = UDim.new(0, 8)
StatusPadding.PaddingBottom = UDim.new(0, 8)
StatusPadding.PaddingLeft = UDim.new(0, 14)
StatusPadding.PaddingRight = UDim.new(0, 14)
StatusPadding.Parent = StatusCard

local StatusLayout = Instance.new("UIListLayout")
StatusLayout.Padding = UDim.new(0, 2)
StatusLayout.SortOrder = Enum.SortOrder.LayoutOrder
StatusLayout.Parent = StatusCard

local function CreateStatusRow(LabelText, ValueText, ValueColor, Order)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 22)
    Row.BackgroundTransparency = 1
    Row.LayoutOrder = Order
    Row.Parent = StatusCard

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.55, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = LabelText
    Label.TextColor3 = Color3.fromRGB(150, 150, 175)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamMedium
    Label.Parent = Row

    local Value = Instance.new("TextLabel")
    Value.Size = UDim2.new(0.45, 0, 1, 0)
    Value.Position = UDim2.new(0.55, 0, 0, 0)
    Value.BackgroundTransparency = 1
    Value.Text = ValueText
    Value.TextColor3 = ValueColor
    Value.TextSize = 12
    Value.TextXAlignment = Enum.TextXAlignment.Right
    Value.Font = Enum.Font.MontserratBold
    Value.Parent = Row
end

CreateStatusRow("Status", "● Ready", Color3.fromRGB(90, 230, 140), 1)
CreateStatusRow("Config", "Auto-save ON", Color3.fromRGB(135, 120, 225), 2)
CreateStatusRow("Design", "Fluent Own", Color3.fromRGB(200, 200, 220), 3)

--==================================================
-- HINT CARD
--==================================================
local HintCard = Instance.new("Frame")
HintCard.Size = UDim2.new(1, 0, 0, 40)
HintCard.BackgroundColor3 = Color3.fromRGB(26, 27, 38)
HintCard.BorderSizePixel = 0
HintCard.LayoutOrder = 4
HintCard.Parent = InfoPage

local HintCorner = Instance.new("UICorner")
HintCorner.CornerRadius = UDim.new(0, 12)
HintCorner.Parent = HintCard

local HintStroke = Instance.new("UIStroke")
HintStroke.Color = Color3.fromRGB(200, 200, 220)
HintStroke.Thickness = 1
HintStroke.Transparency = 0.85
HintStroke.Parent = HintCard

local HintText = Instance.new("TextLabel")
HintText.Size = UDim2.new(1, -24, 1, 0)
HintText.Position = UDim2.new(0, 12, 0, 0)
HintText.BackgroundTransparency = 1
HintText.Text = "Press the A button to hide / show the UI."
HintText.TextColor3 = Color3.fromRGB(150, 150, 175)
HintText.TextSize = 11
HintText.TextXAlignment = Enum.TextXAlignment.Left
HintText.Font = Enum.Font.GothamMedium
HintText.Parent = HintCard

print("✅ Info Tab Loaded")
