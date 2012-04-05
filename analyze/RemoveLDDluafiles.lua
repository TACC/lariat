#!/usr/bin/env lua
-- -*- lua -*-
local cmd = arg[0]

local i,j = cmd:find(".*/")
local cmd_dir = "./"
if (i) then
   cmd_dir = cmd:sub(1,j)
end
package.path = cmd_dir .. "?.lua;" .. package.path


require("fileOps")
local posix       = require("posix")

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



function main()

   for userName, homeDir in processPWRec("/etc/passwd") do
      local dir = pathJoin(homeDir,".sge")
      if ( isDir(dir)) then
         for file in lfs.dir(dir) do
            if (file:sub(-4,-1) == ".lua") then
               posix.unlink(pathJoin(dir,file))
            end
         end
      end
   end

end

main()
