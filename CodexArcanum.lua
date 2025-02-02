--- STEAMODDED HEADER
--- MOD_NAME: Codex Arcanum
--- MOD_ID: CodexArcanum
--- PREFIX: alchemy
--- MOD_AUTHOR: [itayfeder, Lyman, Jumbo, lshtech, AirBurn]
--- MOD_DESCRIPTION: Adds a new set of cards: Alchemy!
--- BADGE_COLOUR: C09D75
--- PRIORITY: 1000
--- VERSION: 1.1.6r
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-1401a]
----------------------------------------------
------------MOD CODE -------------------------
G.C.SECONDARY_SET.Alchemy = HEX("C09D75")

SMODS.Atlas { key = 'modicon', px = 32, py = 32, path = 'modicon.png' }

SMODS.load_file("utils/CA_CardUtil.lua")()
SMODS.load_file("utils/CA_Overrides.lua")()

SMODS.load_file("data/CA_Alchemicals.lua")()
SMODS.load_file("data/CA_BoosterPacks.lua")()
SMODS.load_file("data/CA_Decks.lua")()
SMODS.load_file("data/CA_Jokers.lua")()
SMODS.load_file("data/CA_Vouchers.lua")()
SMODS.load_file("data/CA_Others.lua")()
----------------------------------------------
------------MOD CODE END----------------------