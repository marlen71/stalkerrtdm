-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Клиентская инициализация
-- ============================================================================

include("shared.lua")
include("cl_fonts.lua")
include("cl_hud.lua")
include("cl_shop.lua")
include("cl_scoreboard.lua")
include("cl_voting.lua")
include("cl_settings.lua")
include("cl_deathscreen.lua")

-- Явно подключаем меню (GMod ищет файлы в папке gamemode автоматически)
include("cl_modelmenu.lua")
include("cl_teammenu.lua")

-- ============================================================================
-- ПРОВЕРКА СРАЗУ ПОСЛЕ ПОДКЛЮЧЕНИЯ
-- ============================================================================
print("[STALKER] После include cl_teammenu: " .. type(STALKER_OpenTeamMenu))
print("[STALKER] После include cl_modelmenu: " .. type(STALKER_OpenModelMenu))

-- ============================================================================
-- КЛИЕНТСКИЕ ДАННЫЕ
-- ============================================================================
STALKER_CLIENT = STALKER_CLIENT or {
    RoundState     = ROUND_WAITING,
    RoundEndTime   = 0,
    CurrentMatchup = 1,
    TeamScores     = { [TEAM_FACTION1] = 0, [TEAM_FACTION2] = 0 },

    KillFeed            = {},
    KillFeedMaxItems    = 6,
    KillFeedDuration    = 6,

    MoneyNotifications  = {},
    MoneyNotifDuration  = 3,

    Visuals      = table.Copy(STALKER_CONFIG.DefaultVisuals),
    LevelUpNotif = nil,
    LevelUpTime  = 0,
}

-- ============================================================================
-- НАСТРОЙКИ
-- ============================================================================
function STALKER_LoadClientSettings()
    local raw = file.Read("stalker_tdm/client_settings.json", "DATA")
    if raw then
        local data = util.JSONToTable(raw)
        if data and data.Visuals then
            for k, v in pairs(data.Visuals) do
                STALKER_CLIENT.Visuals[k] = v
            end
        end
    end
end

function STALKER_SaveClientSettings()
    if not file.IsDir("stalker_tdm", "DATA") then
        file.CreateDir("stalker_tdm")
    end
    file.Write("stalker_tdm/client_settings.json",
        util.TableToJSON({ Visuals = STALKER_CLIENT.Visuals }))
end

STALKER_LoadClientSettings()

-- ============================================================================
-- СЕТЕВЫЕ ПРИЁМНИКИ
-- ============================================================================
net.Receive("STALKER_SyncGameData", function()
    STALKER_CLIENT.RoundState                = net.ReadUInt(4)
    STALKER_CLIENT.RoundEndTime              = net.ReadFloat()
    STALKER_CLIENT.CurrentMatchup            = net.ReadUInt(4)
    STALKER_CLIENT.TeamScores[TEAM_FACTION1] = net.ReadInt(16)
    STALKER_CLIENT.TeamScores[TEAM_FACTION2] = net.ReadInt(16)
end)

net.Receive("STALKER_RoundStateChange", function()
    STALKER_CLIENT.RoundState   = net.ReadUInt(4)
    STALKER_CLIENT.RoundEndTime = net.ReadFloat()
end)

net.Receive("STALKER_ScoreUpdate", function()
    STALKER_CLIENT.TeamScores[TEAM_FACTION1] = net.ReadInt(16)
    STALKER_CLIENT.TeamScores[TEAM_FACTION2] = net.ReadInt(16)
end)

net.Receive("STALKER_MoneyNotify", function()
    local amount = net.ReadInt(32)
    local reason = net.ReadString()
    table.insert(STALKER_CLIENT.MoneyNotifications, {
        amount = amount,
        reason = reason,
        time   = CurTime(),
    })
end)

net.Receive("STALKER_LevelUp", function()
    local rank = net.ReadUInt(8)
    local name = net.ReadString()
    STALKER_CLIENT.LevelUpNotif = { rank = rank, name = name }
    STALKER_CLIENT.LevelUpTime  = CurTime()
end)

net.Receive("STALKER_KillFeed", function()
    table.insert(STALKER_CLIENT.KillFeed, 1, {
        attacker     = net.ReadString(),
        attackerTeam = net.ReadUInt(4),
        victim       = net.ReadString(),
        victimTeam   = net.ReadUInt(4),
        weapon       = net.ReadString(),
        headshot     = net.ReadBool(),
        knife        = net.ReadBool(),
        time         = CurTime(),
    })
    while #STALKER_CLIENT.KillFeed > STALKER_CLIENT.KillFeedMaxItems do
        table.remove(STALKER_CLIENT.KillFeed)
    end
end)

net.Receive("STALKER_BuyResult", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    table.insert(STALKER_CLIENT.MoneyNotifications, {
        amount  = 0,
        reason  = message,
        time    = CurTime(),
        isShop  = true,
        success = success,
    })
    if not success then
        surface.PlaySound(STALKER_CONFIG.Sounds.CantBuy)
    end
end)

net.Receive("STALKER_XPUpdate", function()
    -- резерв
end)

net.Receive("STALKER_PlaySoundToAll", function()
    surface.PlaySound(net.ReadString())
end)

net.Receive("STALKER_PlaySoundToPlayer", function()
    surface.PlaySound(net.ReadString())
end)

-- Сервер просит открыть меню команды
net.Receive("STALKER_OpenTeamMenu", function()
    timer.Simple(0.2, function()
        if not IsValid(LocalPlayer()) then return end
        if type(STALKER_OpenTeamMenu) == "function" then
            STALKER_OpenTeamMenu()
        else
            print("[STALKER] ОШИБКА: STALKER_OpenTeamMenu не найдена!")
        end
    end)
end)

-- ============================================================================
-- БИНДЫ
-- ============================================================================
local keyStates = {}

hook.Add("Think", "STALKER_KeyBinds", function()
    if not IsValid(LocalPlayer()) then return end

    -- M — Меню команды
    local mDown = input.IsKeyDown(KEY_M)
    if mDown and not keyStates[KEY_M] then
        keyStates[KEY_M] = true
        if type(STALKER_OpenTeamMenu) == "function" then
            STALKER_OpenTeamMenu()
        else
            print("[STALKER] STALKER_OpenTeamMenu не найдена! Тип: " 
                .. type(STALKER_OpenTeamMenu))
        end
    elseif not mDown then
        keyStates[KEY_M] = false
    end

    -- B — Магазин
    local bDown = input.IsKeyDown(KEY_B)
    if bDown and not keyStates[KEY_B] then
        keyStates[KEY_B] = true
        if type(STALKER_OpenShop) == "function" then
            STALKER_OpenShop()
        end
    elseif not bDown then
        keyStates[KEY_B] = false
    end

    -- F2 — Настройки
    local f2Down = input.IsKeyDown(KEY_F2)
    if f2Down and not keyStates[KEY_F2] then
        keyStates[KEY_F2] = true
        if type(STALKER_OpenSettings) == "function" then
            STALKER_OpenSettings()
        end
    elseif not f2Down then
        keyStates[KEY_F2] = false
    end
end)

-- ============================================================================
-- СКРЫТИЕ СТАНДАРТНОГО HUD
-- ============================================================================
hook.Add("HUDShouldDraw", "STALKER_HideHUD", function(name)
    local hide = {
        ["CHudHealth"]                = true,
        ["CHudBattery"]               = true,
        ["CHudAmmo"]                  = true,
        ["CHudSecondaryAmmo"]         = true,
        ["CHudDamageIndicator"]       = true,
        ["CHudCrosshair"]             = true,
        ["CHudGeiger"]                = true,
        ["CHudBench"]                 = true,
        ["CHudPoisonDamageIndicator"] = true,
        ["CHudSquadStatus"]           = true,
        ["CHudNPCUsedWeapon"]         = true,
    }
    if hide[name] then return false end
end)

hook.Add("HUDDrawTargetID", "STALKER_HideTargetID", function()
    return false
end)

-- ============================================================================
-- БЛОКИРОВКА ZOOM
-- ============================================================================
hook.Add("PlayerBindPress", "STALKER_BlockZoom", function(ply, bind, pressed)
    if bind == "+zoom" then return true end
end)

-- ============================================================================
-- ПРОВЕРКА ЗАГРУЗКИ
-- ============================================================================
hook.Add("InitPostEntity", "STALKER_CheckFunctions", function()
    timer.Simple(2, function()
        print("[STALKER] === ПРОВЕРКА ФУНКЦИЙ ===")
        print("[STALKER] STALKER_OpenTeamMenu: " 
            .. type(STALKER_OpenTeamMenu))
        print("[STALKER] STALKER_OpenShop: "     
            .. type(STALKER_OpenShop))
        print("[STALKER] STALKER_OpenModelMenu: " 
            .. type(STALKER_OpenModelMenu))
        print("[STALKER] ========================")
    end)
end)
