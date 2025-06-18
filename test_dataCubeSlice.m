% Read in data
data_dir = string(pwd) + '\logs\20240514\';
scan = 'scan47_*.csv';
filename = dir(data_dir + scan);
filename = data_dir + filename.name;
T = readtable(filename);
foci = unique(T.(2));
maps = [];
x_arr = sort(unique(T.(1)));
y_arr = sort(unique(T.(3)));

% Extract data for each amplitude and store
for i = 1:numel(foci)
    t = T(T.(2) == foci(i), :);
    X = t.(1);
    Y = t.(3);
    Z = t.(4);
    
    [Xi,Yi] = meshgrid(x_arr,y_arr);
    Zi = griddata(X,Y,Z,Xi,Yi);
    maps = cat(3, maps, Zi); 
end    

% Mask regions to identify fringe maxima and null
maps_size = size(maps);

mask_fringe1 = NaN(maps_size);
mask_fringe1(:, 1:ceil(maps_size(2)/2), :) = maps(:, 1:ceil(maps_size(2)/2), :);
[fringe1_max, ind1_max] = max(mask_fringe1(:));
[ind1_max_1, ind1_max_2, ind1_max_3] = ind2sub(size(maps), ind1_max);
p_1 = [x_arr(ind1_max_2) y_arr(ind1_max_1) foci(ind1_max_3)];

mask_fringe2 = NaN(maps_size);
mask_fringe2(:, ceil(maps_size(2)/2):end, :) = maps(:, ceil(maps_size(2)/2):end, :);
[fringe2_max, ind2_max] = max(mask_fringe2(:));
[ind2_max_1, ind2_max_2, ind2_max_3] = ind2sub(size(maps), ind2_max);
p_2 = [x_arr(ind2_max_2) y_arr(ind2_max_1) foci(ind2_max_3)];

mask_null = NaN(maps_size);
center_low = ceil(maps_size(2)/2) - 3;
center_up = ceil(maps_size(2)/2) + 3;
mask_null(center_low:center_up, center_low:center_up, :) = maps(center_low:center_up, center_low:center_up, :);
[fringeNull_min, indNull_min] = min(mask_null(:));
[indNull_min_1, indNull_min_2, indNull_min_3] = ind2sub(size(maps), indNull_min);
p_null = [x_arr(indNull_min_2) y_arr(indNull_min_1) foci(indNull_min_3)];

% figure;
% imagesc(x, y, mask_fringe1(:,:, ind1_max_3));
% hold on
% plot(position1_max(1), position1_max(2),'r*')
% 
% figure;
% imagesc(x, y, mask_fringe2(:,:, ind2_max_3));
% hold on
% plot(position2_max(1), position2_max(2),'r*')
% 
% figure;
% imagesc(x, y, mask_null(:,:, indNull_min_3));
% hold on
% plot(positionNull_min(1), positionNull_min(2),'r*')

% Equation for plane intersecting the 3 points
normal = cross(p_1-p_2, p_1-p_null);
syms x y z
P = [x,y,z];
planefunction = dot(normal, P-p_1);
zplane = solve(planefunction, z);

% Slicing???
[x, y] = meshgrid(x_arr, y_arr);
z_plane = double(subs(zplane));
x_plane = x; y_plane = y;
[x_mesh,y_mesh,z_mesh] = meshgrid(x_arr, y_arr, foci);
map_slice = interp3(x_mesh,y_mesh,z_mesh,maps,x_plane,y_plane,double(z_plane));

% Plot???
imAlpha=ones(size(map_slice));
imAlpha(isnan(map_slice)) = 0;
imagesc(map_slice,'AlphaData',imAlpha);
set(gca,'color',0*[1 1 1]);







