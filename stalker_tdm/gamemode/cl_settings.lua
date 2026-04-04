-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Настройки (без изменений)
-- ============================================================================

local settingsFrame = nil

function STALKER_OpenSettings()
    if IsValid(settingsFrame) then
        settingsFrame:Remove()
        settingsFrame = nil
        return
    end

    local frameW, frameH = 450, 420

    settingsFrame = vgui.Create("DFrame")
    settingsFrame:SetSize(frameW, frameH)
    settingsFrame:Center()
    settingsFrame:SetTitle("")
    settingsFrame:SetDraggable(true)
    settingsFrame:MakePopup()
    settingsFrame:SetDeleteOnClose(true)

    settingsFrame.Paint = function(self, w, h)
        surface.SetDrawColor(15, 20, 10, 245)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(80, 100, 60, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        draw.SimpleText("═══ НАСТРОЙКИ ═══", "STALKER_HUD_Large",
            w / 2, 15, Color(200, 210, 180), TEXT_ALIGN_CENTER)
    end

    local v = STALKER_CLIENT.Visuals

    local scrollPanel = vgui.Create("DScrollPanel", settingsFrame)
    scrollPanel:SetPos(10, 50)
    scrollPanel:SetSize(frameW - 20, frameH - 60)

    local function AddHeader(text)
        local h = vgui.Create("DLabel", scrollPanel)
        h:Dock(TOP)
        h:DockMargin(0, 10, 0, 5)
        h:SetText(text)
        h:SetFont("STALKER_HUD_Medium")
        h:SetTextColor(Color(180, 200, 120))
        h:SetTall(25)
    end

    local function AddCheckbox(text, getter, setter)
        local cb = vgui.Create("DCheckBoxLabel", scrollPanel)
        cb:Dock(TOP)
        cb:DockMargin(10, 3, 0, 0)
        cb:SetText(text)
        cb:SetFont("STALKER_HUD_Small")
        cb:SetTextColor(Color(200, 210, 180))
        cb:SetChecked(getter())
        cb:SetTall(22)
        cb.OnChange = function(self, val)
            setter(val)
            STALKER_SaveClientSettings()
        end
    end

    local function AddSlider(text, getter, setter, min, max)
        local s = vgui.Create("DNumSlider", scrollPanel)
        s:Dock(TOP)
        s:DockMargin(10, 3, 10, 0)
        s:SetText(text)
        s:SetMin(min)
        s:SetMax(max)
        s:SetDecimals(0)
        s:SetValue(getter())
        s:SetTall(30)
        s.Label:SetFont("STALKER_HUD_Tiny")
        s.Label:SetTextColor(Color(200, 210, 180))
        s.OnValueChanged = function(self, val)
            setter(math.floor(val))
            STALKER_SaveClientSettings()
        end
    end

    AddHeader("Визуальные эффекты")

    AddCheckbox("Шум/зерно экрана",
        function() return v.NoiseEnabled end,
        function(val) v.NoiseEnabled = val end)

    AddSlider("Интенсивность шума",
        function() return v.NoiseAlpha end,
        function(val) v.NoiseAlpha = val end, 0, 50)

    AddCheckbox("Цветовой фильтр (STALKER стиль)",
        function() return v.ColorModEnabled end,
        function(val) v.ColorModEnabled = val end)

    AddHeader("HUD")

    AddSlider("Прозрачность HUD",
        function() return v.HUDAlpha end,
        function(val) v.HUDAlpha = val end, 50, 255)

    AddHeader("Управление")

    local binds = vgui.Create("DLabel", scrollPanel)
    binds:Dock(TOP)
    binds:DockMargin(10, 5, 0, 0)
    binds:SetText(
        "B — Магазин (на базе)\n" ..
        "M — Выбор команды\n" ..
        "TAB — Таблица\n" ..
        "F2 — Настройки")
    binds:SetFont("STALKER_HUD_Small")
    binds:SetTextColor(Color(180, 190, 160))
    binds:SetTall(80)
    binds:SetWrap(true)
    binds:SetAutoStretchVertical(true)

    AddHeader("О режиме")

    local info = vgui.Create("DLabel", scrollPanel)
    info:Dock(TOP)
    info:DockMargin(10, 5, 0, 0)
    info:SetText(
        "S.T.A.L.K.E.R. TDM v1.1\n" ..
        "Лимит фрагов: " .. STALKER_CONFIG.FragLimit .. "\n" ..
        "Время раунда: " .. STALKER_CONFIG.RoundTime .. " сек\n" ..
        "Карта: " .. game.GetMap())
    info:SetFont("STALKER_HUD_Tiny")
    info:SetTextColor(Color(140, 150, 120))
    info:SetTall(70)
    info:SetWrap(true)
    info:SetAutoStretchVertical(true)
end