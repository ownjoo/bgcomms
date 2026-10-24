-- Callouts_spec.lua - the words, the chat channel, and getting them out

local helpers = dofile("tests/helpers.lua")

describe("Callouts", function()
    local Callouts

    before_each(function()
        Callouts = helpers.load({ "Callouts.lua" }).Callouts
    end)

    describe("Text", function()
        it("calls incoming with a count, marked by how many", function()
            assert.are.equal("{square} INC ?: Stables", Callouts.Text({ kind = "INC", node = "Stables" }))
            assert.are.equal("{star} INC 2: Farm", Callouts.Text({ kind = "INC", node = "Farm", count = "2" }))
            assert.are.equal("{circle} INC 4: Farm", Callouts.Text({ kind = "INC", node = "Farm", count = "4" }))
            assert.are.equal("{cross} INC 5+: Farm", Callouts.Text({ kind = "INC", node = "Farm", count = "5+" }))
        end)

        it("calls clear and help at a node, or without one", function()
            assert.are.equal("{triangle} CLEAR: Gold Mine", Callouts.Text({ kind = "CLEAR", node = "Gold Mine" }))
            assert.are.equal("{cross} HELP: Blacksmith", Callouts.Text({ kind = "HELP", node = "Blacksmith" }))
            assert.are.equal("{triangle} CLEAR", Callouts.Text({ kind = "CLEAR" }))
        end)

        it("makes the flag calls", function()
            assert.are.equal("{cross} EFC WEST", Callouts.Text({ kind = "EFC", lane = "WEST" }))
            assert.are.equal("{star} OUR FC MID", Callouts.Text({ kind = "OURFC", lane = "MID" }))
            assert.are.equal("{diamond} INC FLAG ROOM", Callouts.Text({ kind = "FLAGROOM" }))
            assert.are.equal("{cross} FC NEEDS HELP", Callouts.Text({ kind = "FCHELP" }))
        end)
    end)

    describe("Encode and Decode (addon messages)", function()
        it("round-trips a call", function()
            local call = { kind = "INC", node = "Lumber Mill", count = "5+" }
            assert.are.same(call, Callouts.Decode(Callouts.Encode(call)))
            local flag = { kind = "EFC", lane = "EAST" }
            assert.are.same(flag, Callouts.Decode(Callouts.Encode(flag)))
        end)

        it("rejects junk and unknown kinds", function()
            assert.is_nil(Callouts.Decode("hello"))
            assert.is_nil(Callouts.Decode("1|NUKE|Farm|"))
            assert.is_nil(Callouts.Decode("9|INC|Farm|2"))      -- a future format version
        end)
    end)
end)

describe("Channel", function()
    local Channel
    local function api(opts)
        return {
            LE_PARTY_CATEGORY_INSTANCE = 2,
            IsInGroup = function(category)
                if category == 2 then return opts.instance or false end
                return opts.party or opts.raid or false
            end,
            IsInRaid = function() return opts.raid or false end,
        }
    end

    before_each(function()
        Channel = helpers.load({ "Callouts.lua" }).Channel
    end)

    it("talks to the battleground team, else raid, else party", function()
        assert.are.equal("INSTANCE_CHAT", Channel.For(api({ instance = true, raid = true })))
        assert.are.equal("RAID", Channel.For(api({ raid = true })))
        assert.are.equal("PARTY", Channel.For(api({ party = true })))
    end)

    it("has nobody to tell when you're alone", function()
        assert.is_nil(Channel.For(api({})))
    end)
end)

describe("Sender", function()
    local Sender, sent, opened, printed, now, lockdown

    local function api()
        return {
            GetTime = function() return now end,
            C_ChatInfo = {
                SendChatMessage = function(text, chatType) sent[#sent + 1] = { text, chatType } end,
                InChatMessagingLockdown = function() return lockdown end,
            },
            ChatFrame_OpenChat = function(text) opened[#opened + 1] = text end,
            print = function(text) printed[#printed + 1] = text end,
        }
    end

    before_each(function()
        Sender = helpers.load({ "Callouts.lua" }).Sender
        sent, opened, printed, now, lockdown = {}, {}, {}, 100, false
    end)

    it("sends to the channel", function()
        assert.are.equal("sent", Sender.Send(api(), "{triangle} CLEAR: Farm", "INSTANCE_CHAT"))
        assert.are.same({ { "{triangle} CLEAR: Farm", "INSTANCE_CHAT" } }, sent)
    end)

    it("puts the message in your chat box when addons may not send (Midnight), for you to press Enter", function()
        lockdown = true
        assert.are.equal("typed", Sender.Send(api(), "{triangle} CLEAR: Farm", "INSTANCE_CHAT"))
        assert.are.same({}, sent)
        assert.are.same({ "/i {triangle} CLEAR: Farm" }, opened)
    end)

    it("types instead of sending when you choose to", function()
        assert.are.equal("typed", Sender.Send(api(), "x", "RAID", { mode = "type" }))
        assert.are.same({ "/raid x" }, opened)
    end)

    it("falls back to typing when sending fails", function()
        local a = api()
        a.C_ChatInfo.SendChatMessage = function() error("ADDON_ACTION_BLOCKED") end
        assert.are.equal("typed", Sender.Send(a, "x", "PARTY"))
        assert.are.same({ "/p x" }, opened)
    end)

    it("uses the old global SendChatMessage on clients without C_ChatInfo's", function()
        local a = api()
        a.C_ChatInfo.SendChatMessage = nil
        a.SendChatMessage = function(text, chatType) sent[#sent + 1] = { text, chatType } end
        Sender.Send(a, "x", "PARTY")
        assert.are.same({ { "x", "PARTY" } }, sent)
    end)

    it("previews in your chat frame when there's nobody to tell", function()
        assert.are.equal("preview", Sender.Send(api(), "x", nil))
        assert.are.same({}, sent)
        assert.is_true(printed[1]:find("x", 1, true) ~= nil)
    end)

    it("won't repeat the same call within a few seconds", function()
        Sender.Send(api(), "x", "PARTY")
        now = now + 2
        assert.are.equal("throttled", Sender.Send(api(), "x", "PARTY"))
        now = now + 2
        assert.are.equal("sent", Sender.Send(api(), "x", "PARTY"))
        assert.are.equal(2, #sent)
    end)
end)
