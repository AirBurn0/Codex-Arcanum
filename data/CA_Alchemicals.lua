SMODS.Atlas{
    key = "alchemicals_atlas",
    path = "ca_alchemical_atlas.png",
    px = 71,
    py = 95
}

SMODS.ConsumableType{
    key = "Alchemical",
    primary_colour = G.C.SECONDARY_SET.Alchemy,
    secondary_colour = G.C.SECONDARY_SET.Alchemy,
    collection_rows = { 4, 4 },
    shop_rate = 0,
    default = "c_alchemy_ignis"
}

SMODS.UndiscoveredSprite{
    key = "Alchemical",
    atlas = "alchemicals_atlas",
    pos = { x = 4, y = 4 }
}

-- Until SMODS do 'LockedSprite' it will be like that
G.c_alchemy_locked = {
    name = "Locked",
    pos = { x = 5, y = 4 },
    atlas = "alchemy_alchemicals_atlas",
    set = "Alchemical",
    unlocked = false,
    max = 1,
    cost_mult = 1.0,
    config = { }
}

local function get_most_common_suit() 
	local suit_to_card_couner = {}
	for _, v in pairs(SMODS.Suits) do
		if not v.disabled then
			suit_to_card_couner[v.name] = 0
		end
	end
	if G.playing_cards then
		for _, v in pairs(G.playing_cards) do
            if not (SMODS.has_no_suit(v) or SMODS.has_any_suit(v)) then -- stone cards should count as no suit, wildcards should count as any suit
                suit_to_card_couner[v.base.suit] = suit_to_card_couner[v.base.suit] + 1
            end
		end
	end
	local top_suit = "";
	local top_count = -1;
	for suit, count in pairs(suit_to_card_couner) do
		if top_count < count then
			top_suit = suit
			top_count = count
		end
	end

	return top_suit
end

local function max_selected_cards(card) 
	return math.max(1, alchemy_ability_round(card.ability.select_cards))
end

local function mult_blind_score(by_percent)
    G.GAME.blind.chips = math.floor(G.GAME.blind.chips * math.max(0, by_percent))
    G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
    G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
    G.HUD_blind:recalculate() 
    G.hand_text_area.blind_chips:juice_up()
    if not silent then 
        play_sound("chips2") 
    end
    G.GAME.blind.alchemy_chips_win = alchemy_check_for_chips_win()
end

local function get_progress_info(vars)
    local main_end = {}
    localize{ type = "descriptions", set = "Other", key = "a_alchemy_unlock_counter", nodes = main_end, vars = vars }
    return main_end[1]
end

local function count_enhanced_cards(enhance)
    local count = 0
    for _, v in pairs(G.playing_cards) do
        if v.ability.name == enhance then 
            count = count + 1 
        end
    end
    return count
end

-- kinda default constructor
local function new_alchemical(alchemical)
    -- can_use function builder
    -- preharps there is simpler way to do this and don't ctrl+c ctrl+v code
    local can_use_builder = { alchemical.can_use or function(self, card) return G.STATE == G.STATES.SELECTING_HAND end }
    if not alchemical.can_use then
        if alchemical.config and alchemical.config.select_cards then
            local select_type = type(alchemical.config.select_cards)
            if select_type == "number" then -- mutable select size (for cryptid enjoyers)
                can_use_builder[#can_use_builder + 1] = function(self, card) return (#G.hand.highlighted <= max_selected_cards(card) and #G.hand.highlighted > 0) end
            elseif select_type == "string" then -- immutable select size (no cryptid joy)
                local finalSize = tonumber(alchemical.config.select_cards)
                can_use_builder[#can_use_builder + 1] = function(self, card) return (#G.hand.highlighted <= finalSize and #G.hand.highlighted > 0) end
            end
        end
        if alchemical.default_can_use then
            can_use_builder[#can_use_builder + 1] = alchemical.default_can_use
        end
    end
    -- create consumable
    SMODS.Consumable{ 
        key = alchemical.key or "stone", -- default is stone lol
        set = "Alchemical",
        atlas = alchemical.atlas or "alchemicals_atlas",
        pos = alchemical.pos or { x = 3, y = 5 }, -- default is stone lol
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
            if alchemical.undo then -- if effect should be undone after certain events
                if not G.deck.config.alchemy_undo_table then
                    G.deck.config.alchemy_undo_table = {}
                end
                local undo_table = G.deck.config.alchemy_undo_table[card.ability.name] or {} -- always give the table
                alchemical.use(self, card, area, copier, undo_table)
                G.deck.config.alchemy_undo_table[card.ability.name] = undo_table
            else -- or else just evaluate
                alchemical.use(self, card, area, copier)
            end
            check_for_unlock{type = "used_alchemical"}
            return true
        end,
        undo = alchemical.undo
    }
end

new_alchemical{
    key = "ignis",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = alchemy_ability_round(center.ability.extra)
        return { vars = { extra, alchemy_loc_plural("discard", extra) } } 
    end,
    config = { extra = 1 },
    pos = { x = 0, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                ease_discard(alchemy_ability_round(card.ability.extra))
                return true
            end
        }))
    end
}

new_alchemical{
    key = "aqua",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = alchemy_ability_round(center.ability.extra)
        return { vars = { extra, alchemy_loc_plural("hand", extra) } } 
    end,
    config = { extra = 1 },
    pos = { x = 1, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                ease_hands_played(alchemy_ability_round(card.ability.extra))
                return true
            end
        }))
    end
}

new_alchemical{
    key = "terra",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        return { vars = { center.ability.extra * 100} } 
    end,
    config = { extra = 0.15 },
    pos = { x = 2, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                   mult_blind_score(1 - card.ability.extra)
                return true
            end
        }))
    end
}

new_alchemical{
    key = "aero",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = alchemy_ability_round(center.ability.extra)
        return { vars = { extra, alchemy_loc_plural("card", extra) } } 
    end,
    config = { extra = 4 },
    pos = { x = 3, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                alchemy_draw_cards(alchemy_ability_round(card.ability.extra))
                return true 
            end 
        }))
    end
}

new_alchemical{
    key = "quicksilver",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        return { vars = { alchemy_ability_round(center.ability.extra) } }
    end,
    config = { extra = 2 },
    pos = { x = 4, y = 0 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                local extra = alchemy_ability_round(card.ability.extra)
                G.hand:change_size(extra)
                G.deck.config.quicksilver = (G.deck.config.quicksilver or 0) + extra
                return true 
            end 
        }))
    end
}

new_alchemical{
    key = "salt",
    loc_vars = function(self, info_queue, center)
        local extra = math.max(1, alchemy_ability_round(center.ability.extra))
        return { vars = { extra, alchemy_loc_plural("tag", extra) } } 
    end,
    config = { extra = 1 },
    pos = { x = 5, y = 0 },
    can_use = function() return G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for _ = 1, math.max(1, alchemy_ability_round(card.ability.extra)) do
                    local _tag_name
                    if G.FORCE_TAG then 
                        _tag_name = G.FORCE_TAG
                    else
                        local _pool, _pool_key = get_current_pool("Tag", nil, nil, nil)
                        _tag_name = pseudorandom_element(_pool, pseudoseed(_pool_key))
                        local it = 1
                        while _tag_name == "UNAVAILABLE" or _tag_name == "tag_double" or _tag_name == "tag_orbital" do
                            it = it + 1
                            _tag_name = pseudorandom_element(_pool, pseudoseed(_pool_key.."_resample"..it))
                        end
                    end
                    G.GAME.round_resets.blind_tags = G.GAME.round_resets.blind_tags or {}
                    add_tag(Tag(_tag_name, nil, G.GAME.blind))
                end
                return true 
            end 
        }))
    end
}

new_alchemical{
    key = "sulfur",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        return { vars = { center.ability.money } } 
    end,
    config = { money = 4 },
    pos = { x = 0, y = 1 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
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
        }))
    end
}

new_alchemical{
    key = "phosphorus",
    config = { extra = 4 },
    pos = { x = 1, y = 1 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({ 
            trigger = "after", 
            delay = 0.1,
            func = function()
                take_cards_from_discard(#G.discard.cards)
                return true
            end 
        }))
    end
}
  
new_alchemical{
    key = "bismuth",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.e_polychrome
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } }
    end,
    config = { select_cards = 2 },
    pos = { x = 2, y = 1 },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, card in ipairs(G.hand.highlighted) do
                    card:set_edition({ polychrome = true }, true)
                    table.insert(undo_table, card.unique_val)
                end
                return true 
            end 
        }))
    end,
    undo = function(self, undo_table)
        for _, poly_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == poly_id and card.edition and card.edition.polychrome then
                    card:set_edition(nil, true)
                end
            end
        end
    end
}

new_alchemical{
    key = "cobalt",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = alchemy_ability_round(center.ability.extra)
        return { vars = { extra, alchemy_loc_plural("level", extra) } } 
    end,
    config = { extra = 2 },
    pos = { x = 3, y = 1 },
    default_can_use = function(self, card) return #G.hand.highlighted > 0 end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                local text, disp_text = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
                update_hand_text(
                    { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, 
                    { handname = localize(text, "poker_hands"), chips = G.GAME.hands[text].chips, mult = G.GAME.hands[text].mult, level = G.GAME.hands[text].level }
                )
                level_up_hand(card, text, nil, alchemy_ability_round(card.ability.extra))
                update_hand_text( 
                    { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
                    { mult = 0, chips = 0, handname = "", level = "" }
                )
                return true 
            end 
        }))
    end
}

new_alchemical{
    key = "arsenic",
    pos = { x = 4, y = 1 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
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
        }))
    end
}

new_alchemical{
    key = "antimony",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.e_negative
        info_queue[#info_queue+1] = {key = "eternal", set = "Other"}
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = alchemy_ability_round(center.ability.extra)
        return { vars = { extra, alchemy_loc_plural("copy", extra) } } 
    end,
    config = { extra = 1 },
    pos = { x = 5, y = 1 },
    default_can_use = function(self, card) return #G.jokers.cards > 0 end,
    use = function(self, card, area, copier)
        G.jokers.config.antimony = G.jokers.config.antimony or {}
        if #G.jokers.cards > 0 then 
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.1,
                func = function()
                    for _ = 1, alchemy_ability_round(card.ability.extra) or 1 do
                        local chosen_joker = pseudorandom_element(G.jokers.cards, pseudoseed("invisible"))
                        local card = copy_card(chosen_joker, nil, nil, nil, chosen_joker.edition and chosen_joker.edition.negative)
                        card:set_edition({negative = true}, true)
                        card.cost = 0
                        card.sell_cost = 0
                        card:add_to_deck()
                        G.jokers:emplace(card)
                        table.insert(G.jokers.config.antimony, card.unique_val)
                    end
                    return true
                end 
            }))
        end
    end,
    undo = function(self, undo_table) 
        if G.jokers.config.antimony then
            for _, poly_id in ipairs(G.jokers.config.antimony) do
                for k, joker in ipairs(G.jokers.cards) do
                    if joker.unique_val == poly_id then
                        G.E_MANAGER:add_event(Event({
                            trigger = "after",
                            delay = 0.3,
                            blockable = false,
                            func = function()
                                G.jokers:remove_card(joker)
                                joker:remove()
                                joker = nil
                                return true;
                            end
                        }))
                    end
                end
            end
            G.jokers.config.antimony = {}
        end
    end
}

new_alchemical{
    key = "soap",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 3 },
    pos = { x = 0, y = 2 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                local extra = alchemy_ability_round(card.ability.select_cards)
                for k, _card in ipairs(G.hand.highlighted) do
                    return_to_deck(extra, _card)
                end
                alchemy_draw_cards(extra)
                return true
            end
        }))
    end
}

new_alchemical{
    key = "magnet",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = alchemy_ability_round(center.ability.extra)
        return { vars = { extra, alchemy_loc_plural("card", extra) } } 
    end,
    config = { select_cards = "1", extra = 2 },
    pos = { x = 5, y = 2 },
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                local _selected = G.hand.highlighted[1]
                local cur_rank = SMODS.has_no_rank(_selected) and "no_rank" or _selected.base.id
                local count = alchemy_ability_round(card.ability.extra)
                for _, v in pairs(G.deck.cards) do
                    local no_rank = (cur_rank == "no_rank" and SMODS.has_no_rank(v))
                    if (cur_rank == "no_rank" and SMODS.has_no_rank(v)) or (cur_rank ~= "no_rank" and not SMODS.has_no_rank(v) and v.base.id == cur_rank) then
                        delay(0.05)
                        draw_card(G.deck, G.hand, 100, "up", true, v)
                        count = count - 1
                    end
                    if count < 1 then
                        return true
                    end
                end
                return true
            end
        }))
    end
}

new_alchemical{
    key = "wax",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = alchemy_ability_round(center.ability.extra)
        return { vars = { extra, alchemy_loc_plural("copy", extra) } } 
    end,
    config = { select_cards = "1", extra = 2 },
    pos = { x = 2, y = 2 },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                local new_table = {}
                for i = 1, alchemy_ability_round(card.ability.extra) do
                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local _card = copy_card(G.hand.highlighted[1], nil, nil, G.playing_card)
                    _card:add_to_deck()
                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    table.insert(G.playing_cards, _card)
                    G.hand:emplace(_card)
                    table.insert(undo_table, _card.unique_val)
                    table.insert(new_table, _card.unique_val)
                end
                playing_card_joker_effects(new_table)
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        local _first_dissolve = false
        for _, wax_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == wax_id then
                    card:start_dissolve(nil, _first_dissolve)
                    _first_dissolve = true
                end
            end
        end
    end
}

new_alchemical{
    key = "borax",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local top_suit = get_most_common_suit()
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards), top_suit, colours = { G.C.SUITS[top_suit] } } } 
    end,
    config = { select_cards = 4 },
    pos = { x = 3, y = 2 },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                top_suit = get_most_common_suit()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:juice_up(1, 0.5)
                    local prev_suit = _card.base.suit
                    _card:change_suit(top_suit)
                    table.insert(undo_table, { id = _card.unique_val, suit = prev_suit })
                end
                G.hand:parse_highlighted()
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for _, borax_table in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == borax_table.id then
                    card:change_suit(borax_table.suit)
                end
            end
        end
    end
}

new_alchemical{
    key = "glass",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.m_glass
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 4 },
    pos = { x = 4, y = 2 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, alchemy_loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ count_enhanced_cards("Glass Card") }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { enhancement = "Glass Card", count = 8} },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:juice_up(1, 0.5)
                    _card:set_ability(G.P_CENTERS.m_glass)
                    table.insert(undo_table, _card.unique_val)
                end
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for _, glass_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == glass_id and card.config.center == G.P_CENTERS.m_glass then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                end
            end
        end
    end
}

new_alchemical{
    key = "manganese",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.m_steel
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 4 },
    pos = { x = 1, y = 2 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, alchemy_loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ count_enhanced_cards("Steel Card") }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { enhancement = "Steel Card", count = 8} },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:juice_up(1, 0.5)
                    _card:set_ability(G.P_CENTERS.m_steel)
                    table.insert(undo_table, _card.unique_val)
                end
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for _, manganese_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == manganese_id and card.config.center == G.P_CENTERS.m_steel then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                end
            end
        end
    end
}

new_alchemical{
    key = "gold",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.m_gold
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 4 },
    pos = { x = 0, y = 3 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, alchemy_loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ count_enhanced_cards("Gold Card") }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { enhancement = "Gold Card", count = 8} },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:juice_up(1, 0.5)
                    _card:set_ability(G.P_CENTERS.m_gold)
                    table.insert(undo_table, _card.unique_val)
                end
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for _, gold_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == gold_id and card.config.center == G.P_CENTERS.m_gold then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                end
            end
        end
    end
}

new_alchemical{
    key = "silver",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.m_lucky
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 4 },
    pos = { x = 1, y = 3 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, alchemy_loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ count_enhanced_cards("Lucky Card") }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { enhancement = "Lucky Card", count = 8} },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:juice_up(1, 0.5)
                    _card:set_ability(G.P_CENTERS.m_lucky)
                    table.insert(undo_table, _card.unique_val)
                end
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for _, silver_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == silver_id and card.config.center == G.P_CENTERS.m_lucky then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                end
            end
        end
    end
}

new_alchemical{
    key = "oil",
    pos = { x = 2, y = 3 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
    end,
    unlock_condition = { type = "c_alchemy_unlock_oil" },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type
    end,
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, v in ipairs(G.hand.cards) do
                    delay(0.05)
                    v:juice_up(1, 0.5)
                    v:set_debuff(false)
                    v.ability = v.ability or {}
                    v.ability.oil = true
                    table.insert(undo_table, v)
                    if v.facing == "back" then
                        v:flip()
                    end
                end
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for k, card in ipairs(undo_table) do
            if card.ability and card.ability.oil then
                card.ability.oil = nil
            end
        end
    end
}

new_alchemical{
    key = "acid",
    pos = { x = 3, y = 3 },
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = {  select_cards > 1 and " "..tostring(select_cards) or "", alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 1 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, alchemy_loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ #G.playing_cards }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { count = 68 } },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type and #G.playing_cards > 0 and #G.playing_cards > self.unlock_condition.extra.count
    end,
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                local removed_table = {}
                for k, _card in ipairs(G.hand.highlighted) do
                    for k, v in ipairs(G.playing_cards) do
                        if v:get_id() == _card:get_id() then
                            table.insert(undo_table, v)
                            table.insert(removed_table, v)
                            v:start_dissolve({ HEX("E3FF37") }, nil, 1.6)
                        end 
                    end
                end
                SMODS.calculate_context{ remove_playing_cards = true, removed = removed_table }
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for _, acid in ipairs(undo_table) do
            G.playing_card = (G.playing_card and G.playing_card + 1) or 1
            local _card = copy_card(acid, nil, nil, G.playing_card)
            G.deck:emplace(_card)
            G.deck.config.card_limit = G.deck.config.card_limit + 1
            table.insert(G.playing_cards, _card)
        end
    end
}

new_alchemical{
    key = "brimstone",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local hands, discards = alchemy_ability_round(center.ability.extra.hands), alchemy_ability_round(center.ability.extra.discards)
        return { vars =  { hands, alchemy_loc_plural("hand", hands), discards, alchemy_loc_plural("discard", discards) } } 
    end,
    config = { extra = { hands = 2, discards = 2} },
    pos = { x = 4, y = 3 },
    unlock_condition = { type = "discard_custom" },
    check_for_unlock = function(self, args)
        if args.type == self.unlock_condition.type then 
            local eval = evaluate_poker_hand(args.cards)
            if next(eval['Pair']) then
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
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                ease_discard(alchemy_ability_round(card.ability.extra.hands))
                ease_hands_played(alchemy_ability_round(card.ability.extra.discards))
                for i = 1, #G.jokers.cards do
                    if not G.jokers.cards[i].debuff then
                        G.jokers.cards[i]:set_debuff(true)
                        G.jokers.cards[i]:juice_up()
                        break
                    end
                end
                return true
            end
        }))
    end
}

new_alchemical{
    key = "uranium",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local extra = math.max(1, alchemy_ability_round(center.ability.extra))
        return { vars = { extra, alchemy_loc_plural("card", extra) } }
    end,
    config = { select_cards = "1", extra = 3 },
    pos = { x = 5, y = 3 },
    locked_loc_vars = function(self, info_queue, center)
        local extra = self.unlock_condition.extra
        local loc = { vars = { extra, alchemy_loc_plural("card", extra) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ G.GAME.consumeable_usage_total and G.GAME.consumeable_usage_total.alchemical or 0 }
        end
        return loc
    end,
    unlock_condition = { type = "used_alchemical", extra = 10 },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type and G.GAME.consumeable_usage_total.alchemical >= self.unlock_condition.extra
    end,
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for i = 1, math.max(1, alchemy_ability_round(card.ability.extra)) do
                    local eligible_cards = {}
                    for k, v in ipairs(G.hand.cards) do
                        if v.config.center == G.P_CENTERS.c_base and not (v.edition) and not (v.seal) then
                            table.insert(eligible_cards, v)
                        end
                    end
                    if #eligible_cards > 0 then
                        local conv_card = pseudorandom_element(eligible_cards, pseudoseed(card.ability.name))
                        delay(0.05)
                        if not (G.hand.highlighted[1].edition) then 
                            conv_card:juice_up(1, 0.5) 
                        end
                        conv_card:set_ability(G.hand.highlighted[1].config.center)
                        conv_card:set_seal(G.hand.highlighted[1]:get_seal(true))
                        conv_card:set_edition(G.hand.highlighted[1].edition)
                        table.insert(undo_table, conv_card.unique_val)
                    end
                end
                return true
            end
        }))
    end,
    undo = function(self, undo_table)
        for _, uranium_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == uranium_id then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                    card:set_edition({}, nil, true)
                    card:set_seal(nil, true, nil)
                end
            end
        end
    end
}

new_alchemical{
    key = "lithium",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        return { vars = { } } 
    end,
    pos = { x = 0, y = 4 },
    can_use = function() return #G.jokers.highlighted > 0 and G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT end,
    unlock_condition = { type = "c_alchemy_unlock_lithium" },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type
    end,
    use = function(self, card, area, copier, undo_table)
        for _, v in ipairs(G.jokers.highlighted) do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.1,
                func = function()
                    v:juice_up(1, 0.5)
                    v:set_debuff(false)
                    v:set_eternal()
                    v.ability.perishable = nil
                    v:set_rental()
                    return true
                end
            }))
        end
    end
}

new_alchemical{
    key = "honey",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        return { vars = { math.max(0, center.ability.extra) } } 
    end,
    config = { extra = 2 },
    pos = { x = 1, y = 4 },
    unlock_condition = { type = "c_alchemy_unlock_honey" },
    check_for_unlock = function(self, args)
        return args.type == self.unlock_condition.type
    end,
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                G.GAME.blind:disable()
                mult_blind_score(math.max(0, card.ability.extra))
                return true
            end
        }))
    end
}

new_alchemical{
    key = "chlorine",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.m_wild
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 3 },
    pos = { x = 2, y = 4 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, alchemy_loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ count_enhanced_cards("Wild Card") }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { enhancement = "Wild Card", count = 6} },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:juice_up(1, 0.5)
                    _card:set_ability(G.P_CENTERS.m_wild)
                    table.insert(undo_table, _card.unique_val)
                end
                return true
            end
        }))     
    end,
    undo = function(self, undo_table)
        for _, silver_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == silver_id and card.config.center == G.P_CENTERS.m_wild then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                end
            end
        end
    end
}

new_alchemical{
    key = "stone",
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue+1] = G.P_CENTERS.m_stone
        info_queue[#info_queue+1] = { key = "alchemical_card", set = "Other" }
        local select_cards = max_selected_cards(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } } 
    end,
    config = { select_cards = 4 },
    pos = { x = 3, y = 4 },
    locked_loc_vars = function(self, info_queue, center)
        local condition = self.unlock_condition.extra.count
        local loc = { vars = { condition, alchemy_loc_plural("card", condition) } }
        if G.STAGE == G.STAGES.RUN then
            loc.main_end = get_progress_info{ count_enhanced_cards("Stone Card") }
        end
        return loc
    end,
    unlock_condition = { type = "modify_deck", extra = { enhancement = "Stone Card", count = 8} },
    use = function(self, card, area, copier, undo_table)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            func = function()
                for k, _card in ipairs(G.hand.highlighted) do
                    delay(0.05)
                    _card:juice_up(1, 0.5)
                    _card:set_ability(G.P_CENTERS.m_stone)
                    table.insert(undo_table, _card.unique_val)
                end
                return true
            end
        }))     
    end,
    undo = function(self, undo_table)
        for _, silver_id in ipairs(undo_table) do
            for k, card in ipairs(G.playing_cards) do
                if card.unique_val == silver_id and card.config.center == G.P_CENTERS.m_stone then
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                end
            end
        end
    end
}