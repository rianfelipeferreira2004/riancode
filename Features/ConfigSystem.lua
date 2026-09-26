--==================================================
-- YOKUDO HUB - CONFIG SYSTEM
-- Save/Load full hub + AutoExecute no rejoin
-- Folder: YOKUDO-SAE
-- File: yokudo.json
--==================================================

local HttpService = game:GetService("HttpService")

local CONFIG_FOLDER = "YOKUDO-SAE"
local CONFIG_FILE = CONFIG_FOLDER .. "/yokudo.json"

--==================================================
-- DEFAULT CONFIG
--==================================================

local DefaultConfig = {
    SelectedMethod = "TeleportFly",
    TeleportSpeed = 300,
    Rarities = { "Secret", "Eternal", "Divine" },
    AutoEquipBat = false,
    AutoHitPlayer = false,
    AutoAFKFarming = false,
    AutoAttackDrone = false,
    AutoPlaceEgg = false,
    AutoHatch = false,
    HatchRemoteAssist = false,
    WalkSpeedEnabled = false,
    WalkSpeedValue = 50,
    AntiTrap = false,
    AntiAFK = false,
    ManualFastClick = false,
}

--==================================================
-- FILE HELPERS
--==================================================

local function EnsureFolder()
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
    end)
end

local function FileExists(Path)
    local Exists = false
    pcall(function()
        Exists = isfile(Path)
    end)
    return Exists
end

local function CopyRarities(List)
    local Out = {}
    if type(List) == "table" then
        for _, r in ipairs(List) do
            if r == "Secret" or r == "Eternal" or r == "Divine" then
                table.insert(Out, r)
            end
        end
    end
    if #Out == 0 then
        return { "Secret", "Eternal", "Divine" }
    end
    return Out
end

-- Merge + valida: arquivo antigo (só Method+Speed) continua válido
local function NormalizeConfig(Raw)
    local C = {}
    for k, v in pairs(DefaultConfig) do
        if k == "Rarities" then
            C[k] = CopyRarities(v)
        else
            C[k] = v
        end
    end
    if type(Raw) ~= "table" then return C end

    if Raw.SelectedMethod == "TeleportFly" or Raw.SelectedMethod == "InstantTeleport" then
        C.SelectedMethod = Raw.SelectedMethod
    end
    if type(Raw.TeleportSpeed) == "number" then
        C.TeleportSpeed = math.clamp(Raw.TeleportSpeed, 50, 1100)
    end
    if type(Raw.Rarities) == "table" then
        C.Rarities = CopyRarities(Raw.Rarities)
    end
    -- booleanos
    for _, k in ipairs({
        "AutoEquipBat", "AutoHitPlayer", "AutoAFKFarming", "AutoAttackDrone",
        "AutoPlaceEgg", "AutoHatch", "HatchRemoteAssist",
        "WalkSpeedEnabled", "AntiTrap", "AntiAFK", "ManualFastClick",
    }) do
        if type(Raw[k]) == "boolean" then
            C[k] = Raw[k]
        end
    end
    if type(Raw.WalkSpeedValue) == "number" then
        C.WalkSpeedValue = math.clamp(Raw.WalkSpeedValue, 50, 1000)
    end
    return C
end

--==================================================
-- COLLECT CURRENT (lê o estado vivo do hub)
--==================================================

local function SafeIsEnabled(ModuleName)
    local Mod = _G[ModuleName]
    if Mod and type(Mod.IsEnabled) == "function" then
        local Ok, Res = pcall(function() return Mod.IsEnabled() end)
        if Ok then return Res == true end
    end
    return false
end

local function CollectCurrentConfig()
    local C = NormalizeConfig(nil)

    C.SelectedMethod = _G.YOKUDO_SelectedMethod or C.SelectedMethod
    C.TeleportSpeed = _G.YOKUDO_TeleportSpeed or C.TeleportSpeed

    if type(_G.YOKUDO_SelectedRarities) == "table" then
        C.Rarities = CopyRarities(_G.YOKUDO_SelectedRarities)
    end

    do
        local Ok1, R1 = pcall(function() return _G.YOKUDO_AutoAttack.IsAutoEquipEnabled() end)
        if Ok1 and type(R1) == "boolean" then C.AutoEquipBat = R1 end
        local Ok2, R2 = pcall(function() return _G.YOKUDO_AutoAttack.IsAutoHitEnabled() end)
        if Ok2 and type(R2) == "boolean" then C.AutoHitPlayer = R2 end
    end

    C.AutoAFKFarming = SafeIsEnabled("YOKUDO_FarmingManager")
    C.AutoAttackDrone = SafeIsEnabled("YOKUDO_ManagerDrone")
    C.AutoPlaceEgg = SafeIsEnabled("YOKUDO_AutoPlaceEgg")
    C.AutoHatch = SafeIsEnabled("YOKUDO_AutoHatch")
    do
        local Ok, R = pcall(function() return _G.YOKUDO_AutoHatch.IsRemoteAssist() end)
        if Ok and type(R) == "boolean" then C.HatchRemoteAssist = R end
    end
    C.WalkSpeedEnabled = SafeIsEnabled("YOKUDO_WalkSpeed")
    do
        local Ok, V = pcall(function() return _G.YOKUDO_WalkSpeed.GetValue() end)
        if Ok and type(V) == "number" then C.WalkSpeedValue = math.clamp(V, 50, 1000) end
        if _G.YOKUDO_WalkSpeedValue ~= nil and type(_G.YOKUDO_WalkSpeedValue) == "number" then
            C.WalkSpeedValue = math.clamp(_G.YOKUDO_WalkSpeedValue, 50, 1000)
        end
    end
    C.AntiTrap = SafeIsEnabled("YOKUDO_AntiTrap")
    C.AntiAFK = SafeIsEnabled("YOKUDO_AntiAFK")
    C.ManualFastClick = SafeIsEnabled("YOKUDO_ManualFastClick")

    return C
end

--==================================================
-- LOAD CONFIG (arquivo → tabela)
--==================================================

local function LoadConfig()
    EnsureFolder()

    if not FileExists(CONFIG_FILE) then
        print("[YOKUDO] Config not found. Using default.")
        return NormalizeConfig(nil)
    end

    local Success, RawData = pcall(function()
        return readfile(CONFIG_FILE)
    end)

    if not Success or not RawData or RawData == "" then
        print("[YOKUDO] Failed to read config. Using default.")
        return NormalizeConfig(nil)
    end

    local DecodeSuccess, DecodedData = pcall(function()
        return HttpService:JSONDecode(RawData)
    end)

    if not DecodeSuccess or type(DecodedData) ~= "table" then
        print("[YOKUDO] Failed to decode config. Using default.")
        return NormalizeConfig(nil)
    end

    local Config = NormalizeConfig(DecodedData)
    print("[YOKUDO] Config Loaded | Method: " .. Config.SelectedMethod
        .. " | Speed: " .. tostring(Config.TeleportSpeed)
        .. " | Farm: " .. tostring(Config.AutoAFKFarming)
        .. " | Drone: " .. tostring(Config.AutoAttackDrone)
        .. " | Bat: " .. tostring(Config.AutoEquipBat) .. "/" .. tostring(Config.AutoHitPlayer))
    return Config
end

--==================================================
-- SAVE CONFIG
--==================================================

local function SaveConfig(Config)
    EnsureFolder()
    Config = NormalizeConfig(Config)

    local EncodeSuccess, EncodedData = pcall(function()
        return HttpService:JSONEncode(Config)
    end)

    if not EncodeSuccess then
        warn("[YOKUDO] Failed to encode config")
        return false
    end

    local WriteSuccess = pcall(function()
        writefile(CONFIG_FILE, EncodedData)
    end)

    if WriteSuccess then
        print("[YOKUDO] Config Saved")
        return true
    else
        warn("[YOKUDO] Failed to write config")
        return false
    end
end

--==================================================
-- APPLY CONFIG (arquivo → _G, sem ligar nada)
--==================================================

local function ApplyConfig(Config)
    Config = NormalizeConfig(Config)
    _G.YOKUDO_SelectedMethod = Config.SelectedMethod
    _G.YOKUDO_TeleportSpeed = Config.TeleportSpeed
    _G.YOKUDO_SelectedRarities = CopyRarities(Config.Rarities)
    _G.YOKUDO_WalkSpeedValue = Config.WalkSpeedValue

    pcall(function()
        if _G.YOKUDO_TeleportSystem then
            _G.YOKUDO_TeleportSystem.SetMethod(Config.SelectedMethod)
            _G.YOKUDO_TeleportSystem.SetSpeed(Config.TeleportSpeed)
        end
    end)
    pcall(function()
        if _G.YOKUDO_FarmingManager and type(_G.YOKUDO_FarmingManager.SetRarities) == "function" then
            _G.YOKUDO_FarmingManager.SetRarities(CopyRarities(Config.Rarities))
        end
    end)
    pcall(function()
        if _G.YOKUDO_WalkSpeed and type(_G.YOKUDO_WalkSpeed.SetValue) == "function" then
            _G.YOKUDO_WalkSpeed.SetValue(Config.WalkSpeedValue)
        end
    end)
    pcall(function()
        if _G.YOKUDO_AutoHatch and type(_G.YOKUDO_AutoHatch.SetRemoteAssist) == "function" then
            _G.YOKUDO_AutoHatch.SetRemoteAssist(Config.HatchRemoteAssist)
        end
    end)
end

--==================================================
-- REFRESH ALL UI
--==================================================

local function RefreshAllUI()
    task.spawn(function()
        task.wait(0.5)
        pcall(function() if _G.YOKUDO_RefreshSettingUI then _G.YOKUDO_RefreshSettingUI() end end)
        pcall(function() if _G.YOKUDO_RefreshFarmingUI then _G.YOKUDO_RefreshFarmingUI() end end)
        pcall(function() if _G.YOKUDO_RefreshCombatUI then _G.YOKUDO_RefreshCombatUI() end end)
        pcall(function() if _G.YOKUDO_RefreshEventUI then _G.YOKUDO_RefreshEventUI() end end)
        pcall(function() if _G.YOKUDO_RefreshPetUI then _G.YOKUDO_RefreshPetUI() end end)
    end)
end

--==================================================
-- AUTO EXECUTE (rejoin → religa tudo que estava ON)
-- Ordem segura: stats/método → proteções → place/hatch
-- → raridades → bat → farm de ovo → evento.
--==================================================

local function AutoExecute(Config)
    Config = NormalizeConfig(Config or LoadConfig())
    ApplyConfig(Config)

    task.spawn(function()
        print("[YOKUDO] AutoExecute start...")

        -- Espera o character existir antes de ligar voo/farm
        pcall(function()
            local Plr = game:GetService("Players").LocalPlayer
            if Plr and not Plr.Character then
                Plr.CharacterAdded:Wait()
            end
            task.wait(1)
        end)

        -- 1) WalkSpeed
        pcall(function()
            if _G.YOKUDO_WalkSpeed then
                _G.YOKUDO_WalkSpeed.SetValue(Config.WalkSpeedValue)
                if Config.WalkSpeedEnabled then _G.YOKUDO_WalkSpeed.Enable() end
            end
        end)

        -- 2) Proteções / utilidades
        pcall(function() if Config.AntiTrap and _G.YOKUDO_AntiTrap then _G.YOKUDO_AntiTrap.Enable() end end)
        pcall(function() if Config.AntiAFK and _G.YOKUDO_AntiAFK then _G.YOKUDO_AntiAFK.Enable() end end)
        pcall(function() if Config.ManualFastClick and _G.YOKUDO_ManualFastClick then _G.YOKUDO_ManualFastClick.Enable() end end)
        task.wait(0.3)

        -- 3) Place + Hatch
        pcall(function()
            if _G.YOKUDO_AutoHatch then
                _G.YOKUDO_AutoHatch.SetRemoteAssist(Config.HatchRemoteAssist)
                if Config.AutoHatch then _G.YOKUDO_AutoHatch.Enable() end
            end
        end)
        pcall(function() if Config.AutoPlaceEgg and _G.YOKUDO_AutoPlaceEgg then _G.YOKUDO_AutoPlaceEgg.Enable() end end)
        task.wait(0.3)

        -- 4) Raridades do farm de ovo
        pcall(function()
            _G.YOKUDO_SelectedRarities = CopyRarities(Config.Rarities)
            if _G.YOKUDO_FarmingManager then
                _G.YOKUDO_FarmingManager.SetRarities(CopyRarities(Config.Rarities))
            end
            if _G.YOKUDO_ApplyFarmingRarities then
                _G.YOKUDO_ApplyFarmingRarities(CopyRarities(Config.Rarities))
            end
        end)

        -- 5) Bat (já nasce pausado na esteira pelo IsOnTreadmill)
        pcall(function()
            if _G.YOKUDO_AutoAttack then
                if Config.AutoEquipBat then _G.YOKUDO_AutoAttack.EnableAutoEquip() end
                if Config.AutoHitPlayer then _G.YOKUDO_AutoAttack.EnableAutoHit() end
            end
        end)
        task.wait(0.3)

        -- 6) Farm de ovo (assume o AFK/esteira sozinho)
        pcall(function() if Config.AutoAFKFarming and _G.YOKUDO_FarmingManager then _G.YOKUDO_FarmingManager.Enable() end end)
        task.wait(0.5)

        -- 7) Evento (por último: ele divide o AFK com o farm)
        pcall(function() if Config.AutoAttackDrone and _G.YOKUDO_ManagerDrone then _G.YOKUDO_ManagerDrone.Enable() end end)

        print("[YOKUDO] AutoExecute done.")
        RefreshAllUI()
    end)

    return Config
end

--==================================================
-- INITIAL LOAD (só aplica valores, não liga nada)
--==================================================

local LoadedConfig = LoadConfig()
ApplyConfig(LoadedConfig)

--==================================================
-- EXPORT
--==================================================

_G.YOKUDO_ConfigSystem = {
    Folder = CONFIG_FOLDER,
    File = CONFIG_FILE,
    Default = NormalizeConfig(nil),

    Load = function()
        local Config = LoadConfig()
        ApplyConfig(Config)
        RefreshAllUI()
        return Config
    end,

    Save = function()
        return SaveConfig(CollectCurrentConfig())
    end,

    SaveConfig = SaveConfig,
    Get = CollectCurrentConfig,
    Collect = CollectCurrentConfig,
    Apply = ApplyConfig,
    AutoExecute = AutoExecute,
    RefreshUI = RefreshAllUI,

    Reset = function()
        local Def = NormalizeConfig(nil)
        ApplyConfig(Def)
        RefreshAllUI()
        return SaveConfig(Def)
    end,
}

print("✅ ConfigSystem Loaded (full save + autoload + autoexecute)")
