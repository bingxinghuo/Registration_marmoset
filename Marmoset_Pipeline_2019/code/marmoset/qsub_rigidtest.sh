#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l m_mem_free=2G
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
#/opt/hpc/pkg/MATLAB/R2015b/bin/matlab -nodesktop -r "MRI_alignment_maskcost_bnb('${targetnumber}');exit"
outputdirectoryname="/sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/MRImorph"
mkdir $outputdirectoryname

atlasfilename="/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_80_flip_masked_eroded_refined.img"
targetfilename="/sonas-hs/mitra/hpc/home/blee/data/target_images/${targetnumber}/${targetnumber}_mri_full.img"
annofilename="/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_80_flip.img"
atlasmaskfilename="/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_80_flip_refined.img"
outputatlasfilename="${outputdirectoryname}/${targetnumber}_defatlas_to_MRI.img"
outputannofilename="${outputdirectoryname}/${targetnumber}_defanno_to_MRI.img"
outputatlasmaskfilename="${outputdirectoryname}/${targetnumber}_defatlasmask_to_MRI.img"
transformfilename="${outputdirectoryname}/${targetnumber}_atlas_to_MRI_XForm.txt"

python rigidAlignMarmosetAtlas.py ${atlasfilename} ${targetfilename} ${annofilename} ${atlasmaskfilename} ${outputatlasfilename} ${outputannofilename} ${outputatlasmaskfilename} ${transformfilename}
date
