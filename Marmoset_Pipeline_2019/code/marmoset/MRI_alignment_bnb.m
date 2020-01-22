function MRI_alignment_bnb(patientnumber)

% target and atlas filenames
%patientnumber = 'M921';
%targetfilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_cropped.img';
atlasfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_80_flip_masked_eroded.img';
atlasmaskfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_80_flip.img';
annofilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_80_flip.img';
%mrifilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/MRI_rigid.img';

% input directories
targetdirectoryprefix = '/sonas-hs/mitra/hpc/home/blee/data/target_images/';
outputtargetfilename = [targetdirectoryprefix patientnumber '/' patientnumber '_80_full_cropped'];
%rawmrifilename = [targetdirectoryprefix patientnumber '/20160528_21095708DTI128axb1000news180001a001.nii'];
outputmrifilename = [targetdirectoryprefix patientnumber '/' patientnumber '_mri_full'];
targetfilename = outputtargetfilename;
mrifilename = outputmrifilename;

% pre process
%marmosetRegistration_pre_bnb(patientnumber,targetdirectoryprefix,outputtargetfilename,rawmrifilename,outputmrifilename,[100,383,137,416]);

% output directories
dataoutputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/registration/' patientnumber '/'];
mkdir(dataoutputdirectoryname);
transformdirectoryname = [dataoutputdirectoryname 'transforms/'];
mkdir(transformdirectoryname);

%% rigid align MRI to target
system(['python rigidAlignMRI.py ' mrifilename ' ' targetfilename ' ' dataoutputdirectoryname patientnumber '_MRI_rigid.img ' transformdirectoryname patientnumber '_MRI_rigidtrans.txt']);

%% start section alignment with MRI
target = avw_img_read(targetfilename,0);
MRI = avw_img_read([dataoutputdirectoryname patientnumber '_MRI_rigid.img'],0);


a_old = zeros(1,size(MRI.img,2)); % x trnalsation
b_old = zeros(1,size(MRI.img,2)); % y translation
theta_old = zeros(1,size(MRI.img,2)); % rotation
nepochs = 8; % total iterations of the process, change to whatever
newtarget = target;
newMRI = MRI;
newMRI.fileprefix = [dataoutputdirectoryname 'MRI_iter0'];
avw_img_write(newMRI,newMRI.fileprefix);
% start main loop
for i = 1:nepochs
    % do the section alignment 
    niter = 150;
    %[output,a,b,theta] = slice_alignment_walk_withatlas(newtarget, newMRI.img, 'MSE', niter, a_old, b_old, theta_old,'linear');
    [output,a,b,theta] = slice_alignment_walk_withatlas_marmoset(target, newMRI.img, 'MSE', niter, a_old, b_old, theta_old,'linear',1);
    saveSectionTransforms(a,b,theta,transformdirectoryname, ['iter' num2str(i)]); %TODO: fill out your filenames
    
    % combine section alignment parameters for each epoch
    a_old = a+a_old;
    b_old = b+b_old;
    theta_old = theta+theta_old;
    
    % apply the section transforms to the original target image
    newtarget = applySectionTransformsCoronal(target, a_old, b_old, theta_old, 'linear');%%%
    newtarget.fileprefix = [dataoutputdirectoryname 'target_iter' num2str(i)];
    avw_img_write(newtarget,newtarget.fileprefix);
    
    % do rigid registration again
    if i < nepochs
        system(['python rigidAlignMRI_simulations.py ' newMRI.fileprefix '.img ' newtarget.fileprefix '.img ' dataoutputdirectoryname 'MRI_iter' num2str(i) '.img ' transformdirectoryname 'MRI_transform_iter' num2str(i) '.txt']);
        newMRI = avw_img_read([dataoutputdirectoryname 'MRI_iter' num2str(i) '.img'],0);
    end
    %system('python')
    %import sys
    %sys.path.append('/cis/home/fuyan/python/')
    %import reg3D
    %reg3D.reg('/cis/home/fuyan/my_documents/sectionalignment/MRIalign/newMRI.img','/cis/home/fuyan/my_documents/sectionalignment/MRIalign/newtarget.img','/cis/home/fuyan/my_documents/sectionalignment/MRIalign/transform/newMRI')
    %exit()
end

%% generate second Xform file
orig_target_STS = transformOriginalTargetImage(targetfilename,transformdirectoryname,nepochs);
orig_target_STS.fileprefix = [dataoutputdirectoryname '/' patientnumber '_orig_target_STS'];
avw_img_write(orig_target_STS, orig_target_STS.fileprefix);

missingsliceind = [];
for i = 1:size(orig_target_STS.img,2)
    if size(unique(orig_target_STS.img(:,i,:)),1) < 3
        missingsliceind = [missingsliceind i];
    end
end
fid = fopen([transformdirectoryname patientnumber '_XForm.txt'],'w');
fid2 = fopen([transformdirectoryname patientnumber '_XForm_matrix.txt'],'w');
a_old(missingsliceind) = [];
b_old(missingsliceind) = [];
theta_old(missingsliceind) = [];
for i = 1:length(a_old)
    R = [cos(theta_old(i)) -sin(theta_old(i)) a_old(i);sin(theta_old(i)) cos(theta_old(i)) b_old(i); 0 0 1];
    fprintf(fid, '%f,%f,1,1,%d,%d,%f,%f,%f,%f,%f,%d,%d,%d\n',0,0,orig_target_STS.hdr.dime.dim(4),orig_target_STS.hdr.dime.dim(2),theta_old(i),double(orig_target_STS.hdr.dime.dim(4))/2,double(orig_target_STS.hdr.dime.dim(2))/2,b_old(i),a_old(i), 0,0,0);
    fprintf(fid2,'%f,%f,%f,%f,%f,%f,%f,%f,\n', R(1,1), R(1,2), R(2,1), R(2,2), R(1,3), R(2,3), double(orig_target_STS.hdr.dime.dim(4))/2*double(orig_target_STS.hdr.dime.pixdim(4)),double(orig_target_STS.hdr.dime.dim(2))/2*double(orig_target_STS.hdr.dime.pixdim(2)));
end
fclose(fid);
fclose(fid2);

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


%% do lddmm from atlas to target
% mask the target
system(['python maskMarmosetTarget.py ' orig_target_STS_padded.fileprefix '.img ' dataoutputdirectoryname patientnumber '_targetmask.img ' dataoutputdirectoryname patientnumber '_targetmasked.img']);

% maybe do histogram matching
localhist = 0;
if localhist == 1
    %system("matlab -nodesktop -singleCompThread -nojvm -nodisplay -r \"histmatch_daniel(\'/cis/home/leebc/Projects/Mouse_Histology/data/registration/" + patientnumber + "/" + patientnumber + "_targetmasked.img\', \'/cis/home/leebc/Projects/Mouse_Histology/data/registration/" + patientnumber + "/" + patientnumber + "_affine.img\',false);exit\"")
else
    system(['python histogramMatchingMarmoset.py ' dataoutputdirectoryname patientnumber '_targetmasked.img ' dataoutputdirectoryname patientnumber '_affine.img ' dataoutputdirectoryname patientnumber '_affine_lhm.img']);
end

% do smoothing
%lhmtarget = avw_img_read([orig_target_STS_padded.fileprefix '.img']);
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

lddmmoutputdirectoryname = [patientnumber '_lddmm'];

% do lddmm
system(['./mm_lddmm2n_ver03_evensmallersig.pl 2 ' lhmatlas.fileprefix '.img ' lhmtarget.fileprefix '.img 0.4 ' atlasmasksmoothed.fileprefix '.img ' targetmasksmoothed.fileprefix '.img 0.075 ' dataoutputdirectoryname lddmmoutputdirectoryname ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);
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
