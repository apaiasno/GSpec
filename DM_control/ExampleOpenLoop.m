%% This example demonstrates Open Loop surface control of a CDM.

%% Set up path
if ispc
    addpath('C:\Program Files\Boston Micromachines\Bin64\Matlab')
else
    addpath(fullfile('/opt','Boston Micromachines','lib','Matlab'))
end

% ATTENTION: change this string to match the serial number of your hardware
serialNumber = 'MultiUSBOL1';

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

%% Generate high resolution surface map
x = -128:127;
a = -128:127;
surface = a'*(x.*x) / 4096;
surf(surface);

%% Calculate and send commands
[err_code, data, surface_out] = BMCCalculateSurface(dm, surface);
%disp(surface_out)
surf(surface_out)
if (err_code)
    error(BMCGetErrorString(err_code));
end
err_code = BMCSendData(dm, data);
if (err_code)
    error(BMCGetErrorString(err_code));
end
pause(0.5)

%% Generate out-of-range surface map
surface = surface * 8;
[err_code, data, surface_out] = BMCCalculateSurface(dm, surface);
if (isequal(err_code, BMCRC.ERR_OUT_OF_LUT_RANGE))
    disp('Surface shape out of range, as expected, setting clipped shape.');
    [err_code, data, surface_out] = BMCCalculateSurface(dm, surface, 0, DMSurfaceOptions.DM_SURFACE_BEST_EFFORT);
    if (err_code)
        error(BMCGetErrorString(err_code));
    end
else
    error(BMCGetErrorString(err_code));
end

surf(surface_out)
err_code = BMCSendData(dm, data);
if (err_code)
    error(BMCGetErrorString(err_code));
end
pause(0.5)

disp('Open Loop Surface test complete.')

%% Get the last sent data array
data = BMCGetActuatorData(dm);

%% Clean up: Close the driver
BMCCloseDM(dm);
