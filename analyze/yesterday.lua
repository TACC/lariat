#!/usr/bin/env lua
-- -*- lua -*-
require("strict")
local Dbg = require("Dbg")


function main()


   local epoch=tonumber(os.time())

   epoch = epoch - 86400.0

   local t = os.date("*t",epoch)


   local yesterday = string.format("%4d/%02d/%02d",t.year, t.month, t.day)

   print (yesterday)

end

main()
