--========================================================
-- ChilliHub | Interaction.lua
-- Contato físico com o mundo: prompts + touch.
-- Não passa por remote — sobrevive a rename de Remote.
--========================================================

return function(Ctx)
    local S = Ctx.Services
    local U = Ctx.Utils

    local Ix = {}

    function Ix.FirePromptsInRadius(pos, radius)
        radius = radius or 14
        local fired = 0
        for _, d in ipairs(S.Workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Enabled then
                local parent = d.Parent
                local pp = nil
                if parent and parent:IsA("BasePart") then
                    pp = parent.Position
                elseif parent and parent:IsA("Model") then
                    local ok, pivot = pcall(function() return parent:GetPivot().Position end)
                    if ok then pp = pivot end
                end
                if pp and (pp - pos).Magnitude <= radius then
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(d)
                        else
                            d:InputHoldBegin() task.wait(0.05) d:InputHoldEnd()
                        end
                    end)
                    fired = fired + 1
                end
            end
        end
        return fired
    end

    function Ix.TouchAllInRadius(pos, radius)
        radius = radius or 12
        local hrp = U.HRP()
        if not hrp then return 0 end
        local n = 0
        for _, d in ipairs(S.Workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.CanTouch ~= false then
                local nm = string.lower(d.Name .. " " .. (d.Parent and d.Parent.Name or ""))
                if string.find(nm, "egg") then
                    if (d.Position - pos).Magnitude <= radius then
                        pcall(function()
                            if firetouchinterest then
                                firetouchinterest(hrp, d, 0)
                                task.wait(0.05)
                                firetouchinterest(hrp, d, 1)
                            end
                        end)
                        n = n + 1
                    end
                end
            end
        end
        return n
    end

    return Ix
end
