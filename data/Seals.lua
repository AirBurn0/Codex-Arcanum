SMODS.Atlas{
    key = "seals",
    path = "seals.png",
    px = 71,
    py = 95
}

CodexArcanum.pools.Seals = {}

-- kinda default constructor
local function new_seal(seal)
    local key = CodexArcanum.prefix .. "_" .. seal.key
    -- create fake
    if not CodexArcanum.config.modules.Seals[key] then
        CodexArcanum.pools.Seals[#CodexArcanum.pools.Seals + 1] = CodexArcanum.FakeCard{
            key = seal.key or "default",
            atlas = seal.atlas or "seals",
            pos = seal.pos or { x = 4, y = 4 },
            loc_vars = seal.loc_vars
        }
        return
    end

    CodexArcanum.pools.Seals[#CodexArcanum.pools.Seals + 1] = SMODS.Seal{
        key = seal.key,
        badge_colour = seal.badge_colour,
        pos = seal.pos,
        atlas = seal.atlas or "seals",
        weight = seal.weight or 1,
        calculate = seal.calculate
    }
end

local function is_card_in(card, array)
    for k, v in ipairs(array) do
        if (v == card) then
            return true
        end
    end
    return false
end

-- Alchemical Seal
new_seal{
    key = "alchemical",
    badge_colour = HEX("C09D75"),
    pos = { x = 1, y = 0 },
    calculate = function(self, card, context)
        local drawn = context.hand_drawn or context.other_drawn
        if context.cardarea ~= G.hand or not drawn or #G.consumeables.cards + G.GAME.consumeable_buffer >= G.consumeables.config.card_limit or not is_card_in(card, drawn) then
            return
        end
        G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
        G.E_MANAGER:add_event(Event{
            trigger = "before",
            func = function()
                local _card = CodexArcanum.utils.create_alchemical()
                _card:add_to_deck()
                G.consumeables:emplace(_card)
                G.GAME.consumeable_buffer = 0 -- event can be interrupted
                return true
            end
        })
        return { message = localize("p_plus_alchemical"), colour = G.C.SECONDARY_SET.Alchemical }
    end,
}
