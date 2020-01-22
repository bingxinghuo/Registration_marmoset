function outimg = applySectionTransformsCoronal(I,a,b,theta, interpmode)
outimg = I;
nx = double(I.hdr.dime.dim([2,3,4]));
dx = double(I.hdr.dime.pixdim([2,3,4]));

x = (0:nx(1)-1)*dx(1);
y = (0:nx(3)-1)*dx(3);
x = x - mean(x);
y = y - mean(y);

[XX,YY] = meshgrid(y,x); % often we do not use z

for i = 1 : nx(2)
    A = [cos(theta(i)), -sin(theta(i)), 0, a(i);
        sin(theta(i)), cos(theta(i)), 0,  b(i);
        0 0 1 0;
        0 0 0 1];
    TX = A(1,1)*XX + A(1,2)*YY + A(1,4);
    TY = A(2,1)*XX + A(2,2)*YY + A(2,4);
    outimg.img(:,i,:) =  linearInterpolate2D(XX,YY,squeeze(I.img(:,i,:)),TX,TY,interpmode,'edge');
    %outimg.img(:,i,:) =  interp2(XX,YY,squeeze(I.img(:,i,:)),TX,TY);
end
    
end