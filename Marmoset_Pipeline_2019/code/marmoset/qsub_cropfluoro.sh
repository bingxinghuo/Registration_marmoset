#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l m_mem_free=1G
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
echo $targetnumber
python cropMarmosetFluoro.py ~/Marmoset_Pipeline_2019/data/stackalign/${targetnumber}F_maskimg/${targetnumber}_80_AAV_full.img ~/Marmoset_Pipeline_2019/data/stackalign/${targetnumber}F_maskimg/${targetnumber}_80_AAV_full_cropped.img ~/Marmoset_Pipeline_2019/data/stackalign/${targetnumber}F_maskimg/${targetnumber}_F_XForm_crop_matrix.txt
date
