function create_alchemical() 
    return create_card("Alchemical", G.pack_cards, nil, nil, true, true, nil, 'alc')
end

function take_cards_from_discard(count)
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            for i=1, count do --draw cards from deck
                draw_card(G.discard, G.deck, i * 100 / count, 'up', nil, nil, 0.005, i % 2 == 0, nil, math.max((21 - i)/ 20, 0.7))
            end
            return true
        end
    }))
end

function return_to_deck(count, card)
    if not (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and G.hand.config.card_limit <= 0 and #G.hand.cards == 0 then 
        G.STATE = G.STATES.GAME_OVER; G.STATE_COMPLETE = false 
        return true
    end
    delay(0.05)
    draw_card(G.hand,G.deck, 100,'up', false, card)
end

function alchemical_can_use(self, card)
    return G.STATE == G.STATES.SELECTING_HAND and not card.debuff
end

function is_in_booster_pack(state)
	return state == G.STATES.STANDARD_PACK 
	or state == G.STATES.TAROT_PACK 
	or state == G.STATES.PLANET_PACK 
	or state == G.STATES.SPECTRAL_PACK 
	or state == G.STATES.BUFFOON_PACK
	or state == G.STATES.SMODS_BOOSTER_OPENED
end

-- Talisman compat API
local function alchemy_talisman_number(arg)
	local status, ret = pcall(to_big, arg)
	if status then
		return ret
	end
	return arg
end

function alchemy_check_for_chips_win()
	return alchemy_talisman_number(G.GAME.chips) >= alchemy_talisman_number(G.GAME.blind.chips) 
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
			offset = {x = 0, y = y_off}
		}
		play_sound(sound, 0.98 + 0.04 * math.random(), 1)
		if after_func and type(after_func) == "function" then
			after_func()
		end
		return true
	end
	if delayed then
		G.E_MANAGER:add_event(Event({
			trigger = "before",
            delay = 0.75 * 1.25,
			func = text_func
		}))
	else
		text_func()
	end
end

-- Serpent fix, plz do not be like Serpent and don't override what must not be overriden
function alchemy_draw_cards(amount) 
	local serpent = G.GAME.blind.disabled
	G.GAME.blind.disabled = true
	G.FUNCS.draw_from_deck_to_hand(amount)
	G.GAME.blind.disabled = serpent
end

 -- for cryptid enjoyers
function alchemy_ability_round(ability)
	if not ability or type(ability) ~= "number" then
		return 0
	end
	return math.floor(ability + 0.5)
end

function alchemy_loc_plural(word, count)
    local plurals = G.localization.misc.CodexArcanum_plurals[word]
    if not plurals then
        return "nil"
    end
    return plurals(count)
end

function alchemy_get_progress_info(vars)
    local main_end = {}
    localize{ type = "descriptions", set = "Other", key = "a_alchemy_unlock_counter", nodes = main_end, vars = vars }
    return main_end[1]
end