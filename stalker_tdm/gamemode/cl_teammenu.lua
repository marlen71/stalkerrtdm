-- ============================================================================
-- S.T.A.L.K.E.R. TDM — cl_teammenu.lua (ANCHOR centered, no over-stretch)
-- ============================================================================

local TEAM_FRAME
local matCache = {}

local function MAT(path)
    if matCache[path] then return matCache[path] end
    matCache[path] = Material(path, "noclamp smooth")
    return matCache[path]
end

-- Дизайн-сетка
local BASE_W, BASE_H = 1680, 1050

-- Якорь: ui_panel_desc
local AX, AY = 335, 87
local PANEL_W, PANEL_H = 1251, 905

-- ui_window_panel (НЕ 1251x905, иначе растягивается)
-- Используем твои “визуально правильные” размеры:
local WINDOW_X, WINDOW_Y = 423, 253
local WINDOW_W, WINDOW_H = 1113, 361

local function Compute()
    local sw, sh = ScrW(), ScrH()
    local s = math.min(sw / BASE_W, sh / BASE_H)

    -- Центрируем именно панель ui_panel_desc
    local panelW = PANEL_W * s
    local panelH = PANEL_H * s
    local panelX = (sw - panelW) * 0.5
    local panelY = (sh - panelH) * 0.5

    -- ox/oy так, чтобы (AX,AY) попал в (panelX,panelY)
    local ox = panelX - AX * s
    local oy = panelY - AY * s
    return s, ox, oy
end

local function SX(x, s, ox) return math.floor(ox + x * s) end
local function SY(y, s, oy) return math.floor(oy + y * s) end
local function SW(w, s) return math.floor(w * s) end
local function SH(h, s) return math.floor(h * s) end

local function DrawPNG(mat, x, y, w, h, s, ox, oy)
    surface.SetMaterial(mat)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(SX(x, s, ox), SY(y, s, oy), SW(w, s), SH(h, s))
end

local function SetupPNGButton(btn, label, matOff, matOn)
    btn._pressTime = -1
    btn:SetText("")
    btn.Paint = function(self, w, h)
        local pressed = (self._pressTime > 0) and (CurTime() - self._pressTime < 0.28)
        surface.SetMaterial(pressed and matOn or matOff)
        surface.SetDrawColor(255,255,255,255)
        surface.DrawTexturedRect(0, 0, w, h)

        draw.SimpleText(label, "STALKER_HUD_Small",
            w * 0.5, h * 0.52,
            Color(210,200,140), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function Apply(panel)
    local u = panel._ui
    if not u then return end
    local s, ox, oy = Compute()
    panel:SetPos(SX(u.x, s, ox), SY(u.y, s, oy))
    panel:SetSize(SW(u.w, s), SH(u.h, s))
end

function STALKER_OpenTeamMenu()
    if IsValid(TEAM_FRAME) then TEAM_FRAME:Remove() TEAM_FRAME = nil return end

    local matPanelDesc = MAT("stalker_tdm/ui_menu/ui_panel_desc.png")
    local matWindow    = MAT("stalker_tdm/ui_menu/ui_window_panel.png")
    local matBtnOff    = MAT("stalker_tdm/ui_menu/ui_button_off.png")
    local matBtnOn     = MAT("stalker_tdm/ui_menu/ui_button_on.png")
    local matFree      = MAT("ui_greenteam.png")
    local matMerc      = MAT("ui_blueteam.png")

    TEAM_FRAME = vgui.Create("DFrame")
    TEAM_FRAME:SetSize(ScrW(), ScrH())
    TEAM_FRAME:SetPos(0, 0)
    TEAM_FRAME:SetTitle("")
    TEAM_FRAME:SetDraggable(false)
    TEAM_FRAME:ShowCloseButton(false)
    TEAM_FRAME:SetBackgroundBlur(false)
    TEAM_FRAME:MakePopup()

    -- кликабельные зоны команд
    local btnFree = vgui.Create("DButton", TEAM_FRAME)
    local btnMerc = vgui.Create("DButton", TEAM_FRAME)
    btnFree:SetText("")
    btnMerc:SetText("")
    btnFree._ui = { x = 589,  y = 275, w = 256, h = 256 }
    btnMerc._ui = { x = 1111, y = 275, w = 256, h = 256 }

    btnFree.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(50,200,50,60)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(50,220,50,160)
            surface.DrawOutlinedRect(0,0,w,h,2)
        end
    end
    btnMerc.Paint = function(self, w, h)
        if self:IsHovered() then
            surface.SetDrawColor(80,130,255,60)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(80,130,255,160)
            surface.DrawOutlinedRect(0,0,w,h,2)
        end
    end

    btnFree.DoClick = function()
        net.Start("STALKER_TeamSelect")
            net.WriteUInt(TEAM_FACTION2, 4)
        net.SendToServer()
        surface.PlaySound("buttons/button15.wav")
        if IsValid(TEAM_FRAME) then TEAM_FRAME:Remove() TEAM_FRAME = nil end
    end

    btnMerc.DoClick = function()
        net.Start("STALKER_TeamSelect")
            net.WriteUInt(TEAM_FACTION1, 4)
        net.SendToServer()
        surface.PlaySound("buttons/button15.wav")
        if IsValid(TEAM_FRAME) then TEAM_FRAME:Remove() TEAM_FRAME = nil end
    end

    -- нижние кнопки
    local btnBack = vgui.Create("DButton", TEAM_FRAME)
    local btnAuto = vgui.Create("DButton", TEAM_FRAME)
    local btnSpec = vgui.Create("DButton", TEAM_FRAME)

    SetupPNGButton(btnBack, "Назад", matBtnOff, matBtnOn)
    SetupPNGButton(btnAuto, "Автовыбор", matBtnOff, matBtnOn)
    SetupPNGButton(btnSpec, "Наблюдатель", matBtnOff, matBtnOn)

    btnBack._ui = { x = 423,  y = 926, w = 234, h = 71 }
    btnAuto._ui = { x = 1094, y = 926, w = 234, h = 71 }
    btnSpec._ui = { x = 1328, y = 926, w = 234, h = 71 }

    btnBack.DoClick = function(self)
        self._pressTime = CurTime()
        surface.PlaySound("buttons/button15.wav")
        timer.Simple(0.28, function()
            if IsValid(TEAM_FRAME) then TEAM_FRAME:Remove() TEAM_FRAME = nil end
        end)
    end

    btnAuto.DoClick = function(self)
        self._pressTime = CurTime()
        surface.PlaySound("buttons/button15.wav")
        timer.Simple(0.28, function()
            if not IsValid(TEAM_FRAME) then return end
            local t1 = team.NumPlayers(TEAM_FACTION1)
            local t2 = team.NumPlayers(TEAM_FACTION2)
            local pick = (t1 <= t2) and TEAM_FACTION1 or TEAM_FACTION2
            net.Start("STALKER_TeamSelect")
                net.WriteUInt(pick, 4)
            net.SendToServer()
            TEAM_FRAME:Remove()
            TEAM_FRAME = nil
        end)
    end

    btnSpec.DoClick = function(self)
        self._pressTime = CurTime()
        surface.PlaySound("buttons/button15.wav")
        timer.Simple(0.28, function()
            if not IsValid(TEAM_FRAME) then return end
            net.Start("STALKER_GoSpectator")
            net.SendToServer()
            TEAM_FRAME:Remove()
            TEAM_FRAME = nil
        end)
    end

    TEAM_FRAME.Paint = function(self, w, h)
        local s, ox, oy = Compute()

        -- базовая панель
        DrawPNG(matPanelDesc, AX, AY, PANEL_W, PANEL_H, s, ox, oy)

        -- окно (не раздуваем!)
        DrawPNG(matWindow, WINDOW_X, WINDOW_Y, WINDOW_W, WINDOW_H, s, ox, oy)

        -- заголовок
        draw.SimpleText("Выбор команды", "STALKER_HUD_Medium",
            SX(423, s, ox), SY(104, s, oy),
            Color(210,200,140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- номера
        draw.SimpleText("1", "STALKER_HUD_Medium",
            SX(837, s, ox), SY(275, s, oy),
            Color(200,210,160), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("2", "STALKER_HUD_Medium",
            SX(1367, s, ox), SY(275, s, oy),
            Color(200,210,160), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- иконки
        DrawPNG(matFree, 589, 275, 256, 256, s, ox, oy)
        DrawPNG(matMerc, 1111, 275, 256, 256, s, ox, oy)
    end

    TEAM_FRAME.Think = function()
        if not IsValid(TEAM_FRAME) then return end
        Apply(btnFree); Apply(btnMerc)
        Apply(btnBack); Apply(btnAuto); Apply(btnSpec)
    end
end
