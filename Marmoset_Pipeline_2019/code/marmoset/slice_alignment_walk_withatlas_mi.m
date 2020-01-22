% for test 2 lets use a brain
function [output,a_total,b_total,theta_total,best_E] = slice_alignment_walk_withatlas(input, atlas, cost,niter, init_a, init_b, init_theta, interpmode, coronalflip)
% assumes atlas is the same size at input, does not check for it

% flip from coronal plane to to sag
if nargin < 9
    coronalflip = 0;
end
if coronalflip
    input.img = cor_sag_rot(input.img);
    input.hdr.dime.dim(2:4) = size(input.img);
    atlas = cor_sag_rot(atlas);
end

% input is filename or analyze avw structure
if nargin == 0
elseif nargin == 2
    cost = 'MSE';
end
if nargin < 8
    interpmode = 'linear';
end

% clear all;
% close all;
% fclose all;

% filename = '/cis/project/adni/work/timothy/Controls_for_Hope_Trial_Analyze/002_S_0413/moBL/ADNI_002_S_0413_MR____________MPRAGE_SENS_br_raw_20060519180201504_1_S14782_I15800.img';
% avw = avw_img_read(filename);
if isstruct(input)
    avw = input;
else
    filename = input;
    avw = avw_img_read(filename);
end


% build a domain for sampling
nx_orig= double(avw.hdr.dime.dim([3,2,4]));
dx_orig = double(avw.hdr.dime.pixdim([3,2,4]));

x_orig = (0:nx_orig(1)-1)*dx_orig(1);
y_orig = (0:nx_orig(2)-1)*dx_orig(2);
z_orig = (0:nx_orig(3)-1)*dx_orig(3);
x_orig = x_orig - mean(x_orig);
y_orig = y_orig - mean(y_orig);
z_orig = z_orig - mean(z_orig);

[X_orig,Y_orig,Z_orig] = meshgrid(x_orig,y_orig,z_orig);
[XX_orig,YY_orig] = meshgrid(x_orig,y_orig); % often we do not use z
    
% maybe smooth the image in the coronal plane
%kernel = zeros(5,5,3);
%kernel(:,:,2) = ones(5,5);
%avw.img = convn(avw.img,kernel)./sum(sum(sum(kernel)));


% check for missing slices
missingsliceind = [];
for i = 1:size(avw.img,3)
%     if sum(sum(abs(avw.img(:,:,i)-avw.img(1,1,i)))) == 0
%         missingsliceind = [missingsliceind i];
%     end
    if size(unique(avw.img(:,:,i)),1) < 2
        missingsliceind = [missingsliceind i];
    end
end
slicenumbers = 1:size(avw.img,3);
slicenumbers(missingsliceind) = [];

% maybe assign coordinates to every slice, then compute dz by subtracting
% coordinates
slicecoord = slicenumbers*avw.hdr.dime.pixdim(4)-avw.hdr.dime.pixdim(4)/2;

% remove the missing slices from the image
avw.img(:,:,missingsliceind) = [];
origimg = avw.img;
avw.hdr.dime.dim(2:4) = size(avw.img);

% smooth the images
for i = 1:size(avw.img,3)
   avw.img(:,:,i) = imgaussfilt(avw.img(:,:,i),2);
end

% smooth the atlas also?
for i = 1:size(atlas,3)
   atlas(:,:,i) = imgaussfilt(atlas(:,:,i),2);
end


% downsample the image
downsamplefactor = 1;
newimg = zeros([length(1:downsamplefactor:size(avw.img,1)) length(1:downsamplefactor:size(avw.img,2))]);
for i = 1:size(avw.img,3)
   newimg(:,:,i) = avw.img(1:downsamplefactor:end,1:downsamplefactor:end,i);
end
avw.img = newimg;
avw.hdr.dime.dim(2:4) = size(newimg);
avw.hdr.dime.pixdim(2:3) = avw.hdr.dime.pixdim(2:3).*downsamplefactor;

% pad one slice on the top and once slice on the bottom for central
% differences circshift stuff
newimg = zeros(size(avw.img,1), size(avw.img,2), size(avw.img,3)+4);
newimg(:,:,3:end-2) = avw.img;
avw.img = newimg;
avw.hdr.dime.dim(2:4) = size(avw.img);
clear newimg
slicecoord = [slicecoord(1) - dx_orig(3)*2, slicecoord(1) - dx_orig(3), slicecoord, slicecoord(end) + dx_orig(3), slicecoord(end) + dx_orig(3)*2];

% newimg = zeros(size(origimg,1), size(origimg,2), size(origimg,3)+4);
% newimg(:,:,3:end-2) = origimg;
% origimg = newimg;
% clear newimg

% maybe pad the image in the sag/trans planes so that the image doesnt move
% off-"screen"

% build a domain for sampling
nx = double(avw.hdr.dime.dim([3,2,4]));
dx = double(avw.hdr.dime.pixdim([3,2,4]));

x = (0:nx(1)-1)*dx(1);
y = (0:nx(2)-1)*dx(2);
z = (0:nx(3)-1)*dx(3);
x = x - mean(x);
y = y - mean(y);
z = z - mean(z);

[X,Y,Z] = meshgrid(x,y,z);
[XX,YY] = meshgrid(x,y); % often we do not use z


% extract the image
I0 = avw.img;
% normalize to roughly 0-1
scale = quantile(I0(:),0.99);
I0 = I0/scale;
origimg = origimg/scale;


% visualize the image
figure;
subplot(2,2,1)
% isosurface(x,y,z,I0,0.5)
imagesc(y_orig,z_orig,squeeze(origimg(:,round(end/2),:)/scale)')
axis image
set(gca,'ydir','normal')
title('observed')
colormap gray

subplot(2,2,2)
imagesc(x_orig,z_orig,squeeze(origimg(round(end/2),:,:)/scale)')
axis image
set(gca,'ydir','normal')
title('observed')
colormap gray
drawnow;

% our initial guess for I
I = I0;

% visualize our guess, this will be updated as the algorithm progresses
subplot(2,2,2)
imagesc(y,z,squeeze(I(:,round(end/2),:))')
axis image
set(gca,'ydir','normal')
title('observed')
drawnow;

% now we want to estimate parameters
if nargin < 5
    init_a = zeros(1,nx(3));
    init_b = zeros(1,nx(3));
    init_theta = zeros(1,nx(3));
else
    init_a = [0 0 init_a(slicenumbers) 0 0];
    init_b = [ 0 0 init_b(slicenumbers) 0 0];
    init_theta = [0 0 init_theta(slicenumbers) 0 0];
end

a = zeros(1,nx(3));
b = zeros(1,nx(3));
a_old = a;
b_old = b;
theta = zeros(1,nx(3));
theta_old = theta;

% for human brain this step size worked reasonably well
if strcmp(cost, 'MSE') || strcmp(cost,'MI')
%     epsilonxy = 0.0001;
%     epsilontheta = 0.000002; % need to make this very small now
    %epsilonxy = 0.00000001;
    %epsilontheta = 0.00000002;
    
    % these are good
    %epsilonxy = 0.00005;
    %epsilontheta = 0.00000000001;
    
    %using these for epoch stuff
%     epsilonxy = 0.0002;
%     epsilontheta = 0.0000000001;
%     minepsilonxy = 1e-20;
%     minepsilontheta = 2*10^-24;
%     sigmaxy = 0.7;
%     sigmatheta = pi/180*100;
%     sigma_atlas = 0.1;
%     sigma_target = 1;
    
    % using these for 100um mouse brain to allen atlas
%     epsilonxy = 0.00002;
%     epsilontheta = 0.000004;
%     minepsilonxy = 1e-20;
%     minepsilontheta = 2*10^-24;
%     sigmaxy = 0.7;
%     sigmatheta = pi/180*2;
%     sigma_atlas = 1;
%     sigma_target = 1;
%     
%     % using these for 40um mouse brain to allen atlas
    %epsilonxy = 0.000006;
    %epsilontheta = 0.0000012;
    
    % using these for nowhiten
    epsilonxy = 0.0000025;
    epsilontheta = 0.00000055;
    
    minepsilonxy = 1e-20;
    minepsilontheta = 2*10^-24;
    sigmaxy = 0.7*10;
    sigmatheta = pi/180*2*10;
    sigma_atlas = 1;
    sigma_target = 1;
    % maybe reduce sigma_target for the end sections (like the cerebellum)
    sigma_target_radius = 30;
    min_sigma_target = 1;
    factor_vector = ones(1,nx(3));
    factor_vector(1:sigma_target_radius) = linspace(min_sigma_target,1,sigma_target_radius);
    factor_vector(end-sigma_target_radius+1:end) = linspace(1,min_sigma_target,sigma_target_radius);
    sigma_target_vec = (ones(1,nx(3))*sigma_target) .* factor_vector;
    
    if strcmp(cost,'MSE')
        sigma_atlas = 1;
        sigma_atlas_radius = 34;
        min_sigma_atlas = 2;

    else
        sigma_atlas = 0.0005;
        min_sigma_atlas = sigma_atlas;
        sigma_atlas_radius = 30;
    end
    
    factor_vector = ones(1,nx(3));
    factor_vector(1:sigma_atlas_radius) = linspace(min_sigma_atlas,1,sigma_atlas_radius);
    factor_vector(end-sigma_atlas_radius+1:end) = linspace(1,min_sigma_atlas,sigma_atlas_radius);
    sigma_atlas_vec = (ones(1,nx(3))*sigma_atlas) .* factor_vector;
    
    %sigmaxy = 0.1;
    %sigmatheta = pi/180*1;
else
    epsilonxy = 0.0002;
    epsilontheta = 0.000002; % need to make this very small now
    % for human brain these quadratic prior factors worked
    sigmaxy = 0.1;
    sigmatheta = pi/180*0.5;
end
%epsilonxy = 0.001;
%epsilontheta = 0.0000002; % need to make this very small now



% number of iterations
%niter = 50;
iter = 1;
TI = zeros(size(I));
TI_orig = zeros(size(input.img));
%TI_orig_int = zeros(size(input.img));
TI_orig_int = zeros(size(I,1),size(I,2),size(I,3)-4);
Eold = 1e10;
best_E = Eold;
best_a = a;
best_b = b;
best_theta = theta;
climbcountxy = 0;
climbcounttheta = 0;
maxclimbcount = 3;
% update translation on odd, and rotation on even
while (iter < niter)
    % deform the image with the current guess
    transx = zeros(nx(3),1);
    transy = zeros(nx(3),1);
    for i = 1 : nx(3)
        %d = [0 -theta(i) 0 a(i);
        %    theta(i) 0 0 b(i);
        %    0 0 0 0;
        %    0 0 0 0];
        %A = expm(d);
        temptheta = theta + init_theta;
        tempa = a + init_a;
        tempb = b + init_b;
        A = [cos(temptheta(i)), -sin(temptheta(i)), 0, tempa(i);
            sin(temptheta(i)), cos(temptheta(i)), 0,  tempb(i);
            0 0 1 0;
            0 0 0 1];
        TX = A(1,1)*XX + A(1,2)*YY + A(1,4);
        TY = A(2,1)*XX + A(2,2)*YY + A(2,4);
        TI(:,:,i) =  linearInterpolate2D(XX,YY,I(:,:,i),TX,TY,interpmode,'edge');
        if i > 2 && i < nx(3)-1
            TX = A(1,1)*XX_orig + A(1,2)*YY_orig + A(1,4);
            TY = A(2,1)*XX_orig + A(2,2)*YY_orig + A(2,4);
            TI_orig_int(:,:,i-2) =  linearInterpolate2D(XX_orig,YY_orig,origimg(:,:,i-2),TX,TY,interpmode,'edge');
        end
        transx(i) = A(1,4);
        transy(i) = A(2,4);
    end
    TI_orig(:,:,slicenumbers) = TI_orig_int(:,:,1:end);
%     DXTI = (circshift(TI,[0 -1 0]) - TI)/dx(1);
%     DYTI = (circshift(TI,[-1 0 0]) - TI)/dx(2);
% lets use centered difference for xy, this is much nicer
    DXTI = (circshift(TI,[0 -1 0]) - circshift(TI,[0 1 0]))/dx(1)/2; 
    DYTI = (circshift(TI,[-1 0 0]) - circshift(TI,[1 0 0]))/dx(2)/2;
    
    % consider something other than central differences for unevenly spaced
    % data. lagrangian interpolating polynomial maybe, since this will
    % produce the same result as central differences on evenly spaced
    % slices
    
    % try 2nd order lagrangian polynomial first
    %LZTI = repmat( reshape( 2 ./ ( (circshift(slicecoord,[0 1]) - slicecoord) .* (circshift(slicecoord,[0 1]) - circshift(slicecoord,[0 -1])) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* circshift(TI, [0 0 1]) + ...
    %    repmat( reshape( 2 ./ ( (slicecoord - circshift(slicecoord,[0 1])) .* (slicecoord - circshift(slicecoord,[0 -1])) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* TI + ...
    %    repmat( reshape( 2 ./ ( (circshift(slicecoord,[0 -1]) - circshift(slicecoord,[0 1])) .* (circshift(slicecoord,[0 -1]) - slicecoord) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* circshift(TI, [0 0 -1]);
    
    % try with n = 5
    % 2/( (x_1-x_2)(x_1-x_3)(x_1-x_4)(x_1-x_5) ) * y_1 + ...
    
    % this one for (circshift(slicecoord,[0 1])
     shiftindices = [-2 -1 0 1 2];
     mynumerator = zeros(length(shiftindices),length(slicecoord));
     for i = 1:length(shiftindices)
         myshiftind = shiftindices;
         myshiftind(find(myshiftind == shiftindices(i))) = [];
         %numerator1 = 2.*circshift(slicecoord,[0 -2]).*circshift(slicecoord,[0 -1]) + 2.*circshift(slicecoord,[0 -2]).*slicecoord + 2.*circshift(slicecoord,[0 -2]).*circshift(slicecoord,[0 2]) + 2.*circshift(slicecoord,[0 -1]).*slicecoord + 2.*circshift(slicecoord,[0 -1]).*circshift(slicecoord,[0 2]) + 2.*slicecoord.*circshift(slicecoord,[0 2]) - 6*slicecoord.*circshift(slicecoord,[0 -2]) - 6*slicecoord.*circshift(slicecoord,[0 -1]) - 6*slicecoord.*circshift(slicecoord,[0 0])  - 6*slicecoord.*circshift(slicecoord,[0 2]) + 12*slicecoord.^2;
         mynumerator(i,:) = 2.*circshift(slicecoord,[0 myshiftind(1)]).*circshift(slicecoord,[0 myshiftind(2)]) + 2.*circshift(slicecoord,[0 myshiftind(1)]).*circshift(slicecoord,[0 myshiftind(3)]) + 2.*circshift(slicecoord,[0 myshiftind(1)]).*circshift(slicecoord,[0 myshiftind(4)]) + 2.*circshift(slicecoord,[0 myshiftind(2)]).*circshift(slicecoord,[0 myshiftind(3)]) + 2.*circshift(slicecoord,[0 myshiftind(2)]).*circshift(slicecoord,[0 myshiftind(4)]) + 2.*circshift(slicecoord,[0 myshiftind(3)]).*circshift(slicecoord,[0 myshiftind(4)]) - 6*slicecoord.*circshift(slicecoord,[0 myshiftind(1)]) - 6*slicecoord.*circshift(slicecoord,[0 myshiftind(2)]) - 6*slicecoord.*circshift(slicecoord,[0 myshiftind(3)])  - 6*slicecoord.*circshift(slicecoord,[0 myshiftind(4)]) + 12*slicecoord.^2;
     end
     
     LZTI = repmat( reshape( mynumerator(4,:) ./ ( (circshift(slicecoord,[0 1]) - slicecoord) .* (circshift(slicecoord,[0 1]) - circshift(slicecoord,[0 -1])) .* (circshift(slicecoord,[0 1]) - circshift(slicecoord,[0 2])) .* (circshift(slicecoord,[0 1]) - circshift(slicecoord,[0 -2])) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* circshift(TI, [0 0 1]) + ...
     repmat( reshape( mynumerator(5,:) ./ ( (circshift(slicecoord,[0 2]) - slicecoord) .* (circshift(slicecoord,[0 2]) - circshift(slicecoord,[0 -1])) .* (circshift(slicecoord,[0 2]) - circshift(slicecoord,[0 -2])) .* (circshift(slicecoord,[0 2]) - circshift(slicecoord,[0 1])) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* circshift(TI, [0 0 2]) + ...
     repmat( reshape( mynumerator(2,:) ./ ( (circshift(slicecoord,[0 -1]) - slicecoord) .* (circshift(slicecoord,[0 -1]) - circshift(slicecoord,[0 1])) .* (circshift(slicecoord,[0 -1]) - circshift(slicecoord,[0 -2])) .* (circshift(slicecoord,[0 -1]) - circshift(slicecoord,[0 2])) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* circshift(TI, [0 0 -1]) + ...
     repmat( reshape( mynumerator(1,:) ./ ( (circshift(slicecoord,[0 -2]) - slicecoord) .* (circshift(slicecoord,[0 -2]) - circshift(slicecoord,[0 1])) .* (circshift(slicecoord,[0 -2]) - circshift(slicecoord,[0 2])) .* (circshift(slicecoord,[0 -2]) - circshift(slicecoord,[0 -1])) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* circshift(TI, [0 0 -2]) + ...
     repmat( reshape( mynumerator(3,:) ./ ( (slicecoord - circshift(slicecoord,[0 1])) .* (slicecoord - circshift(slicecoord,[0 2])) .* (slicecoord - circshift(slicecoord,[0 -1])) .* (slicecoord - circshift(slicecoord,[0 -2])) ), [1,1,size(slicecoord,2)] ), [size(TI,1),size(TI,2),1] ) .* TI;
     %disp(sum(sum(sum(LZTI.*TI))))




    
    %LZTI = (-2*TI + circshift(TI,[0 0 1]) + circshift(TI,[0 0 -1]))/dx(3)/dx(3);
    
    % cost
    
    % try penalizing the difference in transform from slice to slice. so
    % that a global rigid motion has no cost. but this doesn't really work
    % when the slices are so fuzzy at the beginning because groups of
    % slices aren't well aligned anyway. maybe this should be run after X
    % iterations.
    
    % get difference in transform
    transx_diff = diff(transx);
    transy_diff = diff(transy);
    theta_diff = diff(theta);
    

    if strcmp(cost,'MSE')
        dz = ((circshift(slicecoord, [0 -1]) - slicecoord) - (circshift(slicecoord, [0 1]) - slicecoord))/2;
        dz([1,2]) = dx(3);
        dz([end,end-1]) = dx(3);
        %Eimtarget = 1/sigma_target^2 * sum(sum(sum(-LZTI.*TI)))*prod(dx)/2;
        Eimtarget = sum(1./squeeze(sigma_target_vec).^2 .* squeeze(sum(sum(-LZTI.*TI)))')*prod(dx)/2;
        %Eimatlas = 1/sigma_atlas^2 * sum(sum(sum( (TI_orig(:,:,slicenumbers) - atlas(:,:,slicenumbers)).^2 )))*prod(dx)/2;
        Eimatlas = sum(1./sigma_atlas_vec(3:end-2).^2 .* squeeze(sum(sum( (TI_orig(:,:,slicenumbers) - atlas(:,:,slicenumbers)).^2 )))')*prod(dx)/2;
        Eregxy = sum((a.^2 + b.^2).*dz)/2/sigmaxy^2/size(slicecoord,2);
        Eregtheta = sum((theta.^2).*dz)/2/sigmatheta^2/size(slicecoord,2);
        E = Eimtarget + Eimatlas + Eregxy + Eregtheta;
        %E = 1/sigma_target^2 * sum(sum(sum(-LZTI.*TI)))*prod(dx)/2  + sum((a.^2 + b.^2).*dz)/2/sigmaxy^2/size(slicecoord,2) + sum((theta.^2).*dz)/2/sigmatheta^2/size(slicecoord,2); % plus regularization
        % add the error with the atlas
        %E = E + 1/sigma_atlas^2 * sum(sum(sum( (TI_orig(:,:,slicenumbers) - atlas(:,:,slicenumbers)).^2 )));
        %E = sum(sum(sum(-LZTI.*TI)))*prod(dx)/2  + sum((abs(a).^(3/2) + abs(b).^(3/2)).*dz)/2/sigmaxy^2/size(slicecoord,2) + sum((abs(theta).^(3/2)).*dz)/2/sigmatheta^2/size(slicecoord,2); % plus regularization
    elseif strcmp(cost,'MI')
        bins = linspace(0,255,20);
        sigma = 0.05;
        [mi,migrad] = calc_mi_kernel_vec(TI_orig(:,:,slicenumbers),atlas(:,:,slicenumbers),bins,sigma);
        mi = mi*-1; 
        migrad = migrad*-1;
        dz = ((circshift(slicecoord, [0 -1]) - slicecoord) - (circshift(slicecoord, [0 1]) - slicecoord))/2;
        dz([1,2]) = dx(3);
        dz([end,end-1]) = dx(3);
        %Eimtarget = 1/sigma_target^2 * sum(sum(sum(-LZTI.*TI)))*prod(dx)/2;
        Eimtarget = sum(1./squeeze(sigma_target_vec).^2 .* squeeze(sum(sum(-LZTI.*TI)))')*prod(dx)/2;
        %Eimatlas = 1/sigma_atlas^2 * sum(sum(sum( (TI_orig(:,:,slicenumbers) - atlas(:,:,slicenumbers)).^2 )))*prod(dx)/2;
        Eimatlas = sum(1./sigma_atlas_vec(3:end-2).^2 .* mi )*prod(dx)/2;
        Eregxy = sum((a.^2 + b.^2).*dz)/2/sigmaxy^2/size(slicecoord,2);
        Eregtheta = sum((theta.^2).*dz)/2/sigmatheta^2/size(slicecoord,2);
        E = Eimtarget + Eimatlas + Eregxy + Eregtheta;
    else
        dz = diff(slicecoord);
        E = sum(sum(sum(-LZTI.*TI)))*prod(dx)/2 + sum((transx_diff'.^2 + transy_diff'.^2).*dz)/2/sigmaxy^2 + sum((theta_diff.^2).*dz)/2/sigmatheta^2;
    end
    if E < best_E
        climbcountxy = 0;
        climbcounttheta = 0;
        best_E = E;
        best_a = a;
        best_b = b;
        best_theta = theta;
        if ~mod(iter,2) % if iter is even, that means last time it was odd and I just updated translation
            % dropped this from 1.1 to 1.04 for nowhiten
            epsilonxy = epsilonxy*1.04;
        else
            epsilontheta = epsilontheta*1.04;
        end
    end
    if iter > 1 % dont change epsilon for the first n iterations
        if E > Eold
            if ~mod(iter,2) % if iter is even, that means last time it was odd and I just updated translation
                climbcountxy = climbcountxy+1;
                if climbcountxy > maxclimbcount
                    epsilonxy = epsilonxy/1.5;
                    disp(['reducing epsilonxy to ' num2str(epsilonxy)])
                    if epsilonxy < minepsilonxy && epsilontheta < minepsilontheta
                        break
                    end
                    a = best_a;
                    b = best_b;
                    theta = best_theta;
                    climbcountxy = 0;
                    continue;
                end
            else
                climbcounttheta = climbcounttheta+1;
                if climbcounttheta > maxclimbcount
                    epsilontheta = epsilontheta/1.5;
                    disp(['reducing epsilontheta to ' num2str(epsilontheta)])
                    if epsilontheta < minepsilontheta && epsilontheta < minepsilontheta
                        break
                    end
                    a = best_a;
                    b = best_b;
                    theta = best_theta;
                    climbcounttheta = 0;
                    continue;
                end
            end
        end
%         if E < Eold
%             if ~mod(iter,2) % if iter is even, that means last time it was odd and I just updated translation
%                 epsilonxy = epsilonxy*1.1;
%             else
%                 epsilontheta = epsilontheta*1.1;
%             end
%         end
    end
        
    if ~strcmp(cost,'MSE') && ~strcmp(cost,'MI')
        disp(['iter: ' num2str(iter) ', cost: ' num2str(E) ', im = ' num2str(Eim) ', regxy = ' num2str(Eregxy) ', regt = ' num2str(Eregtheta) ', ep = ' num2str(epsilonxy) ', ' num2str(epsilontheta)])
    else
        %disp(['iter: ' num2str(iter) ', cost: ' num2str(E) ', im = ' num2str(sum(sum(sum(-LZTI.*TI)))*prod(dx)/2) ', regxy = ' num2str( sum((abs(a).^(3/2) + abs(b).^(3/2)).*dz)/2/sigmaxy^2/size(slicecoord,2)) ', regt = ' num2str(sum((abs(theta).^(3/2)).*dz)/2/sigmatheta^2/size(slicecoord,2)) ', ep = ' num2str(epsilonxy) ', ' num2str(epsilontheta)])
        disp(['iter: ' num2str(iter) ', cost: ' num2str(E) ', im_t = ' num2str(Eimtarget) ', im_a = ' num2str(Eimatlas) ', regxy = ' num2str( Eregxy) ', regt = ' num2str(Eregtheta) ', ep = ' num2str(epsilonxy) ', ' num2str(epsilontheta)])
    end
    
    
    gradx = 1./sigma_target_vec.^2 .* squeeze(sum(sum( -2*LZTI.*DXTI   ,1),2)*dx(1)*dx(2))';
    grady = 1./sigma_target_vec.^2 .* squeeze(sum(sum( -2*LZTI.*DYTI   ,1),2)*dx(1)*dx(2))';
    
    % add atlas energy to gradient
    if strcmp(cost,'MSE') 
        diffatlas = zeros(size(DXTI));
        diffatlas(:,:,3:end-2) =  TI_orig(:,:,slicenumbers) - atlas(:,:,slicenumbers);
    else
        diffatlas = zeros(size(DXTI));
        diffatlas(:,:,3:end-2) = migrad;
    end
    
%     gradx = gradx + 1/sigma_atlas^2 .* squeeze(sum(sum( 2*DXTI.*(diffatlas),1),2)*dx(1)*dx(2))';
%     grady = grady + 1/sigma_atlas^2 .* squeeze(sum(sum( 2*DYTI.*(diffatlas),1),2)*dx(1)*dx(2))';
    gradx = gradx + 1./sigma_atlas_vec.^2 .* squeeze(sum(sum( 2*DXTI.*(diffatlas),1),2)*dx(1)*dx(2))';
    grady = grady + 1./sigma_atlas_vec.^2 .* squeeze(sum(sum( 2*DYTI.*(diffatlas),1),2)*dx(1)*dx(2))';
    
    gradtheta = 1./sigma_target_vec.^2 .* squeeze(sum(sum( -2*LZTI.*( DXTI.*(-Y) + DYTI.*(X)  )   ,1),2)*dx(1)*dx(2))';
    %gradtheta = gradtheta + 1/sigma_atlas^2 .* squeeze(sum(sum( 2*( DXTI.*(-Y) + DYTI.*(X)  ).*(diffatlas),1),2)*dx(1)*dx(2))';
    gradtheta = gradtheta + 1./sigma_atlas_vec.^2 .* squeeze(sum(sum( 2*( DXTI.*(-Y) + DYTI.*(X)  ).*(diffatlas),1),2)*dx(1)*dx(2))';
    
    % regularization
    if strcmp(cost,'MSE') || strcmp(cost,'MI')
        gradx = gradx + a/sigmaxy^2;
        grady = grady + b/sigmaxy^2;
        gradtheta = gradtheta + theta/sigmatheta^2;
        %gradx = gradx + 3/2 * sign(a) .* abs(a).^(1/2) / sigmaxy^2;
        %grady = grady + 3/2 * sign(b) .* abs(b).^(1/2) / sigmaxy^2;
        %gradtheta = gradtheta + 3/2 * sign(theta) .* abs(theta).^(1/2) / sigmatheta^2;
    else
        gradx = gradx + [0 transpose(transx_diff)]/sigmaxy^2;
        grady = grady + [0 transpose(transy_diff)]/sigmaxy^2;
        gradtheta = gradtheta + [0 theta_diff]/sigmatheta^2;
    end

    
    % update
    if mod(iter,2) % if odd
        a_old = a;
        b_old  = b;
        a = a - epsilonxy*gradx;
        b = b - epsilonxy*grady;
    else % if even
        theta_old = theta;
        theta = theta - epsilontheta*gradtheta;
    end
    
    subplot(2,2,3)
    imagesc(y_orig,z_orig,squeeze(TI_orig(:,round(end/2),:))')
    axis image
    set(gca,'ydir','normal')
    title 'estimate'
    subplot(2,2,4)
    imagesc(x_orig,z_orig,squeeze(TI_orig(round(end/2),:,:))')
    axis image
    set(gca,'ydir','normal')
    title 'estimate'
    
    
    
%     drawnow;

    
    

    Eold = E;
    iter = iter+1;
end
% set to the best results
a = best_a;
b = best_b;
theta = best_theta;
for i = 1 : nx(3)
    %d = [0 -theta(i) 0 a(i);
    %    theta(i) 0 0 b(i);
    %    0 0 0 0;
    %    0 0 0 0];
    %A = expm(d);
    temptheta = theta + init_theta;
    tempa = a + init_a;
    tempb = b + init_b;
    A = [cos(temptheta(i)), -sin(temptheta(i)), 0, tempa(i);
        sin(temptheta(i)), cos(temptheta(i)), 0,  tempb(i);
        0 0 1 0;
        0 0 0 1];
    TX = A(1,1)*XX + A(1,2)*YY + A(1,4);
    TY = A(2,1)*XX + A(2,2)*YY + A(2,4);
    TI(:,:,i) =  linearInterpolate2D(XX,YY,I(:,:,i),TX,TY,interpmode,'edge');
    if i > 2 && i < nx(3)-1
        TX = A(1,1)*XX_orig + A(1,2)*YY_orig + A(1,4);
        TY = A(2,1)*XX_orig + A(2,2)*YY_orig + A(2,4);
        TI_orig_int(:,:,i-2) =  linearInterpolate2D(XX_orig,YY_orig,origimg(:,:,i-2),TX,TY,interpmode,'edge');
    end
end
TI_orig(:,:,slicenumbers) = TI_orig_int(:,:,1:end);

% add the scale back
output = input;
output.img = TI_orig*scale;



% generate transforms the size of the image
a_total = zeros(1,size(output.img,3));
b_total = zeros(1,size(output.img,3));
theta_total = zeros(1,size(output.img,3));

a_total(slicenumbers) = a(3:end-2);
b_total(slicenumbers) = b(3:end-2);
theta_total(slicenumbers) = theta(3:end-2);

% rotate back
if coronalflip
output.img = cor_sag_rot(output.img);
output.hdr.dime.dim(2:4) = size(output.img);
end
