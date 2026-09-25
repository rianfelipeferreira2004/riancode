--==================================================
-- YOKUDO HUB | FEATURE | Auto Place Egg
-- Quando estiver carregando um ovo (DropHeldEgg.Enabled),
-- voa ate o ponto de entrega e ativa os prompts (place).
-- Fisico primeiro: nenhum remote obrigatorio.
-- ✅ Register manual via _G.YOKUDO_AutoPlaceEgg
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local Enabled = false
local PlacePos = Vector3.new(533, 70, -366) -- mesma SAFE_ZONE do TeleportSystem/VIPTP
local FlySpeed = 250
local PromptRadius = 22
local LoopRunning = false

local BodyVelocity = nil
local BodyGyro = nil
local FlyConnection = nil

--==================================================
-- HELPERS
--==================================================

local function GetRoot()
    local Char = Player.Character
    if not Char then return nil end
    return Char:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local Char = Player.Character
    if not Char then return nil end
    return Char:FindFirstChildOfClass("Humanoid")
end

-- Mesmo sinal que o TeleportSystem usa: carregando ovo?
local function IsCarrying()
    local ok, gui = pcall(function()
        return Player:FindFirstChild("PlayerGui")
    end)
    if not ok or not gui then return false end
    local drop = gui:FindFirstChild("DropHeldEgg")
    if not drop then return false end
    return drop.Enabled == true
end

local function CleanupMovers()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if BodyVelocity then
        pcall(function()
            BodyVelocity.Velocity = Vector3.zero
            BodyVelocity.MaxForce = Vector3.zero
        end)
        BodyVelocity:Destroy()
        BodyVelocity = nil
    end
    if BodyGyro then
        pcall(function() BodyGyro.MaxTorque = Vector3.zero end)
        BodyGyro:Destroy()
        BodyGyro = nil
    end
    local Hum = GetHum()
    if Hum then
        pcall(function() Hum.PlatformStand = false end)
    end
    local Root = GetRoot()
    if Root then
        pcall(function()
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

-- Voo fisico curto (padrao YokuHub: BodyVelocity + lock no destino)
local function FlyTo(Destination, Callback)
    CleanupMovers()

    local Hum, Root = GetHum(), GetRoot()
    if not Hum or not Root then
        if Callback then Callback(false) end
        return
    end
    if Hum.Health <= 0 then
        if Callback then Callback(false) end
        return
    end

    Hum.PlatformStand = true

    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "YokudoPlaceBV"
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.P = 1250
    BodyVelocity.Velocity = Vector3.zero
    BodyVelocity.Parent = Root

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "YokudoPlaceBG"
    BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    BodyGyro.P = 3000
    BodyGyro.D = 500
    BodyGyro.CFrame = Root.CFrame
    BodyGyro.Parent = Root

    local FlyPos = Vector3.new(Destination.X, Destination.Y + 5, Destination.Z)
    local StartTime = tick()
    local Done = false

    local function Finish(ok)
        if Done then return end
        Done = true
        CleanupMovers()
        if ok then
            local R = GetRoot()
            if R then
                R.CFrame = CFrame.new(Destination + Vector3.new(0, 2, 0))
                pcall(function()
                    R.AssemblyLinearVelocity = Vector3.zero
                    R.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end
        if Callback then Callback(ok) end
    end

    FlyConnection = RunService.Heartbeat:Connect(function()
        if Done then return end
        if not Enabled then Finish(false) return end
        local R = GetRoot()
        if not R or not BodyVelocity or not BodyGyro then Finish(false) return end
        local Dir = (FlyPos - R.Position)
        if Vector3.new(Dir.X, 0, Dir.Z).Magnitude <= 3 and math.abs(Dir.Y) <= 3 then
            if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
            Finish(true)
            return
        end
        if tick() - StartTime > 30 then
            if FlyConnection then FlyConnection:Disconnect() FlyConnection = nil end
            Finish(false)
            return
        end
        BodyVelocity.Velocity = Dir.Unit * FlySpeed
        BodyGyro.CFrame = CFrame.new(R.Position, R.Position + Vector3.new(Dir.X, 0, Dir.Z))
    end)
end

local function FirePrompts(Center, Radius)
    local Fired = 0
    pcall(function()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local parent = d.Parent
                local pp = nil
                if parent and parent:IsA("BasePart") then
                    pp = parent.Position
                elseif parent and parent:IsA("Model") then
                    local ok, pivot = pcall(function() return parent:GetPivot().Position end)
                    if ok then pp = pivot end
                end
                if pp and (pp - Center).Magnitude <= Radius then
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(d)
                        else
                            d:InputHoldBegin() task.wait(0.05) d:InputHoldEnd()
                        end
                    end)
                    Fired = Fired + 1
                end
            end
        end
    end)
    return Fired
end

--==================================================
-- MAIN LOOP
--==================================================

local function Loop()
    if LoopRunning then return end
    LoopRunning = true
    task.spawn(function()
        while Enabled do
            if IsCarrying() then
                print("[YOKUDO] AutoPlace: carregando ovo -> indo entregar")
                local Arrived = false
                FlyTo(PlacePos, function(ok) Arrived = ok end)
                local Waited = 0
                while not Arrived and Waited < 35 and Enabled do
                    task.wait(0.5)
                    Waited = Waited + 0.5
                end
                if Enabled and Arrived then
                    local n = FirePrompts(PlacePos, PromptRadius)
                    print("[YOKUDO] AutoPlace: prompts ativados: " .. n)
                    task.wait(1.5)
                    if not IsCarrying() then
                        print("[YOKUDO] AutoPlace: ovo entregue!")
                    else
                        FirePrompts(PlacePos, PromptRadius + 10)
                        task.wait(1.5)
                    end
                end
            else
                task.wait(0.5)
            end
            task.wait(0.2)
        end
        LoopRunning = false
        CleanupMovers()
    end)
end

--==================================================
-- EXPORT
--==================================================

local function Enable()
    if Enabled then return end
    Enabled = true
    Loop()
    print("[YOKUDO] AutoPlaceEgg: ON")
end

local function Disable()
    Enabled = false
    CleanupMovers()
    print("[YOKUDO] AutoPlaceEgg: OFF")
end

_G.YOKUDO_AutoPlaceEgg = {
    Enable = Enable,
    Disable = Disable,
    IsEnabled = function() return Enabled end,
    SetPlacePosition = function(v3) PlacePos = v3 end,
    GetPlacePosition = function() return PlacePos end,
    SetSpeed = function(v)
        FlySpeed = math.clamp(tonumber(v) or 250, 50, 1100)
    end,
}

print("✅ AutoPlaceEgg Loaded (DropHeldEgg + Fly + Prompts)")
