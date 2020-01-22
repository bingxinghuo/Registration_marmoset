% target and atlas filenames
patientnumber = 'M920';
%targetfilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_cropped.img';
atlasfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_80_flip_masked_eroded.img';
atlasmaskfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_80_flip.img';
annofilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_80_flip.img';
%mrifilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/MRI_rigid.img';

% input directories
targetdirectoryprefix = '/sonas-hs/mitra/hpc/home/blee/data/target_images/';
outputtargetfilename = [targetdirectoryprefix patientnumber '/' patientnumber '_80_cropped'];
rawmrifilename = [targetdirectoryprefix patientnumber '/20160528_21095708DTI128axb1000news180001a001.nii'];
outputmrifilename = [targetdirectoryprefix patientnumber '/' patientnumber '_mri_200'];
targetfilename = outputtargetfilename;
mrifilename = outputmrifilename;

% pre process
%marmosetRegistration_pre_bnb(patientnumber,targetdirectoryprefix,outputtargetfilename,rawmrifilename,outputmrifilename,[100,383,137,416]);

% output directories
dataoutputdirectoryname = '/sonas-hs/mitra/hpc/home/blee/data/registration/M920_test/';
mkdir(dataoutputdirectoryname);
transformdirectoryname = [dataoutputdirectoryname 'transforms/'];
mkdir(transformdirectoryname);

orig_target_STS.fileprefix = [dataoutputdirectoryname '/' patientnumber '_orig_target_STS'];

orig_target_STS_padded.fileprefix = [dataoutputdirectoryname '/' patientnumber '_orig_target_STS_padded'];

%% rigidly register the atlas to the target
targetfilename = [orig_target_STS_padded.fileprefix '.img'];
%system(['python rigidAlignMarmosetAtlas.py ' atlasfilename ' ' targetfilename ' ' annofilename ' ' atlasmaskfilename ' ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_annotation_affine.img ' dataoutputdirectoryname patientnumber '_atlasmask_affine.img ' dataoutputdirectoryname patientnumber '_globalaffinetrans.txt']);


%% do lddmm from atlas to target
% mask the target
%system(['python maskMarmosetTarget.py ' orig_target_STS_padded.fileprefix '.img ' dataoutputdirectoryname patientnumber '_targetmask.img ' dataoutputdirectoryname patientnumber '_targetmasked.img']);

% maybe do histogram matching
localhist = 0;
if localhist == 1
    %system("matlab -nodesktop -singleCompThread -nojvm -nodisplay -r \"histmatch_daniel(\'/cis/home/leebc/Projects/Mouse_Histology/data/registration/" + patientnumber + "/" + patientnumber + "_targetmasked.img\', \'/cis/home/leebc/Projects/Mouse_Histology/data/registration/" + patientnumber + "/" + patientnumber + "_affine.img\',false);exit\"")
else
    system(['python histogramMatchingMarmoset.py ' dataoutputdirectoryname patientnumber '_targetmasked.img ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_affine_lhm.img']);
end

% do smoothing
%lhmtarget = avw_img_read([orig_target_STS_padded.fileprefix '.img']);
% or maybe do smoothing on masked target?
lhmtarget = avw_img_read([dataoutputdirectoryname patientnumber '_targetmasked.img']);
lhmtarget.img = imgaussfilt3(lhmtarget.img,0.75);
lhmtarget.fileprefix = [dataoutputdirectoryname patientnumber '_targetsmoothed'];
avw_img_write(lhmtarget, lhmtarget.fileprefix);

lhmatlas = avw_img_read([dataoutputdirectoryname patientnumber '_affine_lhm.img']);
lhmatlas.img = imgaussfilt3(lhmatlas.img,0.75);
lhmatlas.fileprefix = [dataoutputdirectoryname patientnumber '_affine_lhmsmooth'];
avw_img_write(lhmatlas,lhmatlas.fileprefix);

% the masks
atlasmask = avw_img_read([dataoutputdirectoryname patientnumber '_atlasmask_affine.img']);
targetmask = avw_img_read([dataoutputdirectoryname patientnumber '_targetmask.img']);

% smooth the masks
atlasmasksmoothed = atlasmask;
atlasmasksmoothed.fileprefix = [dataoutputdirectoryname patientnumber '_atlasmasksmoothed'];
atlasmasksmoothed.img = imgaussfilt3(atlasmask.img,1.5);
atlasmasksmoothed.hdr.dime.datatype = 16;
atlasmasksmoothed.hdr.dime.bitpix = 32;
avw_img_write(atlasmasksmoothed,atlasmasksmoothed.fileprefix);

targetmasksmoothed = targetmask;
targetmasksmoothed.fileprefix = [dataoutputdirectoryname patientnumber '_targetmasksmoothed'];
targetmasksmoothed.img = imgaussfilt3(targetmask.img,1.5);
avw_img_write(targetmasksmoothed,targetmasksmoothed.fileprefix);


% do lddmm
lddmmoutputdirectoryname = [patientnumber '_lddmm7'];

%system(['./mm_lddmm2n_ver03_evensmallersig.pl 2 ' lhmatlas.fileprefix '.img ' lhmtarget.fileprefix '.img 0.2 '  dataoutputdirectoryname patientnumber '_atlasmask_affine.img ' dataoutputdirectoryname patientnumber '_targetmask.img 0.1 ' dataoutputdirectoryname lddmmoutputdirectoryname ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);

system(['./mm_lddmm2n_ver03_evensmallersig.pl 2 ' lhmatlas.fileprefix '.img ' lhmtarget.fileprefix '.img 0.4 ' atlasmasksmoothed.fileprefix '.img ' targetmasksmoothed.fileprefix '.img 0.075 ' dataoutputdirectoryname lddmmoutputdirectoryname ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);

% apply transform to annotation
system(['./IMG_apply_lddmm_tform1 ' dataoutputdirectoryname patientnumber '_annotation_affine.img ' dataoutputdirectoryname lddmmoutputdirectoryname '/Hmap000.vtk ' dataoutputdirectoryname lddmmoutputdirectoryname '/' patientnumber '_annotation.img 2']);

% post processing transform files
%system(['python convertVTK.py ' dataoutputdirectoryname patientnumber '_lddmm/Hmap000.vtk ' dataoutputdirectoryname patientnumber '_lddmm/Kimap000.vtk ' transformdirectoryname 'field_forward.vtk ' transformdirectoryname 'field_reverse.vtk 0.08']);



