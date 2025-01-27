function CodexArcanum.INIT.CA_Others()
    SMODS.Sprite:new("ca_others_atlas", CodexArcanum.mod.path, "ca_others_atlas.png", 71, 95, "asset_atli"):register();
    SMODS.Sprite:new("ca_decks_atlas", CodexArcanum.mod.path, "ca_decks_atlas.png", 71, 95, "asset_atli"):register();

    -- Mortar and Pestle
    local v_mortar_and_pestle_def = {
        name = "Mortar and Pestle",
        text = {
            "{C:attention}+1{} consumable slot",
        }
    }

    local mortar_and_pestle = SMODS.Voucher:new("Mortar and Pestle", "mortar_and_pestle", { extra = 1 }, { x = 0, y = 2 }, v_mortar_and_pestle_def, 10, true, false, true, nil, "ca_others_atlas")
    mortar_and_pestle:register()

    -- Cauldron
    local v_cauldron_def = {
        name = "Cauldron",
        text = {
            "{C:alchemical}Alchemical{} cards may come with",
            "the {C:dark_edition}Negative{} Edition"
        }
    }

    local cauldron = SMODS.Voucher:new("Cauldron", "cauldron", {}, { x = 0, y = 3 }, v_cauldron_def, 10, true, false, true, { "v_mortar_and_pestle" }, "ca_others_atlas")
    cauldron:register()

    -- Alchemical Merchant
    local v_alchemical_merchant_def = {
        name = "Alchemical Merchant",
        text = {
            "{C:alchemical}Alchemical{} cards can",
            "appear in the shop"
        }
    }

    local alchemical_merchant = SMODS.Voucher:new("Alchemical Merchant", "alchemical_merchant", { extra = 4.8 }, { x = 1, y = 2 }, v_alchemical_merchant_def, 10, true, false, true, nil, "ca_others_atlas")
    alchemical_merchant:register()

    function SMODS.Vouchers.v_alchemical_merchant.redeem(center)
        G.E_MANAGER:add_event(Event({ func = function()
            G.GAME.alchemical_rate = center.extra
            return true
        end }))
    end

    -- Alchemical Tycoon
    local v_alchemical_tycoon_def = {
        name = "Alchemical Tycoon",
        text = {
            "{C:alchemical}Alchemical{} cards appear",
            "{C:attention}2X{} more frequently",
            "in the shop"
        }
    }

    local alchemical_tycoon = SMODS.Voucher:new("Alchemical Tycoon", "alchemical_tycoon", { extra = 4.8 * 2 }, { x = 1, y = 3 }, v_alchemical_tycoon_def, 10, true, false, true, { "v_alchemical_merchant" }, "ca_others_atlas")
    alchemical_tycoon:register()

    function SMODS.Vouchers.v_alchemical_tycoon.redeem(center)
        G.E_MANAGER:add_event(Event({ 
            func = function()
                G.GAME.alchemical_rate = center.extra
                return true
            end 
        }))
    end

    -- Philosopher's Deck
    local philosopher_deck_def = {
        name = "Philosopher's Deck",
        text = {
            "Start run with the",
            "{C:tarot,T:v_alchemical_merchant}Alchemical Merchant{} voucher",
            "and a copy of {C:tarot,T:c_seeker}The Seeker{}"
        },
    }
    local philosopher_deck = SMODS.Deck:new("Philosopher's Deck", "philosopher", { vouchers = { 'v_alchemical_merchant' }, consumables = { 'c_seeker' }, atlas = "ca_decks_atlas" }, { x = 0, y = 0 }, philosopher_deck_def)
    philosopher_deck:register()

    -- Herbalist's Deck
    local herbalist_deck_def = { 
        name = "Herbalist's Deck", 
        text = { 
            "Start run with the", 
            "{C:tarot,T:v_mortar_and_pestle}Mortar and Pestle{} voucher.", 
            "Gain an {C:alchemical}Alchemical{} card before", 
            "each {C:attention}Boss Blind{}" 
        } 
    }

    local herbalist_deck = SMODS.Deck:new("Herbalist's Deck", "herbalist", { vouchers = { 'v_mortar_and_pestle' }, atlas = "ca_decks_atlas" }, { x = 1, y = 0 }, herbalist_deck_def)
    herbalist_deck:register()

    local tag_elemental_def = {
        name = "Elemental Tag",
        text = {
            "Gives a free",
            "{C:alchemical}Mega Alchemy Pack{}"
        }
    }

     -- Elemental Tag
    local tag_elemental = SMODS.Tag:new("Elemental Tag", "elemental", { type = 'new_blind_choice' }, { x = 0, y = 0 }, tag_elemental_def)
    SMODS.Sprite:new("tag_elemental", CodexArcanum.mod.path, "tag_elemental.png", 34, 34, "asset_atli"):register();
    tag_elemental:register()

    function SMODS.Tags.tag_elemental.apply(tag, context)
        if context.type == 'new_blind_choice' then
            local lock = tag.ID
            G.CONTROLLER.locks[lock] = true
            tag:yep('+', G.C.PURPLE, 
                function()
                    local key = 'p_alchemy_mega_1'
                    local card = Card(G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2, G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2, G.CARD_W * 1.27, G.CARD_H * 1.27, G.P_CARDS.empty, G.P_CENTERS[key], { bypass_discovery_center = true, bypass_discovery_ui = true })
                    card.cost = 0
                    card.from_tag = true
                    G.FUNCS.use_card({ config = { ref_table = card } })
                    card:start_materialize()
                    G.CONTROLLER.locks[lock] = nil
                    return true
                end
            )
            tag.triggered = true
            return true
        end
    end

    -- The Seeker
    local tarot_seeker_def = {
        name = "The Seeker",
        text = {
            "Creates up to {C:attention}#1#",
            "random {C:alchemical}Alchemical{} cards",
            "{C:inactive}(Must have room)"
        }
    }

    local tarot_seeker = SMODS.Tarot:new("The Seeker", "seeker", { alchemicals = 2 }, { x = 0, y = 0 }, tarot_seeker_def, 3, 1.0, "Round Bonus", true, false, "ca_others_atlas")
    tarot_seeker:register()

    function SMODS.Tarots.c_seeker.loc_def(card)
        return { card.config.alchemicals }
    end

    function SMODS.Tarots.c_seeker.can_use(card)
        return #G.consumeables.cards < G.consumeables.config.card_limit or card.area == G.consumeables
    end

    function SMODS.Tarots.c_seeker.use(card, area, copier)
        local used_tarot = (copier or card)
        for i = 1, math.min(card.ability.consumeable.alchemicals, G.consumeables.config.card_limit - #G.consumeables.cards) do
            G.E_MANAGER:add_event(Event({ 
                trigger = 'after', 
                delay = 0.4, 
                func = function()
                    if G.consumeables.config.card_limit > #G.consumeables.cards then
                        play_sound('timpani')
                        local card = create_card('Alchemical', G.consumeables, nil, nil, nil, nil, nil, 'see')
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                        used_tarot:juice_up(0.3, 0.5)
                    end
                    return true
                end 
            }))
        end
        delay(0.6)
    end

    -- Philosopher's Stone
    local c_philosopher_stone_def = {
        name = "Philosopher's Stone",
        text = {
            "{C:attention}Paints background{}"
        }
    }

    local spectral_philosopher_stone = SMODS.Spectral:new("Philosopher's Stone", "philosopher_stone", {}, { x = 0, y = 1 }, c_philosopher_stone_def, 4, true, false, "ca_others_atlas")
    spectral_philosopher_stone:register();

    function SMODS.Spectrals.c_philosopher_stone.can_use(card)
        if G.STATE == G.STATES.SELECTING_HAND then
            card.config.in_booster = false
            return true
        end

        if G.STATE == G.STATES.STANDARD_PACK or G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.PLANET_PACK or G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.BUFFOON_PACK then
            card.config.in_booster = true
            return true
        end
    end

    function SMODS.Spectrals.c_philosopher_stone.use(card)
        G.deck.config.philosopher = true
    end

end