-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Shared (клиент + сервер)
-- ============================================================================

GM.Name    = "S.T.A.L.K.E.R. Multiplayer TDM"
GM.Author  = "marlenanother"
GM.Email   = "marlenanother@gmail.com"
GM.Website = "https://discord.gg/SKVgPPA46R"

include("config.lua")

-- ============================================================================
-- ОПРЕДЕЛЕНИЕ КОМАНД
-- ============================================================================
TEAM_FACTION1 = 1
TEAM_FACTION2 = 2
TEAM_UNASSIGNED = TEAM_UNASSIGNED or 1001  -- Для игроков без команды

-- Состояния раунда
ROUND_WAITING   = 0
ROUND_VOTING    = 1
ROUND_WARMUP    = 2
ROUND_ACTIVE    = 3
ROUND_ENDING    = 4
ROUND_MAP_VOTE  = 5

-- ============================================================================
-- УТИЛИТЫ ДЛЯ ФРАКЦИЙ
-- ============================================================================

-- Получить ID фракции игрока (строковый: "mercenaries", "freedom", etc.)
function GM:GetPlayerFactionID(ply)
    if not IsValid(ply) then return nil end

    local matchup = STALKER_CONFIG.FactionMatchups[self.CurrentMatchup or 1]
    if not matchup then return nil end

    local teamID = ply:Team()
    if teamID == TEAM_FACTION1 then
        return matchup.team1.id
    elseif teamID == TEAM_FACTION2 then
        return matchup.team2.id
    end

    return nil
end

-- Получить модель брони для фракции игрока
function GM:GetArmorModelForPlayer(ply, armorClass)
    local factionID = self:GetPlayerFactionID(ply)
    if not factionID then return nil end

    local armorModels = STALKER_CONFIG.ArmorModels[armorClass]
    if not armorModels then return nil end

    local factionModels = armorModels[factionID]
    if not factionModels or #factionModels == 0 then return nil end

    return factionModels[math.random(#factionModels)]
end

-- ============================================================================
-- ОБЩИЕ УТИЛИТЫ
-- ============================================================================

function GM:GetRankByXP(xp)
    local rank = STALKER_CONFIG.Ranks[1]
    local rankLevel = 1
    for i, r in ipairs(STALKER_CONFIG.Ranks) do
        if xp >= r.xp then
            rank = r
            rankLevel = i
        else
            break
        end
    end
    return rankLevel, rank
end

function GM:GetXPToNextRank(currentXP)
    local currentLevel = self:GetRankByXP(currentXP)
    local nextRank = STALKER_CONFIG.Ranks[currentLevel + 1]
    if nextRank then
        return nextRank.xp - currentXP, nextRank
    end
    return 0, nil
end

function GM:CanRankUseItem(rankLevel, item)
    return rankLevel >= (item.minRank or 1)
end

function GM:GetShopItem(className)
    for _, item in ipairs(STALKER_CONFIG.ShopItems) do
        if item.class == className then
            return item
        end
    end
    return nil
end

function GM:IsInBuyZone(ply)
    if not IsValid(ply) then return false end

    local mapName = game.GetMap()
    local spawns = STALKER_CONFIG.Spawns[mapName]
    if not spawns then return true end

    local teamID = ply:Team()
    local center

    if teamID == TEAM_FACTION1 then
        center = spawns.team1BuyZoneCenter
    elseif teamID == TEAM_FACTION2 then
        center = spawns.team2BuyZoneCenter
    end

    if not center then return true end

    local radius = spawns.buyZoneRadius or 500
    return ply:GetPos():DistToSqr(center) <= (radius * radius)
end

-- ============================================================================
-- Добавьте в блок AddNetworkString в shared.lua
-- ============================================================================
if SERVER then
    -- (уже существующие строки...)
    util.AddNetworkString("STALKER_PlaySoundToAll")
    util.AddNetworkString("STALKER_PlaySoundToPlayer")
end

-- ============================================================================
-- Убедитесь что в shared.lua есть ВСЕ эти строки
-- ============================================================================
if SERVER then
    util.AddNetworkString("STALKER_MoneyUpdate")
    util.AddNetworkString("STALKER_MoneyNotify")
    util.AddNetworkString("STALKER_RankUpdate")
    util.AddNetworkString("STALKER_XPUpdate")
    util.AddNetworkString("STALKER_LevelUp")
    util.AddNetworkString("STALKER_BuyItem")
    util.AddNetworkString("STALKER_BuyResult")
    util.AddNetworkString("STALKER_TeamSelect")
    util.AddNetworkString("STALKER_OpenTeamMenu")   -- ОБЯЗАТЕЛЬНО!
    util.AddNetworkString("STALKER_ModelSelect")
    util.AddNetworkString("STALKER_OpenModelMenu")
    util.AddNetworkString("STALKER_StartFactionVote")
    util.AddNetworkString("STALKER_FactionVote")
    util.AddNetworkString("STALKER_FactionVoteUpdate")
    util.AddNetworkString("STALKER_FactionVoteResult")
    util.AddNetworkString("STALKER_StartMapVote")
    util.AddNetworkString("STALKER_MapVote")
    util.AddNetworkString("STALKER_MapVoteUpdate")
    util.AddNetworkString("STALKER_MapVoteResult")
    util.AddNetworkString("STALKER_RoundStateChange")
    util.AddNetworkString("STALKER_ScoreUpdate")
    util.AddNetworkString("STALKER_KillFeed")
    util.AddNetworkString("STALKER_SyncGameData")
    util.AddNetworkString("STALKER_PlaySoundToAll")
    util.AddNetworkString("STALKER_PlaySoundToPlayer")
end