function MRI_alignment_maskcost_bnb_lddmmonly(patientnumber)

% target and atlas filenames
%patientnumber = 'M921';
%targetfilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_cropped.img';
atlasfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_80_flip_masked_eroded.img';
atlasmaskfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_80_flip.img';
annofilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_80_flip.img';
%mrifilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/MRI_rigid.img';

% input directories
targetdirectoryprefix = '/sonas-hs/mitra/hpc/home/blee/data/stackalign/';
outputtargetfilename = [targetdirectoryprefix patientnumber 'N/' patientnumber '_80_full_cropped'];
%rawmrifilename = [targetdirectoryprefix patientnumber '/20160528_21095708DTI128axb1000news180001a001.nii'];
mridirectoryprefix = '/sonas-hs/mitra/hpc/home/blee/data/target_images/';
outputmrifilename = [mridirectoryprefix patientnumber '/' patientnumber '_mri_full'];
targetfilename = outputtargetfilename;
mrifilename = outputmrifilename;

% pre process
%marmosetRegistration_pre_bnb(patientnumber,targetdirectoryprefix,outputtargetfilename,rawmrifilename,outputmrifilename,[100,383,137,416]);

% output directories
dataoutputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/registration/' patientnumber '_maskhist/'];
mkdir(dataoutputdirectoryname);
transformdirectoryname = [dataoutputdirectoryname 'transforms/'];
mkdir(transformdirectoryname);

costmask.fileprefix = [dataoutputdirectoryname '/' patientnumber '_costmask'];
orig_target_STS.fileprefix = [dataoutputdirectoryname '/' patientnumber '_orig_target_STS'];
%orig_target_STS.fileprefix = '/sonas-hs/mitra/hpc/home/blee/data/target_images/M918/M918_80_full_cropped_new';

targetfilename = [orig_target_STS.fileprefix '.img'];


%% do lddmm from atlas to target
% mask the target
%system(['python maskMarmosetTarget.py ' orig_target_STS_padded.fileprefix '.img ' dataoutputdirectoryname patientnumber '_targetmask.img ' dataoutputdirectoryname patientnumber '_targetmasked.img']);
system(['python maskMarmosetTarget.py ' orig_target_STS.fileprefix '.img ' dataoutputdirectoryname patientnumber '_targetmask.img ' dataoutputdirectoryname patientnumber '_targetmasked.img']);

% now do rigid matching after masking
system(['python rigidAlignMarmosetAtlas_maskcost.py ' atlasfilename ' ' dataoutputdirectoryname patientnumber '_targetmasked.img ' annofilename ' ' atlasmaskfilename ' ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_annotation_affine.img ' dataoutputdirectoryname patientnumber '_atlasmask_affine.img ' dataoutputdirectoryname patientnumber '_globalaffinetrans.txt ' costmask.fileprefix '.img']);

% maybe do histogram matching
localhist = 0;
if localhist == 1
    histmatch_daniel_whiten_icm([dataoutputdirectoryname '/' patientnumber '_affine.img'], [patientnumber],false, [dataoutputdirectoryname '/' patientnumber '_affine_lhm']);
    histmatch_daniel_whiten_icm([dataoutputdirectoryname '/' patientnumber '_targetmasked.img'], [patientnumber],false, [dataoutputdirectoryname '/' patientnumber '_targetmasked_lhm']);
    %system("matlab -nodesktop -singleCompThread -nojvm -nodisplay -r \"histmatch_daniel(\'/cis/home/leebc/Projects/Mouse_Histology/data/registration/" + patientnumber + "/" + patientnumber + "_targetmasked.img\', \'/cis/home/leebc/Projects/Mouse_Histology/data/registration/" + patientnumber + "/" + patientnumber + "_affine.img\',false);exit\"")
else
    % mask atlas image before histogram matching, then rescale intensities towards 255
    atlas_forhist = avw_img_read([dataoutputdirectoryname '/' patientnumber '_affine.img'],0);
    atlasmask_forhist = avw_img_read([dataoutputdirectoryname patientnumber '_atlasmask_affine.img'],0);
    atlas_forhist.img(find(atlasmask_forhist.img==0)) == 0;
    atlas_forhist.img(find(atlasmask_forhist.img==1)) = atlas_forhist.img(find(atlasmask_forhist.img==1)) + 50;
    atlas_forhist.img(find(atlasmask_forhist.img==1)) = atlas_forhist.img(find(atlasmask_forhist.img==1)) ./ (max(max(max(atlas_forhist.img(find(atlasmask_forhist.img==1)))))/255.0);
    atlas_forhist.fileprefix = [dataoutputdirectoryname '/' patientnumber '_affine_forhist'];
    avw_img_write(atlas_forhist,atlas_forhist.fileprefix);
    system(['python histogramMatchingMarmoset.py ' dataoutputdirectoryname patientnumber '_targetmasked.img ' dataoutputdirectoryname patientnumber '_affine_forhist.img ' dataoutputdirectoryname patientnumber '_affine_lhm.img']);
end

% do smoothing
%lhmtarget = avw_img_read([orig_target_STS_padded.fileprefix '.img']);
if localhist == 0
    lhmtarget = avw_img_read([dataoutputdirectoryname patientnumber '_targetmasked.img']);
else
    lhmtarget = avw_img_read([dataoutputdirectoryname patientnumber '_targetmasked_lhm.img']);
end
if localhist == 1
    lhmtarget.img(targetmask.img==0) = 0;
end
lhmtarget.img = imgaussfilt3(lhmtarget.img,0.75);
lhmtarget.fileprefix = [dataoutputdirectoryname patientnumber '_targetsmoothed'];
avw_img_write(lhmtarget, lhmtarget.fileprefix);

lhmatlas = avw_img_read([dataoutputdirectoryname patientnumber '_affine_lhm.img']);
if localhist == 1
    lhmatlas.img(atlasmask.img==0) = 0;
end
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

lddmmoutputdirectoryname = [patientnumber '_lddmm'];

% do lddmm
system(['./mm_lddmm2n_ver03_weightonatlas_evensmallersig.pl 2 ' lhmatlas.fileprefix '.img ' lhmtarget.fileprefix '.img ' costmask.fileprefix '.img 0.2 ' atlasmasksmoothed.fileprefix '.img ' targetmasksmoothed.fileprefix '.img ' costmask.fileprefix '.img 0.03 ' dataoutputdirectoryname lddmmoutputdirectoryname ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);
%system(['./mm_lddmm2n_ver03_evensmallersig.pl 2 ' lhmatlas.fileprefix '.img ' lhmtarget.fileprefix '.img 0.4 ' atlasmasksmoothed.fileprefix '.img ' targetmasksmoothed.fileprefix '.img 0.075 ' dataoutputdirectoryname lddmmoutputdirectoryname ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);
%system(['./mm_lddmm2n_ver03_evensmallersig.pl 2 ' lhmatlas.fileprefix '.img ' lhmtarget.fileprefix '.img 0.4 '  dataoutputdirectoryname patientnumber '_atlasmask_affine.img ' dataoutputdirectoryname patientnumber '_targetmask.img 0.075 ' dataoutputdirectoryname patientnumber '_lddmm 3 0.05 10 0.02 10 0.01 10 1 1 1.0'])

%system(['./mm_lddmm2n_ver03_evensmallersig.pl 1 ' lhmatlas.fileprefix '.img ' lhmtarget.fileprefix '.img 0.1 ' dataoutputdirectoryname patientnumber '_lddmm 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);

% apply transform to annotation
system(['./IMG_apply_lddmm_tform1 ' dataoutputdirectoryname patientnumber '_annotation_affine.img ' dataoutputdirectoryname patientnumber '_lddmm/Hmap000.vtk ' dataoutputdirectoryname patientnumber '_annotation.img 2']);

% apply transform to atlas
system(['./IMG_apply_lddmm_tform1 ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_lddmm/Hmap000.vtk ' dataoutputdirectoryname patientnumber '_defatlas.img 1']);

% apply transform to atlas mask
system(['./IMG_apply_lddmm_tform1 ' dataoutputdirectoryname patientnumber '_atlasmask_affine.img ' dataoutputdirectoryname patientnumber '_lddmm/Hmap000.vtk ' dataoutputdirectoryname patientnumber '_atlasmasklddmm.img 2']);

% post processing transform files
system(['python convertVTK.py ' dataoutputdirectoryname patientnumber '_lddmm/Hmap000.vtk ' dataoutputdirectoryname patientnumber '_lddmm/Kimap000.vtk ' transformdirectoryname 'field_forward.vtk ' transformdirectoryname 'field_reverse.vtk 0.08']);



end
