-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Серверная система команд (исправленный)
-- ============================================================================

util.AddNetworkString("STALKER_ModelSelect")
util.AddNetworkString("STALKER_OpenModelMenu")

-- Настройка команд по выбранному набору фракций
function GM:SetupFactionTeams(matchupIndex)
    local matchup = STALKER_CONFIG.FactionMatchups[matchupIndex]
    if not matchup then
        matchup = STALKER_CONFIG.FactionMatchups[1]
        matchupIndex = 1
    end

    self.CurrentMatchup = matchupIndex

    team.SetUp(TEAM_FACTION1, matchup.team1.name, matchup.team1.color, true)
    team.SetUp(TEAM_FACTION2, matchup.team2.name, matchup.team2.color, true)

    print("[STALKER TDM] Фракции установлены: " ..
        matchup.team1.name .. " vs " .. matchup.team2.name)
end

function GM:GetCurrentMatchup()
    return STALKER_CONFIG.FactionMatchups[self.CurrentMatchup]
end

function GM:GetPlayerFactionID(ply)
    local matchup = self:GetCurrentMatchup()
    if not matchup then return nil end
    
    if ply:Team() == TEAM_FACTION1 then
        return matchup.team1.id
    elseif ply:Team() == TEAM_FACTION2 then
        return matchup.team2.id
    end
    return nil
end

function GM:GetAvailableModels(ply, ignoreArmor)
    local factionID = self:GetPlayerFactionID(ply)
    if not factionID then return {} end
    
    if not ignoreArmor then
        local armorType = ply:GetNWString("STALKER_ArmorType", "")
        if armorType ~= "" and STALKER_CONFIG.ArmorModels[armorType] then
            local armorModels = STALKER_CONFIG.ArmorModels[armorType][factionID]
            if armorModels and #armorModels > 0 then
                return armorModels
            end
        end
    end
    
    local matchup = self:GetCurrentMatchup()
    if ply:Team() == TEAM_FACTION1 then
        return matchup.team1.models
    else
        return matchup.team2.models
    end
end

function GM:SetPlayerModel(ply)
    local models = self:GetAvailableModels(ply)
    if #models == 0 then return end
    
    local selectedIndex = ply:GetNWInt("STALKER_ModelIndex", 0)
    if selectedIndex > 0 and selectedIndex <= #models and ply:GetNWString("STALKER_ArmorType", "") == "" then
        ply:SetModel(models[selectedIndex])
    else
        ply:SetModel(models[math.random(#models)])
    end
end

-- ============================================================================
-- ОБРАБОТКА ВЫБОРА КОМАНДЫ (исправлено - флаг HasChosenTeam)
-- ============================================================================
net.Receive("STALKER_TeamSelect", function(len, ply)
    local teamID = net.ReadUInt(4)

    if teamID ~= TEAM_FACTION1 and teamID ~= TEAM_FACTION2 then return end

    -- Проверка кулдауна
    local lastSwitch = ply:GetNWFloat("STALKER_LastTeamSwitch", 0)
    if CurTime() - lastSwitch < STALKER_CONFIG.TeamSwitchCooldown then
        local remaining = math.ceil(STALKER_CONFIG.TeamSwitchCooldown - (CurTime() - lastSwitch))
        ply:ChatPrint("[STALKER] Смена команды доступна через " .. remaining .. " сек.")
        return
    end

    -- Проверка баланса команд
    local team1Count = team.NumPlayers(TEAM_FACTION1)
    local team2Count = team.NumPlayers(TEAM_FACTION2)
    local maxDiff = 2

    if teamID == TEAM_FACTION1 and team1Count - team2Count >= maxDiff then
        ply:ChatPrint("[STALKER] Команда переполнена! Выберите другую.")
        return
    elseif teamID == TEAM_FACTION2 and team2Count - team1Count >= maxDiff then
        ply:ChatPrint("[STALKER] Команда переполнена! Выберите другую.")
        return
    end

    -- Сброс данных при смене команды
    ply:SetNWString("STALKER_ArmorType", "")
    ply:SetNWInt("STALKER_ModelIndex", 0)
    
    -- Устанавливаем команду и флаг
    ply:SetTeam(teamID)
    ply:SetNWFloat("STALKER_LastTeamSwitch", CurTime())
    ply:SetNWBool("STALKER_HasChosenTeam", true) -- Игрок выбрал команду!

    local matchup = GAMEMODE:GetCurrentMatchup()
    local teamName = (teamID == TEAM_FACTION1) and matchup.team1.name or matchup.team2.name

    PrintMessage(HUD_PRINTTALK, "[STALKER] " .. ply:Nick() .. " присоединился к " .. teamName)

    -- Открываем меню выбора модели сразу
    timer.Simple(0.3, function()
        if IsValid(ply) then
            GAMEMODE:OpenModelMenuForPlayer(ply)
        end
    end)

    -- Спавним если раунд активен или разминка
    if GAMEMODE.RoundState == ROUND_ACTIVE or GAMEMODE.RoundState == ROUND_WARMUP then
        ply:Spawn()
    end
end)

-- ============================================================================
-- ВЫБОР МОДЕЛИ
-- ============================================================================
function GM:OpenModelMenuForPlayer(ply)
    local factionID = self:GetPlayerFactionID(ply)
    if not factionID then return end
    
    local matchup = self:GetCurrentMatchup()
    local teamData = (ply:Team() == TEAM_FACTION1) and matchup.team1 or matchup.team2
    
    net.Start("STALKER_OpenModelMenu")
        net.WriteString(teamData.name)
        net.WriteString(factionID)
        net.WriteUInt(#teamData.models, 4)
        for _, mdl in ipairs(teamData.models) do
            net.WriteString(mdl)
        end
    net.Send(ply)
end

net.Receive("STALKER_ModelSelect", function(len, ply)
    local modelIndex = net.ReadUInt(4)
    local factionID = GAMEMODE:GetPlayerFactionID(ply)
    
    if not factionID then return end
    
    local matchup = GAMEMODE:GetCurrentMatchup()
    local models = (ply:Team() == TEAM_FACTION1) and matchup.team1.models or matchup.team2.models
    
    if modelIndex > 0 and modelIndex <= #models then
        ply:SetNWInt("STALKER_ModelIndex", modelIndex)
        
        -- Меняем модель сразу если жив и без брони
        if ply:Alive() and ply:GetNWString("STALKER_ArmorType", "") == "" then
            ply:SetModel(models[modelIndex])
        end
        
        ply:ChatPrint("[STALKER] Модель выбрана!")
    end
end)