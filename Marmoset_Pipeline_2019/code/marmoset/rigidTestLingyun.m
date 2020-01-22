atlasfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_100_flip_masked_eroded.img';
targetfilename = '/sonas-hs/mitra/hpc/home/blee/data/stackalign/lingyun/M9606_100_ani.img';
annofilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_100_flip.img';
atlasmaskfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_100_flip.img';
dataoutputdirectoryname = '/sonas-hs/mitra/hpc/home/blee/data/registration/M9606_ds/';
mkdir(dataoutputdirectoryname);
patientnumber = 'M9606';
targetmaskfilename = '/sonas-hs/mitra/hpc/home/blee/data/stackalign/lingyun/M9606_100_ani_mask.img';

system(['python rigidAlignMarmosetAtlasMasked.py ' atlasfilename ' ' targetfilename ' ' annofilename ' ' atlasmaskfilename ' ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_annotation_affine.img ' dataoutputdirectoryname patientnumber '_atlasmask_affine.img ' dataoutputdirectoryname patientnumber '_globalaffinetrans.txt ' targetmaskfilename]);

% this doesnt work because of all the missing sections. might need to hist match the target instead
%system(['python histogramMatchingMarmoset.py ' targetfilename ' ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_affine_lhm.img']);

% note that this is going to squash the atlas, probably
system(['/sonas-hs/mitra/hpc/home/blee/code/can/mm_lddmm2n_ver03_weightonatlas_evensmallersig.pl 1 ' dataoutputdirectoryname patientnumber '_affine.img ' targetfilename ' ' targetmaskfilename ' 0.4 ' dataoutputdirectoryname patientnumber '_lddmm 3 0.05 10 0.02 10 0.01 10 3 1 0.8']);

% apply to annotation
system(['/sonas-hs/mitra/hpc/home/blee/code/can/BIN/IMG_apply_lddmm_tform1 ' dataoutputdirectoryname patientnumber '_annotation_affine.img ' dataoutputdirectoryname patientnumber '_lddmm/Hmap000.vtk ' dataoutputdirectoryname patientnumber '_annotation.img 2']);
