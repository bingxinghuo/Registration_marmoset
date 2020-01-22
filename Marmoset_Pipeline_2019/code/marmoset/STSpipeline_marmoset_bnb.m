%% now try with 40um target and 40um atlas
%patientnumber = 'PMD2493';
function STSpipeline_marmoset_bnb(patientnumber)
%% run the preprocessing
parentoutputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/registration/' patientnumber];
candirectoryname = '/sonas-hs/mitra/hpc/home/blee/code/can/';
atlasdirectoryname = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/';
targetdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/stackalign/' patientnumber 'N'];

atlasfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_80_flip_masked_eroded_refined.img';
atlasmaskfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_80_flip_refined.img';
annofilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_80_flip.img';

%targetdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/target_images/interpolated'];

dataoutputdirectoryname = [parentoutputdirectoryname '/' patientnumber '_STSpipeline_output/'];
mkdir(dataoutputdirectoryname);
outputdirectoryname = [dataoutputdirectoryname 'images_targetdef/'];
mkdir(outputdirectoryname)
transformdirectoryname = [dataoutputdirectoryname 'transforms/'];
mkdir(transformdirectoryname)


% do target realignment
system(['python alignTargetHorizontal_marmoset.py ' patientnumber ' ' targetdirectoryname '/' patientnumber '_80_full_cropped.img ' parentoutputdirectoryname ' ' patientnumber '_80_full_firstalign.img ' transformdirectoryname]);

% apply target realignment transform to the raw tifs and produce 100um downsampled volume too
system(['python applySTSCompositeTransform_step1.py ' patientnumber ' /sonas-hs/mitra/hpc/home/blee/data/stackalign/' patientnumber 'N/' patientnumber '_N_XForm_matrix.txt /sonas-hs/mitra/hpc/home/blee/data/stackalign/' patientnumber 'N/' patientnumber '_N_XForm.txt ' transformdirectoryname '/' patientnumber '_XForm_firstrotation_matrix.txt ' parentoutputdirectoryname]);

% pad the ends of the image
frontpad = 40;
backpad = 15;
temptarget = avw_img_read([parentoutputdirectoryname '/' patientnumber '_80_full_firstalign.img'],0);
%bgval = temptarget.img(1,1,1);
paddedtargetvol = zeros(size(temptarget.img,1), size(temptarget.img,2)+frontpad+backpad, size(temptarget.img,3));
paddedtargetvol(:,frontpad+1:end-backpad,:) = temptarget.img;
paddedtarget = temptarget;
paddedtarget.img = paddedtargetvol;
paddedtarget.hdr.dime.dim(2:4) = size(paddedtargetvol);
paddedtarget.fileprefix = [parentoutputdirectoryname '/' patientnumber '_80_full_firstalign_padded'];
avw_img_write(paddedtarget,paddedtarget.fileprefix);
clear paddedtargetvol temptarget

% pad the downsampled target
%frontpad_ds = frontpad/2.5;
%backpad_ds = backpad/2.5;
%temptarget = avw_img_read([parentoutputdirectoryname '/' patientnumber '_100_full_firstalign.img'],0);
%%bgval = temptarget.img(1,1,1);
%paddedtargetvol = zeros(size(temptarget.img,1), size(temptarget.img,2)+frontpad_ds+backpad_ds, size(temptarget.img,3));
%paddedtargetvol(:,frontpad_ds+1:end-backpad_ds,:) = temptarget.img;
%paddedtarget_ds = temptarget;
%paddedtarget_ds.img = paddedtargetvol;
%paddedtarget_ds.hdr.dime.dim(2:4) = size(paddedtargetvol);
%paddedtarget_ds.fileprefix = [parentoutputdirectoryname '/' patientnumber '_100_full_firstalign_padded'];
%avw_img_write(paddedtarget_ds,paddedtarget_ds.fileprefix);
%clear paddedtargetvol temptarget

% generate cost function mask
costmask = make_blank_img();
costmask.img = ones(size(paddedtarget.img));
for i = 1:size(costmask.img,2)
    if length(unique(paddedtarget.img(:,i,:))) <= 2
        % set to background value instead of 0? for hist matching?
        costmask.img(:,i,:) = 0;
    end
end
costmask.hdr.dime.dim(2:4) = size(costmask.img);
costmask.hdr.dime.pixdim(2:4) = paddedtarget.hdr.dime.pixdim(2:4);
costmask.hdr.dime.datatype = 2;
costmask.hdr.dime.bitpix = 8;
costmask.hdr.dime.glmax = 1;
costmask.fileprefix = [parentoutputdirectoryname '/' patientnumber '_costmask'];
avw_img_write(costmask,costmask.fileprefix);

% now run the preprocessing
%system(['python mouseRegistration_pre_nowhiten_maskcost_bnb.py ' patientnumber ' ' parentoutputdirectoryname ' ' atlasdirectoryname ' ' parentoutputdirectoryname  ' ' candirectoryname ' ' costmask.fileprefix '.img']);

if strcmp(patientnumber,'M918')
system(['python maskMarmosetTargetBySlice.py ' parentoutputdirectoryname '/' patientnumber '_80_full_firstalign_padded.img ' dataoutputdirectoryname patientnumber '_targetmask.img ' dataoutputdirectoryname patientnumber '_targetmasked.img']);
else
system(['python maskMarmosetTarget.py ' parentoutputdirectoryname '/' patientnumber '_80_full_firstalign_padded.img ' dataoutputdirectoryname patientnumber '_targetmask.img ' dataoutputdirectoryname patientnumber '_targetmasked.img']);
end


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

%system(['python mouseRegistration_pre_nowhiten_bnb.py ' patientnumber ' ' parentoutputdirectoryname ' ' atlasdirectoryname ' ' targetdirectoryname  ' ' candirectoryname]);

%% run the STS

parentoutputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/registration/' patientnumber];
candirectoryname = '/sonas-hs/mitra/hpc/home/blee/code/can/';

atlas = avw_img_read([dataoutputdirectoryname '/' patientnumber '_affine_lhm.img'],0);
target = avw_img_read([dataoutputdirectoryname '/' patientnumber '_targetsmoothed.img'],0);
orig_atlasmask = avw_img_read([dataoutputdirectoryname '/' patientnumber '_atlasmask_affine.img'],0);
orig_targetmask = avw_img_read([dataoutputdirectoryname '/' patientnumber '_targetmask.img'],0);


anoOutImg = avw_img_read([dataoutputdirectoryname '/' patientnumber '_annotation_affine.img'],0);
%mymcmask = avw_img_read([parentoutputdirectoryname '/' patientnumber '_mymcmask.img'],0);



%dataoutputdirectoryname = [parentoutputdirectoryname '/' patientnumber '_STSpipeline_output/'];
%mkdir(dataoutputdirectoryname);
%outputdirectoryname = [dataoutputdirectoryname 'images_targetdef/'];
%mkdir(outputdirectoryname)
%transformdirectoryname = [dataoutputdirectoryname 'transforms/'];
%mkdir(transformdirectoryname)


anoOutImgname = [dataoutputdirectoryname 'anoOutImgRot'];
anoOutImg.fileprefix = anoOutImgname;
%mymcmask.fileprefix = [dataoutputdirectoryname 'mymcmaskRot'];
avw_img_write(anoOutImg, anoOutImg.fileprefix);
%avw_img_write(mymcmask, mymcmask.fileprefix);

% dont put the coronal axis in the 3rd dimension
J = atlas.img;
I = target.img;
Jmask = orig_atlasmask.img;
Imask = orig_targetmask.img;


% pad the images so they are the same size
I_pad = zeros(max([size(I);size(J)]));
J_pad = zeros(max([size(I);size(J)]));
I_pad(1:size(I,1),1:size(I,2),1:size(I,3)) = I;
J_pad(1:size(J,1),1:size(J,2),1:size(J,3)) = J;
Imask_pad = zeros(max([size(I);size(J)]));
Jmask_pad = zeros(max([size(I);size(J)]));
Imask_pad(1:size(I,1),1:size(I,2),1:size(I,3)) = Imask;
Jmask_pad(1:size(J,1),1:size(J,2),1:size(J,3)) = Jmask;

atlasoutput = make_blank_img();
atlasoutput.img = J_pad;
atlasoutput.hdr.dime.dim(2:4) = size(J_pad);
atlasoutput.hdr.dime.pixdim(2:4) = [0.08,0.08,0.08];
atlasoutput.hdr.dime.glmax = max(max(max(J_pad)));
atlasoutput.fileprefix = [dataoutputdirectoryname 'wtlddmmoutput_iter0'];
atlasoutput.hdr.dime.datatype = 16;
atlasoutput.hdr.dime.bitpix = 32;
avw_img_write(atlasoutput,atlasoutput.fileprefix);

orig_atlasoutput = atlasoutput;

output = make_blank_img();
output.img = I_pad;
output.hdr.dime.dim(2:4) = size(I_pad);
output.hdr.dime.glmax = max(max(max(I_pad)));
output.hdr.dime.pixdim(2:4) = [0.08,0.08,0.08];
output.hdr.dime.datatype = 16;
output.hdr.dime.bitpix = 32;

orig_output = output;

atlasmask = make_blank_img();
atlasmask.img = Jmask_pad;
atlasmask.hdr.dime.dim(2:4) = size(Jmask_pad);
atlasmask.hdr.dime.pixdim(2:4) = [0.08,0.08,0.08];
atlasmask.hdr.dime.glmax = max(max(max(Jmask_pad)));
atlasmask.fileprefix = [dataoutputdirectoryname 'wtlddmmmask_iter0'];
avw_img_write(atlasmask,atlasmask.fileprefix);

orig_atlasmask = atlasmask;

targetmask = make_blank_img();
targetmask.img = Imask_pad;
targetmask.hdr.dime.dim(2:4) = size(Imask_pad);
targetmask.hdr.dime.pixdim(2:4) = [0.08,0.08,0.08];
targetmask.hdr.dime.glmax = max(max(max(Imask_pad)));
targetmask.fileprefix = [dataoutputdirectoryname 'wtmask_iter0'];
avw_img_write(targetmask,targetmask.fileprefix);

orig_targetmask = targetmask;


clear Imask_pad Jmask_pad I_pad J_pad I J Imask Jmask target atlas anoOutImg

figure(777);clf
subplot(1,3,2)
imagesc(squeeze(output.img(:,:,120)))
title('realigned target')
axis image
caxis([0 255])
subplot(1,3,3)
imagesc(squeeze(atlasoutput.img(:,:,120)))
title('morphed fake atlas')
axis image
caxis([0 255])
subplot(1,3,1)
imagesc(squeeze(orig_atlasoutput.img(:,:,120)))
title('true atlas')
axis image
caxis([0 255])
saveas(777,[outputdirectoryname 'slice55_iter0.bmp'],'bmp');
figure(777);clf
subplot(1,3,2)
imagesc(squeeze(output.img(:,:,80)))
title('realigned target')
axis image
caxis([0 255])
subplot(1,3,3)
imagesc(squeeze(atlasoutput.img(:,:,80)))
title('morphed fake atlas')
axis image
caxis([0 255])
subplot(1,3,1)
imagesc(squeeze(orig_atlasoutput.img(:,:,80)))
title('true atlas')
axis image
caxis([0 255])
saveas(777,[outputdirectoryname 'slice30_iter0.bmp'],'bmp');

a_old = zeros(1,size(output.img,2));
b_old = zeros(1,size(output.img,2));
theta_old = zeros(1,size(output.img,2));
nepochs = 7;
for i = 1:nepochs
    % run one iteration of section alignment
    if i < 3
        niter = 140;
    elseif i == nepochs
        niter = 300;
    else
        niter = 220;
    end
    [output,a,b,theta] = slice_alignment_walk_withatlas_marmoset(orig_output, atlasoutput.img, 'MSE', niter, a_old, b_old, theta_old,'linear',1);
    saveSectionTransforms(a,b,theta,[dataoutputdirectoryname 'transforms'], ['iter' num2str(i)]);
    a_old = a+a_old;
    b_old = b+b_old;
    theta_old = theta+theta_old;
    output = applySectionTransformsCoronal(orig_output,a_old, b_old, theta_old, 'linear');
    if i == nepochs
        saveSectionTransforms(a_old, b_old, theta_old, [dataoutputdirectoryname 'transforms'], 'final');
    end
    
    % load the mask image and apply the transforms to the mask
    targetmask = applySectionTransformsCoronal(orig_targetmask,a_old,b_old,theta_old,'nearest');
    
    % save output to file
    output.fileprefix = [dataoutputdirectoryname 'wtoutput_iter' num2str(i)];
    avw_img_write(output, output.fileprefix);
    targetmask.fileprefix = [dataoutputdirectoryname 'wtmask_iter' num2str(i)];
    avw_img_write(targetmask, targetmask.fileprefix);
    
    % do smoothing and ventricle removal in prep for lddmm
    % consider doing histogram matching here on the deformed original
    %target instead of just interpolating the histmatched target
    atlasremfile = [dataoutputdirectoryname 'wtlddmmoutputrem_iter' num2str(i)];
    targetremfile = [dataoutputdirectoryname 'wtoutputrem_iter' num2str(i)];
    origRefImgSmoothed = imgaussfilt3(output.img,0.75);
    histmatchedTemplateSmoothed = imgaussfilt3(atlasoutput.img,0.75);
    
    if i == 1
        anoOutImgRotCurrent = avw_img_read(anoOutImgname);
    else
        system([candirectoryname 'BIN/IMG_apply_lddmm_tform1 ' anoOutImgname '.img ' dataoutputdirectoryname 'Hmap_composed.vtk ' dataoutputdirectoryname '/anoOutImgRot_iter' num2str(i) '.img 2']);
        anoOutImgRotCurrent = avw_img_read([dataoutputdirectoryname '/anoOutImgRot_iter' num2str(i) '.img']);
    end
    
    %histmatchedTemplateSmoothed(find(anoOutImgRotCurrent.img==145)) = 0;
    %histmatchedTemplateSmoothed(find(anoOutImgRotCurrent.img==81)) = 0;
    %histmatchedTemplateSmoothed(find(anoOutImgRotCurrent.img==129)) = 0;
    clear anoOutImgRotCurrent
    
    atlasoutputrem = atlasoutput;
    atlasoutputrem.img = histmatchedTemplateSmoothed;
    atlasoutputrem.fileprefix = atlasremfile;
    avw_img_write(atlasoutputrem, atlasoutputrem.fileprefix);
    clear histmatchedTemplateSmoothed
    
    outputrem = output;
    
    % deform mymcmaskRot based on a_old, b_old, theta_old
    %mymcmaskCurrent = applySectionTransformsCoronal(mymcmask,a_old,b_old,theta_old,'nearest');
    origRefImgSmoothed(find(targetmask.img==0)) = 0;
    outputrem.img = origRefImgSmoothed;
    outputrem.fileprefix = targetremfile;
    avw_img_write(outputrem, outputrem.fileprefix);
    %clear mymcmaskCurrent
    
    % call LDDMM
    if i == nepochs
        alpha = 0.02;
        iterations = 1000;
        %system([candirectoryname 'mm_lddmm2n_ver03_evensmallersig.pl 1 ' atlasoutputrem.fileprefix '.img ' outputrem.fileprefix '.img 0.4 ' dataoutputdirectoryname patientnumber '_lddmm' num2str(i) ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);
        %system([candirectoryname 'mm_lddmm2n_ver03_evensmallersig.pl 1 ' atlasoutputrem.fileprefix '.img ' outputrem.fileprefix '.img 0.4 ' dataoutputdirectoryname patientnumber '_lddmm' num2str(i) ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);
        system([candirectoryname '/mm_lddmm2n_ver03_weightonatlas_evensmallersig.pl 2 ' atlasoutputrem.fileprefix '.img ' outputrem.fileprefix '.img ' costmask.fileprefix '.img 0.25 ' atlasmask.fileprefix '.img ' targetmask.fileprefix '.img ' costmask.fileprefix '.img 0.03 ' dataoutputdirectoryname patientnumber '_lddmm' num2str(i) ' 3 0.05 10 0.02 10 0.01 10 1 1 1.0']);
    else
        alpha = 0.02;
        %iterations = 6 + round(1.5*i);
        if i < 3
            iterations = 20;
        else
            iterations = 20 + max(6,round(i/2));
        end
        imagefraction = 0.85;
        system([candirectoryname '/mm_lddmm2n_ver03_weightonatlas_simulations.pl 1 ' atlasoutputrem.fileprefix '.img ' outputrem.fileprefix '.img ' costmask.fileprefix '.img 0.4 ' dataoutputdirectoryname patientnumber '_lddmm' num2str(i) ' 1 0.065 10 1 1 1.0 ' num2str(iterations) ' ' num2str(imagefraction)]);
    end
    
    % compose the hmap files and then transform the original atlas image
    % and the atlas mask
    commandstring = [candirectoryname 'BIN/VTK_combine_maps_ver5 ' num2str(i)];
    for ii = 1:i
        commandstring = [commandstring ' ' dataoutputdirectoryname patientnumber '_lddmm' num2str(ii) '/Hmap000.vtk'];
    end
    commandstring = [commandstring ' ' dataoutputdirectoryname 'Hmap_composed.vtk'];
    system(commandstring)
    system([candirectoryname 'BIN/IMG_apply_lddmm_tform1 ' orig_atlasoutput.fileprefix '.img ' dataoutputdirectoryname 'Hmap_composed.vtk ' dataoutputdirectoryname '/wtlddmmoutput_iter' num2str(i) '.img 1']);
    system([candirectoryname 'BIN/IMG_apply_lddmm_tform1 ' orig_atlasmask.fileprefix '.img ' dataoutputdirectoryname 'Hmap_composed.vtk ' dataoutputdirectoryname '/wtlddmmmask_iter' num2str(i) '.img 2']);
    
    
    % load images from metamorphosis
    atlasoutput = avw_img_read([dataoutputdirectoryname 'wtlddmmoutput_iter' num2str(i) '.img'],0);
    atlasmask = avw_img_read([dataoutputdirectoryname 'wtlddmmmask_iter' num2str(i) '.img'],0);
    
    % draw images
    figure(777);clf
    subplot(1,3,2)
    imagesc(squeeze(output.img(:,:,120)))
    title('realigned target')
    axis image
    caxis([0 255])
    subplot(1,3,3)
    imagesc(squeeze(atlasoutput.img(:,:,120)))
    title('morphed fake atlas')
    axis image
    caxis([0 255])
    subplot(1,3,1)
    imagesc(squeeze(orig_atlasoutput.img(:,:,120)))
    title('true atlas')
    axis image
    caxis([0 255])
    saveas(777,[outputdirectoryname 'slice55_iter' num2str(i) '.bmp'],'bmp');
    
    % draw images
    figure(777);clf
    subplot(1,3,2)
    imagesc(squeeze(output.img(:,:,80)))
    title('realigned target')
    axis image
    caxis([0 255])
    subplot(1,3,3)
    imagesc(squeeze(atlasoutput.img(:,:,80)))
    title('morphed fake atlas')
    axis image
    caxis([0 255])
    subplot(1,3,1)
    imagesc(squeeze(orig_atlasoutput.img(:,:,80)))
    title('true atlas')
    axis image
    caxis([0 255])
    saveas(777,[outputdirectoryname 'slice30_iter' num2str(i) '.bmp'],'bmp');
end

origatlasname = [parentoutputdirectoryname '/' patientnumber '_affine.img'];

system([candirectoryname 'BIN/IMG_apply_lddmm_tform1 ' origatlasname ' ' dataoutputdirectoryname 'Hmap_composed.vtk ' dataoutputdirectoryname '/' patientnumber '_deformedatlas.img 1']);


system([candirectoryname 'BIN/IMG_apply_lddmm_tform1 ' anoOutImgname '.img ' dataoutputdirectoryname 'Hmap_composed.vtk ' dataoutputdirectoryname '/' patientnumber '_annotation.img 2']);

% generate original target again
%orig_target_STS = transformOriginalTargetImage(patientnumber, transformdirectoryname, nepochs);
orig_target_STS = transformOriginalTargetImage([parentoutputdirectoryname '/' patientnumber '_80_full_firstalign_padded.img'],transformdirectoryname,nepochs);
orig_target_STS.fileprefix = [dataoutputdirectoryname '/' patientnumber '_orig_target_STS'];
avw_img_write(orig_target_STS, orig_target_STS.fileprefix);

commandstring = [candirectoryname 'BIN/VTK_combine_maps_ver5 ' num2str(nepochs)];
for ii = 1:nepochs
    commandstring = [commandstring ' ' dataoutputdirectoryname patientnumber '_lddmm' num2str(ii) '/Kimap000.vtk'];
end
commandstring = [commandstring ' ' dataoutputdirectoryname 'Kimap_composed.vtk'];
system(commandstring)

%% also try mapping from original atlas affine_lhmrem data
%system([candirectoryname '/mm_lddmm2n_ver03.pl 2 ' parentoutputdirectoryname '/' patientnumber '_affine_lhmrem.img ' parentoutputdirectoryname  '/' patientnumber '_targetsmoothedmasked.img 0.4 ' parentoutputdirectoryname '/' patientnumber '_atlasmask.img ' parentoutputdirectoryname '/' patientnumber '_targetmaskinner.img 0.075 ' parentoutputdirectoryname '/' patientnumber '_lddmm 4 0.05 10 0.02 10 0.01 10 0.005 10 1 1 1.0']);

%% do the post processing
%system(['python mouseRegistration_post_maskcost_bnb.py ' patientnumber ' ' parentoutputdirectoryname ' ' atlasdirectoryname ' ' targetdirectoryname  ' ' candirectoryname]);

%% generate second Xform file
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


%% realign the target to horizontal one last time
system(['python alignTargetHorizontal_marmoset.py ' patientnumber ' ' dataoutputdirectoryname '/' patientnumber '_orig_target_STS.img ' dataoutputdirectoryname ' ' patientnumber '_orig_target_STS_rot.img ' transformdirectoryname ' 1']);

%% make QC figures
atlas = avw_img_read([dataoutputdirectoryname '/' patientnumber '_annotation_rot.img']);
orig_target_STS = avw_img_read([dataoutputdirectoryname '/' patientnumber '_orig_target_STS_rot.img']);

f1 = figure;
ax1 = axes('Parent', f1);
ax2 = axes('Parent', f1);
h2 = imagesc(transpose(squeeze(atlas.img(:,:,round(size(orig_target_STS.img,2)/2)))), 'Parent', ax2);
set(h2, 'AlphaData', 0.3)
colormap(ax2, 'jet')
h1 = imagesc(squeeze(orig_target_STS.img(:,round(size(orig_target_STS.img,2)/2),:)), 'Parent', ax1);
colormap(ax1, 'gray')
set(ax1, 'Visible', 'off');
set(ax2, 'Visible', 'off');
set(ax1, 'plotboxaspectratio', [1 1 1]);
set(ax2, 'plotboxaspectratio', [1 1 1]);
saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_sts_step1/' patientnumber '_coronal.png']);

f1 = figure;
ax1 = axes('Parent', f1);
ax2 = axes('Parent', f1);
h2 = imagesc(transpose(squeeze(atlas.img(:,:,80))), 'Parent', ax2);
set(h2, 'AlphaData', 0.3)
colormap(ax2, 'jet')
h1 = imagesc(squeeze(orig_target_STS.img(:,80,:)), 'Parent', ax1);
colormap(ax1, 'gray')
set(ax1, 'Visible', 'off');
set(ax2, 'Visible', 'off');
set(ax1, 'plotboxaspectratio', [1 1 1]);
set(ax2, 'plotboxaspectratio', [1 1 1]);
saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_sts_step1/' patientnumber '_coronal80.png']);

f1 = figure;
ax1 = axes('Parent', f1);
ax2 = axes('Parent', f1);
h2 = imagesc(transpose(squeeze(atlas.img(:,round(size(orig_target_STS.img,2)/2),:))), 'Parent', ax2);
set(h2, 'AlphaData', 0.3)
colormap(ax2, 'jet')
h1 = imagesc(squeeze(orig_target_STS.img(round(size(orig_target_STS.img,2)/2),:,:)), 'Parent', ax1);
colormap(ax1, 'gray')
set(ax1, 'Visible', 'off');
set(ax2, 'Visible', 'off');
set(ax1, 'plotboxaspectratio', [1 1 1]);
set(ax2, 'plotboxaspectratio', [1 1 1]);
saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_sts_step1/' patientnumber '_transverse.png'])

f1 = figure;
ax1 = axes('Parent', f1);
ax2 = axes('Parent', f1);
h2 = imagesc(squeeze(atlas.img(round(size(orig_target_STS.img,2)/2),:,:)), 'Parent', ax2);
set(h2, 'AlphaData', 0.3)
colormap(ax2, 'jet')
h1 = imagesc(squeeze(orig_target_STS.img(:,:,round(size(orig_target_STS.img,2)/2))), 'Parent', ax1);
colormap(ax1, 'gray')
set(ax1, 'Visible', 'off');
set(ax2, 'Visible', 'off');
set(ax1, 'plotboxaspectratio', [1 1 1]);
set(ax2, 'plotboxaspectratio', [1 1 1]);
saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_sts_step1/' patientnumber '_sagittal.png'])

% 
% % qc figures for original
% target = avw_img_read(['/sonas-hs/mitra/hpc/home/blee/data/target_images/' patientnumber '/' patientnumber '_40_full.img']);
% atlas = avw_img_read(['/sonas-hs/mitra/hpc/home/blee/data/registration/' patientnumber '/' patientnumber '_annotation_old.img']);
% 
% f1 = figure;
% ax1 = axes('Parent', f1);
% ax2 = axes('Parent', f1);
% h2 = imagesc(transpose(squeeze(atlas.img(:,:,round(size(target.img,2)/2)))), 'Parent', ax2);
% set(h2, 'AlphaData', 0.3)
% colormap(ax2, 'jet')
% h1 = imagesc(squeeze(target.img(:,round(size(target.img,2)/2),:)), 'Parent', ax1);
% colormap(ax1, 'gray')
% set(ax1, 'Visible', 'off');
% set(ax2, 'Visible', 'off');
% set(ax1, 'plotboxaspectratio', [1 1 1]);
% set(ax2, 'plotboxaspectratio', [1 1 1]);
% saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_step1/' patientnumber '_coronal.png']);
% 
% f1 = figure;
% ax1 = axes('Parent', f1);
% ax2 = axes('Parent', f1);
% h2 = imagesc(transpose(squeeze(atlas.img(:,:,80))), 'Parent', ax2);
% set(h2, 'AlphaData', 0.3)
% colormap(ax2, 'jet')
% h1 = imagesc(squeeze(target.img(:,80,:)), 'Parent', ax1);
% colormap(ax1, 'gray')
% set(ax1, 'Visible', 'off');
% set(ax2, 'Visible', 'off');
% set(ax1, 'plotboxaspectratio', [1 1 1]);
% set(ax2, 'plotboxaspectratio', [1 1 1]);
% saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_step1/' patientnumber '_coronal80.png']);
% 
% f1 = figure;
% ax1 = axes('Parent', f1);
% ax2 = axes('Parent', f1);
% h2 = imagesc(transpose(squeeze(atlas.img(:,round(size(target.img,2)/2),:))), 'Parent', ax2);
% set(h2, 'AlphaData', 0.3)
% colormap(ax2, 'jet')
% h1 = imagesc(squeeze(target.img(round(size(target.img,2)/2),:,:)), 'Parent', ax1);
% colormap(ax1, 'gray')
% set(ax1, 'Visible', 'off');
% set(ax2, 'Visible', 'off');
% set(ax1, 'plotboxaspectratio', [1 1 1]);
% set(ax2, 'plotboxaspectratio', [1 1 1]);
% saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_step1/' patientnumber '_transverse.png'])
% 
% f1 = figure;
% ax1 = axes('Parent', f1);
% ax2 = axes('Parent', f1);
% h2 = imagesc(squeeze(atlas.img(round(size(target.img,2)/2),:,:)), 'Parent', ax2);
% set(h2, 'AlphaData', 0.3)
% colormap(ax2, 'jet')
% h1 = imagesc(squeeze(target.img(:,:,round(size(target.img,2)/2))), 'Parent', ax1);
% colormap(ax1, 'gray')
% set(ax1, 'Visible', 'off');
% set(ax2, 'Visible', 'off');
% set(ax1, 'plotboxaspectratio', [1 1 1]);
% set(ax2, 'plotboxaspectratio', [1 1 1]);
% saveas(f1, ['/sonas-hs/mitra/hpc/home/blee/data/qc_step1/' patientnumber '_sagittal.png'])

%% delete intermediate data
%delete([dataoutputdirectoryname 'wtoutputrem_iter*']);
%delete([dataoutputdirectoryname 'wtoutput_iter*']);
%delete([dataoutputdirectoryname 'wtmask_iter*']);
%delete([dataoutputdirectoryname 'wtlddmmoutputrem_iter*']);
%delete([dataoutputdirectoryname 'wtlddmmoutput_iter*']);
%delete([dataoutputdirectoryname 'wtlddmmmask_iter*']);
%for i = 2:9
%    delete([dataoutputdirectoryname 'anoOutImgRot_iter' num2str(i) '.img']);
%end
%for i = 1:9
%    rmdir([dataoutputdirectoryname patientnumber '_lddmm' num2str(i)],'s');
%end

end
