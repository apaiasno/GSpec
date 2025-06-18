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
disp(dm.size);

%% Poke one actuator at a time
data = zeros(1,dm.size);
pokeValue = 0.5;

for k = 1:dm.size
    fprintf('Poking actuator %d of %d.\r', k, dm.size)
	data(k) = pokeValue;
	BMCSendData(dm, data);
	pause(0.1)
	data(k) = 0;
	BMCSendData(dm, data);
end

disp('Poke test complete.');

%% Clean up: Close the driver
BMCCloseDM(dm);
