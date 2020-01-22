% sample syntax:
% flip_mri('819','/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m819/MRI/exvivo/HR_T2/HRT2_CM0819F.nii.gz',...
% '/sonas-hs/mitra/hpc/home/bhuo/scripts/Registration/Marmoset_Pipeline_2019/data/target_images/M819/')
function flip_mri_fun(patientnumber,mrifile,outputdirectoryname)
% addpath nii
% patientnumber = '519';

%if str2num(patientnumber) == 1232
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/HR_T2/HRT2_CM1232M.nii.gz']);
%elseif str2num(patientnumber) == 1145
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/T2/T2_100um_CM1145F.nii.gz']);
%elseif str2num(patientnumber) > 999
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/HR_T2/HR_T2_CM' patientnumber 'F.nii.gz']);
%else
%mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' patientnumber '/MRI/exvivo/HR_T2/HRT2_CM0' patientnumber 'F.nii.gz']);
%end
% if str2num(patientnumber) == 1144 || str2num(patientnumber) == 1146 || str2num(patientnumber) == 1147 || str2num(patientnumber) == 1148 || str2num(patientnumber) == 1231
% mri = load_untouch_nii(['/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/M' patientnumber '_forMRI/invivo/T2_CM' patientnumber 'F_n4.nii.gz']);
% elseif str2num(patientnumber) == 1145 ||  str2num(patientnumber) == 1232
% mri = load_untouch_nii(['/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/M' patientnumber '_forMRI/invivo/T2_CM' patientnumber 'M_n4.nii.gz']);
% elseif str2num(patientnumber) == 826
% mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk123/main/marmosetTEMP/MRI/exvivo/CM0826F/HR_T2/T2_100um_CM0826F.nii']);
% elseif str2num(patientnumber) == 876
% mri = load_untouch_nii('/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m876/MRI/exvivo/T2/T2_100um_CM0876M.nii');
% elseif str2num(patientnumber) == 1559
% mri = load_untouch_nii('/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m1559/MRI/exvivo/T2/T2_100um_CM1559F.nii');
% elseif str2num(patientnumber) == 6328
% mri = load_untouch_nii('/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m6328/MRI/exvivo/HR_T2/HR_T2_I6328F.nii');
% elseif str2num(patientnumber) == 519
% mri = load_untouch_nii('/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m519/MRI/exvivo/reM519_HRT2m.nii');
% else
% %mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' num2str(patientnumber) '/MRI/exvivo/HR_T2/T2_100um_CM' num2str(patientnumber) 'F.nii.gz']);
% mri = load_untouch_nii(['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' num2str(patientnumber) '/MRI/exvivo/HR_T2/HR_T2_CM' num2str(patientnumber) 'F.nii.gz']);
% %mri = load_untouch_nii(['/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/M' patientnumber '_forMRI/invivo/T2_CM0' patientnumber 'F_n4.nii.gz']);
% end
%outputdirectoryname = ['/cis/home/leebc/Projects/Mouse_Histology/data/registration/BNBoutput3/M' patientnumber '_forMRI/invivo/'];
% outputdirectoryname = ['/sonas-hs/mitra/hpc/home/kram/Marmoset_Pipeline_2019/data/target_images/M' patientnumber '/'];
mkdir(outputdirectoryname);
mri = load_untouch_nii(mrifile);
mrivol = mri.img;
mrivol_rot = zeros([size(mri.img,3), size(mri.img,2), size(mri.img,1)]);
for i = 1:size(mrivol,2)
    mrivol_rot(:,size(mrivol,2)-i+1,:) = rot90(rot90(rot90(squeeze(mrivol(:,i,:)))));
%     mrivol_rot(:,size(mrivol,2)-i+1,:) = rot90(squeeze(mrivol(:,i,:)));
    %mrivol_rot(:,size(mrivol,2)-i+1,:) = rot90(rot90(rot90(squeeze(mrivol(:,i,:)))));
end
% scale to 255
mrivol_rot = mrivol_rot./max(max(max(mrivol_rot))).*255;

mriout = make_blank_img();
mriout.hdr.dime.dim(2:4) = size(mrivol_rot);
mriout.hdr.dime.pixdim(2:4) = mri.hdr.dime.pixdim([4 3 2]);
mriout.hdr.dime.glmax = 255;
mriout.fileprefix = [outputdirectoryname 'M' patientnumber '_mri_full'];
mriout.img = mrivol_rot;
mriout.hdr.dime.bitpix = 16;
mriout.hdr.dime.datatype = 16;
mriout.img = mrivol_rot;
avw_img_write(mriout,mriout.fileprefix);
