function create_alchemical()
	return create_card("Alchemical", G.pack_cards, nil, nil, true, true, nil, "alc")
end

function take_cards_from_discard()
	G.E_MANAGER:add_event(Event{
		trigger = "immediate",
		func = function()
			local count = #G.discard.cards
			for i = 1, count do --draw cards from deck
				draw_card(G.discard, G.deck, i * 100 / count, "up", nil, nil, 0.005, i % 2 == 0, nil, math.max((21 - i) / 20, 0.7))
			end
			return true
		end
	})
end

function return_to_deck(card)
	if not (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and G.hand.config.card_limit <= 0 and #G.hand.cards == 0 then
		G.STATE = G.STATES.GAME_OVER
		G.STATE_COMPLETE = false
		return true
	end
	delay(0.05)
	draw_card(G.hand, G.deck, 100, "up", false, card)
end

function is_in_booster_pack(state)
	return state == G.STATES.STANDARD_PACK
		or state == G.STATES.TAROT_PACK
		or state == G.STATES.PLANET_PACK
		or state == G.STATES.SPECTRAL_PACK
		or state == G.STATES.BUFFOON_PACK
		or state == G.STATES.SMODS_BOOSTER_OPENED
end

function alchemy_check_for_chips_win()
	return G.GAME.chips >= G.GAME.blind.chips
end

function alchemy_card_eval_text(card, text, sound, color, text_scale, hold, delayed, after_func)
	local card_aligned = "bm"
	local y_off = 0.15 * G.CARD_H
	if card.area == G.jokers or card.area == G.consumeables then
		y_off = 0.05 * card.T.h
	elseif card.area == G.hand or card.area == G.play or card.jimbo then
		y_off = -0.05 * G.CARD_H
		card_aligned = "tm"
	end
	local text_func = function()
		attention_text{
			text = text,
			scale = text_scale or 1,
			hold = hold or 0.6,
			backdrop_colour = color,
			align = card_aligned,
			major = card,
			offset = { x = 0, y = y_off }
		}
		play_sound(sound, 0.98 + 0.04 * math.random(), 1)
		if after_func and type(after_func) == "function" then
			after_func()
		end
		return true
	end
	if delayed then
		G.E_MANAGER:add_event(Event{
			trigger = "before",
			delay = 0.75 * 1.25,
			func = text_func
		})
	else
		text_func()
	end
end

-- Serpent fix, plz do not be like Serpent and don't override what must not be overriden
function alchemy_draw_cards(amount)
	if G.GAME.blind:get_type() == "Boss" and G.GAME.blind.config.blind.key == "bl_serpent" then
		local serpent = G.GAME.blind.disabled
		G.GAME.blind.disabled = true
		G.FUNCS.draw_from_deck_to_hand(amount)
		G.GAME.blind.disabled = serpent
		return
	end
	G.FUNCS.draw_from_deck_to_hand(amount)
end

-- for cryptid enjoyers
function alchemy_ability_round(ability)
	if not ability or type(ability) ~= "number" then
		return 0
	end
	return math.floor(ability + 0.5)
end


function alchemy_max_selected_cards(card)
    return math.max(1, alchemy_ability_round(card.ability.select_cards))
end

function alchemy_loc_plural(word, count)
	local plurals = G.localization.misc.CodexArcanum_plurals[word]
	if not plurals then
		return "nil"
	end
	return plurals(count)
end

function alchemy_mult_blind_score(by_percent)
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

function alchemy_get_progress_info(vars)
	local main_end = {}
	localize{ type = "descriptions", set = "Other", key = "a_alchemy_unlock_counter", nodes = main_end, vars = vars }
	return main_end[1]
end
