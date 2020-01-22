addpath nii
patientnumber = '1231';

%if str2num(patientnumber) == 1232
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/HR_T2/HRT2_CM1232M.nii.gz']);
%elseif str2num(patientnumber) == 1145
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/T2/T2_100um_CM1145F.nii.gz']);
%elseif str2num(patientnumber) > 999
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/HR_T2/HR_T2_CM' patientnumber 'F.nii.gz']);
%else
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/HR_T2/HRT2_CM0' patientnumber 'F.nii.gz']);
%end
if strcmp(patientnumber,'821') || strcmp(patientnumber,'852') || strcmp(patientnumber,'823') || strcmp(patientnumber,'851')
mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/invivo/T2_200um/T2_200um_CM0' patientnumber 'F_n4.nii.gz']);
elseif strcmp(patientnumber,'1231')
mri = load_untouch_nii('/sonas-hs/mitra/hpc/home/blee/data/target_images/M1231/T1WI_CM1231.nii')
else
mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/invivo/T2/T2_CM0' patientnumber 'F_n4.nii.gz']);
end
%mri = load_untouch_nii(['/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/M' patientnumber '_forMRI/invivo/T2_CM0' patientnumber 'F_n4.nii.gz']);
%outputdirectoryname = ['/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/M' patientnumber '_forMRI/invivo/'];
outputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/target_images/M' patientnumber '/'];
mkdir(outputdirectoryname);
mrivol = mri.img;
mrivol_rot = zeros([size(mri.img,3), size(mri.img,2), size(mri.img,1)]);
for i = 1:size(mrivol,2)
    %mrivol_rot(:,size(mrivol,2)-i+1,:) = rot90(rot90(rot90(squeeze(mrivol(:,i,:)))));
    mrivol_rot(:,size(mrivol,2)-i+1,:) = rot90(squeeze(mrivol(:,i,:)));
end
% scale to 255
mrivol_rot = mrivol_rot./max(max(max(mrivol_rot))).*255;

mriout = make_blank_img();
mriout.hdr.dime.dim(2:4) = size(mrivol_rot);
mriout.hdr.dime.pixdim(2:4) = mri.hdr.dime.pixdim([4 3 2]);
mriout.hdr.dime.glmax = 255;
mriout.fileprefix = [outputdirectoryname 'M' patientnumber '_invivo_mri_full'];
mriout.img = mrivol_rot;
mriout.hdr.dime.bitpix = 16;
mriout.hdr.dime.datatype = 16;
mriout.img = mrivol_rot;
avw_img_write(mriout,mriout.fileprefix);
