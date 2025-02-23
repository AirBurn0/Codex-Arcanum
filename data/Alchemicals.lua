SMODS.Atlas{
    key = "alchemicals",
    path = "alchemicals.png",
    px = 71,
    py = 95
}

SMODS.UndiscoveredSprite{
    key = "Alchemical",
    atlas = "alchemicals",
    pos = { x = 4, y = 4 }
}

-- Until SMODS do "LockedSprite" it will be like that
G.c_alchemy_locked = {
    name = "Locked",
    pos = { x = 5, y = 4 },
    atlas = "alchemy_alchemicals",
    set = "Alchemical",
    unlocked = false,
    max = 1,
    cost_mult = 1.0,
    config = {}
}

SMODS.ConsumableType{
    key = "Alchemical",
    primary_colour = HEX("C09D75"),
    secondary_colour = HEX("C09D75"),
    collection_rows = { 4, 4 },
    shop_rate = 0,
    default = CodexArcanum.utils.get_first_key_enabled(CodexArcanum.config.modules.Alchemicals, "c_fool"), -- should be c_alchemy_ignis if not disabled
}

CodexArcanum.pools.Alchemicals = CodexArcanum.pools.Alchemicals or {}

-- kinda default constructor
local function new_alchemical(alchemical)
    local key = "c_alchemy_" .. alchemical.key
    -- create fake
    if not CodexArcanum.config.modules.Alchemicals[key] then
        CodexArcanum.pools.Alchemicals[#CodexArcanum.pools.Alchemicals + 1] = CodexArcanum.FakeCard:extend{ class_prefix = "c" }{
            key = alchemical.key or "default",
            loc_set = "Alchemical",
            atlas = alchemical.atlas or "alchemicals",
            pos = alchemical.pos or { x = 4, y = 4 },
            loc_vars = function(self, info_queue, center)
                local loc = alchemical.loc_vars and alchemical.loc_vars(self, info_queue, center) or { vars = {} }
                loc.set = "Alchemical"
                return loc
            end,
            config = alchemical.config or {}
        }
        return
    end

    -- can_use function builder
    -- preharps there is simpler way to do this and don't ctrl+c ctrl+v code
    local can_use_builder = { alchemical.can_use or function(self, card) return G.STATE == G.STATES.SELECTING_HAND and not card.debuff end }
    if not alchemical.can_use then
        if alchemical.config and alchemical.config.max_highlighted then
            local select_type = type(alchemical.config.max_highlighted)
            if select_type == "number" then     -- mutable select size (for cryptid enjoyers)
                can_use_builder[#can_use_builder + 1] = function(self, card) return (#G.hand.highlighted <= CodexArcanum.utils.max_highlighted(card) and #G.hand.highlighted > 0) end
            elseif select_type == "string" then -- immutable select size (no cryptid joy)
                local finalSize = tonumber(alchemical.config.max_highlighted)
                can_use_builder[#can_use_builder + 1] = function(self, card) return (#G.hand.highlighted <= finalSize and #G.hand.highlighted > 0) end
            end
        end
        if alchemical.default_can_use then
            can_use_builder[#can_use_builder + 1] = alchemical.default_can_use
        end
    end
    -- create consumable
    CodexArcanum.pools.Alchemicals[#CodexArcanum.pools.Alchemicals + 1] = SMODS.Consumable{
        key = alchemical.key or "unknown",
        set = "Alchemical",
        atlas = alchemical.atlas or "alchemicals",
        pos = alchemical.pos or { x = 4, y = 4 },
        loc_vars = alchemical.loc_vars,
        unlocked = not (alchemical.unlock_condition or alchemical.check_for_unlock),
        unlock_condition = alchemical.unlock_condition,
        check_for_unlock = alchemical.check_for_unlock,
        locked_loc_vars = alchemical.locked_loc_vars,
        discovered = false,
        config = alchemical.config or {},
        cost = alchemical.cost or 3,
        can_use = function(self, card)
            for _, can_use_function in ipairs(can_use_builder) do
                if not can_use_function(self, card) then
                    return false
                end
            end
            return true
        end,
        use = function(self, card, area, copier)
            if not copier then
                if G.GAME.consumeable_usage_total.alchemical then
                    G.GAME.consumeable_usage_total.alchemical = G.GAME.consumeable_usage_total.alchemical + 1
                else
                    G.GAME.consumeable_usage_total.alchemical = 1
                end
                if not G.GAME.used_alchemical_consumeable_unique then
                    G.GAME.used_alchemical_consumeable_unique = { count = 0, consumeables = {} }
                end
                local key = card.config.center.key
                local consumeables = G.GAME.used_alchemical_consumeable_unique.consumeables
                if consumeables and not consumeables[key] then
                    consumeables[key] = true
                    G.GAME.used_alchemical_consumeable_unique.count = (G.GAME.used_alchemical_consumeable_unique.count or 0) + 1
                end
            end
            if card.debuff then
                return
            end
            alchemical.use(self, card, area, copier)
            check_for_unlock{ type = "used_alchemical" }
            return true
        end,
        undo = alchemical.undo
    }
end

local function new_alchemical_enhance(key, pos, enhance, max_highlighted)
    new_alchemical{
        key = key,
        loc_vars = function(self, info_queue, center)
            info_queue[#info_queue + 1] = G.P_CENTERS[enhance]
            info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
            local max_highlighted = CodexArcanum.utils.max_highlighted(center)
            return { vars = { max_highlighted, CodexArcanum.utils.loc_plural("card", max_highlighted) } }
        end,
        config = { max_highlighted = max_highlighted or 4 },
        pos = pos,
        use = function(self, card, area, copier)
            G.E_MANAGER:add_event(Event{
                trigger = "after",
                delay = 0.1,
                func = function()
                    for _, _card in ipairs(G.hand.highlighted) do
                        delay(0.05)
                        _card:set_synthesized{ key = self.key, data = _card.config.center.key }
                        _card:juice_up(1, 0.5)
                        _card:set_ability(G.P_CENTERS[enhance])
                    end
                    return true
                end
            })
        end,
        undo = function(self, card, data)
            if card.config.center.key == G.P_CENTERS[enhance].key then
                card:set_ability(G.P_CENTERS[data], nil, true)
            end
        end
    }
end

new_alchemical{
    key = "ignis",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = CodexArcanum.utils.round_integer(center.ability.extra)
        return { vars = { extra, CodexArcanum.utils.loc_plural("discard", extra) } }
    end,
    config = { extra = 1 },
    pos = { x = 0, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                ease_discard(CodexArcanum.utils.round_integer(card.ability.extra))
                return true
            end
        })
    end
}

new_alchemical{
    key = "aqua",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = CodexArcanum.utils.round_integer(center.ability.extra)
        return { vars = { extra, CodexArcanum.utils.loc_plural("hand", extra) } }
    end,
    config = { extra = 1 },
    pos = { x = 1, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                ease_hands_played(CodexArcanum.utils.round_integer(card.ability.extra))
                return true
            end
        })
    end
}

new_alchemical{
    key = "terra",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        return { vars = { center.ability.extra * 100 } }
    end,
    config = { extra = 0.15 },
    pos = { x = 2, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                CodexArcanum.utils.mult_blind_score(1 - card.ability.extra)
                return true
            end
        })
    end
}

new_alchemical{
    key = "aero",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = CodexArcanum.utils.round_integer(center.ability.extra)
        return { vars = { extra, CodexArcanum.utils.loc_plural("card", extra) } }
    end,
    config = { extra = 4 },
    pos = { x = 3, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                CodexArcanum.utils.draw_cards(CodexArcanum.utils.round_integer(card.ability.extra))
                return true
            end
        })
    end
}

new_alchemical{
    key = "quicksilver",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        return { vars = { CodexArcanum.utils.round_integer(center.ability.extra) } }
    end,
    config = { extra = 2 },
    pos = { x = 4, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                local extra = CodexArcanum.utils.round_integer(card.ability.extra)
                G.hand:change_size(extra)
                G.GAME.alchemy_quicksilver = (G.GAME.alchemy_quicksilver or 0) + extra
                return true
            end
        })
    end
}

new_alchemical{
    key = "salt",
    loc_vars = function(self, info_queue, center)
        local extra = math.max(1, CodexArcanum.utils.round_integer(center.ability.extra))
        return { vars = { extra, CodexArcanum.utils.loc_plural("tag", extra) } }
    end,
    config = { extra = 1 },
    pos = { x = 5, y = 0 },
    can_use = function() return G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                for _ = 1, math.max(1, CodexArcanum.utils.round_integer(card.ability.extra)) do
                    local _tag_name
                    if G.FORCE_TAG then
                        _tag_name = G.FORCE_TAG
                    else
                        local _pool, _pool_key = get_current_pool("Tag", nil, nil, nil)
                        _tag_name = pseudorandom_element(_pool, pseudoseed(_pool_key))
                        local it = 1
                        while _tag_name == "UNAVAILABLE" or _tag_name == "tag_double" or _tag_name == "tag_orbital" do
                            it = it + 1
                            _tag_name = pseudorandom_element(_pool, pseudoseed(_pool_key .. "_resample" .. it))
                        end
                    end
                    G.GAME.round_resets.blind_tags = G.GAME.round_resets.blind_tags or {}
                    add_tag(Tag(_tag_name, nil, G.GAME.blind))
                end
                return true
            end
        })
    end
}

new_alchemical{
    key = "sulfur",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        return { vars = { center.ability.money } }
    end,
    config = { money = 4 },
    pos = { x = 0, y = 1 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                local hands = G.GAME.current_round.hands_left
                if hands > 0 then
                    hands = hands - 1
                    ease_hands_played(-hands)
                    ease_dollars(card.ability.money * hands, true)
                end
                return true
            end
        })
    end
}

new_alchemical{
    key = "phosphorus",
    config = { extra = 4 },
    pos = { x = 1, y = 1 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                CodexArcanum.utils.take_cards_from_discard()
                return true
            end
        })
    end
}

new_alchemical{
    key = "bismuth",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_polychrome
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local max_highlighted = CodexArcanum.utils.max_highlighted(center)
        return { vars = { max_highlighted, CodexArcanum.utils.loc_plural("card", max_highlighted) } }
    end,
    config = { max_highlighted = 2 },
    pos = { x = 2, y = 1 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                for _, _card in ipairs(G.hand.highlighted) do
                    _card:set_synthesized{ key = self.key, data = _card.edition and _card.edition.type or nil }
                    _card:set_edition({ polychrome = true }, true)
                end
                return true
            end
        })
    end,
    undo = function(self, card, data)
        if (card.edition and card.edition.type == "polychrome") then
            card:set_edition(data, true)
        end
    end
}

new_alchemical{
    key = "cobalt",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = CodexArcanum.utils.round_integer(center.ability.extra)
        return { vars = { extra, CodexArcanum.utils.loc_plural("level", extra) } }
    end,
    config = { extra = 2 },
    pos = { x = 3, y = 1 },
    default_can_use = function(self, card) return #G.hand.highlighted > 0 end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                local text, disp_text = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
                update_hand_text(
                    { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
                    { handname = localize(text, "poker_hands"), chips = G.GAME.hands[text].chips, mult = G.GAME.hands[text].mult, level = G.GAME.hands[text].level }
                )
                level_up_hand(card, text, nil, CodexArcanum.utils.round_integer(card.ability.extra))
                update_hand_text(
                    { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
                    { mult = 0, chips = 0, handname = "", level = "" }
                )
                return true
            end
        })
    end
}

new_alchemical{
    key = "arsenic",
    pos = { x = 4, y = 1 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                local temp_hands = G.GAME.current_round.hands_left
                local temp_discards = G.GAME.current_round.discards_left
                G.GAME.current_round.hands_left = 0
                G.GAME.current_round.discards_left = 0
                ease_hands_played(temp_discards)
                ease_discard(temp_hands)
                -- why stop player from being stupid? Let bro cook!
                if temp_discards <= 0 and G.STAGE == G.STAGES.RUN then
                    G.STATE = G.STATES.GAME_OVER;
                    G.STATE_COMPLETE = false
                end
                Game:update_hand_played(nil)
                return true
            end
        })
    end
}

new_alchemical{
    key = "antimony",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        info_queue[#info_queue + 1] = { key = "eternal", set = "Other" }
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = CodexArcanum.utils.round_integer(center.ability.extra)
        return { vars = { extra, CodexArcanum.utils.loc_plural("copy", extra) } }
    end,
    config = { extra = 1 },
    pos = { x = 5, y = 1 },
    default_can_use = function(self, card) return #G.jokers.cards > 0 end,
    use = function(self, card, area, copier)
        G.jokers.config.antimony = G.jokers.config.antimony or {}
        if #G.jokers.cards > 0 then
            G.E_MANAGER:add_event(Event{
                trigger = "after",
                delay = 0.1,
                func = function()
                    for _ = 1, CodexArcanum.utils.round_integer(card.ability.extra) or 1 do
                        local joker = pseudorandom_element(G.jokers.cards, pseudoseed("invisible"))
                        local _card = copy_card(joker, nil, nil, nil, joker.edition and joker.edition.negative)
                        _card:set_edition({ negative = true }, true)
                        _card.cost = 0
                        _card.sell_cost = 0
                        _card:set_synthesized{ key = self.key }
                        _card:add_to_deck()
                        G.jokers:emplace(_card)
                    end
                    return true
                end
            })
        end
    end,
    undo = function(self, card, data)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.3,
            blockable = false,
            func = function()
                G.jokers:remove_card(card)
                card:remove()
                return true;
            end
        })
    end
}

new_alchemical{
    key = "soap",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local max_highlighted = CodexArcanum.utils.max_highlighted(center)
        return { vars = { max_highlighted, CodexArcanum.utils.loc_plural("card", max_highlighted) } }
    end,
    config = { max_highlighted = 3 },
    pos = { x = 0, y = 2 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                for _, _card in ipairs(G.hand.highlighted) do
                    CodexArcanum.utils.return_to_deck(_card)
                end
                CodexArcanum.utils.draw_cards(#G.hand.highlighted)
                return true
            end
        })
    end
}

new_alchemical{
    key = "magnet",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = CodexArcanum.utils.round_integer(center.ability.extra)
        return { vars = { extra, CodexArcanum.utils.loc_plural("card", extra) } }
    end,
    config = { max_highlighted = "1", extra = 2 },
    pos = { x = 5, y = 2 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                local target = G.hand.highlighted[1]
                local t_rank = SMODS.has_no_rank(target) and "no_rank" or target.base.id
                local count = CodexArcanum.utils.round_integer(card.ability.extra)
                for _, _card in pairs(G.deck.cards) do
                    if (t_rank == "no_rank" and SMODS.has_no_rank(_card)) or (t_rank ~= "no_rank" and not SMODS.has_no_rank(_card) and _card.base.id == t_rank) then
                        delay(0.05)
                        draw_card(G.deck, G.hand, 100, "up", true, _card)
                        count = count - 1
                    end
                    if count < 1 then
                        return true
                    end
                end
                return true
            end
        })
    end
}

new_alchemical{
    key = "wax",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = CodexArcanum.utils.round_integer(center.ability.extra)
        return { vars = { extra, CodexArcanum.utils.loc_plural("copy", extra) } }
    end,
    config = { max_highlighted = "1", extra = 2 },
    pos = { x = 2, y = 2 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                local new_table = {}
                for _ = 1, CodexArcanum.utils.round_integer(card.ability.extra) do
                    G.playing_card = (G.playing_card or 0) + 1
                    local _card = copy_card(G.hand.highlighted[1], nil, nil, G.playing_card)
                    _card:add_to_deck()
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    _card:set_synthesized{ key = self.key }
                    table.insert(G.playing_cards, _card)
                    G.hand:emplace(_card)
                    table.insert(new_table, _card.unique_val)
                end
                playing_card_joker_effects(new_table)
                return true
            end
        })
    end,
    undo = function(self, card, data)
        card:start_dissolve(nil, true)
    end
}

new_alchemical{
    key = "borax",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local top_suit = CodexArcanum.utils.get_most_common_suit()
        local max_highlighted = CodexArcanum.utils.max_highlighted(center)
        return { vars = { max_highlighted, CodexArcanum.utils.loc_plural("card", max_highlighted), top_suit, colours = { G.C.SUITS[top_suit] } } }
    end,
    config = { max_highlighted = 4 },
    pos = { x = 3, y = 2 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                local top_suit = CodexArcanum.utils.get_most_common_suit()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:set_synthesized{ key = self.key, data = { prev_suit = _card.base.suit, suit = top_suit } }
                    _card:juice_up(1, 0.5)
                    _card:change_suit(top_suit)
                end
                G.hand:parse_highlighted()
                return true
            end
        })
    end,
    undo = function(self, card, data)
        if card.base.suit == data.suit then
            card:change_suit(data.prev_suit)
        end
    end
}

new_alchemical_enhance("glass", { x = 4, y = 2 }, "m_glass", 4)

new_alchemical_enhance("manganese", { x = 1, y = 2 }, "m_steel", 4)

new_alchemical_enhance("gold", { x = 0, y = 3 }, "m_gold", 4)

new_alchemical_enhance("silver", { x = 1, y = 3 }, "m_lucky", 4)

new_alchemical{
    key = "oil",
    pos = { x = 2, y = 3 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
    end,
    unlock_condition = { type = "c_alchemy_unlock_oil" },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                for _, _card in ipairs(G.hand.cards) do
                    delay(0.05)
                    _card:set_synthesized{ key = self.key }
                    _card:juice_up(1, 0.5)
                    _card:set_debuff(false)
                    _card.ability = _card.ability or {}
                    _card.ability.oil = true
                    if _card.facing == "back" then
                        _card:flip()
                    end
                end
                return true
            end
        })
    end,
    undo = function(self, card, data)
        card.ability.oil = nil
    end
}

new_alchemical{
    key = "acid",
    pos = { x = 3, y = 3 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
    end,
    config = { max_highlighted = 1 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, CodexArcanum.utils.loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = CodexArcanum.utils.get_progress_info{ #G.playing_cards }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { count = 68 } },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type and #G.playing_cards > 0 and #G.playing_cards > self.unlock_condition.extra.count
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                G.GAME.alchemy_acid = G.GAME.alchemy_acid or {}
                local removed_table = {}
                for _, _card in ipairs(G.hand.highlighted) do
                    local t_rank = SMODS.has_no_rank(_card) and "no_rank" or _card.base.id
                    for _, v in ipairs(G.playing_cards) do
                        if (t_rank == "no_rank" and SMODS.has_no_rank(v)) or (t_rank ~= "no_rank" and not SMODS.has_no_rank(v) and v.base.id == t_rank) then
                            table.insert(G.GAME.alchemy_acid, v:save()) -- in case that game will be reopened
                            table.insert(removed_table, v)
                            v:start_dissolve({ HEX("E3FF37") }, nil, 1.6)
                        end
                    end
                end
                SMODS.calculate_context{ remove_playing_cards = true, removed = removed_table }
                return true
            end
        })
    end,
    undo = function(self, card, data)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                card = Card(0, 0, G.CARD_W, G.CARD_H, G.P_CENTERS.j_joker, G.P_CENTERS.c_base, { playing_card = G.playing_card })
                card:load(data)
                G.playing_card = (G.playing_card or 0) + 1
                -- not really adding card cuz some jokers can go nuts
                G.deck:emplace(card)
                G.deck.config.card_limit = G.deck.config.card_limit + 1
                table.insert(G.playing_cards, card)
                G.deck:set_ranks()
                G.deck:align_cards()
                G.deck:hard_set_cards()
                return true
            end
        })
    end
}

new_alchemical{
    key = "brimstone",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local hands, discards = CodexArcanum.utils.round_integer(center.ability.extra.hands), CodexArcanum.utils.round_integer(center.ability.extra.discards)
        return { vars = { hands, CodexArcanum.utils.loc_plural("hand", hands), discards, CodexArcanum.utils.loc_plural("discard", discards) } }
    end,
    config = { extra = { hands = 2, discards = 2 } },
    pos = { x = 4, y = 3 },
    unlock_condition = { type = "discard_custom" },
    check_for_unlock = function(self, args)
        if args.type == self.unlock_condition.type then
            local eval = evaluate_poker_hand(args.cards)
            if next(eval["Pair"]) then
                local flag = true
                for j = 1, #args.cards do
                    if args.cards[j]:get_id() ~= 2 then
                        flag = false
                    end
                end
                return flag
            end
        end
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                ease_discard(CodexArcanum.utils.round_integer(card.ability.extra.hands))
                ease_hands_played(CodexArcanum.utils.round_integer(card.ability.extra.discards))
                for i = 1, #G.jokers.cards do
                    if not G.jokers.cards[i].debuff then
                        G.jokers.cards[i]:set_debuff(true)
                        G.jokers.cards[i]:juice_up()
                        break
                    end
                end
                return true
            end
        })
    end
}

new_alchemical{
    key = "uranium",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        local extra = math.max(1, CodexArcanum.utils.round_integer(center.ability.extra))
        return { vars = { extra, CodexArcanum.utils.loc_plural("card", extra) } }
    end,
    config = { max_highlighted = "1", extra = 3 },
    pos = { x = 5, y = 3 },
    locked_loc_vars = function(self, info_queue, center)
        local extra = self.unlock_condition.extra
        local loc = { vars = { extra, CodexArcanum.utils.loc_plural("card", extra) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = CodexArcanum.utils.get_progress_info{ G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.alchemical or 0 }
        end
        return loc
    end,
    unlock_condition = { type = "used_alchemical", extra = 10 },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type and G.GAME.consumeable_usage_total.alchemical >= self.unlock_condition.extra
    end,
    use = function(self, card, area, copier)
        -- search for suitable cards
        local eligible_cards = {}
        for _, v in ipairs(G.hand.cards) do
            if v.config.center == G.P_CENTERS.c_base and not (v.edition) and not (v.seal) then
                table.insert(eligible_cards, v)
            end
        end
        -- randomsort array
        for i = #eligible_cards, 2, -1 do
            local j = pseudorandom(pseudoseed(card.ability.name), 1, i)
            eligible_cards[i], eligible_cards[j] = eligible_cards[j], eligible_cards[i]
        end
        -- call it a day
        local target = G.hand.highlighted[1]
        for i = 1, math.max(1, CodexArcanum.utils.round_integer(card.ability.extra)) do
            if #eligible_cards < i then
                break
            end
            local _card = eligible_cards[i]
            G.E_MANAGER:add_event(Event{
                trigger = "after",
                delay = 0.1,
                func = function()
                    _card:set_synthesized{ key = self.key, data = { center = target.config.center.key, edition = target.edition and target.edition.type or nil, seal = target:get_seal(true) } }
                    if not target.edition then
                        _card:juice_up(1, 0.5)
                    end
                    _card:set_ability(target.config.center)
                    _card:set_edition(target.edition, true)
                    _card:set_seal(target:get_seal(true), false, true)
                    return true
                end
            })
        end
    end,
    undo = function(self, card, data)
        if card.config.center.key == data.center then
            card:set_ability(G.P_CENTERS.c_base, nil, true)
        end
        if card.edition and card.edition.type == data.edition then
            card:set_edition({}, nil, true)
        end
        if card:get_seal(true) == data.seal then
            card:set_seal(nil, true, nil)
        end
    end
}

new_alchemical{
    key = "lithium",
    pos = { x = 0, y = 4 },
    can_use = function() return #G.jokers.highlighted > 0 and G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT end,
    unlock_condition = { type = "c_alchemy_unlock_lithium" },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type
    end,
    use = function(self, card, area, copier)
        for _, _card in ipairs(G.jokers.highlighted) do
            G.E_MANAGER:add_event(Event{
                trigger = "after",
                delay = 0.1,
                func = function()
                    _card:juice_up(1, 0.5)
                    _card:set_debuff(false)
                    _card:set_eternal()
                    _card.ability.perishable = nil
                    _card:set_rental()
                    return true
                end
            })
        end
    end
}

new_alchemical{
    key = "honey",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemical_card", set = "Other" }
        return { vars = {} }
    end,
    pos = { x = 1, y = 4 },
    unlock_condition = { type = "c_alchemy_unlock_honey" },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event{
            trigger = "after",
            delay = 0.1,
            func = function()
                G.GAME.blind.dollars = G.GAME.blind.dollars * 0
                G.GAME.current_round.dollars = G.GAME.current_round.dollars * 0
                G.GAME.current_round.dollars_to_be_earned = "$0"
                G.GAME.blind:disable()
                return true
            end
        })
    end
}

new_alchemical_enhance("chlorine", { x = 2, y = 4 }, "m_wild", 3)

new_alchemical_enhance("stone", { x = 3, y = 4 }, "m_stone", 4)
