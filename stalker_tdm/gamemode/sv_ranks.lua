-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Серверная система рангов (5 уровней)
-- ============================================================================

util.AddNetworkString("STALKER_PlaySoundToAll")
util.AddNetworkString("STALKER_PlaySoundToPlayer")

-- Воспроизвести звук конкретному игроку
function GM:PlaySoundToPlayer(ply, sound)
    if not IsValid(ply) then return end
    net.Start("STALKER_PlaySoundToPlayer")
        net.WriteString(sound)
    net.Send(ply)
end

-- Воспроизвести звук всем
function GM:PlaySoundToAll(sound)
    net.Start("STALKER_PlaySoundToAll")
        net.WriteString(sound)
    net.Broadcast()
end

-- Добавить опыт
function GM:AddXP(ply, amount)
    if not IsValid(ply) then return end

    local currentXP  = ply:GetNWInt("STALKER_XP", 0)
    local oldRank    = ply:GetNWInt("STALKER_Rank", 1)
    local newXP      = currentXP + amount
    ply:SetNWInt("STALKER_XP", newXP)

    local newRankLevel, newRankData = self:GetRankByXP(newXP)
    ply:SetNWInt("STALKER_Rank", newRankLevel)

    -- Повышение ранга
    if newRankLevel > oldRank then
        net.Start("STALKER_LevelUp")
            net.WriteUInt(newRankLevel, 8)
            net.WriteString(newRankData.name)
        net.Send(ply)

        -- Звук повышения ранга (зависит от фракции)
        local factionID = self:GetPlayerFactionID(ply)
        local rankSounds = STALKER_CONFIG.RankUpSounds[newRankLevel]
        if rankSounds and factionID and rankSounds[factionID] then
            self:PlaySoundToPlayer(ply, rankSounds[factionID])
        end

        PrintMessage(HUD_PRINTTALK,
            "[STALKER] " .. ply:Nick() .. " получил звание: " .. newRankData.name .. "!")
    end

    net.Start("STALKER_XPUpdate")
        net.WriteInt(newXP, 32)
        net.WriteInt(amount, 16)
    net.Send(ply)
end

-- Сброс ранга (после раунда)
function GM:ResetPlayerRank(ply)
    if not IsValid(ply) then return end
    ply:SetNWInt("STALKER_XP",       0)
    ply:SetNWInt("STALKER_Rank",     1)
    ply:SetNWInt("STALKER_Kills",    0)
    ply:SetNWInt("STALKER_Deaths",   0)
    ply:SetNWInt("STALKER_Killstreak", 0)
end

function GM:ResetAllRanks()
    for _, ply in ipairs(player.GetAll()) do
        self:ResetPlayerRank(ply)
    end
    print("[STALKER TDM] Ранги и опыт сброшены.")
end

-- Загрузка (начинаем с нуля — ранги не сохраняются между раундами)
function GM:LoadPlayerRank(ply)
    ply:SetNWInt("STALKER_XP",   0)
    ply:SetNWInt("STALKER_Rank", 1)
end

function GM:SavePlayerRank(ply)  end
function GM:SaveAllRanks()       end