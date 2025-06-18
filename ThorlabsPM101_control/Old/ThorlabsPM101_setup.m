function test_meter = ThorlabsPM101_setup(PM_ind, t_avg, t_timeout)
% Sets up Thorlabs PM101 for taking measurements.
% Inputs:
% PM_ind: integer index of power meter device
% t_avg: float of average measurement time in seconds
% t_timeout: float of timeout value in miliseconds
%
% Outputs:
% test_meter: object associated with chosen power meter device

% Set default values
if ~exist('PM_ind','var')
     % Default power meter index
      PM_ind = 1;
end
if ~exist('t_avg','var')
     % Default average time value in seconds
      t_avg = 0.01;
end
if ~exist('t_timeout', 'var')
    % Default timeout value in miliseconds
    t_timeout = 1000;
end

meter_list = ThorlabsPowerMeter; % Initiate the meter_list
DeviceDescription = meter_list.listdevices; % List available device(s)
test_meter = meter_list.connect(DeviceDescription, PM_ind); % Connect single/the first devices
test_meter.setWaveLength(635); % Set sensor wavelength
test_meter.setDispBrightness(0.3); % Set display brightness
test_meter.sensorInfo; % Retrive the sensor info
test_meter.setPowerAutoRange(1); % Set Autorange
pause(5) % Pause the program a bit to allow the power meter to autoadjust
test_meter.setAverageTime(t_avg);                            % Set average time for the measurement
test_meter.setTimeout(t_timeout);                                % Set timeout value 
end