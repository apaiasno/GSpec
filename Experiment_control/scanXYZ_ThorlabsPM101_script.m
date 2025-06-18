%%% Notes %%%
notes = 'MMF; right aperture illuminated; mask rotated counterclockwise (2)';

%%% Set up scan %%%
center = [11.6300    8.7832   16.7846]; % MMF
span = [0.1, 0.05, 0.1];
% center = [10.8884   23.4650   17.9000]; % MMF
% span = [0.1, 0.03, 0.1];
sampling = [11, 1, 11];
Zaber_params.default = true;
PM101_params.default = true;

%%% Set up DM %%%
dm = DM();
% flat = zeros(12, 12);
% flat(:,1:6) = -635/4;
% flat(:,7:12) = 635/4;
% zernike_corr = [[3 -38.6916]; [4 45.2276]; [5 62.0353]; [6 -2.0861]; ...
%     [7 -63.9907]; [8 46.6995]; [9 13.0991]; [10 0.4272]; [11 -3.2932]; ...    
%     [12 -35.2179]; [13 -4.0505]; [14 6.9865]];
% load('DM_control/surface_nulling_20240510.mat');
% zernike_corr = [[0 0]];
% dm.setZernike(zernike_corr(:,1), zernike_corr(:,2), flat)

%%% Run scan %%%
[position_max, power_max, axis1_range, axis2_range, axis3_range, power_3D] = ...
    scanXYZ_ThorlabsPM101(center, span, sampling, Zaber_params, PM101_params, notes);
power_max