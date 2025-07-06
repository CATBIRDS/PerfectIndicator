-- Chinese localization provided by jcyl2023
local localization = {
    -- Mod Info
    mod_name = {
        en = "Perfect Indicator",
        ["zh-cn"] = "完美格挡指示器",
        ["zh-tw"] = "完美格擋指示器",
    },
    mod_description = {
        en = "Displays indicators upon successful perfect blocks",
        ["zh-cn"] = "显示成功完美格挡准心指示，可以根据攻击类型启用，以及自定义完美格挡的粒子脉冲效果",
        ["zh-tw"] = "成功完美格擋顯示指示器",
    },
    -- Settings
    mod_group = {
        en        = "Mod Settings",
        ["zh-cn"] = "MOD设置",
        ["zh-tw"] = "MOD設置",
    },
    ENABLED = {
        en        = "Enable/Disable Mod",
        ["zh-tw"] = "模組啟停",
        ["zh-cn"] = "模组启停",
    },
    PARTICLE = {
        en = "Show Particles",
        ["zh-cn"] = "显示脉冲粒子",
        ["zh-tw"] = "顯示粒子",
    },
    PERSISTENT_STAMINA = {
        en = "Always Show Stamina Bar",
    },
}

--------------------------------------------------------------------------
-- PLEASE DO NOT EDIT BEYOND THIS POINT IF YOU ARE ADDING LOCALIZATIONS --
--------------------------------------------------------------------------

localization.MELEE               = { en = Localize("loc_setting_melee") }                             -- "Melee"
localization.RANGED              = { en = Localize("loc_setting_ranged") }                            -- "Ranged"
localization.notifications_group = { en = Localize("loc_setting_menu_group_notification_settings") }  -- "Notifications"
localization.HITMARKER           = { en = Localize("loc_setting_hit_indicator_enabled") }             -- "Show Hit Indicators"
localization.STAMINA             = { en = Localize("loc_hud_display_name_stamina") }                  -- "Stamina"
localization.AUDIO               = { en = Localize("loc_settings_menu_category_sound")}               -- "Audio"
localization.none                = { en = Localize("loc_setting_com_wheel_tap_none") }                -- "None"
localization.plasteel            = { en = Localize("loc_currency_name_plasteel") }                    -- "Plasteel"
localization.diamantine          = { en = Localize("loc_currency_name_diamantine") }                  -- "Diamantine"
localization.grenade = { en = (Localize("loc_adamant_female_c__look_at_grenade_01"):gsub("%p", "")) } -- "Grenade"
localization.ammo                = { en = Localize("loc_glossary_term_ammunition") }                  -- "Ammo"
localization.weakspot            = { en = Localize("loc_weapon_details_weakspot") }                   -- "Weakspot"
localization.crit                = { en = Localize("loc_weapon_details_crit") }                       -- "Critical"
localization.servo_skull         = { en = Localize("loc_interactable_servo_skull_scanner") }          -- "Servo-Skull"

return localization
