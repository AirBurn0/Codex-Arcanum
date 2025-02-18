G.C.SECONDARY_SET.Alchemy = HEX("C09D75")

SMODS.Atlas{ key = "modicon", px = 32, py = 32, path = "modicon.png" }

SMODS.load_file("utils/CardUtil.lua")()
SMODS.load_file("utils/Overrides.lua")()

SMODS.load_file("data/Alchemicals.lua")()
SMODS.load_file("data/BoosterPacks.lua")()
SMODS.load_file("data/Jokers.lua")()
SMODS.load_file("data/Consumables.lua")()
SMODS.load_file("data/Decks.lua")()
SMODS.load_file("data/Vouchers.lua")()
SMODS.load_file("data/Tags.lua")()
