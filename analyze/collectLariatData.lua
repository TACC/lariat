#!/usr/bin/env lua
-- -*- lua -*-
local cmd = arg[0]

local i,j = cmd:find(".*/")
local cmd_dir = "./"
if (i) then
   cmd_dir = cmd:sub(1,j)
end
package.path = cmd_dir .. "?.lua;" .. package.path
local floor     = math.floor
local lfs       = require("lfs")
local mod       = math.mod
execNameA       = {}

require("strict")
require("capture")
local BeautifulTbl = require("BeautifulTbl")
local Optiks       = require("Optiks")
local Version      = "1.4"
local concatTbl    = table.concat
local json         = require("json")
local s_master     = {}
require("serializeTbl")
require("string_split")
require("fileOps")
require("VarDump")
userT = {}
local Dbg = require("Dbg")
------------------------------------------------------------------------
-- This function returns an iterator:  The iterator returns the next
-- username and homeDir or nil if there are no users left.

function processPWRec(fn)
   io.input(fn)
   return 
     function()
        local line = io.read()
        if (line == nil) then
           return nil
        end
        local a    = {}
        for v in line:split(':') do
           a[#a + 1] = v
        end
        return a[1], a[6]
     end
end

function dateToEpoch(year, month, day)

   local t = { year = 0, month = 0, day=0, hour = 0, min = 0, sec = 0 }

   t.year  = tonumber(year)
   t.month = tonumber(month)
   t.day   = tonumber(day)

   local epoch=tonumber(os.time(t))

   return epoch, epoch + 86400.0

end



function processLuaRecord(fn, sgeT)
   local f=io.open(fn, "r")
   if (f == nil) then return end
   local whole = f:read("*all")
   f:close()
   if (whole:sub(1,1) == "{") then
      whole = "userT="..whole
   end

   f=loadstring(whole)
   if (not f) then return  end
   f()

   local jobID = userT.jobID

   local a = sgeT[jobID] or {}

   local t = {}
   for k, v in pairs(userT) do
      t[k] = v
   end

   a[#a+1] = t
   if (jobID) then
      sgeT[jobID] = a
   end
end

function masterTbl()
   return s_master
end

function main()

   local numTimes = 0
   local iuser = 0
   local unit  = 2
   local fence = unit
   --------------------------------------------------------------
   -- count number of active users

   local sgeT = {}

   options()
   local masterTbl  = masterTbl()
   local pargs      = masterTbl.pargs

   for userName, homeDir in processPWRec("/etc/passwd") do
      local dir = pathJoin(homeDir,".sge")
      if ( isDir(dir)) then
         iuser = iuser + 1
      end
   end
   local nusers = iuser
   local year, month, day = masterTbl.date:match("(%d+)/(%d+)/(%d+)")

   
   local startTime, endTime = dateToEpoch(year,month,day)

   iuser = 0
   local icount = 0
   for userName, homeDir in processPWRec("/etc/passwd") do
      local dir = pathJoin(homeDir,".sge")
      if ( isDir(dir)) then
         iuser = iuser + 1
         local j = floor(iuser/nusers*100)
         if ( j > fence) then
            io.stderr:write("#")
            io.stderr:flush()
            fence = fence + unit
         end
         for file in lfs.dir(dir) do
            if (file:sub(-4,-1) == ".lua") then
               local fn  = pathJoin(dir,file)
               local fnT = lfs.attributes(fn)
               if (startTime <= fnT.modification and fnT.modification < endTime) then
                  icount = icount + 1
                  processLuaRecord(fn, sgeT)
                  if (masterTbl.delete) then
                     os.remove(fn)
                  end
               end
            end
         end
      end
   end

   if (icount > 0) then      
      local s = serializeTbl{indent=true, name="sgeT", value=sgeT}

      --------------------------------
      -- Write out file here.

      local path = pathJoin(masterTbl.masterDir,year,month)
      mkdir_recursive(path)

      local n = {}
      n[#n+1] = "lariatData-sgeT-"
      n[#n+1] = year
      n[#n+1] = "-"
      n[#n+1] = month
      n[#n+1] = "-"
      n[#n+1] = day
      
      local name = concatTbl(n,"") 

      local resultFn = pathJoin(path,name..".lua")
   
      local f = io.open(resultFn,"w")
      f:write(s)
      f:close()

      ------------------------------------------------------------------------
      -- Write out JSON file as well

      resultFn = pathJoin(path,name..".json")
   
      f = io.open(resultFn,"w")
      s = json.encode(sgeT)
      f:write(s)
      f:close()
   end
   io.stderr:write("\n")
end
function options()
   local masterTbl = masterTbl()
   local Version   = "1.0"
   local usage         = "Usage: collectLariatData.lua [options]"
   local cmdlineParser = Optiks:new{usage=usage, version=Version}

   cmdlineParser:add_option{ 
      name    = {'--date'},
      dest    = 'date',
      action  = 'store',
      default = nil,
      help    = "date in yyyy/mm/dd format",
   }
   cmdlineParser:add_option{ 
      name    = {'--masterDir'},
      dest    = 'masterDir',
      action  = 'store',
      default = nil,
      help    = "Master Root Directory",
   }

   cmdlineParser:add_option{ 
      name    = {'--delete'},
      dest    = 'delete',
      action  = 'store_true',
      default = false,
      help    = "Delete lariat data file after processing",
   }

   local optionTbl, pargs = cmdlineParser:parse(arg)

   for v in pairs(optionTbl) do
      masterTbl[v] = optionTbl[v]
   end
   masterTbl.pargs = pargs

end

main()
