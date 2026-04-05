-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Серверная инициализация (исправленный)
-- ============================================================================

-- init.lua — серверная сторона
-- Добавить ЭТО в init.lua чтобы файлы выполнялись на клиенте:
AddCSLuaFile("cl_fonts.lua")
AddCSLuaFile("config.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_shop.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_voting.lua")
AddCSLuaFile("cl_settings.lua")
AddCSLuaFile("cl_deathscreen.lua")
AddCSLuaFile("cl_modelmenu.lua")
AddCSLuaFile("cl_teammenu.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")
include("sv_economy.lua")
include("sv_ranks.lua")
include("sv_spawns.lua")
include("sv_voting.lua")
include("sv_rounds.lua")
include("sv_teams.lua")

-- ============================================================================
-- ИНИЦИАЛИЗАЦИЯ GAMEMODE
-- ============================================================================
function GM:Initialize()
    self.BaseClass:Initialize()
    print("[STALKER TDM] Gamemode initialized!")

    -- Текущие фракции (по умолчанию — первый набор)
    self.CurrentMatchup = 1

    -- Состояние раунда
    self.RoundState = ROUND_WAITING
    self.RoundStartTime = 0
    self.RoundEndTime = 0

    -- Флаги для защиты от спама
    self.MapVoteInProgress = false

    -- Счёт команд
    self.TeamScores = { [TEAM_FACTION1] = 0, [TEAM_FACTION2] = 0 }

    -- Kill feed
    self.KillFeed = {}
end

-- ============================================================================
-- ПОДКЛЮЧЕНИЕ ИГРОКА (исправлено - нет спама меню)
-- ============================================================================
function GM:PlayerInitialSpawn(ply)
    -- Инициализация данных игрока (всегда с чистого листа!)
    ply:SetNWInt("STALKER_Money", STALKER_CONFIG.StartMoney)
    ply:SetNWInt("STALKER_XP", 0)
    ply:SetNWInt("STALKER_Rank", 1)
    ply:SetNWInt("STALKER_Kills", 0)
    ply:SetNWInt("STALKER_Deaths", 0)
    ply:SetNWInt("STALKER_Killstreak", 0)
    ply:SetNWFloat("STALKER_LastTeamSwitch", 0)
    ply:SetNWString("STALKER_ArmorType", "")
    ply:SetNWInt("STALKER_ModelIndex", 0)
    ply:SetNWBool("STALKER_HasChosenTeam", false) -- Флаг: выбирал ли уже команду

    -- Синхронизируем данные
    self:SyncGameData(ply)
    
    -- Показываем меню ТОЛЬКО если игрок ещё не выбирал команду в этой сессии
    -- и если мы не в активном раунде (т.е. только при первом заходе или после голосования)
    timer.Simple(1, function()
        if IsValid(ply) and not ply:GetNWBool("STALKER_HasChosenTeam", false) then
            -- Показываем меню только в состоянии ожидания или голосования
            if self.RoundState == ROUND_WAITING or self.RoundState == ROUND_VOTING then
                net.Start("STALKER_OpenTeamMenu")
                net.Send(ply)
            end
        end
    end)
end

-- Синхронизация данных раунда для нового игрока
function GM:SyncGameData(ply)
    net.Start("STALKER_SyncGameData")
        net.WriteUInt(self.RoundState, 4)
        net.WriteFloat(self.RoundEndTime or 0)
        net.WriteUInt(self.CurrentMatchup, 4)
        net.WriteInt(self.TeamScores[TEAM_FACTION1] or 0, 16)
        net.WriteInt(self.TeamScores[TEAM_FACTION2] or 0, 16)
    net.Send(ply)
end

-- ============================================================================
-- СПАВН ИГРОКА (не открываем меню здесь!)
-- ============================================================================
function GM:PlayerSpawn(ply)
    -- Если игрок не в команде — не спавнить (только наблюдение)
    if ply:Team() ~= TEAM_FACTION1 and ply:Team() ~= TEAM_FACTION2 then
        ply:Spectate(OBS_MODE_ROAMING)
        ply:StripWeapons()
        return
    end

    ply:UnSpectate()
    
    -- Стандартное поведение
    self.BaseClass:PlayerSpawn(ply)

    -- Установка модели (с учётом брони)
    self:SetPlayerModel(ply)

    -- Скорость (экзоскелет замедляет)
    local walkSpeed = 200
    local runSpeed = 350
    if ply:GetNWString("STALKER_ArmorType") == "armor_exo" then
        walkSpeed = 150
        runSpeed = 280
    end
    ply:SetWalkSpeed(walkSpeed)
    ply:SetRunSpeed(runSpeed)

    -- Выдача стандартного снаряжения
    self:GiveDefaultLoadout(ply)

    -- Защита от спавн-килла
    self:ApplySpawnProtection(ply)

    -- Перемещение на спавн
    self:MoveToSpawn(ply)

    -- Сброс killstreak
    ply:SetNWInt("STALKER_Killstreak", 0)
end

-- Выдача стартового снаряжения
function GM:GiveDefaultLoadout(ply)
    ply:StripWeapons()
    ply:RemoveAllAmmo()

    for _, wep in ipairs(STALKER_CONFIG.DefaultLoadout.weapons) do
        ply:Give(wep)
    end

    for _, ammoData in ipairs(STALKER_CONFIG.DefaultLoadout.ammo) do
        ply:GiveAmmo(ammoData.count, ammoData.type, true)
    end

    ply:SetArmor(0) -- Броня сброшена, при респавне без брони
end

-- Установка модели по фракции и броне
function GM:SetPlayerModel(ply)
    local models = self:GetAvailableModels(ply)
    if #models == 0 then return end
    
    local selectedIndex = ply:GetNWInt("STALKER_ModelIndex", 0)
    if selectedIndex > 0 and selectedIndex <= #models then
        ply:SetModel(models[selectedIndex])
    else
        ply:SetModel(models[math.random(#models)])
    end
end

-- Защита от спавн-килла
function GM:ApplySpawnProtection(ply)
    ply:GodEnable()
    ply.SpawnProtected = true
    ply:SetRenderMode(RENDERMODE_TRANSALPHA)
    ply:SetColor(Color(255, 255, 255, 150))

    timer.Simple(STALKER_CONFIG.SpawnProtectionTime, function()
        if IsValid(ply) then
            ply:GodDisable()
            ply.SpawnProtected = false
            ply:SetRenderMode(RENDERMODE_NORMAL)
            ply:SetColor(Color(255, 255, 255, 255))
        end
    end)
end

-- ============================================================================
-- СМЕРТЬ ИГРОКА — дополнение к основному init.lua
-- Вставьте эту функцию в ваш init.lua
-- ============================================================================
function GM:PlayerDeath(victim, inflictor, attacker)
    if not IsValid(victim) then return end

    victim:SetNWInt("STALKER_Deaths",    victim:GetNWInt("STALKER_Deaths", 0) + 1)
    victim:SetNWInt("STALKER_Killstreak", 0)
    victim:SetNWString("STALKER_ArmorType", "")

    local isHeadshot = victim:LastHitGroup() == HITGROUP_HEAD
    local isKnife    = false
    local isSuicide  = false
    local isTeamKill = false

    if IsValid(attacker) and attacker:IsPlayer() then
        if attacker == victim then
            isSuicide = true
        else
            local wep = attacker:GetActiveWeapon()
            if IsValid(wep) then
                local wc = wep:GetClass()
                if wc:find("knife") or wc == "weapon_crowbar" or wc == "weapon_stunstick" then
                    isKnife = true
                end
            end
            if attacker:Team() == victim:Team() then
                isTeamKill = true
            end
        end
    end

    -- Экономика и XP
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        if isTeamKill then
            self:AddMoney(attacker, STALKER_CONFIG.Rewards.TeamKill, "Убийство союзника")
        else
            -- Деньги
            if isKnife then
                self:AddMoney(attacker, STALKER_CONFIG.Rewards.KnifeKill, "Убийство ножом!")
            else
                self:AddMoney(attacker, STALKER_CONFIG.Rewards.Kill, "Убийство")
                if isHeadshot then
                    self:AddMoney(attacker, STALKER_CONFIG.Rewards.Headshot, "Хедшот!")
                end
            end

            -- XP
            self:AddXP(attacker, STALKER_CONFIG.XPRewards.Kill)
            if isHeadshot then
                self:AddXP(attacker, STALKER_CONFIG.XPRewards.Headshot)
            end

            -- Статистика
            attacker:SetNWInt("STALKER_Kills",
                attacker:GetNWInt("STALKER_Kills", 0) + 1)
            local streak = attacker:GetNWInt("STALKER_Killstreak", 0) + 1
            attacker:SetNWInt("STALKER_Killstreak", streak)

            -- Звуки убийств (только атакующему)
            if isKnife then
                self:PlaySoundToPlayer(attacker, STALKER_CONFIG.Sounds.KnifeKill)
            elseif isHeadshot then
                self:PlaySoundToPlayer(attacker, STALKER_CONFIG.Sounds.Headshot)
            end

            -- Серия убийств
            if STALKER_CONFIG.KillstreakBonuses[streak] then
                self:AddMoney(attacker,
                    STALKER_CONFIG.KillstreakBonuses[streak],
                    "Серия: " .. streak .. " убийств!")
                self:PlaySoundToPlayer(attacker, STALKER_CONFIG.Sounds.Killstreak)
            end

            -- Счёт команды
            if self.RoundState == ROUND_ACTIVE then
                local t = attacker:Team()
                self.TeamScores[t] = (self.TeamScores[t] or 0) + 1
                self:BroadcastScores()
                self:CheckScoreEvents(t)

                if self.TeamScores[t] >= STALKER_CONFIG.FragLimit then
                    self:EndRound(t)
                end
            end
        end
    elseif isSuicide then
        self:AddMoney(victim, STALKER_CONFIG.Rewards.Suicide, "Самоубийство")
    end

    self:SendKillFeed(attacker, victim, inflictor, isHeadshot, isKnife)
end

-- ============================================================================
-- SEND KILL FEED
-- ============================================================================
function GM:SendKillFeed(attacker, victim, inflictor, isHeadshot, isKnife)
    if not IsValid(victim) then return end

    local attackerName = "Мир"
    local attackerTeam = 0
    if IsValid(attacker) and attacker:IsPlayer() then
        attackerName = attacker:Nick()
        attackerTeam = attacker:Team()
    end

    local weaponName = ""
    if IsValid(inflictor) and inflictor:IsWeapon() then
        weaponName = inflictor:GetClass()
    elseif IsValid(attacker) and attacker:IsPlayer() then
        local wep = attacker:GetActiveWeapon()
        if IsValid(wep) then weaponName = wep:GetClass() end
    end

    net.Start("STALKER_KillFeed")
        net.WriteString(attackerName)
        net.WriteUInt(attackerTeam, 4)
        net.WriteString(victim:Nick())
        net.WriteUInt(victim:Team(), 4)
        net.WriteString(weaponName)
        net.WriteBool(isHeadshot)
        net.WriteBool(isKnife)
    net.Broadcast()
end

-- В GM:Initialize или отдельным хуком

-- ============================================================================
-- УРОН ОТ ПАДЕНИЯ (включаем)
-- ============================================================================
hook.Add("Initialize", "STALKER_EnableFallDamage", function()
    -- Убираем блокировку урона от падения если она была
    RunConsoleCommand("sv_falldamage", "1")
end)

-- Реальный урон от падения (формула как в CS/оригинальном GMod)
hook.Add("GetFallDamage", "STALKER_FallDamage", function(ply, vel)
    -- Урон начинается при скорости падения > 450 юнитов/с
    if vel < 450 then return 0 end
    -- Урон пропорционален скорости
    local damage = (vel - 450) * 0.25
    return math.Clamp(damage, 0, 100)
end)

-- ============================================================================
-- ГОЛОСОВОЙ ЧАТ (общий для всех)
-- ============================================================================
hook.Add("PlayerCanHearPlayersVoice", "STALKER_GlobalVoice", function(listener, talker)
    -- Все слышат всех (глобальный голосовой чат)
    if IsValid(listener) and IsValid(talker) then
        return true, false -- true = слышит, false = не 3D позиционирование
    end
end)

-- ============================================================================
-- ЗАПРЕТ СМЕНЫ НА НАБЛЮДАТЕЛЯ ДЛЯ ИГРОКОВ В КОМАНДЕ
-- ============================================================================
hook.Add("PlayerShouldTakeDamage", "STALKER_Init", function() end)

-- Запрет перехода в наблюдатель если уже в команде
hook.Add("PlayerNoClip", "STALKER_NoNoclip", function(ply)
    return false -- Отключаем noclip полностью
end)
