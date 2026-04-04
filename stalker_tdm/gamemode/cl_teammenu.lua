-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Меню выбора команды
-- ============================================================================

-- Глобальная переменная для хранения фрейма
local TEAM_FRAME = nil

-- Описания фракций
local FACTION_DESC = {
    mercenaries = "Искатели приключений и головорезы со всего мира, не гнушающиеся никакой, даже самой грязной работы. Их девиз: «Деньги не пахнут». Здесь артефакты, а значит — пахнет большими деньгами. «Наёмники» экипированы в основном западным стрелковым вооружением.",
    freedom     = "Анархисты Зоны. Исповедуют идею, что Зона — это заповедник свободы. Считают, что все законы, правила и условности внешнего мира здесь теряют силу. Их девиз: «Делай что хочешь, но не мешай другим». «Свобода» экипирована в основном стрелковым оружием бывшего СССР и России.",
}

-- Иконки фракций (используем материалы из папки)
local matFreedom = nil
local matMerc    = nil

local function GetMaterial(path)
    if file.Exists("materials/" .. path, "GAME") then
        return Material(path, "noclamp smooth")
    end
    return nil
end

-- ============================================================================
-- ГЛАВНАЯ ФУНКЦИЯ — открытие меню
-- ============================================================================
function STALKER_OpenTeamMenu()
    -- Если уже открыто — закрываем
    if IsValid(TEAM_FRAME) then
        TEAM_FRAME:Remove()
        TEAM_FRAME = nil
        return
    end

    -- Загрузка материалов
    if not matFreedom then
        matFreedom = GetMaterial("ui_greenteam.png")
    end
    if not matMerc then
        matMerc = GetMaterial("ui_blueteam.png")
    end

    local scrW, scrH = ScrW(), ScrH()
    local fW, fH     = 760, 480

    -- Получаем данные о фракциях
    local matchupIdx = STALKER_CLIENT and STALKER_CLIENT.CurrentMatchup or 1
    local matchup    = STALKER_CONFIG.FactionMatchups[matchupIdx]
    if not matchup then
        matchup = STALKER_CONFIG.FactionMatchups[1]
    end

    -- ====================================================
    -- Создание основного фрейма
    -- ====================================================
    TEAM_FRAME = vgui.Create("DFrame")
    TEAM_FRAME:SetSize(fW, fH)
    TEAM_FRAME:SetPos(scrW / 2 - fW / 2, scrH / 2 - fH / 2)
    TEAM_FRAME:SetTitle("")
    TEAM_FRAME:SetDraggable(false)
    TEAM_FRAME:ShowCloseButton(false)
    TEAM_FRAME:MakePopup()

    local frameStart = CurTime()

    TEAM_FRAME.Paint = function(self, w, h)
        -- Blur фон
        Derma_DrawBackgroundBlur(self, frameStart)

        -- Основной фон
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 13, 8, 250))

        -- Внешняя рамка (золотая)
        surface.SetDrawColor(140, 120, 50, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        -- Внутренняя рамка (тёмная)
        surface.SetDrawColor(50, 65, 35, 120)
        surface.DrawOutlinedRect(3, 3, w - 6, h - 6, 1)

        -- Заголовок фон
        surface.SetDrawColor(20, 25, 12, 220)
        surface.DrawRect(0, 0, w, 40)

        -- Линия под заголовком
        surface.SetDrawColor(140, 120, 50, 180)
        surface.DrawRect(0, 40, w, 1)

        -- Текст заголовка
        draw.SimpleText("Выбор команды", "STALKER_HUD_Large",
            w / 2, 12, Color(210, 195, 140, 240), TEXT_ALIGN_CENTER)
    end

    -- Кнопка закрытия (X)
    local closeBtn = vgui.Create("DButton", TEAM_FRAME)
    closeBtn:SetPos(fW - 30, 8)
    closeBtn:SetSize(22, 22)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        surface.SetDrawColor(self:IsHovered() and 180 or 100, 30, 30,
            self:IsHovered() and 220 or 160)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText("X", "STALKER_HUD_Small",
            w / 2, h / 2, Color(220, 200, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        TEAM_FRAME:Remove()
        TEAM_FRAME = nil
    end

    -- ====================================================
    -- Панели фракций
    -- ====================================================
    local btnW    = (fW - 40) / 2 - 5
    local btnH    = 300
    local btnTopY = 50

    -- Текущая выбранная команда игрока
    local myTeam  = LocalPlayer():Team()

    -- Общая функция создания панели фракции
    local function MakeFactionPanel(teamID, teamData, posX)
        local isMyTeam = (myTeam == teamID)

        local btn = vgui.Create("DButton", TEAM_FRAME)
        btn:SetPos(posX, btnTopY)
        btn:SetSize(btnW, btnH)
        btn:SetText("")

        local hovered  = false
        local clr      = teamData.color
        local mat      = (teamData.id == "freedom") and matFreedom or matMerc

        btn.OnCursorEntered = function() hovered = true  end
        btn.OnCursorExited  = function() hovered = false end

        btn.Paint = function(self, w, h)
            -- Фон
            local bgA = hovered and 160 or 100
            if isMyTeam then bgA = 140 end

            surface.SetDrawColor(
                clr.r * 0.1, clr.g * 0.1, clr.b * 0.1, bgA)
            surface.DrawRect(0, 0, w, h)

            -- Рамка
            if isMyTeam then
                surface.SetDrawColor(clr.r, clr.g, clr.b, 220)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
            elseif hovered then
                surface.SetDrawColor(clr.r, clr.g, clr.b, 180)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            else
                surface.SetDrawColor(60, 80, 40, 120)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            -- Иконка фракции
            if mat then
                surface.SetDrawColor(255, 255, 255, hovered and 240 or 200)
                surface.SetMaterial(mat)
                local iconSize = 130
                surface.DrawTexturedRect(
                    w / 2 - iconSize / 2,
                    25,
                    iconSize, iconSize
                )
            else
                -- Заглушка если нет текстуры
                surface.SetDrawColor(clr.r, clr.g, clr.b, 60)
                surface.DrawRect(w/2 - 55, 20, 110, 110)
                draw.SimpleText("?", "STALKER_HUD_Large",
                    w/2, 75, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Название команды
            draw.SimpleText(teamData.name, "STALKER_HUD_Medium",
                w / 2, 170, clr, TEXT_ALIGN_CENTER)

            -- Кол-во игроков
            local cnt = team.NumPlayers(teamID)
            draw.SimpleText(cnt .. " игроков", "STALKER_HUD_Small",
                w / 2, 198, Color(160, 170, 140), TEXT_ALIGN_CENTER)

            -- Пометка "ВЫ ЗДЕСЬ" если уже в команде
            if isMyTeam then
                draw.SimpleText("[ ВЫ ЗДЕСЬ ]", "STALKER_HUD_Tiny",
                    w / 2, 222, clr, TEXT_ALIGN_CENTER)
            end

            -- Описание
            local desc = FACTION_DESC[teamData.id] or ""
            surface.SetFont("STALKER_HUD_Tiny")
            local lines    = {}
            local words    = string.Explode(" ", desc)
            local curLine  = ""
            local maxLineW = w - 20

            for _, word in ipairs(words) do
                local testLine = curLine == "" and word or (curLine .. " " .. word)
                local tw, _    = surface.GetTextSize(testLine)
                if tw > maxLineW then
                    table.insert(lines, curLine)
                    curLine = word
                else
                    curLine = testLine
                end
            end
            if curLine ~= "" then table.insert(lines, curLine) end

            local descStartY = 248
            for li, line in ipairs(lines) do
                if descStartY + li * 16 < h - 10 then
                    draw.SimpleText(line, "STALKER_HUD_Tiny",
                        w / 2, descStartY + (li - 1) * 16,
                        Color(155, 163, 130, 200), TEXT_ALIGN_CENTER)
                end
            end
        end

        btn.DoClick = function()
            -- Отправляем выбор команды
            net.Start("STALKER_TeamSelect")
                net.WriteUInt(teamID, 4)
            net.SendToServer()

            surface.PlaySound("buttons/button15.wav")

            -- Закрываем меню
            if IsValid(TEAM_FRAME) then
                TEAM_FRAME:Remove()
                TEAM_FRAME = nil
            end
        end

        return btn
    end

    MakeFactionPanel(TEAM_FACTION2, matchup.team2, 15)            -- Свобода (слева)
    MakeFactionPanel(TEAM_FACTION1, matchup.team1, 20 + btnW)     -- Наёмники (справа)

    -- ====================================================
    -- Нижние кнопки
    -- ====================================================
    local bottomY = btnTopY + btnH + 15

    -- Функция создания нижних кнопок
    local function MakeBottomBtn(label, px, bw, onClick)
        local b = vgui.Create("DButton", TEAM_FRAME)
        b:SetPos(px, bottomY)
        b:SetSize(bw, 32)
        b:SetText("")
        b.Paint = function(self, w, h)
            surface.SetDrawColor(
                self:IsHovered() and 60 or 25,
                self:IsHovered() and 80 or 33,
                self:IsHovered() and 40 or 18,
                self:IsHovered() and 230 or 200
            )
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(100, 130, 60, 150)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(label, "STALKER_HUD_Small",
                w / 2, h / 2, Color(200, 210, 165),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = onClick
        return b
    end

    local bw     = 150
    local totalW = bw * 3 + 20
    local bStartX = fW / 2 - totalW / 2

    -- Назад
    MakeBottomBtn("Назад", bStartX, bw, function()
        if IsValid(TEAM_FRAME) then
            TEAM_FRAME:Remove()
            TEAM_FRAME = nil
        end
    end)

    -- Автовыбор
    MakeBottomBtn("Автовыбор", bStartX + bw + 10, bw, function()
        local t1 = team.NumPlayers(TEAM_FACTION1)
        local t2 = team.NumPlayers(TEAM_FACTION2)
        local pick = (t1 <= t2) and TEAM_FACTION1 or TEAM_FACTION2

        net.Start("STALKER_TeamSelect")
            net.WriteUInt(pick, 4)
        net.SendToServer()

        surface.PlaySound("buttons/button15.wav")

        if IsValid(TEAM_FRAME) then
            TEAM_FRAME:Remove()
            TEAM_FRAME = nil
        end
    end)

    -- Наблюдатель
    MakeBottomBtn("Наблюдатель", bStartX + (bw + 10) * 2, bw, function()
        if IsValid(TEAM_FRAME) then
            TEAM_FRAME:Remove()
            TEAM_FRAME = nil
        end
    end)

    -- ====================================================
    -- Разделитель VS
    -- ====================================================
    local vsLabel = vgui.Create("DLabel", TEAM_FRAME)
    vsLabel:SetText("VS")
    vsLabel:SetFont("STALKER_HUD_Large")
    vsLabel:SetTextColor(Color(200, 70, 70, 220))
    vsLabel:SizeToContents()
    vsLabel:SetPos(fW / 2 - vsLabel:GetWide() / 2, btnTopY + btnH / 2 - vsLabel:GetTall() / 2)
end

-- ============================================================================
-- Проверяем что функция создана корректно
-- ============================================================================
if not STALKER_OpenTeamMenu then
    print("[STALKER TDM] КРИТИЧЕСКАЯ ОШИБКА: STALKER_OpenTeamMenu не создана!")
end