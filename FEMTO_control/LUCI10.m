classdef LUCI10 < matlab.mixin.Copyable
    % Zaber: MATLAB class to control Zaber translation stages
    % 
    % Functions
    % THORLABSPM101: Construct an instance of this class and sets up
    % Thorlabs PM101 device.
    % readPower: Sets up Thorlabs PM101 for taking measurements.
    % disconnect: Closes the connection with the Thorlabs power meter device.
    
    properties
        index; % index associated with LUCI10 controller device
        log_gain; % log_10 of gain
        noise_flag; % high speed = 0, low noise = 1
        ACDC_flag; % AC = 0, DC = 1
    end
    
    methods
        function obj = LUCI10(default, log_gain, noise_flag, ACDC_flag)
            % Sets up LUCI10 controller for communicating with FEMTO receiver.
            % Inputs:
            % default: boolean; True if read defaults from LUCI10_defaults.mat, False if
            % defining additional parameters manually
            % log_gain (default: 3): integer representing log_10 of gain
            % value to set
            % noise_flag (default: 1): 0 or 1; high speed = 0, low noise = 1
            % ACDC_flag (default: 0): 0 or 1; AC = 0, DC = 1
            %
            % Outputs:
            % obj: LUCI10 object
                      
            file_dir = 'C:\Users\paiasnodkar.1\GSpec\MATLAB\FEMTO_control\Driver\';
            loadlibrary(join([file_dir,'LUCI_10_x64.dll']), join([file_dir,'LUCI_10_x64.h']), 'alias', 'LUCI10_lib');
            obj.index = calllib('LUCI10_lib', 'EnumerateUsbDevices');
            calllib('LUCI10_lib', 'LedOn', obj.index);
            if default
                setGain(obj, default);      
            else
                setGain(obj, default, log_gain, noise_flag, ACDC_flag); 
            end
        end
        
        function setGain(obj, default, log_gain, noise_flag, ACDC_flag)
            % Sets gain and read settings (low noise vs. high speed, AC vs.
            % DC).
            % default: boolean; True if read defaults from LUCI10_defaults.mat, False if
            % defining additional parameters manually
            % log_gain (default: 3): integer representing log_10 of gain
            % value to set
            % noise_flag (default: 1): 0 or 1; high speed = 0, low noise = 1
            % ACDC_flag (default: 0): 0 or 1; AC = 0, DC = 1
            
            % Set default values
            if default
                 % Read in default COMport value
                  load('LUCI10_defaults.mat', 'log_gain', 'noise_flag', 'ACDC_flag');
            end
            
            if (noise_flag ~= 0) && (noise_flag ~= 1)
                error("ValueError: input noise_flag must be either 0 or 1.")
            end
            
            if (ACDC_flag ~= 0) && (ACDC_flag ~= 1)
                error("ValueError: input ACDC_flag must be either 0 or 1.")
            end
            
            if noise_flag && (log_gain < 3 || log_gain > 9)
                error("ValueError: input log_gain must be between 3 and 9 for low noise setting.")
            elseif ~noise_flag && (log_gain < 5 || log_gain > 11)
                error("ValueError: input log_gain must be between 5 and 11 for high speed setting.")
            end
            
            try
                if noise_flag
                    gain_ind = log_gain - 3; % log_10(gain) ranges from 3 to 9
                else
                    gain_ind = log_gain - 5; % log_10(gain) ranges from 5 to 11
                end
                gain_input = string(noise_flag) + string(ACDC_flag) + dec2bin(gain_ind, 3);
                data_low = bin2dec('000' + gain_input);
                data_high = bin2dec('00000000');

                calllib('LUCI10_lib', 'WriteData', obj.index, data_low, data_high);
                obj.log_gain = log_gain;
                obj.noise_flag = noise_flag;
                obj.ACDC_flag = ACDC_flag;
                
%                 disp('LUCI10 set to gain = 10^'+string(obj.log_gain));
%                 if obj.noise_flag
%                     disp('LUCI10 set to low noise')
%                 else
%                     disp('LUCI10 set to high speed')
%                 end
%                 if obj.ACDC_flag
%                     disp('LUCI10 set to DC')
%                 else
%                     disp('LUCI10 set to AC')
%                 end               
                
            catch exception
                obj.disconnect();
                rethrow(exception);
            end
        end
            
        function disconnect(obj)
            % Disconnects LUCI10 controller.
            % Inputs:
            % obj: LUCI10 object            
            %
            % Outputs:
            % None
            
            calllib('LUCI10_lib', 'LedOff', obj.index);
            disp('LUCI10 connection closed.')
        end
    end
end