SMODS.Atlas{
    key = "stickers",
    path = "stickers.png",
    px = 71,
    py = 95
}

CodexArcanum.pools.Stickers = {}

-- kinda default constructor
local function new_sticker(sticker)
    local key = CodexArcanum.prefix .. "_" .. sticker.key
    -- create fake
    if not CodexArcanum.config.modules.Stickers[key] then
        CodexArcanum.pools.Stickers[#CodexArcanum.pools.Stickers + 1] = CodexArcanum.FakeCard{
            key = sticker.key or "default",
            atlas = sticker.atlas or "stickers",
            pos = sticker.pos or { x = 4, y = 4 },
            loc_vars = sticker.loc_vars,
            apply = function(self, card, val)
                card.ability[self.key] = val
            end
        }
        return
    end

    CodexArcanum.pools.Stickers[#CodexArcanum.pools.Stickers + 1] = SMODS.Sticker{
        key = sticker.key,
        default_compat = false,
        sets = sticker.sets,
        badge_colour = sticker.badge_colour,
        order = sticker.order,
        pos = sticker.pos,
        atlas = sticker.atlas or "stickers",
        loc_vars = sticker.loc_vars,
        apply = sticker.apply,
        calculate = sticker.calculate
    }
end

-- Synthesized
new_sticker{
    key = "synthesized",
    sets = { Joker = true, Default = true, Enhanced = true },
    badge_colour = HEX("C09D75"),
    order = 17,
    pos = { x = 0, y = 0 },
    loc_vars = function(self, info_queue, center)
        local default = CodexArcanum.utils.synthesized_rounds(self, center)
        local extra = center.ability[self.key]
        return { vars = { default, CodexArcanum.utils.loc_plural("round", default), (extra and type(extra) == "table" and extra.rounds) or default } }
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
        rounds = CodexArcanum.utils.synthesized_rounds(self, card)
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
                if center and center.undo then
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
