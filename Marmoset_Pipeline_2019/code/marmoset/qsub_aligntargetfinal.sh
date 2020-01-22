#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l m_mem_free=2.5G
#$ -pe threads 16
#$ -V

date
source /sonas-hs/it/hpc/home/easybuild/lmod-setup.sh
#module load GCC/4.9.3-binutils-2.25
#module load OpenMPI/.1.8.8
#module load Python/2.7.10
module load foss/2016a
module load IntelPython/2.7.12
#python ~/code/mouseRegistration_bnb.py $targetnumber
#echo $targetnumber
#/opt/hpc/pkg/MATLAB/R2015b/bin/matlab -nodesktop -r "MRI_alignment_bnb;exit"
echo $targetnumber
python alignTargetHorizontal_marmoset.py ${targetnumber} /sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/${targetnumber}_STSpipeline_output/${targetnumber}_orig_target_STS.img /sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/${targetnumber}_STSpipeline_output/ ${targetnumber}_orig_target_STS_rot2.img /sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/${targetnumber}_STSpipeline_output/transforms/ 1
date
