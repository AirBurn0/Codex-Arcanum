SMODS.Atlas({
    key = 'ca_booster_atlas',
    path = 'ca_booster_atlas.png',
    px = '71',
    py = '95'
})

function create_alchemical_booster(booster) 
    SMODS.Booster {
        key = booster.key,
        loc_txt = {
            group_name = "Alchemy Pack",
            name = (booster.name and booster.name.." Alchemy Pack") or "Alchemy Pack",
            text = {
                "Choose {C:attention}#1#{} of up to",
                "{C:attention}#2#{C:alchemical} Alchemical{} cards to",
                "add to your consumeables"
            }
        },
        kind = "Alchemical",
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.choose, card.ability.extra } }
        end,
        config = { extra = booster.extra, choose = booster.choose, name = "Alchemical" },
        pos = booster.pos,
        atlas = 'ca_booster_atlas',
        weight = booster.weight or 1,
        cost = booster.cost or 4,
        in_pool = function() 
            return true 
        end,
        create_card = function(self, card)
            return create_alchemical()
        end
    }
end

function CodexArcanum.INIT.CA_BoosterPacks()
    G.localization.misc.dictionary["k_alchemy_pack"] = "Alchemy Pack"

    for i = 1, 4 do
        create_alchemical_booster({ key = "alchemy_normal_"..i, choose = 1, extra = 2, pos = { x = i - 1, y = 0 } })
    end
    for i = 1, 2 do
        create_alchemical_booster({ key = "alchemy_jumbo_"..i, name = "Jumbo", choose = 1, extra = 4, pos = { x = i - 1, y = 1 }, cost = 6 })
    end
    create_alchemical_booster({ key = "alchemy_mega_1", name = "Mega", choose = 2, extra = 4, pos = { x = 2, y = 1 }, cost = 8, weight = 0.25 })

end
