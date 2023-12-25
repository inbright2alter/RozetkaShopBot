-- RATIONALE:
-- having time events that happen at very specific occasions is fun, but not productive
-- if it is needed to make a time event with a repition of less than "once a month" then it is only
-- neccessary to get the distance from the reference date to now (in seconds) and divide it by reptition period in seconds
-- For events that happen every month or year, it is more logical to work with the date structure itself
--
-- Since if you work with both <year-month> and <day-hour-min-sec> repitions, then the first breaks the math for the second
-- since now the second has to comply with the limitations set by the first, and I can hardly imagine the first really
-- being frequently used, more so having the need to use them both at the same time. I mean, even using "every 2 years"
-- is incredibly hard to imagine. Every month is gonna come in handy a lot, but not really alongside <day-hour-min-sec>.

-- TODO: also have to take into account things like 31/2 and stuff like that
-- I am actually very curious as to what will happen if I give it the wrong date

local module = {}

local utils = require("utils")

local TimeTriggerProto = {
    ref = {
        year  = 0,
        month = 0,
        day   = 0,
        hour  = 0,
        min   = 0,
        sec   = 0 
    },
    rep = {
        format = "", -- "months" / "seconds"
        value  = 0 
    }
}

function TimeTriggerProto:triggerTimeAfter(ref)
    ref.isdst = false
    local reftime = os.time(ref)
    local diff = os.difftime(os.time(self.ref), reftime) -- reftime - self.ref
    if diff < 0 then
        if self.rep.format == "months" then
            local mdiff = math.max((ref.year - self.ref.year) * 12 + ref.month - self.ref.month, self.rep.value)
            while diff < 0 do
                self.ref.month = self.ref.month + mdiff
                if self.ref.month > 12 then
                    -- we do -1 for cases when it's 12th month and we add 12 months (so to not leave 0)
                    local m = math.floor((self.ref.month - 1) / 12)
                    self.ref.year = self.ref.year + m
                    self.ref.month = self.ref.month - m * 12
                end
                diff = os.difftime(reftime, os.time(ref))
                mdiff = self.rep.value
            end 
        elseif self.rep.format == "seconds" then
            diff = diff + math.floor((-diff + self.rep.value - 1) / self.rep.value) * self.rep.value
        else
            error("invalid repitition format!")
        end
    end
    return reftime + diff
end

module.TimeTrigger = function(ref, rep)
    local captures = { string.match(ref, "(%d%d?)/(%d%d?)/(%d+) (%d%d?):(%d%d?):(%d%d?)") }
    assert(#captures ~= 0)

    local this = setmetatable({}, { __index = TimeTriggerProto })
    this.ref = {}
    this.rep = {}
    this.ref.day   = tonumber(captures[1])
    this.ref.month = tonumber(captures[2])
    this.ref.year  = tonumber(captures[3])
    this.ref.hour  = tonumber(captures[4])
    this.ref.min   = tonumber(captures[5])
    this.ref.sec   = tonumber(captures[6])
    this.ref.isdst = false

    assert(this.ref.year  >= 2022 and this.ref.year  <= 2030)
    assert(this.ref.month >= 1    and this.ref.month <= 12)
    assert(this.ref.day   >= 1    and this.ref.day   <= 31)
    assert(this.ref.hour  >= 0    and this.ref.hour  <= 23)
    assert(this.ref.min   >= 0    and this.ref.min   <= 60)
    assert(this.ref.sec   >= 0    and this.ref.sec   <= 60)
    
    if rep.year or rep.month then
        if rep.day or rep.hour or rep.min or rep.sec then
            error("repition of form <year, month> can not have <day, hour, min, sec> repitition.")
        end
        this.rep.format = "months"
        rep.year = rep.year or 0
        rep.month = rep.month or 0
        this.rep.value  = rep.year * 12 + rep.month
    elseif rep.day or rep.hour or rep.min or rep.sec then
        this.rep.format = "seconds"
        rep.day = rep.day or 0
        rep.hour = rep.hour or 0
        rep.min = rep.min or 0
        rep.sec = rep.sec or 0
        this.rep.value  = rep.day * 24 * 60 * 60 + rep.hour * 60 * 60 + rep.min * 60 + rep.sec
    else
        error("invalid repitition!")
    end

--    print(string.format("[EventTriggerCreate] %02d/%02d/%d %02d:%02d:%02d <> repeat every %d %s", this.ref.day, this.ref.month, this.ref.year, this.ref.hour, this.ref.min, this.ref.sec, this.rep.value, this.rep.format))

    return this
end

module.sortEventList = function(eventList)
    table.sort(eventList, function(a, b) return a.ntt < b.ntt end)
end

-- Event:
--      ntt : number   // next trigger time
--      act : function // action
--      rep : table    // repitition
--      ctx : table    // context

-- TODO: don't track monthly events like that
--       if an event doesn't happen in 24 hours, 
--       don't even put it into the list
module.updateEventList = function(eventList, refpoint, api)
    local numTriggered = 1
    local reftime = os.time(refpoint)
    while numTriggered <= #eventList and reftime > eventList[numTriggered].ntt do
        local event = eventList[numTriggered]
        event.act(event.ctx, api)
        if event.rep.format == "months" then
            local ref = os.date("*t", event.ntt)
            ref.month = ref.month + event.rep.value
            local m = math.floor((ref.month - 1) / 12)
            ref.year = ref.year + m
            ref.month = ref.month - 12 * m
            ref.isdst = false
            event.ntt = os.time(ref)
        else
            event.ntt = event.ntt + event.rep.value
        end
        numTriggered = numTriggered + 1
    end
    if numTriggered > 1 then
        module.sortEventList(eventList)
        module.printEventList(eventList)
    end
end

module.buildEventList = function(eventList, chatBook, eventBook)
    local now = os.date("*t")
    for k, chat in pairs(chatBook) do
        utils.print("processing chat:", k)
        assert(chat.chat_id ~= nil)
        assert(chat.events  ~= nil)
        chat.name = k

        for _, eventName in ipairs(chat.events) do
            local eventInfo = eventBook[eventName]
            assert(eventInfo ~= nil)
            utils.print(string.format("\tprocessing event: %s (%d triggers)", eventName, #eventInfo.triggers))

            for _, trigger in ipairs(eventInfo.triggers) do
                table.insert(eventList, { 
                    ntt = trigger:triggerTimeAfter(now),
                    act = eventInfo.action,
                    rep = trigger.rep,
                    ctx = chat,
                    _ev = eventName
                })
            end
        end
    end
    module.sortEventList(eventList)
    module.printEventList(eventList)
end

module.printEventList = function(eventList)
    utils.print("Current Event List:")
    for _, event in ipairs(eventList) do
        utils.print(string.format("\t%s: ", os.date("%d/%m/%y %H:%M:%S", event.ntt)), event._ev, "->", event.ctx.name)
    end
end

return module
