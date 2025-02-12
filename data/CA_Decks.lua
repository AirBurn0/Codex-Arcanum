SMODS.Atlas{
    key = "decks_atlas",
    path = "ca_decks_atlas.png",
    px = 71,
    py = 95
}

-- kinda default constructor
local function new_deck(deck)
    -- create deck
    SMODS.Back{
        key = deck.key,    
        config = deck.config or {},
        unlocked = not deck.check_for_unlock,
        check_for_unlock = deck.check_for_unlock,
        apply = function(self) end,
        pos = deck.pos or { x = 0, y = 0 },
        atlas = "decks_atlas",
        trigger_effect = deck.trigger_effect
    }
end

new_deck{
    key = "philosopher",
    config = { vouchers = { "v_alchemy_alchemical_merchant" }, atlas = "decks_atlas" },
    pos = { x = 0, y = 0 },
    check_for_unlock = function(self, args)
        if args.type == "discover_amount" and G.P_CENTERS.c_alchemy_philosopher_stone.discovered then
            unlock_card(self)
        end
    end
}

new_deck{
    key = "herbalist",
    config = { vouchers = { "v_alchemy_mortar_and_pestle" }, atlas = "decks_atlas" },
    pos = { x = 1, y = 0 },
    check_for_unlock = function(self, args)
        if args.type == "discover_amount" and G.P_CENTERS.c_alchemy_seeker.discovered then
            unlock_card(self)
        end
    end,
    trigger_effect = function(self, context)
        if context.setting_blind then
            delay(0.2)
            G.E_MANAGER:add_event(Event({
                trigger = "immediate",
                func = function()
                    if G.consumeables.config.card_limit > #G.consumeables.cards then
                        play_sound("timpani")
                        local card = create_card("Alchemical", G.consumeables, nil, nil, nil, nil, nil, "see")
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                    end
                    return true
                end
            }))
        end
    end
}