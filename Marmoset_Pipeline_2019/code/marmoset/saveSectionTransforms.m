function saveSectionTransforms(a,b,theta, outputdirectoryname, outputprefix)

fid = fopen([outputdirectoryname '/' outputprefix '_a.txt'],'w');
for i = 1:length(a)
    fprintf(fid,'%f\n',a(i));
end
fclose(fid);

fid = fopen([outputdirectoryname '/' outputprefix '_b.txt'],'w');
for i = 1:length(a)
    fprintf(fid,'%f\n',b(i));
end
fclose(fid);

fid = fopen([outputdirectoryname '/' outputprefix '_theta.txt'],'w');
for i = 1:length(a)
    fprintf(fid,'%f\n',theta(i));
end
fclose(fid);