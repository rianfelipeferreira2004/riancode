--[[ 
    Chilli Hub | Steal an Egg — Versão Limpa Rayfield + Save Config
    ----------------------------------------------------------------
    Origem: https://raw.githubusercontent.com/tienkhanh1/Chilli-Hub-Script/refs/heads/main/StealAnEgg
    Formato original: Luraph Obfuscator v15.0 (~1.58 MB, VM + constantes criptografadas)
    Este arquivo: reimplementação limpa, sem obfuscação, em 1 único script Lua,
    com UI Rayfield (https://sirius.menu/rayfield), com ConfigurationSaving
    (configs salvas por jogo).

    Jogo alvo: Steal An Egg (PlaceId 107778070777162)
    Loop do jogo: roubar ovo -> levar pra base -> chocar -> pet gera dinheiro
                   -> treinar speed na treadmill -> upgrade treadmill/base
                   -> roubar ovos maiores/raros/mutados.

    Uso: loadstring(game:HttpGet("SEU_LINK_AQUI"))()  ou cole no executor.
]]

--========================================================
--// 1. LOAD RAYFIELD (com fallback p/ Delta)
--========================================================
local function bootNotify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title), Text = tostring(text), Duration = dur or 6
        })
    end)
end
bootNotify("Chilli Hub", "Iniciando... carregando UI", 4)

local Rayfield
do
    local urls = {
        { "sirius", "https://sirius.menu/rayfield" },
        { "gh-raw", "https://raw.githubusercontent.com/sirius-menu/rayfield/main/source.lua" },
        { "jsdelivr", "https://cdn.jsdelivr.net/gh/sirius-menu/rayfield@main/source.lua" },
    }
    local log = {}
    for _, pair in ipairs(urls) do
        local tag, u = pair[1], pair[2]
        local ok, res = pcall(game.HttpGet, game, u)
        if not ok then
            table.insert(log, tag .. " http-FAIL: " .. string.sub(tostring(res), 1, 90))
        elseif type(res) ~= "string" or #res < 10000 then
            table.insert(log, tag .. " http-curto(" .. tostring(res and #res) .. "b): " .. string.sub(tostring(res), 1, 90))
        else
            local fn, cerr = loadstring(res, "Rayfield")
            if not fn then
                table.insert(log, tag .. " compile-FAIL(" .. #res .. "b): " .. string.sub(tostring(cerr), 1, 110))
            else
                local ok2, lib = pcall(fn)
                if ok2 and lib then
                    Rayfield = lib
                    table.insert(log, tag .. " OK(" .. #res .. "b)")
                    break
                else
                    table.insert(log, tag .. " run-FAIL(" .. #res .. "b): " .. string.sub(tostring(lib), 1, 110))
                end
            end
        end
    end
    if not Rayfield then
        local full = "ChilliHub diag | " .. table.concat(log, " || ")
        pcall(function() if setclipboard then setclipboard(full) end end)
        warn("[ChilliHub] " .. full)
        bootNotify("Chilli Hub ERRO", "Falha ao baixar Rayfield (diag copiado).", 8)
        task.wait(0.5)
        bootNotify("Chilli Hub ERRO 2/2", string.sub(table.concat(log, " || "), 1, 200), 10)
        return
    end
end

--========================================================
--// 2. SERVIÇOS / BASE
--========================================================
local cloneref = (cloneref or clonereference or function(i) return i end)
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local HttpService = cloneref(game:GetService("HttpService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local Lighting = cloneref(game:GetService("Lighting"))

local LocalPlayer = Players.LocalPlayer
local PLACE_ID = game.PlaceId

local function Notify(title, content, dur)
    pcall(function()
        Rayfield:Notify({ Title = tostring(title), Content = tostring(content), Duration = dur or 4, Image = 4483362458 })
    end)
end

local function HRP()
    local c = LocalPlayer.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function Hum()
    local c = LocalPlayer.Character
    if c then return c:FindFirstChildOfClass("Humanoid") end
    return nil
end

--========================================================
--// 3. ESTADO GLOBAL
--========================================================
local State = {
    AutoSteal = false,
    AutoStealAll = false,
    AutoReturn = false,
    AutoSnipe = false,
    SmartTween = true,
    TweenSpeed = 220,
    StealDelay = 0.35,
    NoClip = false,
    FlySteal = false,

    FilterZones = {},
    FilterRarities = {},
    FilterMutations = {},
    Priority = "Mais Raro",

    AutoHatch = false,
    HatchEgg = "All",
    HatchDelay = 0.5,
    AutoEquipBest = false,

    AutoTrain = false,
    AutoUpgradeTreadmill = false,
    AutoUpgradeBase = false,
    AutoCollect = false,
    CollectDelay = 2,

    EggESP = false,
    PlayerESP = false,
    BaseESP = false,
    HighlightBest = true,
    ESPMaxDist = 1500,

    WalkSpeed = 16,
    JumpPower = 50,
    WSEnabled = false,
    JPEnabled = false,
    AntiAFK = true,
    Godmode = false,
}

-- Listas conhecidas do jogo (podem expandir com updates)
local ALL_ZONES = { "Forest", "Beach", "Desert", "Winter", "Volcano", "Abyss Ocean", "Cherry Blossom", "Cosmic", "Prehistoric", "All" }
local ALL_RARITIES = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Eternal", "Divine", "Huge" }
local ALL_MUTATIONS = { "Normal", "Silver", "Golden", "Rainbow", "Dark", "Light" }

--========================================================
--// 4. NOCLIP / ANTI-AFK / UTILS
--========================================================
local NoclipConn = nil
local function SetNoclip(on)
    State.NoClip = on
    if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
    if on then
        NoclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
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

LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
    end
end)

local function ServerHop()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PLACE_ID)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then
        local data = HttpService:JSONDecode(res)
        for _, s in ipairs(data.data or {}) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PLACE_ID, s.id, LocalPlayer)
                return
            end
        end
    end
    TeleportService:Teleport(PLACE_ID, LocalPlayer)
end

-- Tween robusto (cancela se toggle desligar ou morrer)
local ActiveTween = nil
local function TweenTo(cf, speed)
    local hrp = HRP()
    if not hrp then return false end
    speed = speed or State.TweenSpeed
    if speed <= 0 then speed = 220 end
    local dist = (hrp.Position - cf.Position).Magnitude
    if dist < 4 then return true end
    local t = math.clamp(dist / speed, 0.05, 12)
    if ActiveTween then pcall(function() ActiveTween:Cancel() end) ActiveTween = nil end
    local tw = game:GetService("TweenService"):Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = cf })
    ActiveTween = tw
    local wasNoclip = State.NoClip
    if State.SmartTween then SetNoclip(true) end
    tw:Play()
    local done = false
    local conn; conn = tw.Completed:Connect(function() done = true end)
    local start = os.clock()
    while not done and os.clock() - start < (t + 2) do
        if not HRP() then break end
        -- interrompe se alvo ficou longe demais (repath) — sai e deixa o loop repensar
        task.wait()
    end
    if conn then conn:Disconnect() end
    if State.SmartTween and not wasNoclip and not State.NoClip then
        -- mantém noclip só durante tween; restaura
        if NoclipConn then NoclipConn:Disconnect() NoclipConn = nil end
        State.NoClip = wasNoclip
    end
    return done
end

local function FirePromptsInRadius(pos, radius)
    radius = radius or 14
    local fired = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local parent = d.Parent
            local pp = nil
            if parent and parent:IsA("BasePart") then pp = parent.Position
            elseif parent and parent:IsA("Model") then
                local ok, pivot = pcall(function() return parent:GetPivot().Position end)
                if ok then pp = pivot end
            end
            if pp and (pp - pos).Magnitude <= radius then
                pcall(function()
                    if fireproximityprompt then fireproximityprompt(d)
                    else
                        -- fallback: segura E via prompt (alguns executores sem fireproximityprompt)
                        d:InputHoldBegin() task.wait(0.05) d:InputHoldEnd()
                    end
                end)
                fired = fired + 1
            end
        end
    end
    return fired
end

local function TouchAllInRadius(pos, radius)
    radius = radius or 12
    local hrp = HRP()
    if not hrp then return 0 end
    local n = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and d.CanTouch ~= false then
            local nm = string.lower(d.Name .. " " .. (d.Parent and d.Parent.Name or ""))
            if string.find(nm, "egg") then
                if (d.Position - pos).Magnitude <= radius then
                    pcall(function()
                        if firetouchinterest then
                            firetouchinterest(hrp, d, 0) task.wait(0.05) firetouchinterest(hrp, d, 1)
                        end
                    end)
                    n = n + 1
                end
            end
        end
    end
    return n
end

--========================================================
--// 5. AUTODESCOBERTA DE REMOTES (funciona mesmo renomeado)
--========================================================
local RemoteCache = { list = {}, byName = {} }

local function RefreshRemotes()
    RemoteCache.list = {}
    RemoteCache.byName = {}
    local function scan(parent)
        for _, d in ipairs(parent:GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent") then
                table.insert(RemoteCache.list, d)
                RemoteCache.byName[d:GetFullName()] = d
            end
        end
    end
    pcall(scan, ReplicatedStorage)
    pcall(scan, Workspace)
    pcall(scan, game:GetService("ReplicatedFirst"))
    return #RemoteCache.list
end

local function ScoreRemote(remote, keywords)
    local full = string.lower(remote:GetFullName() .. " " .. remote.Name .. " " .. remote.ClassName)
    local s = 0
    for _, k in ipairs(keywords) do
        if string.find(full, string.lower(k), 1, true) then s = s + 10 end
    end
    return s
end

local function FindRemote(keywords, exclude)
    local best, bestScore = nil, 0
    for _, r in ipairs(RemoteCache.list) do
        local skip = false
        if exclude then for _, e in ipairs(exclude) do if r == e then skip = true break end end end
        if not skip then
            local s = ScoreRemote(r, keywords)
            if s > bestScore then best, bestScore = r, s end
        end
    end
    return best
end

local function SafeFire(remote, ...)
    if not remote then return false end
    local args = table.pack(...)
    local ok = false
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        ok = pcall(function() remote:FireServer(table.unpack(args, 1, args.n)) end)
    elseif remote:IsA("RemoteFunction") then
        ok = pcall(function() remote:InvokeServer(table.unpack(args, 1, args.n)) end)
    end
    return ok
end

-- Atalhos com cache preguiçoso
local R = {}
local function GetRemote(slot, keywords)
    if R[slot] and R[slot].Parent then return R[slot] end
    if #RemoteCache.list == 0 then RefreshRemotes() end
    local r = FindRemote(keywords)
    if r then R[slot] = r end
    return r
end

--========================================================
--// 6. LEITURA DO MAPA (heurística, não depende de nome fixo)
--========================================================
local function GetCarryingEgg()
    local c = LocalPlayer.Character
    if not c then return nil end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("Model") and string.find(string.lower(d.Name), "egg") then return d end
        if (d:IsA("Tool") or d:IsA("Model")) and string.find(string.lower(d.Name), "egg") then return d end
    end
    -- alguns jogos usam atributo/flag
    local ok, v = pcall(function() return LocalPlayer:GetAttribute("CarryingEgg") end)
    if ok and v then return true end
    return nil
end

local function GetMyBaseCFrame()
    -- tenta: Plot/Tycoon/Base com Owner == player
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ObjectValue") or d:IsA("StringValue") or d:IsA("IntValue") then
            local ln = string.lower(d.Name)
            if ln == "owner" or ln == "player" or ln == "plotowner" then
                local val = d.Value
                local isMine = (val == LocalPlayer) or (type(val) == "string" and (val == LocalPlayer.Name or val == LocalPlayer.DisplayName))
                if isMine then
                    local m = d:FindFirstAncestorOfClass("Model")
                    if m then
                        local ok, cf = pcall(function() return m:GetPivot() end)
                        if ok then return cf, m end
                    end
                end
            end
        end
    end
    -- fallback: pasta Bases/Plots com nome do player
    for _, folderName in ipairs({ "Bases", "Plots", "Tycoons", "PlayerBases" }) do
        local f = Workspace:FindFirstChild(folderName)
        if f then
            local mine = f:FindFirstChild(LocalPlayer.Name)
            if mine then
                local ok, cf = pcall(function() return (mine:IsA("Model") and mine:GetPivot()) or (mine:IsA("BasePart") and mine.CFrame) end)
                if ok and cf then return cf, mine end
            end
        end
    end
    -- fallback: SpawnLocation do player
    local sp = Workspace:FindFirstChild(LocalPlayer.Name .. "_Base") or Workspace:FindFirstChild("SpawnLocation")
    if sp and sp:IsA("BasePart") then return sp.CFrame + Vector3.new(0, 5, 0), sp end
    return nil, nil
end

local function GetTreadmillCFrame()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Model") then
            if string.find(string.lower(d.Name), "treadmill") then
                if d:IsA("Model") then
                    local ok, cf = pcall(function() return d:GetPivot() end)
                    if ok then return cf + Vector3.new(0, 4, 0), d end
                else
                    return d.CFrame + Vector3.new(0, 4, 0), d
                end
            end
        end
    end
    return nil, nil
end

local function GetHatchCFrame()
    for _, key in ipairs({ "hatch", "hatchery", "hatcharea", "eggshop", "hatchzone" }) do
        for _, d in ipairs(Workspace:GetDescendants()) do
            if (d:IsA("BasePart") or d:IsA("Model")) and string.find(string.lower(d.Name), key) then
                if d:IsA("Model") then
                    local ok, cf = pcall(function() return d:GetPivot() end)
                    if ok then return cf + Vector3.new(0, 4, 0), d end
                else
                    return d.CFrame + Vector3.new(0, 4, 0), d
                end
            end
        end
    end
    -- fallback: usa a própria base (muitos jogos chocam na base)
    local cf = GetMyBaseCFrame()
    return cf, nil
end

-- Extrai raridade/mutação/tamanho de um modelo de ovo via nome + atributos
local RARITY_SCORE = { common = 1, rare = 2, epic = 3, legendary = 4, mythic = 5, secret = 6, eternal = 7, divine = 8, huge = 9, cosmic = 7, rainbow = 6 }
local function EggInfo(model)
    local name = model.Name or "Egg"
    local lname = string.lower(model.ClassName .. " " .. model.Name .. " " .. model:GetFullName())
    local rarity, mutation, size = "Common", "Normal", 1
    for r, _ in pairs(RARITY_SCORE) do
        if string.find(lname, r, 1, true) then rarity = r:sub(1,1):upper() .. r:sub(2) break end
    end
    -- atributos oficiais do jogo (se existirem)
    pcall(function()
        for _, att in ipairs({ "Rarity", "rarity", "Mutation", "mutation", "Size", "size", "Zone", "zone", "Biome", "biome" }) do
            local v = model:GetAttribute(att)
            if v ~= nil then
                local lv = string.lower(att)
                if lv == "rarity" then rarity = tostring(v)
                elseif lv == "mutation" then mutation = tostring(v)
                elseif lv == "size" then size = tonumber(v) or size
                end
            end
        end
    end)
    for _, m in ipairs(ALL_MUTATIONS) do
        if string.find(lname, string.lower(m), 1, true) then mutation = m break end
    end
    local pos = nil
    pcall(function()
        if model:IsA("Model") then pos = model:GetPivot().Position
        elseif model:IsA("BasePart") then pos = model.Position end
    end)
    return { Model = model, Name = name, Rarity = rarity, Mutation = mutation, Size = size, Position = pos }
end

local function FindEggs()
    local out = {}
    local seen = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        local isEgg = false
        if d:IsA("Model") then
            local ln = string.lower(d.Name)
            if string.find(ln, "egg") and not string.find(ln, "hatch") and not string.find(string.lower(d:GetFullName()), "player") then
                -- ignora ovo grudado em jogador (carregado)
                if not d:FindFirstAncestorOfClass("Player") and (not LocalPlayer.Character or not d:IsDescendantOf(LocalPlayer.Character)) then
                    isEgg = true
                end
            end
        elseif d:IsA("BasePart") then
            local ln = string.lower(d.Name)
            if (ln == "egg" or string.find(ln, "egg")) and d.Parent ~= LocalPlayer.Character then
                -- só conta partes soltas no mapa (não dentro de character)
                if not d:FindFirstAncestorOfClass("Player") then isEgg = true end
            end
        end
        if isEgg and not seen[d] then
            seen[d] = true
            local info = EggInfo(d)
            if info.Position then table.insert(out, info) end
        end
    end
    return out
end

local function PassFilters(info)
    -- zonas
    if #State.FilterZones > 0 then
        local full = string.lower(info.Model:GetFullName())
        local okz = false
        for _, z in ipairs(State.FilterZones) do
            if z == "All" then okz = true break end
            if string.find(full, string.lower(z), 1, true) or string.find(string.lower(info.Name), string.lower(z), 1, true) then okz = true break end
        end
        if not okz then return false end
    end
    if #State.FilterRarities > 0 then
        local okr = false
        for _, r in ipairs(State.FilterRarities) do
            if string.find(string.lower(info.Rarity), string.lower(r), 1, true) then okr = true break end
        end
        if not okr then return false end
    end
    if #State.FilterMutations > 0 then
        local okm = false
        for _, m in ipairs(State.FilterMutations) do
            if string.find(string.lower(info.Mutation), string.lower(m), 1, true) then okm = true break end
        end
        if not okm then return false end
    end
    return true
end

local function RarityScore(r)
    return RARITY_SCORE[string.lower(tostring(r))] or 1
end

local function SortEggs(list)
    local hrp = HRP()
    local hp = hrp and hrp.Position or Vector3.new()
    if State.Priority == "Mais Próximo" then
        table.sort(list, function(a, b) return (a.Position - hp).Magnitude < (b.Position - hp).Magnitude end)
    elseif State.Priority == "Maior Tamanho" then
        table.sort(list, function(a, b) return (tonumber(a.Size) or 1) > (tonumber(b.Size) or 1) end)
    elseif State.Priority == "Mais Distante" then
        table.sort(list, function(a, b) return (a.Position - hp).Magnitude > (b.Position - hp).Magnitude end)
    else -- Mais Raro
        table.sort(list, function(a, b)
            local ra, rb = RarityScore(a.Rarity), RarityScore(b.Rarity)
            if ra == rb then return (a.Position - hp).Magnitude < (b.Position - hp).Magnitude end
            return ra > rb
        end)
    end
    return list
end

local function TryStealEgg(info)
    local pos = info.Position
    -- 1) remote (se existir)
    local stealR = GetRemote("steal", { "steal", "takeegg", "take_egg", "grabegg", "grab_egg", "collectegg" })
    if stealR then
        -- tenta variações comuns de args
        SafeFire(stealR, info.Model)
        SafeFire(stealR, info.Model.Name)
        SafeFire(stealR, info.Model:GetAttribute("Id") or info.Model.Name)
    end
    -- 2) físico: encosta + prompt (funciona mesmo sem remote mapeado)
    TouchAllInRadius(pos, 14)
    FirePromptsInRadius(pos, 14)
    return true
end

--========================================================
--// 7. LOOPS PRINCIPAIS
--========================================================
task.spawn(function()
    while true do
        if State.AutoSteal or State.AutoStealAll then
            local ok, err = pcall(function()
                if GetCarryingEgg() and State.AutoReturn then
                    local cf = GetMyBaseCFrame()
                    if cf then TweenTo(cf + Vector3.new(0, 4, 0)) task.wait(0.3) FirePromptsInRadius(cf.Position, 20) end
                    task.wait(State.StealDelay)
                else
                    local eggs = FindEggs()
                    if not State.AutoStealAll then
                        local f = {}
                        for _, e in ipairs(eggs) do if PassFilters(e) then table.insert(f, e) end end
                        eggs = f
                    end
                    eggs = SortEggs(eggs)
                    local target = eggs[1]
                    if target and target.Position then
                        local hrp = HRP()
                        local dist = hrp and (hrp.Position - target.Position).Magnitude or 9999
                        if dist > 10 then
                            TweenTo(CFrame.new(target.Position + Vector3.new(0, 4, 0)))
                        else
                            TryStealEgg(target)
                            task.wait(State.StealDelay)
                        end
                    else
                        task.wait(0.5)
                    end
                end
            end)
            if not ok then task.wait(1) end
        else
            task.wait(0.25)
        end
        task.wait(0.05)
    end
end)

task.spawn(function()
    while true do
        if State.AutoSnipe then
            pcall(function()
                local eggs = SortEggs(FindEggs())
                -- snipe: foca ovos raros caídos longe (Golden/Rainbow/Secret+)
                for _, e in ipairs(eggs) do
                    local rs = RarityScore(e.Rarity)
                    local lm = string.lower(e.Mutation)
                    if rs >= 5 or lm == "golden" or lm == "rainbow" then
                        if not GetCarryingEgg() then
                            TweenTo(CFrame.new(e.Position + Vector3.new(0, 4, 0)))
                            TryStealEgg(e)
                            break
                        end
                    end
                end
            end)
            task.wait(0.4)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while true do
        if State.AutoHatch then
            pcall(function()
                local hatchR = GetRemote("hatch", { "hatch", "openegg", "open_egg", "unbox", "eggopen" })
                local targetEgg = State.HatchEgg
                if hatchR then
                    if targetEgg == "All" then
                        SafeFire(hatchR, "All") SafeFire(hatchR, 1) SafeFire(hatchR, "Hatch")
                    else
                        SafeFire(hatchR, targetEgg) SafeFire(hatchR, targetEgg, 1) SafeFire(hatchR, { Egg = targetEgg })
                    end
                else
                    -- fallback físico: vai até hatch e segura prompts
                    local cf = GetHatchCFrame()
                    if cf then
                        local hrp = HRP()
                        if hrp and (hrp.Position - cf.Position).Magnitude > 12 then
                            TweenTo(cf)
                        else
                            FirePromptsInRadius(cf.Position, 20)
                        end
                    end
                end
                if State.AutoEquipBest then
                    local eq = GetRemote("equip", { "equipbest", "equip_best", "equip", "bestpet" })
                    if eq then SafeFire(eq, "Best") SafeFire(eq, true) end
                end
            end)
            task.wait(math.clamp(State.HatchDelay, 0.1, 5))
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while true do
        if State.AutoTrain then
            pcall(function()
                local trainR = GetRemote("train", { "train", "treadmill", "speed", "workout", "run" })
                if trainR then SafeFire(trainR) SafeFire(trainR, 1) SafeFire(trainR, "Train") end
                local cf = GetTreadmillCFrame()
                if cf then
                    local hrp = HRP()
                    if hrp and (hrp.Position - cf.Position).Magnitude > 10 then
                        TweenTo(cf)
                    else
                        FirePromptsInRadius(cf.Position, 16)
                        TouchAllInRadius(cf.Position, 12)
                    end
                end
            end)
            task.wait(0.5)
        else
            task.wait(0.5)
        end
        if State.AutoUpgradeTreadmill then
            pcall(function()
                local up = GetRemote("upT", { "upgradetreadmill", "treadmillupgrade", "buy treadmill", "treadmill" })
                -- tenta nomes genéricos de upgrade com args comuns
                if up then SafeFire(up) SafeFire(up, 1) SafeFire(up, "Treadmill") end
                local gen = GetRemote("upgrade", { "upgrade", "buy", "purchase" })
                if gen and not up then SafeFire(gen, "Treadmill") SafeFire(gen, "treadmill", 1) end
            end)
            task.wait(2)
        end
        if State.AutoUpgradeBase then
            pcall(function()
                local gen = GetRemote("upgradeB", { "upgrade", "buy", "purchase", "base" })
                if gen then SafeFire(gen, "Base") SafeFire(gen, "base", 1) end
            end)
            task.wait(2)
        end
        if State.AutoCollect then
            pcall(function()
                local c = GetRemote("collect", { "collect", "claim", "income", "money", "cash", "reward", "index" })
                if c then SafeFire(c) SafeFire(c, "All") SafeFire(c, "Collect") end
                local cf = GetMyBaseCFrame()
                if cf then FirePromptsInRadius(cf.Position, 25) end
            end)
            task.wait(math.clamp(State.CollectDelay, 0.5, 30))
        end
        task.wait(0.2)
    end
end)

--========================================================
--// 8. ESP
--========================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ChilliHubESP"
pcall(function() ESPFolder.Parent = cloneref(game:GetService("CoreGui")) end)
if not ESPFolder.Parent then ESPFolder.Parent = Workspace end

local function ClearESP(prefix)
    for _, g in ipairs(ESPFolder:GetChildren()) do
        if string.sub(g.Name, 1, #prefix) == prefix then g:Destroy() end
    end
end

local function EggBillboard(info, isBest)
    local m = info.Model
    local adornee = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)) or m
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
    local hrp = HRP()
    local dist = hrp and math.floor((hrp.Position - info.Position).Magnitude) or 0
    tl.Text = ("%s\n%s | %s [%dm]"):format(info.Name, info.Rarity, info.Mutation, dist)
    tl.TextColor3 = isBest and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 255, 160)
    tl.Parent = gui
    gui.Parent = ESPFolder
    if isBest then
        local hl = Instance.new("Highlight")
        hl.Name = "BEST_" .. tostring(m:GetDebugId())
        hl.Adornee = m:IsA("Model") and m or adornee
        hl.FillColor = Color3.fromRGB(255, 200, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.6
        hl.Parent = ESPFolder
    end
end

task.spawn(function()
    while true do
        if State.EggESP then
            pcall(function()
                ClearESP("EGG_") ClearESP("BEST_")
                local eggs = SortEggs(FindEggs())
                local hrp = HRP()
                local hp = hrp and hrp.Position or Vector3.new()
                local best = eggs[1]
                local shown = 0
                for _, e in ipairs(eggs) do
                    if shown >= 40 then break end
                    if (e.Position - hp).Magnitude <= State.ESPMaxDist then
                        EggBillboard(e, State.HighlightBest and e == best)
                        shown = shown + 1
                    end
                end
            end)
            task.wait(1.2)
        else
            if #ESPFolder:GetChildren() > 0 and not State.PlayerESP and not State.BaseESP then
                -- limpa quando tudo off
            end
            ClearESP("EGG_") ClearESP("BEST_")
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while true do
        if State.PlayerESP then
            pcall(function()
                ClearESP("PLR_")
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
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
                            local hrp = HRP()
                            local d = hrp and math.floor((hrp.Position - h.Position).Magnitude) or 0
                            local spd = "?"
                            pcall(function()
                                local ls = p:FindFirstChild("leaderstats")
                                if ls then
                                    for _, v in ipairs(ls:GetChildren()) do
                                        if string.find(string.lower(v.Name), "speed") then spd = tostring(v.Value) break end
                                    end
                                end
                            end)
                            tl.Text = ("%s [%dm] Speed:%s"):format(p.DisplayName, d, tostring(spd))
                            tl.TextColor3 = Color3.fromRGB(255, 120, 120)
                            tl.Parent = gui
                            gui.Parent = ESPFolder
                        end
                    end
                end
            end)
            task.wait(1.5)
        else
            ClearESP("PLR_")
            task.wait(0.5)
        end
    end
end)

-- WalkSpeed / Jump loop
task.spawn(function()
    while true do
        pcall(function()
            local h = Hum()
            if h then
                if State.WSEnabled then h.WalkSpeed = State.WalkSpeed end
                if State.JPEnabled then h.JumpPower = State.JumpPower; h.UseJumpPower = true end
                if State.Godmode then
                    -- anti-catch simples: mantém humanoide vivo + sem ragdoll
                    if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
                    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                end
            end
        end)
        task.wait(0.3)
    end
end)

--========================================================
--// 9. JANELA RAYFIELD + SAVE CONFIG
--========================================================
local Window = Rayfield:CreateWindow({
    Name = "Chilli Hub | Steal an Egg",
    Icon = 0,
    LoadingTitle = "Chilli Hub",
    LoadingSubtitle = "by Chilli • Rayfield",
    ShowText = "Chilli Hub",
    Theme = "Default",
    ToggleUIKeybind = "RightShift",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ChilliHub",
        FileName = "StealAnEgg"
    },
    Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
    KeySystem = false,
})

local FarmTab = Window:CreateTab("Farm", 4483362458)
local PetsTab = Window:CreateTab("Pets", 4483362458)
local TreinoTab = Window:CreateTab("Treino", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458)
local JogadorTab = Window:CreateTab("Jogador", 4483362458)
local DiagTab = Window:CreateTab("Diagnostico", 4483362458)

local function MultiToArray(v)
    local out = {}
    if type(v) ~= "table" then return out end
    for _, s in ipairs(v) do table.insert(out, s) end
    return out
end

--========== FARM ==========
FarmTab:CreateSection("Roubo automatico")

FarmTab:CreateToggle({ Name = "Auto Steal (com filtros)", CurrentValue = false, Flag = "AutoSteal",
    Callback = function(v) State.AutoSteal = v end })
FarmTab:CreateToggle({ Name = "Auto Steal TUDO", CurrentValue = false, Flag = "AutoStealAll",
    Callback = function(v) State.AutoStealAll = v end })
FarmTab:CreateToggle({ Name = "Auto Voltar pra Base", CurrentValue = true, Flag = "AutoReturn",
    Callback = function(v) State.AutoReturn = v end })
FarmTab:CreateToggle({ Name = "Snipe Raros (Golden/Rainbow/Secret+)", CurrentValue = false, Flag = "AutoSnipe",
    Callback = function(v) State.AutoSnipe = v end })
FarmTab:CreateToggle({ Name = "Smart Tween + NoClip", CurrentValue = true, Flag = "SmartTween",
    Callback = function(v) State.SmartTween = v end })

FarmTab:CreateSlider({ Name = "Tween Speed (studs/s)", Range = {60, 600}, Increment = 5, CurrentValue = 220, Flag = "TweenSpeed",
    Callback = function(v) State.TweenSpeed = v end })
FarmTab:CreateSlider({ Name = "Delay entre roubos (s)", Range = {0.1, 2}, Increment = 0.05, CurrentValue = 0.35, Flag = "StealDelay",
    Callback = function(v) State.StealDelay = v end })

FarmTab:CreateSection("Filtros (vazio = todas)")
FarmTab:CreateDropdown({ Name = "Zonas / Biomas", Options = ALL_ZONES, CurrentOption = {}, MultipleOptions = true, Flag = "FilterZones",
    Callback = function(v) State.FilterZones = MultiToArray(v) end })
FarmTab:CreateDropdown({ Name = "Raridades", Options = ALL_RARITIES, CurrentOption = {}, MultipleOptions = true, Flag = "FilterRarities",
    Callback = function(v) State.FilterRarities = MultiToArray(v) end })
FarmTab:CreateDropdown({ Name = "Mutacoes", Options = ALL_MUTATIONS, CurrentOption = {}, MultipleOptions = true, Flag = "FilterMutations",
    Callback = function(v) State.FilterMutations = MultiToArray(v) end })
FarmTab:CreateDropdown({ Name = "Prioridade do alvo", Options = { "Mais Raro", "Mais Próximo", "Mais Distante", "Maior Tamanho" }, CurrentOption = {"Mais Raro"}, MultipleOptions = false, Flag = "Priority",
    Callback = function(v)
        if type(v) == "table" then State.Priority = v[1] or "Mais Raro" else State.Priority = v end
    end })

FarmTab:CreateSection("Acoes rapidas")
FarmTab:CreateButton({ Name = "Roubar melhor ovo AGORA", Callback = function()
    task.spawn(function()
        local eggs = SortEggs(FindEggs())
        local t = eggs[1]
        if t then TweenTo(CFrame.new(t.Position + Vector3.new(0, 4, 0))) TryStealEgg(t) Notify("Steal", t.Name .. " | " .. t.Rarity)
        else Notify("Steal", "Nenhum ovo encontrado") end
    end)
end })
FarmTab:CreateButton({ Name = "Voltar pra Base AGORA", Callback = function()
    task.spawn(function()
        local cf = GetMyBaseCFrame()
        if cf then TweenTo(cf + Vector3.new(0, 5, 0)) FirePromptsInRadius(cf.Position, 20) Notify("Base", "Entregue / prompt ativado")
        else Notify("Base", "Base não encontrada — use Diagnostico") end
    end)
end })

--========== PETS ==========
PetsTab:CreateSection("Chocar ovos")
PetsTab:CreateToggle({ Name = "Auto Hatch", CurrentValue = false, Flag = "AutoHatch",
    Callback = function(v) State.AutoHatch = v end })
PetsTab:CreateToggle({ Name = "Auto Equipar Melhor", CurrentValue = false, Flag = "AutoEquipBest",
    Callback = function(v) State.AutoEquipBest = v end })
PetsTab:CreateSlider({ Name = "Delay do Hatch (s)", Range = {0.2, 5}, Increment = 0.1, CurrentValue = 0.5, Flag = "HatchDelay",
    Callback = function(v) State.HatchDelay = v end })
PetsTab:CreateInput({ Name = "Ovo p/ Hatch (ou All)", CurrentValue = "All", PlaceholderText = "Ex: Cosmic / All", RemoveTextAfterFocusLost = false, Flag = "HatchEgg",
    Callback = function(v) State.HatchEgg = (v == "" and "All" or v) end })
PetsTab:CreateButton({ Name = "Equipar Melhor AGORA", Callback = function()
    local eq = GetRemote("equip", { "equipbest", "equip_best", "equip", "bestpet" })
    if eq then SafeFire(eq, "Best") Notify("Pets", "Equip Best disparado") else Notify("Pets", "Remote de equip não achado") end
end })
PetsTab:CreateButton({ Name = "Chocar 1x AGORA", Callback = function()
    local h = GetRemote("hatch", { "hatch", "openegg", "open_egg", "unbox" })
    if h then SafeFire(h, State.HatchEgg) Notify("Hatch", "Disparado: " .. tostring(State.HatchEgg))
    else local cf = GetHatchCFrame() if cf then TweenTo(cf) FirePromptsInRadius(cf.Position, 20) end end
end })

--========== TREINO ==========
TreinoTab:CreateSection("Speed + Upgrades + Renda")
TreinoTab:CreateToggle({ Name = "Auto Treinar (treadmill)", CurrentValue = false, Flag = "AutoTrain",
    Callback = function(v) State.AutoTrain = v end })
TreinoTab:CreateToggle({ Name = "Auto Upgrade Treadmill", CurrentValue = false, Flag = "AutoUpTread",
    Callback = function(v) State.AutoUpgradeTreadmill = v end })
TreinoTab:CreateToggle({ Name = "Auto Upgrade Base", CurrentValue = false, Flag = "AutoUpBase",
    Callback = function(v) State.AutoUpgradeBase = v end })
TreinoTab:CreateToggle({ Name = "Auto Coletar Dinheiro", CurrentValue = false, Flag = "AutoCollect",
    Callback = function(v) State.AutoCollect = v end })
TreinoTab:CreateSlider({ Name = "Delay coleta (s)", Range = {1, 30}, Increment = 0.5, CurrentValue = 2, Flag = "CollectDelay",
    Callback = function(v) State.CollectDelay = v end })
TreinoTab:CreateButton({ Name = "Ir pra Treadmill", Callback = function()
    local cf = GetTreadmillCFrame()
    if cf then TweenTo(cf) else Notify("Treino", "Treadmill não achada — use Diagnostico") end
end })

--========== VISUAL ==========
VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({ Name = "Egg ESP", CurrentValue = false, Flag = "EggESP",
    Callback = function(v) State.EggESP = v end })
VisualTab:CreateToggle({ Name = "Destacar melhor ovo", CurrentValue = true, Flag = "HighlightBest",
    Callback = function(v) State.HighlightBest = v end })
VisualTab:CreateToggle({ Name = "Player ESP (nome+dist+speed)", CurrentValue = false, Flag = "PlayerESP",
    Callback = function(v) State.PlayerESP = v end })
VisualTab:CreateSlider({ Name = "Distancia max ESP", Range = {200, 5000}, Increment = 50, CurrentValue = 1500, Flag = "ESPMaxDist",
    Callback = function(v) State.ESPMaxDist = v end })
VisualTab:CreateButton({ Name = "Limpar ESP", Callback = function() ClearESP("EGG_") ClearESP("BEST_") ClearESP("PLR_") end })

--========== JOGADOR ==========
JogadorTab:CreateSection("Movimento")
JogadorTab:CreateToggle({ Name = "Ativar WalkSpeed custom", CurrentValue = false, Flag = "WSEnabled",
    Callback = function(v) State.WSEnabled = v end })
JogadorTab:CreateSlider({ Name = "WalkSpeed", Range = {16, 250}, Increment = 1, CurrentValue = 16, Flag = "WalkSpeed",
    Callback = function(v) State.WalkSpeed = v end })
JogadorTab:CreateToggle({ Name = "Ativar Jump custom", CurrentValue = false, Flag = "JPEnabled",
    Callback = function(v) State.JPEnabled = v end })
JogadorTab:CreateSlider({ Name = "JumpPower", Range = {50, 400}, Increment = 1, CurrentValue = 50, Flag = "JumpPower",
    Callback = function(v) State.JumpPower = v end })
JogadorTab:CreateToggle({ Name = "NoClip", CurrentValue = false, Flag = "NoclipT",
    Callback = function(v) SetNoclip(v) end })
JogadorTab:CreateToggle({ Name = "Godmode (anti-catch)", CurrentValue = false, Flag = "Godmode",
    Callback = function(v) State.Godmode = v end })
JogadorTab:CreateToggle({ Name = "Anti-AFK", CurrentValue = true, Flag = "AntiAFK",
    Callback = function(v) State.AntiAFK = v end })

JogadorTab:CreateSection("Servidor / Performance")
JogadorTab:CreateButton({ Name = "Server Hop (servidor vazio)", Callback = ServerHop })
JogadorTab:CreateButton({ Name = "Reentrar (Rejoin)", Callback = function() TeleportService:Teleport(PLACE_ID, LocalPlayer) end })
JogadorTab:CreateButton({ Name = "FPS Boost (tira sombra/efeito)", Callback = function()
    pcall(function()
        Lighting.GlobalShadows = false Lighting.FogEnd = 1e9
        for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("PostEffect") or v:IsA("Atmosphere") then v.Enabled = false end end
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Trail") then o.Enabled = false end
        end
        Notify("FPS", "Boost aplicado")
    end)
end })

--========== DIAGNÓSTICO ==========
DiagTab:CreateSection("Autodescoberta")
DiagTab:CreateParagraph({ Title = "Scanners", Content = "Se algo não funcionar, rode os scanners. Fallback fisico (tween + prompt + touch) sobrevive a rename de Remote." })
DiagTab:CreateButton({ Name = "Escanear Remotes", Callback = function()
    local n = RefreshRemotes()
    print("===== [ChilliHub] REMOTES (" .. n .. ") =====")
    for _, r in ipairs(RemoteCache.list) do print(r.ClassName, r:GetFullName()) end
    print("===== FIM =====")
    local s = FindRemote({ "steal" }) local h = FindRemote({ "hatch" }) local t = FindRemote({ "train", "treadmill" })
    local u = FindRemote({ "upgrade" }) local c = FindRemote({ "collect", "claim", "income" })
    Notify("Remotes", ("Achados: %d | steal:%s hatch:%s train:%s up:%s collect:%s"):format(n, s and "ok" or "--", h and "ok" or "--", t and "ok" or "--", u and "ok" or "--", c and "ok" or "--"), 6)
end })
DiagTab:CreateButton({ Name = "Escanear Mapa (ovos/base/treadmill)", Callback = function()
    local eggs = FindEggs()
    local bcf = GetMyBaseCFrame()
    local tcf = GetTreadmillCFrame()
    local hcf = GetHatchCFrame()
    print(("===== [ChilliHub] MAPA: ovos=%d base=%s treadmill=%s hatch=%s ====="):format(#eggs, bcf and "ok" or "NAO", tcf and "ok" or "NAO", hcf and "ok" or "NAO"))
    for i = 1, math.min(#eggs, 20) do
        local e = eggs[i]
        print(i, e.Name, e.Rarity, e.Mutation, tostring(e.Position))
    end
    Notify("Mapa", ("Ovos: %d | Base: %s | Treadmill: %s"):format(#eggs, bcf and "OK" or "NÃO", tcf and "OK" or "NÃO"), 6)
end })
DiagTab:CreateButton({ Name = "Copiar lista de Remotes", Callback = function()
    RefreshRemotes()
    local t = {}
    for _, r in ipairs(RemoteCache.list) do table.insert(t, r.ClassName .. " | " .. r:GetFullName()) end
    if setclipboard then setclipboard(table.concat(t, "\n")) Notify("Clipboard", "Lista copiada (" .. #t .. ")") end
end })

--========== SAVE CONFIG (Rayfield) ==========
RefreshRemotes()
Rayfield:Notify({ Title = "Chilli Hub", Content = "Carregado! Config salva em ChilliHub/StealAnEgg.json", Duration = 5, Image = 4483362458 })
print("[ChilliHub] Rayfield + SaveConfig carregado. PlaceId:", PLACE_ID)

Rayfield:LoadConfiguration()
