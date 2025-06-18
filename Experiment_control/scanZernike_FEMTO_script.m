notes = 'Nulling Zernike optimization for Z = 14 (vertical quadrafoil)';
zernike_mode = 14;
zernike_corr = [[3 -17.1288], [4 -14.3076], [5 2.3053], [6 4.8095], [7 -7.2114], ...
    [8 -0.61896], [9 5.6363], [10 -3.0764], [11 6.5268], [12 6.1694], [13 -11.2166],
    [14 -4.0348]];
% mask = zernike_corr(:, 1) == zernike_mode;
% zernike_row = zernike_corr(mask,:);
% amp_center = zernike_row(2);
% zernike_corr = zernike_corr(~mask, :);
flat = zeros(12, 12);
% flat(:,1:6) = -635/4;
% flat(:,7:12) = 635/4;
% flat = load('DM_control\surface_nulling_20240530.mat');
center = [12.6139        6.848       0];
span = [0.005, 0.005, 200];
sampling = [21 21 11];
focus =  17.725 ;

Zaber_params.default = true;
PM101_params.default = true;
[amp_opt, position_max, power_max, axis1_range, axis3_range, Zernike_range, power_3D] ...
    = scanZernike_FEMTO(zernike_mode, zernike_corr, center, span, sampling, ...
    focus, flat, Zaber_params, notes);