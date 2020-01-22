#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l m_mem_free=0.8G
#$ -pe threads 16
#$ -V

date
source /sonas-hs/it/hpc/home/easybuild/lmod-setup.sh
#module load GCC/4.9.3-binutils-2.25
#module load OpenMPI/.1.8.8
#module load Python/2.7.10
module load foss/2016a
module load IntelPython/2.7.12
#python ~/code/StackAlignNew/rigidSTSBrainBySliceAndTypeCSHL_marmoset_bnb.py /sonas-hs/mitra/hpc/home/blee/data/stackalign/BNBLists/ ~/data/stackalign/${targetnumber}N/ $targetnumber N 0.0588
if [ "$targetnumber" == "M819" ]
then
    singlestartind=85
    singleendind=350
elif [ "$targetnumber" == "M820" ]
then
    singlestartind=51
    singleendind=200
elif [ "$targetnumber" == "M821" ]
then
    singlestartind=67
    singleendind=248
elif [ "$targetnumber" == "M822" ]
then
    singlestartind=91
    singleendind=190
elif [ "$targetnumber" == "M851" ]
then
    singlestartind=51
    singleendind=220
elif [ "$targetnumber" == "M854" ]
then
    singlestartind=79
    singleendind=180
elif [ "$targetnumber" == "M917" ]
then
    singlestartind=73
    singleendind=240
elif [ "$targetnumber" == "M918" ]
then
    singlestartind=73
    singleendind=222
elif [ "$targetnumber" == "M919" ]
then
    singlestartind=77
    singleendind=120
elif [ "$targetnumber" == "M920" ]
then
    singlestartind=73
    singleendind=218
elif [ "$targetnumber" == "M921" ]
then
    singlestartind=73
    singleendind=240
elif [ "$targetnumber" == "M922" ]
then
    singlestartind=73
    singleendind=222
elif [ "$targetnumber" == "M983" ]
then
    singlestartind=149
    singleendind=225
elif [ "$targetnumber" == "M985" ]
then
    singlestartind=61
    singleendind=282
elif [ "$targetnumber" == "M1144" ]
then
    singlestartind=73
    singleendind=240
elif [ "$targetnumber" == "M1145" ]
then
    singlestartind=70
    singleendind=243
elif [ "$targetnumber" == "M1146" ]
then
    singlestartind=79
    singleendind=240
elif [ "$targetnumber" == "M1147" ]
then
    singlestartind=79
    singleendind=252
elif [ "$targetnumber" == "M1148" ]
then
    singlestartind=73
    singleendind=259
elif [ "$targetnumber" == "M1231" ]
then
    singlestartind=67
    singleendind=234
elif [ "$targetnumber" == "M1232" ]
then
    singlestartind=67
    singleendind=252
elif [ "$targetnumber" == "M1228" ]
then
    singlestartind=69
    singleendind=235
elif [ "$targetnumber" == "M826" ]
then
    singlestartind=73
    singleendind=200
elif [ "$targetnumber" == "M853" ]
then
    singlestartind=73
    singleendind=236
elif [ "$targetnumber" == "M855" ]
then
    singlestartind=56
    singleendind=220
elif [ "$targetnumber" == "M823" ]
then
    singlestartind=51
    singleendind=220
elif [ "$targetnumber" == "M876" ]
then
    singlestartind=61
    singleendind=252
elif [ "$targetnumber" == "M519" ]
then
    singlestartind=133
    singleendind=500
elif [ "$targetnumber" == "M1316" ]
then
    singlestartind=73
    singleendind=251
elif [ "$targetnumber" == "M1229" ]
then
    singlestartind=67
    singleendind=234
elif [ "$targetnumber" == "M1559" ]
then
    singlestartind=999
    singleendind=999
elif [ "$targetnumber" == "M6328" ]
then
    singlestartind=55
    singleendind=245
elif [ "$targetnumber" == "M519" ]
then
    singlestartind=133
    singleendind=500
elif [ "$targetnumber" == "M489" ]
then
    singlestartind=133
    singleendind=472
fi
python ~/Marmoset_Pipeline_2019/code/StackAlignNew/rigidSTSBrainBySliceAndTypeCSHL_marmoset_bnb.py /sonas-hs/mitra/hpc/home/kram/Marmoset_Pipeline_2019/data/stackalign/BNBLists/ ~/Marmoset_Pipeline_2019/data/stackalign/${targetnumber}N/ $targetnumber N 0.0588 $singlestartind $singleendind
#python ~/Marmoset_Pipeline_2019/code/StackAlignNew/rigidSTSBrainBySliceAndTypeCSHL_marmoset_hata_bnb.py /sonas-hs/mitra/hpc/home/kram/Marmoset_Pipeline_2019/data/stackalign/BNBLists/ ~/Marmoset_Pipeline_2019/data/stackalign/${targetnumber}N/ $targetnumber N 0.0588 $singlestartind $singleendind
#python ~/code/StackAlignNew/rigidSTSBrainBySliceAndTypeCSHL_marmoset_bnb.py /sonas-hs/mitra/hpc/home/blee/data/stackalign/BNBLists_M24/ ~/data/stackalign/${targetnumber}N/ $targetnumber N 0.0588 $singlestartind $singleendind
#python ~/code/StackAlignNew/rigidSTSBrainBySliceAndTypeCSHL_marmoset_bnb.py /sonas-hs/mitra/hpc/home/blee/data/stackalign/BNBLists/ ~/data/stackalign/${targetnumber}F_maskimg/ $targetnumber F 0.0882 $singlestartind $singleendind
#python ~/code/StackAlignNew/rigidSTSBrainBySliceAndTypeCSHL_bnb.py /nfs/mitraweb2/mnt/disk125/main/toBrian/StackAlignNew/data/BNBLists/ ~/data/stackalign/${targetnumber}F/ $targetnumber F 0.01472
date

