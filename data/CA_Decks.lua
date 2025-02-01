SMODS.Atlas{
    key = 'decks_atlas',
    path = 'ca_decks_atlas.png',
    px = 71,
    py = 95
}

-- kinda default constructor
local function new_deck(deck)
    -- create deck
    SMODS.Back{
        key = deck.key,    
        config = deck.config or {},
        unlocked = true,
        apply = function(self) end,
        pos = deck.pos or { x = 0, y = 0 },
        atlas = 'decks_atlas'
    }
end

new_deck{
    key = "philosopher",
    config = { vouchers = { 'v_alchemy_alchemical_merchant' }, consumables = { 'c_alchemy_seeker' }, atlas = "decks_atlas" },
    pos = { x = 0, y = 0 }
}

new_deck{
    key = "herbalist",
    config = { vouchers = { 'v_alchemy_mortar_and_pestle' }, atlas = "decks_atlas" },
    pos = { x = 1, y = 0 }
}