--========================================================
-- ChilliHub | Config.lua
-- Estado global + constantes do jogo. Fonte única de verdade.
-- Nenhum outro módulo deve criar defaults próprios.
--========================================================

local Config = {}

Config.ALL_ZONES = {
    "Forest", "Beach", "Desert", "Winter", "Volcano",
    "Abyss Ocean", "Cherry Blossom", "Cosmic", "Prehistoric", "All",
}

Config.ALL_RARITIES = {
    "Common", "Rare", "Epic", "Legendary",
    "Mythic", "Secret", "Eternal", "Divine", "Huge",
}

Config.ALL_MUTATIONS = {
    "Normal", "Silver", "Golden", "Rainbow", "Dark", "Light",
}

-- Score usado por SortEggs / Snipe / HighlightBest
Config.RARITY_SCORE = {
    common = 1, rare = 2, epic = 3, legendary = 4,
    mythic = 5, secret = 6, eternal = 7, divine = 8,
    huge = 9, cosmic = 7, rainbow = 6,
}

-- Prioridades válidas (usado pela UI cycle/dropdown)
Config.PRIORITIES = { "Mais Raro", "Mais Proximo", "Mais Distante", "Maior Tamanho" }

-- Estado inicial. Main.lua clona via Config.newState().
function Config.newState()
    return {
        -- Farm / steal
        AutoSteal = false,
        AutoStealAll = false,
        AutoReturn = false,
        AutoSnipe = false,
        SmartTween = true,
        TweenSpeed = 150, -- teto do Modo Seguro; slider da UI vai até 600 p/ quem assume o risco
        StealDelay = 0.35,
        NoClip = false,
        FlySteal = false,

        -- Filtros (lista vazia = tudo)
        FilterZones = {},
        FilterRarities = {},
        FilterMutations = {},
        Priority = "Mais Raro",

        -- Pets / hatch
        AutoHatch = false,
        HatchEgg = "All",
        HatchDelay = 0.5,
        AutoEquipBest = false,

        -- Treino / economia
        AutoTrain = false,
        AutoUpgradeTreadmill = false,
        AutoUpgradeBase = false,
        AutoCollect = false,
        CollectDelay = 2,

        -- Visual
        EggESP = false,
        PlayerESP = false,
        BaseESP = false,
        HighlightBest = true,
        ESPMaxDist = 1500,

        -- Jogador
        WalkSpeed = 16,
        JumpPower = 50,
        WSEnabled = false,
        JPEnabled = false,
        AntiAFK = true,
        Godmode = false,

        -- Proteção / bypass (paridade YokuHub: NADA agressivo liga sozinho.
        -- Hooks de metamethod e UI Orion são opt-in: o AC client-side do
        -- jogo pode detectar ambos no boot.)
        AntiKick = false,
        Humanized = false,
        BlockKickRemotes = false,
        SafeMode = true,
        UseRemotes = true,
        UsePathfind = false,
        SpoofProps = false,
        AutoRejoin = true,

        -- UI: Nativa por padrão. Orion (nome famoso, blacklistável)
        -- só com opt-in explícito.
        UseOrion = false,
    }
end

return Config
