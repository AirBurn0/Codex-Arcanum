SMODS.Atlas{
    key = "consumables",
    path = "consumables.png",
    px = 71,
    py = 95
}

local function extra(x)
    return math.max(1, alchemy_ability_round(x))
end

SMODS.Tarot{
    key = "seeker",
    pos = { x = 0, y = 0 },
    atlas = "consumables",
    loc_vars = function(self, info_queue, center)
        local extra = extra(center.ability.extra.alchemicals)
        return { vars = { extra, alchemy_loc_plural("card", extra) } }
    end,
    config = { extra = { alchemicals = 2 } },
    cost = 3,
    unlocked = true,
    discovered = false,
    can_use = function(card) return true end,
    use = function(self, card, area, copier)
        local cards = math.min(extra(card.ability.extra.alchemicals), G.consumeables.config.card_limit - #G.consumeables.cards)
        if cards < 1 then
            return
        end
        local used_tarot = (copier or card)
        for i = 1, cards do
            G.E_MANAGER:add_event(Event{
                trigger = "after",
                delay = 0.4,
                func = function()
                    if G.consumeables.config.card_limit > #G.consumeables.cards then
                        play_sound("timpani")
                        local card = create_card("Alchemical", G.consumeables, nil, nil, nil, nil, nil, "see")
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                        used_tarot:juice_up(0.3, 0.5)
                    end
                    return true
                end
            })
        end
        delay(0.6)
    end
}

SMODS.Spectral{
    key = "philosopher_stone",
    pos = { x = 0, y = 1 },
    atlas = "consumables",
    cost = 4,
    unlocked = true,
    discovered = false,
    can_use = function(card) return not (G.deck and G.deck.config and G.deck.config.philosopher) and G.STATE == G.STATES.SELECTING_HAND end,
    use = function(self, card, area, copier)
        G.deck.config.philosopher = true
    end
}
