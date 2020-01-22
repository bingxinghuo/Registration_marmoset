#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l m_mem_free=5G
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
#/opt/hpc/pkg/MATLAB/R2015b/bin/matlab -nodesktop -r "MRI_alignment_maskcost_bnb('${targetnumber}');exit"
outputdirectoryname="/sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/"
mkdir $outputdirectoryname

atlasfilename="/sonas-hs/mitra/hpc/home/blee/data/target_images/${targetnumber}/${targetnumber}_invivo_mri_full.img"
#nisslfilename="/sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/${targetnumber}_orig_target_STS.img"
nisslfilename="/sonas-hs/mitra/hpc/home/blee/data/target_images/${targetnumber}/${targetnumber}_defMRI.img"
mrifilename="/sonas-hs/mitra/hpc/home/blee/data/registration/${targetnumber}/MRI_iter7.img"
targetfilename="/sonas-hs/mitra/hpc/home/blee/data/target_images/${targetnumber}/${targetnumber}_mri_full.img"
annofilename="/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_80_flip.img"
atlasmaskfilename="/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_80_flip_refined.img"
outputatlasfilename="${outputdirectoryname}/${targetnumber}_invivo_to_exvivo_MRI.img"
outputannofilename="${outputdirectoryname}/${targetnumber}_defanno_to_MRI.img"
outputatlasmaskfilename="${outputdirectoryname}/${targetnumber}_defatlasmask_to_MRI.img"
transformfilename="${outputdirectoryname}/${targetnumber}_invivo_to_exvivo_MRI_XForm.txt"

#python rigidAlignMarmosetAtlas.py ${atlasfilename} ${targetfilename} ${annofilename} ${atlasmaskfilename} ${outputatlasfilename} ${outputannofilename} ${outputatlasmaskfilename} ${transformfilename}
#python rigidAlignMRI_withaffine.py ${atlasfilename} ${nisslfilename} ${outputatlasfilename} ${transformfilename}
#/sonas-hs/mitra/hpc/home/blee/code/can/mm_lddmm2n_ver03_evensmallersig.pl 1 ${outputatlasfilename} ${nisslfilename} 1 ${outputdirectoryname}/${targetnumber}_invivo_to_exvivo_lddmm 3 0.05 10 0.02 10 0.01 10 1 1 1.0
/sonas-hs/mitra/hpc/home/blee/code/can/BIN/IMG_apply_lddmm_tform1 ${outputatlasfilename} ${outputdirectoryname}/${targetnumber}_invivo_to_exvivo_lddmm/Hmap000.vtk ${outputdirectoryname}/${targetnumber}_invivo_to_exvivo_lddmm/${targetnumber}_invivo_to_exvivo_MRI_lddmm.img 1
date
