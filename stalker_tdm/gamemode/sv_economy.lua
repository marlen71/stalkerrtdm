-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Серверная экономика
-- ============================================================================

function GM:AddMoney(ply, amount, reason)
    if not IsValid(ply) then return end

    local current = ply:GetNWInt("STALKER_Money", 0)
    local newAmount = math.Clamp(current + amount, 0, STALKER_CONFIG.MaxMoney)
    ply:SetNWInt("STALKER_Money", newAmount)

    net.Start("STALKER_MoneyNotify")
        net.WriteInt(amount, 32)
        net.WriteString(reason or "")
    net.Send(ply)
end

function GM:SetMoney(ply, amount)
    if not IsValid(ply) then return end
    ply:SetNWInt("STALKER_Money", math.Clamp(amount, 0, STALKER_CONFIG.MaxMoney))
end

function GM:GetMoney(ply)
    return ply:GetNWInt("STALKER_Money", 0)
end

-- ============================================================================
-- ПОКУПКА ПРЕДМЕТА (ИСПРАВЛЕНО — с поддержкой моделей брони)
-- ============================================================================
function GM:AttemptPurchase(ply, itemClass)
    local item = self:GetShopItem(itemClass)
    if not item then
        self:SendBuyResult(ply, false, "Предмет не найден")
        return false
    end

    -- Проверка: жив ли
    if not ply:Alive() then
        self:SendBuyResult(ply, false, "Вы мертвы!")
        return false
    end

    -- Проверка: в команде ли
    if ply:Team() ~= TEAM_FACTION1 and ply:Team() ~= TEAM_FACTION2 then
        self:SendBuyResult(ply, false, "Сначала выберите команду!")
        return false
    end

    -- Проверка зоны покупки
    if not self:IsInBuyZone(ply) then
        self:SendBuyResult(ply, false, "Покупка доступна только на базе!")
        return false
    end

    -- Проверка состояния раунда
    if self.RoundState ~= ROUND_ACTIVE and self.RoundState ~= ROUND_WARMUP then
        self:SendBuyResult(ply, false, "Покупка недоступна сейчас")
        return false
    end

    -- Проверка ранга
    local playerRank = ply:GetNWInt("STALKER_Rank", 1)
    if not self:CanRankUseItem(playerRank, item) then
        local reqRank = STALKER_CONFIG.Ranks[item.minRank]
        self:SendBuyResult(ply, false,
            "Требуется ранг: " .. (reqRank and reqRank.name or "???"))
        return false
    end

    -- Проверка денег
    local money = self:GetMoney(ply)
    if money < item.price then
        self:SendBuyResult(ply, false,
            "Недостаточно средств! (нужно " .. item.price .. " RU)")
        return false
    end

    -- ====== ПОКУПКА! ======
    self:SetMoney(ply, money - item.price)

    if item.category == "armor" then
        -- ====== БРОНЯ С МОДЕЛЬЮ ======
        local armorVal = item.armorVal or 100
        ply:SetArmor(math.min(ply:Armor() + armorVal, 255))

        -- Сохраняем тип брони и устанавливаем модель
        if item.isArmor then
            ply:SetNWString("STALKER_CurrentArmor", item.class)

            -- Получаем модель для фракции игрока
            local armorModel = self:GetArmorModelForPlayer(ply, item.class)
            if armorModel then
                ply:SetModel(armorModel)
                print("[STALKER TDM] Set armor model for " .. ply:Nick() ..
                    ": " .. armorModel)
            end
        end

    elseif item.category == "ammo" then
        -- ====== ПАТРОНЫ ======
        ply:GiveAmmo(item.ammoCount or 30, item.ammoType or "pistol", true)

    else
        -- ====== ОРУЖИЕ ======
        -- Проверяем, нет ли уже такого оружия
        if ply:HasWeapon(item.class) then
            self:SetMoney(ply, money) -- Возвращаем деньги
            self:SendBuyResult(ply, false, "У вас уже есть это оружие!")
            return false
        end

        ply:Give(item.class)
    end

    self:SendBuyResult(ply, true, item.name .. " куплен!")
    ply:EmitSound(STALKER_CONFIG.Sounds.Buy)

    return true
end

function GM:SendBuyResult(ply, success, message)
    net.Start("STALKER_BuyResult")
        net.WriteBool(success)
        net.WriteString(message)
    net.Send(ply)

    if not success then
        ply:EmitSound(STALKER_CONFIG.Sounds.CantBuy)
    end
end

-- ============================================================================
-- ОБРАБОТКА ЗАПРОСОВ ПОКУПКИ
-- ============================================================================
net.Receive("STALKER_BuyItem", function(len, ply)
    local itemClass = net.ReadString()
    if not IsValid(ply) then return end
    
    -- Находим предмет в конфиге
    local itemData = nil
    for _, item in ipairs(STALKER_CONFIG.ShopItems) do
        if item.class == itemClass then
            itemData = item
            break
        end
    end
    
    if not itemData then return end
    
    -- Проверка ранга
    if ply:GetNWInt("STALKER_Rank", 1) < (itemData.minRank or 1) then
        ply:ChatPrint("[STALKER] Недостаточно ранга!")
        return
    end
    
    -- Проверка денег
    local money = ply:GetNWInt("STALKER_Money", 0)
    if money < itemData.price then
        ply:ChatPrint("[STALKER] Недостаточно рублей!")
        return
    end
    
    -- ===== ПРОВЕРКА СЛОТОВ =====
    local currentWeps = ply:GetWeapons()
    local hasPistol = false
    local hasPrimary = false
    local hasGrenadeCount = 0
    
    local pistols = {
        "tfa_st_pm", "tfa_st_pb", "tfa_st_walter", "tfa_st_usp45", 
        "tfa_st_sig220", "tfa_st_desert"
    }
    local primaries = {
        "tfa_st_mp5", "tfa_st_bm16", "tfa_st_bm16a", "tfa_st_toz34", 
        "tfa_st_winchester1300", "tfa_st_spas12", "tfa_st_protecta",
        "tfa_st_ak74u", "tfa_st_ak74", "tfa_st_lr300", "tfa_st_an94", 
        "tfa_st_val", "tfa_st_svu", "tfa_st_svd", "tfa_st_vintorez", 
        "tfa_st_gauss"
    }
    
    for _, w in ipairs(currentWeps) do
        local cls = w:GetClass()
        if table.HasValue(pistols, cls) then hasPistol = true end
        if table.HasValue(primaries, cls) then hasPrimary = true end
        if cls == "tfa_st_f1" or cls == "tfa_st_rgd5" then 
            hasGrenadeCount = hasGrenadeCount + 1 
        end
        if cls == "tfa_st_rpg" then hasGrenadeCount = 99 end
    end
    
    -- Проверка брони
    local currentArmor = ply:GetNWInt("STALKER_ArmorLevel", 0)
    
    -- Логика проверки
    local category = itemData.category
    local canBuy = true
    local reason = ""
    
    if itemData.isArmor then
        if currentArmor > 0 then
            canBuy = false
            reason = "У вас уже есть броня!"
        end
    elseif category == "pistols" then
        if hasPistol then
            canBuy = false
            reason = "Уже есть пистолет!"
        end
    elseif category == "smg" or category == "shotguns" or 
           category == "rifles" or category == "snipers" then
        if hasPrimary then
            canBuy = false
            reason = "Уже есть основное оружие!"
        end
    elseif category == "grenades" then
        if itemClass == "tfa_st_f1" or itemClass == "tfa_st_rgd5" then
            if hasGrenadeCount >= 2 then
                canBuy = false
                reason = "Максимум 2 гранаты!"
            end
        elseif itemClass == "tfa_st_rpg" then
            if hasGrenadeCount > 0 then
                canBuy = false
                reason = "Нет места для RPG!"
            end
        end
    end
    
    if not canBuy then
        ply:ChatPrint("[STALKER] " .. reason)
        -- ✅ ИСПРАВЛЕНО: используем EmitSound вместо surface.PlaySound
        ply:EmitSound(STALKER_CONFIG.Sounds.CantBuy)
        return
    end
    
    -- ===== ПОКУПКА =====
    ply:SetNWInt("STALKER_Money", money - itemData.price)
    
    if itemData.isArmor then
        local armorLevels = {
            ["armor_light"]  = 1,
            ["armor_medium"] = 2,
            ["armor_heavy"]  = 3,
            ["armor_exo"]    = 4
        }
        
        local newLevel = armorLevels[itemClass] or 0
        if newLevel > currentArmor then
            ply:SetNWInt("STALKER_ArmorLevel", newLevel)
            ply:SetArmor(itemData.armorVal or 0)
            
            local factionID = ply:Team() == TEAM_FACTION1 
                and "mercenaries" or "freedom"
            local models = STALKER_CONFIG.ArmorModels[itemClass]
            if models and models[factionID] then
                local mdl = table.Random(models[factionID])
                if util.IsValidModel(mdl) then
                    ply:SetModel(mdl)
                end
            end
        end
    elseif category == "ammo" then
        ply:GiveAmmo(itemData.ammoCount or 0, itemData.ammoType or "")
    else
        ply:Give(itemClass)
    end
    
    -- ✅ ИСПРАВЛЕНО: используем EmitSound вместо surface.PlaySound
    ply:EmitSound(STALKER_CONFIG.Sounds.Buy)
end)

-- Сброс брони при смерти
hook.Add("PlayerDeath", "STALKER_ResetArmorOnDeath", function(ply)
    if IsValid(ply) then
        ply:SetNWInt("STALKER_ArmorLevel", 0)
    end
end)

-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Обработка продажи предметов (Одиночная и Полная)
-- ============================================================================

util.AddNetworkString("STALKER_SellWeaponSingle")
util.AddNetworkString("STALKER_SellAllInventory")

-- ПОШТУЧНАЯ ПРОДАЖА (ПКМ)
net.Receive("STALKER_SellWeaponSingle", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if not GAMEMODE:IsInBuyZone(ply) then return end

    local class = net.ReadString()
    if not ply:HasWeapon(class) then return end

    -- Поиск предмета
    local itemData = nil
    for _, item in ipairs(STALKER_CONFIG.ShopItems) do
        if item.class == class then itemData = item break end
    end

    if not itemData then return end
    if itemData.category == "melee" and class == "tfa_st_knife" then return end -- Нож продавать нельзя

    -- Удаляем и даём 60% цены
    ply:StripWeapon(class)
    local sellPrice = math.floor(itemData.price * 0.6)
    GAMEMODE:AddMoney(ply, sellPrice, "Продано: " .. itemData.name)
    ply:EmitSound("ambient/levels/canals/coin_drop_1.wav")
end)


-- ПРОДАЖА ВСЕГО (Кнопка снизу)
net.Receive("STALKER_SellAllInventory", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if not GAMEMODE:IsInBuyZone(ply) then return end

    local totalBack = 0
    local weaponsToStrip = {}

    for _, wep in ipairs(ply:GetWeapons()) do
        local class = wep:GetClass()
        if class == "tfa_st_knife" or class == "tfa_st_bolt2" then continue end

        for _, item in ipairs(STALKER_CONFIG.ShopItems) do
            if item.class == class then
                totalBack = totalBack + math.floor(item.price * 0.6)
                table.insert(weaponsToStrip, class)
                break
            end
        end
    end

    for _, class in ipairs(weaponsToStrip) do
        ply:StripWeapon(class)
    end

    if totalBack > 0 then
        GAMEMODE:AddMoney(ply, totalBack, "Продано всё снаряжение")
        ply:EmitSound("ambient/levels/canals/coin_drop_1.wav")
    else
        ply:ChatPrint("[STALKER] Нечего продавать.")
    end
end)