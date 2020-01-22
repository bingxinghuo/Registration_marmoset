function out_mat = cor_sag_rot(in_mat)

out_mat = zeros([size(in_mat,1), size(in_mat,3), size(in_mat,2)]);
for i = 1:size(in_mat,2)
    out_mat(:,:,i) = in_mat(:,i,:);
end

end