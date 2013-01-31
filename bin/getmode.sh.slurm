#!/bin/bash 
#
# $Id: fstab 1267 2012-06-26 12:41:57Z karl $
#------------------------------------------------------------------------------
# Note: this file is managed via LosF
#
# You should, in general, not edit this file directly as you will 
# *lose* the contents during the next sync process. Instead, 
# edit the template file in your local config directory:
# 
# /admin/build/admin/hpc_stack/config/const_files/Stampede/compute/getmode.sh
#
# Questions? karl@tacc.utexas.edu
#
#------------------------------------------------------------------------------

#
#---------------------------------------------------------
# Hopefully a kinder, gentler getmode() Trying to keep as 
# light-weight as possible as we might get called in 
# parallel.
#
# Primary launch types are currently defined as:
#
# * mvapich2_ssh
# * intel mpi
# 
# $Id:$
#---------------------------------------------------------

# Delineate specific stacks that are supported por favor.

if [ -n "$TACC_MPI_GETMODE" ]; then
  echo "$TACC_MPI_GETMODE"
else
  case $MPICH_HOME in 
      /opt/apps/*/mvapich2/*)
  	builtin echo "mvapich2_ssh";;
#      /opt/apps/*/mvapich2/*)
#  	builtin echo "mvapich2_slurm";;
      /opt/apps/*/mvapich2-debug/*)
  	builtin echo "mvapich2_ssh";;
      /opt/apps/*/impi/4*)
  	builtin echo "impi_hydra";;
      *)
  	builtin echo "UNKNOWN";;
  esac
fi

