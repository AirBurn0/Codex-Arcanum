SMODS.Atlas{
    key = "joker_atlas",
    path = "ca_joker_atlas.png",
    px = 71,
    py = 95
}

local function add_card_event(self, card_func) -- card creation delayed
    G.E_MANAGER:add_event(Event({
        trigger = "before",
        func = function()
            local card = card_func()
            card:add_to_deck()
            G.consumeables:emplace(card)
            G.GAME.consumeable_buffer = 0 -- event can be interrupted
            return true
        end
    }))
end

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
        locked_loc_vars = joker.locked_loc_vars,
        unlock_condition = joker.unlock_condition,
        check_for_unlock = joker.check_for_unlock,
        unlocked = not (joker.unlock_condition or joker.check_for_unlock), 
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
        -- sell blueprint for alchemical? HELL YEAH!!
        if context.selling_self and G.consumeables.config.card_limit - (#G.consumeables.cards + G.GAME.consumeable_buffer) > 0 then
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            add_card_event(card, create_alchemical)
            return { message = localize("p_plus_alchemical"), colour = G.C.SECONDARY_SET.Alchemy }
        elseif context.joker_main then
            return { mult = card.ability.mult }
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
            if card.ability.loyalty_remaining == 0 and not context.blueprint then
                juice_card_until(card, function(_card) return (_card.ability.loyalty_remaining == 0) end, true)
            elseif card.ability.loyalty_remaining == card.ability.extra.every then
                if not context.blueprint then
                    card.ability.loyalty_remaining = card.ability.extra.every
                end
                if G.consumeables.config.card_limit - (#G.consumeables.cards + G.GAME.consumeable_buffer) > 0 then
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                    add_card_event(card, create_alchemical)
                    return { message = localize("p_plus_alchemical"), colour = G.C.SECONDARY_SET.Alchemy }
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
                return { message = localize{ type = "variable", key = "a_chips", vars = { card.ability.extra.chips } } }
            end
            return
        end
        if context.joker_main then
            local expected_total_chips = 0
            if G.GAME.used_alchemical_consumeable_unique then
                expected_total_chips = G.GAME.used_alchemical_consumeable_unique.count * card.ability.extra.chips
            end
            return { message = localize{ type = "variable", key = "a_chips", vars = { expected_total_chips } }, chip_mod = expected_total_chips }
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
            return { message = localize{ type = "variable", key = "a_xmult", vars = { card.ability.x_mult } } }
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
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            add_card_event(_card, create_alchemical)
            card_eval_status_text(_card, "extra", nil, nil, nil, { message = localize("p_plus_alchemical"), colour = G.C.SECONDARY_SET.Alchemy })
        end
    end
}

new_joker{
    key = "chain_reaction",
    pos = { x = 2, y = 0 },
    config = { extra = { used = false } },
    rarity = 3,
    cost = 6,
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.count
        return { vars = { condition, alchemy_loc_plural("card", condition), (self.unlock_condition.tally and G.DISCOVER_TALLIES) and G.DISCOVER_TALLIES[self.unlock_condition.tally].tally or 0 } }
    end,
    unlock_condition = { type = "discover_amount", tally = "alchemicals", count = 24 },
    check_for_unlock = function(self, args) 
        if args.type == self.unlock_condition.type and self.unlock_condition.tally and G.DISCOVER_TALLIES and G.DISCOVER_TALLIES[self.unlock_condition.tally] then 
            local tally = G.DISCOVER_TALLIES[self.unlock_condition.tally]
            return self.unlock_condition.count <= tally.tally
        end
    end,
    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            juice_card_until(card, function(_card) return not _card.ability.extra.used end, true)
        end
        local used = context.consumeable
        if not G.GAME.blind.in_blind or not context.using_consumeable or used.config.in_booster or used.ability.set ~= "Alchemical" or card.ability.extra.used then
            return
        end
        if not context.blueprint then
            card.ability.extra.used = true
        end
        if not (used.edition and used.edition.negative) then
            if G.consumeables.config.card_limit <= (#G.consumeables.cards + G.GAME.consumeable_buffer) then
                return
            end
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
        end
        add_card_event(card, function() return copy_card(context.consumeable, nil, nil, nil) end)
        return { message = localize("k_copied_ex"), colour = G.C.SECONDARY_SET.Alchemy }
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
        local choice = pseudorandom(pseudoseed("breaking_bozo"))
        if choice < 0.33 or not G.GAME.blind.in_blind then
            return { dollars = card.ability.extra.money * (G.GAME.blind.in_blind and context.consumeable.config.center.key == "c_alchemy_salt" and 2 or 1) } -- jesse we need to cook
        elseif choice < 0.66 then
            alchemy_draw_cards(alchemy_ability_round(card.ability.extra.cards))
            return { message = localize("p_alchemy_plus_card"), colour = G.C.SECONDARY_SET.Alchemy }
        else
            G.E_MANAGER:add_event(Event({
                trigger = "before",
                func = function()
                    local newScore = math.floor(G.GAME.blind.chips * (1 - card.ability.extra.blind_reduce))
                    local difference = G.GAME.blind.chips - newScore
                    G.GAME.blind.chips = newScore
                    G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
                    G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
                    G.HUD_blind:recalculate()
                    G.hand_text_area.blind_chips:juice_up()
                    G.GAME.blind.alchemy_chips_win = alchemy_check_for_chips_win()
                    return true
                end
            }))
            return { message = localize("a_alchemy_reduce_blind"), colour = G.C.SECONDARY_SET.Alchemy }
        end
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