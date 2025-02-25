CodexArcanum.FakeCard = SMODS.Center:extend{
    unlocked = true,
    discovered = true,
    pos = { x = 0, y = 0 },
    legendaries = {},
    config = {},
    set = "Consumeables",
    required_params = {
        "key",
    },
    inject = function(self) end,
}

CodexArcanum.FakeTag = SMODS.GameObject:extend{
    obj_table = SMODS.Tags,
    obj_buffer = {},
    required_params = {
        "key",
    },
    discovered = false,
    min_ante = nil,
    class_prefix = "tag",
    atlas = "tags",
    set = "Tag",
    pos = { x = 0, y = 0 },
    config = {},
    inject = function(self) end
}
