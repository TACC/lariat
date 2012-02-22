ADMIN_stampede="/fixMe/fixMe"
ADMIN_ranger="/share/tacc_admin/reverseMapD"
ADMIN_ls4="/home1/tacc_admin/reverseMapD"
ADMIN_longhorn="/share/tacc_admin/reverseMapD"

nlocal=$(hostname -f)
nA=($(builtin echo "$nlocal" | tr '.' ' '))
first=${nA[0]}
SYSHOST=${nA[1]}

if [ "$first" = spur ]; then
  SYSHOST=ranger
fi

eval "ADMIN_DIR=\$ADMIN_$SYSHOST"


rm -f $ADMIN_DIR/reverseMapT.old.lua
/opt/apps/lmod/lmod/libexec/spider -o reverseMap > $ADMIN_DIR/reverseMapT.new.lua
mv $ADMIN_DIR/reverseMapT.lua $ADMIN_DIR/reverseMapT.old.lua
mv $ADMIN_DIR/reverseMapT.new.lua $ADMIN_DIR/reverseMapT.lua

