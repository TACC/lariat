#!/bin/bash
#---------------------------------------------------------
# Hopefully a kinder, gentler getmode()
# Trying to keep as light-weight as possible as we
# might get called in parallel.
#
# Primary launch types are currently defined as:
# (1) mvapich1_ssh
# (2) mvapich2_ssh
# (3) openmpi_ssh (same for all version)
# 
# Note that we have kicked mpd to the curb...
#---------------------------------------------------------

# Delineate specific stacks that are supported por favor.

if [ -n "$TACC_MPI_GETMODE" ]; then
  echo "$TACC_MPI_GETMODE"
else
  case $MPICH_HOME in 
      /opt/apps/*/mvapich/1.0.1)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/mvapich/1.0.1c)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/mvapich2/1.2)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/openmpi/1.3*)
  	builtin echo "openmpi_1.3_ssh";;
      /opt/apps/*/openmpi/*)
  	builtin echo "openmpi_ssh";;
      /opt/apps/*/mvapich/1.0)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/mvapich-hybrid/*)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/hecura/*)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/hecura-debug/*)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/mvapich2/1.0)
  	builtin echo "mvapich2_mpd";;
      /opt/apps/*/mvapich-devel/*)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/mvapich/0.9.9)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/openmpi/1.2.4)
  	builtin echo "openmpi_ssh";;
      /opt/apps/*/mvapich-old/*)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/mvapich2-debug/*)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/mvapich-new/*)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/mvapich2/1.6)
  	builtin echo "mvapich2_ssh";;
      /share1/apps/*/mvapich2test/1.6)
  	builtin echo "mvapich2_ssh";;
      /share1/apps/*/mvapich1test/1.2rc1)
  	builtin echo "mvapich1_ssh";;
      /share1/apps/*/mvapich2-rel/*)
  	builtin echo "mvapich2_ssh";;
      *)
  	builtin echo "UNKNOWN";;
  esac
fi
# if env | grep MPICH_HOME | grep -q mvapich2-devel; then
#   builtin echo "mvapich2_ssh"
# elif env | grep MPICH_HOME | grep -q mvapich2; then
#   builtin echo "mvapich2_mpd"
# elif env | grep MPICH_HOME | grep -q "openmpi/1.3"; then
#   builtin echo "openmpi_1.3_ssh"
# elif env | grep MPICH_HOME | grep -q openmpi; then
#   builtin echo "openmpi_ssh"
# elif env | grep MPICH_HOME | grep -q mvapich-devel; then
#   builtin echo "mvapich1_devel_ssh"
# elif env | grep MPICH_HOME | grep -q mvapich; then
#   builtin echo "mvapich1_ssh"
# else
#   builtin echo "mvapich1_ssh"
# fi

