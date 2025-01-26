function CodexArcanum.INIT.CA_Jokers()
    SMODS.Sprite:new("ca_joker_atlas", CodexArcanum.mod.path, "ca_joker_atlas.png", 71, 95, "asset_atli"):register();

    -- Studious Joker
    local studious_joker_def = { 
        name = "Studious Joker",
        text = { 
            "{C:mult}+#1#{} Mult. Sell this", 
            "joker to get one", 
            "{C:alchemical} Alchemical{} card" 
        } 
    }

    local studious_joker = SMODS.Joker:new("Studious Joker", "studious_joker", { mult = 4 }, { x = 0, y = 0 }, studious_joker_def, 1, 5, true, false, true, true, "Mult", "ca_joker_atlas")
    studious_joker:register()

    function SMODS.Jokers.j_studious_joker.loc_def(card)
        return { card.ability.mult }
    end

    function SMODS.Jokers.j_studious_joker.calculate(card, context)
        if context.selling_self and not context.blueprint then
            add_random_alchemical(card)
            card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize('p_plus_alchemical'), colour = G.C.SECONDARY_SET.Alchemy })
            return { card = card }
        end

        if context.joker_main then
            return { message = localize { type = 'variable', key = 'a_mult', vars = { card.ability.mult } }, mult_mod = card.ability.mult }
        end
    end

    -- Bottled Buffoon
    local bottled_buffoon_def = { 
        name = "Bottled Buffoon", 
        text = { 
            "Create an {C:alchemical}Alchemical{} card", 
            "every {C:attention}#1#{} hands played",
            "{C:inactive}(#2#)" 
        } 
    }

    local bottled_buffoon = SMODS.Joker:new("Bottled Buffoon", "bottled_buffoon", { extra = { every = 3 } }, { x = 1, y = 0 }, bottled_buffoon_def, 1, 5, true, false, true, true, "", "ca_joker_atlas")
    bottled_buffoon:register()

    function SMODS.Jokers.j_bottled_buffoon.loc_def(card)
        return { card.ability.extra.every + 1, localize { type = 'variable', key = (card.ability.loyalty_remaining == 0 and 'loyalty_active' or 'loyalty_inactive'), vars = { card.ability.loyalty_remaining } } }
    end

    function SMODS.Jokers.j_bottled_buffoon.calculate(card, context)
        if context.cardarea == G.jokers and context.after then
            card.ability.loyalty_remaining = (card.ability.extra.every - 1 - (G.GAME.hands_played - card.ability.hands_played_at_create)) % (card.ability.extra.every + 1)
            if context.blueprint then
                if card.ability.loyalty_remaining == card.ability.extra.every then
                    add_random_alchemical(card)
                    card.ability.loyalty_remaining = card.ability.extra.every
                    return { message = localize('p_plus_alchemical') }
                end
            else
                if card.ability.loyalty_remaining == 0 then
                    local eval = function(_card)
                        return (_card.ability.loyalty_remaining == 0)
                    end
                    juice_card_until(card, eval, true)
                elseif card.ability.loyalty_remaining == card.ability.extra.every then
                    add_random_alchemical(card)
                    card.ability.loyalty_remaining = card.ability.extra.every
                    return { message = localize('p_plus_alchemical') }
                end
            end
        end
    end

    -- Mutated Joker
    local mutated_joker_def = { 
        name = "Mutated Joker", 
        text = { 
            "{C:chips}+#1#{} Chips for each", 
            "unique {C:alchemical}Alchemical{} card", 
            "used this run", 
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)" 
        } 
    }

    local mutated_joker = SMODS.Joker:new("Mutated Joker", "mutated_joker", { extra = { chips = 10 } }, { x = 1, y = 2 }, mutated_joker_def, 1, 5, true, false, true, true, "", "ca_joker_atlas")
    mutated_joker:register()

    function SMODS.Jokers.j_mutated_joker.loc_def(card)
        local expected_total_chips = 0
            if G.GAME.consumeable_usage then
                local alchemical_tally = 0
                for k, v in pairs(G.GAME.consumeable_usage) do
                    if v.set == 'Alchemical' then 
                        alchemical_tally = alchemical_tally + 1
                    end
                end
                expected_total_chips = alchemical_tally * card.ability.extra.chips
            end
        return { card.ability.extra.chips, expected_total_chips }
    end

    function SMODS.Jokers.j_mutated_joker.calculate(card, context)
        if context.using_consumeable and not context.consumeable.config.in_booster and context.consumeable.ability.set == 'Alchemical' then 
            G.E_MANAGER:add_event(Event({ 
                func = function()
                    card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize { type = 'variable', key = 'a_chips', vars = { card.ability.extra.chips } } })
                    return true
                end 
            }))
            return
        end
        if context.joker_main then
            local expected_total_chips = 0
            if G.GAME.consumeable_usage then
                local alchemical_tally = 0
                for k, v in pairs(G.GAME.consumeable_usage) do
                    if v.set == 'Alchemical' then 
                        alchemical_tally = alchemical_tally + 1
                    end
                end
                expected_total_chips = alchemical_tally * card.ability.extra.chips
            end
            return { message = localize { type = 'variable', key = 'a_chips', vars = { expected_total_chips } }, chip_mod = expected_total_chips }
        end
    end

    -- Chain Reaction
    local chain_reaction_def = { 
        name = "Chain Reaction", 
        text = { 
            "Create a {C:dark_edition}Negative{} {C:attention}copy{}", 
            "of the first {C:alchemical}Alchemical{} ", 
            "card used each blind" 
        } 
    }

    local chain_reaction = SMODS.Joker:new("Chain Reaction", "chain_reaction", { extra = { used = false } }, { x = 2, y = 0 }, chain_reaction_def, 2, 5, false, false, true, true, "", "ca_joker_atlas")
    chain_reaction:register()

    function SMODS.Jokers.j_chain_reaction.calculate(card, context)
        if context.using_consumeable and not context.consumeable.config.in_booster and context.consumeable.ability.set == 'Alchemical' then
            if not card.ability.extra.used then
                G.E_MANAGER:add_event(Event({ func = function()
                    local _card = copy_card(context.consumeable, nil, nil, nil)
                    _card:set_edition({ negative = true }, true)
                    _card:add_to_deck()
                    G.consumeables:emplace(_card)

                    return true
                end }))
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = "Copied", colour = G.C.SECONDARY_SET.Alchemy })
                card.ability.extra.used = true
                return
            end
        end
    end

    -- Essence of Comedy
    local essence_of_comedy_def = { 
        name = "Essence of Comedy", 
        text = { 
            "Gains {X:mult,C:white}X#1#{} Mult", 
            "per {C:alchemical}Alchemical{} card used", 
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)" 
        } 
    }

    local essence_of_comedy = SMODS.Joker:new("Essence of Comedy", "essence_of_comedy", { extra = 0.1, Xmult = 1 }, { x = 0, y = 1 }, essence_of_comedy_def, 2, 6, true, false, true, true, "", "ca_joker_atlas")
    essence_of_comedy:register()

    function SMODS.Jokers.j_essence_of_comedy.loc_def(card)
        return { card.ability.extra, card.ability.x_mult }
    end

    function SMODS.Jokers.j_essence_of_comedy.calculate(card, context)
        if context.using_consumeable and not context.consumeable.config.in_booster and context.consumeable.ability.set == 'Alchemical' then
            card.ability.x_mult = card.ability.x_mult + card.ability.extra
            G.E_MANAGER:add_event(Event({ func = function()
                card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.x_mult } } });
                return true
            end }))
            return
        end
    end

    -- Shock Humor
    local shock_humor_def = { 
        name = "Shock Humor", 
        text = { 
            "{C:green}#1# in #2#{} chance to", 
            "create an {C:alchemical}Alchemical{} card", 
            "when you discard a {C:attention}Gold{},", 
            "{C:attention}Steel{} or {C:attention}Stone{} card" 
        } 
    }

    local shock_humor = SMODS.Joker:new("Shock Humor", "shock_humor", { extra = { odds = 5 } }, { x = 1, y = 1 }, shock_humor_def, 2, 5, true, false, true, true, "", "ca_joker_atlas")
    shock_humor:register()

    function SMODS.Jokers.j_shock_humor.loc_def(card) 
        return { '' .. (G.GAME and G.GAME.probabilities.normal or 1), card.ability.extra.odds }
    end

    function SMODS.Jokers.j_shock_humor.calculate(card, context)
        if context.discard and not context.other_card.debuff then
            if context.other_card.config.center == G.P_CENTERS.m_steel or context.other_card.config.center == G.P_CENTERS.m_gold or context.other_card.config.center == G.P_CENTERS.m_stone then
                if pseudorandom('shock_humor') < G.GAME.probabilities.normal / card.ability.extra.odds then
                    add_random_alchemical(card)
                    card_eval_status_text(card, 'extra', nil, nil, nil, { message = localize('p_plus_alchemical'), colour = G.C.SECONDARY_SET.Alchemy })
                end
            end
        end
    end

    -- Breaking Bozo
    local breaking_bozo_def = { 
        name = "Breaking Bozo", 
        text = { 
            "After you use an {C:alchemical}Alchemical{}",
            "card, does one the following: ",
            "- Reduce {C:attention}Blind score{} by {C:attention}#1#%{}",
            "- Draw {C:attention}#2#{} cards", 
            "- Earn {C:money}$#3#{}" 
        }
    }

    local breaking_bozo = SMODS.Joker:new("Breaking Bozo", "breaking_bozo", { blind_size = 0.1, cards = 2, money = 5 }, { x = 2, y = 1 }, breaking_bozo_def, 3, 7, true, false, true, true, "", "ca_joker_atlas")
    breaking_bozo:register()

    function SMODS.Jokers.j_breaking_bozo.loc_vars(self, info_queue, card)
        return { vars = { card.ability.blind_size * 100, card.ability.cards, card.ability.money } }
    end

    function SMODS.Jokers.j_breaking_bozo.calculate(card, context)
        if context.using_consumeable and not context.consumeable.config.in_booster and context.consumeable.ability.set == 'Alchemical' then
            G.E_MANAGER:add_event(Event({ 
                trigger = 'after', 
                delay = 0.1, 
                func = function()
                    local choice = pseudorandom(pseudoseed('breaking_bozo'))
                    if choice < 0.33 then
                        G.FUNCS.draw_from_deck_to_hand(card.ability.cards)
                        card_eval_status_text(card, 'extra', nil, nil, nil, { instant = true, message = localize('p_alchemy_plus_card'), colour = G.C.SECONDARY_SET.Alchemy })
                    elseif choice < 0.66 then
                        ease_dollars(card.ability.money, true)
                        card_eval_status_text(card, 'dollars', card.ability.money, nil, nil, { instant = true })
                    else
                        local newScore = math.floor(G.GAME.blind.chips * (1 - card.ability.blind_size))
                        local difference = G.GAME.blind.chips - newScore
                        G.GAME.blind.chips = newScore
                        G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
                        G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
                        G.HUD_blind:recalculate()
                        G.hand_text_area.blind_chips:juice_up()
                        local card_aligned = 'bm'
                        local y_off = 0.15 * G.CARD_H
                        if card.area == G.jokers or card.area == G.consumeables then
                            y_off = 0.05 * card.T.h
                        elseif card.area == G.hand or card.area == G.play or card.jimbo then
                            y_off = -0.05 * G.CARD_H
                            card_aligned = 'tm'
                        end
                        attention_text({
                            text = localize{type='variable', key='p_alchemy_reduce_blind', vars = { difference } },
                            scale = 0.5, 
                            hold = 1,
                            backdrop_colour = G.C.SECONDARY_SET.Alchemy,
                            align = card_aligned,
                            major = card,
                            offset = {x = 0, y = y_off}
                        })
                        play_sound('chips2', 0.98 + 0.04 * math.random(), 1)
                    end
                    return true
                end
            }))
        end
    end

    -- Catalyst Joker
    local catalyst_joker_def = { 
        name = "Catalyst Joker", 
        text = { 
            "{C:attention}+1{} consumable slots.", 
            "Gains {X:mult,C:white}X#2#{} Mult for", 
            "every {C:attention}Consumable Card{} held", 
            "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)"
        } 
    }

    local catalyst_joker = SMODS.Joker:new("Catalyst Joker", "catalyst_joker", { extra = { slots = 1, bonus = 0.5 } }, { x = 0, y = 2 }, catalyst_joker_def, 3, 6, true, false, true, true, "", "ca_joker_atlas")
    catalyst_joker:register()

    function SMODS.Jokers.j_catalyst_joker.loc_def(card)
        return { card.ability.extra.slots, card.ability.extra.bonus, 1 + card.ability.extra.bonus * (card.ability.consumeable_tally or 0) }
    end

    function SMODS.Jokers.j_catalyst_joker.calculate(card, context)
        if context.joker_main then
            return { message = localize { type = 'variable', key = 'a_xmult', vars = { 1 + card.ability.extra.bonus * card.ability.consumeable_tally } }, Xmult_mod = 1 + card.ability.extra.bonus * card.ability.consumeable_tally, colour = G.C.MULT }
        end
    end
end