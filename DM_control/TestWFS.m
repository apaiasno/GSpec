DM_size = 12;
coefs_WFS = [0.07, -0.08, 0.03]/3.5;
ns = [1, 1, 2];
ms = [-1, 1, 0];
aber_sizes = 12 * ones(size(coefs_WFS));
offsets = zeros(numel(coefs_WFS), 2);
DM_shape = MakeZernikeCombined(aber_sizes, coefs_WFS, ns, ms, 12, offsets);
SetShape(DM_shape, 0);
