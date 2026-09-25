--========================================================
-- Chilli Hub | Load.lua (loader slim)
-- Só bootstrap: baixa cada módulo de src/ChilliHub e
-- entrega as factories para Main.lua montar o Ctx.
--
-- COMO USAR (executor):
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/rianfelipeferreira2004/v2/main/Load.lua"))()
--
-- O código antigo (monolito de 1400 linhas) está no git:
--   git show HEAD:Load.lua  (ou renomeie este arquivo)
--========================================================

local BASE = "https://raw.githubusercontent.com/rianfelipeferreira2004/v2/main/src/ChilliHub"

local ORDER = {
    "Config", "Services", "Utils", "OrionBootstrap",
    "Movement", "Interaction", "Remotes", "World",
    "AntiCheat", "Automation", "ESP", "PlayerMods",
}

local function fetch(name)
    local url = BASE .. "/" .. name .. ".lua"
    local ok, res = pcall(game.HttpGet, game, url)
    assert(ok and type(res) == "string" and #res > 500,
        "[ChilliHub] falhou baixar " .. name .. " (" .. url .. ")")
    local fn, err = loadstring(res, "ChilliHub/" .. name)
    assert(fn, "[ChilliHub] compile " .. name .. ": " .. tostring(err))
    return fn()
end

local function fetchUI(name)
    local url = BASE .. "/UI/" .. name .. ".lua"
    local ok, res = pcall(game.HttpGet, game, url)
    assert(ok and type(res) == "string" and #res > 500,
        "[ChilliHub] falhou baixar UI/" .. name)
    local fn, err = loadstring(res, "ChilliHub/UI/" .. name)
    assert(fn, "[ChilliHub] compile UI/" .. name .. ": " .. tostring(err))
    return fn()
end

local M = {}
for _, name in ipairs(ORDER) do
    M[name] = fetch(name)
end
M.OrionUI = fetchUI("Orion")
M.NativeUI = fetchUI("Native")

local mainUrl = BASE .. "/Main.lua"
local ok, res = pcall(game.HttpGet, game, mainUrl)
assert(ok and type(res) == "string" and #res > 500, "[ChilliHub] falhou baixar Main")
local mainFn, mainErr = loadstring(res, "ChilliHub/Main")
assert(mainFn, "[ChilliHub] compile Main: " .. tostring(mainErr))

return mainFn()(M)
