function [outImg] = transformOriginalTargetImage(inputfilename, transformdirectory, niter)
%inImg = avw_img_read(['/sonas-hs/mitra/hpc/home/blee/data/target_images/' patientnumber '/' patientnumber '_40_full.img'],0);

inImg = avw_img_read(inputfilename,0);

%imrot = zeros([size(inImg.img,1), size(inImg.img,3), size(inImg.img,2)]);
%for i = 1:size(inImg.img,3)
%    imrot(:,i,:) = squeeze(inImg.img(:,:,i));
%end

%outImg = inImg;
%outImg.img = imrot;
%outImg.hdr.dime.dim(2:4) = size(imrot);

%outImg.fileprefix = ' ';

[a,b,theta] = composeSectionTransforms_range(transformdirectory, niter);

outImg = applySectionTransformsCoronal(inImg,a,b,theta,'linear');

end
