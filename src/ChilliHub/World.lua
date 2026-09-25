--========================================================
-- ChilliHub | World.lua
-- Leitura do mapa por heurística (sem nome fixo):
-- base, treadmill, hatch, ovos, filtros, ordenação, steal.
-- Depende de Ctx.Remotes e Ctx.Interaction (lazy via Ctx).
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local State = Ctx.State
    local U = Ctx.Utils
    local Config = Ctx.Config
    local LocalPlayer = S.LocalPlayer

    local W = {}

    function W.GetCarryingEgg()
        local c = LocalPlayer.Character
        if not c then return nil end
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("Model") and string.find(string.lower(d.Name), "egg") then return d end
            if (d:IsA("Tool") or d:IsA("Model")) and string.find(string.lower(d.Name), "egg") then return d end
        end
        local ok, v = pcall(function() return LocalPlayer:GetAttribute("CarryingEgg") end)
        if ok and v then return true end
        return nil
    end

    function W.GetMyBaseCFrame()
        for _, d in ipairs(S.Workspace:GetDescendants()) do
            if d:IsA("ObjectValue") or d:IsA("StringValue") or d:IsA("IntValue") then
                local ln = string.lower(d.Name)
                if ln == "owner" or ln == "player" or ln == "plotowner" then
                    local val = d.Value
                    local isMine = (val == LocalPlayer)
                        or (type(val) == "string" and (val == LocalPlayer.Name or val == LocalPlayer.DisplayName))
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
        for _, folderName in ipairs({ "Bases", "Plots", "Tycoons", "PlayerBases" }) do
            local f = S.Workspace:FindFirstChild(folderName)
            if f then
                local mine = f:FindFirstChild(LocalPlayer.Name)
                if mine then
                    local ok, cf = pcall(function()
                        return (mine:IsA("Model") and mine:GetPivot())
                            or (mine:IsA("BasePart") and mine.CFrame)
                    end)
                    if ok and cf then return cf, mine end
                end
            end
        end
        local sp = S.Workspace:FindFirstChild(LocalPlayer.Name .. "_Base")
            or S.Workspace:FindFirstChild("SpawnLocation")
        if sp and sp:IsA("BasePart") then
            return sp.CFrame + Vector3.new(0, 5, 0), sp
        end
        return nil, nil
    end

    function W.GetTreadmillCFrame()
        for _, d in ipairs(S.Workspace:GetDescendants()) do
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

    function W.GetHatchCFrame()
        for _, key in ipairs({ "hatch", "hatchery", "hatcharea", "eggshop", "hatchzone" }) do
            for _, d in ipairs(S.Workspace:GetDescendants()) do
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
        local cf = W.GetMyBaseCFrame()
        return cf, nil
    end

    -- Extrai raridade/mutação/tamanho via nome + atributos
    function W.EggInfo(model)
        local name = model.Name or "Egg"
        local lname = string.lower(model.ClassName .. " " .. model.Name .. " " .. model:GetFullName())
        local rarity, mutation, size = "Common", "Normal", 1
        for r, _ in pairs(Config.RARITY_SCORE) do
            if string.find(lname, r, 1, true) then
                rarity = r:sub(1, 1):upper() .. r:sub(2)
                break
            end
        end
        pcall(function()
            for _, att in ipairs({ "Rarity", "rarity", "Mutation", "mutation", "Size", "size" }) do
                local v = model:GetAttribute(att)
                if v ~= nil then
                    local lv = string.lower(att)
                    if lv == "rarity" then rarity = tostring(v)
                    elseif lv == "mutation" then mutation = tostring(v)
                    elseif lv == "size" then size = tonumber(v) or size end
                end
            end
        end)
        for _, m in ipairs(Config.ALL_MUTATIONS) do
            if string.find(lname, string.lower(m), 1, true) then mutation = m break end
        end
        local pos = nil
        pcall(function()
            if model:IsA("Model") then pos = model:GetPivot().Position
            elseif model:IsA("BasePart") then pos = model.Position end
        end)
        return { Model = model, Name = name, Rarity = rarity, Mutation = mutation, Size = size, Position = pos }
    end

    function W.FindEggs()
        local out, seen = {}, {}
        for _, d in ipairs(S.Workspace:GetDescendants()) do
            local isEgg = false
            if d:IsA("Model") then
                local ln = string.lower(d.Name)
                if string.find(ln, "egg") and not string.find(ln, "hatch")
                    and not string.find(string.lower(d:GetFullName()), "player") then
                    if not d:FindFirstAncestorOfClass("Player")
                        and (not LocalPlayer.Character or not d:IsDescendantOf(LocalPlayer.Character)) then
                        isEgg = true
                    end
                end
            elseif d:IsA("BasePart") then
                local ln = string.lower(d.Name)
                if (ln == "egg" or string.find(ln, "egg")) and d.Parent ~= LocalPlayer.Character then
                    if not d:FindFirstAncestorOfClass("Player") then isEgg = true end
                end
            end
            if isEgg and not seen[d] then
                seen[d] = true
                local info = W.EggInfo(d)
                if info.Position then table.insert(out, info) end
            end
        end
        return out
    end

    function W.PassFilters(info)
        if #State.FilterZones > 0 then
            local full = string.lower(info.Model:GetFullName())
            local okz = false
            for _, z in ipairs(State.FilterZones) do
                if z == "All" then okz = true break end
                if string.find(full, string.lower(z), 1, true)
                    or string.find(string.lower(info.Name), string.lower(z), 1, true) then
                    okz = true break
                end
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

    function W.RarityScore(r)
        return Config.RARITY_SCORE[string.lower(tostring(r))] or 1
    end

    function W.SortEggs(list)
        local hrp = U.HRP()
        local hp = hrp and hrp.Position or Vector3.new()
        if State.Priority == "Mais Proximo" then
            table.sort(list, function(a, b) return (a.Position - hp).Magnitude < (b.Position - hp).Magnitude end)
        elseif State.Priority == "Maior Tamanho" then
            table.sort(list, function(a, b) return (tonumber(a.Size) or 1) > (tonumber(b.Size) or 1) end)
        elseif State.Priority == "Mais Distante" then
            table.sort(list, function(a, b) return (a.Position - hp).Magnitude > (b.Position - hp).Magnitude end)
        else -- Mais Raro
            table.sort(list, function(a, b)
                local ra, rb = W.RarityScore(a.Rarity), W.RarityScore(b.Rarity)
                if ra == rb then return (a.Position - hp).Magnitude < (b.Position - hp).Magnitude end
                return ra > rb
            end)
        end
        return list
    end

    -- 1) físico primeiro (prompt + toque), 2) remote UMA vez se permitido
    function W.TryStealEgg(info)
        local pos = info.Position
        Ctx.Interaction.TouchAllInRadius(pos, 14)
        Ctx.Interaction.FirePromptsInRadius(pos, 14)
        if State.UseRemotes then
            local stealR = Ctx.Remotes.Get("steal",
                { "steal", "takeegg", "take_egg", "grabegg", "grab_egg", "collectegg" })
            if stealR then Ctx.Remotes.SafeFire(stealR, info.Model) end
        end
        return true
    end

    return W
end
