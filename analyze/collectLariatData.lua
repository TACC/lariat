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
local BeautifulTbl = require("BeautifulTbl")
local Optiks       = require("Optiks")
local Version      = "1.4"
local master       = {}
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

function processLuaRecord(fn, sgeT, accT, libT)
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
   sgeT[jobID] = {}
   for k, v in pairs(userT) do
      sgeT[jobID][k] = v
   end

   local su = userT.numCores * userT.runTime / 3600.0

   local t = accT[userT.execType] or { num = 0, su = 0, user = {} }

   t.num   = t.num + 1
   t.su    = t.su  + su
   t.user[userT.user] = (t.user[userT.user] or 0) + 1
   accT[userT.execType] = t

   local sizeT = userT.sizeT or {bss = 0}
   local bss = tonumber(sizeT.bss or 0)
   if (bss > largeBSS) then
      accT.bss.num = accT.bss.num + 1
      accT.bss.jobID[jobID] = {userT.user, bss/(1024*1024*1024)}
   end

   if (userT.execType:find("^system:")) then
      accT.system.num = accT.system.num + 1
      accT.system.su  = accT.system.su  + su
   end

   if (next(userT.pkgT) ~= nil ) then
      recordLibT(su, userT.pkgT, libT)
   end
end

function masterTbl()
   return master
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

   local activeT = {}
   iuser = 0
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
               local fn = pathJoin(dir,file)
               activeT[userName] = (activeT[userName] or 0) + 1
               numTimes = numTimes + 1
               processLuaRecord(fn, sgeT, accT, libT)
           end
         end
      end
   end
   io.stdout:write("\n")

   local s = serializeTbl{indent=true, name="accT", value=accT}
   io.stdout:write("\n",s,"\n")
               
   local execT = {}
   processExecT(sgeT,execT)

   reportLibT(libT)   

   reportTop(execT, masterTbl.execFile)

end
function options()
   local masterTbl = masterTbl()
   local usage         = "Usage: processLDDjob [options]"
   local cmdlineParser = Optiks:new{usage=usage, version=Version}

   cmdlineParser:add_option{ 
      name    = {'-f','--execFile'},
      dest    = 'execFile',
      action  = 'store',
      default = nil,
      help    = "File containing a list of executables in a lua Table execNameA={}",
   }


   local optionTbl, pargs = cmdlineParser:parse(arg)

   for v in pairs(optionTbl) do
      masterTbl[v] = optionTbl[v]
   end
   masterTbl.pargs = pargs

end

main()
