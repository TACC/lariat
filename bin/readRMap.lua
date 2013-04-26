require("strict")
require("fileOps")
require("declare")
require("string_split")
local Dbg = require("Dbg")

reverseMapT = false

function readRMap(reverseMapD)

   local dbg = Dbg:dbg()
   dbg.start("readRMap(",reverseMapD,")")
   -- open reverseMap file and read it in.

   local mapT = {}

   --declare("reverseMapT",{})
   for dir in reverseMapD:split(":") do
      _G.reverseMapT = false
      local reverseMapFn = pathJoin(dir,"reverseMapT.lua")
      local rmF          = io.open(reverseMapFn,"r")
      dbg.print("(1) fn: ", reverseMapFn, ", found: ", tostring((not (not rmF))),"\n")
      if (not rmF) then
         reverseMapFn = pathJoin(dir,"reverseMapT.old.lua")
         rmF          = io.open(reverseMapFn,"r")
         dbg.print("(2) fn: ", reverseMapFn, ", found: ", tostring((not (not rmF))),"\n")
      end
      
      if (rmF) then
         local whole  = rmF:read("*all")
         rmF:close()
         local func, msg = loadstring(whole)
         if (func) then
            func()
         else
            dbg.print("Problem with reverse map: ",msg,"\n")
         end
      else
         dbg.print("Unable to open rmap file\n")
      end

      local rmapT = _G.reverseMapT
      if (rmapT and next(rmapT) ~= nil) then
         for k, v in pairs(rmapT) do
            mapT[k] = v
         end
      end
   end

   dbg.fini()
   return mapT 

end
