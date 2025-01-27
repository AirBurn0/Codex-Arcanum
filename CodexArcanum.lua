--- STEAMODDED HEADER
--- MOD_NAME: Codex Arcanum
--- MOD_ID: CodexArcanum
--- MOD_AUTHOR: [itayfeder, Lyman, Jumbo, lshtech, AirBurn]
--- MOD_DESCRIPTION: Adds a new set of cards: Alchemy!
--- BADGE_COLOUR: C09D75
--- PRIORITY: -100
--- VERSION: 1.1.5
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-1321d]
----------------------------------------------
------------MOD CODE -------------------------

G.C.SECONDARY_SET.Alchemy = HEX("C09D75")
G.P_CENTER_POOLS.Alchemical = {}
G.localization.descriptions.Alchemical = {}
G.localization.misc.dictionary["k_alchemical"] = "Alchemical"
G.localization.misc.dictionary["p_plus_alchemical"] = "+1 Alchemical"
G.localization.misc.dictionary["p_alchemy_plus_card"] = "+2 Cards"
G.localization.misc.dictionary["p_alchemy_plus_money"] = "+5 Dollars"
G.localization.misc.v_dictionary["p_alchemy_reduce_blind"] = "Blind score -#1#"
G.localization.misc.dictionary["b_stat_alchemicals"] = "Alchemicals"

CodexArcanum = {}
CodexArcanum.mod_id = 'CodexArcanum'
CodexArcanum.INIT = {}

SMODS.Atlas { key = 'modicon', px = 32, py = 32, path = 'tag_elemental.png' }

function SMODS.INIT.CodexArcanum()
    CodexArcanum.mod = SMODS.findModByID(CodexArcanum.mod_id)

    SMODS.load_file("api/AlchemicalAPI.lua")()

    SMODS.load_file("utils/CA_AlchemyUI.lua")()
    SMODS.load_file("utils/CA_CardUtil.lua")()

    SMODS.load_file("CA_Overrides.lua")()

    SMODS.load_file("data/CA_Jokers.lua")()
    SMODS.load_file("data/CA_Alchemicals.lua")()
    SMODS.load_file("data/CA_BoosterPacks.lua")()
    SMODS.load_file("data/CA_Others.lua")()

    for _, v in pairs(CodexArcanum.INIT) do
        if v and type(v) == 'function' then
            v()
        end
    end

    loc_colour("mult", nil)
    G.ARGS.LOC_COLOURS["alchemical"] = G.C.SECONDARY_SET.Alchemy

    SMODS.LOAD_LOC()
    SMODS.SAVE_UNLOCKS()
    ALCHEMICAL_SAVE_UNLOCKS()
end

----------------------------------------------
------------MOD CODE END----------------------
