SMODS.Tags = {}
SMODS.Tag = {
	name = "",
	slug = "",
	config = {},
	pos = {},
	loc_txt = {},
	discovered = false,
	min_ante = nil
}

function SMODS.Tag:new(name, slug, config, pos, loc_txt, min_ante, discovered, atlas)
	o = {}
	setmetatable(o, self)
	self.__index = self

	o.loc_txt = loc_txt
	o.name = name
	o.slug = "tag_" .. slug
	o.config = config or {}
	o.pos = pos or {
		x = 0,
		y = 0
	}
	o.min_ante = min_ante or nil
	o.discovered = discovered or false
	o.atlas = atlas or "tags"
	o.mod_name = SMODS._MOD_NAME
	o.badge_colour = SMODS._BADGE_COLOUR
	return o
end

function SMODS.Tag:register()
	SMODS.Tags[self.slug] = self
	local tag_obj = {
		discovered = self.discovered,
		name = self.name,
		set = "Tag",
		order = table_length(G.P_CENTER_POOLS['Tag']) + 1,
		key = self.slug,
		pos = self.pos,
		config = self.config,
		min_ante = self.min_ante,
		atlas = self.atlas,
		mod_name = self.mod_name,
		badge_colour = self.badge_colour
	}

	for _i, sprite in ipairs(SMODS.Sprites) do
		if sprite.name == tag_obj.key then
			tag_obj.atlas = sprite.name
		end
	end

	G.P_TAGS[self.slug] = tag_obj
	table.insert(G.P_CENTER_POOLS['Tag'], tag_obj)

	G.localization.descriptions["Tag"][self.slug] = self.loc_txt

end


local apply_to_runref = Tag.apply_to_run
function Tag:apply_to_run(_context)
	local ret_val = apply_to_runref(self, _context)
	if not self.triggered and self.config.type == _context.type then
		local key = self.key
        local tag_obj = SMODS.Tags[key]
        if tag_obj and tag_obj.apply and type(tag_obj.apply) == "function" then
            local o = tag_obj.apply(self, _context)
            if o then return o end
        end
	end

	return ret_val;
end