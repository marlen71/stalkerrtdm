-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Экран смерти (ИСПРАВЛЕНО)
-- ============================================================================

hook.Add("HUDPaint", "STALKER_DeathScreen", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if ply:Alive() then return end
    -- Только для игроков в командах
    if ply:Team() ~= TEAM_FACTION1 and ply:Team() ~= TEAM_FACTION2 then return end

    local scrW, scrH = ScrW(), ScrH()

    -- Затемнение
    surface.SetDrawColor(0, 0, 0, 180)
    surface.DrawRect(0, 0, scrW, scrH)

    -- Красная виньетка
    local va = 80 + math.sin(CurTime() * 2) * 30
    for i = 0, 3 do
        local a = va - i * 15
        surface.SetDrawColor(100, 0, 0, math.max(0, a))
        surface.DrawOutlinedRect(i * 20, i * 20,
            scrW - i * 40, scrH - i * 40, 20)
    end

    -- Текст
    draw.SimpleText("ВЫ ПОГИБЛИ", "STALKER_LevelUp",
        scrW / 2, scrH / 2 - 50,
        Color(200, 50, 50, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Таймер
    local timeLeft = 0
    if ply.NextSpawnTime then
        timeLeft = math.max(0, ply.NextSpawnTime - CurTime())
    end

    if timeLeft > 0 then
        draw.SimpleText(
            string.format("Респавн через: %.1f сек", timeLeft),
            "STALKER_HUD_Medium",
            scrW / 2, scrH / 2 + 10,
            Color(200, 200, 180), TEXT_ALIGN_CENTER)
    else
        if STALKER_CLIENT.RoundState == ROUND_ACTIVE
           or STALKER_CLIENT.RoundState == ROUND_WARMUP then
            draw.SimpleText("Респавн...", "STALKER_HUD_Medium",
                scrW / 2, scrH / 2 + 10,
                Color(200, 200, 180,
                    150 + math.sin(CurTime() * 4) * 100),
                TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Ожидание раунда...", "STALKER_HUD_Medium",
                scrW / 2, scrH / 2 + 10,
                Color(200, 180, 100), TEXT_ALIGN_CENTER)
        end
    end

    -- Статистика
    local k = ply:GetNWInt("STALKER_Kills", 0)
    local d = ply:GetNWInt("STALKER_Deaths", 0)
    local m = ply:GetNWInt("STALKER_Money", 0)

    draw.SimpleText(
        string.format("Убийства: %d | Смерти: %d | Деньги: %d RU", k, d, m),
        "STALKER_HUD_Small",
        scrW / 2, scrH / 2 + 60,
        Color(150, 160, 130), TEXT_ALIGN_CENTER)
end)

-- Синхронизация таймера смерти
hook.Add("Think", "STALKER_DeathThinkSync", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply:Alive() and not ply.NextSpawnTime then
        ply.NextSpawnTime = CurTime() + STALKER_CONFIG.RespawnDelay
    elseif ply:Alive() then
        ply.NextSpawnTime = nil
    end
end)