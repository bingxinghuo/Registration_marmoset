function [outImg] = transformOriginalTargetImage(inputfilename, transformdirectoryname, frontpad, backpad)
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

%[a,b,theta] = composeSectionTransforms(transformdirectory, niter);
a = readSectionTransform([transformdirectoryname '/final_a.txt']);
b = readSectionTransform([transformdirectoryname '/final_b.txt']);
theta = readSectionTransform([transformdirectoryname '/final_theta.txt']);


outImg = applySectionTransformsCoronal(inImg,a,b,theta,'linear');

outvol = zeros(size(outImg.img,1), size(outImg.img,2)+frontpad+backpad, size(outImg.img,3));
outvol(:,frontpad+1:end-backpad,:) = outImg.img;
outImg.img = outvol;
outImg.hdr.dime.dim(2:4) = size(outvol);

end
