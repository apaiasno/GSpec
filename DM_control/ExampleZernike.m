%% This example demonstrates Open Loop Zernike control of a CDM.

%% Set up path
if ispc
    addpath('C:\Program Files\Boston Micromachines\Bin64\Matlab')
else
    addpath(fullfile('/opt','Boston Micromachines','lib','Matlab'))
end

% ATTENTION: change this string to match the serial number of your hardware
serialNumber = 'MultiUSB000';

%% Configure SDK
BMCConfigureLog(fullfile(cd, 'dmsdk-ol-example.log'), 'BMC_LOG_DEBUG');

[err_code, dm] = BMCGetDM();
if ispc
    profileDir = 'C:\Program Files\Boston Micromachines\Profiles';
else
    profileDir = fullfile('/opt','Boston Micromachines','Profiles');
end
% profileDir = fullfile(cd, '..', 'Matlab');
BMCSetProfilesPath(dm, profileDir);
% BMCSetMapsPath(dm, profileDir);
% Optional because we load the file later
calibrationDir = fullfile(profileDir, '..', 'Calibration')
% BMCSetCalibrationsPath(dm, calibrationDir);

%% Open the driver and retrieve DM info struct

[err_code, dm] = BMCOpenDM(serialNumber, dm);

%% Load the calibration table

err_code = BMCLoadCalibrationFile(dm, fullfile(calibrationDir, 'Sample_Multi_OLC1_CAL.mat'));

%% Get piston range

% Get full piston range with no tilt
[err_code, minPiston, maxPiston] = BMCGetSegmentPistonRange(dm, 0, 0, 0, 1);
disp(BMCGetErrorString(err_code));

Zernike_coefficients = [ 0, 0, 0, 0, 0, 0 ]
w = dm.width

%% Add 200nm RMS of defocus
% NOTE: MATLAB index starts at 1, so add 1 to the OSA Zernike index
Zernike_coefficients(5) = 200;
[err_code, surface] = BMCZernikeSurface(dm, Zernike_coefficients, 0, 0);
%disp(surface)
surf(surface)
if (err_code)
    error(BMCGetErrorString(err_code));
end
err_code = BMCSetSurface(dm, surface);
if (err_code)
    error(BMCGetErrorString(err_code));
end
pause(0.5)

%% Add 100nm RMS of astigmatism
Zernike_coefficients(4) = 100;
[err_code, surface] = BMCZernikeSurface(dm, Zernike_coefficients, 0, 0);
surf(surface)
if (err_code)
    error(BMCGetErrorString(err_code));
end
err_code = BMCSetSurface(dm, surface);
if (err_code)
    error(BMCGetErrorString(err_code));
end
pause(0.5)

%% Add 50nm RMS of tilt
Zernike_coefficients(3) = 50;
[err_code, surface] = BMCZernikeSurface(dm, Zernike_coefficients, 0, 0);
surf(surface)
if (err_code)
    error(BMCGetErrorString(err_code));
end
err_code = BMCSetSurface(dm, surface);
if (err_code)
    error(BMCGetErrorString(err_code));
end
pause(0.5)

%% Add 1000nm RMS of astigmatism - out of calibrated range
Zernike_coefficients(6) = 1000;
[err_code, surface] = BMCZernikeSurface(dm, Zernike_coefficients, 0, 0);
surf(surface)
if (err_code)
    error(BMCGetErrorString(err_code));
end
err_code = BMCSetSurface(dm, surface);
if (isequal(err_code, BMCRC.ERR_OUT_OF_LUT_RANGE))
    disp('Zernike shape out of range, as expected, setting clipped shape.');
    err_code = BMCSetSurface(dm, surface, 0, DMSurfaceOptions.DM_SURFACE_BEST_EFFORT);
    if (err_code)
        error(BMCGetErrorString(err_code));
    end
else
    error(BMCGetErrorString(err_code));
end
pause(0.5)

disp('Zernike test complete.')

%% Get the last sent data array
data = BMCGetActuatorData(dm);

%% Clean up: Close the driver
BMCCloseDM(dm);
