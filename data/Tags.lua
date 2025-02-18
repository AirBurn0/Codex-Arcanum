SMODS.Atlas{
    key = "tags",
    path = "tags.png",
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
    atlas = "tags"
}
