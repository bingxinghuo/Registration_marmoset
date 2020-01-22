function [a,b,theta] = composeSectionTransforms(directoryname,niter)

for i = 1:niter
    acur = readSectionTransform([directoryname '/iter' num2str(i) '_a.txt'])';
    bcur = readSectionTransform([directoryname '/iter' num2str(i) '_b.txt'])';
    thetacur = readSectionTransform([directoryname '/iter' num2str(i) '_theta.txt'])';
    if i == 1
        a = zeros(size(acur));
        b = zeros(size(bcur));
        theta = zeros(size(thetacur));
    end
    a = a + acur;
    b = b + bcur;
    theta = theta + thetacur;
end

end
