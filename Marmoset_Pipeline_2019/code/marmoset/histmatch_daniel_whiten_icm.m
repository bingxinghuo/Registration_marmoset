function histmatch_daniel_whiten_icm(patientnumber, actualpatientnumber, reorient, output)
%patientnumber = 'PMD2044';

%targetimg = avw_img_read(['/cis/home/leebc/Projects/Mouse_Histology/data/target_images/interpolated/' patientnumber '_40_full.img']);
targetimg = avw_img_read([patientnumber]);

addpath /sonas-hs/mitra/hpc/home/blee/code/localHistogramMatching/
% histmatch
OPTH = struct;
OPTH.dx = targetimg.hdr.dime.pixdim(2);
OPTH.dy = targetimg.hdr.dime.pixdim(3);
OPTH.dz = targetimg.hdr.dime.pixdim(4);
OPTH.n = 13;
OPTH.epsilon = 0.05;
OPTH.sigma = 0.7;
OPTH.whitenOnly = 1;
%IToStay = targetimg.img;
%IToChange = templatereorient;
[J, I1h] = localHistMatch_oneShot_v14(targetimg.img,targetimg.img,OPTH); 

outimg = targetimg;
outimg.img = I1h.*255;
%outimg.fileprefix = ['/cis/home/leebc/Projects/Mouse_Histology/data/registration/' actualpatientnumber '_targetwhitened'];
outimg.fileprefix = output;
if reorient == true
outimg.hdr.hist.orient = 0;
else
outimg.hdr.hist.orient = 2;
end

outimg.hdr.dime.dim(2:4) = size(outimg.img);
avw_img_write(outimg, outimg.fileprefix);


end
