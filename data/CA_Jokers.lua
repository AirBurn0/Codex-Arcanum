SMODS.Atlas{
    key = "joker_atlas",
    path = "ca_joker_atlas.png",
    px = 71,
    py = 95
}

-- kinda default constructor
local function new_joker(joker)
    -- create joker
    SMODS.Joker{ 
        key = joker.key, 
        pos = joker.pos or { x = 0, y = 0},
        atlas = joker.atlas or "joker_atlas",
        loc_vars = joker.loc_vars, 
        config = joker.config or {},
        rarity = joker.rarity or 1, 
        cost = joker.cost or 5, 
        unlocked = not joker.locked, 
        discovered = joker.discovered or false, 
        blueprint_compat = not joker.no_blueprint, 
        perishable_compat = true, 
        eternal_compat = true,
        calculate = joker.calculate or function(self, card, context) end
    }
end

new_joker{
    key = "studious_joker",
    pos = { x = 0, y = 0 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.mult } }
    end,
    config = { mult = 4 },
    rarity = 1,
    cost = 5,
    calculate = function(self, card, context)
        -- sadly but that's how canon works
        if context.selling_self and not context.blueprint and G.consumeables.config.card_limit - (#G.consumeables.cards + G.GAME.consumeable_buffer) > 0 then
            add_random_alchemical(card)
            card_eval_status_text(card, "extra", nil, nil, nil, { message = localize("p_plus_alchemical"), colour = G.C.SECONDARY_SET.Alchemy })
            return { card = card }
        elseif context.joker_main then
            return { message = localize { type = "variable", key = "a_mult", vars = { card.ability.mult } }, mult_mod = card.ability.mult }
        end
    end
}

new_joker{
    key = "bottled_buffoon",
    pos = { x = 1, y = 0 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.every + 1, localize{ type = "variable", key = (card.ability.loyalty_remaining == 0 and "loyalty_active" or "loyalty_inactive"), vars = { card.ability.loyalty_remaining or card.ability.extra.every } } } }
    end,
    config = { extra = { every = 3 } },
    rarity = 1,
    cost = 5,
    calculate = function(self, card, context)
        if context.cardarea == G.jokers and context.after then
            card.ability.loyalty_remaining = (card.ability.extra.every - 1 - (G.GAME.hands_played - card.ability.hands_played_at_create)) % (card.ability.extra.every + 1)
            if context.blueprint then
                if card.ability.loyalty_remaining == card.ability.extra.every then
                    add_random_alchemical(card)
                    card.ability.loyalty_remaining = card.ability.extra.every
                    return { message = localize("p_plus_alchemical") }
                end
            else
                if card.ability.loyalty_remaining == 0 then
                    juice_card_until(card, function(_card) return (_card.ability.loyalty_remaining == 0) end, true)
                elseif card.ability.loyalty_remaining == card.ability.extra.every then
                    add_random_alchemical(card)
                    card.ability.loyalty_remaining = card.ability.extra.every
                    return { message = localize("p_plus_alchemical") }
                end
            end
        end
    end
}

new_joker{
    key = "mutated_joker",
    pos = { x = 1, y = 2 },
    loc_vars = function(self, info_queue, card)
        local expected_total_chips = 0
        if G.GAME.used_alchemical_consumeable_unique then
            expected_total_chips = G.GAME.used_alchemical_consumeable_unique.count * card.ability.extra.chips
        end
        return { vars = { card.ability.extra.chips, expected_total_chips } }
    end,
    config = { extra = { chips = 15 } },
    rarity = 1,
    cost = 5,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint and not context.consumeable.config.in_booster and context.consumeable.ability.set == "Alchemical" then
            if G.GAME.consumeable_usage and G.GAME.consumeable_usage[context.consumeable.config.center.key].count == 1 then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        card_eval_status_text(card, "extra", nil, nil, nil, { message = localize { type = "variable", key = "a_chips", vars = { card.ability.extra.chips } } })
                        return true
                    end
                }))
            end
            return
        end
        if context.joker_main then
            local expected_total_chips = 0
            if G.GAME.used_alchemical_consumeable_unique then
                expected_total_chips = G.GAME.used_alchemical_consumeable_unique.count * card.ability.extra.chips
            end
            return { message = localize { type = "variable", key = "a_chips", vars = { expected_total_chips } }, chip_mod = expected_total_chips }
        end
    end
}

new_joker{
    key = "chain_reaction",
    pos = { x = 2, y = 0 },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = { key = "e_negative_consumable", set = "Edition", config = { extra = 1 } }
        return { vars = { } }
    end,
    config = { extra = { used = false } },
    rarity = 2,
    cost = 5,
    no_blueprint = true, -- sadly but that's how canon works
    calculate = function(self, card, context)
        if context.blueprint then
            return
        end
        if context.first_hand_drawn then
            juice_card_until(card, function(_card) return not _card.ability.extra.used end, true)
        end
        if G.GAME.blind.in_blind and context.using_consumeable and not context.consumeable.config.in_booster and context.consumeable.ability.set == "Alchemical" and not card.ability.extra.used then
            G.E_MANAGER:add_event(Event({
                trigger = "after", 
                delay = 0.1, 
                func = function()
                    alchemy_card_eval_text(card, localize("k_copied_ex"), "generic1", G.C.SECONDARY_SET.Alchemy, nil, nil, true, function() 
                        local _card = copy_card(context.consumeable, nil, nil, nil)
                        _card:set_edition({ negative = true }, true)
                        _card:add_to_deck()
                        G.consumeables:emplace(_card)
                    end)                    
                    return true
                end
            }))
            card.ability.extra.used = true
            return
        end
    end
}

new_joker{
    key = "essence_of_comedy",
    pos = { x = 0, y = 1 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.x_mult } }
    end,
    config = { extra = 0.1, Xmult = 1 },
    rarity = 2,
    cost = 6,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint and not context.consumeable.config.in_booster and context.consumeable.ability.set == "Alchemical" then
            card.ability.x_mult = card.ability.x_mult + card.ability.extra
            G.E_MANAGER:add_event(Event({
                func = function()
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = localize { type = "variable", key = "a_xmult", vars = { card.ability.x_mult } } });
                    return true
                end
            }))
            return
        end
    end
}

new_joker{
    key = "shock_humor",
    pos = { x = 1, y = 1 },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = G.P_CENTERS.m_gold
        info_queue[#info_queue+1] = G.P_CENTERS.m_steel
        info_queue[#info_queue+1] = G.P_CENTERS.m_stone
        return { vars = { "" .. (G.GAME and G.GAME.probabilities.normal or 1), card.ability.extra.odds } }
    end,
    config = { extra = { odds = 5 } },
    rarity = 2,
    cost = 5,
    calculate = function(self, card, context)
        local discarded = context.other_card
        if context.discard 
        and G.consumeables.config.card_limit - (#G.consumeables.cards + G.GAME.consumeable_buffer) > 0
        and not discarded.debuff 
        and (discarded.config.center == G.P_CENTERS.m_steel or discarded.config.center == G.P_CENTERS.m_gold or discarded.config.center == G.P_CENTERS.m_stone) 
        and pseudorandom("shock_humor") < G.GAME.probabilities.normal / card.ability.extra.odds 
        then
            local _card = context.blueprint_card or card
            add_random_alchemical(_card)
            card_eval_status_text(_card, "extra", nil, nil, nil, { message = localize("p_plus_alchemical"), colour = G.C.SECONDARY_SET.Alchemy })
        end
    end
}

new_joker{
    key = "breaking_bozo",
    pos = { x = 2, y = 1 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.blind_reduce * 100, card.ability.extra.cards, card.ability.extra.money } }
    end,
    config = { extra = { blind_reduce = 0.1, cards = 2, money = 5 } },
    rarity = 3,
    cost = 7,
    calculate = function(self, card, context)
        if not context.using_consumeable or context.consumeable.config.in_booster or context.consumeable.ability.set ~= "Alchemical" then
            return
        end
        local _card = context.blueprint_card or card
        G.E_MANAGER:add_event(Event({ 
            trigger = "after", 
            delay = 0.1, 
            func = function()
                local choice = pseudorandom(pseudoseed("breaking_bozo"))
                if choice < 0.33 or (not G.GAME.blind.in_blind and context.consumeable.config.center.key == "c_alchemy_salt") then
                    local money = card.ability.extra.money
                    alchemy_card_eval_text(_card, (money <-0.01 and "-" or "")..localize("$")..tostring(math.abs(money)), nil, money <-0.01 and G.C.RED or G.C.MONEY, nil, nil, true, function()
                        ease_dollars(money, true)
                    end)
                elseif choice < 0.66 then
                    G.FUNCS.draw_from_deck_to_hand(card.ability.extra.cards)
                    alchemy_card_eval_text(_card, localize("p_alchemy_plus_card"), "generic1", G.C.SECONDARY_SET.Alchemy, nil, nil, true)
                else
                    alchemy_card_eval_text(_card, localize{ type ="variable", key="a_alchemy_reduce_blind", vars = { difference } }, "chips2", G.C.SECONDARY_SET.Alchemy, 0.5, nil, true, function() 
                        local newScore = math.floor(G.GAME.blind.chips * (1 - card.ability.extra.blind_reduce))
                        local difference = G.GAME.blind.chips - newScore
                        G.GAME.blind.chips = newScore
                        G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
                        G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
                        G.HUD_blind:recalculate()
                        G.hand_text_area.blind_chips:juice_up()
                        G.GAME.blind.alchemy_chips_win = alchemy_check_for_chips_win()
                    end)
                end
                return true
            end
        }))
    end
}

new_joker{
    key = "catalyst_joker",
    pos = { x = 0, y = 2 },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.slots, card.ability.extra.bonus, 1 + card.ability.extra.bonus * (G.consumeables and #G.consumeables.cards or 0) } }
    end,
    config = { extra = { slots = 1, bonus = 0.5 } },
    rarity = 3,
    cost = 6,
    calculate = function(self, card, context)
        if context.joker_main then
            return { message = localize { type = "variable", key = "a_xmult", vars = { 1 + card.ability.extra.bonus * #G.consumeables.cards } }, Xmult_mod = 1 + card.ability.extra.bonus * #G.consumeables.cards, colour = G.C.MULT }
        end
    end
}