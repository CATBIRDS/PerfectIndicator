local mod = get_mod("PerfectIndicator")
local widgets = {
    {
        setting_id  = "mod_group",
        type        = "group",
        sub_widgets = {
            {
                setting_id    = "ENABLED",
                type          = "checkbox",
                default_value = true,
            },
            {
                setting_id    = "MELEE",
                type          = "checkbox",
                default_value = true,
            },
            {
                setting_id    = "RANGED",
                type          = "checkbox",
                default_value = true,
            },
        },
    },
    {
        setting_id  = "notifications_group",
        type        = "group",
        sub_widgets = {
            {
                setting_id    = "HITMARKER",
                type          = "checkbox",
                default_value = false,
            },
            {
                setting_id    = "PARTICLE",
                type          = "checkbox",
                default_value = false,
            },
            {
                setting_id    = "AUDIO",
                type          = "dropdown",
                default_value = "none",
                options = {
                    { text = "none", value = "none" },
                    { text = "plasteel", value = "wwise/events/player/play_pick_up_forge_material_large" },
                    { text = "diamantine", value = "wwise/events/player/play_pick_up_forge_material_platinum_large" },
                    { text = "grenade", value = "wwise/events/player/play_pick_up_grenade" },
                    { text = "ammo", value = "wwise/events/player/play_pick_up_ammo_01" },
                    { text = "weakspot", value = "wwise/events/weapon/play_indicator_weakspot" },
                    { text = "crit", value = "wwise/events/weapon/play_indicator_crit_melee_hit" },
                    { text = "servo_skull", value = "wwise/events/player/play_device_auspex_bio_minigame_progress" }
                }
            },
            {
                setting_id    = "STAMINA",
                type          = "checkbox",
                default_value = false,
            },
            {
                setting_id    = "PERSISTENT_STAMINA",
                type          = "checkbox",
                default_value = false,
            },
        }
    }
}

return {
    name         = mod:localize("mod_name"),
    description  = mod:localize("mod_description"),
    is_togglable = true,
    allow_rehooking = true,
    options = {
        widgets = widgets
    }
}
