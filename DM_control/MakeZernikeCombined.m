function shape = MakeZernikeCombined(aber_sizes, coefs, ns, ms, DM_size, offsets)

% Returns a DM shape of size DM_size corresponding to a Zernike polynomial.
% Removes corners.
% Inputs:
% aber_size: 1xk, diameters of aberrations for all k Zernike modes being
% set
% coefs: 1xk matrix, coefficients for all k Zernike modes being set
% ns: 1xk matrix, radial degree for all k Zernike modes being set
% ms: 1xk matrix, azimuthal degrees for all k Zernike modes being set
% DM_size: integer, size of deformable mirror
% offsets: kx2 matrix, [x,y] offsets for all k Zernike modes being set
% relative to center
%
% Outputs:
% shape: 1D array of actuator values readable by DM representing combination
% of Zernike modes superposed on deformable mirror grid

% Combine Zernike modes
map_mat = zeros(DM_size, DM_size);
for i = 1:numel(coefs)
    map_mat = map_mat + coefs(i) * zernike_DM(aber_sizes(i), ns(i), ms(i), DM_size, offsets(i,:));
end

% Convert to DM readable format with corners removed
map_mat_T = map_mat';
shape = map_mat_T(:);
remove = [1, DM_size, DM_size^2 - DM_size + 1, DM_size^2];
shape(remove) = [];

% Add to flat
fID = fopen('..\DM_shapes\DM_flat.txt', 'r');
flat_shape = fscanf(fID, '%f');
shape = shape + flat_shape;
end
