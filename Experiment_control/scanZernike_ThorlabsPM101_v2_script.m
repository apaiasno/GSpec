notes = 'Nulling Zernike optimization for Z = 8 (horizontal coma)';
zernike_mode = 8;
% zernike_corr = [[3 -38.6916]; [4 45.2276]; [5 62.0353]; [6 -2.0861]; ...
%     [7 -63.9907]; [8 46.6995]; [9 13.0991]; [10 0.4272]; [11 -3.2932]; ...    
%     [12 -35.2179]; [13 -4.0505]; [14 6.9865]];
% zernike_corr = false;
load('DM_control/surface_nulling_20240510.mat');
zernike_corr = [[0 0]];
center = [10.8510   6.1376   -50];
span = [0.01, 0.01, 100];
sampling = [15 15 11];
focus =  23.4600;

Zaber_params.default = true;
PM101_params.default = true;
[amp_opt, position_max, power_max, axis1_range, axis3_range, Zernike_range, power_3D] ...
    = scanZernike_ThorlabsPM101_v2(zernike_mode, zernike_corr, center, span, sampling, ...
    focus, surface_nulling, Zaber_params, PM101_params, notes)