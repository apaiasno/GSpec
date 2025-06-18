function ThorlabsPM101_readContinuous(test_meter, t_update, t_duration)
% Sets up Thorlabs PM101 for taking measurements.
% Inputs:
% test_meter: object associated with chosen power meter device
% t_update: float of time interval at which to periodically update power
% reading in seconds
% t_duration: float of time duration at which to stop reading from power meter in
% seconds
%
% Outputs:
% None

% Set default values
if ~exist('t_update','var')
     % Default average time value in seconds
      t_update = 0.01;
end
if ~exist('t_duration','var')
     % Default readout duration in seconds
      t_update = 300;
end

t_max = 3600;
tic;
while (toc < t_duration) && (toc < t_max) % always include a failsafe!
    ThorlabsPM101_readPower(test_meter, t_update);
end

end