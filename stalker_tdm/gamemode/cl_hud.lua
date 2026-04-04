-- ============================================================================
-- S.T.A.L.K.E.R. TDM — HUD
-- HP, броня и патроны убраны (есть свой HUD)
-- Добавлены: деньги, ранг/XP, счёт, таймер, kill feed, уведомления
-- ============================================================================

-- ============================================================================
-- ШРИФТЫ
-- ============================================================================
surface.CreateFont("STALKER_HUD_Large", {
    font      = "Arial",
    size      = 28,
    weight    = 700,
    antialias = true,
})
surface.CreateFont("STALKER_HUD_Medium", {
    font      = "Arial",
    size      = 20,
    weight    = 600,
    antialias = true,
})
surface.CreateFont("STALKER_HUD_Small", {
    font      = "Arial",
    size      = 16,
    weight    = 500,
    antialias = true,
})
surface.CreateFont("STALKER_HUD_Tiny", {
    font      = "Arial",
    size      = 14,
    weight    = 400,
    antialias = true,
})
surface.CreateFont("STALKER_KillFeed", {
    font      = "Arial",
    size      = 15,
    weight    = 600,
    antialias = true,
})
surface.CreateFont("STALKER_Notify", {
    font      = "Arial",
    size      = 18,
    weight    = 700,
    antialias = true,
})
surface.CreateFont("STALKER_LevelUp", {
    font      = "Arial",
    size      = 36,
    weight    = 800,
    antialias = true,
})
surface.CreateFont("STALKER_Money_Big", {
    font      = "Arial",
    size      = 22,
    weight    = 800,
    antialias = true,
})
surface.CreateFont("STALKER_Rank_Font", {
    font      = "Arial",
    size      = 13,
    weight    = 600,
    antialias = true,
})

-- ============================================================================
-- ЦВЕТА
-- ============================================================================
local CLR = {
    bg          = Color(0,   0,   0,   170),
    bgDark      = Color(5,   8,   3,   210),
    border      = Color(80,  100, 60,  200),
    borderLight = Color(120, 140, 80,  130),
    borderGold  = Color(180, 155, 60,  200),
    text        = Color(200, 210, 180, 255),
    textBright  = Color(240, 245, 220, 255),
    textDim     = Color(140, 150, 120, 180),
    money       = Color(230, 200, 60,  255),  -- Золотой (как в оригинале)
    moneyGain   = Color(100, 220, 100, 255),
    moneyLoss   = Color(220, 80,  80,  255),
    xpBar       = Color(80,  160, 80,  220),
    xpBarBg     = Color(20,  40,  20,  180),
    rankIcon    = Color(200, 180, 80,  255),  -- Золотые погоны
    team1       = Color(80,  120, 255, 255),  -- Наёмники (синий)
    team2       = Color(50,  200, 50,  255),  -- Свобода (зелёный)
}

-- ============================================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================================

local function DrawPanel(x, y, w, h, alpha)
    alpha = alpha or (STALKER_CLIENT and STALKER_CLIENT.Visuals.HUDAlpha or 220)
    surface.SetDrawColor(5, 8, 3, alpha * 0.85)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(CLR.border.r, CLR.border.g, CLR.border.b, alpha * 0.9)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(CLR.borderLight.r, CLR.borderLight.g, CLR.borderLight.b, alpha * 0.25)
    surface.DrawOutlinedRect(x+1, y+1, w-2, h-2, 1)
end

local function DrawGoldPanel(x, y, w, h, alpha)
    alpha = alpha or 220
    surface.SetDrawColor(15, 12, 3, alpha * 0.9)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(CLR.borderGold.r, CLR.borderGold.g, CLR.borderGold.b, alpha)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    surface.SetDrawColor(CLR.borderGold.r, CLR.borderGold.g, CLR.borderGold.b, alpha * 0.3)
    surface.DrawOutlinedRect(x+1, y+1, w-2, h-2, 1)
end

local function DrawBar(x, y, w, h, frac, fgClr, bgClr)
    frac = math.Clamp(frac, 0, 1)
    surface.SetDrawColor(bgClr)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(fgClr)
    surface.DrawRect(x, y, w * frac, h)
end

-- Рисуем "звёздочки" ранга (как шевроны в STALKER)
local function DrawRankStars(x, y, rankLevel, maxRank)
    local starSize = 10
    local starGap  = 3
    local totalW   = maxRank * (starSize + starGap) - starGap
    local startX   = x - totalW / 2

    for i = 1, maxRank do
        local sx = startX + (i-1) * (starSize + starGap)
        if i <= rankLevel then
            -- Заполненная звезда (золотая)
            surface.SetDrawColor(200, 175, 50, 240)
            surface.DrawRect(sx, y, starSize, starSize)
            surface.SetDrawColor(230, 210, 80, 180)
            surface.DrawOutlinedRect(sx, y, starSize, starSize, 1)
        else
            -- Пустая
            surface.SetDrawColor(40, 50, 30, 150)
            surface.DrawRect(sx, y, starSize, starSize)
            surface.SetDrawColor(70, 85, 50, 120)
            surface.DrawOutlinedRect(sx, y, starSize, starSize, 1)
        end
    end
end

-- ============================================================================
-- ОСНОВНОЙ HUD HOOK
-- ============================================================================
hook.Add("HUDPaint", "STALKER_HUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local scrW, scrH = ScrW(), ScrH()
    local alive      = ply:Alive()

    -- ========================================================
    -- БЛОК ДЕНЕГ И РАНГА (правый верхний угол, стиль STALKER)
    -- ========================================================
    if alive then
        local money     = ply:GetNWInt("STALKER_Money", 0)
        local xp        = ply:GetNWInt("STALKER_XP", 0)
        local rankLevel = ply:GetNWInt("STALKER_Rank", 1)
        local rankData  = STALKER_CONFIG.Ranks[rankLevel]
        local rankName  = rankData and rankData.name or "Новичок"
        local maxRank   = #STALKER_CONFIG.Ranks

        -- Размеры панелей (правый верхний угол)
        local panelW  = 180
        local panelH  = 70
        local marginR = 10
        local marginT = 10
        local px      = scrW - panelW - marginR
        local py      = marginT

        -- === ПАНЕЛЬ ДЕНЕГ ===
        DrawGoldPanel(px, py, panelW, panelH)

        -- Иконка "деньги" (текст ДЕНЬГИ)
        draw.SimpleText("ДЕНЬГИ", "STALKER_Rank_Font",
            px + panelW/2, py + 7,
            Color(160, 140, 50, 200), TEXT_ALIGN_CENTER)

        -- Сумма (крупно, золотом)
        draw.SimpleText(
            string.format("%d RU", money),
            "STALKER_Money_Big",
            px + panelW/2, py + 25,
            CLR.money, TEXT_ALIGN_CENTER
        )

        -- Звёздочки ранга под деньгами
        DrawRankStars(px + panelW/2, py + 52, rankLevel, maxRank)

        -- === ПАНЕЛЬ РАНГА (под деньгами) ===
        local rankPanelH = 45
        local ry         = py + panelH + 5

        DrawPanel(px, ry, panelW, rankPanelH)

        -- Название ранга
        draw.SimpleText(rankName, "STALKER_HUD_Small",
            px + panelW/2, ry + 6,
            CLR.rankIcon, TEXT_ALIGN_CENTER)

        -- XP бар
        local nextRank   = STALKER_CONFIG.Ranks[rankLevel + 1]
        local xpFraction = 1
        local xpText     = "МАКС"
        if nextRank then
            local base   = rankData and rankData.xp or 0
            local needed = nextRank.xp - base
            local cur    = xp - base
            xpFraction = needed > 0 and math.Clamp(cur / needed, 0, 1) or 1
            xpText = string.format("%d / %d XP", xp, nextRank.xp)
        end

        local barX = px + 8
        local barY = ry + 26
        local barW = panelW - 16
        local barH = 10

        DrawBar(barX, barY, barW, barH, xpFraction,
            CLR.xpBar, CLR.xpBarBg)

        -- Рамка бара
        surface.SetDrawColor(CLR.border.r, CLR.border.g, CLR.border.b, 120)
        surface.DrawOutlinedRect(barX, barY, barW, barH, 1)

        -- XP текст
        draw.SimpleText(xpText, "STALKER_Rank_Font",
            px + panelW/2, barY + 12,
            CLR.textDim, TEXT_ALIGN_CENTER)
    end

    -- ========================================================
    -- СЧЁТ КОМАНД И ТАЙМЕР (верхний центр)
    -- ========================================================
    do
        local matchup = STALKER_CONFIG and STALKER_CONFIG.FactionMatchups and
                        STALKER_CONFIG.FactionMatchups[STALKER_CLIENT.CurrentMatchup]
        if not matchup then matchup = STALKER_CONFIG.FactionMatchups[1] end

        local cx       = scrW / 2
        local topY     = 8
        local scoreW   = 320
        local scoreH   = 48

        DrawPanel(cx - scoreW/2, topY, scoreW, scoreH)

        local s1 = STALKER_CLIENT.TeamScores[TEAM_FACTION1] or 0
        local s2 = STALKER_CLIENT.TeamScores[TEAM_FACTION2] or 0

        -- Свобода (слева, зелёный)
        draw.SimpleText(matchup.team2.name, "STALKER_HUD_Tiny",
            cx - scoreW/2 + 12, topY + 6,
            CLR.team2)
        draw.SimpleText(tostring(s2), "STALKER_HUD_Large",
            cx - 30, topY + 10,
            CLR.team2, TEXT_ALIGN_CENTER)

        -- Разделитель
        draw.SimpleText("--", "STALKER_HUD_Large",
            cx, topY + 10, CLR.text, TEXT_ALIGN_CENTER)

        -- Наёмники (справа, синий)
        draw.SimpleText(tostring(s1), "STALKER_HUD_Large",
            cx + 30, topY + 10,
            CLR.team1, TEXT_ALIGN_CENTER)
        draw.SimpleText(matchup.team1.name, "STALKER_HUD_Tiny",
            cx + scoreW/2 - 12, topY + 6,
            CLR.team1, TEXT_ALIGN_RIGHT)

        -- Таймер (под счётом, красный если мало)
        local timeLeft = math.max(0, STALKER_CLIENT.RoundEndTime - CurTime())
        local minutes  = math.floor(timeLeft / 60)
        local seconds  = math.floor(timeLeft % 60)
        local timeStr  = string.format("%02d:%02d", minutes, seconds)
        local timeClr  = (timeLeft < 60) and Color(220, 60, 60) or Color(200, 180, 100)

        draw.SimpleText(timeStr, "STALKER_HUD_Small",
            cx, topY + scoreH + 3,
            timeClr, TEXT_ALIGN_CENTER)

        -- Состояние раунда
        local stateText = ""
        if STALKER_CLIENT.RoundState == ROUND_WAITING then
            stateText = "Ожидание игроков..."
        elseif STALKER_CLIENT.RoundState == ROUND_VOTING then
            stateText = "Голосование за фракции"
        elseif STALKER_CLIENT.RoundState == ROUND_WARMUP then
            stateText = "Разминка"
        elseif STALKER_CLIENT.RoundState == ROUND_ENDING then
            stateText = "Раунд завершён"
        elseif STALKER_CLIENT.RoundState == ROUND_MAP_VOTE then
            stateText = "Голосование за карту"
        end

        if stateText ~= "" then
            local pulse = 200 + math.sin(CurTime() * 3) * 55
            draw.SimpleText(stateText, "STALKER_HUD_Tiny",
                cx, topY + scoreH + 20,
                Color(255, 200, 100, pulse), TEXT_ALIGN_CENTER)
        end
    end

    -- ========================================================
    -- KILL FEED (правая сторона, под деньгами)
    -- ========================================================
    DrawKillFeed(scrW, 175)

    -- ========================================================
    -- УВЕДОМЛЕНИЯ О ДЕНЬГАХ (центр экрана)
    -- ========================================================
    DrawMoneyNotifications(scrW / 2, scrH / 2 + 80)

    -- ========================================================
    -- УВЕДОМЛЕНИЕ О ПОВЫШЕНИИ РАНГА
    -- ========================================================
    DrawLevelUpNotification(scrW / 2, scrH / 3)

    -- ========================================================
    -- ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
    -- ========================================================
    DrawVisualEffects(scrW, scrH)
end)

-- ============================================================================
-- KILL FEED
-- ============================================================================
function DrawKillFeed(scrW, startY)
    local curTime = CurTime()
    local y       = startY
    local i       = 1

    while i <= #STALKER_CLIENT.KillFeed do
        local entry = STALKER_CLIENT.KillFeed[i]
        local age   = curTime - entry.time

        if age > STALKER_CLIENT.KillFeedDuration then
            table.remove(STALKER_CLIENT.KillFeed, i)
        else
            local alpha = 255
            if age > STALKER_CLIENT.KillFeedDuration - 1 then
                alpha = math.Clamp(255 * (STALKER_CLIENT.KillFeedDuration - age), 0, 255)
            end

            local clrA = ColorAlpha(
                entry.attackerTeam == TEAM_FACTION1 and CLR.team1 or CLR.team2, alpha)
            local clrV = ColorAlpha(
                entry.victimTeam == TEAM_FACTION1 and CLR.team1 or CLR.team2, alpha)

            local wepText = string.gsub(entry.weapon, "tfa_st_", "")
                                  :gsub("tfa_", ""):gsub("weapon_", "")
            if entry.headshot then wepText = wepText .. " [HS]"    end
            if entry.knife    then wepText = wepText .. " [НОЖ]"  end

            local panelX = scrW - 360
            local panelH = 22

            DrawPanel(panelX, y, 345, panelH)

            -- Атакующий
            surface.SetFont("STALKER_KillFeed")
            local aw = surface.GetTextSize(entry.attacker)
            draw.SimpleText(entry.attacker, "STALKER_KillFeed",
                panelX + 5, y + 3, clrA)

            -- Оружие
            local midStr = "  [" .. wepText .. "]  "
            local mw     = surface.GetTextSize(midStr)
            draw.SimpleText(midStr, "STALKER_KillFeed",
                panelX + 5 + aw, y + 3,
                ColorAlpha(CLR.textDim, alpha))

            -- Жертва
            draw.SimpleText(entry.victim, "STALKER_KillFeed",
                panelX + 5 + aw + mw, y + 3, clrV)

            y = y + panelH + 3
            i = i + 1
        end
    end
end

-- ============================================================================
-- УВЕДОМЛЕНИЯ О ДЕНЬГАХ
-- ============================================================================
function DrawMoneyNotifications(x, startY)
    local curTime = CurTime()
    local y       = startY

    for i = #STALKER_CLIENT.MoneyNotifications, 1, -1 do
        local notif = STALKER_CLIENT.MoneyNotifications[i]
        local age   = curTime - notif.time

        if age > STALKER_CLIENT.MoneyNotifDuration then
            table.remove(STALKER_CLIENT.MoneyNotifications, i)
        else
            local alpha = 255
            if age > STALKER_CLIENT.MoneyNotifDuration - 1 then
                alpha = math.Clamp(255 * (STALKER_CLIENT.MoneyNotifDuration - age), 0, 255)
            end

            local color, text
            if notif.isShop then
                color = notif.success and CLR.moneyGain or CLR.moneyLoss
                text  = notif.reason
            elseif notif.amount > 0 then
                color = CLR.moneyGain
                text  = string.format("+%d RU  %s", notif.amount, notif.reason)
            elseif notif.amount < 0 then
                color = CLR.moneyLoss
                text  = string.format("%d RU  %s",  notif.amount, notif.reason)
            else
                color = CLR.text
                text  = notif.reason
            end

            local offsetY = -age * 18
            draw.SimpleText(text, "STALKER_Notify",
                x, y + offsetY,
                ColorAlpha(color, alpha),
                TEXT_ALIGN_CENTER)

            y = y - 26
        end
    end
end

-- ============================================================================
-- УВЕДОМЛЕНИЕ О ПОВЫШЕНИИ РАНГА
-- ============================================================================
function DrawLevelUpNotification(x, y)
    if not STALKER_CLIENT.LevelUpNotif then return end

    local age = CurTime() - STALKER_CLIENT.LevelUpTime
    if age > 5 then
        STALKER_CLIENT.LevelUpNotif = nil
        return
    end

    local alpha = 255
    if age > 4 then
        alpha = math.Clamp(255 * (5 - age), 0, 255)
    end

    local bounce = math.abs(math.sin(age * 6)) * 6

    draw.SimpleText("ПОВЫШЕНИЕ ЗВАНИЯ!", "STALKER_LevelUp",
        x, y - bounce,
        ColorAlpha(Color(255, 215, 60), alpha),
        TEXT_ALIGN_CENTER)

    draw.SimpleText("► " .. STALKER_CLIENT.LevelUpNotif.name .. " ◄",
        "STALKER_HUD_Large",
        x, y + 42,
        ColorAlpha(CLR.textBright, alpha),
        TEXT_ALIGN_CENTER)
end

-- ============================================================================
-- ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
-- ============================================================================
function DrawVisualEffects(scrW, scrH)
    local v = STALKER_CLIENT and STALKER_CLIENT.Visuals
    if not v then return end

    -- Цветовой фильтр
    if v.ColorModEnabled then
        DrawColorModify({
            ["$pp_colour_addr"]       = (v.ColorModAdd.r or 3)   / 255,
            ["$pp_colour_addg"]       = (v.ColorModAdd.g or 8)   / 255,
            ["$pp_colour_addb"]       = (v.ColorModAdd.b or 0)   / 255,
            ["$pp_colour_brightness"] = -0.02,
            ["$pp_colour_contrast"]   = 1.04,
            ["$pp_colour_colour"]     = 0.92,
            ["$pp_colour_mulr"]       = (v.ColorModMul.r or 238) / 255,
            ["$pp_colour_mulg"]       = (v.ColorModMul.g or 232) / 255,
            ["$pp_colour_mulb"]       = (v.ColorModMul.b or 198) / 255,
        })
    end

    -- Зерно
    if v.NoiseEnabled then
        local noiseAlpha = v.NoiseAlpha or 12
        for i = 1, 40 do
            surface.SetDrawColor(255, 255, 255, math.random(0, noiseAlpha))
            surface.DrawRect(
                math.random(0, scrW),
                math.random(0, scrH),
                math.random(1, 3),
                math.random(1, 3)
            )
        end
    end
end