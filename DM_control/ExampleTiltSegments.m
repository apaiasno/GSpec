%% Set up path
if ispc
    addpath('C:\Program Files\Boston Micromachines\Bin64\Matlab')
else
    addpath(fullfile('/opt','Boston Micromachines','lib','Matlab'))
end

% ATTENTION: change this string to match the serial number of your hardware
serialNumber = 'HexW111#000';

%% Configure SDK
BMCConfigureLog(fullfile(cd, 'dmsdk-example.log'), 'BMC_LOG_DEBUG');

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

err_code = BMCLoadCalibrationFile(dm, fullfile(calibrationDir, 'Sample_Lookup_Table.mat'));

%% Get piston and tilt ranges

% Get full piston range with no tilt
[err_code, minPiston, maxPiston] = BMCGetSegmentPistonRange(dm, 0, 0, 0, 1);
disp(BMCGetErrorString(err_code))

% Get X-Tilt range for minimum piston
[err_code, minXTilt, maxXTilt] = BMCGetSegmentXTiltRange(dm, 0, minPiston, 0, 1);
disp(BMCGetErrorString(err_code))

% Get Y-Tilt range for minimum piston
[err_code, minYTilt, maxYTilt] = BMCGetSegmentYTiltRange(dm, 0, minPiston, 0, 1);
disp(BMCGetErrorString(err_code))

%% Piston or tilt one segment at a time
pistonValue = (maxPiston + minPiston)/2;
tiltValue = -1.0e-6;
numSegments = dm.size/3;

for k = 0:numSegments-1
    fprintf('Piston segment %d of %d %fnm.\r', k, numSegments, pistonValue)
    BMCSetSegment(dm, k, pistonValue, 0, 0, 1, 1);
    fprintf('Tilt segment %d of %d %fr.\r', k, numSegments, tiltValue)
    BMCSetSegment(dm, k, pistonValue, tiltValue, 0, 1, 1);
    BMCSetSegment(dm, k, pistonValue, tiltValue, tiltValue, 1, 1);
    BMCSetSegment(dm, k, pistonValue, 0, tiltValue, 1, 1);
end

%% Try to piston out of calibrated range
pistonValue = minPiston - 1;
segment_no = 5;
err_code = BMCSetSegment(dm, segment_no, pistonValue, 0, 0, 1, 1);
if (isequal(err_code, BMCRC.ERR_OUT_OF_LUT_RANGE))
    [~, minPiston, maxPiston] = BMCGetSegmentPistonRange(dm, segment_no, 0, 0, 1);
    fprintf('Piston %d out of range: [%d, %d]\n', pistonValue, minPiston, maxPiston);
else
    error(BMCGetErrorString(err_code));
end

%% Piston or tilt all segments simultaneously
pistonValue = (maxPiston + minPiston)/2;
tiltValue = -1.0e-6;
numSegments = dm.size/3;
sendNow = 0;

for k = 0:numSegments-1
    fprintf('Piston/tilt segment %d of %d %fnm %fr.\r', k, numSegments, pistonValue, tiltValue)
    if (k == numSegments-1)
        sendNow = 1;
    end
    err_code = BMCSetSegment(dm, k, pistonValue, tiltValue, tiltValue, 1, sendNow);
end

disp('Segment test complete.')

%% Get the last sent data array
data = BMCGetActuatorData(dm);

%% Clean up: Close the driver
BMCCloseDM(dm);
