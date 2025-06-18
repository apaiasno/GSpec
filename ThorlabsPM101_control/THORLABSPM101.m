classdef THORLABSPM101 < matlab.mixin.Copyable
    % THORLABSPM101: MATLAB class to control Thorlabs PM101 power meter
    % 
    % Functions
    % THORLABSPM101: Construct an instance of this class and sets up
    % Thorlabs PM101 device.
    % readPower: Sets up Thorlabs PM101 for taking measurements.
    % disconnect: Closes the connection with the Thorlabs power meter device.
    
    properties
        test_meter; % Object associated with chosen power meter device
    end
    
    methods
        function obj = THORLABSPM101(default, PM_ind, t_avg, t_timeout)
            % Sets up Thorlabs PM101 for taking measurements.
            % Inputs:
            % default: boolean; True if read defaults from ThorlabsPM101_defaults.mat, False if
            % defining additional parameters manually
            % PM_ind (default: 1): integer index of power meter device
            % t_avg (default: 0.01): float of average measurement time in seconds
            % t_timeout (default: 1000): float of timeout value in miliseconds
            %
            % Outputs:
            % obj: THORLABSPM101 object
            
            % Set default values
            if default
                 % Read in default values
                  load("ThorlabsPM101_defaults.mat", "PM_ind", "t_avg", "t_timeout");
            end

            meter_list = ThorlabsPowerMeter; % Initiate the meter_list
            DeviceDescription = meter_list.listdevices; % List available device(s)
            test_meter = meter_list.connect(DeviceDescription, PM_ind); % Connect single/the first devices
            test_meter.setWaveLength(635); % Set sensor wavelength
            test_meter.setDispBrightness(0.3); % Set display brightness
            test_meter.sensorInfo; % Retrive the sensor info
            test_meter.setPowerAutoRange(1); % Set Autorange
            pause(5) % Pause the program a bit to allow the power meter to autoadjust
            test_meter.setAverageTime(t_avg); % Set average time for the measurement
            test_meter.setTimeout(t_timeout); % Set timeout value 
            obj.test_meter = test_meter;
        end
        
        function power = readPower(obj, default, t_update, N)
            % Sets up Thorlabs PM101 for taking measurements.
            % Inputs:
            % obj: THORLABSPM101 object 
            % t_update (default: 0.01): float of time interval at which to update power reading
            % N (default: 10): number of readings to average
            %
            % Outputs:
            % power: float of power measurement 

            % Set default values
            if default
                 % Read in default values
                  load("ThorlabsPM101_defaults.mat", "t_update", "N");
            end

            power = [];
            for i = 1:N
                obj.test_meter.updateReading(t_update); % Update the power reading
                power = [power obj.test_meter.meterPowerReading];
            end
            power = mean(power);   
        end
        
        function disconnect(obj)
            % Closes the connection with the Thorlabs power meter device.
            % Inputs:
            % obj: THORLABSPM101 object 
            %
            % Outputs:
            % None
            obj.test_meter.disconnect;
            disp('Thorlabs PM101 connection closed.')
        end
    end
end

    
        
        