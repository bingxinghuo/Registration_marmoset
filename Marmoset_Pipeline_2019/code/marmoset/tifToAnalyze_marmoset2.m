addpath /cis/home/fuyan/matlab

modalities = ['N','F','M','C'];
for ii = 1:length(modalities)

    directoryname = ['/cis/home/fuyan/Downloads/M920/photos/M920' modalities(ii) '-RTIF/'];
    directory = dir(directoryname);
    slicenumbers = [];
    tempadr = {};
    for i = 1:size(directory,1)
        if ~isempty(regexp(directory(i).name,'.tif'))
            tempadr{length(tempadr)+1} = directory(i).name;
        end
    end
    %adr = natsortfiles({directory(4:end).name});
    adr = natsortfiles(tempadr);
    uind1 = regexp(adr{1},modalities(ii));
    uind2 = regexp(adr{1},'--');
    slidenum = str2num(adr{1}(uind1(end)+1:uind2-1));
    slidepos = str2num(adr{1}(uind2+3));

    firstslicenumber = (slidenum-1)*2+slidepos;
    for i = 1:size(adr,2)
        uind1 = regexp(adr{i},modalities(ii));
        uind2 = regexp(adr{i},'--');
        slidenum = str2num(adr{i}(uind1(end)+1:uind2(end)-1));
        % for m820 only
        %slidepos = str2num(directory(i).name(uind2+3))-1;
        slidepos = str2num(adr{i}(uind2(end)+3));
        if i == 1
            lastslidenum = slidenum;
            lastslidepos = slidepos;
            slicenumbers = [slicenumbers firstslicenumber];
            continue
        end
        if lastslidenum == slidenum
            slicenumbers = [slicenumbers, slicenumbers(end) + 1];
        else
            % m983
            %if slidenum < 149 || slidenum > 225
            % m919new
            %if slidenum < 77 || slidenum > 120
            % m820new
            %if slidenum < 51 || slidenum > 200
            % m920
            if slidenum < 73 || slidenum > 218
                slicenumbers = [slicenumbers, slicenumbers(end) + (slidenum - lastslidenum-1)*2 + (slidepos-lastslidepos+2)];
            else
                slicenumbers = [slicenumbers, slicenumbers(end) + (slidenum - lastslidenum-1)*1 + 1];
            end
        end
        lastslidenum = slidenum;
        lastslidepos = slidepos;
    end
    if strcmp(modalities(ii),'N')
        nslicenumbers = slicenumbers;
    elseif strcmp(modalities(ii),'F')
        fslicenumbers = slicenumbers;
    elseif strcmp(modalities(ii),'M')
        mslicenumbers = slicenumbers;
    elseif strcmp(modalities(ii),'C')
        cslicenumbers = slicenumbers;
    end
end

minslicenumber = min([nslicenumbers(1),fslicenumbers(1),mslicenumbers(1),cslicenumbers(1)]);
maxslicenumber = max([nslicenumbers(end),fslicenumbers(end),mslicenumbers(end),cslicenumbers(end)]);
nslices = maxslicenumber - minslicenumber + 1;

originalpixelsize = [0.46*128/1000 0.08 0.46*128/1000];
newpixelsize = [0.08 0.08 0.08];

factor = 4; % pick a factor of the pixel ratio for your kernel width/height
kernelsize_x = round(newpixelsize(1)/originalpixelsize(1)*factor); %select the kernel width/height (not the gaussian radius), I usually make it a few times bigger than the pixel ratio
kernelsize_y = round(newpixelsize(3)/originalpixelsize(3)*factor);
if ~mod(kernelsize_x,2)
    kernelsize_x = kernelsize_x+1;
end
if ~mod(kernelsize_y,2)
    kernelsize_y = kernelsize_y+1;
end
kernel = zeros(kernelsize_x,kernelsize_y);
kernelcenter_x = ceil(kernelsize_x/2);
kernelcenter_y = ceil(kernelsize_y/2);

sigma_x = newpixelsize(1)/originalpixelsize(1)/4;
sigma_y = newpixelsize(3)/originalpixelsize(3)/4;

% populate kernel with 2d gaussian
for i = 1:kernelsize_x
    for ii = 1:kernelsize_y
        kernel(i,ii) = exp(-1*((i-kernelcenter_x)^2/(2*sigma_x^2) + (ii-kernelcenter_y)^2/(2*sigma_y^2)));
    end
end

% normalize the kernel
kernel = kernel./(sum(sum(kernel)));

for ii = 1:length(modalities)
    % load the first nissl image
    directoryname = ['/cis/home/fuyan/Downloads/M920/photos/M920' modalities(ii) '-RTIF/'];
    directory = dir(directoryname);
    tempadr = {};
    for i = 1:size(directory,1)
        if ~isempty(regexp(directory(i).name,'.tif'))
            tempadr{length(tempadr)+1} = directory(i).name;
        end
    end
    %adr = natsortfiles({directory(4:end).name});
    adr = natsortfiles(tempadr);

    img = rgb2gray(imread([directoryname adr{1}]));
    
    if strcmp(modalities(ii),'N') || strcmp(modalities(ii),'C') || strcmp(modalities(ii),'M')
        originalpixelsize = [0.46*128/1000 0.08 0.46*128/1000];
    else
        originalpixelsize = [0.46*128*1.5/1000 0.08 0.46*128*1.5/1000];
    end

    [meshx,meshy] = meshgrid(1:newpixelsize(3)/originalpixelsize(3):size(img,2),1:newpixelsize(1)/originalpixelsize(1):size(img,1));
    
    if strcmp(modalities(ii),'F')
        newimg = ones(size(meshx,1), nslices , size(meshx,2))*0;
    else
        newimg = ones(size(meshx,1), nslices , size(meshx,2))*255;
    end
    for i = 1:length(nslicenumbers)
        img = rgb2gray(imread([directoryname adr{i}]));
        bgval = img(1,1);
        newslice = conv2(double(img), double(kernel), 'same');
        newslice_interp = interp2(newslice, meshx, meshy);
        newimg(:,nslicenumbers(i)-minslicenumber+1,:) = newslice_interp;    
        newimg(1,nslicenumbers(i)-minslicenumber+1,:) = bgval;
        newimg(end,nslicenumbers(i)-minslicenumber+1,:) = bgval;
        newimg(:,nslicenumbers(i)-minslicenumber+1,1) = bgval;
        newimg(:,nslicenumbers(i)-minslicenumber+1,end) = bgval;
    end

    % analyze format
    outimg = make_blank_img();
    outimg.img = newimg;
    outimg.hdr.dime.dim(2:4) = size(newimg);
    outimg.hdr.dime.pixdim(2:4) = newpixelsize;
    outimg.hdr.dime.datatype = 16;
    outimg.hdr.dime.bitpix = 16;
    outimg.fileprefix = ['/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_' modalities(ii)];
    avw_img_write(outimg,outimg.fileprefix)

    % crop the image because it's way too big
    if strcmp(modalities(ii),'N')
        newimg([1:100, 383:end],:,:) = [];
        newimg(:,:,[1:137, 416:end]) = [];
    elseif strcmp(modalities(ii),'F')
        newimg([1:210,489:end],:,:) = [];
        newimg(:,:,[1:265,548:end]) = [];
    end
    if strcmp(modalities(ii),'N') || strcmp(modalities(ii),'C') || strcmp(modalities(ii),'M')
        newimg = -1*newimg + 255;
    end
    outimg = make_blank_img();
    outimg.img = newimg;
    outimg.hdr.dime.dim(2:4) = size(newimg);
    outimg.hdr.dime.pixdim(2:4) = newpixelsize;
    outimg.hdr.dime.datatype = 16;
    outimg.hdr.dime.bitpix = 16;
    outimg.fileprefix = ['/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_' modalities(ii) '_cropped'];
    avw_img_write(outimg,outimg.fileprefix)
end

%%
% downsample the atlas
atlas = load_nii('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/Nissl.nii');
originalatlasvoxelsize = [atlas.hdr.dime.pixdim(2:4)];
%newatlasvoxelsize = [0.115 0.115 0.115];
%newatlasvoxelsize = [0.3 0.3 0.3];
%newatlasvoxelsize = [0.23 0.23 0.23];
newatlasvoxelsize = [0.08 0.08 0.08];

kernel = ones(ceil(newatlasvoxelsize(1)/originalatlasvoxelsize(1)),ceil(newatlasvoxelsize(2)/originalatlasvoxelsize(2)),ceil(newatlasvoxelsize(3)/originalatlasvoxelsize(3)));
xscaled = convn(atlas.img, kernel, 'same')./numel(kernel);

[xm,ym,zm] = meshgrid(1:newatlasvoxelsize(2)/originalatlasvoxelsize(2):size(xscaled,2), 1:newatlasvoxelsize(1)/originalatlasvoxelsize(1):size(xscaled,1), 1:newatlasvoxelsize(3)/originalatlasvoxelsize(3):size(xscaled,3));
xscaled_int = interp3(xscaled,xm,ym,zm, 'linear');

avw = make_blank_img();
avw.fileprefix = ['/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/atlas_80'];
avw.hdr.dime.dim(2:4) = size(xscaled_int);
avw.hdr.dime.pixdim(2:4) = newatlasvoxelsize;
avw.hdr.dime.bitpix = atlas.hdr.dime.bitpix;
avw.hdr.dime.datatype = atlas.hdr.dime.datatype;
avw.img = xscaled_int;
avw_img_write(avw, avw.fileprefix); 

atlas = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/atlas_80');
newatlas = zeros(size(atlas.img,3),size(atlas.img,2),size(atlas.img,1));
for i = 1:size(atlas.img,2)
    newatlas(:,i,:) = rot90(squeeze(atlas.img(:,size(atlas.img,2)-i+1,:)));
end

avw = make_blank_img();
avw.fileprefix = ['/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/atlas_80_flip'];
avw.hdr.dime.dim(2:4) = size(newatlas);
avw.hdr.dime.pixdim(2:4) = newatlasvoxelsize;
avw.hdr.dime.bitpix = atlas.hdr.dime.bitpix;
avw.hdr.dime.datatype = atlas.hdr.dime.datatype;
avw.img = newatlas;
avw_img_write(avw, avw.fileprefix); 

seg = load_nii('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/LabelMap.nii');
originalatlasvoxelsize = [seg.hdr.dime.pixdim(2:4)];
%newatlasvoxelsize = [0.115 0.115 0.115];
%newatlasvoxelsize = [0.3 0.3 0.3];
%newatlasvoxelsize = [0.23 0.23 0.23];
newatlasvoxelsize = [0.08 0.08 0.08];

% kernel = ones(ceil(newatlasvoxelsize(1)/originalatlasvoxelsize(1)),ceil(newatlasvoxelsize(2)/originalatlasvoxelsize(2)),ceil(newatlasvoxelsize(3)/originalatlasvoxelsize(3)));
% xscaled = convn(atlas.img, kernel, 'same')./numel(kernel);

[xm,ym,zm] = meshgrid(1:newatlasvoxelsize(2)/originalatlasvoxelsize(2):size(xscaled,2), 1:newatlasvoxelsize(1)/originalatlasvoxelsize(1):size(xscaled,1), 1:newatlasvoxelsize(3)/originalatlasvoxelsize(3):size(xscaled,3));
xscaled_int = interp3(seg.img,xm,ym,zm, 'nearest');

avw = make_blank_img();
avw.fileprefix = ['/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/annotation_80'];
avw.hdr.dime.dim(2:4) = size(xscaled_int);
avw.hdr.dime.pixdim(2:4) = newatlasvoxelsize;
avw.hdr.dime.bitpix = seg.hdr.dime.bitpix;
avw.hdr.dime.datatype = seg.hdr.dime.datatype;
avw.img = xscaled_int;
avw_img_write(avw, avw.fileprefix); 

seg = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/annotation_80');
newatlas = zeros(size(seg.img,3),size(seg.img,2),size(seg.img,1));
for i = 1:size(seg.img,2)
    newatlas(:,i,:) = rot90(squeeze(seg.img(:,size(seg.img,2)-i+1,:)));
end

avw = make_blank_img();
avw.fileprefix = ['/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/annotation_80_flip'];
avw.hdr.dime.dim(2:4) = size(newatlas);
avw.hdr.dime.pixdim(2:4) = newatlasvoxelsize;
avw.hdr.dime.bitpix = seg.hdr.dime.bitpix;
avw.hdr.dime.datatype = seg.hdr.dime.datatype;
avw.img = newatlas;
avw_img_write(avw, avw.fileprefix); 


% mask the atlas because the colors are messed up and adam can't find the
% right atlas
atlas = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/atlas_80_flip');
img = atlas.img;

ind = img>20;
img(ind) = 255 - img(ind);

se = strel('sphere',1); % needs matlab 2017
ind_erode = imerode(ind,se);
%ind_erode = imerode(ind_erode,se);
% save the mask
newimg = make_blank_img();
newimg.img = ind_erode;
newimg.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/mask_80_flip';
newimg.hdr.dime.dim(2:4) = size(newimg.img);
newimg.hdr.dime.pixdim(2:4) = [0.08 0.08 0.08];
avw_img_write(newimg,newimg.fileprefix);

ind_diff = ind;
ind_diff(ind_erode==1)=0;
img(ind_diff==1) = 255-img(ind_diff==1);
%img(ind_diff==1) = 0;
%img(ind_erode==0) = 0;

% save the new image
newimg = make_blank_img();
newimg.img = img;
newimg.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/atlas_80_flip_masked_eroded';
newimg.hdr.dime.dim(2:4) = size(newimg.img);
newimg.hdr.dime.pixdim(2:4) = [0.08 0.08 0.08];
avw_img_write(newimg,newimg.fileprefix);

% mask = zeros(size(img));
% mask(ind) = 1;
% % try to remove the edges of the inverted atlas
% erod = zeros(size(img));
% sel1 = strel('disk',1);
% B = [0 1 0; 1 1 1; 0 1 0];
% %sel1 = [1 1 1;1 1 1];
% for n = 1:size(mask,1)
%     im = squeeze(mask(n,:,:));
%     im1 = imerode(im,sel1);
%     
%     cc = bwconncomp(im1,4);
%     numPixels = cellfun(@numel,cc.PixelIdxList);
%     A = find(numPixels<100);
%     for i = 1:length(A)
%         im1(cc.PixelIdxList{A(i)}) = 0;
%     end
%     im3 = imdilate(im1,B);
%     erod(n,:,:) = im3; 
% end
% 
% im2 = img;
% im2(erod==0) = 0;
% 
% % save the mask
% newimg = make_blank_img();
% newimg.img = erod;
% newimg.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/mask_80_flip';
% newimg.hdr.dime.dim(2:4) = size(newimg.img);
% newimg.hdr.dime.pixdim(2:4) = [0.08 0.08 0.08];
% avw_img_write(newimg,newimg.fileprefix);
% 
% % save the new image
% newimg = make_blank_img();
% newimg.img = im2;
% newimg.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/hashikawa/atlas_80_flip_masked';
% newimg.hdr.dime.dim(2:4) = size(newimg.img);
% newimg.hdr.dime.pixdim(2:4) = [0.08 0.08 0.08];
% avw_img_write(newimg,newimg.fileprefix);

% resample the atlas to 100um
%atlas = avw_img_read('


% now do the mri
mri = load_untouch_nii('/cis/home/fuyan/Downloads/M920/20160528_21095708DTI128axb1000news180001a001.nii');
mrivol = mri.img(:,:,:,1);
mrivol_rot = zeros(105,190,190);
for i = 1:size(mrivol,2)
    mrivol_rot(:,i,:) = rot90(squeeze(mrivol(:,i,:)));
end
% scale to 255
mrivol_rot = mrivol_rot./max(max(max(mrivol_rot))).*255;

mriout = make_blank_img();
mriout.hdr.dime.dim(2:4) = size(mrivol_rot);
mriout.hdr.dime.pixdim(2:4) = mri.hdr.dime.pixdim(2:4); % shouldn't this be flipped?
mriout.hdr.dime.glmax = 255;
mriout.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/m920/mri_200'
mriout.img = mrivol_rot;
mriout.hdr.dime.bitpix = 16;
mriout.hdr.dime.datatype = 16;
avw_img_write(mriout,mriout.fileprefix);

% register the mri to the nissl volume


%% now do the t2 mri instead of dwi
%mri = load_untouch_nii('/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/m920/MRI/HRT2_CM0920F.nii.gz');
patientnumber = '819';
mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/HR_T2/HRT2_CM0' patientnumber 'F.nii.gz']);
outputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/target_images/M' patientnumber '/'];
mkdir(outputdirectoryname);
mrivol = mri.img;
mrivol_rot = zeros([size(mri.img,3), size(mri.img,2), size(mri.img,1)]);
for i = 1:size(mrivol,2)
    mrivol_rot(:,size(mrivol,2)-i+1,:) = rot90(rot90(rot90(squeeze(mrivol(:,i,:)))));
end
% scale to 255
mrivol_rot = mrivol_rot./max(max(max(mrivol_rot))).*255;

mriout = make_blank_img();
mriout.hdr.dime.dim(2:4) = size(mrivol_rot);
mriout.hdr.dime.pixdim(2:4) = mri.hdr.dime.pixdim([4 3 2]);
mriout.hdr.dime.glmax = 255;
mri.fileprefix = [outputdirectoryname 'M' patientnumber '_mri_full'];
mriout.img = mrivol_rot;
mriout.hdr.dime.bitpix = 16;
mriout.hdr.dime.datatype = 16;
mriout.img = mrivol_rot;
avw_img_write(mriout,mriout.fileprefix);
