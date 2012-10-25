#!/bin/bash
# -*- shell-script -*-

my_hostname=$(hostname -f)
firstName=${my_hostname%%.*}
secondName=${my_hostname#*.}
secondName=${secondName%%.*}

if [ "$firstName" = spur ]; then
  SYSHOST=ranger
else
  SYSHOST=$secondName
fi

MCLAY_ranger=/share/home/00515/mclay
MCLAY_ls4=/home1/00515/mclay

SOURCEME_ranger=sourceme.sh
SOURCEME_ls4=sourceme

eval MCLAY=\$MCLAY_$SYSHOST

export LUA_PATH="$MCLAY"'/l/pkg/luatools/luatools/share/5.1/?.lua;;'
export LUA_CPATH="$MCLAY"'/l/pkg/luatools/luatools/lib/5.1/?.so;;'

eval SOURCEME=\$SOURCEME_$SYSHOST

. /root/$SOURCEME

module load lua

yesterday=$($MCLAY/w/ibwrapper/analyze/yesterday.lua)

umask 022

$MCLAY/w/ibwrapper/analyze/collectLariatData.lua --delete --date=$yesterday --masterDir=/scratch/projects/lariatData
