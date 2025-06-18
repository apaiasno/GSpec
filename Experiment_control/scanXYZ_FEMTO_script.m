% TO DO: iterate between 1) translate lens down and 2) rotate lens
% clockwise

%%% Notes %%%
notes = 'SMF; original mask, DM zeroed.';

%%% Set up scan %%%
% center = [12.3993        6.655      6.24257]; % SMF
center = [12.612       17.733       6.8485];
% center = [6.93767       8.8934      16.5134]; % MMF
% span = [0.01, 0.02, 0.01]; % SMF
% sampling = [15 1 15];
span = [0.01, 0.02, 0.01]; % SMF
sampling = [81 1 81];
% sampling = [101 1 21];
Zaber_params.default = true;

%%% Set up DM %%%
dm = DM();
dm.setFlat();
flat = zeros(12, 12);
flat(:,1:6) = -635/4;
flat(:,7:12) = 635/4;
% zernike_corr = [[3 0]];
zernike_corr = [[3 -17.1288], [4 -14.3076], [5 2.3053], [6 4.8095], [7 -7.2114], ...
    [8 -0.61896], [9 5.6363], [10 -3.0764], [11 6.5268], [12 6.1694], [13 -11.2166], ...
    [14 -4.0348]];
% % load('DM_control/surface_nulling_20240530.mat');
dm.setZernike(zernike_corr(:,1), zernike_corr(:,2), flat)

%%% Run scan %%%
[position_max, power_max, axis1_range, axis2_range, axis3_range, power_3D] = ...
    scanXYZ_FEMTO(center, span, sampling, Zaber_params, notes);
power_max