%% Set up path
if ispc
    addpath('C:\Program Files\Boston Micromachines\Bin64\Matlab')
else
    addpath(fullfile('/opt','Boston Micromachines','lib','Matlab'))
end

% ATTENTION: change this string to match the serial number of your hardware
serialNumber1 = 'MultiUSB422';
serialNumber2 = 'MultiUSB431';

%% Open the connection to the driver
[err_code, dm1] = BMCOpenDM(serialNumber1);
disp(dm1.size);
[err_code, dm2] = BMCOpenDM(serialNumber2);
disp(dm2.size);

%% Poke one actuator at a time
data1 = zeros(1,dm1.size);
data2 = zeros(1,dm2.size);
pokeValue1 = 0.4;
pokeValue2 = 0.8;
size = min(dm1.size, dm2.size)

for k = 1:size
    fprintf('Poking actuator %d of %d for both DMs.\r', k, size)
	data1(k) = pokeValue1;
	data2(k) = pokeValue2;
	BMCSendData(dm1, data1);
	BMCSendData(dm2, data2);
	pause(0.1)
	data1(k) = 0;
	data2(k) = 0;
	BMCSendData(dm1, data1);
	BMCSendData(dm2, data2);
end

disp('2 DM Poke test complete.');

%% Close the driver for one DM
BMCCloseDM(dm1);

% Try to send data to closed DM, get error code
err_code = BMCSendData(dm1, data1);
if (~isequal(err_code, BMCRC.ERR_NOT_OPEN))
    error('Unexpected error code sending data to closed DM.');
end

%% Continue poking the other DM
disp(dm2.size);
for k = 1:dm2.size
    fprintf('Poking actuator %d of %d for second DM.\r', k, dm2.size)
	data2(k) = pokeValue2;
	BMCSendData(dm2, data2);
	pause(0.1)
	data2(k) = 0;
	BMCSendData(dm2, data2);
end
disp('Poke test complete.');

%% Clean up - close the driver for second DM
BMCCloseDM(dm2);
