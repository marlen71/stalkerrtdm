-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Голосование (Только за карту!)
-- ============================================================================

local mapVoteFrame = nil

-- ====== ГОЛОСОВАНИЕ ЗА КАРТУ (Оставляем как есть) ======

net.Receive("STALKER_StartMapVote", function()
    local endTime = net.ReadFloat()
    local count = net.ReadUInt(8)
    local maps = {}
    for i = 1, count do
        table.insert(maps, net.ReadString())
    end
    STALKER_OpenMapVote(maps, endTime)
end)

function STALKER_OpenMapVote(maps, endTime)
    if IsValid(mapVoteFrame) then mapVoteFrame:Remove() end

    local frameW = 500
    local btnH = 38
    local frameH = 80 + #maps * (btnH + 5)

    mapVoteFrame = vgui.Create("DPanel")
    mapVoteFrame:SetSize(frameW, frameH)
    mapVoteFrame:Center()
    mapVoteFrame:MakePopup()
    mapVoteFrame:SetKeyboardInputEnabled(false)

    mapVoteFrame.endTime = endTime
    mapVoteFrame.votes = {}
    for i = 1, #maps do
        mapVoteFrame.votes[i] = 0
    end

    mapVoteFrame.Paint = function(self, w, h)
        surface.SetDrawColor(15, 20, 10, 245)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(80, 100, 60, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        draw.SimpleText("═══ ГОЛОСОВАНИЕ ЗА КАРТУ ═══", "STALKER_HUD_Large",
            w / 2, 15, Color(200, 210, 180), TEXT_ALIGN_CENTER)

        local tl = math.max(0, self.endTime - CurTime())
        draw.SimpleText(string.format("Осталось: %d сек", math.ceil(tl)),
            "STALKER_HUD_Small",
            w / 2, h - 18, Color(200, 180, 100), TEXT_ALIGN_CENTER)
    end

    for i, mapName in ipairs(maps) do
        local btn = vgui.Create("DButton", mapVoteFrame)
        btn:SetText("")
        btn:SetPos(20, 50 + (i - 1) * (btnH + 5))
        btn:SetSize(frameW - 40, btnH)
        btn.idx = i

        btn.Paint = function(self, w, h)
            local isCurrent = (mapName == game.GetMap())
            local bg
            if isCurrent then
                bg = Color(60, 50, 30, self:IsHovered() and 220 or 180)
            else
                bg = self:IsHovered()
                    and Color(50, 70, 35, 220)
                    or Color(30, 40, 20, 200)
            end

            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(80, 100, 60, 150)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            local label = mapName
            if isCurrent then label = label .. " (текущая)" end

            draw.SimpleText(label, "STALKER_HUD_Medium",
                15, h / 2, Color(200, 210, 180),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local vc = mapVoteFrame.votes[self.idx] or 0
            draw.SimpleText(tostring(vc), "STALKER_HUD_Medium",
                w - 15, h / 2, Color(180, 200, 100),
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            net.Start("STALKER_MapVote")
                net.WriteUInt(i, 8)
            net.SendToServer()
            surface.PlaySound(STALKER_CONFIG.Sounds.VoteStart)
        end
    end

    timer.Create("STALKER_MapVoteClose",
        math.max(0.1, endTime - CurTime() + 1), 1, function()
        if IsValid(mapVoteFrame) then mapVoteFrame:Remove() end
    end)
end

net.Receive("STALKER_MapVoteUpdate", function()
    if not IsValid(mapVoteFrame) then return end
    for i = 1, #STALKER_CONFIG.MapList do
        mapVoteFrame.votes[i] = net.ReadUInt(8)
    end
end)

net.Receive("STALKER_MapVoteResult", function()
    local mapName = net.ReadString()
    if IsValid(mapVoteFrame) then mapVoteFrame:Remove() end
    chat.AddText(Color(100, 220, 100), "[STALKER] Следующая карта: " .. mapName)
end)