% TO DO: iterate between 1) translate lens down and 2) rotate lens
% clockwise

%%% Notes %%%
notes = 'SMF; measure null?';

%%% Set up scan %%%
center = [12.6149       6.8485   1.08]; % SMF
span = [0.01, 0.01, 0.1]; % SMF
sampling = [151 151 1];
focus = 17.715; 
wavelength = 635;
Zaber_params.default = true;

%%% Set up DM %%%
dm = DM();
zernike_corr = [[3 0]];

%%% Run scan %%%
[axis1_range, axis3_range, offset_range, power_3D] = ...
    scanPhaseOffset_FEMTO(wavelength, zernike_corr, center, span, sampling, ...
    focus, Zaber_params, notes);