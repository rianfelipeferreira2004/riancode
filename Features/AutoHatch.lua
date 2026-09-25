--==================================================
-- YOKUDO HUB | FEATURE | Auto Hatch
-- Choca ovos no ponto de hatch do mapa.
-- Fisico primeiro (vai ate o hatch + ativa prompts).
-- Remote assist OPT-IN (default OFF): 1 invoke por ciclo,
-- com delay — rajada = assinatura de exploit.
-- ✅ Register manual via _G.YOKUDO_AutoHatch
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local Enabled = false
local RemoteAssist = false
local HatchDelay = 1.0
local LoopRunning = false

local HatchPoint = nil -- Vector3 (descoberto por scan)
local HatchRemote = nil -- RemoteEvent/RemoteFunction (descoberto por scan)
local LastScan = 0

local BodyVelocity = nil
local BodyGyro = nil
local FlyConnection = nil
local FlySpeed = 250

local RemoteVariants = { {}, { 1 }, { "Hatch" }, { "All" } }
local VariantIndex = 0

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
end

local function FlyTo(Destination, Callback)
    CleanupMovers()
    local Hum, Root = GetHum(), GetRoot()
    if not Hum or not Root or Hum.Health <= 0 then
        if Callback then Callback(false) end
        return
    end
    Hum.PlatformStand = true
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "YokudoHatchBV"
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.P = 1250
    BodyVelocity.Velocity = Vector3.zero
    BodyVelocity.Parent = Root
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "YokudoHatchBG"
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

-- Procura ponto de hatch no mapa (nome contem "hatch")
local function ScanHatchPoint()
    local found, foundPos = nil, nil
    pcall(function()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Model") then
                if string.find(string.lower(d.Name), "hatch") then
                    local ok, cf = pcall(function()
                        if d:IsA("Model") then return d:GetPivot() end
                        return d.CFrame
                    end)
                    if ok and cf then
                        found, foundPos = d, (cf + Vector3.new(0, 4, 0)).Position
                        break
                    end
                end
            end
        end
    end)
    HatchPoint = foundPos
    LastScan = tick()
    if found then
        print("[YOKUDO] AutoHatch: ponto achado: " .. found:GetFullName())
    end
    return foundPos
end

-- Procura remote de hatch (1x, com cache). Ignora kick/ban/anti.
local function ScanHatchRemote()
    if HatchRemote and HatchRemote.Parent then return HatchRemote end
    pcall(function()
        for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent") then
                local n = string.lower(d.Name)
                local blocked = string.find(n, "kick") or string.find(n, "ban") or string.find(n, "cheat")
                    or string.find(n, "detect") or string.find(n, "anticheat")
                if not blocked then
                    if string.find(n, "hatch") or string.find(n, "unbox")
                        or string.find(n, "openegg") or string.find(n, "open_egg")
                        or string.find(n, "eggopen") then
                        HatchRemote = d
                        print("[YOKUDO] AutoHatch: remote achado: " .. d:GetFullName())
                        break
                    end
                end
            end
        end
    end)
    return HatchRemote
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

local function SafeFire(remote, args)
    if not remote then return false end
    local ok = false
    pcall(function()
        if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
            remote:FireServer(table.unpack(args))
            ok = true
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(table.unpack(args))
            ok = true
        end
    end)
    return ok
end

--==================================================
-- CICLO UNICO (usado pelo loop E pelo FarmingManager/AFK)
-- 1) prompts onde estou (cobre ovo chocado na plot);
-- 2) voa ao ponto de hatch + prompts + 1 remote opt-in.
--==================================================
local function HatchOnce()
    local Root = GetRoot()
    -- 1) abre o que chocou por perto (ex: na plot apos entregar)
    if Root then
        local n = FirePrompts(Root.Position, 25)
        if n > 0 then
            print("[YOKUDO] AutoHatch: prompts proximos ativados: " .. n)
        end
    end
    -- 2) ponto de hatch
    if not HatchPoint and tick() - LastScan > 30 then
        ScanHatchPoint()
    end
    if not HatchPoint then return false end
    local R = GetRoot()
    if R and (R.Position - HatchPoint).Magnitude > 12 then
        local Arrived = false
        FlyTo(HatchPoint, function(ok) Arrived = ok end)
        local Waited = 0
        while not Arrived and Waited < 35 and Enabled do
            task.wait(0.5)
            Waited = Waited + 0.5
        end
        if not Arrived then return false end
        R = GetRoot()
    end
    if not Enabled then return false end
    local n = FirePrompts(HatchPoint, 20)
    if n > 0 then
        print("[YOKUDO] AutoHatch: prompts ativados: " .. n)
    end
    if RemoteAssist then
        local r = ScanHatchRemote()
        if r then
            VariantIndex = (VariantIndex % #RemoteVariants) + 1
            SafeFire(r, RemoteVariants[VariantIndex])
            task.wait(0.3)
        end
    end
    return true
end

--==================================================
-- MAIN LOOP
--==================================================

local function Loop()
    if LoopRunning then return end
    LoopRunning = true
    task.spawn(function()
        while Enabled do
            if not HatchPoint and tick() - LastScan > 30 then
                ScanHatchPoint()
                if not HatchPoint then
                    print("[YOKUDO] AutoHatch: ponto de hatch nao achado, tentando de novo em 30s")
                end
            end
            if HatchPoint then
                HatchOnce()
            end
            task.wait(math.clamp(HatchDelay, 0.3, 10))
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
    ScanHatchPoint()
    if RemoteAssist then ScanHatchRemote() end
    Loop()
    print("[YOKUDO] AutoHatch: ON (remote assist " .. (RemoteAssist and "ON" or "OFF") .. ")")
end

local function Disable()
    Enabled = false
    CleanupMovers()
    print("[YOKUDO] AutoHatch: OFF")
end

_G.YOKUDO_AutoHatch = {
    Enable = Enable,
    Disable = Disable,
    IsEnabled = function() return Enabled end,
    HatchOnce = HatchOnce,
    SetRemoteAssist = function(v) RemoteAssist = v and true or false end,
    IsRemoteAssist = function() return RemoteAssist end,
    SetDelay = function(v) HatchDelay = math.clamp(tonumber(v) or 1, 0.3, 10) end,
    SetHatchPoint = function(v3) HatchPoint = v3 end,
    ScanNow = function()
        ScanHatchPoint()
        ScanHatchRemote()
        return HatchPoint, HatchRemote
    end,
}

print("✅ AutoHatch Loaded (fisico + remote opt-in)")
