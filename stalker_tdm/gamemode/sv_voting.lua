-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Серверная система (Без голосования за фракции)
-- ============================================================================

-- ============================================================================
-- НАСТРОЙКА ФРАКЦИЙ (Автоматически выбирает Наёмники vs Свободу)
-- ============================================================================
function GM:SetupDefaultFactions()
    -- Жёстко задаём первый (и единственный) набор фракций из конфига
    self.CurrentMatchup = 1
    
    -- Применяем настройки команд (TEAM_FACTION1, TEAM_FACTION2)
    self:SetupFactionTeams(self.CurrentMatchup)
    
    PrintMessage(HUD_PRINTTALK, "[STALKER] Матч: Наёмники против Свободы.")
end

-- ============================================================================
-- ЗАПУСК РАУНДА (Замена FinishFactionVote)
-- ============================================================================
function GM:StartMatchSequence()
    -- 1. Фиксируем фракции (без голосования)
    self:SetupDefaultFactions()

    -- 2. Сбрасываем всех в спектаторов, чтобы выбрать команду заново или автобаланс
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() ~= TEAM_SPECTATOR then
            ply:SetTeam(TEAM_SPECTATOR)
            ply:Spectate(OBS_MODE_ROAMING)
            ply:Spawn()
        end
    end
    
    -- 3. Открываем меню выбора команды игрокам (через небольшую задержку)
    timer.Simple(1.5, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Team() == TEAM_SPECTATOR then
                net.Start("STALKER_OpenTeamMenu")
                net.Send(ply)
            end
        end
    end)

    -- 4. Запускаем разминку через несколько секунд
    timer.Simple(5, function()
        self:StartWarmup()
    end)
end

-- ============================================================================
-- ГОЛОСОВАНИЕ ЗА КАРТУ
-- ============================================================================

function GM:StartMapVote()
    if self.RoundState == ROUND_MAP_VOTE then return end
    if self.MapVoteInProgress then return end
    
    self.MapVoteInProgress = true
    self:SetRoundState(ROUND_MAP_VOTE)
    self.RoundEndTime = CurTime() + STALKER_CONFIG.MapVoteTime

    -- Сбрасываем голоса
    self.MapVotes = {}
    for i, map in ipairs(STALKER_CONFIG.MapList) do
        self.MapVotes[i] = 0
    end
    self.MapVoters = {}

    -- Отправляем клиентам
    net.Start("STALKER_StartMapVote")
        net.WriteFloat(self.RoundEndTime)
        net.WriteUInt(#STALKER_CONFIG.MapList, 8)
        for _, mapName in ipairs(STALKER_CONFIG.MapList) do
            net.WriteString(mapName)
        end
    net.Broadcast()

    PrintMessage(HUD_PRINTTALK, "[STALKER] Голосование за карту! " .. STALKER_CONFIG.MapVoteTime .. " сек.")
end

net.Receive("STALKER_MapVote", function(len, ply)
    local choice = net.ReadUInt(8)

    if not GAMEMODE.MapVotes then return end
    if GAMEMODE.RoundState ~= ROUND_MAP_VOTE then return end
    if GAMEMODE.MapVoters[ply:SteamID()] then return end

    if choice < 1 or choice > #STALKER_CONFIG.MapList then return end

    GAMEMODE.MapVotes[choice] = (GAMEMODE.MapVotes[choice] or 0) + 1
    GAMEMODE.MapVoters[ply:SteamID()] = choice

    -- Обновление
    net.Start("STALKER_MapVoteUpdate")
        for i = 1, #STALKER_CONFIG.MapList do
            net.WriteUInt(GAMEMODE.MapVotes[i] or 0, 8)
        end
    net.Broadcast()

    ply:ChatPrint("[STALKER] Голос за карту принят!")
end)

function GM:FinishMapVote()
    if not self.MapVoteInProgress then return end
    self.MapVoteInProgress = false

    local maxVotes = 0
    local winnerMap = STALKER_CONFIG.MapList[1] or game.GetMap()

    if self.MapVotes then
        for i, votes in pairs(self.MapVotes) do
            if votes > maxVotes then
                maxVotes = votes
                winnerMap = STALKER_CONFIG.MapList[i]
            end
        end
    end

    net.Start("STALKER_MapVoteResult")
        net.WriteString(winnerMap)
    net.Broadcast()

    PrintMessage(HUD_PRINTTALK, "[STALKER] Следующая карта: " .. winnerMap)

    -- Смена карты через 5 секунд
    timer.Simple(5, function()
        RunConsoleCommand("changelevel", winnerMap)
    end)
end -- БЫЛО end)