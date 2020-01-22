% sample syntax: generateListsFileBNB('819','N','/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/','~/scripts/Registration/Marmoset_Pipeline_2019/data/stackalign/BNBLists/')
function generateListsFileBNBfun(id,modality,inputdir,outputdir)
% id = 519;
% modality = 'N'
suffix = '.tif';
foldername = ['M' num2str(id) num2str(modality) '-STIF/'];
%foldername = 'JP2/';
%foldername = [''];

% f = fopen(['/sonas-hs/mitra/hpc/home/kram/Marmoset_Pipeline_2019/data/stackalign/BNBLists/M' num2str(id) '_' num2str(modality) '_List.txt'],'w');
f = fopen([outputdir,'/M' num2str(id) '_' num2str(modality) '_List.txt'],'w');
% directoryname = ['/nfs/mitraweb2/mnt/disk125/main/marmosetRIKEN/NZ/m' num2str(id) '/m' num2str(id) num2str(modality) '/' foldername];
directoryname = [inputdir,'/m' num2str(id) '/m' num2str(id) num2str(modality) '/' foldername];
%directoryname = ['/nfs/mitraweb2/mnt/disk123/main/TempForTrasfer/' foldername];
%directoryname = ['/nfs/mitraweb2/mnt/disk125/main/mba_converted_imaging_data/MD693/MD693/' foldername];
%directoryname = ['/nfs/mitraweb2/mnt/disk123/main/mba_converted_imaging_data/PMD2308&2307/PMD2307/' foldername];
directory = dir(directoryname);
filenames = {};
for i = 1:size(directory,1)
    if isempty(regexp(directory(i).name,suffix))
        continue
    end
    filenames{length(filenames)+1} = directory(i).name;
end

% addpath natsortfiles
filenames_sort = natsortfiles(filenames);

for i = 1:length(filenames_sort)
    fprintf(f, '%s\n', [directoryname filenames_sort{i}]);
end
fclose(f)
