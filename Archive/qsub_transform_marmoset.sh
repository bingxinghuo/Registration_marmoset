#! /opt/hpc/bin/bash
# Tell the SGE that this is an array job, with "tasks" to be numbered 1 to 10000
# When a single command in the array job is sent to a compute node,
# its task number is stored in the variable SGE_TASK_ID,
# so we can use the value of that variable to get the results we want:

source /sonas-hs/it/hpc/home/easybuild/lmod-setup.sh
module load foss/2016a
module load IntelPython/2.7.12

BRAINNO=$1
STYPE=$2
TASKID=${SGE_TASK_ID}

BASELOC=/sonas-hs/mitra/hpc/home/kram/StackAlignNew/

SCRIPTS_DIR=$BASELOC/Scripts/

python $SCRIPTS_DIR/python/qsub_applySTSCompositeTransform_fullfluo_marmoset.py ${BRAINNO} ${STYPE} ${TASKID}