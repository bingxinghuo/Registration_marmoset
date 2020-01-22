#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l m_mem_free=1G
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
echo $targetnumber
/opt/hpc/pkg/MATLAB/R2015b/bin/matlab -nodesktop -r "ctbSTS_marmoset('/sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/${targetnumber}_orig_target_STS.img', '/sonas-hs/mitra/hpc/home/blee/data/stackalign/${targetnumber}C/${targetnumber}_80_full_cropped.img', '/sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/ctb/', '${targetnumber}');exit"
date
