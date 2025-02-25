function CodexArcanum:description_loc_vars()
    return { shadow = true, scale = 1 / 0.75, text_colour = G.C.UI.TEXT_LIGHT, background_colour = G.C.CLEAR }
end

local function create_category_pane(args)
    table.insert(args.nodes, 1, {
        n = G.UIT.R,
        config = { align = "tm", padding = 0.2 },
        nodes = {
            { n = G.UIT.T, config = { text = args.text.title[1], shadow = true, scale = 0.5, colour = G.C.UI.TEXT_LIGHT } }
        }
    })
    return create_UIBox_generic_options{
        back_func = G.ACTIVE_MOD_UI and "openModUI_" .. G.ACTIVE_MOD_UI.id or "your_collection",
        contents = {
            {
                n = G.UIT.C,
                config = { r = 0.1, padding = 0.25, minw = 6, align = args.align or "tm", colour = args.colour or G.C.BLACK, outline = args.outline, outline_colour = args.outline_colour },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { r = 0.1, padding = 0.1, minw = 6, align = args.align or "tm", colour = args.colour or G.C.BLACK, outline = args.outline, outline_colour = args.outline_colour },
                        nodes = args.nodes
                    }
                }
            }
        }
    }
end

-- modified SMODS.card_collection_UIBox(pool, rows, args)
local function card_collection_UIBox(pool, rows, create_card, args)
    args = args or {}
    args.no_materialize = true
    args.area_type = args.area_type or "shop"
    args.w_mod = args.w_mod or 1
    args.h_mod = args.h_mod or 1
    args.card_scale = args.card_scale or 1
    local deck_tables = {}
    G.your_collection = {}
    local cards_per_page = 0
    local row_totals = {}
    for j = 1, #rows do
        if cards_per_page >= #pool and args.collapse_single_page then
            rows[j] = nil
        else
            row_totals[j] = cards_per_page
            cards_per_page = cards_per_page + rows[j]
            G.your_collection[j] = CardArea(
                G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                (args.w_mod * rows[j] + 0.25) * G.CARD_W,
                args.h_mod * G.CARD_H,
                { card_limit = rows[j], type = args.area_type or "title", highlight_limit = 0, collection = true }
            )
            table.insert(deck_tables,
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.07, no_fill = true },
                    nodes = {
                        { n = G.UIT.O, config = { object = G.your_collection[j] } }
                    }
                })
        end
    end
    local options = {}
    for i = 1, math.ceil(#pool / cards_per_page) do
        table.insert(options, localize("k_page") .. " " .. tostring(i) .. "/" .. tostring(math.ceil(#pool / cards_per_page)))
    end
    G.FUNCS.SMODS_card_collection_page = function(e)
        if not e or not e.cycle_config then return end
        for j = 1, #G.your_collection do
            for i = #G.your_collection[j].cards, 1, -1 do
                local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
                c:remove()
                c = nil
            end
        end
        for j = 1, #rows do
            for i = 1, rows[j] do
                local center = pool[i + row_totals[j] + (cards_per_page * (e.cycle_config.current_option - 1))]
                if not center then
                    break
                end
                local card = create_card(center, i, j, args)
                if not args.no_materialize then
                    card:start_materialize(nil, i > 1 or j > 1)
                end
                G.your_collection[j]:emplace(card)
            end
        end
        INIT_COLLECTION_CARD_ALERTS()
    end
    G.FUNCS.SMODS_card_collection_page{ cycle_config = { current_option = 1 } }
    local t = create_UIBox_generic_options{
        back_func = (args and args.back_func) or G.ACTIVE_MOD_UI and "openModUI_" .. G.ACTIVE_MOD_UI.id,
        snap_back = args.snap_back,
        infotip = args.infotip,
        contents = {
            { n = G.UIT.R, config = { align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables },
            (not args.hide_single_page or cards_per_page < #pool) and {
                n = G.UIT.R,
                config = { align = "cm" },
                nodes = {
                    create_option_cycle{ options = options, w = 4.5, cycle_shoulders = true, opt_callback = "SMODS_card_collection_page", current_option = 1, colour = G.C.RED, no_pips = true, focus_args = { snap_to = true, nav = "wide" } }
                }
            } or nil,
        }
    }
    return t
end

local function create_cards_disable_collection(mod_config, pool, rows, args)
    local create_card = function(center, i, j, _args)
        local key = center.key
        local params = (type(_args.params) == "table" and _args.params) or (type(_args.params) == "function") and _args.params(center) or {}
        params.toggle_config = function(card)
            mod_config[key] = not mod_config[key]
            return mod_config[key]
        end
        card = CodexArcanum.UICard(
            G.your_collection[j].T.x + G.your_collection[j].T.w / 2,
            G.your_collection[j].T.y,
            (_args.card_w or G.CARD_W) * _args.card_scale,
            (_args.card_h or G.CARD_H) * _args.card_scale, G.P_CARDS.empty,
            (_args.center and G.P_CENTERS[_args.center]) or center,
            mod_config,
            params
        )
        card.debuff = not mod_config[center.key]
        return card
    end
    return card_collection_UIBox(pool, rows, create_card, args)
end

local function config_category_button(category, menu, loc, color)
    local button = UIBox_button{
        label = loc and loc.title,
        id = { category = category, menu = menu },
        shadow = true,
        scale = 0.5,
        colour = color,
        minw = 4.5,
        minh = 0.75,
        button = "alchemy_config_button"
    }
    if loc and loc.tooltip then
        button.nodes[1].config.tooltip = { text = loc.tooltip }
    end
    return button
end

local UIDEF = {
    alchemicals = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_alchemicals")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("alchemicals", "disable", loc[2], G.C.RED),
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Alchemicals, CodexArcanum.pools.Alchemicals, { 4, 4 }, {
                h_mod = 0.95,
            })
        end
    },
    boosters = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_boosters")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("boosters", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.BoosterPacks, CodexArcanum.pools.BoosterPacks, { 4, 3 }, {
                h_mod = 1.3,
                card_scale = 1.27
            })
        end
    },
    jokers = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_jokers")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("jokers", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Jokers, CodexArcanum.pools.Jokers, { 4, 4 }, {
                h_mod = 0.95,
            })
        end
    },
    consumables = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_consumables")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("consumables", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Consumables, CodexArcanum.pools.Consumables, { 1, 1 }, {
                h_mod = 0.95,
            })
        end
    },
    decks = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_decks")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("decks", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Decks, CodexArcanum.pools.Decks, { 2 }, {
                h_mod = 0.95,
            })
        end
    },
    vouchers = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_vouchers")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("vouchers", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Vouchers, CodexArcanum.pools.Vouchers, { 2, 2 })
        end
    },
    tags = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_tags")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("tags", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Tags, CodexArcanum.pools.Tags, { 2 }, {
                w_mod = 0.5,
                h_mod = 0.5,
                card_w = 1,
                card_h = 1,
            })
        end
    },
    seals = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_seals")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("seals", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Seals, CodexArcanum.pools.Seals, { 2 }, {
                snap_back = true,
                hide_single_page = true,
                collapse_single_page = true,
                center = "c_base",
                h_mod = 0.95,
                card_args = {},
                params = function(center)
                    return { overlays = { center } }
                end
            })
        end,

    },
    stickers = {
        menu = function()
            local loc = localize("b_alchemy_ui_config_stickers")
            return create_category_pane{ text = loc[1], nodes = {
                config_category_button("stickers", "disable", loc[2], G.C.RED)
            } }
        end,
        disable = function()
            return create_cards_disable_collection(CodexArcanum.config.modules.Stickers, CodexArcanum.pools.Stickers, { 2 }, {
                snap_back = true,
                hide_single_page = true,
                collapse_single_page = true,
                center = "c_base",
                h_mod = 0.95,
                params = function(center)
                    return { overlays = { center } }
                end
            })
        end
    }
}

function G.FUNCS.alchemy_config_button(e)
    G.FUNCS.overlay_menu{ definition = UIDEF[e.config.id.category][e.config.id.menu]() }
end

CodexArcanum.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { r = 0.25, align = "tm", padding = 0.25, colour = G.C.BLACK, minw = 9 },
        nodes = {
            {
                n = G.UIT.C,
                config = { align = "tm", padding = 0.15, },
                nodes = {
                    config_category_button("alchemicals", "menu", localize("b_alchemy_ui_config_alchemicals")[1], G.C.SECONDARY_SET.Alchemical),
                    config_category_button("boosters", "menu", localize("b_alchemy_ui_config_boosters")[1], G.C.BOOSTER),
                    config_category_button("jokers", "menu", localize("b_alchemy_ui_config_jokers")[1], G.C.SECONDARY_SET.Joker),
                    config_category_button("consumables", "menu", localize("b_alchemy_ui_config_consumables")[1], G.C.SECONDARY_SET.Tarot),
                    config_category_button("decks", "menu", localize("b_alchemy_ui_config_decks")[1], HEX("3DAD82")),
                    config_category_button("vouchers", "menu", localize("b_alchemy_ui_config_vouchers")[1], G.C.SECONDARY_SET.Voucher),
                    config_category_button("tags", "menu", localize("b_alchemy_ui_config_tags")[1], HEX("878DC6")),
                    config_category_button("seals", "menu", localize("b_alchemy_ui_config_seals")[1], G.C.SECONDARY_SET.Planet),
                    config_category_button("stickers", "menu", localize("b_alchemy_ui_config_stickers")[1], HEX("ffc75985"))
                }
            }
        }
    }
end
