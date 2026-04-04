-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Система раундов со звуками и отсчётом
-- (Без голосования за фракции — всегда Наёмники vs Свобода)
-- ============================================================================

-- Изменить состояние раунда
function GM:SetRoundState(state)
    self.RoundState = state
    net.Start("STALKER_RoundStateChange")
        net.WriteUInt(state, 4)
        net.WriteFloat(self.RoundEndTime or 0)
    net.Broadcast()
end

-- ============================================================================
-- Автоматическая установка фракций (замена голосования)
-- ============================================================================
function GM:SetupDefaultFactions()
    self.CurrentMatchup = 1
    self:SetupFactionTeams(self.CurrentMatchup)
    PrintMessage(HUD_PRINTTALK, "[STALKER] Фракции: Наёмники против Свободы.")
end

-- ============================================================================
-- Запуск последовательности матча (замена StartFactionVote + FinishFactionVote)
-- ============================================================================
function GM:StartMatchSequence()
    -- Защита от повторного вызова
    if self.MatchSequenceStarted then return end
    self.MatchSequenceStarted = true

    -- 1. Устанавливаем фракции без голосования
    self:SetupDefaultFactions()

    -- 2. Открываем меню выбора команды игрокам
    timer.Simple(1, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Team() ~= TEAM_FACTION1 and ply:Team() ~= TEAM_FACTION2 then
                net.Start("STALKER_OpenTeamMenu")
                net.Send(ply)
            end
        end
    end)

    -- 3. Через несколько секунд запускаем разминку
    timer.Simple(5, function()
        self.MatchSequenceStarted = false
        if self.RoundState ~= ROUND_WARMUP and self.RoundState ~= ROUND_ACTIVE then
            self:StartWarmup()
        end
    end)
end

-- ============================================================================
-- Запуск нового раунда
-- ============================================================================
function GM:StartRound()
    self.TeamScores = { [TEAM_FACTION1] = 0, [TEAM_FACTION2] = 0 }
    self:BroadcastScores()
    self.RoundEndTime = CurTime() + STALKER_CONFIG.RoundTime

    -- Флаг лидера (чтобы не спамить звук)
    self.CurrentLeader = nil

    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_FACTION1 or ply:Team() == TEAM_FACTION2 then
            ply:SetNWInt("STALKER_Killstreak", 0)
            ply:SetNWInt("STALKER_ArmorLevel", 0)  -- Сброс брони на старте раунда
            ply:Spawn()
        end
    end

    self:SetRoundState(ROUND_ACTIVE)
    self:PlaySoundToAll(STALKER_CONFIG.Sounds.RoundStart)
end

-- ============================================================================
-- Разминка
-- ============================================================================
function GM:StartWarmup()
    self:SetRoundState(ROUND_WARMUP)
    self.RoundEndTime = CurTime() + STALKER_CONFIG.WarmupTime
    self:PlaySoundToAll(STALKER_CONFIG.Sounds.Ready)
    PrintMessage(HUD_PRINTTALK, "[STALKER] Разминка! Раунд начнётся через " ..
        STALKER_CONFIG.WarmupTime .. " сек.")
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_FACTION1 or ply:Team() == TEAM_FACTION2 then
            ply:Spawn()
        end
    end
end

-- ============================================================================
-- Завершение раунда
-- ============================================================================
function GM:EndRound(winnerTeam)
    if self.RoundState == ROUND_ENDING then return end

    self:SetRoundState(ROUND_ENDING)
    self.RoundEndTime = CurTime() + STALKER_CONFIG.EndRoundTime

    local matchup    = self:GetCurrentMatchup()
    local winnerName = "Ничья"

    if winnerTeam == TEAM_FACTION1 then
        winnerName = matchup.team1.name
        self:PlaySoundToAll(STALKER_CONFIG.Sounds.MercWin)
    elseif winnerTeam == TEAM_FACTION2 then
        winnerName = matchup.team2.name
        self:PlaySoundToAll(STALKER_CONFIG.Sounds.FreedomWin)
    else
        self:PlaySoundToAll(STALKER_CONFIG.Sounds.Draw)
    end

    PrintMessage(HUD_PRINTTALK, "[STALKER] Раунд окончен! Победитель: " .. winnerName)

    -- XP за победу / поражение
    for _, ply in ipairs(player.GetAll()) do
        if ply:Team() == winnerTeam then
            self:AddXP(ply, STALKER_CONFIG.XPRewards.TeamWin)
        elseif ply:Team() == TEAM_FACTION1 or ply:Team() == TEAM_FACTION2 then
            self:AddXP(ply, STALKER_CONFIG.XPRewards.TeamLose)
        end
    end

    -- Сброс рангов, денег, брони
    self:ResetAllRanks()

    if STALKER_CONFIG.ResetMoneyOnMapChange then
        for _, ply in ipairs(player.GetAll()) do
            ply:SetNWInt("STALKER_Money", STALKER_CONFIG.StartMoney)
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        ply:SetNWString("STALKER_ArmorType", "")
        ply:SetNWInt("STALKER_ArmorLevel", 0)
        ply:SetNWInt("STALKER_ModelIndex", 0)
    end
end

-- ============================================================================
-- Трансляция счёта
-- ============================================================================
function GM:BroadcastScores()
    net.Start("STALKER_ScoreUpdate")
        net.WriteInt(self.TeamScores[TEAM_FACTION1] or 0, 16)
        net.WriteInt(self.TeamScores[TEAM_FACTION2] or 0, 16)
    net.Broadcast()
end

-- ============================================================================
-- Проверка лидерства и счёта (звуки)
-- ============================================================================
function GM:CheckScoreEvents(scoringTeam)
    local s1 = self.TeamScores[TEAM_FACTION1] or 0
    local s2 = self.TeamScores[TEAM_FACTION2] or 0

    -- Счёт сравнялся
    if s1 == s2 then
        self:PlaySoundToAll(STALKER_CONFIG.Sounds.ScoreEqual)
        self.CurrentLeader = nil
        return
    end

    -- Определяем нового лидера
    local newLeader = (s1 > s2) and TEAM_FACTION1 or TEAM_FACTION2

    -- Звук лидерства — только если лидер сменился
    if newLeader ~= self.CurrentLeader then
        self.CurrentLeader = newLeader
        if newLeader == TEAM_FACTION1 then
            self:PlaySoundToAll(STALKER_CONFIG.Sounds.MercLead)
        else
            self:PlaySoundToAll(STALKER_CONFIG.Sounds.FreedomLead)
        end
    end
end

-- ============================================================================
-- Отсчёт перед голосованием карты (5..1)
-- ============================================================================
function GM:StartMapCountdown()
    if self.MapCountdownStarted then return end
    self.MapCountdownStarted = true

    local counts = {
        [1] = STALKER_CONFIG.Sounds.Count5,
        [2] = STALKER_CONFIG.Sounds.Count4,
        [3] = STALKER_CONFIG.Sounds.Count3,
        [4] = STALKER_CONFIG.Sounds.Count2,
        [5] = STALKER_CONFIG.Sounds.Count1,
    }

    PrintMessage(HUD_PRINTTALK, "[STALKER] Смена карты через 5 секунд...")

    for i = 1, 5 do
        local delay = i - 1
        local snd   = counts[i]
        timer.Simple(delay, function()
            if snd then GAMEMODE:PlaySoundToAll(snd) end
        end)
    end

    -- После отсчёта — голосование за карту
    timer.Simple(5, function()
        self.MapCountdownStarted = false
        self:StartMapVote()
    end)
end

-- ============================================================================
-- GAME THINK (Исправленный — без голосования за фракции)
-- ============================================================================
function GM:Think()
    self.BaseClass:Think(self)

    local curTime      = CurTime()
    local totalPlayers = team.NumPlayers(TEAM_FACTION1) + team.NumPlayers(TEAM_FACTION2)

    -- ====================================================================
    -- ROUND_WAITING — ждём игроков, затем запускаем матч
    -- ====================================================================
    if self.RoundState == ROUND_WAITING then
        -- Как только есть хотя бы 1 игрок — запускаем
        if totalPlayers >= 1 then
            self:StartMatchSequence()
        end

    -- ====================================================================
    -- ROUND_WARMUP — разминка перед боем
    -- ====================================================================
    elseif self.RoundState == ROUND_WARMUP then
        if self.RoundEndTime and curTime >= self.RoundEndTime then
            self:StartRound()
        end

    -- ====================================================================
    -- ROUND_ACTIVE — бой идёт
    -- ====================================================================
    elseif self.RoundState == ROUND_ACTIVE then
        -- Таймер раунда истёк
        if self.RoundEndTime and curTime >= self.RoundEndTime then
            local s1 = self.TeamScores[TEAM_FACTION1] or 0
            local s2 = self.TeamScores[TEAM_FACTION2] or 0
            local winner = nil
            if s1 > s2 then winner = TEAM_FACTION1
            elseif s2 > s1 then winner = TEAM_FACTION2 end
            self:EndRound(winner)
        end

        -- Все игроки ушли — возврат в ожидание
        if totalPlayers < 1 then
            self.MatchSequenceStarted = false  -- Сбрасываем флаг
            self:SetRoundState(ROUND_WAITING)
        end

    -- ====================================================================
    -- ROUND_ENDING — показ результатов
    -- ====================================================================
    elseif self.RoundState == ROUND_ENDING then
        if self.RoundEndTime and curTime >= self.RoundEndTime then
            self:StartMapCountdown()
        end

    -- ====================================================================
    -- ROUND_MAP_VOTE — голосование за карту
    -- ====================================================================
    elseif self.RoundState == ROUND_MAP_VOTE then
        if self.RoundEndTime and curTime >= self.RoundEndTime then
            self:FinishMapVote()
        end
    end
end