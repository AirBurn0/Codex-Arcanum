--class
CodexArcanum.UICard = Moveable:extend()

--class methods
function CodexArcanum.UICard:init(X, Y, W, H, card, center, mod_config, params)
    self.params = (type(params) == "table") and params or {}
    Moveable.init(self, X, Y, W, H)
    self.CT = self.VT
    self.config = {
        card = card or {},
        center = center,
        mod_config = mod_config,
        overlays = self.params.overlays
    }
    self.tilt_var = { mx = 0, my = 0, dx = 0, dy = 0, amt = 0 }
    self.ambient_tilt = 0.2
    self.states.collide.can = true
    self.states.hover.can = true
    self.states.drag.can = true
    self.states.click.can = true
    self.playing_card = self.params.playing_card
    G.sort_id = (G.sort_id or 0) + 1
    self.sort_id = G.sort_id
    if self.params.viewed_back then
        self.back = "viewed_back"
    else
        self.back = "selected_back"
    end
    self.no_ui = self.config.card and self.config.card.no_ui
    self.children = {}
    self.base_cost = 0
    self.extra_cost = 0
    self.cost = 0
    self.sell_cost = 0
    self.sell_cost_label = 0
    self.children.shadow = Moveable(0, 0, 0, 0)
    self.unique_val = 1 - self.ID / 1603301
    self.edition = nil
    self.zoom = true
    self:set_ability(center, true)
    self:set_base(card, true)
    self.facing = "front"
    self.sprite_facing = "front"
    self.flipping = nil
    self.area = nil
    self.highlighted = false
    self.click_timeout = 0.3
    self.T.scale = 0.95
    self.rank = nil
    self.added_to_deck = nil
    if self.children.front then self.children.front.VT.w = 0 end
    self.children.back.VT.w = 0
    self.children.center.VT.w = 0
    if self.children.front then
        self.children.front.parent = self;
        self.children.front.layered_parallax = nil
    end
    self.children.back.parent = self
    self.children.back.layered_parallax = nil
    self.children.center.parent = self
    self.children.center.layered_parallax = nil
    self.states.focus.can = false
    self.states.drag.can = false
    self.children.alert = nil
end

function CodexArcanum.UICard:set_base(card, initial)
    card = card or {}

    self.config.card = card
    for k, v in pairs(G.P_CARDS) do
        if card == v then self.config.card_key = k end
    end

    if next(card) then
        self:set_sprites(nil, card)
    end

    local suit_base_nominal_original = nil
    if self.base and self.base.suit_nominal_original then suit_base_nominal_original = self.base.suit_nominal_original end
    self.base = {
        name = self.config.card.name,
        suit = self.config.card.suit,
        value = self.config.card.value,
        nominal = 0,
        suit_nominal = 0,
        face_nominal = 0,
        colour = G.C.SUITS[self.config.card.suit],
        times_played = 0
    }

    if self.base.value == "2" then
        self.base.nominal = 2; self.base.id = 2
    elseif self.base.value == "3" then
        self.base.nominal = 3; self.base.id = 3
    elseif self.base.value == "4" then
        self.base.nominal = 4; self.base.id = 4
    elseif self.base.value == "5" then
        self.base.nominal = 5; self.base.id = 5
    elseif self.base.value == "6" then
        self.base.nominal = 6; self.base.id = 6
    elseif self.base.value == "7" then
        self.base.nominal = 7; self.base.id = 7
    elseif self.base.value == "8" then
        self.base.nominal = 8; self.base.id = 8
    elseif self.base.value == "9" then
        self.base.nominal = 9; self.base.id = 9
    elseif self.base.value == "10" then
        self.base.nominal = 10; self.base.id = 10
    elseif self.base.value == "Jack" then
        self.base.nominal = 10; self.base.face_nominal = 0.1; self.base.id = 11
    elseif self.base.value == "Queen" then
        self.base.nominal = 10; self.base.face_nominal = 0.2; self.base.id = 12
    elseif self.base.value == "King" then
        self.base.nominal = 10; self.base.face_nominal = 0.3; self.base.id = 13
    elseif self.base.value == "Ace" then
        self.base.nominal = 11; self.base.face_nominal = 0.4; self.base.id = 14
    end

    if initial then self.base.original_value = self.base.value end

    if self.base.suit == "Diamonds" then
        self.base.suit_nominal = 0.01; self.base.suit_nominal_original = suit_base_nominal_original or 0.001
    elseif self.base.suit == "Clubs" then
        self.base.suit_nominal = 0.02; self.base.suit_nominal_original = suit_base_nominal_original or 0.002
    elseif self.base.suit == "Hearts" then
        self.base.suit_nominal = 0.03; self.base.suit_nominal_original = suit_base_nominal_original or 0.003
    elseif self.base.suit == "Spades" then
        self.base.suit_nominal = 0.04; self.base.suit_nominal_original = suit_base_nominal_original or 0.004
    end

    if not initial then G.GAME.blind:debuff_card(self) end
    if self.playing_card and not initial then check_for_unlock{ type = "modify_deck" } end
end

function CodexArcanum.UICard:set_sprites(center, front)
    if front then
        local atlas, pos = get_front_spriteinfo(front)
        if self.children.front then
            self.children.front.atlas = atlas
            self.children.front:set_sprite_pos(pos)
        else
            self.children.front = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, atlas, pos)
            self.children.front.states.hover = self.states.hover
            self.children.front.states.click = self.states.click
            self.children.front.states.drag = self.states.drag
            self.children.front.states.collide.can = false
            self.children.front:set_role{ major = self, role_type = "Glued", draw_major = self }
        end
    end
    if not center then
        return
    end
    local atlas_key = center.atlas or center.set_ability
    local pos = atlas_key and center.pos or { x = 1, y = 0 }
    atlas_key = atlas_key or "centers"
    if self.children.center then
        self.children.center.atlas = G.ASSET_ATLAS[atlas_key]
        self.children.center:set_sprite_pos(pos)
    else
        self.children.center = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, G.ASSET_ATLAS[atlas_key], pos)
        self.children.center.states.hover = self.states.hover
        self.children.center.states.click = self.states.click
        self.children.center.states.drag = self.states.drag
        self.children.center.states.collide.can = false
        self.children.center:set_role{ major = self, role_type = "Glued", draw_major = self }
    end

    if center.soul_pos then
        self.children.floating_sprite = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, G.ASSET_ATLAS["Joker"], self.config.center.soul_pos)
        self.children.floating_sprite.role.draw_major = self
        self.children.floating_sprite.states.hover.can = false
        self.children.floating_sprite.states.click.can = false
    end

    if not self.children.back then
        self.children.back = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, G.ASSET_ATLAS["centers"], self.params.bypass_back or (self.playing_card and G.GAME[self.back].pos or G.P_CENTERS["b_red"].pos))
        self.children.back.states.hover = self.states.hover
        self.children.back.states.click = self.states.click
        self.children.back.states.drag = self.states.drag
        self.children.back.states.collide.can = false
        self.children.back:set_role{ major = self, role_type = "Glued", draw_major = self }
    end

    if self.config.overlays then
        for k, v in ipairs(self.config.overlays) do
            local overlay = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, G.ASSET_ATLAS[v.atlas], v.pos)
            self.children["overlay_" .. k] = overlay
            overlay.states.hover = self.states.hover
            overlay.states.click = self.states.click
            overlay.states.drag = self.states.drag
            overlay.states.collide.can = false
            overlay:set_role{ major = self, role_type = "Glued", draw_major = self }
        end
    end
end

function CodexArcanum.UICard:set_ability(center, initial, delay_sprites)
    self.config.center = center
    for k, v in pairs(G.P_CENTERS) do
        if center == v then self.config.center_key = k end
    end
    if self.params.discover and not center.discovered then
        unlock_card(center)
        discover_card(center)
    end
    if delay_sprites then
        G.E_MANAGER:add_event(Event{
            func = function()
                if not self.REMOVED then
                    self:set_sprites(center)
                end
                return true
            end
        })
    else
        self:set_sprites(center)
    end
    self.ability = {
        name = center.name,
        effect = center.effect,
        set = center.set,
        mult = center.config.mult or 0,
        h_mult = center.config.h_mult or 0,
        h_x_mult = center.config.h_x_mult or 0,
        h_dollars = center.config.h_dollars or 0,
        p_dollars = center.config.p_dollars or 0,
        t_mult = center.config.t_mult or 0,
        t_chips = center.config.t_chips or 0,
        x_mult = center.config.Xmult or 1,
        h_size = center.config.h_size or 0,
        d_size = center.config.d_size or 0,
        extra = copy_table(center.config.extra) or nil,
        extra_value = 0,
        type = center.config.type or "",
        order = center.order or nil,
        forced_selection = self.ability and self.ability.forced_selection or nil,
        perma_bonus = self.ability and self.ability.perma_bonus or 0,
    }
    self.ability.bonus = (self.ability.bonus or 0) + (center.config.bonus or 0)
    if center.consumeable then
        self.ability.consumeable = center.config
    end
    self.base_cost = center.cost or 1
    self.ability.hands_played_at_create = G.GAME and G.GAME.hands_played or 0
    self.label = center.label or self.config.card.label or self.ability.set or self.ability.name
    if not initial then
        G.GAME.blind:debuff_card(self)
    end
end

function CodexArcanum.UICard:update_alert()

end

function CodexArcanum.UICard:remove_from_deck()

end

function CodexArcanum.UICard:get_id()
    if self.ability.effect == "Stone Card" and not self.vampired then
        return -math.random(100, 1000000)
    end
    return self.base.id
end

function CodexArcanum.UICard:set_card_area(area)
    self.area = area
    self.parent = area
    self.layered_parallax = area.layered_parallax
end

function CodexArcanum.UICard:remove_from_area()
    self.area = nil
    self.parent = nil
    self.layered_parallax = { x = 0, y = 0 }
end

function CodexArcanum.UICard:align()
    if self.children.floating_sprite then
        self.children.floating_sprite.T.y = self.T.y
        self.children.floating_sprite.T.x = self.T.x
        self.children.floating_sprite.T.r = self.T.r
    end
    if self.children.focused_ui then
        self.children.focused_ui:set_alignment()
    end
end

function CodexArcanum.UICard:flip()
    if self.facing == "front" then
        self.flipping = "f2b"
        self.facing = "back"
        self.pinch.x = true
    elseif self.facing == "back" then
        self.ability.wheel_flipped = nil
        self.flipping = "b2f"
        self.facing = "front"
        self.pinch.x = true
    end
end

function CodexArcanum.UICard:update(dt)
    if self.flipping == "f2b" then
        if self.sprite_facing == "front" or true then
            if self.VT.w <= 0 then
                self.sprite_facing = "back"
                self.pinch.x = false
            end
        end
    end
    if self.flipping == "b2f" then
        if self.sprite_facing == "back" or true then
            if self.VT.w <= 0 then
                self.sprite_facing = "front"
                self.pinch.x = false
            end
        end
    end
    if not self.states.focus.is and self.children.focused_ui then
        self.children.focused_ui:remove()
        self.children.focused_ui = nil
    end
end

function CodexArcanum.UICard:hard_set_T(X, Y, W, H)
    local x = (X or self.T.x)
    local y = (Y or self.T.y)
    local w = (W or self.T.w)
    local h = (H or self.T.h)
    Moveable.hard_set_T(self, x, y, w, h)
    if self.children.front then self.children.front:hard_set_T(x, y, w, h) end
    self.children.back:hard_set_T(x, y, w, h)
    self.children.center:hard_set_T(x, y, w, h)
end

function CodexArcanum.UICard:move(dt)
    Moveable.move(self, dt)
    if self.children.h_popup then
        self.children.h_popup:set_alignment(self:align_h_popup())
    end
end

function CodexArcanum.UICard:juice_up(scale, rot_amount)
    local rot_amt = rot_amount and 0.4 * (math.random() > 0.5 and 1 or -1) * rot_amount or (math.random() > 0.5 and 1 or -1) * 0.16
    scale = scale and scale * 0.4 or 0.11
    Moveable.juice_up(self, scale, rot_amt)
end

function CodexArcanum.UICard:draw(layer)
    layer = layer or "both"
    self.hover_tilt = 1
    if not self.states.visible then return end
    if (layer == "shadow" or layer == "both") then
        self.ARGS.send_to_shader = self.ARGS.send_to_shader or {}
        self.ARGS.send_to_shader[1] = math.min(self.VT.r * 3, 1) + G.TIMERS.REAL / (28) + (self.juice and self.juice.r * 20 or 0) + self.tilt_var.amt
        self.ARGS.send_to_shader[2] = G.TIMERS.REAL

        for k, v in pairs(self.children) do
            if v.VT then
                v.VT.scale = self.VT.scale
            end
        end
    end
    G.shared_shadow = self.sprite_facing == "front" and self.children.center or self.children.back
    --Draw the shadow
    if not self.no_shadow and G.SETTINGS.GRAPHICS.shadows == "On" and (layer == "shadow" or layer == "both") then
        self.shadow_height = 0 * (0.08 + 0.4 * math.sqrt(self.velocity.x ^ 2)) + ((((self.highlighted and self.area == G.play) or self.states.drag.is) and 0.35) or (self.area and self.area.config.type == "title_2") and 0.04 or 0.1)
        G.shared_shadow:draw_shader("dissolve", self.shadow_height)
    end

    if (layer == "card" or layer == "both") and self.area ~= G.hand then
        if self.children.focused_ui then self.children.focused_ui:draw() end
    end

    if (layer ~= "card" and layer ~= "both") then
        return
    end
    -- for all hover/tilting:
    self.tilt_var = self.tilt_var or { mx = 0, my = 0, dx = self.tilt_var.dx or 0, dy = self.tilt_var.dy or 0, amt = 0 }
    local tilt_factor = 0.3
    if self.states.focus.is then
        self.tilt_var.mx, self.tilt_var.my = G.CONTROLLER.cursor_position.x + self.tilt_var.dx * self.T.w * G.TILESCALE * G.TILESIZE, G.CONTROLLER.cursor_position.y + self.tilt_var.dy * self.T.h * G.TILESCALE * G.TILESIZE
        self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1 + self.tilt_var.dx + self.tilt_var.dy - 1) * tilt_factor
    elseif self.states.hover.is then
        self.tilt_var.mx, self.tilt_var.my = G.CONTROLLER.cursor_position.x, G.CONTROLLER.cursor_position.y
        self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1) * tilt_factor
    elseif self.ambient_tilt then
        local tilt_angle = G.TIMERS.REAL * (1.56 + (self.ID / 1.14212) % 1) + self.ID / 1.35122
        self.tilt_var.mx = ((0.5 + 0.5 * self.ambient_tilt * math.cos(tilt_angle)) * self.VT.w + self.VT.x + G.ROOM.T.x) * G.TILESIZE * G.TILESCALE
        self.tilt_var.my = ((0.5 + 0.5 * self.ambient_tilt * math.sin(tilt_angle)) * self.VT.h + self.VT.y + G.ROOM.T.y) * G.TILESIZE * G.TILESCALE
        self.tilt_var.amt = self.ambient_tilt * (0.5 + math.cos(tilt_angle)) * tilt_factor
    end
    --Any particles
    if self.children.particles then
        self.children.particles:draw()
    end

    if self.vortex then
        if self.facing == "back" then
            self.children.back:draw_shader("vortex")
        else
            self.children.center:draw_shader("vortex")
            if self.children.front then
                self.children.front:draw_shader("vortex")
            end
        end

        love.graphics.setShader()
    elseif self.sprite_facing == "front" then
        --Draw the main part of the card
        if (self.edition and self.edition.negative) or (self.ability.name == "Antimatter") then
            self.children.center:draw_shader("negative", nil, self.ARGS.send_to_shader)
            if self.children.front and self.ability.effect ~= "Stone Card" then
                self.children.front:draw_shader("negative", nil, self.ARGS.send_to_shader)
            end
        elseif not self.greyed then
            self.children.center:draw_shader("dissolve")
            --If the card has a front, draw that next
            if self.children.front and self.ability.effect ~= "Stone Card" then
                self.children.front:draw_shader("dissolve")
            end
        end
        for k, v in pairs(self.children) do
            if string.find(k, "overlay_") then
                v.role.draw_major = self
                v:draw_shader('dissolve', nil, nil, nil, self.children.center)
            end
        end

        --If the card has any edition, add that here
        if self.edition or (self.ability.set == "Spectral") or self.debuff or self.greyed or (self.ability.name == "The Soul") or (self.ability.set == "Voucher") or (self.ability.set == "Booster") or self.config.center.soul_pos then
            if (self.ability.set == "Voucher") and (self.ability.name ~= "Antimatter") then
                self.children.center:draw_shader("voucher", nil, self.ARGS.send_to_shader)
            end
            if self.ability.set == "Booster" or self.ability.set == "Spectral" then
                self.children.center:draw_shader("booster", nil, self.ARGS.send_to_shader)
            end
            if self.edition and self.edition.holo then
                self.children.center:draw_shader("holo", nil, self.ARGS.send_to_shader)
                if self.children.front then
                    self.children.front:draw_shader("holo", nil, self.ARGS.send_to_shader)
                end
            end
            if self.edition and self.edition.foil then
                self.children.center:draw_shader("foil", nil, self.ARGS.send_to_shader)
                if self.children.front then
                    self.children.front:draw_shader("foil", nil, self.ARGS.send_to_shader)
                end
            end
            if self.edition and self.edition.polychrome then
                self.children.center:draw_shader("polychrome", nil, self.ARGS.send_to_shader)
                if self.children.front then
                    self.children.front:draw_shader("polychrome", nil, self.ARGS.send_to_shader)
                end
            end
            if (self.edition and self.edition.negative) or (self.ability.name == "Antimatter") then
                self.children.center:draw_shader("negative_shine", nil, self.ARGS.send_to_shader)
            end
            if self.ability.name == "The Soul" then
                local scale_mod = 0.05 + 0.05 * math.sin(1.8 * G.TIMERS.REAL) + 0.07 * math.sin((G.TIMERS.REAL - math.floor(G.TIMERS.REAL)) * math.pi * 14) * (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 3
                local rotate_mod = 0.1 * math.sin(1.219 * G.TIMERS.REAL) + 0.07 * math.sin((G.TIMERS.REAL) * math.pi * 5) * (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 2
                G.shared_soul.role.draw_major = self
                G.shared_soul:draw_shader("dissolve", 0, nil, nil, self.children.center, scale_mod, rotate_mod, nil, 0.1 + 0.03 * math.sin(1.8 * G.TIMERS.REAL), nil, 0.6)
                G.shared_soul:draw_shader("dissolve", nil, nil, nil, self.children.center, scale_mod, rotate_mod)
            end

            if self.config.center.soul_pos then
                local scale_mod = 0.07 + 0.02 * math.sin(1.8 * G.TIMERS.REAL) + 0.00 * math.sin((G.TIMERS.REAL - math.floor(G.TIMERS.REAL)) * math.pi * 14) * (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 3
                local rotate_mod = 0.05 * math.sin(1.219 * G.TIMERS.REAL) + 0.00 * math.sin((G.TIMERS.REAL) * math.pi * 5) * (1 - (G.TIMERS.REAL - math.floor(G.TIMERS.REAL))) ^ 2

                if self.ability.name == "Hologram" then
                    self.hover_tilt = self.hover_tilt * 1.5
                    self.children.floating_sprite:draw_shader("hologram", nil, self.ARGS.send_to_shader, nil, self.children.center, 2 * scale_mod, 2 * rotate_mod)
                    self.hover_tilt = self.hover_tilt / 1.5
                else
                    self.children.floating_sprite:draw_shader("dissolve", 0, nil, nil, self.children.center, scale_mod, rotate_mod, nil, 0.1 + 0.03 * math.sin(1.8 * G.TIMERS.REAL), nil, 0.6)
                    self.children.floating_sprite:draw_shader("dissolve", nil, nil, nil, self.children.center, scale_mod, rotate_mod)
                end
            end
            if self.debuff then
                self.children.center:draw_shader("debuff", nil, self.ARGS.send_to_shader)
                if self.children.front then
                    self.children.front:draw_shader("debuff", nil, self.ARGS.send_to_shader)
                end
            end
            if self.greyed then
                self.children.center:draw_shader("played", nil, self.ARGS.send_to_shader)
                if self.children.front then
                    self.children.front:draw_shader("played", nil, self.ARGS.send_to_shader)
                end
            end
        end
    elseif self.sprite_facing == "back" then
        local overlay = G.C.WHITE
        if self.area and self.area.config.type == "deck" and self.rank > 3 then
            self.back_overlay = self.back_overlay or {}
            self.back_overlay[1] = 0.5 + ((#self.area.cards - self.rank) % 7) / 50
            self.back_overlay[2] = 0.5 + ((#self.area.cards - self.rank) % 7) / 50
            self.back_overlay[3] = 0.5 + ((#self.area.cards - self.rank) % 7) / 50
            self.back_overlay[4] = 1
            overlay = self.back_overlay
        end
        if self.area and self.area.config.type == "deck" then
            self.children.back:draw(overlay)
        else
            self.children.back:draw_shader("dissolve")
        end
    end

    for k, v in pairs(self.children) do
        if not string.find(k, "overlay_") and k ~= "focused_ui" and k ~= "front" and k ~= "back" and k ~= "soul_parts" and k ~= "center" and k ~= "floating_sprite" and k ~= "shadow" and k ~= "use_button" and k ~= "buy_button" and k ~= "buy_and_use_button" and k ~= "debuff" and k ~= "price" and k ~= "particles" and k ~= "h_popup" then
            v:draw()
        end
    end

    if (layer == "card" or layer == "both") and self.area == G.hand then
        if self.children.focused_ui then self.children.focused_ui:draw() end
    end

    add_to_drawhash(self)
    self:draw_boundingrect()
end

function CodexArcanum.UICard:release(dragged)
    if dragged:is(CodexArcanum.UICard) and self.area then
        self.area:release(dragged)
    end
end

function CodexArcanum.UICard:highlight(is_higlighted)
    self.highlighted = is_higlighted
end

function CodexArcanum.UICard:card_h_popup()
    local AUT = self.ability_UIBox_table
    if not AUT then
        return
    end
    return {
        n = G.UIT.ROOT,
        config = { align = "cm", colour = G.C.CLEAR },
        nodes = {
            {
                n = G.UIT.C,
                config = { align = "cm", func = "show_infotip", object = Moveable() },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { padding = 0.05, r = 0.12, colour = lighten(G.C.JOKER_GREY, 0.5), emboss = 0.07 },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.1, r = 0.1, colour = adjust_alpha(darken(G.C.BLACK, 0.1), 0.8) },
                                nodes = {
                                    name_from_rows(AUT.name, AUT.card_type == "Enhanced" or AUT.card_type == "Default" and G.C.WHITE or nil)
                                }
                            }
                        }
                    }
                }
            },
        }
    }
end

function CodexArcanum.UICard:align_h_popup()
    local focused_ui = self.children.focused_ui and true or false
    local popup_direction = (self.T.y < G.CARD_H * 0.8) and "bm" or "tm"
    return {
        major = self.children.focused_ui or self,
        parent = self,
        xy_bond = "Strong",
        r_bond = "Weak",
        wh_bond = "Weak",
        offset = {
            x = --popup_direction ~= "cl" and 0 or
                focused_ui and -0.05 or
                (self.ability.consumeable and 0.0) or
                (self.ability.set == "Voucher" and 0.0) or
                -0.05,
            y = focused_ui and (
                    popup_direction == "tm" and (self.area and self.area == G.hand and -0.08 or -0.15) or
                    popup_direction == "bm" and 0.12 or
                    0
                ) or
                popup_direction == "tm" and -0.13 or
                popup_direction == "bm" and 0.1 or
                0
        },
        type = popup_direction,
    }
end

function CodexArcanum.UICard:hover()
    local debuff = self.debuff
    self.debuff = false
    self.ability_UIBox_table = {
        main = {},
        info = {},
        type = {},
        name = {},
        badges = {}
    }
    local center = self.config.center
    local loc = center.loc_vars and center:loc_vars({}, self) or {}
    local set = loc.set or center.set
    local key = loc.key or center.key or "playing_card"
    -- extreme crutch start
    if set == "Default" and self.config.overlays then
        local k, overlay = next(self.config.overlays)
        key = overlay.key
        if overlay.is and overlay:is(SMODS.Seal) then -- I really DO hate that inconsistency
            key = key .. "_seal"
        end
    end
    if not G.localization.descriptions[set] then
        set = "Other"
    end
    -- extreme crutch end
    self.ability_UIBox_table.card_type = set
    self.ability_UIBox_table.name = localize{ type = loc.type or "name", key = key, set = set, nodes = self.ability_UIBox_table.name, vars = loc }
    self.config.h_popup = self:card_h_popup()
    self.config.h_popup_config = self:align_h_popup()
    self.debuff = debuff
    Node.hover(self)
end

function CodexArcanum.UICard:generate_UIBox_ability_table()
    local card_type = self.ability.set or "None"
    local loc_vars = nil

    if card_type == "Default" or card_type == "Enhanced" then
        loc_vars = {
            playing_card = not not self.base.colour,
            value = self.base.value,
            suit = self.base.suit,
            colour = self.base.colour,
            nominal_chips = self.base.nominal > 0 and self.base.nominal or nil,
            bonus_chips = (self.ability.bonus + (self.ability.perma_bonus or 0)) > 0 and (self.ability.bonus + (self.ability.perma_bonus or 0)) or nil,
        }
    end
    return generate_card_ui(self.config.center, nil, loc_vars, card_type, {})
end

function CodexArcanum.UICard:remove_UI()
    self.ability_UIBox_table = nil
    self.config.h_popup = nil
    self.config.h_popup_config = nil
    self.no_ui = true
end

function CodexArcanum.UICard:stop_hover()
    Node.stop_hover(self)
end

function CodexArcanum.UICard:click()
    play_sound("tarot1", 0.9 + 0.1 * math.random(), 0.4)
    self:juice_up(1, 0.5)
    self.debuff = not self.params.toggle_config(self)
end

function CodexArcanum.UICard:remove()
    self.removed = true
    if self.area then
        self.area:remove_card(self)
    end
    self:remove_from_deck()
    if self.ability.queue_negative_removal then
        if self.ability.consumeable then
            G.consumeables.config.card_limit = G.consumeables.config.card_limit - 1
        else
            G.jokers.config.card_limit = G.jokers.config.card_limit - 1
        end
    end

    if not G.OVERLAY_MENU then
        for k, v in pairs(G.P_CENTERS) do
            if v.name == self.ability.name then
                if not next(find_joker(self.ability.name, true)) then
                    G.GAME.used_jokers[k] = nil
                end
            end
        end
    end

    if G.playing_cards then
        for k, v in ipairs(G.playing_cards) do
            if v == self then
                table.remove(G.playing_cards, k)
                break
            end
        end
        for k, v in ipairs(G.playing_cards) do
            v.playing_card = k
        end
    end

    remove_all(self.children)

    for k, v in pairs(G.I.CARD) do
        if v == self then
            table.remove(G.I.CARD, k)
        end
    end
    Moveable.remove(self)
end
