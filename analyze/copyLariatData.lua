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
local s_master     = {}
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

   local nusers = 1000
   local iuser  = 0
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
         local targetDir = pathJoin("/tmp/lariatData",userName,".sge")

         mkdir_recursive(targetDir)

         local a = {}
         a[#a+1] = "cp"
         a[#a+1] = pathJoin(homeDir,".sge") .. "/*.lua"
         a[#a+1] = targetDir
         local cmd = concatTbl(a," ")
         os.execute(cmd)
      end
   end
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
