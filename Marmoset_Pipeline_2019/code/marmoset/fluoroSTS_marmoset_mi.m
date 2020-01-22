function fluoroSTS_marmoset(nisslfilename, fluorofilename, outputdirectoryname, patientnumber, nissldirectoryname)

%nissl = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/PMD2643_orig_target_STS_rot.img',0);
%nisslmask = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/wtmask_iter9.img',0);
%fluoro = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/PMD2643_40_AAV_full.img',0);

% maybe mask nissl

nissl = avw_img_read([nissldirectoryname '/' patientnumber '_orig_target_STS.img'],0);

%nissl = avw_img_read(nisslfilename,0);
fluoro = avw_img_read(fluorofilename,0);

mkdir(outputdirectoryname);
transformdirectoryname = [outputdirectoryname '/fluoro_transforms/'];
mkdir([outputdirectoryname '/fluoro_transforms']);

nissl.img(:,[1:40, end-14:end],:) = [];
nissl.hdr.dime.dim(2:4) = size(nissl.img);
orig_nissl_size = size(nissl.img);
nissl.fileprefix = [outputdirectoryname '/' patientnumber '_orig_target_STS_masked_cropped.img']

% pad the nissl image so it is the same size
padsize = [max(size(fluoro.img,1),size(nissl.img,1)) max(size(fluoro.img,2),size(nissl.img,2)) max(size(fluoro.img,3),size(nissl.img,3))];

nisslvol = zeros(padsize);
nisslvol(1:size(nissl.img,1), 1:size(nissl.img,2), 1:size(nissl.img,3)) = nissl.img;
nissl.img = nisslvol;
nissl.hdr.dime.dim(2:4) = size(nissl.img);

fluorovol = zeros(padsize);
fluorovol(1:size(fluoro.img,1), 1:size(fluoro.img,2), 1:size(fluoro.img,3)) = fluoro.img;
fluoro.img = fluorovol;
fluoro.hdr.dime.dim(2:4) = size(fluoro.img);

% scale to 255
fluoro.img = fluoro.img./max(max(max(fluoro.img))).*255.0;

% hist match the fluoro image?
% nissl.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/PMD2643_orig_target_STS_rot_crop';
% avw_img_write(nissl,nissl.fileprefix);


a_old = zeros(1,size(nissl.img,2));
b_old = zeros(1,size(nissl.img,2));
theta_old = zeros(1,size(nissl.img,2));
coronalflip = 1;
interpmode = 'linear';
cost='MI';
niter = 1000;
[output,a,b,theta,best_E] = slice_alignment_walk_withatlas_mi(fluoro, nissl.img, cost,niter, a_old, b_old, theta_old, interpmode, coronalflip);
a_old = a_old + a;
b_old = b_old + b;
theta_old = theta_old + theta;

%outputvol = zeros(orig_nissl_size);

output.fileprefix = [outputdirectoryname '/' patientnumber '_fluoro_STS'];
avw_img_write(output, output.fileprefix);

saveSectionTransforms(a_old,b_old,theta_old,transformdirectoryname, 'final');

%% generate CSHL Xform file
missingsliceind = [];
for i = 1:size(output.img,2)
    if size(unique(output.img(:,i,:)),1) < 3
        missingsliceind = [missingsliceind i];
    end
end
fid = fopen([transformdirectoryname patientnumber '_fluoro_XForm.txt'],'w');
fid2 = fopen([transformdirectoryname patientnumber '_fluoro_XForm_matrix.txt'],'w');
a_old(missingsliceind) = [];
b_old(missingsliceind) = [];
theta_old(missingsliceind) = [];
for i = 1:length(a_old)
    R = [cos(theta_old(i)) -sin(theta_old(i)) a_old(i);sin(theta_old(i)) cos(theta_old(i)) b_old(i); 0 0 1];
    fprintf(fid, '%f,%f,1,1,%d,%d,%f,%f,%f,%f,%f,%d,%d,%d\n',0,0,output.hdr.dime.dim(4),output.hdr.dime.dim(2),theta_old(i),double(output.hdr.dime.dim(4))/2,double(output.hdr.dime.dim(2))/2,b_old(i),a_old(i), 0,0,0);
    fprintf(fid2,'%f,%f,%f,%f,%f,%f,%f,%f,\n', R(1,1), R(1,2), R(2,1), R(2,2), R(1,3), R(2,3), double(output.hdr.dime.dim(4))/2*double(output.hdr.dime.pixdim(4)),double(output.hdr.dime.dim(2))/2*double(output.hdr.dime.pixdim(2)));
end
fclose(fid);
fclose(fid2);


outputvol = output;
%outputvol.img = outputvol.img(1:orig_nissl_size(1),1:orig_nissl_size(2),1:orig_nissl_size(3));
outputvol.img = zeros([orig_nissl_size(1), orig_nissl_size(2) + 55, orig_nissl_size(3)]);
outputvol.img(:,41:end-15,:) = output.img(1:orig_nissl_size(1),:,1:orig_nissl_size(3));
outputvol.hdr.dime.dim(2:4) = size(outputvol.img);
outputvol.fileprefix = [outputdirectoryname '/' patientnumber '_fluoro_STS_padded'];
avw_img_write(outputvol,outputvol.fileprefix);

outImg = transformOriginalTargetImage_padded(fluorofilename, transformdirectoryname, 40, 15);
outImg.fileprefix =  [outputdirectoryname '/' patientnumber '_fluoro_orig_STS_padded'];
avw_img_write(outImg, outImg.fileprefix);

end
