function SetAllFixed(value)
% Sets all DM actuators to a fixed value
% Inputs:
% value: float between 0 and 1, represents value to which actuators will be
% set
%
% Outputs:
% N/A
if (value < 0) || (value > 1)
    error("ValueError: input must be between 0 and 1.")
end

%% Set up path
if ispc
    addpath('C:\Program Files\Boston Micromachines\Bin64\Matlab')
else
    addpath(fullfile('/opt','Boston Micromachines','lib','Matlab'))
end

% ATTENTION: change this string to match the serial number of your hardware
serialNumber = 'MultiUSB000';

%% Open the connection to the driver
[err_code, dm] = BMCOpenDM(serialNumber);
if err_code
    error(BMCGetErrorString(err_code))
end

disp('DM size: '+string(dm.size));

%% Poke one actuator at a time
data = ones(1,dm.size) * value;
BMCSendData(dm, data);

disp('Setting all actuators to '+string(value)+' complete.');

%% Clean up: Close the driver
BMCCloseDM(dm);