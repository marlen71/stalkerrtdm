-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Меню закупки v2.1 (Фикс иконок + Продажа через ПКМ)
-- ============================================================================

local shopFrame = nil
local selectedCat = "pistols"

local cachedMats = {} -- Кэш материалов для оптимизации

STALKER_Loadouts = STALKER_Loadouts or {
    [1] = { name = "Набор №1", pistol = "", primary = "", grenade = "", armor = "" },
    [2] = { name = "Набор №2", pistol = "", primary = "", grenade = "", armor = "" },
    [3] = { name = "Набор №3", pistol = "", primary = "", grenade = "", armor = "" },
}

local function GetPlayerInventory(ply)
    if not IsValid(ply) then return {} end

    local inv = {
        hasKnife = false,
        pistol = nil,
        primary = nil,
        grenades = {},
        armorLevel = 0,
        money = ply:GetNWInt("STALKER_Money", 0),
        rank = ply:GetNWInt("STALKER_Rank", 1),
    }

    local cats = {
        ["tfa_st_knife"] = "knife",
        ["tfa_st_bolt2"] = "knife",

        ["tfa_st_pm"] = "pistol",
        ["tfa_st_pb"] = "pistol",
        ["tfa_st_walter"] = "pistol",
        ["tfa_st_usp45"] = "pistol",
        ["tfa_st_sig220"] = "pistol",
        ["tfa_st_desert"] = "pistol",

        ["tfa_st_mp5"] = "primary",
        ["tfa_st_bm16"] = "primary",
        ["tfa_st_bm16a"] = "primary",
        ["tfa_st_toz34"] = "primary",
        ["tfa_st_winchester1300"] = "primary",
        ["tfa_st_spas12"] = "primary",
        ["tfa_st_protecta"] = "primary",
        ["tfa_st_ak74u"] = "primary",
        ["tfa_st_ak74"] = "primary",
        ["tfa_st_lr300"] = "primary",
        ["tfa_st_an94"] = "primary",
        ["tfa_st_val"] = "primary",
        ["tfa_st_svu"] = "primary",
        ["tfa_st_svd"] = "primary",
        ["tfa_st_vintorez"] = "primary",
        ["tfa_st_gauss"] = "primary",

        ["tfa_st_f1"] = "grenade",
        ["tfa_st_rgd5"] = "grenade",
        ["tfa_st_rpg"] = "rpg",
    }

    local weps = ply:GetWeapons()
    for _, w in ipairs(weps) do
        local cls = w:GetClass()
        local slot = cats[cls]

        if slot == "knife" then
            inv.hasKnife = true
        elseif slot == "pistol" then
            inv.pistol = cls
        elseif slot == "primary" then
            inv.primary = cls
        elseif slot == "grenade" then
            table.insert(inv.grenades, cls)
        elseif slot == "rpg" then
            inv.grenades = { "rpg" }
        end
    end

    inv.armorLevel = ply:GetNWInt("STALKER_ArmorLevel", 0)

    return inv
end

local function GetItemType(item)
    if item.isArmor then return "armor" end
    if item.category == "melee" then
        if item.class == "tfa_st_f1" or item.class == "tfa_st_rgd5" then return "grenade" end
        if item.class == "tfa_st_rpg" then return "rpg" end
        return "knife"
    end
    if item.category == "pistols" then return "pistol" end
    if item.category == "ammo" then return "ammo" end
    return "primary"
end

local function CanBuyItem(inv, item)
    local itemType = GetItemType(item)

    if itemType == "armor" then
        return inv.armorLevel == 0
    end

    if itemType == "pistol" then
        return inv.pistol == nil
    end

    if itemType == "primary" then
        return inv.primary == nil
    end

    if itemType == "grenade" then
        if #inv.grenades > 0 and inv.grenades[1] == "rpg" then return false end
        return #inv.grenades < 2
    end

    if itemType == "rpg" then
        return #inv.grenades == 0
    end

    return true
end

local function GetLoadoutPrice(loadoutIdx)
    local ld = STALKER_Loadouts[loadoutIdx]
    if not ld then return 0 end

    local total = 0

    local function findPrice(class)
        if class == "" then return 0 end
        for _, item in ipairs(STALKER_CONFIG.ShopItems) do
            if item.class == class then return item.price end
        end
        return 0
    end

    if ld.pistol ~= "" then total = total + findPrice(ld.pistol) end
    if ld.primary ~= "" then total = total + findPrice(ld.primary) end
    if ld.grenade ~= "" then total = total + findPrice(ld.grenade) end
    if ld.armor ~= "" then total = total + findPrice(ld.armor) end

    return total
end

function STALKER_OpenShop()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply:Alive() then
        chat.AddText(Color(255, 80, 80), "[STALKER] Вы мертвы! Покупка невозможна.")
        return
    end

    if IsValid(shopFrame) then
        shopFrame:Remove()
        shopFrame = nil
        return
    end

    local fW, fH = 950, 620

    shopFrame = vgui.Create("DFrame")
    shopFrame:SetSize(fW, fH)
    shopFrame:Center()
    shopFrame:SetTitle("")
    shopFrame:SetDraggable(true)
    shopFrame:MakePopup()
    shopFrame:SetDeleteOnClose(true)

    shopFrame.Paint = function(self, w, h)
        surface.SetDrawColor(12, 15, 10, 245)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(65, 75, 55, 220)
        surface.DrawOutlinedRect(0, 0, w, h, 3)
        surface.SetDrawColor(35, 45, 25, 180)
        surface.DrawOutlinedRect(4, 4, w - 8, h - 8, 1)

        draw.SimpleText("МЕНЮ ЗАКУПКИ", "STALKER_HUD_Large", w / 2, 12, Color(210, 200, 140), TEXT_ALIGN_CENTER)

        local money = ply:GetNWInt("STALKER_Money", 0)
        draw.SimpleText(string.format("%d RU", money), "STALKER_Money_Big", w - 25, 18, Color(225, 195, 65), TEXT_ALIGN_RIGHT)

        local rank = ply:GetNWInt("STALKER_Rank", 1)
        local rankData = STALKER_CONFIG.Ranks[rank]
        draw.SimpleText(rankData and rankData.name or "Новичок", "STALKER_HUD_Small", 25, 18, Color(160, 175, 120))
    end

    local itemPanel = vgui.Create("DScrollPanel", shopFrame)
    itemPanel:SetPos(190, 55)
    itemPanel:SetSize(520, fH - 115)

    local infoLabel = vgui.Create("DLabel", shopFrame)
    infoLabel:SetPos(190, fH - 40)
    infoLabel:SetSize(520, 30)
    infoLabel:SetText("")
    infoLabel:SetTextColor(Color(180, 180, 120))

    local PopulateItems

    local catPanel = vgui.Create("DPanel", shopFrame)
    catPanel:SetPos(12, 55)
    catPanel:SetSize(168, fH - 115)

    catPanel.Paint = function(self, w, h)
        surface.SetDrawColor(8, 12, 6, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(70, 85, 50, 160)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local categories = {
        { id = "pistols",  name = "Пистолеты" },
        { id = "smg",      name = "ПП" },
        { id = "shotguns", name = "Дробовики" },
        { id = "rifles",   name = "Автоматы" },
        { id = "snipers",  name = "Снайперские" },
        { id = "melee",    name = "Ближний бой" },
        { id = "armor",    name = "Броня" },
        { id = "ammo",     name = "Патроны" },
    }

    local catButtons = {}

    for i, cat in ipairs(categories) do
        local btn = vgui.Create("DButton", catPanel)
        btn:SetPos(4, 8 + (i - 1) * 48)
        btn:SetSize(160, 42)
        btn:SetText("")

        btn.Selected = false
        btn.SetSelected = function(s, state) s.Selected = state end
        btn.GetSelected = function(s) return s.Selected end

        btn.Paint = function(self, w, h)
            local isSel = (selectedCat == cat.id)
            surface.SetDrawColor(isSel and 45 or 18, isSel and 55 or 22, isSel and 25 or 12, isSel and 255 or 200)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(90, 110, 60, isSel and 200 or 100)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(cat.name, "STALKER_HUD_Medium",
                w / 2, h / 2, isSel and Color(230, 220, 140) or Color(170, 185, 140),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btn.DoClick = function()
            selectedCat = cat.id
            for _, b in pairs(catButtons) do
                if b.SetSelected then b:SetSelected(false) end
            end
            btn:SetSelected(true)
            PopulateItems(cat.id)
        end

        catButtons[cat.id] = btn
    end

    PopulateItems = function(category)
        itemPanel:Clear()

        local grid = vgui.Create("DIconLayout", itemPanel)
        grid:SetWide(itemPanel:GetWide() - 20) 
        grid:SetSpaceX(12)
        grid:SetSpaceY(12)
        grid:SetBorder(10)

        local inv = GetPlayerInventory(ply)

        for _, item in ipairs(STALKER_CONFIG.ShopItems) do
            if item.category ~= category then continue end

            local itemType = GetItemType(item)
            local canBuy = (inv.rank >= (item.minRank or 1)) and (inv.money >= item.price)
            local slotReason = ""

            if canBuy then
                if not CanBuyItem(inv, item) then
                    canBuy = false
                    if itemType == "armor" then
                        slotReason = " (есть броня)"
                    elseif itemType == "pistol" then
                        slotReason = " (есть пистолет)"
                    elseif itemType == "primary" then
                        slotReason = " (есть осн. оружие)"
                    elseif itemType == "grenade" or itemType == "rpg" then
                        slotReason = " (нет места)"
                    else
                        slotReason = " (слот занят)"
                    end
                end
            end

            local isOwned = false
            if itemType == "pistol" and inv.pistol == item.class then
                isOwned = true
            elseif itemType == "primary" and inv.primary == item.class then
                isOwned = true
            elseif itemType == "grenade" then
                for _, g in ipairs(inv.grenades) do
                    if g == item.class then isOwned = true break end
                end
            elseif itemType == "armor" then
                local armLvl = ({ armor_light = 1, armor_medium = 2, armor_heavy = 3, armor_exo = 4 })[item.class] or 0
                if inv.armorLevel > 0 and inv.armorLevel >= armLvl then isOwned = true end
            end

            local icon = grid:Add("DButton")
            icon:SetSize(110, 110)
            icon:SetText("")

            local capturedCanBuy = canBuy
            local capturedIsOwned = isOwned
            local capturedSlotReason = slotReason

            icon.Paint = function(self, w, h)
                surface.SetDrawColor(15, 20, 12, 240)
                surface.DrawRect(0, 0, w, h)

                -- ФИКС КАРТИНОК: Поддержка картинок без file.Exists
                if item.icon then
                    if not cachedMats[item.icon] then
                        cachedMats[item.icon] = Material(item.icon, "unlitgeneric smooth")
                    end
                    surface.SetMaterial(cachedMats[item.icon])
                    surface.SetDrawColor(255, 255, 255, capturedCanBuy and 255 or 90)
                    surface.DrawTexturedRect(4, 4, w - 8, h - 35)
                end

                surface.SetDrawColor(0, 0, 0, 150)
                surface.DrawRect(0, h - 24, w, 24)

                draw.SimpleText(item.name, "STALKER_HUD_Tiny", w / 2, h - 18, Color(200, 205, 170), TEXT_ALIGN_CENTER)

                if item.price > 0 then
                    local col = (inv.money >= item.price) and Color(200, 190, 70) or Color(170, 60, 60)
                    draw.SimpleText(item.price .. " RU", "STALKER_HUD_Tiny", w / 2, h - 6, col, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText("БЕСПЛАТНО", "STALKER_HUD_Tiny", w / 2, h - 6, Color(100, 200, 100), TEXT_ALIGN_CENTER)
                end

                if capturedIsOwned then
                    surface.SetDrawColor(60, 140, 60, 160)
                    surface.DrawRect(0, 0, w, h)
                    draw.SimpleText("✓", "STALKER_HUD_Large", w - 18, 8, Color(80, 220, 80))
                elseif not capturedCanBuy and inv.rank < (item.minRank or 1) then
                    surface.SetDrawColor(100, 60, 60, 100)
                    surface.DrawRect(0, 0, w, h)
                    draw.SimpleText("Ранг", "STALKER_HUD_Tiny", w / 2, h / 2, Color(200, 100, 100), TEXT_ALIGN_CENTER)
                elseif not capturedCanBuy and capturedSlotReason ~= "" then
                    surface.SetDrawColor(100, 100, 60, 100)
                    surface.DrawRect(0, 0, w, h)
                end
            end

            -- ЛКМ: Покупка
            icon.DoClick = function()
                if capturedIsOwned then
                    chat.AddText(Color(255,200,100), "[STALKER] Предмет уже есть! Нажмите ПКМ, чтобы продать.")
                    return
                end

                if not capturedCanBuy then
                    surface.PlaySound(STALKER_CONFIG.Sounds.CantBuy)
                    chat.AddText(Color(255, 100, 100), "[STALKER] Нельзя купить!" .. capturedSlotReason)
                    return
                end

                net.Start("STALKER_BuyItem")
                    net.WriteString(item.class)
                net.SendToServer()

                timer.Simple(0.15, function()
                    if IsValid(infoLabel) then
                        infoLabel:SetText("Куплено: " .. item.name .. " (-" .. item.price .. " RU)")
                        infoLabel:SizeToContents()
                    end
                    if IsValid(itemPanel) then
                        PopulateItems(selectedCat)
                    end
                end)
            end

            -- ПКМ: Продажа одного предмета!
            icon.DoRightClick = function()
                if not capturedIsOwned then return end
                if itemType == "knife" or itemType == "ammo" then return end -- Ножи и патроны продавать нельзя

                local sellPercent = 0.6 -- 60% от цены
                local sellPrice = math.floor(item.price * sellPercent)

                local menu = DermaMenu()
                menu:AddOption("Продать за " .. sellPrice .. " RU", function()
                    net.Start("STALKER_SellWeaponSingle")
                        net.WriteString(item.class)
                    net.SendToServer()

                    timer.Simple(0.2, function()
                        if IsValid(itemPanel) then PopulateItems(selectedCat) end
                    end)
                end):SetIcon("icon16/money_delete.png")
                menu:Open()
            end

            icon.OnCursorEntered = function(self)
                local txt = item.name .. "\nЦена: " .. item.price .. " RU\nМин. ранг: " .. (item.minRank or 1)
                if item.caliber then txt = txt .. "\nКалибр: " .. item.caliber end
                if capturedSlotReason ~= "" then txt = txt .. "\n" .. capturedSlotReason end
                self:SetTooltip(txt)
            end
        end
    end

    -- ====================== ПРАВАЯ ПАНЕЛЬ (Loadout) ======================
    local rightPanel = vgui.Create("DPanel", shopFrame)
    rightPanel:SetPos(fW - 220, 55)
    rightPanel:SetSize(208, fH - 115)

    rightPanel.Paint = function(self, w, h)
        surface.SetDrawColor(10, 14, 8, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(70, 85, 50, 160)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText("НАБОРЫ (LOADOUT)", "STALKER_HUD_Small", w / 2, 8, Color(210, 200, 140), TEXT_ALIGN_CENTER)
    end

    local function GetItemName(class)
        if class == "" then return "" end
        for _, it in ipairs(STALKER_CONFIG.ShopItems) do
            if it.class == class then return it.name end
        end
        return class
    end

    for i = 1, 3 do
        local yOffset = 35 + (i - 1) * 155

        local pnl = vgui.Create("DPanel", rightPanel)
        pnl:SetPos(8, yOffset)
        pnl:SetSize(192, 145)

        local ld = STALKER_Loadouts[i]

        pnl.Paint = function(self, w, h)
            local price = GetLoadoutPrice(i)

            surface.SetDrawColor(20, 25, 15, 230)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(60, 70, 45, 200)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            draw.SimpleText(ld.name, "STALKER_HUD_Small", 10, 5, Color(180, 200, 140), TEXT_ALIGN_LEFT)

            local priceColor = Color(200, 190, 70)
            if price > ply:GetNWInt("STALKER_Money", 0) then
                priceColor = Color(200, 80, 80)
            end
            draw.SimpleText(price > 0 and (price .. " RU") or "БЕСПЛ.", "STALKER_HUD_Tiny", w - 10, 8, priceColor, TEXT_ALIGN_RIGHT)

            local y = 25
            local lineH = 14

            if ld.pistol ~= "" then
                draw.SimpleText("Пист: " .. GetItemName(ld.pistol), "STALKER_HUD_Tiny", 10, y, Color(160, 170, 140), TEXT_ALIGN_LEFT)
                y = y + lineH
            end
            if ld.primary ~= "" then
                draw.SimpleText("Осн: " .. GetItemName(ld.primary), "STALKER_HUD_Tiny", 10, y, Color(160, 170, 140), TEXT_ALIGN_LEFT)
                y = y + lineH
            end
            if ld.grenade ~= "" then
                draw.SimpleText("Гран: " .. GetItemName(ld.grenade), "STALKER_HUD_Tiny", 10, y, Color(160, 170, 140), TEXT_ALIGN_LEFT)
                y = y + lineH
            end
            if ld.armor ~= "" then
                draw.SimpleText("Бр: " .. GetItemName(ld.armor), "STALKER_HUD_Tiny", 10, y, Color(160, 170, 140), TEXT_ALIGN_LEFT)
                y = y + lineH
            end

            if ld.pistol == "" and ld.primary == "" and ld.grenade == "" and ld.armor == "" then
                draw.SimpleText("(пусто)", "STALKER_HUD_Tiny", 10, y, Color(120, 120, 100), TEXT_ALIGN_LEFT)
            end

            if price > 0 and price > ply:GetNWInt("STALKER_Money", 0) then
                surface.SetDrawColor(150, 50, 50, 60)
                surface.DrawRect(0, 0, w, h)
            end
        end

        local btnBuy = vgui.Create("DButton", pnl)
        btnBuy:SetText("")
        btnBuy:SetPos(4, 105)
        btnBuy:SetSize(88, 32)

        btnBuy.Paint = function(self, w, h)
            surface.SetDrawColor(self:IsHovered() and 40 or 20, 50, 25, 200)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(100, 120, 60, 180)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText("КУПИТЬ", "STALKER_HUD_Tiny", w / 2, h / 2, Color(200, 210, 170), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btnBuy.DoClick = function()
            local ldData = STALKER_Loadouts[i]
            if not ldData then return end

            local itemsToBuy = {}
            if ldData.pistol ~= "" then table.insert(itemsToBuy, ldData.pistol) end
            if ldData.primary ~= "" then table.insert(itemsToBuy, ldData.primary) end
            if ldData.grenade ~= "" then table.insert(itemsToBuy, ldData.grenade) end
            if ldData.armor ~= "" and ply:GetNWInt("STALKER_ArmorLevel", 0) == 0 then
                table.insert(itemsToBuy, ldData.armor)
            end

            if #itemsToBuy == 0 then
                chat.AddText(Color(200, 200, 100), "[STALKER] Набор пуст!")
                return
            end

            for idx, cls in ipairs(itemsToBuy) do
                timer.Simple((idx - 1) * 0.3, function()
                    net.Start("STALKER_BuyItem")
                        net.WriteString(cls)
                    net.SendToServer()
                end)
            end

            chat.AddText(Color(100, 255, 100), "[STALKER] Загрузка набора " .. i .. "...")

            timer.Simple(#itemsToBuy * 0.3 + 0.2, function()
                if IsValid(itemPanel) then
                    PopulateItems(selectedCat)
                end
            end)
        end

        local btnSave = vgui.Create("DButton", pnl)
        btnSave:SetText("")
        btnSave:SetPos(96, 105)
        btnSave:SetSize(88, 32)

        btnSave.Paint = function(self, w, h)
            surface.SetDrawColor(self:IsHovered() and 50 or 25, 55, 30, 200)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(130, 110, 60, 180)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText("СОХРАНИТЬ", "STALKER_HUD_Tiny", w / 2, h / 2, Color(200, 180, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        btnSave.DoClick = function()
            local inv = GetPlayerInventory(ply)
            STALKER_Loadouts[i].pistol = inv.pistol or ""
            STALKER_Loadouts[i].primary = inv.primary or ""
            STALKER_Loadouts[i].grenade = (#inv.grenades > 0) and inv.grenades[1] or ""

            if inv.armorLevel > 0 then
                local armorClasses = { "armor_light", "armor_medium", "armor_heavy", "armor_exo" }
                STALKER_Loadouts[i].armor = armorClasses[inv.armorLevel] or ""
            else
                STALKER_Loadouts[i].armor = ""
            end

            STALKER_SaveLoadouts()
            chat.AddText(Color(100, 200, 255), "[STALKER] Набор " .. i .. " сохранён!")
        end
    end

    -- ====================== НИЖНИЕ КНОПКИ ======================
    local btnY = fH - 48
    local btnW = 140

    local function BottomBtn(text, x, color, func)
        local b = vgui.Create("DButton", shopFrame)
        b:SetPos(x, btnY)
        b:SetSize(btnW, 36)
        b:SetText("")

        b.Paint = function(self, w, h)
            surface.SetDrawColor(self:IsHovered() and 55 or 25, 65, 30, self:IsHovered() and 240 or 200)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(110, 130, 70, 180)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(text, "STALKER_HUD_Small", w / 2, h / 2, color or Color(200, 210, 170), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = func
        return b
    end

    BottomBtn("Продать всё", 200, Color(190, 80, 80), function()
        -- Заменяем на продажу всех слотов, кроме ножа
        net.Start("STALKER_SellAllInventory")
        net.SendToServer()
        
        timer.Simple(0.2, function() PopulateItems(selectedCat) end)
    end)

    BottomBtn("Закрыть", fW - btnW - 30, Color(170, 170, 170), function()
        if IsValid(shopFrame) then shopFrame:Remove() end
    end)

    timer.Simple(0.05, function()
        if IsValid(catButtons["pistols"]) then
            catButtons["pistols"]:DoClick()
        end
    end)

    timer.Create("STALKER_ShopRefresh", 2, 0, function()
        if IsValid(shopFrame) and IsValid(itemPanel) then
            PopulateItems(selectedCat)
        else
            timer.Remove("STALKER_ShopRefresh")
        end
    end)
end

function STALKER_SaveLoadouts()
    local data = util.TableToJSON(STALKER_Loadouts)
    file.Write("stalker_loadouts.txt", data)
end

function STALKER_LoadLoadoutsFromFile()
    if file.Exists("stalker_loadouts.txt", "DATA") then
        local data = file.Read("stalker_loadouts.txt", "DATA")
        if data then
            local decoded = util.JSONToTable(data)
            if decoded then
                STALKER_Loadouts = decoded
            end
        end
    end
end

hook.Add("Initialize", "STALKER_LoadSavedLoadouts", function()
    timer.Simple(1, STALKER_LoadLoadoutsFromFile)
end)

hook.Add("ShutDown", "STALKER_SaveLoadoutsOnExit", STALKER_SaveLoadouts)