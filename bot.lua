local bot = {}

local conf  = require("conf")
local event = require("event")
local api   = require('telegram-bot-lua.core').configure(conf.api_key)
local _conf = require('telegram-bot-lua.config')
local utils = require("utils")

api.send_msg = function(text, chat_id, topic_id)
    local success, res = api.request(
        _conf.endpoint .. api.token .. '/sendMessage',
        {
            ['chat_id']                     = chat_id,
            ['message_thread_id']           = topic_id,
            ['text']                        = text,
            ['parse_mode']                  = "HTML",
            ['disable_web_page_preview']    = false,
            ['disable_notification']        = false
        }
    )
end

function bot.launchWithCb(cb)
    local offset = 0 
    local eventList = {}
    event.buildEventList(eventList, conf.chatBook, conf.eventBook)
    while true do
        local updates = api.get_updates(0, offset, 1, nil, nil)
        local now = os.date("*t")
        event.updateEventList(eventList, now, api)
        cb()
        if updates and type(updates) == 'table' and updates.result then
            for _, v in pairs(updates.result) do
                api.process_update(v)
                offset = v.update_id + 1
            end
        end
    end
end

function table_print(t)
    for k, v in pairs(t) do
        utils.print("\t" .. k, tostring(v))
    end
    utils.print("")
end

function api.on_message(message)
    utils.print("message:")
    table_print(message) 
    utils.print("chat:")
    table_print(message.chat) 
end

bot.launchWithCb(function() end)
