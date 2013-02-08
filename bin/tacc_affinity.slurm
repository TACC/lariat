#!/bin/bash
# -*- sh -*-
# ---------------------------------------------------------------------
# Affinity convenicence script. Designed to be used with ibrun
# on TACC HPC systems.
#
# $Id: ibrun 1515 2012-12-05 23:28:12Z karl $
# ---------------------------------------------------------------------


export MV2_USE_AFFINITY=0
export MV2_ENABLE_AFFINITY=0
export VIADEV_USE_AFFINITY=0
export VIADEV_ENABLE_AFFINITY=0
export I_MPI_PIN=0

my_rank=$(( ${PMI_RANK-0} + ${PMI_ID-0} + ${MPIRUN_RANK-0} + ${OMPI_COMM_WORLD_RANK-0} + ${OMPI_MCA_ns_nds_vpid-0} ))

SCHEDULER=SLURM
if [ "$SCHEDULER" == "SGE" ];then
    myway=`builtin echo $PE | /bin/sed s/way//`
elif [ "$SCHEDULER" == "SLURM" ];then
  # Figure out number of MPI tasks per node.   Added by McCalpin 2012-12-05
  # If running under "ibrun", NODE_TASKS_PPN_INFO will already be set
  # else get info from SLURM_TASKS_PER_NODE (not propagated by "ibrun" due to illegal characters)
  if [ -z "$NODE_TASKS_PPN_INFO" ]
  then
    myway=`echo $SLURM_TASKS_PER_NODE | awk -F '(' '{print $1}'`
  else
    myway=16
    #Because slurm will spread tasks evenly across nodes, the wayness of each node 
    # may be different.  The env variable NODE_TASKS_PPN_INFO propagates the wayness 
    # per node cluster with this format:
    #"{# of tasks per node},{#initial task id}_[repeats if necessary]"
    NODE_TASKS_PPN_INFO=`echo $NODE_TASKS_PPN_INFO | sed -e's/_/ /g'`
    for cluster in $NODE_TASKS_PPN_INFO ; do 
        way=`echo $cluster | awk -F ',' '{print $1}'` ; 
        task_cutoff=`echo $cluster | awk -F ',' '{print $2}'`; 
	if [ $my_rank -ge $task_cutoff ] ; then
           myway=$way
           mytask_cutoff=$task_cutoff
        fi
    done 
#    echo "TA DEBUG: my_rank = $my_rank  myway = $myway "
  fi
 
else
    echo "ERROR: Unknown batch system"
    exit 1
fi

########################################################################
# Figure out which system we are on.
########################################################################

h=$(hostname -f)
h=${h%%.tacc.utexas.edu}
first=${h%%.*}
SYSHOST=${h#*.}

local_rank=$(( ( $my_rank - $mytask_cutoff) % $myway ))
# local_rank=`builtin eval echo \\\$local_$my_rank`

if [ "$SYSHOST" = ranger ]; then

  # Based on "wayness" determine socket layout on local node
  # if less than 4-way, offset to skip socket 0
  if [ $myway -eq 1 ]; then
      numnode="0,1,2,3"
  # if 2-way, set 1st task on 0,1 and second on 2,3
  elif [ $myway -eq 2 ]; then
      numnode="$(( 2 * $local_rank )),$(( 2 * $local_rank + 1 ))"
  elif [ $myway -lt 4 ]; then
      numnode=$(( $local_rank + 1 ))
  # if 4-way to 12-way, spread processes equally on sockets
  elif [ $myway -lt 13 ]; then
      numnode=$(( $local_rank / ( $myway / 4 ) ))
  # if 16-way, spread processes equally on sockets
  elif [ $myway -eq 16 ]; then
      numnode=$(( $local_rank / ( $myway / 4 ) ))
  # Offset to not use 4 processes on socket 0
  else
      numnode=$(( ($local_rank + 1) / 4 ))
  fi
else
  # Based on "wayness" determine socket layout on local node
  #   Modified to fit Longhorn  (2 sockets, 4 cores), Lars on Wed Jan 20 13:49:59 CST 2010
  #   Modified to fit Lonestar4 (2 sockets, 6 cores), Lars on Thu Jan 20 15:39:50 CST 2011
  if [ $myway -eq 1 ]; then
      numnode="0,1"
  elif [ $myway -eq 2 ]; then
      numnode=$local_rank
  elif [ $myway -le 4 ]; then
      numnode=$(( local_rank / 2 ))
  elif [ $myway -le 6 ]; then
      numnode=$(( local_rank / 3 ))
  elif [ $myway -le 8 ]; then
      numnode=$(( local_rank / 4 ))
  elif [ $myway -le 10 ]; then
      numnode=$(( local_rank / 5 ))
  elif [ $myway -le 12 ]; then
      numnode=$(( local_rank / 6 ))
  elif [ $myway -le 14 ]; then
      numnode=$(( local_rank / 7 ))
  elif [ $myway -le 16 ]; then
      numnode=$(( local_rank / 8 ))
  fi
fi

my_host=`hostname -s`
# echo "TACC: Running $my_rank on socket $numnode on $my_host"

if [ $myway -eq 16 ]; then
  # echo "TA DEBUG:  exec numactl --physcpubind=$local_rank $* "
#  echo "TACC: Running $my_rank on core $local_rank on $my_host"
  exec numactl --physcpubind=$local_rank --membind=$numnode $* 
else
  # echo "TA DEBUG:  exec numactl --cpunodebind=$numnode --membind=$numnode $* "
#  echo "TACC: Running $my_rank on socket $numnode on $my_host"
  exec numactl --cpunodebind=$numnode --membind=$numnode $* 
fi


