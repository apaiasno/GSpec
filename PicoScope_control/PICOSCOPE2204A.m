classdef PICOSCOPE2204A < matlab.mixin.Copyable
    % Zaber: MATLAB class to control Zaber translation stages
    % 
    % Functions
    % THORLABSPM101: Construct an instance of this class and sets up
    % Thorlabs PM101 device.
    % readPower: Sets up Thorlabs PM101 for taking measurements.
    % disconnect: Closes the connection with the Thorlabs power meter device.
    
    properties
        deviceObj; % Object associated with chosen power meter device
        blockGroupObj;
    end
    
    methods
        function obj = PICOSCOPE2204A()
            % Sets up PicoScope for reading measurements from FEMTO photoreceiver.
            % Inputs:
            % None
            %
            % Outputs:
            % obj: PICOSCOPE object
            
            % Load configuration information
            PS2000Config;
            
            %% Device connection
            % Create a device object. 
            obj.deviceObj = icdevice('picotech_ps2000_generic.mdd');

            % Connect device object to hardware.
            connect(obj.deviceObj);   
            try
                %% Obtain Device Groups
                % Obtain references to device groups to access their respective properties
                % and functions.

                % Block specific properties and functions are located in the Instrument
                % Driver's Block group.

                obj.blockGroupObj = get(obj.deviceObj, 'Block');
                obj.blockGroupObj = obj.blockGroupObj(1);
           catch exception
                obj.disconnect();
                rethrow(exception);
           end
        end
        
        function readVal = readSignal(obj)
            % Reads signal from channel A of PicoScope.
            % Inputs:
            % obj: PICOSCOPE object 
            %
            % Outputs:
            % readVal: float of signal measurement
            
            try
                %% Data Collection
                % Capture a block of data on Channels A and B together with times. Data for
                % channels is returned in millivolts.
%                 disp('Collecting block of data...');

                % Execute device object function(s).
                set(obj.deviceObj, 'numberOfSamples', 1024);
                [bufferTimes, readVal, bufferChB, numSamples, timeIndisposedMs] = invoke(obj.blockGroupObj, 'getBlockData');
%                 disp('Data collection complete.');
             catch exception
                obj.disconnect();
                rethrow(exception);
            end
        end
        
        function [readVal, gain] = autoReadPicoscope(obj, luci10)
            gain = luci10.log_gain;
            signal = obj.readSignal();
            readVal = mean(signal);
            modBoundLow = 50.0;
            modBoundHigh = 1000.0;

            if readVal > modBoundLow && readVal < modBoundHigh
                readVal = readVal / 10^gain;
                % Do nothing since within bounds
                return
            end

            %% Perform change

            if readVal < modBoundLow
                % Initial gain was too low
                while readVal < modBoundLow
                    if (gain >= 9 && luci10.noise_flag == 1) || (gain >= 11 && luci10.noise_flag == 0)
                        % Gain is already at maximum
                        if readVal < 20.0
                            % Warn if power is still outside of bounds
                            warning(['Femto gain is at Maximum but power is still low\n' ...
                                  ' Current Gain = ~10^%i   |  Current Power = %f'], ...
                                  gain, readVal)
                        end
                        readVal = readVal / 10^gain;
                        % Exit function
                        return
                    end

                    % Increase the gain
                    gain = gain + 1;

                    % Change gain
                    luci10.setGain(false, gain, luci10.noise_flag, luci10.ACDC_flag);

                    % Check power at new gain 
                    readVal = mean(obj.readSignal());        
                end
                readVal = readVal / 10^gain;
                % New gain setting is done; exit
                return
            end
            if readVal > modBoundHigh
                % Initial gain was too high
                while readVal > modBoundHigh
                    if (gain <= 3 && luci10.noise_flag == 1) || (gain <= 5 && luci10.noise_flag == 0)
                        % Gain is already at minimum
                        if readVal > modBoundHigh
                            % Warn if power is still outside of bounds
                            warning(['Femto gain is at Minimum but power is still too High\n' ...
                                  ' Current Gain = ~10^%i   |  Current Power = %f'], ...
                                  gain, readVal)
                        end
                        readVal = readVal / 10^gain;
                        % Exit function
                        return
                    end

                    % Decrease the gain
                    gain = gain - 1;

                    % Change gain
                    luci10.setGain(false, gain, luci10.noise_flag, luci10.ACDC_flag);

                    % Check power at new gain 
                    readVal = mean(obj.readSignal());     
                end
                readVal = readVal / 10^gain;
                return
            end
        end

        function [readVal, gain] = maxGainReadPicoscope(obj, luci10)
            gain = luci10.log_gain;
            signal = obj.readSignal();
            readVal = mean(signal);
            modBoundLow = 50.0;
            modBoundHigh = 1000.0;

            if readVal > modBoundLow && readVal < modBoundHigh
                readVal = readVal / 10^gain;
                % Do nothing since within bounds
                return
            end

            %% Perform change

            if readVal < modBoundLow
                % Initial gain was too low
                while readVal < modBoundLow
                    if (gain >= 9 && luci10.noise_flag == 1) || (gain >= 11 && luci10.noise_flag == 0)
                        % Gain is already at maximum
                        if readVal < 20.0
                            % Warn if power is still outside of bounds
                            warning(['Femto gain is at Maximum but power is still low\n' ...
                                  ' Current Gain = ~10^%i   |  Current Power = %f'], ...
                                  gain, readVal)
                        end
                        readVal = readVal / 10^gain;
                        % Exit function
                        return
                    end

                    % Increase the gain
                    gain = gain + 1;

                    % Change gain
                    luci10.setGain(false, gain, luci10.noise_flag, luci10.ACDC_flag);

                    % Check power at new gain 
                    readVal = mean(obj.readSignal());        
                end
                readVal = readVal / 10^gain;
                % New gain setting is done; exit
                return
            end
            if readVal > modBoundHigh
                % Initial gain was too high
                while readVal > modBoundHigh
                    if (gain <= 3 && luci10.noise_flag == 1) || (gain <= 5 && luci10.noise_flag == 0)
                        % Gain is already at minimum
                        if readVal > modBoundHigh
                            % Warn if power is still outside of bounds
                            warning(['Femto gain is at Minimum but power is still too High\n' ...
                                  ' Current Gain = ~10^%i   |  Current Power = %f'], ...
                                  gain, readVal)
                        end
                        readVal = readVal / 10^gain;
                        % Exit function
                        return
                    end

                    % Decrease the gain
                    gain = gain - 1;

                    % Change gain
                    luci10.setGain(false, gain, luci10.noise_flag, luci10.ACDC_flag);

                    % Check power at new gain 
                    readVal = mean(obj.readSignal());     
                end
                readVal = readVal / 10^gain;
                return
            end
        end
        
        function disconnect(obj)
            % Closes the connection with the PICOSCOPE device.
            % Inputs:
            % obj: PICOSCOPE object 
            %
            % Outputs:
            % None
            %% Stop the device
            stopStatus = invoke(obj.deviceObj, 'ps2000Stop');
            %% Disconnect device
            % Disconnect device object from hardware.
            disconnect(obj.deviceObj);
            delete(obj.deviceObj);
            disp('PicoScope connection closed.')
        end
    end
end

    
        
        