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
dataoutputdirectoryname = '/sonas-hs/mitra/hpc/home/blee/data/registration/M920/';
mkdir(dataoutputdirectoryname);
transformdirectoryname = [dataoutputdirectoryname 'transforms/'];
mkdir(transformdirectoryname);

orig_target_STS.fileprefix = [dataoutputdirectoryname '/' patientnumber '_orig_target_STS'];

%% pad the target image
orig_target_STS = avw_img_read(orig_target_STS.fileprefix,0);
orig_target_STS_padded = orig_target_STS;
orig_target_STS_padded.img = zeros([size(orig_target_STS.img,1), size(orig_target_STS.img,2)+40,size(orig_target_STS.img,3)]);
orig_target_STS_padded.img(:,21:end-20,:) = orig_target_STS.img;
orig_target_STS_padded.hdr.dime.dim(2:4) = size(orig_target_STS_padded.img);
orig_target_STS_padded.fileprefix = [dataoutputdirectoryname '/' patientnumber '_orig_target_STS_padded'];
avw_img_write(orig_target_STS_padded, orig_target_STS_padded.fileprefix);

%% rigidly register the atlas to the target
targetfilename = [orig_target_STS_padded.fileprefix '.img'];
system(['python rigidAlignMarmosetAtlas.py ' atlasfilename ' ' targetfilename ' ' annofilename ' ' atlasmaskfilename ' ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_annotation_affine.img ' dataoutputdirectoryname patientnumber '_atlasmask_affine.img ' dataoutputdirectoryname patientnumber '_globalaffinetrans.txt']);


