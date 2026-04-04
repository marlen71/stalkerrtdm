-- ============================================================================
-- S.T.A.L.K.E.R. TDM — Конфигурационный файл
-- Только две фракции: Наёмники vs Свобода
-- ============================================================================

STALKER_CONFIG = {}

-- ============================================================================
-- ОБЩИЕ НАСТРОЙКИ
-- ============================================================================
STALKER_CONFIG.MaxPlayers      = 128
STALKER_CONFIG.RoundTime       = 1800
STALKER_CONFIG.FragLimit       = 100
STALKER_CONFIG.RespawnDelay    = 4
STALKER_CONFIG.SpawnProtectionTime = 3
STALKER_CONFIG.FriendlyFire    = false
STALKER_CONFIG.TeamSwitchCooldown  = 5
STALKER_CONFIG.WarmupTime      = 15
STALKER_CONFIG.EndRoundTime    = 10
STALKER_CONFIG.ResetMoneyOnMapChange = true

-- ============================================================================
-- ЭКОНОМИКА (переработана под 5 рангов и новое оружие)
-- ============================================================================
STALKER_CONFIG.StartMoney = 2000
STALKER_CONFIG.MaxMoney   = 99999

STALKER_CONFIG.Rewards = {
    Kill      = 1000,
    Headshot  = 300,
    KnifeKill = 2000,
    Suicide   = -500,
    TeamKill  = -1000,
}

STALKER_CONFIG.KillstreakBonuses = {
    [3]  = 500,
    [5]  = 1000,
    [7]  = 1500,
    [10] = 2500,
}

-- ============================================================================
-- РАНГИ (5 уровней)
-- ============================================================================
STALKER_CONFIG.XPRewards = {
    Kill     = 80,
    Headshot = 40,
    TeamWin  = 250,
    TeamLose = 80,
}

-- name, xp — минимальный порог, moneyBonus — бонус к стартовым деньгам
STALKER_CONFIG.Ranks = {
    [1] = { name = "Новичок",       xp = 0,     moneyBonus = 0    },
    [2] = { name = "Опытный",       xp = 500,   moneyBonus = 300  },
    [3] = { name = "Профессионал",  xp = 1500,  moneyBonus = 700  },
    [4] = { name = "Ветеран",       xp = 3500,  moneyBonus = 1200 },
    [5] = { name = "Легенда",       xp = 7000,  moneyBonus = 2000 },
}

-- ============================================================================
-- ЗВУКИ ПРИ ПОВЫШЕНИИ РАНГА (по фракции и рангу)
-- Формат: [rankLevel][factionID] = путь к звуку
-- Все файлы лежат в sound/multiplayer/
-- ============================================================================
STALKER_CONFIG.RankUpSounds = {
    -- Опытный (ранг 2)
    [2] = {
        mercenaries = "multiplayer/теперьвыопытныйнаемник.ogg",
        freedom     = "multiplayer/теперьвыопытныйсвободовец.ogg",
    },
    -- Профессионал (ранг 3)
    [3] = {
        mercenaries = "multiplayer/теперьвыпрофессиональныйнаемник.ogg",
        freedom     = "multiplayer/теперьвыпрофессиональныйсвободовец.ogg",
    },
    -- Ветеран (ранг 4)
    [4] = {
        mercenaries = "multiplayer/теперьвынаемниквтеран.ogg",
        freedom     = "multiplayer/теперьвыветерансвободы.ogg",
    },
    -- Легенда (ранг 5)
    [5] = {
        mercenaries = "multiplayer/теперьвылегендарныйнаемник.ogg",
        freedom     = "multiplayer/теперьвылегендарныйсвободовец.ogg",
    },
}

-- ============================================================================
-- ЗВУКИ ИГРОВЫХ СОБЫТИЙ
-- ============================================================================
STALKER_CONFIG.Sounds = {
    -- Покупка
    Buy          = "items/ammo_pickup.wav",
    CantBuy      = "buttons/button10.wav",

    -- Убийства
    Headshot     = "multiplayer/вголову.ogg",
    KnifeKill    = "multiplayer/убийствосножа.ogg",
    Kill         = "buttons/button15.wav",

    -- Серии убийств
    Killstreak   = "multiplayer/серияубийств.ogg",

    -- Счёт
    ScoreEqual   = "multiplayer/счетравный.ogg",    -- Счёт сравнялся
    MercLead     = "multiplayer/наемникилидируют.ogg",
    FreedomLead  = "multiplayer/свободалидирует.ogg",

    -- Победа
    MercWin      = "multiplayer/наемникивыгралиматч.ogg",
    FreedomWin   = "multiplayer/свободавыгралиматч.ogg",
    Draw         = "multiplayer/счетравный.ogg",

    -- Раунд
    RoundStart   = "multiplayer/матчначался.ogg",
    RoundEnd     = "multiplayer/dm_won.ogg",
    Ready        = "multiplayer/ready.ogg",

    -- Таймер смены карты (отсчёт 5..1)
    Count5       = "multiplayer/пять.ogg",
    Count4       = "multiplayer/четыре.ogg",
    Count3       = "multiplayer/три.ogg",
    Count2       = "multiplayer/два.ogg",
    Count1       = "multiplayer/один.ogg",

    -- Голосование
    VoteStart    = "buttons/button9.wav",
}

-- ============================================================================
-- МОДЕЛИ ФРАКЦИЙ
-- ============================================================================
STALKER_CONFIG.FactionMatchups = {
    [1] = {
        name  = "Наёмники vs Свобода",
        team1 = {
            name   = "Наёмники",
            id     = "mercenaries",
            color  = Color(80, 120, 255),
            -- Базовые модели (выбираются в меню при входе)
            models = {
                "models/flaymi/anomaly/stalker_merc_mp/stalker_ki_mask.mdl",
                "models/flaymi/anomaly/stalker_merc_mp/stalker_merc_2.mdl",
            },
        },
        team2 = {
            name   = "Свобода",
            id     = "freedom",
            color  = Color(50, 200, 50),
            -- Базовые модели (выбираются в меню при входе)
            models = {
                "models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_old.mdl",
                "models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_mas4.mdl",
            },
        },
    },
}

-- ============================================================================
-- МОДЕЛИ БРОНИ (меняют модель игрока при покупке)
-- ============================================================================
STALKER_CONFIG.ArmorModels = {
    ["armor_light"] = {
        mercenaries = {
            "models/flaymi/anomaly/stalker_merc_mp/stalker_ki_mask.mdl",
            "models/flaymi/anomaly/stalker_merc_mp/stalker_merc_2.mdl",
        },
        freedom = {
            "models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_old.mdl",
            "models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_2_mas4.mdl",
        },
    },
    ["armor_medium"] = { -- Сева
        mercenaries = {
            "models/flaymi/anomaly/stalker_merc_mp/stalker_mercenary3.mdl",
        },
        freedom = {
            "models/flaymi/anomaly/stalker_freedom_mp/stalker_free_0.mdl",
        },
    },
    ["armor_heavy"] = { -- Скат
        mercenaries = {
            "models/flaymi/anomaly/stalker_merc_mp/stalker_merc_4_skat.mdl",
        },
        freedom = {
            "models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_military.mdl",
        },
    },
    ["armor_exo"] = { -- Экзоскелет
        mercenaries = {
            "models/flaymi/anomaly/stalker_merc_mp/stalker_merc_exo_proto.mdl",
        },
        freedom = {
            "models/flaymi/anomaly/stalker_freedom_mp/stalker_freedom_4_proto.mdl",
        },
    },
}

-- ============================================================================
-- КАТЕГОРИИ МАГАЗИНА
-- ============================================================================
STALKER_CONFIG.ShopCategories = {
    "pistols",
    "smg",
    "shotguns",
    "rifles",
    "snipers",
    "melee",
    "armor",
    "ammo",
}

STALKER_CONFIG.ShopCategoryNames = {
    pistols  = "Пистолеты",
    smg      = "ПП",
    shotguns = "Дробовики",
    rifles   = "Автоматы",
    snipers  = "Снайперки",
    melee    = "Ближний бой",
    armor    = "Броня",
    ammo     = "Патроны",
}

-- ============================================================================
-- ПРЕДМЕТЫ МАГАЗИНА (переработаны под 5 рангов)
-- minRank: 1=Новичок 2=Опытный 3=Профессионал 4=Ветеран 5=Легенда
-- Цены: ~1-2 убийства = SMG, ~2-3 = автомат, ~4-5 = снайперка
-- ============================================================================
STALKER_CONFIG.ShopItems = {

    -- ============================
    -- ПИСТОЛЕТЫ
    -- ============================
    {
        class    = "tfa_st_pm",
        name     = "ПМ",
        price    = 300,
        minRank  = 1,
        category = "pistols",
        caliber  = "9x18",
        icon     = "stalker_tdm/icons/pm.png",
    },
    {
        class    = "tfa_st_pb",
        name     = "ПБ (глушитель)",
        price    = 500,
        minRank  = 1,
        category = "pistols",
        caliber  = "9x18",
        icon     = "stalker_tdm/icons/pb.png",
    },
    {
        class    = "tfa_st_walter",
        name     = "Вальтер",
        price    = 600,
        minRank  = 2,
        category = "pistols",
        caliber  = "9x18",
        icon     = "stalker_tdm/icons/walker.png",
    },
    {
        class    = "tfa_st_usp45",
        name     = "УДП Компакт",
        price    = 700,
        minRank  = 2,
        category = "pistols",
        caliber  = ".45",
        icon     = "stalker_tdm/icons/usp.png",
    },
    {
        class    = "tfa_st_sig220",
        name     = "СИП-т М200",
        price    = 750,
        minRank  = 3,
        category = "pistols",
        caliber  = ".45",
        icon     = "stalker_tdm/icons/sig.png",
    },
    {
        class    = "tfa_st_desert",
        name     = "Дигл",
        price    = 900,
        minRank  = 3,
        category = "pistols",
        caliber  = ".50",
        icon     = "stalker_tdm/icons/deagle.png",
    },

    -- ============================
    -- ПИСТОЛЕТЫ-ПУЛЕМЁТЫ
    -- ============================
    {
        class    = "tfa_st_mp5",
        name     = "MP5",
        price    = 1800,
        minRank  = 2,
        category = "smg",
        caliber  = "9x19",
        icon     = "stalker_tdm/icons/mp5.png",
    },

    -- ============================
    -- ДРОБОВИКИ
    -- ============================
    {
        class    = "tfa_st_bm16",
        name     = "Обрез",
        price    = 500,
        minRank  = 1,
        category = "shotguns",
        caliber  = "12ga",
        icon     = "stalker_tdm/icons/obrez.png",
    },
    {
        class    = "tfa_st_bm16a",
        name     = "БМ-16",
        price    = 900,
        minRank  = 2,
        category = "shotguns",
        caliber  = "12ga",
        icon     = "stalker_tdm/icons/bm16.png",
    },
    {
        class    = "tfa_st_toz34",
        name     = "ТОЗ-34",
        price    = 1400,
        minRank  = 2,
        category = "shotguns",
        caliber  = "12ga",
        icon     = "stalker_tdm/icons/toz.png",
    },
    {
        class    = "tfa_st_winchester1300",
        name     = "Чайзер",
        price    = 2200,
        minRank  = 3,
        category = "shotguns",
        caliber  = "12ga",
        icon     = "stalker_tdm/icons/chaser.png",
    },
    {
        class    = "tfa_st_spas12",
        name     = "SPAS-14",
        price    = 3000,
        minRank  = 4,
        category = "shotguns",
        caliber  = "12ga",
        icon     = "stalker_tdm/icons/spas.png",
    },
    {
        class    = "tfa_st_protecta",
        name     = "Отбойник",
        price    = 4500,
        minRank  = 5,
        category = "shotguns",
        caliber  = "12ga",
        icon     = "stalker_tdm/icons/protecta.png",
    },

    -- ============================
    -- АВТОМАТЫ
    -- ============================
    {
        class    = "tfa_st_ak74u",
        name     = "АК-74у",
        price    = 2200,
        minRank  = 2,
        category = "rifles",
        caliber  = "5.45x39",
        icon     = "stalker_tdm/icons/ak74u.png",
    },
    {
        class    = "tfa_st_ak74",
        name     = "АК-74",
        price    = 2800,
        minRank  = 3,
        category = "rifles",
        caliber  = "5.45x39",
        icon     = "stalker_tdm/icons/ak74.png",
    },
    {
        class    = "tfa_st_lr300",
        name     = "LR-300",
        price    = 3200,
        minRank  = 3,
        category = "rifles",
        caliber  = "5.56x45",
        icon     = "stalker_tdm/icons/lr300.png",
    },
    {
        class    = "tfa_st_an94",
        name     = "АН-94 Абакан",
        price    = 3800,
        minRank  = 4,
        category = "rifles",
        caliber  = "5.45x39",
        icon     = "stalker_tdm/icons/an94.png",
    },
    {
        class    = "tfa_st_val",
        name     = "АС-ВАЛ",
        price    = 4500,
        minRank  = 4,
        category = "rifles",
        caliber  = "9x39",
        icon     = "stalker_tdm/icons/val.png",
    },

    -- ============================
    -- СНАЙПЕРКИ
    -- ============================
    {
        class    = "tfa_st_svu",
        name     = "СВУ",
        price    = 5500,
        minRank  = 3,
        category = "snipers",
        caliber  = "7.62x54",
        icon     = "stalker_tdm/icons/svu.png",
    },
    {
        class    = "tfa_st_svd",
        name     = "СВД",
        price    = 7500,
        minRank  = 4,
        category = "snipers",
        caliber  = "7.62x54",
        icon     = "stalker_tdm/icons/svd.png",
    },
    {
        class    = "tfa_st_vintorez",
        name     = "Винтарь",
        price    = 9000,
        minRank  = 4,
        category = "snipers",
        caliber  = "9x39",
        icon     = "stalker_tdm/icons/vintorez.png",
    },
    {
        class    = "tfa_st_gauss",
        name     = "Гаусс",
        price    = 14000,
        minRank  = 5,
        category = "snipers",
        caliber  = "gauss",
        icon     = "stalker_tdm/icons/gauss.png",
    },

    -- ============================
    -- БЛИЖНИЙ БОЙ
    -- ============================
    {
        class    = "tfa_st_knife",
        name     = "Нож",
        price    = 0,
        minRank  = 1,
        category = "melee",
        caliber  = "none",
        icon     = "stalker_tdm/icons/knife.png",
    },
    {
        class    = "tfa_st_f1",
        name     = "Граната Ф-1",
        price    = 1200,
        minRank  = 2,
        category = "melee",
        caliber  = "none",
        icon     = "stalker_tdm/icons/f1.png",
    },
    {
        class    = "tfa_st_rgd5",
        name     = "Граната РГД-5",
        price    = 1200,
        minRank  = 2,
        category = "melee",
        caliber  = "none",
        icon     = "stalker_tdm/icons/rgd.png",
    },
    {
        class    = "tfa_st_rpg",
        name     = "РПГ-7",
        price    = 35000,
        minRank  = 5,
        category = "melee",
        caliber  = "none",
        icon     = "stalker_tdm/icons/rpg.png",
    },

    -- ============================
    -- БРОНЯ (меняет модель!)
    -- ============================
    {
        class    = "armor_light",
        name     = "Лёгкий бронежилет",
        price    = 250,
        minRank  = 1,
        category = "armor",
        armorVal = 75,
        isArmor  = true,
        icon     = "stalker_tdm/icons/armor_light.png",
    },
    {
        class    = "armor_medium",
        name     = "Сева",
        price    = 1500,
        minRank  = 3,
        category = "armor",
        armorVal = 125,
        isArmor  = true,
        icon     = "stalker_tdm/icons/armor_seva.png",
    },
    {
        class    = "armor_heavy",
        name     = "Скат",
        price    = 3500,
        minRank  = 4,
        category = "armor",
        armorVal = 175,
        isArmor  = true,
        icon     = "stalker_tdm/icons/armor_skat.png",
    },
    {
        class    = "armor_exo",
        name     = "Экзоскелет",
        price    = 6000,
        minRank  = 5,
        category = "armor",
        armorVal = 250,
        isArmor  = true,
        icon     = "stalker_tdm/icons/armor_exo.png",
    },

    -- ============================
    -- ПАТРОНЫ
    -- ============================
    {
        class     = "ammo_9x18",
        name      = "9×18 мм (30 шт.)",
        price     = 150,
        minRank   = 1,
        category  = "ammo",
        ammoType  = "st_ammo_9x18_fmj",
        ammoCount = 30,
    },
    {
        class     = "ammo_9x19",
        name      = "9×19 мм (30 шт.)",
        price     = 200,
        minRank   = 1,
        category  = "ammo",
        ammoType  = "st_ammo_9x19_fmj",
        ammoCount = 30,
    },
    {
        class     = "ammo_45acp",
        name      = ".45 ACP (30 шт.)",
        price     = 200,
        minRank   = 1,
        category  = "ammo",
        ammoType  = "st_ammo_1143x23_fmj",
        ammoCount = 30,
    },
    {
        class     = "ammo_12ga",
        name      = "12 кал. (8 шт.)",
        price     = 250,
        minRank   = 1,
        category  = "ammo",
        ammoType  = "st_ammo_12x76_bull",
        ammoCount = 8,
    },
    {
        class     = "ammo_545",
        name      = "5.45×39 мм (30 шт.)",
        price     = 350,
        minRank   = 2,
        category  = "ammo",
        ammoType  = "st_ammo_545x39_fmj",
        ammoCount = 30,
    },
    {
        class     = "ammo_556",
        name      = "5.56×45 мм (30 шт.)",
        price     = 350,
        minRank   = 3,
        category  = "ammo",
        ammoType  = "st_ammo_556x45_fmj",
        ammoCount = 30,
    },
    {
        class     = "ammo_939",
        name      = "9×39 мм (30 шт.)",
        price     = 400,
        minRank   = 4,
        category  = "ammo",
        ammoType  = "st_ammo_9x39_pab9",
        ammoCount = 30,
    },
    {
        class     = "ammo_762",
        name      = "7.62×54 мм (10 шт.)",
        price     = 450,
        minRank   = 3,
        category  = "ammo",
        ammoType  = "st_ammo_pkm_100",
        ammoCount = 10,
    },
    {
        class     = "ammo_gauss",
        name      = "Гаусс-заряд (5 шт.)",
        price     = 600,
        minRank   = 5,
        category  = "ammo",
        ammoType  = "st_ammo_gauss",
        ammoCount = 5,
    },
}

-- ============================================================================
-- СТАРТОВОЕ СНАРЯЖЕНИЕ
-- ============================================================================
STALKER_CONFIG.DefaultLoadout = {
    weapons = { "tfa_st_pm", "tfa_st_knife", "tfa_st_bolt2" },
    ammo    = {
        { type = "st_ammo_9x18_fmj", count = 64 },
    },
    armor   = 0,
}

-- ============================================================================
-- СПАВНЫ
-- ============================================================================
STALKER_CONFIG.Spawns = {
    ["rp_wildterritory"] = {
        team1 = {
            { pos = Vector(1014.1, -4523.7, 98), ang = Angle(0, 0, 0) },
            { pos = Vector(883.7,  -4526.2, 98), ang = Angle(0, 0, 0) },
            { pos = Vector(999,    -4693.3, 57), ang = Angle(0, 0, 0) },
            { pos = Vector(845.4,  -4687,   56), ang = Angle(0, 0, 0) },
        },
        team2 = {
            { pos = Vector(260.3, -7513,   56), ang = Angle(0, 180, 0) },
            { pos = Vector(76.4,  -7508.5, 56), ang = Angle(0, 180, 0) },
            { pos = Vector(271.9, -7695.9, 56), ang = Angle(0, 180, 0) },
            { pos = Vector(76.1,  -7644.6, 56), ang = Angle(0, 180, 0) },
        },
        team1BuyZoneCenter = Vector(785,   -4606.5, 56),
        team2BuyZoneCenter = Vector(183.9, -7905.7, 56),
        buyZoneRadius      = 500,
    },
    ["aim_zavod_yantar_v2"] = {
        team1 = {
            { pos = Vector(-2598.1, 153,    684), ang = Angle(0, 0, 0) },
            { pos = Vector(-2716.8, -222,   684), ang = Angle(0, 0, 0) },
            { pos = Vector(-2541.1, -56,    684), ang = Angle(0, 0, 0) },
            { pos = Vector(-2459.8, -284.7, 684), ang = Angle(0, 0, 0) },
        },
        team2 = {
            { pos = Vector(1883.6, -845.6, 688.5), ang = Angle(0, 180, 0) },
            { pos = Vector(1853.6, -570.4, 693),   ang = Angle(0, 180, 0) },
            { pos = Vector(1598.9, -562.6, 683.8), ang = Angle(0, 180, 0) },
            { pos = Vector(1590.7, -878.7, 680.2), ang = Angle(0, 180, 0) },
        },
        team1BuyZoneCenter = Vector(-2617,  -136.8, 684),
        team2BuyZoneCenter = Vector(1630.1, -665.5, 685.2),
        buyZoneRadius      = 500,
    },
    ["aim_z_pool_stalker"] = {
        team1 = {
            { pos = Vector(-18.6, 534.8, -488), ang = Angle(0, 0, 0) },
            { pos = Vector(-22.2, 635.5, -488), ang = Angle(0, 0, 0) },
            { pos = Vector(-19.7, 741.8, -488), ang = Angle(0, 0, 0) },
            { pos = Vector(-25.4, 845,   -488), ang = Angle(0, 0, 0) },
        },
        team2 = {
            { pos = Vector(1333.7, 714.9, -488), ang = Angle(0, 180, 0) },
            { pos = Vector(1332.7, 618.7, -488), ang = Angle(0, 180, 0) },
            { pos = Vector(1315.3, 808.1, -488), ang = Angle(0, 180, 0) },
            { pos = Vector(1353.6, 528.8, -488), ang = Angle(0, 180, 0) },
        },
        team1BuyZoneCenter = Vector(21.7,   675.9, -488),
        team2BuyZoneCenter = Vector(1326.5, 663.1, -488),
        buyZoneRadius      = 500,
    },
}

-- ============================================================================
-- ГОЛОСОВАНИЕ
-- ============================================================================
STALKER_CONFIG.VoteTime    = 25
STALKER_CONFIG.MapVoteTime = 25

STALKER_CONFIG.MapList = {
    "rp_wildterritory",
    "aim_zavod_yantar_v2",
    "aim_z_pool_stalker",
}

-- ============================================================================
-- ВИЗУАЛЬНЫЕ НАСТРОЙКИ
-- ============================================================================
STALKER_CONFIG.DefaultVisuals = {
    NoiseEnabled    = true,
    NoiseAlpha      = 12,
    ColorModEnabled = true,
    ColorModAdd     = Color(3, 8, 0),
    ColorModMul     = Color(238, 232, 198),
    HUDAlpha        = 220,
}