-- Load_spec.lua - smoke test: load every file in .toc order against stubbed WoW globals, then
-- drive the addon through a battleground. Runs on a retail (Midnight), a Forever and a TBC
-- Anniversary client; retail can be put in chat lockdown, where calls are typed, not sent.

local function stubObject()
    local obj = {}
    return setmetatable(obj, {
        __index = function(t, key)
            return function() return stubObject() end
        end,
    })
end

local function tocFiles()
    local files = {}
    for line in io.lines("BattlegroundComms.toc") do
        if line:match("%.lua%s*$") then files[#files + 1] = line:match("^%s*(.-)%s*$"):gsub("\\", "/") end
    end
    return files
end

-- instance: { zone, type, id }, e.g. { "Arathi Basin", "pvp", 529 }
local function clientSpecs(label, interface)
    describe("BG Comms on a " .. label .. " client", function()
        local eventHandler, texts, sent, addonSent, opened, printed, where, lockdown, now, inCombat
        local hasPings = interface >= 16000   -- retail and Forever have the ping system; TBC doesn't

        local function sawText(pattern, plain)
            for _, text in ipairs(texts) do
                if type(text) == "string" and text:find(pattern, 1, plain) then return true end
            end
            return false
        end

        local function enter(zone, id, subzone)
            where = { zone = zone, type = "pvp", id = id, subzone = subzone or "" }
            eventHandler(nil, "PLAYER_ENTERING_WORLD")
        end

        before_each(function()
            eventHandler, texts, sent, addonSent, opened, printed = nil, {}, {}, {}, {}, {}
            where, lockdown, now = { zone = "Orgrimmar", type = "none", id = 1, subzone = "" }, false, 1000
            inCombat = false
            _G.InCombatLockdown = function() return inCombat end
            _G.GetCVarBool = function() return false end
            _G.C_Ping = hasPings and { IsPingSystemEnabled = function() return true end } or nil
            _G.BGCommsDB = nil
            _G.UIParent = stubObject()
            _G.Minimap = stubObject()
            Minimap.GetWidth = function() return 140 end
            _G.UISpecialFrames = {}
            _G.SlashCmdList = {}
            _G.tinsert = table.insert
            _G.C_Timer = { After = function(_, fn) fn() end, NewTicker = function() return stubObject() end }
            _G.GetTime = function() return now end
            _G.GetBuildInfo = function() return "x", "1", "Oct 24 2026", interface end
            _G.UnitName = function() return "Speedimus" end
            _G.UnitFactionGroup = function() return "Alliance" end
            _G.IsShiftKeyDown = function() return false end
            _G.IsInRaid = function() return where.type == "pvp" end
            _G.LE_PARTY_CATEGORY_INSTANCE = 2
            _G.IsInGroup = function(category)
                if category == 2 then return where.type == "pvp" end
                return where.type == "pvp"
            end
            _G.GetInstanceInfo = function() return where.zone, where.type, 0, "", 40, 0, false, where.id end
            _G.GetRealZoneText = function() return where.zone end
            _G.GetSubZoneText = function() return where.subzone end
            _G.GameTooltip = stubObject()
            _G.print = function(text) printed[#printed + 1] = text end
            _G.ChatFrame_OpenChat = function(text) opened[#opened + 1] = text end
            _G.C_ChatInfo = {
                RegisterAddonMessagePrefix = function() return true end,
                SendAddonMessage = function(prefix, message, chatType) addonSent[#addonSent + 1] = { prefix, message, chatType } end,
                SendChatMessage = function(text, chatType) sent[#sent + 1] = { text, chatType } end,
            }
            if interface >= 120000 then
                C_ChatInfo.InChatMessagingLockdown = function() return lockdown end
                _G.Enum = { AddOnRestrictionType = { Combat = 0, Encounter = 1, PvPMatch = 3 } }
                _G.C_RestrictedActions = { IsAddOnRestrictionActive = function(kind) return lockdown and kind == 3 end }
            else
                _G.Enum, _G.C_RestrictedActions = nil, nil
            end

            _G.CreateFrame = function(frameType, name)
                local f = stubObject()
                local shown = frameType ~= "Frame"
                f.Show = function() shown = true end
                f.Hide = function() shown = false end
                f.IsShown = function() return shown end
                f.SetShown = function(_, v) shown = v and true or false end
                f.RegisterEvent = function() end
                f.scripts = {}
                f.SetScript = function(_, script, fn)
                    f.scripts[script] = fn
                    if script == "OnEvent" then eventHandler = fn end
                end
                f.SetText = function(_, text) f.text = text; texts[#texts + 1] = text end
                f.attributes = {}
                f.SetAttribute = function(_, key, value)
                    if inCombat then error("ADDON_ACTION_BLOCKED: SetAttribute in combat") end
                    f.attributes[key] = value
                end
                f.hooks = {}
                f.HookScript = function(_, script, fn) f.hooks[script] = fn end
                f.GetText = function() return f.text end
                f.CreateFontString = function()
                    local fs = stubObject()
                    fs.SetText = function(_, text) fs.text = text; texts[#texts + 1] = text end
                    fs.GetText = function() return fs.text end
                    return fs
                end
                if name then _G[name] = f end
                return f
            end

            local ns = {}
            for _, file in ipairs(tocFiles()) do
                assert(loadfile(file))("BattlegroundComms", ns)
            end
            eventHandler(nil, "ADDON_LOADED", "BattlegroundComms")
            eventHandler(nil, "PLAYER_ENTERING_WORLD")
        end)

        local function click(button, mouseButton)
            if button.scripts.OnClick then button.scripts.OnClick(button, mouseButton or "LeftButton") end
            if button.hooks.OnClick then button.hooks.OnClick(button, mouseButton or "LeftButton") end
        end

        it("stays out of the way outside battlegrounds", function()
            assert.is_false(BGCommsBar:IsShown())
        end)

        it("shows the battleground's nodes when you enter one", function()
            enter("Arathi Basin", 529)
            assert.is_true(BGCommsBar:IsShown())
            assert.are.equal("Stables", BGCommsNode1:GetText())
            assert.are.equal("Gold Mine", BGCommsNode5:GetText())
            assert.is_false(BGCommsNode6:IsShown())
            enter("Orgrimmar", 1)
            where.type = "none"
            eventHandler(nil, "PLAYER_ENTERING_WORLD")
            assert.is_false(BGCommsBar:IsShown())
        end)

        it("calls incoming at a node with the picked count, to the team and their addons", function()
            enter("Arathi Basin", 529)
            click(BGCommsCount4)                            -- "3"
            click(BGCommsNode3)                             -- Farm
            assert.are.same({ "{circle} INC 3: Farm", "INSTANCE_CHAT" }, sent[1])
            assert.are.same({ "BGComms", "1|INC|Farm|3", "INSTANCE_CHAT" }, addonSent[1])
            assert.is_true(sawText("Farm: INC 3", true))    -- on your own board too
        end)

        it("calls clear with Shift+click and help with a right-click", function()
            enter("Arathi Basin", 529)
            _G.IsShiftKeyDown = function() return true end
            click(BGCommsNode1)
            _G.IsShiftKeyDown = function() return false end
            now = now + 10
            click(BGCommsNode2, "RightButton")
            assert.are.equal("{triangle} CLEAR: Stables", sent[1][1])
            assert.are.equal("{cross} HELP: Blacksmith", sent[2][1])
        end)

        it("has flag carrier calls in Warsong Gulch", function()
            enter("Warsong Gulch", 489)
            assert.is_true(BGCommsFlags:IsShown())
            click(BGCommsEFC1)
            click(BGCommsFlagRoom)
            assert.are.equal("{cross} EFC WEST", sent[1][1])
            assert.are.equal("{diamond} INC FLAG ROOM", sent[2][1])
        end)

        it("calls where you stand from a keybinding", function()
            enter("Arathi Basin", 529, "Lumber Mill")
            BGComms_IncHere()
            assert.are.equal("{square} INC ?: Lumber Mill", sent[1][1])
        end)

        it("puts teammates' calls on the board, and doesn't repeat one they just made", function()
            enter("Arathi Basin", 529)
            eventHandler(nil, "CHAT_MSG_ADDON", "BGComms", "1|INC|Farm|2", "INSTANCE_CHAT", "Ann-Forever")
            assert.is_true(sawText("Farm: INC 2", true))
            assert.is_true(sawText("Ann", true))
            click(BGCommsCount3)                            -- "2"
            click(BGCommsNode3)                             -- Farm, same as Ann's
            assert.are.equal(0, #sent)
        end)

        it("has INC / CLEAR / HELP buttons for where you stand, pinging your spot where pings exist", function()
            enter("Arathi Basin", 529, "Farm")
            if hasPings then
                assert.are.equal("macro", BGCommsHereInc.attributes.type)
                assert.are.equal("/ping [@player] 2", BGCommsHereInc.attributes.macrotext)
                assert.are.equal("/ping [@player] 4", BGCommsHereHelp.attributes.macrotext)
            else
                assert.is_nil(BGCommsHereInc.attributes.macrotext)
            end
            click(BGCommsHereInc)
            assert.are.equal("{square} INC ?: Farm", sent[1][1])
        end)

        it("pings your target with the flag carrier calls where pings exist", function()
            enter("Warsong Gulch", 489)
            if hasPings then
                assert.are.equal("/ping [@target,harm,nodead] 1", BGCommsEFC2.attributes.macrotext)
                assert.are.equal("/ping [@target,help,nodead] 4", BGCommsOurFC1.attributes.macrotext)
            else
                assert.is_nil(BGCommsEFC2.attributes.macrotext)
            end
        end)

        it("turns pings off and on with /bgc pings", function()
            SlashCmdList.BGCOMMS("pings off")
            assert.is_nil(BGCommsHereInc.attributes.macrotext)
            SlashCmdList.BGCOMMS("pings on")
            if hasPings then assert.are.equal("/ping [@player] 2", BGCommsHereInc.attributes.macrotext) end
        end)

        it("waits for the end of combat to show or re-lay out the bar", function()
            inCombat = true
            enter("Arathi Basin", 529)                      -- e.g. zoning in mid-fight
            assert.is_false(BGCommsBar:IsShown())
            inCombat = false
            eventHandler(nil, "PLAYER_REGEN_ENABLED")
            assert.is_true(BGCommsBar:IsShown())
        end)

        it("binds keys to the where-you-stand buttons", function()
            assert.are.equal("INC where you are", _G["BINDING_NAME_CLICK BGCommsHereInc:LeftButton"])
        end)

        it("ignores other addons' messages and junk", function()
            enter("Arathi Basin", 529)
            eventHandler(nil, "CHAT_MSG_ADDON", "DBM", "1|INC|Farm|2", "INSTANCE_CHAT", "Ann")
            eventHandler(nil, "CHAT_MSG_ADDON", "BGComms", "garbage", "INSTANCE_CHAT", "Ann")
            assert.is_false(sawText("Farm: INC", true))
        end)

        it("reports what's restricted with /bgc diag", function()
            enter("Arathi Basin", 529, "Farm")
            SlashCmdList.BGCOMMS("diag")
            local all = table.concat(printed, "\n")
            assert.is_true(all:find("Arathi Basin", 1, true) ~= nil)
            assert.is_true(all:find("INSTANCE_CHAT", 1, true) ~= nil)
            assert.is_true(all:find("lockdown", 1, true) ~= nil)
        end)

        if interface >= 120000 then
            it("types the call for you to send when Midnight blocks addon chat", function()
                enter("Arathi Basin", 529)
                lockdown = true
                click(BGCommsNode1)
                assert.are.equal(0, #sent)
                assert.are.equal(0, #addonSent)               -- no addon messages either
                assert.are.same({ "/i {square} INC ?: Stables" }, opened)
                assert.is_true(table.concat(printed, "\n"):find("press Enter", 1, true) ~= nil)
            end)
        end
    end)
end

clientSpecs("retail (Midnight)", 120105)
clientSpecs("Forever", 16001)
clientSpecs("TBC Anniversary", 20506)
