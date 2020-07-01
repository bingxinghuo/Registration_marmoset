%% Simple 3D reconstruction for marmoset sections
function signal3d=volume_reconstruct(animalid,signalstack,targetdir,savefile,flips)
if nargin<5
    flips=[1,2];
end
% get 3D reconstruction of annotation
annoimgfile=[targetdir,'/',upper(animalid),'_annotation.img'];
seclistfile=[targetdir,'/',upper(animalid),'F_anno_seclist.csv']; % correspondence file
[annoimgs,seclist]=loadannoimg(annoimgfile,seclistfile,flips);
%%
[filepath,filename,~]=fileparts(savefile);
maskfile=[filepath,'/',filename,'_mask.tif'];
%% reorient to atlas
seccorr=seclist{2};
signal3d=maptoatlas(signalstack,annoimgs,seccorr);
if length(signal3d)==1
    saveimgstack(signal3d{1},savefile);
    saveimgstack(uint8(signal3d{1}>0)*255,maskfile);
else
    rgbimg=cat(3,signal3d{1}(:,:,1),signal3d{2}(:,:,1),signal3d{3}(:,:,1));
    saveimgstack(rgbimg,savefile);
    saveimgstack(uint8(rgbimg>0)*255,maskfile);    
end
disp('Please proofread using ',maskfile,' before transforming into the atlas space.')

