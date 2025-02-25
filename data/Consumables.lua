SMODS.Atlas{
    key = "consumables",
    path = "consumables.png",
    px = 71,
    py = 95
}

CodexArcanum.pools.Consumables = {}

local function new_consumable(consumable)
    local key = "c_" .. CodexArcanum.prefix .. "_" .. consumable.key
    -- create fake
    if not CodexArcanum.config.modules.Consumables[key] then
        CodexArcanum.pools.Consumables[#CodexArcanum.pools.Consumables + 1] = CodexArcanum.FakeCard:extend{ class_prefix = "c" }{
            key = consumable.key or "default",
            loc_set = consumable.set,
            atlas = consumable.atlas or "consumables",
            pos = consumable.pos or { x = 0, y = 0 },
            loc_vars = function(self, info_queue, center)
                local loc = consumable.loc_vars and consumable.loc_vars(self, info_queue, center) or { vars = {} }
                loc.set = consumable.set
                return loc
            end,
            config = consumable.config or {},
        }
        return
    end

    CodexArcanum.pools.Consumables[#CodexArcanum.pools.Consumables + 1] = SMODS.Consumable{
        key = consumable.key,
        set = consumable.set,
        pos = consumable.pos or { x = 0, y = 0 },
        atlas = consumable.atlas or "consumables",
        loc_vars = consumable.loc_vars,
        config = consumable.config or {},
        cost = consumable.cost or 1,
        unlocked = true,
        discovered = false,
        can_use = consumable.can_use or function(card) return true end,
        use = consumable.use
    }
end

new_consumable{
    key = "seeker",
    set = "Tarot",
    pos = { x = 0, y = 0 },
    loc_vars = function(self, info_queue, center)
        local extra = CodexArcanum.utils.round_to_natural(center.ability.extra.alchemicals)
        return { vars = { extra, CodexArcanum.utils.loc_plural("card", extra) } }
    end,
    config = { extra = { alchemicals = 2 } },
    cost = 3,
    use = function(self, card, area, copier)
        local cards = math.min(CodexArcanum.utils.round_to_natural(card.ability.extra.alchemicals), G.consumeables.config.card_limit - #G.consumeables.cards)
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
                        local _card = create_card("Alchemical", G.consumeables, nil, nil, nil, nil, nil, "see")
                        _card:add_to_deck()
                        G.consumeables:emplace(_card)
                        used_tarot:juice_up(0.3, 0.5)
                    end
                    return true
                end
            })
        end
        delay(0.6)
    end
}

new_consumable{
    key = "philosopher_stone",
    set = "Spectral",
    pos = { x = 0, y = 1 },
    config = { extra = "alchemy_alchemical", select_cards = 1 },
    cost = 4,
    loc_vars = function(self, info_queue, center)
        info_queue[#info_queue + 1] = { key = "alchemy_alchemical_seal", set = "Other" }
        local select_cards = CodexArcanum.utils.max_highlighted(center)
        return { vars = { select_cards, CodexArcanum.utils.loc_plural("card", select_cards) } }
    end,
    can_use = function(self, card) return #G.hand.highlighted <= CodexArcanum.utils.max_highlighted(card) and #G.hand.highlighted > 0 end,
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
                    _card:set_seal(CodexArcanum.config.modules.Seals.alchemy_alchemical and card.ability.extra or "Gold", false, true)
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
