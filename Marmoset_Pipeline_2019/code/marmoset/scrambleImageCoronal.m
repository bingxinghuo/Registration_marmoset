function [outimg,a_save,b_save,theta_save] = scrambleImageCoronal(avw)
addpath /cis/home/dtward/Functions/interp 
nx = double(avw.hdr.dime.dim([3,2,4]));
dx = double(avw.hdr.dime.pixdim([3,2,4]));

x = (0:nx(1)-1)*dx(1);
y = (0:nx(2)-1)*dx(2);
z = (0:nx(3)-1)*dx(3);
x = x - mean(x);
y = y - mean(y);
z = z - mean(z);

[XX,YY] = meshgrid(z,y); % often we do not use z

TI = zeros(size(avw.img));
myrand_theta = randn(1,nx(1));
myrand_a = randn(1,nx(1));
myrand_b = randn(1,nx(1));
a_save = zeros(1,nx(1));
b_save = zeros(1,nx(1));
theta_save = zeros(1,nx(1));
for i = 1 : nx(1)
    theta = 5*pi/180*(myrand_theta(i));
    a = dx(1)*4*(myrand_a(i));
    b = dx(3)*4*(myrand_b(i));
    A = [cos(theta), -sin(theta), 0, a;
        sin(theta), cos(theta), 0,  b;
        0 0 1 0;
        0 0 0 1];
    TX = A(1,1)*XX + A(1,2)*YY + A(1,4);
    TY = A(2,1)*XX + A(2,2)*YY + A(2,4);
    TI(:,i,:) = linearInterpolate2D(XX,YY,squeeze(avw.img(:,i,:)),TX,TY,'linear','edge');
    a_save(i) = a;
    b_save(i) = b;
    theta_save(i) = theta;
end
outimg = avw;
outimg.img = TI;
