--==================================================
-- YOKUDO HUB - TELEPORT SYSTEM (DUAL MODE + DUAL OPTION + RECOVERY)
-- First Egg: FlyTP (Shot TP)
-- Target Egg: FlyTP (Shot TP) / Instant
-- Safe Zone: FlyTP (No Shot TP) + BodyV/G
-- Recovery: Tween Teleport (No Limit)
-- ✅ DropHeldEgg Check
-- ✅ Safe Zone: Reset State + Stop ភ្លាមៗ
-- ✅ Tween ប្រើតែ Recovery
-- ✅ Recovery គ្មាន Limit
-- ✅ Sequence Number → ការពារ Race Condition (មិន Stuck ពេលធីកលឿន)
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Container = workspace:WaitForChild("AreaEggSlotsClient")

--==================================================
-- REMOTES
--==================================================

local CollectEvent = nil
local ForestStrike = nil

pcall(function()
    CollectEvent = ReplicatedStorage.Packages.Networking["RF/EggWorld/AskFieldEggCarry"]
end)

pcall(function()
    ForestStrike = ReplicatedStorage.Packages.Networking["RE/GuardPatrol/ForestStrike"]
end)

if not CollectEvent then
    warn("[YOKUDO] CollectEvent not found")
    return
end

print("[YOKUDO] TeleportSystem: CollectEvent OK")

--==================================================
-- SETTINGS
--==================================================

local TARGET_UID = nil
local SAFE_ZONE = Vector3.new(533, 70, -366)

local FLY_SPEED = 300
local RETURN_SPEED = 300

local CurrentMethod = "TeleportFly"

local FLY_OFFSET = 5
local SHOT_DISTANCE = 30
local LOCK_ABOVE = 2

local ARRIVE_DISTANCE = 2
local SAFE_LOCK_DISTANCE = 3
local TIMEOUT_SECONDS = 30

local COLLECT_INTERVAL = 0.2
local SEARCH_PREFIX = "FirstAreaEgg"
local POSITION_THRESHOLD = 1

local TWEEN_DURATION = 0.50
local NEAR_OFFSET = 20
local TARGET_COLLECT_TIMEOUT = 15

local LOCK_POSITION = Vector3.new(
    607.6259155273438,
    70.57420349121094,
    -326.8830261230469
)

--==================================================
-- ✅ SEQUENCE NUMBER (ការពារ Race Condition)
--==================================================

local RunSequence = 0

--==================================================
-- RAGDOLL BYPASS STATE
--==================================================

local RagdollEnabled = false
local RagdollConnection = nil
local ForceUpConnection = nil

--==================================================
-- DROPHELDEGG STATE
--==================================================

local PlayerGui = nil
local DropHeldEgg = nil
local DropHeldEggConnection = nil
local LastDropState = false

--==================================================
-- STATE
--==================================================

local Running = false
local CurrentStep = "idle"
local CurrentMode = "none"

local FlyConnection = nil
local BodyVelocity = nil
local BodyGyro = nil
local ActiveHeartbeat = nil
local LockConnection = nil

local FirstEggList = {}
local FirstEggUid = nil
local FirstEggSlotKey = nil

local CollectAttempts = 0
local CollectTime = 0
local TargetCollectStartTime = 0

local FlyTargetStarted = false
local CollectDone = false
local TargetCollected = false
local RemotesFired = false
local RecoveryTriggered = false
local RecoveryAttempts = 0

local SavedTargetPosition = nil
local TargetLockedCFrame = nil

local SavedWalkSpeed = nil
local SavedJumpPower = nil
local SavedJumpHeight = nil
local SavedUseJumpPower = nil

--==================================================
-- FORWARD DECLARATIONS
--==================================================

local CleanupMovers
local DisableRagdollBypass
local StopActiveHeartbeat
local RestoreStats
local AutoStop
local FlyToTargetAgain
local FlyToSafeZone
local StartFlyToTarget
local StartActiveHeartbeat
local StartProcess

--==================================================
-- GET HUMANOID
--==================================================

local function GetHumanoid()
    local Char = Player.Character
    if not Char then return nil, nil end
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    local Root = Char:FindFirstChild("HumanoidRootPart")
    return Hum, Root
end

--==================================================
-- RAGDOLL BYPASS
--==================================================

local function ForceUp()
    local Hum, Root = GetHumanoid()
    if not Hum or not Root then return end

    pcall(function()
        if Hum:GetState() == Enum.HumanoidStateType.Physics then
            Hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end

        Hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        Hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

        Hum.PlatformStand = false
        Hum.Sit = false

        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero

        Root.CanCollide = true

        Hum.BreakJointsOnDeath = false
        Hum.RequiresNeck = false
    end)
end

local function CleanupRagdollConstraints()
    local Char = Player.Character
    if not Char then return end

    pcall(function()
        for _, descendant in ipairs(Char:GetDescendants()) do
            if descendant.Name:find("RagdollConstraint") then
                descendant:Destroy()
            end
            if descendant.Name:find("RagdollAttachment") then
                descendant:Destroy()
            end
        end

        for _, descendant in ipairs(Char:GetDescendants()) do
            if descendant:IsA("Motor6D") then
                descendant.Enabled = true
            end
        end
    end)
end

local function EnableRagdollBypass()
    if RagdollEnabled then return end
    RagdollEnabled = true

    RagdollConnection = RunService.Heartbeat:Connect(function()
        if not RagdollEnabled then return end
        ForceUp()
    end)

    ForceUpConnection = task.spawn(function()
        while RagdollEnabled do
            task.wait(0.1)
            ForceUp()
            CleanupRagdollConstraints()
        end
    end)

    print("[YOKUDO] Ragdoll Bypass: ON")
end

DisableRagdollBypass = function()
    if not RagdollEnabled then return end
    RagdollEnabled = false

    if RagdollConnection then
        RagdollConnection:Disconnect()
        RagdollConnection = nil
    end

    print("[YOKUDO] Ragdoll Bypass: OFF")
end

--==================================================
-- SAVE / RESTORE STATS
--==================================================

local function SaveStats()
    local Hum = GetHumanoid()
    if not Hum then return end

    if SavedWalkSpeed == nil then SavedWalkSpeed = Hum.WalkSpeed end
    if SavedJumpPower == nil then SavedJumpPower = Hum.JumpPower end
    if SavedJumpHeight == nil then SavedJumpHeight = Hum.JumpHeight end
    if SavedUseJumpPower == nil then SavedUseJumpPower = Hum.UseJumpPower end
end

RestoreStats = function()
    local Hum = GetHumanoid()
    if not Hum then return end

    if SavedWalkSpeed ~= nil then pcall(function() Hum.WalkSpeed = SavedWalkSpeed end) end
    if SavedJumpPower ~= nil then pcall(function() Hum.JumpPower = SavedJumpPower end) end
    if SavedJumpHeight ~= nil then pcall(function() Hum.JumpHeight = SavedJumpHeight end) end
    if SavedUseJumpPower ~= nil then pcall(function() Hum.UseJumpPower = SavedUseJumpPower end) end
end

--==================================================
-- CLEANUP
--==================================================

CleanupMovers = function()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if LockConnection then
        LockConnection:Disconnect()
        LockConnection = nil
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
        pcall(function()
            BodyGyro.MaxTorque = Vector3.zero
        end)
        BodyGyro:Destroy()
        BodyGyro = nil
    end

    local Hum, Root = GetHumanoid()
    if Root then
        for _, Child in ipairs(Root:GetChildren()) do
            if Child.Name == "YokudoBV" or Child.Name == "YokudoBG" then
                pcall(function() Child:Destroy() end)
            end
        end
    end

    if Hum then
        pcall(function()
            Hum.PlatformStand = false
            Hum.Sit = false
        end)
    end

    if Root then
        pcall(function()
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

--==================================================
-- LOCK AT TARGET (Y+2)
--==================================================

local function StartLock(TargetPosition)
    if not TargetPosition then return end

    TargetLockedCFrame = CFrame.new(TargetPosition + Vector3.new(0, LOCK_ABOVE, 0))

    if LockConnection then
        LockConnection:Disconnect()
    end

    LockConnection = RunService.Heartbeat:Connect(function()
        if not Running then
            if LockConnection then LockConnection:Disconnect() LockConnection = nil end
            return
        end

        local Hum, Root = GetHumanoid()
        if not Root then return end

        Root.CFrame = TargetLockedCFrame
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end)
end

--==================================================
-- GET POSITION
--==================================================

local function GetPosition(Object)
    if not Object then return nil end
    if Object:IsA("Model") then
        if Object.PrimaryPart then return Object.PrimaryPart.Position end
        local Part = Object:FindFirstChildWhichIsA("BasePart")
        if Part then return Part.Position end
        for _, Desc in ipairs(Object:GetDescendants()) do
            if Desc:IsA("BasePart") then return Desc.Position end
        end
    elseif Object:IsA("BasePart") then
        return Object.Position
    end
    return nil
end

--==================================================
-- SETUP DROPHELDEGG
--==================================================

local function SetupDropHeldEgg()
    PlayerGui = Player:FindFirstChild("PlayerGui")
    if not PlayerGui then
        PlayerGui = Player:WaitForChild("PlayerGui", 5)
    end

    if not PlayerGui then
        warn("[YOKUDO] PlayerGui not found!")
        return
    end

    DropHeldEgg = PlayerGui:FindFirstChild("DropHeldEgg")
    if not DropHeldEgg then
        warn("[YOKUDO] DropHeldEgg not found!")
        return
    end

    LastDropState = DropHeldEgg.Enabled
    print("[YOKUDO] DropHeldEgg found | Enabled: " .. tostring(DropHeldEgg.Enabled))

    if DropHeldEggConnection then
        DropHeldEggConnection:Disconnect()
        DropHeldEggConnection = nil
    end

    DropHeldEggConnection = DropHeldEgg:GetPropertyChangedSignal("Enabled"):Connect(function()
        print("[YOKUDO] DropHeldEgg.Enabled changed: " .. tostring(LastDropState) .. " → " .. tostring(DropHeldEgg.Enabled))
        LastDropState = DropHeldEgg.Enabled
    end)
end

--==================================================
-- CHECK TARGET COLLECTED
--==================================================

local function IsTargetCollectedByDropHeldEgg()
    if not DropHeldEgg then return false end
    return DropHeldEgg.Enabled == true
end

--==================================================
-- SEARCH FIRST EGGS
--==================================================

local function SearchFirstEggs()
    FirstEggList = {}
    if not Container then return end

    for _, Slot in ipairs(Container:GetChildren()) do
        if string.find(Slot.Name, SEARCH_PREFIX) then
            local SlotNum = string.match(Slot.Name, "Slot_(%d+)")
            if SlotNum then
                table.insert(FirstEggList, {
                    Slot = Slot,
                    Uid = Slot.Name,
                    SlotKey = "Forest:Slot_" .. SlotNum,
                    SlotNum = tonumber(SlotNum)
                })
            end
        end
    end
end

local function FindClosestEgg()
    local Hum, Root = GetHumanoid()
    if not Root then return nil end

    local Closest = nil
    local ClosestDistance = 9999

    for _, Egg in ipairs(FirstEggList) do
        local Pos = GetPosition(Egg.Slot)
        if Pos then
            local Dist = (Pos - Root.Position).Magnitude
            if Dist < ClosestDistance then
                ClosestDistance = Dist
                Closest = Egg
            end
        end
    end

    if Closest then
        FirstEggUid = Closest.Uid
        FirstEggSlotKey = Closest.SlotKey
    end

    return Closest
end

--==================================================
-- ✅ FLY TP (Sequence Number + Disconnect ភ្លាម)
--==================================================

local function FlyTP(Destination, Speed, UseShotTP, IsSafeZone, Callback)
    -- ✅ បង្កើន Sequence
    RunSequence = RunSequence + 1
    local CurrentSequence = RunSequence

    CleanupMovers()

    local Hum, Root = GetHumanoid()
    if not Hum or not Root then return end
    if Hum.Health <= 0 then return end

    local FlyPos = Vector3.new(Destination.X, Destination.Y + FLY_OFFSET, Destination.Z)
    local LockCFrame = CFrame.new(Destination + Vector3.new(0, LOCK_ABOVE, 0))

    Hum.PlatformStand = true

    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "YokudoBV"
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.P = 1250
    BodyVelocity.Velocity = Vector3.zero
    BodyVelocity.Parent = Root

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "YokudoBG"
    BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    BodyGyro.P = 3000
    BodyGyro.D = 500
    BodyGyro.CFrame = Root.CFrame
    BodyGyro.Parent = Root

    local StartTime = tick()
    local ShotDone = false

    FlyConnection = RunService.Heartbeat:Connect(function()
        -- ✅ ពិនិត្យ Sequence (ការពារ Race Condition)
        if CurrentSequence ~= RunSequence then
            if FlyConnection then
                FlyConnection:Disconnect()
                FlyConnection = nil
            end
            return
        end

        if not Running then
            CleanupMovers()
            return
        end

        local Hum2, Root2 = GetHumanoid()
        if not Hum2 or not Root2 then
            CleanupMovers()
            return
        end
        if Hum2.Health <= 0 then return end

        if not BodyVelocity or not BodyGyro then
            CleanupMovers()
            return
        end

        local CurrentPos = Root2.Position
        local Direction = (FlyPos - CurrentPos)
        local HorizDist = Vector3.new(Direction.X, 0, Direction.Z).Magnitude
        local VertDist = math.abs(Direction.Y)
        local TotalDist = Direction.Magnitude

        -- ✅ Safe Zone: No Shot TP — Disconnect ភ្លាម
        if IsSafeZone then
            if HorizDist <= SAFE_LOCK_DISTANCE then
                if BodyVelocity then
                    BodyVelocity.Velocity = Vector3.zero
                    BodyVelocity.MaxForce = Vector3.zero
                end
                if BodyGyro then
                    BodyGyro.MaxTorque = Vector3.zero
                end

                if FlyConnection then
                    FlyConnection:Disconnect()
                    FlyConnection = nil
                end

                CleanupMovers()
                Root2.CFrame = LockCFrame
                Root2.AssemblyLinearVelocity = Vector3.zero
                Root2.AssemblyAngularVelocity = Vector3.zero
                StartLock(Destination)

                task.defer(function()
                    if Callback then Callback() end
                end)
                return
            end
        end

        -- ✅ Shot TP — Disconnect ភ្លាម
        if not IsSafeZone and UseShotTP and not ShotDone and HorizDist <= SHOT_DISTANCE then
            ShotDone = true

            if BodyVelocity then
                BodyVelocity.Velocity = Vector3.zero
                BodyVelocity.MaxForce = Vector3.zero
            end
            if BodyGyro then
                BodyGyro.MaxTorque = Vector3.zero
            end

            if FlyConnection then
                FlyConnection:Disconnect()
                FlyConnection = nil
            end

            CleanupMovers()
            Root2.CFrame = LockCFrame
            Root2.AssemblyLinearVelocity = Vector3.zero
            Root2.AssemblyAngularVelocity = Vector3.zero
            StartLock(Destination)

            task.defer(function()
                if Callback then Callback() end
            end)
            return
        end

        -- Arrived fallback
        if HorizDist <= ARRIVE_DISTANCE and VertDist <= 2 then
            if BodyVelocity then
                BodyVelocity.Velocity = Vector3.zero
                BodyVelocity.MaxForce = Vector3.zero
            end
            if BodyGyro then
                BodyGyro.MaxTorque = Vector3.zero
            end

            if FlyConnection then
                FlyConnection:Disconnect()
                FlyConnection = nil
            end

            CleanupMovers()
            Root2.CFrame = LockCFrame
            Root2.AssemblyLinearVelocity = Vector3.zero
            Root2.AssemblyAngularVelocity = Vector3.zero
            StartLock(Destination)

            task.defer(function()
                if Callback then Callback() end
            end)
            return
        end

        -- Timeout
        if tick() - StartTime > TIMEOUT_SECONDS then
            CleanupMovers()
            if Callback then Callback() end
            return
        end

        if TotalDist > 1 then
            BodyVelocity.Velocity = Direction.Unit * Speed
        else
            BodyVelocity.Velocity = Vector3.zero
        end

        BodyGyro.CFrame = CFrame.new(CurrentPos, CurrentPos + Vector3.new(Direction.X, 0, Direction.Z))
    end)
end

--==================================================
-- INSTANT FLY TP
--==================================================

local function InstantFlyTP(Destination, Callback)
    -- ✅ បង្កើន Sequence
    RunSequence = RunSequence + 1

    CleanupMovers()

    local Hum, Root = GetHumanoid()
    if not Hum or not Root then return end
    if Hum.Health <= 0 then return end

    local LockCFrame = CFrame.new(Destination + Vector3.new(0, LOCK_ABOVE, 0))

    Root.CFrame = LockCFrame
    Root.AssemblyLinearVelocity = Vector3.zero
    Root.AssemblyAngularVelocity = Vector3.zero

    StartLock(Destination)

    if Callback then Callback() end
end

--==================================================
-- ✅ TWEEN TELEPORT (សម្រាប់ RECOVERY តែប៉ុណ្ណោះ)
--==================================================

local function TweenTP(Destination, Callback)
    -- ✅ បង្កើន Sequence
    RunSequence = RunSequence + 1

    CleanupMovers()

    local Hum, Root = GetHumanoid()
    if not Hum or not Root then return end
    if Hum.Health <= 0 then return end

    Hum.PlatformStand = true

    local Direction = (Destination - Root.Position).Unit
    local NearPos = Destination - (Direction * NEAR_OFFSET)

    local TweenInfoObj = TweenInfo.new(TWEEN_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local Tween = TweenService:Create(Root, TweenInfoObj, {
        CFrame = CFrame.new(NearPos, Destination)
    })

    Tween:Play()
    Tween.Completed:Wait()

    FlyTP(Destination, FLY_SPEED, true, false, Callback)
end

--==================================================
-- TELEPORT TO TARGET (Option Specific)
--==================================================

local function TeleportToTarget(TargetPos, Callback)
    if CurrentMethod == "InstantTeleport" then
        print("[YOKUDO] Instant TP to Target")
        InstantFlyTP(TargetPos, Callback)
    else
        print("[YOKUDO] FlyTP to Target (Shot TP)")
        FlyTP(TargetPos, FLY_SPEED, true, false, Callback)
    end
end

--==================================================
-- REMOTE COLLECT
--==================================================

local function RemoteCollectFirst()
    if not CollectEvent or not FirstEggSlotKey or not FirstEggUid then return false end
    local success = pcall(function()
        return CollectEvent:InvokeServer({
            FirstAreaSlotKey = FirstEggSlotKey,
            Uid = FirstEggUid
        })
    end)
    return success
end

local function RemoteCollectTarget()
    if not CollectEvent or not TARGET_UID then return false end
    local success = pcall(function()
        return CollectEvent:InvokeServer({
            Uid = TARGET_UID
        })
    end)
    return success
end

--==================================================
-- FIRE FOREST STRIKE
--==================================================

local function FireForestStrike()
    if RemotesFired then return end
    RemotesFired = true

    EnableRagdollBypass()

    pcall(function()
        ForestStrike:FireServer({
            EggUid = FirstEggUid,
            GuardCFrame = CFrame.new(LOCK_POSITION)
        })
    end)

    task.spawn(function()
        for i = 1, 10 do
            task.wait(0.05)
            ForceUp()
            CleanupRagdollConstraints()
        end
    end)

    print("[YOKUDO] ForestStrike Fired (Only Once per First Egg)")
end

--==================================================
-- CHECK EGG
--==================================================

local function IsFirstEggInWorkspace()
    if not FirstEggUid then return false end
    return workspace:FindFirstChild(FirstEggUid) ~= nil
end

local function IsFirstEggInContainer()
    if not FirstEggUid then return false end
    if not Container then return false end
    return Container:FindFirstChild(FirstEggUid) ~= nil
end

local function IsTargetInContainer()
    if not TARGET_UID or not Container then return false end
    return Container:FindFirstChild(TARGET_UID) ~= nil
end

local function IsTargetInWorkspace()
    if not TARGET_UID then return false end
    return workspace:FindFirstChild(TARGET_UID) ~= nil
end

--==================================================
-- ✅ AUTO STOP (Reset State + Sequence++)
--==================================================

AutoStop = function()
    Running = false
    CurrentStep = "done"

    -- ✅ បង្កើន Sequence ដើម្បីបញ្ឈប់ FlyConnection ទាំងអស់
    RunSequence = RunSequence + 1

    CleanupMovers()
    DisableRagdollBypass()
    StopActiveHeartbeat()
    RestoreStats()

    -- ✅ Reset State ទាំងអស់
    FirstEggList = {}
    FirstEggUid = nil
    FirstEggSlotKey = nil
    CollectAttempts = 0
    CollectTime = 0
    TargetCollectStartTime = 0
    FlyTargetStarted = false
    CollectDone = false
    TargetCollected = false
    RemotesFired = false
    RecoveryTriggered = false
    RecoveryAttempts = 0
    SavedTargetPosition = nil
    TargetLockedCFrame = nil

    print("[YOKUDO] TeleportSystem: Auto Stop + Reset State")
end

--==================================================
-- FLY TO TARGET
--==================================================

StartFlyToTarget = function()
    if FlyTargetStarted then return end
    FlyTargetStarted = true

    CurrentStep = "to_target"

    local TargetPos = nil

    if CurrentMode == "spawn" then
        local TargetEgg = Container and Container:FindFirstChild(TARGET_UID)
        if TargetEgg then
            TargetPos = GetPosition(TargetEgg)
        end
    elseif CurrentMode == "workspace" then
        if SavedTargetPosition then
            TargetPos = SavedTargetPosition
        else
            local WSEgg = workspace:FindFirstChild(TARGET_UID)
            if WSEgg then
                TargetPos = GetPosition(WSEgg)
                SavedTargetPosition = TargetPos
            end
        end
    end

    if not TargetPos then
        AutoStop()
        return
    end

    TeleportToTarget(TargetPos, function()
        TargetCollected = false
        CollectTime = 0
        CollectAttempts = 0
        RecoveryTriggered = false
        TargetCollectStartTime = tick()
        CurrentStep = "collect_target"
    end)
end

--==================================================
-- ✅ FLY TO TARGET AGAIN (Recovery — Tween, No Limit)
--==================================================

FlyToTargetAgain = function()
    RecoveryAttempts = RecoveryAttempts + 1

    print("[YOKUDO] ⚠️ Egg Dropped → Recovery #" .. RecoveryAttempts .. " (Tween Teleport)")
    CurrentStep = "recovery"

    -- ✅ ១. Stop BodyV/G ភ្លាម
    if BodyVelocity then
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.zero
    end
    if BodyGyro then
        BodyGyro.MaxTorque = Vector3.zero
    end

    -- ✅ ២. រក TargetPos
    local TargetPos = nil

    if IsTargetInContainer() then
        CurrentMode = "spawn"
        local TargetEgg = Container:FindFirstChild(TARGET_UID)
        if TargetEgg then
            TargetPos = GetPosition(TargetEgg)
        end
    elseif IsTargetInWorkspace() then
        CurrentMode = "workspace"
        local WSEgg = workspace:FindFirstChild(TARGET_UID)
        if WSEgg then
            TargetPos = GetPosition(WSEgg)
            SavedTargetPosition = TargetPos
        end
    else
        print("[YOKUDO] ✅ Target Gone (Both) → AutoStop")
        AutoStop()
        return
    end

    if not TargetPos then
        print("[YOKUDO] Target Pos not found → AutoStop")
        AutoStop()
        return
    end

    -- ✅ ៣. Tween Teleport ទៅ Target
    RecoveryTriggered = false
    TargetCollected = false

    print("[YOKUDO] Recovery Tween → FlyTP to Target")
    TweenTP(TargetPos, function()
        print("[YOKUDO] ✅ Recovery #" .. RecoveryAttempts .. " Arrived → collect_target")

        TargetCollected = false
        CollectTime = 0
        CollectAttempts = 0
        RecoveryTriggered = false
        RemotesFired = false
        TargetCollectStartTime = tick()

        CurrentStep = "collect_target"
    end)
end

--==================================================
-- FLY TO SAFE (NO SHOT TP — BodyV/G)
--==================================================

FlyToSafeZone = function()
    CurrentStep = "to_safe"

    print("[YOKUDO] FlyTP to Safe Zone (No Shot TP, BodyV/G)")

    FlyTP(SAFE_ZONE, RETURN_SPEED, false, true, function()
        AutoStop()
    end)
end

--==================================================
-- HEARTBEAT
--==================================================

StartActiveHeartbeat = function()
    if ActiveHeartbeat then
        ActiveHeartbeat:Disconnect()
        ActiveHeartbeat = nil
    end

    ActiveHeartbeat = RunService.Heartbeat:Connect(function()
        if not Running then return end

        local Hum, Root = GetHumanoid()
        if not Hum or not Root then return end
        if Hum.Health <= 0 then return end

        -- Step 1: Collect First Egg
        if CurrentStep == "collect_first" and not CollectDone then
            if IsFirstEggInWorkspace() then
                CollectDone = true
                FireForestStrike()
                CurrentStep = "wait_spawn_back"
                return
            end

            if tick() - CollectTime > COLLECT_INTERVAL then
                CollectTime = tick()

                if IsFirstEggInContainer() then
                    RemoteCollectFirst()
                    CollectAttempts = CollectAttempts + 1
                else
                    if IsFirstEggInWorkspace() then
                        CollectDone = true
                        FireForestStrike()
                        CurrentStep = "wait_spawn_back"
                    end
                end
            end
        end

        -- Step 2: Wait First Egg Spawn Back
        if CurrentStep == "wait_spawn_back" and not FlyTargetStarted then
            if IsFirstEggInContainer() then
                task.spawn(function() StartFlyToTarget() end)
            end
        end

        -- Step 3: Collect Target Egg (DropHeldEgg + Mode ដើម)
        if CurrentStep == "collect_target" and not TargetCollected then

            -- ✅ DropHeldEgg Check
            if IsTargetCollectedByDropHeldEgg() then
                print("[YOKUDO] ✅ DropHeldEgg.Enabled = true → Target Collected!")
                TargetCollected = true
                RecoveryTriggered = false
                task.spawn(function() FlyToSafeZone() end)
                return
            end

            -- ✅ Mode ដើម
            if CurrentMode == "spawn" then
                if workspace:FindFirstChild(TARGET_UID) then
                    TargetCollected = true
                    RecoveryTriggered = false
                    task.spawn(function() FlyToSafeZone() end)
                    return
                end
            elseif CurrentMode == "workspace" then
                if SavedTargetPosition then
                    local WSEgg = workspace:FindFirstChild(TARGET_UID)
                    if WSEgg then
                        local CurrentPos = GetPosition(WSEgg)
                        if CurrentPos then
                            local Dist = (CurrentPos - SavedTargetPosition).Magnitude
                            if Dist >= POSITION_THRESHOLD then
                                TargetCollected = true
                                RecoveryTriggered = false
                                task.spawn(function() FlyToSafeZone() end)
                                return
                            end
                        end
                    end
                end
            end

            -- ✅ បន្ត Collect
            if tick() - CollectTime > COLLECT_INTERVAL then
                CollectTime = tick()
                RemoteCollectTarget()
                CollectAttempts = CollectAttempts + 1
            end

            -- ✅ Timeout → Recovery
            if tick() - TargetCollectStartTime > TARGET_COLLECT_TIMEOUT then
                print("[YOKUDO] ⚠️ Target Collect Timeout → Recovery")
                if not RecoveryTriggered then
                    RecoveryTriggered = true
                    task.spawn(function() FlyToTargetAgain() end)
                end
                return
            end
        end

        -- Step 4: Recovery (Egg Drop តាមផ្លូវ)
        if CurrentStep == "to_safe" then
            if not IsTargetCollectedByDropHeldEgg() then
                if not RecoveryTriggered then
                    RecoveryTriggered = true
                    print("[YOKUDO] ⚠️ Egg Dropped on Way → Recovery!")
                    task.spawn(function() FlyToTargetAgain() end)
                end
                return
            else
                RecoveryTriggered = false
            end
        end
    end)
end

StopActiveHeartbeat = function()
    if ActiveHeartbeat then
        ActiveHeartbeat:Disconnect()
        ActiveHeartbeat = nil
    end
end

--==================================================
-- MAIN PROCESS
--==================================================

StartProcess = function()
    -- ✅ បង្កើន Sequence
    RunSequence = RunSequence + 1

    Running = true
    CurrentStep = "search"

    CollectAttempts = 0
    CollectTime = 0
    TargetCollectStartTime = 0
    FlyTargetStarted = false
    CollectDone = false
    TargetCollected = false
    RemotesFired = false
    RecoveryTriggered = false
    RecoveryAttempts = 0
    SavedTargetPosition = nil
    TargetLockedCFrame = nil
    LastDropState = false

    SetupDropHeldEgg()

    SaveStats()
    EnableRagdollBypass()

    if IsTargetInContainer() then
        CurrentMode = "spawn"
        print("[YOKUDO] Target found in Container → spawn mode")
    elseif IsTargetInWorkspace() then
        CurrentMode = "workspace"
        local WSEgg = workspace:FindFirstChild(TARGET_UID)
        if WSEgg then
            SavedTargetPosition = GetPosition(WSEgg)
        end
        print("[YOKUDO] Target found in Workspace → workspace mode")
    else
        local WaitTime = 0
        while Running and not IsTargetInContainer() and not IsTargetInWorkspace() do
            task.wait(0.5)
            WaitTime = WaitTime + 0.5
            if WaitTime > 60 then
                AutoStop()
                return
            end
        end

        if IsTargetInContainer() then
            CurrentMode = "spawn"
        elseif IsTargetInWorkspace() then
            CurrentMode = "workspace"
            local WSEgg = workspace:FindFirstChild(TARGET_UID)
            if WSEgg then
                SavedTargetPosition = GetPosition(WSEgg)
            end
        end
    end

    SearchFirstEggs()

    if #FirstEggList == 0 then
        AutoStop()
        return
    end

    local Closest = FindClosestEgg()

    if not Closest then
        AutoStop()
        return
    end

    local EggPos = GetPosition(Closest.Slot)
    if not EggPos then
        AutoStop()
        return
    end

    CurrentStep = "fly_first"

    StartActiveHeartbeat()

    print("[YOKUDO] FlyTP to First Egg (Shot TP)")
    FlyTP(EggPos, FLY_SPEED, true, false, function()
        CollectDone = false
        CollectTime = 0
        CurrentStep = "collect_first"
    end)
end

--==================================================
-- ✅ FULL RESET (Sequence++ — ការពារ Race)
--==================================================

local function FullReset()
    Running = false
    CurrentStep = "idle"
    CurrentMode = "none"

    -- ✅ បង្កើន Sequence ដើម្បីបញ្ឈប់ Thread ទាំងអស់
    RunSequence = RunSequence + 1

    FirstEggList = {}
    FirstEggUid = nil
    FirstEggSlotKey = nil
    CollectAttempts = 0
    CollectTime = 0
    TargetCollectStartTime = 0
    FlyTargetStarted = false
    CollectDone = false
    TargetCollected = false
    RemotesFired = false
    RecoveryTriggered = false
    RecoveryAttempts = 0
    SavedTargetPosition = nil
    TargetLockedCFrame = nil
    LastDropState = false

    if DropHeldEggConnection then
        DropHeldEggConnection:Disconnect()
        DropHeldEggConnection = nil
    end
    DropHeldEgg = nil
    PlayerGui = nil

    if CleanupMovers then CleanupMovers() end
    if DisableRagdollBypass then DisableRagdollBypass() end
    if StopActiveHeartbeat then StopActiveHeartbeat() end
    if RestoreStats then RestoreStats() end

    print("[YOKUDO] TeleportSystem: Full Reset")
end

--==================================================
-- ENABLE / DISABLE / SET TARGET / SET SPEED / SET METHOD
--==================================================

local function Enable()
    if Running then return end
    if not CollectEvent then warn("[YOKUDO] CollectEvent not found") return end
    if not TARGET_UID then warn("[YOKUDO] No Target ID") return end

    FullReset()
    StartProcess()

    print("[YOKUDO] TeleportSystem: ON | Method: " .. CurrentMethod)
end

local function Disable()
    FullReset()
    print("[YOKUDO] TeleportSystem: OFF")
end

local function SetTargetId(Id)
    TARGET_UID = Id
    print("[YOKUDO] TeleportSystem Target ID: " .. tostring(Id))
end

local function SetSpeed(Value)
    Value = math.clamp(Value, 50, 1100)
    FLY_SPEED = Value
    RETURN_SPEED = Value
    print("[YOKUDO] TeleportSystem Speed: " .. tostring(Value))
end

local function SetMethod(Method)
    if Method == "InstantTeleport" then
        CurrentMethod = "InstantTeleport"
    else
        CurrentMethod = "TeleportFly"
    end
    print("[YOKUDO] TeleportSystem Method: " .. CurrentMethod)
end

local function GetMethod()
    return CurrentMethod
end

local function GetSpeed()
    return FLY_SPEED
end

--==================================================
-- EXPORT
--==================================================

_G.YOKUDO_TeleportSystem = {
    Enable = Enable,
    Disable = Disable,
    SetTargetId = SetTargetId,
    SetSpeed = SetSpeed,
    SetMethod = SetMethod,
    GetMethod = GetMethod,
    GetSpeed = GetSpeed,
    IsEnabled = function() return Running end,
    GetTargetId = function() return TARGET_UID end
}

print("✅ TeleportSystem Loaded (Dual Mode + Dual Option + DropHeldEgg + Recovery Tween No Limit + Safe Zone Stop + Sequence Number)")
