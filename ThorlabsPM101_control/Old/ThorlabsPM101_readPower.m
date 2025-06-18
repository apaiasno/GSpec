function power = ThorlabsPM101_readPower(test_meter, t_update, N)
% Sets up Thorlabs PM101 for taking measurements.
% Inputs:
% test_meter: object associated with chosen power meter device
% t_update: float of time interval at which to update power reading
% N: number of readings to average
%
% Outputs:
% power: float of power measurement 

% Set default values
if ~exist('t_update','var')
     % Default average time value in seconds
      t_update = 0.01;
end
if ~exist('N','var')
     % Default number of readings to average
      N = 10;
end

power = [];
for i = 1:N
    test_meter.updateReading(t_update); % Update the power reading
    power = [power test_meter.meterPowerReading];
end
power = mean(power);   
fprintf('%.10f%c\r', power, test_meter.meterPowerUnit);
end