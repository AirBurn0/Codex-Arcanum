G.C.SECONDARY_SET.Alchemy = HEX("C09D75")

SMODS.Atlas{ key = "modicon", px = 32, py = 32, path = "modicon.png" }

SMODS.load_file("utils/CA_CardUtil.lua")()
SMODS.load_file("utils/CA_Overrides.lua")()

SMODS.load_file("data/CA_Alchemicals.lua")()
SMODS.load_file("data/CA_BoosterPacks.lua")()
SMODS.load_file("data/CA_Decks.lua")()
SMODS.load_file("data/CA_Jokers.lua")()
SMODS.load_file("data/CA_Vouchers.lua")()
SMODS.load_file("data/CA_Others.lua")()
