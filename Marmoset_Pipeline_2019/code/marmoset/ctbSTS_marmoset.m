function fluoroSTS_marmoset(nisslfilename, fluorofilename, outputdirectoryname, patientnumber)

%nissl = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/PMD2643_orig_target_STS_rot.img',0);
%nisslmask = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/wtmask_iter9.img',0);
%fluoro = avw_img_read('/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/PMD2643_40_AAV_full.img',0);

% maybe mask nissl
system(['python /sonas-hs/mitra/hpc/home/blee/code/maskBySlice.py ' nisslfilename ' ' outputdirectoryname '/' patientnumber '_orig_target_STS_mask.img ' outputdirectoryname '/' patientnumber '_orig_target_STS_masked.img']);

nissl = avw_img_read([outputdirectoryname '/' patientnumber '_orig_target_STS_masked.img'],0);

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

% hist match the fluoro image?
% nissl.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/PMD2643_orig_target_STS_rot_crop';
% avw_img_write(nissl,nissl.fileprefix);

%fluoro.img(find(fluoro.img>22)) = 22;
%fluoro.img = double(fluoro.img)./max(max(max(fluoro.img))) .* 100;
% fluoro.fileprefix = '/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/PMD2643_fluoro_thresh';
% avw_img_write(fluoro,fluoro.fileprefix);
fluoro.fileprefix = [outputdirectoryname '/' patientnumber '_fluoro_pre'];
avw_img_write(fluoro,fluoro.fileprefix);

% maybe mask
system(['python /sonas-hs/mitra/hpc/home/blee/code/maskBySlice.py ' fluoro.fileprefix '.img ' outputdirectoryname '/' patientnumber '_fluoro_mask.img ' outputdirectoryname '/' patientnumber '_fluoro_masked.img']);

fluoro = avw_img_read([outputdirectoryname '/' patientnumber '_fluoro_masked.img'],0);

a_old = zeros(1,size(nissl.img,2));
b_old = ones(1,size(nissl.img,2)) .* 7.0;
theta_old = zeros(1,size(nissl.img,2));
% maybe try centering every image on its center of mass
for i = 1:size(nissl.img,2)
    [nisslyind,nisslxind] = find(squeeze(nissl.img(:,i,:)) > 0);
    [fluoroyind,fluoroxind] = find(squeeze(fluoro.img(:,i,:)) > 0);
    if isempty(fluoroxind) || isempty(nisslxind)
        if i == 1
            a_old(i) = 0;
        else
            a_old(i) = a_old(i-1);
        end
    else
        a_old(i) = 1*(mean(fluoroxind)-mean(nisslxind))*0.08;
    end
    if isempty(fluoroyind) || isempty(nisslyind)
        if i == 1
            b_old(i) = 0;
        else
            b_old(i) = b_old(i-1);
        end
    else
        b_old(i) = 1*(mean(fluoroyind)-mean(nisslyind))*0.08;
    end
end

interpmode = 'linear';
cost=  'MSE';
niter = 1000;
coronalflip = 1;

dx = [0.08,0.08,0.08];
x = (0:size(fluoro.img,1)-1)*dx(1);
y = (0:size(fluoro.img,2)-1)*dx(2);
z = (0:size(fluoro.img,3)-1)*dx(3);
x = x - mean(x);
y = y - mean(y);
z = z - mean(z);

[XX,YY] = meshgrid(z,x); % often we do not use z

TI = zeros(size(fluoro.img));
for i = 1:size(nissl.img,2)
    temptheta = theta_old;
    tempa = a_old;
    tempb = b_old;
    A = [cos(temptheta(i)), -sin(temptheta(i)), 0, tempa(i);
        sin(temptheta(i)), cos(temptheta(i)), 0,  tempb(i);
        0 0 1 0;
        0 0 0 1];
    TX = A(1,1)*XX + A(1,2)*YY + A(1,4);
    TY = A(2,1)*XX + A(2,2)*YY + A(2,4);
    TI(:,i,:) =  linearInterpolate2D(XX,YY,squeeze(fluoro.img(:,i,:)),TX,TY,interpmode,'edge');
end
TIout = fluoro;
TIout.img = TI;
TIout.fileprefix = [outputdirectoryname '/' patientnumber '_fluoro_pre_padded_centered.img'];
avw_img_write(TIout,TIout.fileprefix);
nissl.fileprefix = [outputdirectoryname '/' patientnumber '_nissl_masked_padded.img'];
avw_img_write(nissl,nissl.fileprefix);

[output,a,b,theta,best_E] = slice_alignment_walk_withatlas_fluoro(fluoro, nissl.img, cost,niter, a_old, b_old, theta_old, interpmode, coronalflip);
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

end
