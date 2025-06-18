function [img1, img2] = conjugatePairImages(offset)
% Generates conjugate pair images for a given offset.
% Inputs:
% offset: float, float between 0 and 0.5, represents value added to actuator 
% in its flat state
% 
% Outputs:
% DM_basis: matrix, basis images for each actuator

img1 = load('conjugatePairs/Actuator_1_offset'+string(offset)+'_pos.mat');
img1 = img1.img;
pixels = numel(img1);
DM_basis = NaN(pixels, 140);
for i = 1:140
    img1 = load('conjugatePairs/Actuator_'+string(i)+'_offset'+string(offset)+'_pos.mat');
    img1 = img1.img;
    img1 = img1.';
    img1 = img1(:);
    DM_basis(:, i) = img1;
end
    