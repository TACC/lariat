#!/bin/bash
# -*- shell-script -*-
# set -x


export MV2_USE_AFFINITY=0
export MV2_ENABLE_AFFINITY=0
export VIADEV_USE_AFFINITY=0
export VIADEV_ENABLE_AFFINITY=0
export I_MPI_PIN=0

########################################################################
# Figure out which system we are on.
########################################################################


#Set defaults for nodes

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
    if [ x$SLURM_QUEUE == "xlargemem" ]; then
      myway=32
    else
      myway=16
    fi
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


local_rank=$(( ( $my_rank - $mytask_cutoff) % $myway ))
# local_rank=`builtin eval echo \\\$local_$my_rank`

if [ x$SLURM_QUEUE == "xlargemem" ]; then

  # Based on "wayness" determine socket layout on local node
  # if less than 4-way, offset to skip socket 0
  if [ $myway -eq 1 ]; then
      numnode="0,1,2,3"
  # if 2-way, set 1st task on 0,1 and second on 2,3
  elif [ $myway -eq 2 ]; then
      numnode="$(( 2 * $local_rank )),$(( 2 * $local_rank + 1 ))"
  # if 3-way move tasks off socket 0
  elif [ $myway -eq 3 ]; then
      numnode=$(( $local_rank + 1 ))
  # if 4-way to 32-way, spread processes equally on sockets
  else 
      numnode=$(( ( $local_rank * 4 ) / $myway  ))
  fi
else
  # Based on "wayness" determine socket layout on local node
  #   Modified to fit Longhorn  (2 sockets, 4 cores), Lars on Wed Jan 20 13:49:59 CST 2010
  #   Modified to fit Lonestar4 (2 sockets, 6 cores), Lars on Thu Jan 20 15:39:50 CST 2011 
  if [ $myway -eq 1 ]; then
      numnode="0,1"
  # if 2-way to 16-way, spread processes equally on sockets
  else 
      numnode=$(( ( $local_rank * 2 ) / $myway  ))
  fi
fi

my_host=`hostname -s`
# echo "TACC: Running $my_rank on socket $numnode on $my_host"

if [ x$SLURM_QUEUE == "xlargemem" -a $myway -eq 32 ]; then
  #Core layout on largemem node is round robin so local_ran
  # must be converted
  cores_per_cpu=8
  sockets_per_node=4
  core_id=$((  $local_rank/$cores_per_cpu + ($local_rank % $cores_per_cpu)*$sockets_per_node ))
  # echo "TA DEBUG:  exec numactl --physcpubind=$core_id $* "
  # echo "TACC: Running $my_rank on core $core_id on $my_host"
  exec numactl --physcpubind=$core_id $* 
elif [ $myway -eq 16 -a x$SLURM_QUEUE != "xlargemem" ]; then
  # echo "TA DEBUG:  exec numactl --physcpubind=$local_rank $* "
  # echo "TACC: Running $my_rank on core $local_rank on $my_host"
  exec numactl --physcpubind=$local_rank $* 
else
  # echo "TA DEBUG:  exec numactl --cpunodebind=$numnode --membind=$numnode $* "
  # echo "TACC: Running $my_rank on socket $numnode on $my_host"
  exec numactl --cpunodebind=$numnode --membind=$numnode $* 
fi

