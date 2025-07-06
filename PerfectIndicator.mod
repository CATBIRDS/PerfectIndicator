return {
    run = function()
    fassert(rawget(_G, "new_mod"), "`PerfectIndicator` encountered an error loading the Darktide Mod Framework.")

        new_mod("PerfectIndicator", {
            mod_script       = "PerfectIndicator/scripts/mods/PerfectIndicator/PerfectIndicator",
            mod_data         = "PerfectIndicator/scripts/mods/PerfectIndicator/PerfectIndicator_data",
            mod_localization = "PerfectIndicator/scripts/mods/PerfectIndicator/PerfectIndicator_localization",
        })
    end,
    packages = {},
}
