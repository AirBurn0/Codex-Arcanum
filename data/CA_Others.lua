SMODS.Atlas{
    key = "others_atlas",
    path = "ca_others_atlas.png",
    px = 71,
    py = 95
}

SMODS.Tarot{
    key = "seeker",
    pos = { x = 0, y = 0 },
    atlas = "others_atlas",
    loc_vars = function(self, info_queue, center)
        return { vars = { math.max(1, alchemy_ability_round(center.ability.extra.alchemicals)) } }
    end,
    config = { extra = { alchemicals = 2 } },
    cost = 3,
    unlocked = true,
    discovered = false,
    can_use = function(card) return true end,
    use = function(self, card, area, copier)
        local cards = math.min(math.max(1, alchemy_ability_round(card.ability.extra.alchemicals)), G.consumeables.config.card_limit - #G.consumeables.cards)
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
    atlas = "others_atlas",
    config = { extra = "alchemy_alchemical", select_cards = 1 },
    cost = 4,
    unlocked = true,
    discovered = false,
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemy_alchemical_seal", set = "Other" }
        local select_cards = alchemy_max_highlighted(center)
        return { vars = { select_cards, alchemy_loc_plural("card", select_cards) } }
    end,
    can_use = function(self, card) return G.STATE == G.STATES.SELECTING_HAND and #G.hand.highlighted <= alchemy_max_highlighted(card) and #G.hand.highlighted > 0 end,
    use = function(self, card, area, copier)
        for _, _card in ipairs(G.hand.highlighted) do
            G.E_MANAGER:add_event(Event{
                func = function()
                    play_sound("tarot1")
                    card:juice_up(0.3, 0.5)
                    return true
                end
            })
            G.E_MANAGER:add_event(Event{
                trigger = "after",
                delay = 0.1,
                func = function()
                    _card:set_seal(card.ability.extra, false, true)
                    return true
                end
            })
            delay(0.5)
            G.E_MANAGER:add_event(Event{
                trigger = "after",
                delay = 0.2,
                func = function()
                    G.hand:unhighlight_all()
                    return true
                end
            })
        end
    end
}

SMODS.Atlas{
    key = "tag_atlas",
    path = "ca_tag_atlas.png",
    px = 34,
    py = 34
}

-- Elemental Tag
SMODS.Tag{
    key = "elemental",
    config = { type = "new_blind_choice" },
    apply = function(self, tag, context)
        if context.type ~= "new_blind_choice" then
            return
        end
        local lock = tag.ID
        G.CONTROLLER.locks[lock] = true
        tag:yep("+", G.C.PURPLE,
            function()
                local key = "p_alchemy_mega_1"
                local card = Card(G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2, G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2, G.CARD_W * 1.27, G.CARD_H * 1.27, G.P_CARDS.empty, G.P_CENTERS[key], { bypass_discovery_center = true, bypass_discovery_ui = true })
                card.cost = 0
                card.from_tag = true
                G.FUNCS.use_card{ config = { ref_table = card } }
                card:start_materialize()
                G.CONTROLLER.locks[lock] = nil
                return true
            end
        )
        tag.triggered = true
        return true
    end,
    pos = { x = 0, y = 0 },
    atlas = "tag_atlas"
}

SMODS.Atlas{
    key = "sticker_atlas",
    path = "ca_sticker_atlas.png",
    px = 71,
    py = 95
}

local function get_rounds_left()
    return 1
end

-- Synthesized
SMODS.Sticker{
    key = "synthesized",
    default_compat = false,
    sets = { Joker = true, Default = true, Enhanced = true },
    badge_colour = G.C.SECONDARY_SET.Alchemy,
    order = 17,
    pos = { x = 0, y = 0 },
    atlas = "sticker_atlas",
    loc_vars = function(self, info_queue, center)
        local default = get_rounds_left()
        local extra = center.ability[self.key]
        return { vars = { default, alchemy_loc_plural("round", default), (extra and type(extra) == "table" and extra.rounds) or default } }
    end,
    apply = function(self, card, val)
        if not val or type(val) ~= "table" then
            card.ability[self.key] = val
            return
        end
        local extra = card.ability[self.key]
        if not extra or type(extra) ~= "table" then
            array = {}
            extra = { array = array }
            card.ability[self.key] = extra
        end
        table.insert(extra.array, 1, val)
        rounds = get_rounds_left()
    end,
    calculate = function(self, card, context)
        if context.update_round then
            local extra = card.ability[self.key]
            if not extra then
                return
            end
            extra.rounds = (extra.rounds or 0) - 1
            if extra.rounds > 0 then
                return
            end
            -- eval all
            for _, entry in ipairs(extra.array) do
                local center = G.P_CENTERS[entry.key]
                if center.undo then
                    center.undo(center, card, entry.data)
                end
            end
            -- reset
            card:set_synthesized(nil)
        end
    end
}

function Card:set_synthesized(data)
    SMODS.Stickers["alchemy_synthesized"]:apply(self, data)
end

SMODS.Atlas{
    key = "seals_atlas",
    path = "ca_seals_atlas.png",
    px = 71,
    py = 95
}

local function is_card_in(card, array)
    for k, v in ipairs(array) do
        if (v == card) then
            return true
        end
    end
    return false
end

-- Alchemical Seal
SMODS.Seal{
    key = "alchemical",
    badge_colour = G.C.SECONDARY_SET.Alchemy,
    pos = { x = 1, y = 0 },
    atlas = "seals_atlas",
    weight = 1,
    calculate = function(self, card, context)
        if context.cardarea ~= G.hand or not context.hand_drawn or #G.consumeables.cards + G.GAME.consumeable_buffer >= G.consumeables.config.card_limit or not is_card_in(card, context.hand_drawn) then
            return
        end
        G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
        G.E_MANAGER:add_event(Event{
            trigger = "before",
            func = function()
                local _card = create_alchemical()
                _card:add_to_deck()
                G.consumeables:emplace(_card)
                G.GAME.consumeable_buffer = 0 -- event can be interrupted
                return true
            end
        })
        return { message = localize("p_plus_alchemical"), colour = G.C.SECONDARY_SET.Alchemy }
    end,
}
