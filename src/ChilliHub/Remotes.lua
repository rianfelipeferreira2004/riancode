--========================================================
-- ChilliHub | Remotes.lua
-- Autodescoberta de remotes por keyword (sobrevive a rename).
-- Cache preguiçoso por slot: steal / hatch / equip / ...
--========================================================

return function(Ctx)
    local S = Ctx.Services

    local Rm = {}
    Rm.Cache = { list = {}, byName = {} }
    local Slots = {} -- R[slot] = remote

    function Rm.Refresh()
        Rm.Cache.list = {}
        Rm.Cache.byName = {}
        local function scan(parent)
            for _, d in ipairs(parent:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent") then
                    table.insert(Rm.Cache.list, d)
                    Rm.Cache.byName[d:GetFullName()] = d
                end
            end
        end
        pcall(scan, S.ReplicatedStorage)
        pcall(scan, S.Workspace)
        pcall(scan, game:GetService("ReplicatedFirst"))
        return #Rm.Cache.list
    end

    local function ScoreRemote(remote, keywords)
        local full = string.lower(remote:GetFullName() .. " " .. remote.Name .. " " .. remote.ClassName)
        local s = 0
        for _, k in ipairs(keywords) do
            if string.find(full, string.lower(k), 1, true) then s = s + 10 end
        end
        return s
    end

    function Rm.Find(keywords, exclude)
        local best, bestScore = nil, 0
        for _, r in ipairs(Rm.Cache.list) do
            local skip = false
            if exclude then
                for _, e in ipairs(exclude) do
                    if r == e then skip = true break end
                end
            end
            if not skip then
                local s = ScoreRemote(r, keywords)
                if s > bestScore then best, bestScore = r, s end
            end
        end
        return best
    end

    function Rm.SafeFire(remote, ...)
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

    -- Atalho com cache preguiçoso
    function Rm.Get(slot, keywords)
        if Slots[slot] and Slots[slot].Parent then return Slots[slot] end
        if #Rm.Cache.list == 0 then Rm.Refresh() end
        local r = Rm.Find(keywords)
        if r then Slots[slot] = r end
        return r
    end

    function Rm.Invalidate(slot)
        if slot then Slots[slot] = nil
        else Slots = {} end
    end

    return Rm
end
