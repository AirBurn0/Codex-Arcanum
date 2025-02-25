CodexArcanum = SMODS.current_mod

SMODS.Atlas{ key = "modicon", px = 32, py = 32, path = "modicon.png" }

SMODS.load_file("utils/CardUtil.lua")()
SMODS.load_file("utils/Overrides.lua")()
SMODS.load_file("utils/FakeGameObjects.lua")()
SMODS.load_file("utils/UICard.lua")()
SMODS.load_file("utils/UI.lua")()

CodexArcanum.pools = CodexArcanum.pools or {}

local current_config = SMODS.load_file("config.lua")().modules -- There is some cases of OLD/invalid data in config, so try to clean it
for module, config in pairs(CodexArcanum.config.modules) do
    if current_config[module] == nil then
        -- remove nonexistent module
        CodexArcanum.config.modules[module] = nil
    else
        for key, _ in pairs(config) do
            if current_config[module][key] == nil then
                -- remove nonexistent config key
                config[key] = nil
            end
        end
        SMODS.load_file("data/" .. module .. ".lua")()
    end
end
