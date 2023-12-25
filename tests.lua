local event     = require("event")
local conf      = require("conf")

local tests = {
    ["EventList"] = function()
        local eventList = {}

        event.buildEventList(eventList, conf.chatBook, conf.eventBook)

        event.printEventList(eventList)
    end,
    ["TimeTrigger"] = function()
        local now = os.date("*t")
        local trigger = event.TimeTrigger("20/10/2022 10:00:00", { day = 7 })
        local nextTrigger = trigger:triggerTimeAfter(now)
        print(string.format("next event trigger: %s", os.date("%c", nextTrigger)))
    end,
    ["OOP"] = function()
        local Class = {
            name = "",
            age  = 0
        }

        function Object(name, age)
            local this = setmetatable({}, { __index = Class } )
            this.name = name
            this.age = age
            return this
        end

        function Class:print()
            print(self.name, self.age)
        end

        local clare = Object("Clare", 21)
        local kevin = Object("Kevin", 25)

        clare:print()
        kevin:print()
        clare:print()
    end
}

if arg[1] then
    tests[arg[1]]()
else
    print("available tests:")
    for k, v in pairs(tests) do
        print("\t" .. k)
    end
    print("")
end
