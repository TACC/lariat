#!/usr/bin/env lua
-- -*- lua -*-
require("strict")
local Dbg = require("Dbg")


function main()

   local startDate = arg[1]
   local year, month, day = startDate:match("(%d+)/(%d+)/(%d+)")

   local t = { year = 0, month = 0, day=0, hour = 0, min = 0, sec = 0 }

   t.year  = tonumber(year)
   t.month = tonumber(month)
   t.day   = tonumber(day)

   local epoch=tonumber(os.time(t))

   epoch = epoch + 86400.0

   t = os.date("*t",epoch)

   local nextDay = string.format("%4d/%02d/%02d",t.year, t.month, t.day)

   print (nextDay)

end

main()
