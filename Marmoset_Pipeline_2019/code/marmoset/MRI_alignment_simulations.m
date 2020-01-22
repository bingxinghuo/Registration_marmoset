function MRI_alignment_simulations(startiter, enditer, simulation)
patientnumber = 'MRIsim'
for kk = startiter:enditer
    patientnumber = 'MRIsim';
    % target and atlas filenames
    %patientnumber = 'M921';
    %targetfilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/M920_80_cropped.img';
    atlasfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/atlas_115_flip_cropped.img';
    %atlasmaskfilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/mask_80_flip_refined.img';
    %annofilename = '/sonas-hs/mitra/hpc/home/blee/data/atlas_images/marmoset/annotation_80_flip.img';
    %mrifilename = '/cis/home/leebc/Projects/Mouse_Histology/data/marmoset/test/MRI_rigid.img';

    % input directories
    %targetdirectoryprefix = '/sonas-hs/mitra/hpc/home/blee/data/stackalign/';
    outputtargetfilename = atlasfilename;
    %rawmrifilename = [targetdirectoryprefix patientnumber '/20160528_21095708DTI128axb1000news180001a001.nii'];
    outputmrifilename = atlasfilename;
    targetfilename = outputtargetfilename;
    mrifilename = outputmrifilename;

    % pre process
    %marmosetRegistration_pre_bnb(patientnumber,targetdirectoryprefix,outputtargetfilename,rawmrifilename,outputmrifilename,[100,383,137,416]);

    % output directories
    %dataoutputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/registration/MRI_alignment_simulations_noise__0_25__' num2str(simulation) '/'];
    dataoutputdirectoryname = ['/sonas-hs/mitra/hpc/home/blee/data/registration/MRI_alignment2_simulations_noise_' num2str(simulation) '/'];
    mkdir(dataoutputdirectoryname);
    transformdirectoryname = [dataoutputdirectoryname 'transforms/'];
    mkdir(transformdirectoryname);

    temptarget = avw_img_read([outputtargetfilename '.img'],0);

    % generate cost function mask
    costmask = make_blank_img();
    blankimg = make_blank_img();
    costmask.img = ones(size(temptarget.img));
    for i = 1:size(costmask.img,2)
        if length(unique(temptarget.img(:,i,:))) <= 2
            % set to background value instead of 0? for hist matching?
            costmask.img(:,i,:) = 0;
        end
    end
    costmask.hdr.dime.dim(2:4) = size(costmask.img);
    costmask.hdr.dime.pixdim(2:4) = temptarget.hdr.dime.pixdim(2:4);
    costmask.hdr.dime.datatype = 2;
    costmask.hdr.dime.bitpix = 8;
    costmask.hdr.dime.glmax = 1;
    costmask.hdr.hist = blankimg.hdr.hist;
    costmask.fileprefix = [dataoutputdirectoryname '/' patientnumber '_costmask'];
    avw_img_write(costmask,costmask.fileprefix);

    %% randomly scramble the target image
    [target_scrambled,a_save,b_save,theta_save] = scrambleImageCoronal(temptarget);
    saveSectionTransforms(b_save,a_save,theta_save, [dataoutputdirectoryname '/transforms'], ['iteration_' num2str(kk) '_original']);
    
    %% randomly euler3d the MRI
    randmrifilename = [dataoutputdirectoryname '/' patientnumber '_MRI_randrot.img'];
    system(['python randomRigid3DMRI.py ' mrifilename ' ' randmrifilename ' ' transformdirectoryname patientnumber '_MRI_rigidtrans_original.txt']);
    
    %% randomly add noise to the MRI
    randmri = avw_img_read(randmrifilename,0);
    randmri.img = randmri.img + randn(size(randmri.img)) .* (0.25*mean(mean(mean(randmri.img))));
    
    %% initial stack alignment for target image
    [output,init_a,init_b,init_theta] = slice_alignment_walk(target_scrambled,'MSE',300);
    output.fileprefix = [dataoutputdirectoryname '/' patientnumber '_stackalign'];
    avw_img_write(output, output.fileprefix);

    %% rigid align MRI to target
    system(['python rigidAlignMRI_maskcost.py ' randmrifilename ' ' output.fileprefix '.img ' costmask.fileprefix '.img ' dataoutputdirectoryname patientnumber '_MRI_rigid.img ' transformdirectoryname patientnumber '_MRI_rigidtrans_simulation' num2str(kk) '.txt']);

    %% start section alignment with MRI
    target = target_scrambled;
    MRI = avw_img_read([dataoutputdirectoryname patientnumber '_MRI_rigid.img'],0);


    a_old = init_a; % x trnalsation
    b_old = init_b; % y translation
    theta_old = init_theta; % rotation
    nepochs = 8; % total iterations of the process, change to whatever
    newtarget = target;
    newMRI = MRI;
    newMRI.fileprefix = [dataoutputdirectoryname 'MRI_iter0'];
    avw_img_write(newMRI,newMRI.fileprefix);
    % start main loop
    for i = 1:nepochs
        % do the section alignment 
        niter = 100;
        %[output,a,b,theta] = slice_alignment_walk_withatlas(newtarget, newMRI.img, 'MSE', niter, a_old, b_old, theta_old,'linear');
        [output,a,b,theta] = slice_alignment_walk_withatlas_marmoset(target, newMRI.img, 'MSE', niter, a_old, b_old, theta_old,'linear',1);
        saveSectionTransforms(a,b,theta,transformdirectoryname, ['simulation' num2str(kk) '_iter' num2str(i)]); %TODO: fill out your filenames
        
        % combine section alignment parameters for each epoch
        a_old = a+a_old;
        b_old = b+b_old;
        theta_old = theta+theta_old;
        
        % apply the section transforms to the original target image
        newtarget = applySectionTransformsCoronal(target, a_old, b_old, theta_old, 'linear');%%%
        newtarget.fileprefix = [dataoutputdirectoryname 'target_iter' num2str(i)];
        avw_img_write(newtarget,newtarget.fileprefix);
        
        % do rigid registration again
        if i < nepochs
            system(['python rigidAlignMRI_maskcost_simulations.py ' newMRI.fileprefix '.img ' newtarget.fileprefix '.img ' costmask.fileprefix '.img ' dataoutputdirectoryname 'MRI_iter' num2str(i) '.img ' transformdirectoryname 'MRI_transform_simulation' num2str(kk) '_iter' num2str(i) '.txt']);
            newMRI = avw_img_read([dataoutputdirectoryname 'MRI_iter' num2str(i) '.img'],0);
        end
        %system('python')
        %import sys
        %sys.path.append('/cis/home/fuyan/python/')
        %import reg3D
        %reg3D.reg('/cis/home/fuyan/my_documents/sectionalignment/MRIalign/newMRI.img','/cis/home/fuyan/my_documents/sectionalignment/MRIalign/newtarget.img','/cis/home/fuyan/my_documents/sectionalignment/MRIalign/transform/newMRI')
        %exit()
    end


    saveSectionTransforms(a_old,b_old,theta_old,transformdirectoryname, ['simulation' num2str(kk) '_final']);
    clear output,a_old,b_old,theta_old,init_a,init_b,init_theta,newMRI,newtarget,target,temptarget
end

end
