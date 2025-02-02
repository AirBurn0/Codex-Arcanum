SMODS.Atlas{
    key = "voucher_atlas",
    path = "ca_voucher_atlas.png",
    px = 71,
    py = 95
}

-- kinda default constructor
local function new_voucher(voucher)
    -- create joker
    SMODS.Voucher {
        key = voucher.key,
        pos = voucher.pos or { x = 0, y = 0 },
        atlas = voucher.atlas or "voucher_atlas",
        loc_vars = voucher.loc_vars, 
        config = voucher.config or {},
        requires = voucher.requires,
        cost = voucher.cost or 10,
        discovered = false,
        unlocked = not voucher.locked,
        redeem = voucher.redeem or function() end
    }
end

new_voucher{
    key = "mortar_and_pestle",
    config = { extra = 1 },
    pos = { x = 0, y = 0 },
    redeem = function(self, center)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.consumeables.config.card_limit = (G.consumeables.config.card_limit or 0) + (center and center.ability.extra or self.config.extra)
                return true
            end
        }))
    end
}

new_voucher{
    key = "cauldron",
    config = { extra = 1 },
    pos = { x = 0, y = 1 },
    requires = { "v_alchemy_mortar_and_pestle" }
}

new_voucher{
    key = "alchemical_merchant",
    config = { extra = 4.8 },
    pos = { x = 1, y = 0 },
    redeem = function(self, center)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.alchemical_rate = center and center.ability.extra or self.config.extra
                return true
            end 
        }))
    end
}

new_voucher{
    key = "alchemical_tycoon",
    config = { extra = 4.8 * 2 },
    pos = { x = 1, y = 1 },
    requires = { "v_alchemy_alchemical_merchant" },
    redeem = function(self, center)
        G.E_MANAGER:add_event(Event({ 
            func = function()
                G.GAME.alchemical_rate = center and center.ability.extra or self.config.extra
                return true
            end 
        }))
    end
}