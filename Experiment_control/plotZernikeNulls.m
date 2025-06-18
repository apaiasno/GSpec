% Current null: 0.0083
% Best null: 0.002804
% Read in data
data_dir = string(pwd) + '\logs\20240607\';
scan = 'scan21_*.csv';
null_guess = 10.875;
filename = dir(data_dir + scan);
filename = data_dir + filename.name;
T = readtable(filename);
x = sort(unique(T.(1)));
y = sort(unique(T.(2)));
amps = sort(unique(T.(3)));
maps = [];

% Extract data for each focus and store
for i = 1:numel(amps)
    t = T(T.(3) == amps(i), :);
    X = t.(1);
    Y = t.(2);
    Z = t.(4);
    [Xi,Yi] = meshgrid(x,y);
    Zi = griddata(X,Y,Z,Xi,Yi);
    maps = cat(3, maps, Zi);    
end

% Choose focus point where peaks are most balanced
bool_1 = logical(x > null_guess);
null_min = inf;
ind_max_3 = 1;
y_check = 50;
nulls = [];
for i=1:numel(amps)
%%% Check where peaks are equalized
%     maps_1 = maps(:, bool_1, i); maps_2 = maps(:, ~bool_1, i);
%     max_1 = max(maps_1(:));
%     max_2 = max(maps_2(:));
%     if abs(max_1-max_2) < peak_diff
%         peak_diff = abs(max_1-max_2);
%         ind_max_3 = i;  
%     end
%%% Check for deepest null 

    % Extract 1-D profile and null depth
    map = maps(:, :, i);
    peak = max(map(:));
    [power_max, ind_max] = max(map(:));
    [ind_max_1, ind_max_2] = ind2sub(size(map), ind_max);
    profile = maps(ind_max_1, :, i);
    profile_1 = profile; profile_2 = profile; profile_null = NaN(numel(y), numel(x));
    profile_1(bool_1) = NaN;
    profile_2(~bool_1) = NaN;
    [~, ind_peak1] = max(profile_1);
    [~, ind_peak2] = max(profile_2);
    
    y_num = numel(y);
    y_ind_low = ind_max_1 - floor(y_num/y_check); y_ind_up = ind_max_1 + floor(y_num/y_check);
    
    null_range = zeros(numel(y), numel(x));
    null_range(y_ind_low:y_ind_up, ind_peak1:ind_peak2) = 1;
    null_range = logical(null_range);
    profile_null(null_range) = map(null_range);
    [null, ind_null] = min(profile_null(:));
    [ind_null_row, ind_null_col] = ind2sub(size(map), ind_null);
    profile = map(ind_null_row, :);
    peak = max(profile);
    null_depth = null/peak;
    if null_depth < null_min
        null_min = null_depth;
        ind_max_3 = i;
    end
    nulls = [null_depth; nulls];
end
% ind_max_3 = 2;

% Extract 1-D profile and null depth
map = maps(:, :, ind_max_3);
peak = max(map(:));
[power_max, ind_max] = max(map(:));
[ind_max_1, ind_max_2] = ind2sub(size(map), ind_max);
profile = maps(ind_max_1, :, ind_max_3);
profile_1 = profile; profile_2 = profile; profile_null = NaN(numel(y), numel(x));
profile_1(bool_1) = NaN;
profile_2(~bool_1) = NaN;
[~, ind_peak1] = max(profile_1);
[~, ind_peak2] = max(profile_2);

y_num = numel(y);
y_ind_low = ind_max_1 - floor(y_num/y_check); y_ind_up = ind_max_1 + floor(y_num/y_check);

null_range = zeros(numel(y), numel(x));
null_range(y_ind_low:y_ind_up, ind_peak1:ind_peak2) = 1;
null_range = logical(null_range);
profile_null(null_range) = map(null_range);
[null, ind_null] = min(profile_null(:));
[ind_null_row, ind_null_col] = ind2sub(size(map), ind_null);
null_depth = null/peak;
profile = map(ind_null_row, :);
null_depth = null/peak;

% Profile along y direction at outskirts of map
figure;
y_outskirts = maps(:, 1, ind_max_3);
plot(y, y_outskirts, 'color', 'blue');
hold on
y_outskirts = maps(:, end, ind_max_3);
plot(y, y_outskirts, 'color', 'red');
xline(y(ind_null_row), 'color', 'green');
xlim([min(y), max(y)]);
xlabel("y (mm)");
ylabel("Power (arbitrary units)");
title("Edge profile along y");

% Profile along y direction at x-position of null
figure;
y_profile = maps(:, ind_null_col, ind_max_3);
plot(y, y_profile, 'color', 'black');
hold on
xline(y(ind_null_row), 'color', 'green');
xlim([min(y), max(y)]);
xlabel("y (mm)");
ylabel("Power (arbitrary units)");
title("Null depth: "+string(null/peak));

% 1D throughput profile through null
figure;
plot(x, profile, 'color', 'black');
hold on
xline(x(ind_null_col), 'color', 'green');
xline(x(ind_peak1), 'color', 'red');
xline(x(ind_peak2), 'color', 'red');
xlabel("x (mm)");
ylabel("Power (arbitrary units)");
title("Null depth: "+string(null/peak));

% 2D map
map = maps(:, :, ind_max_3);
figure;
imagesc(x, y, map);
xline(x(ind_null_col), 'color', 'green');
yline(y(ind_null_row), 'color', 'green');
xlabel('x (mm)');
ylabel('y (mm)');
set(gca, 'YDir','normal');
title("Null depth: "+string(null/peak));
colormap(gray);
colorbar;

% Plot null depth vs. wavefront RMS
figure;
plot(amps, nulls, 'o-');
xlabel('Wavefront RMS (nm)');
ylabel('Null depth');

disp("Deepest null Zernike mode amplitude: "+string(amps(ind_max_3)));


