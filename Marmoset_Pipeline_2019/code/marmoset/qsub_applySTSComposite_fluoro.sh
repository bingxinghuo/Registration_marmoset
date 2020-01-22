#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l m_mem_free=1.5G
#$ -pe threads 8
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
#echo $targetnumber
python applySTSCompositeTransform_fluoro.py M920 /sonas-hs/mitra/hpc/home/blee/data/stackalign/M920F_maskimg/M920_F_XForm_matrix.txt /sonas-hs/mitra/hpc/home/blee/data/stackalign/M920F_maskimg/M920_F_XForm.txt /sonas-hs/mitra/hpc/home/blee/data/stackalign/M920F_maskimg/M920_F_XForm_crop_matrix.txt /sonas-hs/mitra/hpc/home/blee/data/registration/M920/fluoro/fluoro_transforms/M920_fluoro_XForm_matrix.txt /sonas-hs/mitra/hpc/home/blee/data/registration/M920/fluoro/fluoro_transforms/M920_fluoro_XForm.txt 0.0882 291 308 0.08 0.08 /sonas-hs/mitra/hpc/home/blee/data/registration/M920/M920_80_AAV_full_fromraw.img 73 218 /sonas-hs/mitra/hpc/home/blee/data/stackalign/BNBLists/M920_F_List.txt
date
