local mod = get_mod("PerfectIndicator")
-- PlayerUnitWeaponExtension Dependencies
local AttackSettings = require("scripts/settings/damage/attack_settings")
-- Particles Dependencies
local VisualLoadoutCustomization = require("scripts/extension_systems/visual_loadout/utilities/visual_loadout_customization")
-- HudElementBlocking Dependencies
local UIWidget = require("scripts/managers/ui/ui_widget")
local HudElementBlockingSettings = require("scripts/ui/hud/elements/blocking/hud_element_blocking_settings")

local MOD = {
    ENABLED = true,             -- Enable or disable the mod
    RANGED = false,             -- Show perfect block hitmarker when perfect blocking ranged attacks
    MELEE = false,              -- Show perfect block hitmarker when perfect blocking melee attacks
    DURATION = 0.5,             -- Duration of perfect block hitmarker visibiilty in seconds (set to match game settings upon load)
    PARTICLE = false,           -- Spawn particles on perfect block
    HITMARKER = false,          -- Show hitmarker on perfect block
    STAMINA = false,            -- Change stamina bar color to green during perfect block window
    PERSISTENT_STAMINA = false, -- Always show stamina bar
    AUDIO = "none",             -- Audio to play upon successfully blocking an attack with perfect block
}

PLAYER = {
    WORLD = nil,                -- World reference for audio playback
    PLAYING = nil,              -- Currently playing sound effect, or nil
    PERFECT = false,            -- Player's current perfect block state
    RANGED = false,             -- Whether the last perfect block was against a ranged attack
}

OG = {                          -- Original Stamina Widget Colors
    empty = { 100,  63,  56,  43 },
    half  = { 155, 113, 126, 103 },
    full  = { 255, 216, 229, 207 }
}

GREEN = {                       --  Perfect Block Stamina Widget Colors
    empty = { 100,  30,  90,  20 },
    half  = { 155,  60, 180,  50 },
    full  = { 255, 100, 255, 100 }
}

mod.on_enabled = function()
    MOD.ENABLED = true
end

mod.on_disabled = function()
    MOD.ENABLED = false
end

mod.on_game_state_changed = function(state, state_name)
    -- Reset world on state change
    PLAYER.WORLD = nil
end

mod.on_unload = function()
end

mod.on_all_mods_loaded = function()
    MOD.ENABLED = mod:get("ENABLED")
    for setting_id, _ in pairs(MOD) do
        if mod:get(setting_id) ~= nil then
            MOD[setting_id] = mod:get(setting_id)
        end
    end
    -- Set hit indicator duration to match user's game settings
    local save_manager = Managers.save
    if save_manager then
        local account_data = save_manager:account_data()
        MOD.DURATION = account_data and account_data.interface_settings.hit_indicator_duration or MOD.DURATION
    end
end

mod.on_setting_changed = function(setting_id)
    if MOD[setting_id] ~= nil then
        MOD[setting_id] = mod:get(setting_id)
    end
end

mod.update = function()
    if MOD.ENABLED then
        -- Set world reference if available and not already set
        if not PLAYER.WORLD then
            local world_manager = Managers.world
            local world = world_manager and world_manager:world("level_world")
            local wwise_world = world and world_manager:wwise_world(world)
            if wwise_world then
                PLAYER.WORLD = wwise_world
            end
        end
        -- Clear audio container if no longer playing
        if PLAYER.PLAYING and PLAYER.WORLD then
            if not WwiseWorld.is_playing(PLAYER.WORLD, PLAYER.PLAYING) then
                PLAYER.PLAYING = nil
            end
        end
        -- Handle successful perfect blocks
        if PLAYER.PERFECT then
            -- Play audio dependent on mod settings
            if MOD.AUDIO and MOD.AUDIO ~= "none" and PLAYER.WORLD then
                -- Play only if not already playing
                if not PLAYER.PLAYING then
                    PLAYER.PLAYING = mod.play_audio(PLAYER.WORLD)
                end
            end
            -- Hitmarker visibility decay - perfect block forcibly resets hit indicator to max opacity, decaying to 0 over MOD.DURATION
            local elapsed = Managers.time:time("main") - (PLAYER.TIME or 0)
            PLAYER.PROGRESS = math.max(0, 1 - (elapsed / MOD.DURATION))
            if PLAYER.PROGRESS == 0 then
                PLAYER.PERFECT = false
            end
        end
    end
end

--  ╔═╗╔═╗╦═╗╔╦╗╦╔═╗╦  ╔═╗╔═╗
--  ╠═╝╠═╣╠╦╝ ║ ║║  ║  ║╣ ╚═╗
--  ╩  ╩ ╩╩╚═ ╩ ╩╚═╝╩═╝╚═╝╚═╝

-- Custom spawner to bypass server forcing particles to not be spawned sometimes
mod.create_particles = function(fx_extension, particle_name, particle_source, link, orphaned_policy)
    if not fx_extension or not particle_name then return end
    local world = fx_extension._world
    local pose = Matrix4x4.identity()
    local spawner = fx_extension._vfx_spawners and fx_extension._vfx_spawners[particle_source]
    local particle_group = fx_extension._player_particle_group_id
    if world and spawner and particle_group then
        spawner = spawner[VisualLoadoutCustomization.ROOT_ATTACH_NAME]
        local unit = fx_extension._unit
        local is_first_person = fx_extension._is_in_first_person_mode
        local node_unit, node
        if is_first_person or not spawner.node_3p then
            node_unit = spawner.unit
            node = spawner.node
        else
            node = spawner.node_3p
            node_unit = unit
        end
        -- Create particles
        local particle_id = World.create_particles(world, particle_name, Vector3.zero(), nil, nil, particle_group)
        -- Link to spawner node
        if link then
            World.link_particles(world, particle_id, node_unit, node, pose, orphaned_policy)
        end
        if is_first_person then
		    World.set_particles_use_custom_fov(world, particle_id, true)
	    end
    end
end

--  ╦ ╦╦╔╦╗╔╦╗╔═╗╦═╗╦╔═╔═╗╦═╗
--  ╠═╣║ ║ ║║║╠═╣╠╦╝╠╩╗║╣ ╠╦╝
--  ╩ ╩╩ ╩ ╩ ╩╩ ╩╩╚═╩ ╩╚═╝╩╚═

-- Hitmarker Modification - overrides hit indicator to be green and refreshes indicator opacity on perfect block
mod:hook_require("scripts/ui/utilities/crosshair", function(instance)
    mod:hook(instance, "update_hit_indicator", function(func, style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
        if not MOD.ENABLED then return func(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator) end
        if PLAYER.PERFECT and MOD.HITMARKER then
            hit_progress = PLAYER.PROGRESS
            draw_hit_indicator = true
            hit_color = {255, 0, 255, 0}
        end
        return func(style, hit_progress, hit_color, hit_weakspot, draw_hit_indicator)
    end)
end)

--  ╔═╗╔╦╗╔═╗╔╦╗╦╔╗╔╔═╗
--  ╚═╗ ║ ╠═╣║║║║║║║╠═╣
--  ╚═╝ ╩ ╩ ╩╩ ╩╩╝╚╝╩ ╩

-- Stamina Bar Modification - changes widget to be green when perfect blocking. Unfortunately long hook as coloring takes place at the end but hook_safe is insufficient
mod:hook(CLASS.HudElementBlocking, "_draw_shields", function(func, self, dt, t, ui_renderer)
    if not MOD.ENABLED then return func(self, dt, t, ui_renderer) end
    if MOD.STAMINA then
        local num_shields = self._shield_amount
        if num_shields < 1 then
            return
        end
        local widget = self._shield_widget
        local widget_offset = widget.offset
        local shield_width = self._shield_width
        local stamina_fraction = 1
        local parent = self._parent
        local player_extensions = parent:player_extensions()
        local is_perfect_blocking
        if player_extensions then
            local player_unit_data = player_extensions.unit_data
            if player_unit_data then
                local stamina_component = player_unit_data:read_component("stamina")
                local block_component = player_unit_data:read_component("block")
                is_perfect_blocking = block_component and block_component.is_blocking and block_component.is_perfect_blocking
                if stamina_component and stamina_component.current_fraction then
                    stamina_fraction = stamina_component.current_fraction
                end
            end
        end
        local gauge_widget = self._widgets_by_name.gauge
        local fake_percent = math.clamp(stamina_fraction, 0, 1) * 100 -- For some reason calculated properly but not used for proper display in base game
        gauge_widget.content.value_text = string.format("%.0f%%", fake_percent)
        local step_fraction = 1 / num_shields
        if self._start_on_half_bar then
            stamina_fraction = stamina_fraction - step_fraction * 0.51
        end
        local spacing = HudElementBlockingSettings.spacing
        local x_offset = (shield_width + spacing) * (num_shields - 1) * 0.5
        local shields = self._shields
        for i = num_shields, 1, -1 do
            local shield = shields[i]
            if not shield then
                return
            end
            local end_value = i * step_fraction
            local start_value = end_value - step_fraction
            local is_full, is_half, is_empty
            if fake_percent == 100 then -- Fixes base-game bug where final shield is never colored "full" even at max stamina
                is_full = true
            elseif stamina_fraction >= start_value + step_fraction * 0.5 then
                is_full = true
            elseif start_value < stamina_fraction then
                is_half = true
            else
                is_empty = true
            end
            local active_color
            -- Color in accordance to perfect blocking state and shield fullness
            if is_empty then
                active_color = is_perfect_blocking and GREEN.empty or OG.empty
            elseif is_full then
                active_color = is_perfect_blocking and GREEN.full or OG.full
            elseif is_half then
                active_color = is_perfect_blocking and GREEN.half or OG.half
            end
            local widget_style = widget.style
            local widget_color = widget_style.full.color
            widget_color[1] = active_color[1]
            widget_color[2] = active_color[2]
            widget_color[3] = active_color[3]
            widget_color[4] = active_color[4]
            widget_offset[1] = x_offset
            UIWidget.draw(widget, ui_renderer)
            x_offset = x_offset - shield_width - spacing
        end
    else
        return func(self, dt, t, ui_renderer)
    end
end)

-- Override visibility function while PERSISTENT_STAMINA is enabled
mod:hook(CLASS.HudElementBlocking, "_update_visibility", function(func, self, dt, t)
    if not MOD.ENABLED then return func(self, dt, t, input_service, ui_renderer, render_settings) end
    if MOD.PERSISTENT_STAMINA then
        self._alpha_multiplier = 1
    else
        return func(self, dt, t)
    end
end)

--  ╔═╗╔═╗╦ ╦╔╗╔╔╦╗
--  ╚═╗║ ║║ ║║║║ ║║
--  ╚═╝╚═╝╚═╝╝╚╝═╩╝

-- Plays audio and returns its id
mod.play_audio = function(wwise_world)
    if not wwise_world or not MOD.AUDIO or MOD.AUDIO == "none" then return end
    return WwiseWorld.trigger_resource_event(wwise_world, MOD.AUDIO)
end

--  ╔╗ ╦  ╔═╗╔═╗╦╔═  ╔╦╗╔═╗╔╦╗╔═╗╔═╗╔╦╗╦╔═╗╔╗╔
--  ╠╩╗║  ║ ║║  ╠╩╗   ║║║╣  ║ ║╣ ║   ║ ║║ ║║║║
--  ╚═╝╩═╝╚═╝╚═╝╩ ╩  ═╩╝╚═╝ ╩ ╚═╝╚═╝ ╩ ╩╚═╝╝╚╝

-- Detect perfect blocks as session client (normal online play)
mod:hook(CLASS.WeaponSystem, "rpc_player_blocked_attack", function(func, self, channel_id, unit_id, attacking_unit_id, hit_world_position, block_broken, weapon_template_id, attack_type_id)
    if not MOD.ENABLED then return func(self, channel_id, unit_id, attacking_unit_id, hit_world_position, block_broken, weapon_template_id, attack_type_id) end
    local blocking_unit = Managers.state.unit_spawner:unit(unit_id)
    local player_manager = Managers.player
    local player = player_manager and player_manager:local_player_safe(1)
    local player_unit = player and player.player_unit
    -- If this RPC is for the local player
    if player_unit and blocking_unit == player_unit then
        local data_extension = player_unit and ScriptUnit.has_extension(player_unit, "unit_data_system")
        local block_component = data_extension and data_extension:read_component("block")
        local weapon_extension = ScriptUnit.has_extension(player_unit, "weapon_system")
        -- And the player was not block broken while perfect blocking
        if weapon_extension and block_component and block_component.is_perfect_blocking and not block_broken then
            local attack_type = NetworkLookup.attack_types[attack_type_id]
            PLAYER.RANGED = attack_type == AttackSettings.attack_types.ranged
            local valid_ranged = PLAYER.RANGED and MOD.RANGED or not PLAYER.RANGED and MOD.MELEE
            -- And mod settings allow showing an indicator for blocking this kind of attack
            if valid_ranged then
                PLAYER.PERFECT = true
                -- Set timestamp for hitmarker display
                PLAYER.TIME = Managers.time:time("main")
                -- Collect block source for particle spawning
                local weapon = weapon_extension:_wielded_weapon(weapon_extension._inventory_component, weapon_extension._weapons)
                local fx_sources = weapon.fx_sources
                local block_source = fx_sources._block
                -- Find any valid fx source if the weapon does not have a dedicated block source
                if fx_sources and not block_source then
                    for _, source in pairs(fx_sources) do
                        if source then
                            block_source = source
                            break
                        end
                    end
                end
                -- Spawn particles if particle setting is enabled
                if block_source and MOD.PARTICLE then
                    local particle_name = "content/fx/particles/interacts/grimoire_discard"
                    local fx_extension = weapon._fx_extension
                    if block_source and fx_extension then
                        mod.create_particles(fx_extension, particle_name, block_source, true, "stop")
                    end
                end
            end
        end
    end
    return func(self, channel_id, unit_id, attacking_unit_id, hit_world_position, block_broken, weapon_template_id, attack_type_id)
end)

-- Detect perfect blocks as session host (Psykhanium, Solo mode, etc.)
mod:hook(CLASS.PlayerUnitWeaponExtension, "blocked_attack", function(func, self, attacking_unit, hit_world_position, block_broken, weapon_template, attack_type, block_cost, is_perfect_block)
    if not MOD.ENABLED then return func(self, attacking_unit, hit_world_position, block_broken, weapon_template, attack_type, block_cost, is_perfect_block) end
    PLAYER.RANGED = attack_type == AttackSettings.attack_types.ranged
    local valid_ranged = PLAYER.RANGED and MOD.RANGED or not PLAYER.RANGED and MOD.MELEE
    -- If the player was not block broken while perfect blocking an attack type marked as valid by mod settings
    if is_perfect_block and not block_broken and valid_ranged then
        PLAYER.PERFECT = true
        -- Set timestamp for hitmarker display
        PLAYER.TIME = Managers.time:time("main")
        -- Collect block source for particle spawning
        local weapon = self:_wielded_weapon(self._inventory_component, self._weapons)
        local fx_sources = weapon.fx_sources
        local block_source = fx_sources._block
        -- Find any valid fx source if the weapon does not have a dedicated block source
        if fx_sources and not block_source then
            for _, source in pairs(fx_sources) do
                if source then
                    block_source = source
                    break
                end
            end
        end
        -- Spawn particles if particle setting is enabled
        if block_source and MOD.PARTICLE then
            local fx_extension = self._fx_extension
            local particle_name = "content/fx/particles/interacts/grimoire_discard"
            mod.create_particles(fx_extension, particle_name, block_source, true, "stop")
        end
    end
    return func(self, attacking_unit, hit_world_position, block_broken, weapon_template, attack_type, block_cost, is_perfect_block)
end)