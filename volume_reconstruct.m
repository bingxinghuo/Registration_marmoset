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
    imwrite(signal3d{1}(:,:,1),savefile,'writemode','overwrite','compression','packbit')
    imwrite(uint8(signal3d{1}(:,:,1)>0)*255,maskfile,'writemode','overwrite','compression','packbit')
    for k=2:size(signal3d{1},3)
        imwrite(signal3d{1}(:,:,k),savefile,'writemode','append','compression','packbit')
        imwrite(uint8(signal3d{1}(:,:,k)>0)*255,maskfile,'writemode','append','compression','packbit')
    end
else
    rgbimg=cat(3,signal3d{1}(:,:,1),signal3d{2}(:,:,1),signal3d{3}(:,:,1));
    imwrite(rgbimg,savefile,'writemode','overwrite','compression','packbit')
    imwrite(uint8(rgbimg>0)*255,maskfile,'writemode','overwrite','compression','packbit')
    for k=2:size(signal3d{1},3)
        rgbimg=cat(3,signal3d{1}(:,:,k),signal3d{2}(:,:,k),signal3d{3}(:,:,k));
        imwrite(rgbimg,savefile,'writemode','append','compression','packbit')
        imwrite(uint8(rgbimg>0)*255,maskfile,'writemode','append','compression','packbit')
    end
    
end
% disp(['Please proofread using ',maskfile,' before transforming into the atlas space.'])

