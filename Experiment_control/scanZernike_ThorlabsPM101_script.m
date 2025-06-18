zernike_mode = [3, 3];
DC = false;
center = [21.615, 6.0635, 0];
span = [0.008, 0.008, 0.3];
sampling = [11 11, 7];
focus = 20.065;
Zaber_params.default = true;
PM101_params.default = true;
[position_max, power_max, axis1_range, axis3_range, Zernike_range, power_3D] ...
    = scanZernike_ThorlabsPM101(zernike_mode, DC, center, span, sampling, ...
    focus, Zaber_params, PM101_params)