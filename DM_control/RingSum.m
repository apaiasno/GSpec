function [metric, com_x, com_y] = RingSum(image, rad_in, rad_out, cenxy)
% Computes (first) ring sum metric from image data for Eye Doctor Zernike
% optimization routine.
% Inputs:
% image: 2D image array of image intensity values
% rad_in: integer, inner radius of "ring" in pixels
% rad_out: integer, outer radius of "ring" in pixels
% cenxy: 1x2 array or NaN, (x,y) coordinates of initial guess for centroid
%
% Outputs:
% metric: integer, value representing ring sum (negated for minimization)

[rows, cols] = size(image);

% Subtract background from image
edge_mask = zeros(size(image));
edge_mask(1:5,:) = 1;
edge_mask(end-4:end,:) = 1;
edge_mask(:, 1:5) = 1;
edge_mask(:, end-4:end) = 1;
image_bgsub = image - median(image(edge_mask == 1), 'all');

% Impose mask of 2*radius and refine centroid
radius2 = 2*rad_in;
if isnan(cenxy)
    [~, idx] = max(image_bgsub, [], 'all');
    [ceny, cenx] = ind2sub(size(image_bgsub),idx);
else
    cenx = cenxy(1);
    ceny = cenxy(2);
end
centroid_mask = zeros(size(image_bgsub));
x = 1:cols;
y = 1:rows;
[xx, yy] = meshgrid(x, y);
xx_cen = xx - cenx;
yy_cen = yy - ceny;
centroid_mask(xx_cen.^2 + yy_cen.^2 <= radius2^2) = 1;
image_cen = image .* centroid_mask;
% Compute center of mass
mean_image = mean(image_cen(:));
com_x = mean(image_cen(:) .* xx(:)) / mean_image;
com_y = mean(image_cen(:) .* yy(:)) / mean_image;

% Impose core mask and compute sum in core
core_mask = ones(size(image_bgsub));
xx_com = xx - com_x;
yy_com = yy - com_y;
core_mask(xx_com.^2 + yy_com.^2 <= rad_in^2) = 0;
core_mask(xx_com.^2 + yy_com.^2 >= rad_out^2) = 0;
image_com = image(core_mask == 1);
metric = -sum(image_com(:));
end






