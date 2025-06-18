function image = TakeCoreImage(t_exp, core_rad, cenxy)
% Takes an image and plots the core of the Airy disk.
% Inputs:
% t_exp: float, exposure time in ms
% core_rad: integer, radius of "core" in pixels
% cenxy: 1x2 array or NaN, (x,y) coordinates of initial guess for centroid
%
% Outputs:
% image: 2D array of image intensity values

% Take image
image = CamAcquisition(t_exp);
image_doub = double(image);

% Subtract background for centroid estimation
[rows, cols] = size(image_doub);

% Subtract background from image
edge_mask = zeros(size(image_doub));
edge_mask(1:5,:) = 1;
edge_mask(end-4:end,:) = 1;
edge_mask(:, 1:5) = 1;
edge_mask(:, end-4:end) = 1;
image_bgsub = image_doub - median(image_doub(edge_mask == 1), 'all');

% Impose mask of 2*radius and refine centroid
radius2 = 2*core_rad;
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

imshow(image)
colorbar
% set(gca,'ColorScale','log')
%         set(cbr,'YTick', {10, 100, 255})

hold on
theta = 0 : (2 * pi / 10000) : (2 * pi);
pline_x = core_rad * cos(theta) + cenx;
pline_y = core_rad * sin(theta) + ceny;
k = ishold;
plot(pline_x, pline_y, 'r-', 'LineWidth', 1);
xlim([cenx-5*core_rad, cenx+5*core_rad]);
ylim([ceny-5*core_rad, ceny+5*core_rad]);
pbaspect([1, 1, 1])
title('Optimized intensity map', 'Units', 'normalized', ...
    'Position', [0.5, 1.1])     
drawnow

end
