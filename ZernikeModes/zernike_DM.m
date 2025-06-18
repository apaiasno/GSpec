function map_mat = zernike_DM(aber_size, n, m, DM_size, offset)

% Returns a matrix of size DM_size corresponding to a Zernike polynomial.
% Inputs:
% aber_size: integer, diameter of aberration
% n: integer, radial degree
% m: integer, azimuthal degree m
% DM_size: integer, size of deformable mirror
% offset: 1x2 matrix, [x,y] offset of abberation relative to center
%
% Outputs:
% map_mat: DM_size x DM_size matrix, Zernike polynomial representing
% aberration superposed on deformable mirror grid
if aber_size > DM_size
    error('ValueError: Aberration size must be less than size of deformable mirror.')
else
    % Generate aberration
    x = linspace(-1, 1, aber_size);
    y = linspace(-1, 1, aber_size);
    [x, y] = meshgrid(x, y);
    [t, r] = cart2pol(x, y);
    zern_mat = zernike(r, t, n, m);
    % Rescale map to range between 0 and 1
    if n+m ~= 0
        zern_mat_max = max(zern_mat, [], 'all');
        zern_mat_min = min(zern_mat, [], 'all');
        zern_mat_scaled = (zern_mat - zern_mat_min)/(zern_mat_max - zern_mat_min);
    else
        zern_mat_scaled = zern_mat;
    end
    % Superpose map on grid of deformable mirror size
    map_mat = zeros(DM_size);
    i_start = round(DM_size/2) - floor(aber_size/2);
    if (mod(DM_size,2) == 0) && (mod(aber_size,2) == 0)
        i_start = i_start + 1;
    end
    x_start = i_start + offset(1);
    x_end = x_start + aber_size - 1;
    y_start = i_start + offset(2);
    y_end = y_start + aber_size - 1;
    if (x_end > DM_size) || (x_start < 1)
        error('ValueError: x-offset is out of bounds.')
    elseif (y_end > DM_size) || (y_start < 1)
        error('ValueError: y-offset is out of bounds.')
    end
    map_mat(x_start:x_end, y_start:y_end) = zern_mat_scaled;
    % Fill in remainder of map with edge values of aberration
    for i = 1:y_start
        map_mat(x_start:x_end, i) = map_mat(x_start:x_end, y_start);
    end
    for i = y_end:DM_size
        map_mat(x_start:x_end, i) = map_mat(x_start:x_end, y_end);
    end
    for i = 1:x_start
        map_mat(i, y_start:y_end) = map_mat(x_start, y_start:y_end);
    end
    for i = x_end:DM_size
        map_mat(i, y_start:y_end) = map_mat(x_end, y_start:y_end);
    end
    map_mat(1:x_start, 1:y_start) = map_mat(x_start, y_start);
    map_mat(1:x_start, y_end:end) = map_mat(x_start, y_end);
    map_mat(x_end:end, 1:y_start) = map_mat(x_end, y_start);
    map_mat(x_end:end, y_end:end) = map_mat(x_end, y_end);    
end

