ADMIN_stampede="/fixMe/fixMe"
ADMIN_ranger="/share/moduleData/reverseMapD"
ADMIN_ls4="/home1/moduleData/reverseMapD"
ADMIN_longhorn="/share/tacc_admin/reverseMapD"

nlocal=$(hostname -f)
nA=($(builtin echo "$nlocal" | tr '.' ' '))
first=${nA[0]}
SYSHOST=${nA[1]}

if [ "$first" = spur ]; then
  SYSHOST=ranger
fi

eval "ADMIN_DIR=\$ADMIN_$SYSHOST"

OLD="$ADMIN_DIR/reverseMapT.old.lua"
NEW="$ADMIN_DIR/reverseMapT.new.lua"
RMAP="$ADMIN_DIR/reverseMapT.lua"

BASE_MODULE_PATH="/opt/apps/teragrid/modulefiles:/opt/apps/modulefiles:/opt/modulefiles"

rm -f $OLD
/opt/apps/lmod/lmod/libexec/spider -o reverseMap $BASE_MODULE_PATH > $NEW
chmod 644 $NEW

if [ -f "$RMAP" ]; then
  mv $RMAP $OLD
fi
mv $NEW  $RMAP
