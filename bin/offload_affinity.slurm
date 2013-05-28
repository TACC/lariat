#!/bin/bash
# -*- shell-script -*-
# set -x



########################################################################
# Since this is for MIC, we must be on Stampede
########################################################################

#Set defaults for nodes

my_rank=$(( ${PMI_RANK-0} + ${PMI_ID-0} + ${MPIRUN_RANK-0} + ${OMPI_COMM_WORLD_RANK-0} + ${OMPI_MCA_ns_nds_vpid-0} ))

#Check to see if MIC_OMP_NUM_THREADS is set
# if not set, assume MIC_OMP_NUM_THREADS=15
#  Matches 16 tasks/node
if [ x"$MIC_OMP_NUM_THREADS" == "x" ]; then
   export MIC_OMP_NUM_THREADS=15
fi

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
fi

#Set the local rank
local_rank=$(( ( $my_rank - $mytask_cutoff) % $myway ))
#DEBUG
# echo "TA DEBUG: local_rank = $local_rank my_rank = $my_rank  myway = $myway "

#Determine the range for each offload section dependent upon # tasks/node 
# and assumes the use of max of 60 MIC cores(240 threads)

# set -x
mic_cores=60
offload_section_size=$(( $mic_cores/$myway ))
section_overlap=$(( $mic_cores % $myway ))
section_extra=$(( $local_rank<$section_overlap?$local_rank:$section_overlap ))
core_start=$(( $local_rank*$offload_section_size + $section_extra ))
local_rank=$((local_rank+1))
section_extra=$(( $local_rank<$section_overlap?$local_rank:$section_overlap ))
core_end=$(( $local_rank*$offload_section_size + $section_extra - 1))

#Calculate the hardware thread start/end points
thread_start=$(( 4*core_start + 1))
thread_end=$(( 4*(core_end + 1)  ))
# echo "DEBUG: $my_rank :: $local_rank : $myway :: $core_start - $core_end :: $thread_start  - $thread_end"

#Now, since MIC_KMP_AFFINITY can't handle compact,scatter, or balanced with a range of
#  cores, we have to set the range for each THREAD!

#Determine the range for each thread in the offload section 
# dependent upon the thread range calculated above
thread_range=$(( $thread_end - $thread_start + 1 ))

#If MIC_OMP_NUM_THREADS is less than range of threads
#  spread the threads out evenly(i.e. balanced)
if [ "$thread_range" -gt "$MIC_OMP_NUM_THREADS" ] 
then 
  thread_span=$(( $thread_range/$MIC_OMP_NUM_THREADS ))
  #If the thread span is greater than 4
  # match balanced behavior and assign threads to consecutive
  # cores, i.e. every 4th hardware thread
  if [ "$thread_span" -lt "4" ]
  then
    thread_overlap=$(( $thread_range % $MIC_OMP_NUM_THREADS ))
  else
    thread_overlap=0
    thread_span=4
  fi
  #Setup MIC_KMP_AFFINITY
  export MIC_KMP_AFFINITY="explicit,proclist=["
  #Iterate over # of threads
#  for tid in {0..$MIC_OMP_NUM_THREADS}
  for (( tid=0; tid<$MIC_OMP_NUM_THREADS; tid++ )) 
  do 
    thread_extra=$(( $tid<$thread_overlap?$tid:$thread_overlap ))
    tid_start=$(( $tid*$thread_span + $thread_extra  ))
    tidp1=$((tid+1))
    thread_extra=$(( $tidp1<$thread_overlap?$tidp1:$thread_overlap ))
    tid_end=$(( $tidp1*$thread_span + $thread_extra - 1 ))
    MIC_KMP_AFFINITY="${MIC_KMP_AFFINITY}{$(( $thread_start + $tid_start )),$(( $thread_start + $tid_end ))},"
  done
  MIC_KMP_AFFINITY="${MIC_KMP_AFFINITY}]"

#If MIC_OMP_NUM_THREADS is greater than range of threads
#  just set the range,(i.e. compact)
else
  export MIC_KMP_AFFINITY="proclist=[${thread_start}-${thread_end}],explicit"
fi

#DEBUG
# To debug, set the DEBUG_OFFLOAD_AFFINITY environment variable
#  to a non empty string and the DEBUG_TASK environment variable
#  to the task id you want to see
if [[ -n ${DEBUG_OFFLOAD_AFFINITY+x} ]] 
then
  if ! [[ "$DEBUG_TASK" =~ ^[0-9]+$ ]] ; then
    DEBUG_TASK=0
  fi
  if [ "x$my_rank" == "x$DEBUG_TASK" ]; then
   echo "DEBUG: $my_rank :: $local_rank : $myway :: $core_start - $core_end :: $thread_start  - $thread_end"
   export MIC_KMP_AFFINITY="${MIC_KMP_AFFINITY},verbose"
   echo "DEBUG: MIC_KMP_AFFINITY=${MIC_KMP_AFFINITY}"
  fi
fi

#Run the executable
$*

