-- helpers.lua - load addon files the way WoW does: each chunk gets (addonName, sharedNamespace)

local helpers = {}

function helpers.load(files)
    local ns = {}
    for _, file in ipairs(files) do
        local chunk = assert(loadfile(file))
        chunk("BattlegroundComms", ns)
    end
    return ns
end

return helpers
