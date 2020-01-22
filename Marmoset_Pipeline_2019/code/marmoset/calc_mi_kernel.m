function [mi,grad] = calc_mi_kernel(I,J,bins,sigma,W)
% return mutual information and gradient with respect to I
% note I usually will want to minimize the negative of this
% 
% TO DO
% include weights
% double check sign on gradient
% 
% keyboard
% do a version with a kernel
% in kernel version
% we input a width of a gaussian kernel sigma
if nargin == 4
    W = ones(size(I))/numel(I);
end
Ivec = I(:);
Jvec = J(:);
Wvec = W(:);
nb = length(bins);

% the weight should sum to 1

% work out the joint and marginal densities
p_i = zeros(1,nb);
p_j = zeros(1,nb);
p_ij = zeros(nb,nb);
for i_ = 1 : nb
    p_i(i_) = sum( exp(  -(bins(i_) - Ivec).^2/2/sigma^2 )/(sqrt(2*pi*sigma^2)).*Wvec);
    p_j(i_) = sum( exp(  -(bins(i_) - Jvec).^2/2/sigma^2 )/(sqrt(2*pi*sigma^2)).*Wvec);
    for j_ = 1 : nb
        p_ij(i_,j_) = sum( exp( -(bins(i_) - Ivec).^2/2/sigma^2 )/(sqrt(2*pi*sigma^2)) .* exp( -(bins(j_) - Jvec).^2/2/sigma^2 )/(sqrt(2*pi*sigma^2)).*Wvec );
    end
end
tosum = p_ij.*log(p_ij./(p_i'*p_j));
mi = sum(tosum(~isnan(tosum)));

% gradient
if nargout > 1
grad = zeros(numel(I),1);
for i_ = 1 : nb
    for j_ = 1 : nb
        dp_ij = (bins(i_) - Ivec)/sigma^2 .* exp( -(bins(i_) - Ivec).^2/2/sigma^2 )/(sqrt(2*pi*sigma^2)) .* exp( -(bins(j_) - Jvec).^2/2/sigma^2 )/(sqrt(2*pi*sigma^2)) *(bins(2)-bins(1))^2;
        tmp = dp_ij*log(p_ij(i_,j_)/p_i(i_));
        tmp(isnan(tmp)) = 0;
        tmp(isinf(abs(tmp))) = 0;
%         grad = grad + 1/numel(I)*tmp;
        grad = grad + tmp.*Wvec;
    end
end
grad = reshape(grad,size(I));
end