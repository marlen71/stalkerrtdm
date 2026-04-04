-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Серверная система спавнов (ИСПРАВЛЕНО)
-- ============================================================================

function GM:MoveToSpawn(ply)
    local mapName = game.GetMap()
    local spawns = STALKER_CONFIG.Spawns[mapName]

    if not spawns then
        -- Используем стандартные спавны
        local defaultSpawns = ents.FindByClass("info_player_start")
        if #defaultSpawns > 0 then
            local spawn = defaultSpawns[math.random(#defaultSpawns)]
            ply:SetPos(spawn:GetPos() + Vector(0, 0, 10))
            ply:SetEyeAngles(spawn:GetAngles())
        end
        return
    end

    local teamSpawns
    if ply:Team() == TEAM_FACTION1 then
        teamSpawns = spawns.team1
    elseif ply:Team() == TEAM_FACTION2 then
        teamSpawns = spawns.team2
    end

    if not teamSpawns or #teamSpawns == 0 then
        print("[STALKER TDM] WARNING: No spawns for team " .. ply:Team() ..
            " on " .. mapName)
        return
    end

    -- Ищем безопасный спавн
    local bestSpawn = nil
    local bestDist = 0

    for _, spawnData in ipairs(teamSpawns) do
        local pos = spawnData.pos
        local minEnemyDist = math.huge

        for _, other in ipairs(player.GetAll()) do
            if IsValid(other) and other:Alive() and other ~= ply
               and other:Team() ~= ply:Team()
               and (other:Team() == TEAM_FACTION1 or other:Team() == TEAM_FACTION2) then
                local dist = other:GetPos():DistToSqr(pos)
                if dist < minEnemyDist then
                    minEnemyDist = dist
                end
            end
        end

        if minEnemyDist > bestDist then
            bestDist = minEnemyDist
            bestSpawn = spawnData
        end
    end

    if not bestSpawn then
        bestSpawn = teamSpawns[math.random(#teamSpawns)]
    end

    -- Небольшое смещение вверх чтобы не застревать в полу
    ply:SetPos(bestSpawn.pos + Vector(0, 0, 10))
    ply:SetEyeAngles(bestSpawn.ang)
end

-- ============================================================================
-- УТИЛИТЫ ДЛЯ НАСТРОЙКИ СПАВНОВ
-- ============================================================================
concommand.Add("stalker_addspawn", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then
        if IsValid(ply) then
            ply:ChatPrint("[STALKER] Только суперадмины!")
        end
        return
    end

    local teamNum = tonumber(args[1]) or 1
    local mapName = game.GetMap()
    local pos = ply:GetPos()
    local ang = ply:EyeAngles()

    print("======= STALKER SPAWN POINT =======")
    print(string.format(
        '{ pos = Vector(%.1f, %.1f, %.1f), ang = Angle(%.1f, %.1f, %.1f) },',
        pos.x, pos.y, pos.z,
        ang.p, ang.y, ang.r
    ))
    print("Map: " .. mapName .. " | Team: " .. teamNum)
    print("====================================")

    ply:ChatPrint("[STALKER] Спавн записан в консоль. Команда: " .. teamNum)
end)

concommand.Add("stalker_setbuyzone", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local teamNum = tonumber(args[1]) or 1
    local pos = ply:GetPos()

    print("======= STALKER BUY ZONE =======")
    print(string.format(
        'team%dBuyZoneCenter = Vector(%.1f, %.1f, %.1f),',
        teamNum, pos.x, pos.y, pos.z
    ))
    print("=================================")

    ply:ChatPrint("[STALKER] Зона покупки записана. Команда: " .. teamNum)
end)

-- Показать зону покупки (для отладки)
concommand.Add("stalker_showzones", function(ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local mapName = game.GetMap()
    local spawns = STALKER_CONFIG.Spawns[mapName]

    if not spawns then
        ply:ChatPrint("[STALKER] Спавны для этой карты не настроены!")
        return
    end

    ply:ChatPrint("[STALKER] === ЗОНЫ ДЛЯ " .. mapName .. " ===")

    if spawns.team1BuyZoneCenter then
        ply:ChatPrint("[STALKER] Team1 BuyZone: " ..
            tostring(spawns.team1BuyZoneCenter))
    end
    if spawns.team2BuyZoneCenter then
        ply:ChatPrint("[STALKER] Team2 BuyZone: " ..
            tostring(spawns.team2BuyZoneCenter))
    end

    ply:ChatPrint("[STALKER] BuyZone Radius: " ..
        (spawns.buyZoneRadius or 500))

    -- Проверяем текущую позицию
    local inZone = GAMEMODE:IsInBuyZone(ply)
    ply:ChatPrint("[STALKER] Вы " ..
        (inZone and "В зоне покупки" or "ВНЕ зоны покупки"))
end)