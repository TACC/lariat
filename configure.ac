dnl Process this file with autoconf to produce a configure script.

AC_INIT(Makefile.in)
AC_SUBST(PATH_TO_LUA)
AC_SUBST(PATH_TO_HASHSUM)
AC_PATH_PROG(luaprog, lua, "")
if test x$luaprog = "x"; then
  echo The program "lua" must be in your path
  exit
fi
PATH_TO_LUA=$(echo $luaprog | sed -e 's|/lua$||')


AC_OUTPUT(makefile:Makefile.in)

