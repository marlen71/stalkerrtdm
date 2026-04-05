-- ============================================================================
-- S.T.A.L.K.E.R. TDM — cl_modelmenu.lua (ANCHOR centered, exact sizes)
-- ============================================================================

local MODEL_FRAME
local matCache = {}

local function MAT(path)
    if matCache[path] then return matCache[path] end
    matCache[path] = Material(path, "noclamp smooth")
    return matCache[path]
end

local MODEL_PREVIEWS = {
    ["models/flaymi/anomaly/stalker_merc_mp/stalker_ki_mask.mdl"] =
        "stalker_tdm/icons/merc_mp2.png",
    ["models/flaymi/anomaly/stalker_merc_mp/stalker_merc_2.mdl"] =
        "stalker_tdm/icons/merc_mp1.png",

    ["models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_old.mdl"] =
        "stalker_tdm/icons/free_mp1.png",
    ["models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_mas4.mdl"] =
        "stalker_tdm/icons/free_mp2.png",
}

local BASE_W, BASE_H = 1680, 1050

-- ЯКОРЬ: ui_panel_desc
local AX, AY = 335, 87
local AW, AH = 1251, 905

local function Compute()
    local sw, sh = ScrW(), ScrH()
    local s = math.min(sw / BASE_W, sh / BASE_H)

    local panelW = AW * s
    local panelH = AH * s
    local panelX = (sw - panelW) * 0.5
    local panelY = (sh - panelH) * 0.5

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
    surface.SetDrawColor(255,255,255,255)
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
            w * 0.5, h * 0.52, Color(210,200,140),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function Apply(panel)
    local u = panel._ui
    if not u then return end
    local s, ox, oy = Compute()
    panel:SetPos(SX(u.x, s, ox), SY(u.y, s, oy))
    panel:SetSize(SW(u.w, s), SH(u.h, s))
end

net.Receive("STALKER_OpenModelMenu", function()
    local teamName  = net.ReadString()
    local factionID = net.ReadString()
    local count     = net.ReadUInt(4)
    local models    = {}
    for i=1,count do models[i] = net.ReadString() end
    STALKER_OpenModelMenu(teamName, factionID, models)
end)

function STALKER_OpenModelMenu(teamName, factionID, models)
    if IsValid(MODEL_FRAME) then MODEL_FRAME:Remove() end
    if not models or #models == 0 then return end

    local matPanelDesc = MAT("stalker_tdm/ui_menu/ui_panel_desc.png")
    local matTwoWin    = MAT("stalker_tdm/ui_menu/ui_two_windows.png")
    local matBtnOff    = MAT("stalker_tdm/ui_menu/ui_button_off.png")
    local matBtnOn     = MAT("stalker_tdm/ui_menu/ui_button_on.png")

    MODEL_FRAME = vgui.Create("DFrame")
    MODEL_FRAME:SetSize(ScrW(), ScrH())
    MODEL_FRAME:SetPos(0,0)
    MODEL_FRAME:SetTitle("")
    MODEL_FRAME:SetDraggable(false)
    MODEL_FRAME:ShowCloseButton(false)
    MODEL_FRAME:SetBackgroundBlur(false)
    MODEL_FRAME:MakePopup()

    -- карточки моделей
    local card1 = vgui.Create("DButton", MODEL_FRAME)
    local card2 = vgui.Create("DButton", MODEL_FRAME)
    card1:SetText("")
    card2:SetText("")
    card1._ui = { x = 793,  y = 213, w = 124, h = 320 }
    card2._ui = { x = 1043, y = 213, w = 124, h = 320 }

    local function SetupCard(card, idx)
        local mdl = models[idx]
        local pth = mdl and MODEL_PREVIEWS[mdl]
        local pm  = pth and MAT(pth) or nil

        card.Paint = function(self, w, h)
            if pm then
                surface.SetMaterial(pm)
                surface.SetDrawColor(255,255,255,255)
                surface.DrawTexturedRect(0,0,w,h)
            end
            if self:IsHovered() then
                surface.SetDrawColor(200,200,100,120)
                surface.DrawOutlinedRect(0,0,w,h,2)
            end
        end

        card.DoClick = function()
            net.Start("STALKER_ModelSelect")
                net.WriteUInt(idx, 4)
            net.SendToServer()
            surface.PlaySound("buttons/button15.wav")
            timer.Simple(0.1, function()
                if IsValid(MODEL_FRAME) then MODEL_FRAME:Remove() end
            end)
        end
    end

    SetupCard(card1, 1)
    SetupCard(card2, 2)

    -- кнопки
    local btnBack = vgui.Create("DButton", MODEL_FRAME)
    local btnAuto = vgui.Create("DButton", MODEL_FRAME)
    local btnSpec = vgui.Create("DButton", MODEL_FRAME)

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
            if IsValid(MODEL_FRAME) then MODEL_FRAME:Remove() end
        end)
    end

    btnAuto.DoClick = function(self)
        self._pressTime = CurTime()
        surface.PlaySound("buttons/button15.wav")
        timer.Simple(0.28, function()
            if not IsValid(MODEL_FRAME) then return end
            local rnd = math.random(1, #models)
            net.Start("STALKER_ModelSelect")
                net.WriteUInt(rnd, 4)
            net.SendToServer()
            MODEL_FRAME:Remove()
        end)
    end

    btnSpec.DoClick = function(self)
        self._pressTime = CurTime()
        surface.PlaySound("buttons/button15.wav")
        timer.Simple(0.28, function()
            if not IsValid(MODEL_FRAME) then return end
            net.Start("STALKER_GoSpectator")
            net.SendToServer()
            MODEL_FRAME:Remove()
        end)
    end

    MODEL_FRAME.Paint = function(self, w, h)
        local s, ox, oy = Compute()

        DrawPNG(matPanelDesc, 335, 87, 1251, 905, s, ox, oy)
        DrawPNG(matTwoWin,    428, 177, 1097, 432, s, ox, oy)

        draw.SimpleText("Выбор формы", "STALKER_HUD_Medium",
            SX(423, s, ox), SY(104, s, oy),
            Color(210,200,140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        draw.SimpleText("1", "STALKER_HUD_Medium",
            SX(914, s, ox), SY(206, s, oy),
            Color(200,210,160), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("2", "STALKER_HUD_Medium",
            SX(1161, s, ox), SY(206, s, oy),
            Color(200,210,160), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end

    MODEL_FRAME.Think = function()
        if not IsValid(MODEL_FRAME) then return end
        Apply(card1); Apply(card2)
        Apply(btnBack); Apply(btnAuto); Apply(btnSpec)
    end
end
