-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Scoreboard (ИСПРАВЛЕНО)
-- ============================================================================

local scoreboardPanel = nil

function GM:ScoreboardShow()
    if IsValid(scoreboardPanel) then
        scoreboardPanel:Remove()
    end

    local scrW, scrH = ScrW(), ScrH()
    local frameW, frameH = 850, 580

    scoreboardPanel = vgui.Create("DPanel")
    scoreboardPanel:SetSize(frameW, frameH)
    scoreboardPanel:Center()
    scoreboardPanel:MakePopup()
    scoreboardPanel:SetKeyboardInputEnabled(false)

    scoreboardPanel.Paint = function(self, w, h)
        surface.SetDrawColor(15, 20, 10, 245)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(80, 100, 60, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        draw.SimpleText("S.T.A.L.K.E.R. TDM", "STALKER_HUD_Large",
            w / 2, 10, Color(200, 210, 180), TEXT_ALIGN_CENTER)

        -- Счёт
        local matchup = STALKER_CONFIG.FactionMatchups[STALKER_CLIENT.CurrentMatchup or 1]
        if matchup then
            local s1 = STALKER_CLIENT.TeamScores[TEAM_FACTION1] or 0
            local s2 = STALKER_CLIENT.TeamScores[TEAM_FACTION2] or 0

            draw.SimpleText(matchup.team1.name, "STALKER_HUD_Medium",
                w / 2 - 100, 42, matchup.team1.color, TEXT_ALIGN_RIGHT)
            draw.SimpleText(s1 .. " : " .. s2, "STALKER_HUD_Large",
                w / 2, 38, Color(200, 210, 180), TEXT_ALIGN_CENTER)
            draw.SimpleText(matchup.team2.name, "STALKER_HUD_Medium",
                w / 2 + 100, 42, matchup.team2.color)
        end

        -- Карта
        draw.SimpleText("Карта: " .. game.GetMap(), "STALKER_HUD_Tiny",
            w - 10, h - 15, Color(120, 130, 100, 150), TEXT_ALIGN_RIGHT)
    end

    -- Заголовки
    local colX = { 15, 320, 410, 490, 580, 700 }
    local colNames = { "Игрок", "Ранг", "Убийства", "Смерти", "Деньги", "K/D" }

    local headerPanel = vgui.Create("DPanel", scoreboardPanel)
    headerPanel:SetPos(0, 72)
    headerPanel:SetSize(frameW, 25)
    headerPanel.Paint = function(self, w, h)
        surface.SetDrawColor(40, 50, 30, 200)
        surface.DrawRect(0, 0, w, h)
        for i, name in ipairs(colNames) do
            draw.SimpleText(name, "STALKER_HUD_Small",
                colX[i], 4, Color(180, 190, 160))
        end
    end

    -- Список
    local listPanel = vgui.Create("DScrollPanel", scoreboardPanel)
    listPanel:SetPos(0, 100)
    listPanel:SetSize(frameW, frameH - 120)

    local scrollbar = listPanel:GetVBar()
    scrollbar:SetWide(6)
    scrollbar.Paint = function() end
    scrollbar.btnGrip.Paint = function(self, w, h)
        surface.SetDrawColor(80, 100, 60, 200)
        surface.DrawRect(0, 0, w, h)
    end
    scrollbar.btnUp.Paint = function() end
    scrollbar.btnDown.Paint = function() end

    -- Игроки по командам
    local teams = { [TEAM_FACTION1] = {}, [TEAM_FACTION2] = {} }

    for _, ply in ipairs(player.GetAll()) do
        local t = ply:Team()
        if teams[t] then
            table.insert(teams[t], ply)
        end
    end

    for _, pList in pairs(teams) do
        table.sort(pList, function(a, b)
            return a:GetNWInt("STALKER_Kills", 0) > b:GetNWInt("STALKER_Kills", 0)
        end)
    end

    local function AddTeamSection(teamID, players)
        local tc = team.GetColor(teamID) or Color(200, 200, 200)
        local tn = team.GetName(teamID) or "Unknown"

        local header = vgui.Create("DPanel", listPanel)
        header:Dock(TOP)
        header:DockMargin(0, 8, 0, 2)
        header:SetTall(24)
        header.Paint = function(self, w, h)
            surface.SetDrawColor(tc.r, tc.g, tc.b, 60)
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(
                tn .. " — " .. #players .. " игроков",
                "STALKER_HUD_Small", 10, 4, tc)
        end

        for _, ply in ipairs(players) do
            local row = vgui.Create("DPanel", listPanel)
            row:Dock(TOP)
            row:DockMargin(0, 1, 0, 0)
            row:SetTall(28)

            local k = ply:GetNWInt("STALKER_Kills", 0)
            local d = ply:GetNWInt("STALKER_Deaths", 0)
            local m = ply:GetNWInt("STALKER_Money", 0)
            local rl = ply:GetNWInt("STALKER_Rank", 1)
            local rd = STALKER_CONFIG.Ranks[rl]
            local rn = rd and rd.name or "?"
            local kd = d > 0
                and string.format("%.2f", k / d)
                or tostring(k)

            local isMe = (ply == LocalPlayer())

            row.Paint = function(self, w, h)
                if isMe then
                    surface.SetDrawColor(tc.r, tc.g, tc.b, 35)
                else
                    surface.SetDrawColor(20, 25, 15, 150)
                end
                surface.DrawRect(0, 0, w, h)

                if self:IsHovered() then
                    surface.SetDrawColor(60, 80, 40, 40)
                    surface.DrawRect(0, 0, w, h)
                end

                local txtC = isMe and Color(255, 255, 200) or Color(200, 210, 180)

                draw.SimpleText(ply:Nick(), "STALKER_HUD_Small",
                    colX[1], 6, txtC)
                draw.SimpleText(rn, "STALKER_HUD_Tiny",
                    colX[2], 7, Color(150, 180, 120))
                draw.SimpleText(tostring(k), "STALKER_HUD_Small",
                    colX[3], 6, Color(100, 220, 100))
                draw.SimpleText(tostring(d), "STALKER_HUD_Small",
                    colX[4], 6, Color(220, 100, 100))
                draw.SimpleText(string.format("%d RU", m), "STALKER_HUD_Tiny",
                    colX[5], 7, Color(220, 200, 80))
                draw.SimpleText(kd, "STALKER_HUD_Small",
                    colX[6], 6, txtC)
            end
        end
    end

    AddTeamSection(TEAM_FACTION1, teams[TEAM_FACTION1])
    AddTeamSection(TEAM_FACTION2, teams[TEAM_FACTION2])

    -- Обновление каждую секунду
    timer.Create("STALKER_ScoreboardRefresh", 1, 0, function()
        if IsValid(scoreboardPanel) then
            scoreboardPanel:Remove()
            GAMEMODE:ScoreboardShow()
        else
            timer.Remove("STALKER_ScoreboardRefresh")
        end
    end)
end

function GM:ScoreboardHide()
    if IsValid(scoreboardPanel) then
        scoreboardPanel:Remove()
        scoreboardPanel = nil
    end
    timer.Remove("STALKER_ScoreboardRefresh")
end