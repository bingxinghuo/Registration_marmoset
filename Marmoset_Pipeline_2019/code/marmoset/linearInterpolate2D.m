function [Iout,px,py] = linearInterpolate2D(X,Y,I,phiInvX,phiInvY,method,boundary,diffeo)
% the diffeo means just subtract X Y first
% this is actually a bad idea and not correct, it does not result in the
% composition of diffeos
%
% What I want is with diffeo set, boundary=c is interpretted as identity+c,
% and boundary = 'edge' is interpretted as identity + edge - identity(edge)
% 
% This is NOT IMPLEMENTED YET
%

if nargin == 5
    method = 'linear';
    boundary = 'edge'; % can be a number, or the string edge
    diffeo = 0;
end
if nargin == 6
    boundary = 'edge';
    diffeo = 0;
end
if nargin == 7
    diffeo = 0;
end


% in this case, I do not specify x,y
% this is just for convenience
if nargin == 3 || ischar(phiInvX)
    phiInvY = I;
    phiInvX = Y;
    I = X;
    [nRow,nCol,nSlice] = size(I);
    x = 1 : nCol;
    y = 1 : nRow;
    [X,Y] = meshgrid(x,y);
    diffeo = 0;
end

% % for diffeomorphism, just subtract identity, add it back at the end
% if diffeo
%     if size(I,3) ~= 2
%         error('When using diffeomorphism boundary conditions, input image must be 2D')
%     end
%     I(:,:,1) = I(:,:,1) - X;
%     I(:,:,2) = I(:,:,2) - Y;
% end

% convert to index
[nRow,nCol,nSlice] = size(I);
dx = X(1,2) - X(1,1);
dy = Y(2,1) - Y(1,1);
x0 = X(1,1);
y0 = Y(1,1);
phiInvXInd = (phiInvX - x0)/dx + 1; % index starts at 1
phiInvYInd = (phiInvY - y0)/dy + 1;


% integer part
phiInvXIndFloor = floor(phiInvXInd);
phiInvYIndFloor = floor(phiInvYInd);
if strcmp(method,'linear')
    % fraction part
    px = phiInvXInd - phiInvXIndFloor;
    py = phiInvYInd - phiInvYIndFloor;
end
    

% if we're doing linear interpolation, we also need to get the next index
if strcmp(method,'linear')
    phiInvXIndFloorP1 = phiInvXIndFloor+1;
    phiInvYIndFloorP1 = phiInvYIndFloor+1;
end
% boundary conditions
% we will enforce edge boundary conditions here, and modify for other
% boundary conditions later
if strcmp(method,'linear')    
    indXP1Low = phiInvXIndFloorP1<1;
    phiInvXIndFloorP1(indXP1Low) = 1;
    indXP1High = phiInvXIndFloorP1>nCol;
    phiInvXIndFloorP1(indXP1High) = nCol;
    indYP1Low = phiInvYIndFloorP1<1;
    phiInvYIndFloorP1(indYP1Low) = 1;
    indYP1High = phiInvYIndFloorP1>nRow;
    phiInvYIndFloorP1(indYP1High) = nRow;
end
indXLow = phiInvXIndFloor<1;
phiInvXIndFloor(indXLow) = 1;
indXHigh = phiInvXIndFloor>nCol;
phiInvXIndFloor(indXHigh) = nCol;
indYLow = phiInvYIndFloor<1;
phiInvYIndFloor(indYLow) = 1;
indYHigh = phiInvYIndFloor>nRow;
phiInvYIndFloor(indYHigh) = nRow;

% are out out of bounds, regardless of direction?
if strcmp(method,'nearest') && ~strcmp(boundary,'edge')
    ind = indXLow | indXHigh | indYLow | indYHigh;
end

% the way to do this RIGHT
% is to generate four images
% apply boundary conditions to each one

Iout = zeros([size(phiInvX) size(I,3)]); % initialize to same size
% [nRowOut,nColOut,nSliceOut] = size(Iout);
for i = 1 : nSlice    
    I_ = I(:,:,i);
    % okay this type of indexing doesn't work, I'll have to use vector
    % indexing
    if strcmp(method,'linear')
        if i == 1 % only do this once when looping over chanels
            ind1 = phiInvYIndFloor   + phiInvXIndFloor  *nRow - nRow;
            c1 = (1 - px) .* (1 - py);
            ind2 = phiInvYIndFloorP1 + phiInvXIndFloor  *nRow - nRow;
            c2 = (1 - px) .* (0 + py);
            ind3 = phiInvYIndFloor   + phiInvXIndFloorP1*nRow - nRow;
            c3 = (0 + px) .* (1 - py);
            ind4 = phiInvYIndFloorP1 + phiInvXIndFloorP1*nRow - nRow;
            c4 = (0 + px) .* (0 + py);
        end
        I00 = I_(ind1); % x0 y0
        I10 = I_(ind2); % x0 y1
        I01 = I_(ind3); % x1 y0
        I11 = I_(ind4); % x1 y1
        
        if i == 1 && (strcmp(boundary,'edge') || diffeo == 1) % otherwise I don't need it
            out1 = indXLow | indXHigh | indYLow | indYHigh;
            out2 = indXLow | indXHigh | indYP1Low | indYP1High;
            out3 = indXP1Low | indXP1High | indYLow | indYHigh;            
            out4 = indXP1Low | indXP1High | indYP1Low | indYP1High;
        end
        
        
                    
        if strcmp(boundary,'edge')
            % all these images already have edge boundary conditions    
            if diffeo == 0
                I__ = I00.*c1 + I10.*c2 + I01.*c3 + I11.*c4;
            elseif diffeo == 1
                % what to do here?
                % I'm pretty sure this is not what to do
                % I don't know what to do yet
                % what we're doing is taking the edge value and adding to
                % if we evaluate at a point x, outside the sampled region,
                % we want to return x (this is the simplest case)
                % that's done below
                % in the edge case
                % if x is out of bounds to the right, we want to return the
                % edge value plus the distance of x from the edge (x
                % component)
                % if it's on top this is the same, but the distance should
                % be 0
%                 keyboard

                if i == 1 % x component
                    I00(out1) = I00(out1) + phiInvX(out1) - X(ind1(out1));
                    I10(out2) = I10(out2) + phiInvX(out2) - X(ind2(out2));
                    I01(out3) = I01(out3) + phiInvX(out3) - X(ind3(out3));
                    I11(out4) = I11(out4) + phiInvX(out4) - X(ind4(out4));
                elseif i == 2 % y component
                    I00(out1) = I00(out1) + phiInvY(out1) - Y(ind1(out1));
                    I10(out2) = I10(out2) + phiInvY(out2) - Y(ind2(out2));
                    I01(out3) = I01(out3) + phiInvY(out3) - Y(ind3(out3));
                    I11(out4) = I11(out4) + phiInvY(out4) - Y(ind4(out4));
                end
                
                I__ = I00.*c1 + I10.*c2 + I01.*c3 + I11.*c4;
            end
        else % using constant boundary conditions
            % four images, apply four boundary conditions
            if diffeo == 0
                I00(out1) = boundary;
                I10(out2) = boundary;
                I01(out3) = boundary;
                I11(out4) = boundary;
            elseif diffeo == 1
                if i == 1 % x component
                    I00(out1) = phiInvX(out1) + boundary;
                    I10(out2) = phiInvX(out2) + boundary;
                    I01(out3) = phiInvX(out3) + boundary;
                    I11(out4) = phiInvX(out4) + boundary;
                elseif i == 2
                    I00(out1) = phiInvY(out1) + boundary;
                    I10(out2) = phiInvY(out2) + boundary;
                    I01(out3) = phiInvY(out3) + boundary;
                    I11(out4) = phiInvY(out4) + boundary;
                end
            end
            
            I__ = I00.*c1 + I10.*c2 + I01.*c3 + I11.*c4;
            
            
            
        end
    elseif strcmp(method,'nearest')
        if i == 1
            ind1 = phiInvYIndFloor  + phiInvXIndFloor  *nRow - nRow;
        end
        I__ = I_(ind1);
        % this image already has edge boundary conditions, switch it if we
        % want constant
        if ~strcmp(boundary,'edge')
            I__(ind) = boundary;
        end
    end
    
    Iout(:,:,i) = I__;
end


% if diffeo
%     Iout(:,:,1) = Iout(:,:,1) + X;
%     Iout(:,:,2) = Iout(:,:,2) + Y;
% end

% so notice the following
% we resample the image four times
% and we take a linear combination of these four
% Iout_{i,j} = I_{i+di_ij,j+dj_ij}*(1-px_{ij})*(1-py_{ij}) +
% I_{i+di_ij+1,j+dj_ij}*(px_{ij})*(1-py_{ij}) +
% I_{i+di_ij,j+dj_ij+1}*(1-px_{ij})*(py_{ij}) +
% I_{i+di_ij+1,j+dj_ij+1}*(px_{ij})*(py_{ij})
% hit this with another image, and reindex the sum
% sum_ij J_ij * I_{i+di_ij,j+dj_ij}*(1-px_{ij})*(1-py_{ij}) +
% sum_ij J_ij * I_{i+di_ij+1,j+dj_ij}*(px_{ij})*(1-py_{ij}) +
% sum_ij J_ij * I_{i+di_ij,j+dj_ij+1}*(1-px_{ij})*(py_{ij}) +
% sum_ij J_ij * I_{i+di_ij+1,j+dj_ij+1}*(px_{ij})*(py_{ij})
% how would I do this?
% sum_{ij \in (i+di_ij, j+dj_ij)} J_{i-di_ij,j-dj_ij} I_{i,j}*(1-px_{i-di_ij,j-dj_ij})*(1-py_{i-di_ij,j-dj_ij})
% + sum_{ij \in (i+di_ij+1, j+dj_ij)} J_{i-di_ij+1,j-dj_ij} I_{i,j}*(1-px_{i-di_ij+1,j-dj_ij})*(1-py_{i-di_ij-1,j-dj_ij})
% + sum_{ij \in (i+di_ij, j+dj_ij+1)} J_{i-di_ij,j-dj_ij-1} I_{i,j}*(1-px_{i-di_ij,j-dj_ij-1})*(1-py_{i-di_ij,j-dj_ij-1})
% + sum_{ij \in (i+di_ij+1, j+dj_ij+1)} J_{i-di_ij-1,j-dj_ij-1} I_{i,j}*(1-px_{i-di_ij-1,j-dj_ij-1})*(1-py_{i-di_ij-1,j-dj_ij-1})
% okay this says to do the following
% calculate the ps
% resample J, four times
% resample the ps, four times
% sum over these four