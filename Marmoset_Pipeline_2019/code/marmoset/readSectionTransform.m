function [transform] = readSectionTransform(filename)

fid = fopen(filename);
transform = fscanf(fid,'%f\n');

end
