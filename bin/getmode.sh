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
      /opt/apps/*/mvapich/)
  	builtin echo "mvapich1_ssh";;
      /opt/apps/*/mvapich2/*)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/openmpi/1.3*)
  	builtin echo "openmpi_1.3_ssh";;
      /opt/apps/*/openmpi/*)
  	builtin echo "openmpi_ssh";;
      /opt/apps/*/mvapich2/*)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/mvapich2-debug/*)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/impi/4*)
  	builtin echo "impi_hydra";;
      *)
  	builtin echo "UNKNOWN";;
  esac
fi
