%% Set up path
if ispc
    addpath('C:\Program Files\Boston Micromachines\Bin64\Matlab')
else
    addpath(fullfile('/opt','Boston Micromachines','lib','Matlab'))
end

% ATTENTION: change this string to match the serial number of your hardware
serialNumber = 'MultiUSB000';

%% Show library version
disp(BMCVersionString);

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
% BMCSetCalibrationsPath(dm, profileDir);

%% Open the driver and retrieve DM info struct

[err_code, dm] = BMCOpenDM(serialNumber, dm);

%% Show library functions window

% libfunctionsview libbmc

%% retrieve the default mapping in the variable lut

[err_code, lut] = BMCGetDefaultMapping(dm);

%% Send some random data

data = rand(1,dm.size);
err_code = BMCSendData(dm, data);

%% Get the description of err_code 

disp(BMCGetErrorString(err_code))

%% Send data with a custom mapping
% in this case the mapping LUT is sequential mapping. ie. 1,2,3,4...

lut = 1:dm.size;
BMCSendDataCustomMapping(dm, data, lut);

%% Get the last sent data array
data2 = BMCGetActuatorData(dm);

% Test. Retreived data is rounded to increments of 2e-16.
diff = abs(data2-data);
if any(diff > .01)
    error('Data does not match data sent!');
end

%% Clean up: Close the driver
BMCCloseDM(dm);
