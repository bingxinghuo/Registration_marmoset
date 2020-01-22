function [a,b,theta] = composeSectionTransforms(directoryname,startiter,enditer)

for i = startiter:enditer
    acur = readSectionTransform([directoryname '/iter' num2str(i) '_a.txt'])';
    bcur = readSectionTransform([directoryname '/iter' num2str(i) '_b.txt'])';
    thetacur = readSectionTransform([directoryname '/iter' num2str(i) '_theta.txt'])';
    if i == startiter
        a = zeros(size(acur));
        b = zeros(size(bcur));
        theta = zeros(size(thetacur));
    end
    a = a + acur;
    b = b + bcur;
    theta = theta + thetacur;
end

end
