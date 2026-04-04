-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Меню выбора внешности (с PNG превью)
-- ============================================================================

local MODEL_FRAME = nil

-- ============================================================================
-- Таблица превью: mdl -> путь к PNG (относительно materials/)
-- ============================================================================
local MODEL_PREVIEWS = {
    -- Наёмники
    ["models/flaymi/anomaly/stalker_merc_mp/stalker_ki_mask.mdl"]
        = "stalker_tdm/icons/merc_mp2.png",
    ["models/flaymi/anomaly/stalker_merc_mp/stalker_merc_2.mdl"]
        = "stalker_tdm/icons/merc_mp1.png",

    -- Свобода
    ["models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_old.mdl"]
        = "stalker_tdm/icons/free_mp1.png",
    ["models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_mas4.mdl"]
        = "stalker_tdm/icons/free_mp2.png",
}

-- Кэш загруженных материалов
local matCache = {}

local function GetPreviewMat(mdlPath)
    if matCache[mdlPath] then return matCache[mdlPath] end

    local pngPath = MODEL_PREVIEWS[mdlPath]
    if pngPath and file.Exists("materials/" .. pngPath, "GAME") then
        matCache[mdlPath] = Material(pngPath, "noclamp smooth")
        return matCache[mdlPath]
    end

    return nil
end

-- ============================================================================
-- Приём сетевого сигнала от сервера
-- ============================================================================
net.Receive("STALKER_OpenModelMenu", function()
    local teamName  = net.ReadString()
    local factionID = net.ReadString()
    local count     = net.ReadUInt(4)
    local models    = {}
    for i = 1, count do
        table.insert(models, net.ReadString())
    end
    STALKER_OpenModelMenu(teamName, factionID, models)
end)

-- ============================================================================
-- ГЛАВНАЯ ФУНКЦИЯ
-- ============================================================================
function STALKER_OpenModelMenu(teamName, factionID, models)
    if IsValid(MODEL_FRAME) then
        MODEL_FRAME:Remove()
        MODEL_FRAME = nil
    end

    if not models or #models == 0 then return end

    local scrW, scrH = ScrW(), ScrH()

    -- Такой же размер как меню выбора команды
    local fW = 760
    local fH = 480

    -- ====================================================
    -- Основной фрейм
    -- ====================================================
    MODEL_FRAME = vgui.Create("DFrame")
    MODEL_FRAME:SetSize(fW, fH)
    MODEL_FRAME:SetPos(scrW / 2 - fW / 2, scrH / 2 - fH / 2)
    MODEL_FRAME:SetTitle("")
    MODEL_FRAME:SetDraggable(false)
    MODEL_FRAME:ShowCloseButton(false)
    MODEL_FRAME:MakePopup()

    local frameStart    = CurTime()
    local selectedIndex = 0   -- 0 = не выбран

    MODEL_FRAME.Paint = function(self, w, h)
        Derma_DrawBackgroundBlur(self, frameStart)

        -- Основной тёмный фон
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 13, 8, 250))

        -- Внешняя золотая рамка
        surface.SetDrawColor(140, 120, 50, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        -- Внутренняя тёмная рамка
        surface.SetDrawColor(50, 65, 35, 120)
        surface.DrawOutlinedRect(3, 3, w - 6, h - 6, 1)

        -- Заголовок фон
        surface.SetDrawColor(20, 25, 12, 220)
        surface.DrawRect(0, 0, w, 40)

        -- Линия под заголовком
        surface.SetDrawColor(140, 120, 50, 180)
        surface.DrawRect(0, 40, w, 1)

        -- Заголовок
        draw.SimpleText("Выбор формы", "STALKER_HUD_Large",
            w / 2, 12, Color(210, 195, 140, 240), TEXT_ALIGN_CENTER)

        -- Подзаголовок (название фракции)
        draw.SimpleText(teamName, "STALKER_HUD_Small",
            w / 2, 36, Color(160, 170, 130, 180), TEXT_ALIGN_CENTER)
    end

    -- ====================================================
    -- Область карточек персонажей
    -- ====================================================
    local cardAreaY  = 48
    local cardAreaH  = fH - 48 - 60  -- 60 под нижние кнопки
    local cardAreaW  = fW - 80        -- отступы по бокам (стрелки)

    -- Максимум 4 карточки в ряд
    local maxVisible = 4
    local cardCount  = #models
    local cols       = math.min(cardCount, maxVisible)

    local cardW      = math.floor(cardAreaW / cols) - 10
    local cardH      = cardAreaH - 10
    local cardStartX = 40 + math.floor((cardAreaW - (cols * (cardW + 10) - 10)) / 2)
    local cardStartY = cardAreaY + 5

    -- Кнопки-стрелки (если моделей > 4)
    local scrollOffset = 0
    local arrowLeft, arrowRight

    if cardCount > maxVisible then
        -- Стрелка влево
        arrowLeft = vgui.Create("DButton", MODEL_FRAME)
        arrowLeft:SetPos(5, cardAreaY + cardAreaH / 2 - 20)
        arrowLeft:SetSize(30, 40)
        arrowLeft:SetText("")
        arrowLeft.Paint = function(self, w, h)
            surface.SetDrawColor(self:IsHovered() and 80 or 40, 90, 50, 200)
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText("<<", "STALKER_HUD_Small",
                w/2, h/2, Color(200,210,160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        arrowLeft.DoClick = function()
            scrollOffset = math.max(0, scrollOffset - 1)
        end

        -- Стрелка вправо
        arrowRight = vgui.Create("DButton", MODEL_FRAME)
        arrowRight:SetPos(fW - 35, cardAreaY + cardAreaH / 2 - 20)
        arrowRight:SetSize(30, 40)
        arrowRight:SetText("")
        arrowRight.Paint = function(self, w, h)
            surface.SetDrawColor(self:IsHovered() and 80 or 40, 90, 50, 200)
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(">>", "STALKER_HUD_Small",
                w/2, h/2, Color(200,210,160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        arrowRight.DoClick = function()
            scrollOffset = math.min(cardCount - maxVisible, scrollOffset + 1)
        end
    end

    -- ====================================================
    -- Карточки моделей
    -- ====================================================
    local cards = {}

    for i = 1, cardCount do
        local mdl    = models[i]
        local previewMat = GetPreviewMat(mdl)
        local col    = (i - 1) % maxVisible
        local cx     = cardStartX + col * (cardW + 10)
        local cy     = cardStartY

        local card = vgui.Create("DButton", MODEL_FRAME)
        card:SetPos(cx, cy)
        card:SetSize(cardW, cardH)
        card:SetText("")
        card:SetVisible(true)

        card.modelIndex  = i
        card.mdlPath     = mdl
        card.previewMat  = previewMat
        card.isSelected  = false
        card.isHovered   = false

        card.OnCursorEntered = function() card.isHovered = true  end
        card.OnCursorExited  = function() card.isHovered = false end

        card.Paint = function(self, w, h)
            -- Видимость по scrollOffset
            local visibleIdx = self.modelIndex - scrollOffset
            if visibleIdx < 1 or visibleIdx > maxVisible then
                return
            end

            -- Обновляем позицию
            local newX = cardStartX + (visibleIdx - 1) * (cardW + 10)
            self:SetPos(newX, cardStartY)
            self:SetVisible(true)

            -- Фон карточки (тёмный с сеткой)
            surface.SetDrawColor(18, 22, 14, 240)
            surface.DrawRect(0, 0, w, h)

            -- Текстура сетки (если есть)
            local gridMat = matCache["__grid"]
            if not gridMat and file.Exists("ui_grid.png", "GAME") then
                gridMat = Material("stalker_tdm/ui_grid.png", "noclamp smooth")
                matCache["__grid"] = gridMat
            end
            if gridMat then
                surface.SetDrawColor(255, 255, 255, 30)
                surface.SetMaterial(gridMat)
                surface.DrawTexturedRect(0, 0, w, h)
            end

            -- Рамка карточки
            if self.isSelected then
                -- Выбранная — яркая рамка
                surface.SetDrawColor(180, 200, 100, 240)
                surface.DrawOutlinedRect(0, 0, w, h, 3)
                surface.SetDrawColor(140, 170, 70, 150)
                surface.DrawOutlinedRect(3, 3, w-6, h-6, 1)
            elseif self.isHovered then
                surface.SetDrawColor(140, 160, 80, 200)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            else
                surface.SetDrawColor(60, 80, 40, 160)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            -- Превью персонажа (PNG картинка)
            if self.previewMat then
                -- Белая подложка чтобы картинка не сливалась
                surface.SetDrawColor(255, 255, 255, self.isHovered and 255 or 220)
                surface.SetMaterial(self.previewMat)

                -- Центрируем картинку в карточке
                local imgW = w - 20
                local imgH = h - 50
                local imgX = 10
                local imgY = 25

                surface.DrawTexturedRect(imgX, imgY, imgW, imgH)
            else
                -- Заглушка если нет PNG
                surface.SetDrawColor(30, 40, 25, 150)
                surface.DrawRect(10, 25, w - 20, h - 50)
                draw.SimpleText("?", "STALKER_HUD_Large",
                    w/2, h/2, Color(140, 150, 120),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Номер варианта (вверху слева)
            draw.SimpleText(tostring(self.modelIndex), "STALKER_HUD_Medium",
                12, 6, Color(200, 210, 160, 220))

            -- Галочка если выбрано
            if self.isSelected then
                draw.SimpleText("✓", "STALKER_HUD_Large",
                    w - 15, 5, Color(150, 220, 80, 230), TEXT_ALIGN_RIGHT)
            end

            -- Статус внизу
            local statusText = self.isSelected and "[ ВЫБРАНО ]" or
                               (self.isHovered and "Выбрать" or "")
            if statusText ~= "" then
                surface.SetDrawColor(0, 0, 0, 120)
                surface.DrawRect(0, h - 22, w, 22)
                draw.SimpleText(statusText, "STALKER_HUD_Tiny",
                    w/2, h - 11,
                    self.isSelected and Color(150, 220, 80) or Color(200, 210, 160),
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        card.DoClick = function()
            -- Сбрасываем все выборы
            for _, c in ipairs(cards) do
                c.isSelected = false
            end
            card.isSelected = true
            selectedIndex   = card.modelIndex

            -- Сразу отправляем на сервер
            net.Start("STALKER_ModelSelect")
                net.WriteUInt(card.modelIndex, 4)
            net.SendToServer()

            surface.PlaySound("buttons/button15.wav")

            -- Закрываем через короткую паузу
            timer.Simple(0.5, function()
                if IsValid(MODEL_FRAME) then
                    MODEL_FRAME:Remove()
                    MODEL_FRAME = nil
                end
            end)
        end

        table.insert(cards, card)
    end

    -- Обновляем видимость карточек при прокрутке
    local function UpdateCardVisibility()
        for _, card in ipairs(cards) do
            local visIdx = card.modelIndex - scrollOffset
            card:SetVisible(visIdx >= 1 and visIdx <= maxVisible)
        end
    end

    -- Перехватываем DoClick стрелок для обновления видимости
    if IsValid(arrowLeft) then
        local origLeft = arrowLeft.DoClick
        arrowLeft.DoClick = function()
            scrollOffset = math.max(0, scrollOffset - 1)
            UpdateCardVisibility()
        end
    end
    if IsValid(arrowRight) then
        local origRight = arrowRight.DoClick
        arrowRight.DoClick = function()
            scrollOffset = math.min(cardCount - maxVisible, scrollOffset + 1)
            UpdateCardVisibility()
        end
    end

    -- Начальная видимость
    UpdateCardVisibility()

    -- ====================================================
    -- Нижние кнопки
    -- ====================================================
    local bottomY = fH - 50

    -- Линия над кнопками
    local divider = vgui.Create("DPanel", MODEL_FRAME)
    divider:SetPos(0, bottomY - 8)
    divider:SetSize(fW, 1)
    divider.Paint = function(self, w, h)
        surface.SetDrawColor(140, 120, 50, 150)
        surface.DrawRect(0, 0, w, h)
    end

    local function MakeBtn(label, px, bw, onClick)
        local b = vgui.Create("DButton", MODEL_FRAME)
        b:SetPos(px, bottomY)
        b:SetSize(bw, 35)
        b:SetText("")
        b.Paint = function(self, w, h)
            -- Фон
            surface.SetDrawColor(
                self:IsHovered() and 55 or 22,
                self:IsHovered() and 72 or 30,
                self:IsHovered() and 35 or 15,
                self:IsHovered() and 235 or 205
            )
            surface.DrawRect(0, 0, w, h)

            -- Рамка
            surface.SetDrawColor(110, 140, 65, 160)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            -- Внутренняя рамка
            surface.SetDrawColor(80, 100, 45, 80)
            surface.DrawOutlinedRect(1, 1, w-2, h-2, 1)

            -- Текст
            draw.SimpleText(label, "STALKER_HUD_Small",
                w / 2, h / 2,
                Color(205, 215, 168),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = onClick
        return b
    end

    local bW      = 150
    local totalBW = bW * 3 + 20
    local bsx     = fW / 2 - totalBW / 2

    -- Назад (закрыть без выбора)
    MakeBtn("Назад", bsx, bW, function()
        if IsValid(MODEL_FRAME) then
            MODEL_FRAME:Remove()
            MODEL_FRAME = nil
        end
    end)

    -- Автовыбор (случайная модель)
    MakeBtn("Автовыбор", bsx + bW + 10, bW, function()
        local rnd = math.random(1, #models)
        net.Start("STALKER_ModelSelect")
            net.WriteUInt(rnd, 4)
        net.SendToServer()
        surface.PlaySound("buttons/button15.wav")
        if IsValid(MODEL_FRAME) then
            MODEL_FRAME:Remove()
            MODEL_FRAME = nil
        end
    end)

    -- Наблюдатель
    MakeBtn("Наблюдатель", bsx + (bW + 10) * 2, bW, function()
        if IsValid(MODEL_FRAME) then
            MODEL_FRAME:Remove()
            MODEL_FRAME = nil
        end
    end)
end