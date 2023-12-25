local utils = {}

-- 01-02-03-04-05-06-07-08-09-10
--                ||
--       ||       --       ||
--             || --    ||    ||
--     ||         --
--                --

-- 11 >> 1 = 5,  6th,  6 - 10 (5)
-- 10 >> 1 = 5,  6th,  6 - 9  (4)
-- 9  >> 1 = 4,  5th,  5 - 8  (4)
--
-- 11 / 2 = 5 (5 elements to the right, 5 to the left)
-- 10 / 2 = 5 (5 elements to the right, 4 to the left)
-- 9  / 2 = 4 (4 elements to the right, 4 to the left)
-- if the number is odd - the list will have a center element
-- otherwise it will have one more element to the left than to the right
-- 
--
-- bsearch(#10, 11)
-- 0: base = 0, limit = 10, p = 5 => limit = (10 - 1) / 2 = 4, base = 6
-- 1: base = 6, limit =  4, p = 8 => limit = ( 4 - 1) / 2 = 1, base = 9
-- 2: base = 9, limit =  1, p = 9 => limit = ( 1 - 1) / 2 = 0, base = 10
--
-- bsearch(#10, 0)
-- 0: base = 0, limit = 10, p = 5 => limit = 10 / 2 = 5
-- 1: base = 0, limit =  5, p = 2 => limit =  5 / 2 = 2
-- 2: base = 0, limit =  2, p = 1 => limit =  2 / 2 = 1
-- 3: base = 0, limit =  1, p = 0 => limit =  1 / 2 = 0


-- limit - how many elements we currently have
-- base  - base (first) element
-- this particular algorithm is good because it has 1 less
-- if statement then the other version, but it because I can't
-- use lua version that supports bit operations - it isn't as much better
function bsearch2(t, key)
    assert(type(t) == "table")
    local limit = #t
    local base  = 1
    while limit ~= 0 do
        local middle = base + math.floor(limit / 2)
        if t[middle] == key then
            io.write(" (found)\n")
            return middle
        elseif t[middle] < key then
            -- if we currently have an even number of elements
            -- (say 4) then we took the element 2 as the middle element
            -- but that means, that to the right we only have 1 element
            -- and so if we were to divide limit by 2 as-is it would give us
            -- 2, but if we subtract 1, it will instead give us the correct 1
            -- If limit is odd - nothing will happen, decrement won't do anything.
            base = middle + 1
            limit = limit - 1
        end
        limit = math.floor(limit / 2)
    end
    io.write("\n")
    return -1
end

function utils.bsearch(t, key)
    assert(type(t) == "table")
    local left  = 1
    local right = #t
    while left <= right do
        local middle = math.floor((left + right) / 2)
        if t[middle] < key then
            left = middle + 1
        elseif t[middle] > key then
            right = middle - 1 
        else return middle end
    end
    io.write("\n")
    return -1
end

utils.outfile = io.open("bot.log", "w")

utils.print = function(...)
    utils.outfile:write(os.date("%H:%M:%S: "))
    for i, v in ipairs(arg) do
        utils.outfile:write("\t" .. v)
    end
    utils.outfile:write("\n")
    utils.outfile:flush()
end

return utils
