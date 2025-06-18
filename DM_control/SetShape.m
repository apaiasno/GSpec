function SetShape(data, duration)
% Sets all DM actuators to a fixed shape for a certain amount of time.
% Inputs:
% data: 1D array (size of DM), represents values to which actuators will be
% set
% duration: float; if 0, then shape holds indefinitely until driver is
% closed, else it is held for value of duration (in seconds)
% Outputs:
% N/A

if (min(data, [], 'all') < 0) || (max(data, [], 'all') > 1)
    error("ValueError: input shape must have values between 0 and 1.")
end

if duration < 0
    error("ValueError: duration must be a float/integer greater than or equal to 0.")
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
if numel(data) ~= dm.size
    error("ValueError: input shape must have size "+string(dm.size))
end

%% Send shape to DM
BMCSendData(dm, data);
if ~duration
    disp('Setting DM to shape complete.');
else
    pause(duration)
    %% Clean up: Close the driver
    BMCCloseDM(dm);
    disp('Setting DM to shape complete.');
end






