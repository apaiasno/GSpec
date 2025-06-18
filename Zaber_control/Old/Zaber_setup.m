function [device, connection] = Zaber_setup(default, COMport)
% Sets up Zaber translation devices.
% Inputs:
% default: boolean; True if read defaults from Zaber_defaults.mat, False if
% defining additional parameters manually
% COMport (default: 4): integer of Zaber communication port
%
% Outputs:
% device: object associated with the Zaber translation stages
% connection: object associated with communicating to the serial port

% Imports
import zaber.motion.ascii.Connection;
import zaber.motion.Units;

% Set default values
if default
     % Read in default COMport value
      load("Zaber_defaults.mat", "COMport");
end

connection = Connection.openSerialPort('COM'+string(COMport));
try
    % Connect to axis
    connection.enableAlerts();

    deviceList = connection.detectDevices();
    fprintf('Found %d devices.\n', deviceList.length);

    device = deviceList(1);
catch exception
    connection.close();
    rethrow(exception);
end

end