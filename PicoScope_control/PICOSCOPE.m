classdef PICOSCOPE < matlab.mixin.Copyable
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
        ps5000aEnuminfo;
    end
    
    methods
        function obj = PICOSCOPE()
            % Sets up PicoScope for reading measurements from FEMTO photoreceiver.
            % Inputs:
            % None
            %
            % Outputs:
            % obj: PICOSCOPE object
            
            % Load configuration information
            PS5000aConfig;
            
            %% Device connection

            % Check if an Instrument session using the device object |ps5000aDeviceObj|
            % is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
            if (exist('ps5000aDeviceObj', 'var') && ps5000aDeviceObj.isvalid && strcmp(ps5000aDeviceObj.status, 'open'))

                openDevice = questionDialog(['Device object ps5000aDeviceObj has an open connection. ' ...
                    'Do you wish to close the connection and continue?'], ...
                    'Device Object Connection Open');

                if (openDevice == PicoConstants.TRUE)

                    % Close connection to device.
                    disconnect(ps5000aDeviceObj);
                    delete(ps5000aDeviceObj);

                else

                    % Exit script if User selects 'No'.
                    return;

                end

            end
            % Create a device object. 
            obj.deviceObj = icdevice('picotech_ps5000a_generic', ''); 

            % Connect device object to hardware.
            connect(obj.deviceObj);   
            try
                %% Set channels
                % Default driver settings applied to channels are listed below - use the
                % Instrument Driver's |ps5000aSetChannel()| function to turn channels on or
                % off and set voltage ranges, coupling, as well as analog offset.

                % In this example, data is collected on channels A and B. If it is a
                % 4-channel model, channels C and D will be switched off if the power
                % supply is connected.

                % Channels       : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
                % Enabled        : 1 (PicoConstants.TRUE)
                % Type           : 1 (ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC)
                % Range          : 8 (ps5000aEnuminfo.enPS5000ARange.PS5000A_5V)
                % Analog Offset  : 0.0 V

                % Channels       : 1 - 3 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_B & PS5000A_CHANNEL_C & PS5000A_CHANNEL_D)
                % Enabled        : 0 (PicoConstants.FALSE)
                % Type           : 1 (ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC)
                % Range          : 8 (ps5000aEnuminfo.enPS5000ARange.PS5000A_5V)
                % Analog Offset  : 0.0 V

                % Find current power source
                [status.currentPowerSource] = invoke(obj.deviceObj, 'ps5000aCurrentPowerSource');

                if (obj.deviceObj.channelCount == PicoConstants.QUAD_SCOPE && status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_CONNECTED)
                    [status.setChB] = invoke(obj.deviceObj, 'ps5000aSetChannel', 1, 0, 1, 8, 0.0);
                    [status.setChC] = invoke(obj.deviceObj, 'ps5000aSetChannel', 2, 0, 1, 8, 0.0);
                    [status.setChD] = invoke(obj.deviceObj, 'ps5000aSetChannel', 3, 0, 1, 8, 0.0);

                end
                %% Set device resolution

                % Max. resolution with 1 channel enabled is 16 bits.
                [status.setResolution, resolution] = invoke(obj.deviceObj, 'ps5000aSetDeviceResolution', 16);
                %% Verify timebase index and maximum number of samples
                % Use the |ps5000aGetTimebase2()| function to query the driver as to the
                % suitability of using a particular timebase index and the maximum number
                % of samples available in the segment selected, then set the |timebase|
                % property if required.
                %
                % To use the fastest sampling interval possible, enable one analog
                % channel and turn off all other channels.
                %
                % Use a while loop to query the function until the status indicates that a
                % valid timebase index has been selected. In this example, the timebase
                % index of 65 is valid.

                % Initial call to ps5000aGetTimebase2() with parameters:
                %
                % timebase      : 65
                % segment index : 0

                status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
                timebaseIndex = 65;
                while (status.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
                    [status.getTimebase2, timeIntervalNanoseconds, maxSamples] = invoke(obj.deviceObj, ...
                                                                                    'ps5000aGetTimebase2', timebaseIndex, 0);
                    if (status.getTimebase2 == PicoStatus.PICO_OK)
                        break;
                    else
                        timebaseIndex = timebaseIndex + 1;
                    end    
                end
                fprintf('Timebase index: %d, sampling interval: %d ns\n', timebaseIndex, timeIntervalNanoseconds);
                %% Set simple trigger
                % Set a trigger on channel A, with an auto timeout - the default value for
                % delay is used.

                % Trigger properties and functions are located in the Instrument
                % Driver's Trigger group.

                triggerGroupObj = get(obj.deviceObj, 'Trigger');
                triggerGroupObj = triggerGroupObj(1);

                % Set the |autoTriggerMs| property in order to automatically trigger the
                % oscilloscope after 1 second if a trigger event has not occurred. Set to 0
                % to wait indefinitely for a trigger event.

                set(triggerGroupObj, 'autoTriggerMs', 1000);

                % Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
                % Threshold   : 1000 mV
                % Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)
                % Can also include delay and autoTrigger_ms as inputs

                [status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 1000, 2);

                %% Set block parameters and capture data
                % Capture a block of data and retrieve data values for channels A and B.

                % Block data acquisition properties and functions are located in the 
                % Instrument Driver's Block group.

                obj.blockGroupObj = get(obj.deviceObj, 'Block');
                obj.blockGroupObj = obj.blockGroupObj(1);

                % Set pre-trigger and post-trigger samples as required - the total of this
                % should not exceed the value of |maxSamples| returned from the call to
                % |ps5000aGetTimebase2()|. The number of pre-trigger samples is set in this
                % example but default of 10000 post-trigger samples is used.

                % Set pre-trigger samples.
                set(obj.deviceObj, 'numPreTriggerSamples', 1024);
                
                obj.ps5000aEnuminfo = ps5000aEnuminfo;
           catch exception
                obj.disconnect();
                rethrow(exception);
           end
        end
        
        function [numSamples, overflow, signal] = readSignal(obj)
            % Reads signal from channel A of PicoScope.
            % Inputs:
            % obj: PICOSCOPE object 
            %
            % Outputs:
            % signal: float of signal measurement

            % This example uses the |runBlock()| function in order to collect a block of
            % data - if other code needs to be executed while waiting for the device to
            % indicate that it is ready, use the |ps5000aRunBlock()| function and poll
            % the |ps5000aIsReady()| function.

            % Capture a block of data:
            %
            % segment index: 0 (The buffer memory is not segmented in this example)

            try
                invoke(obj.blockGroupObj, 'runBlock', 0);

                % Retrieve data values:

                startIndex              = 0;
                segmentIndex            = 0;
                downsamplingRatio       = 1;
                downsamplingRatioMode   = obj.ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

                % Provide additional output arguments for other channels e.g. chC for
                % channel C if using a 4-channel PicoScope.
                [numSamples, overflow, signal] = invoke(obj.blockGroupObj, 'getBlockData', startIndex, segmentIndex, ...
                                                            downsamplingRatio, downsamplingRatioMode);
             catch exception
                obj.disconnect();
                rethrow(exception);
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
            [status.stop] = invoke(obj.deviceObj, 'ps5000aStop');
            %% Disconnect device
            % Disconnect device object from hardware.
            disconnect(obj.deviceObj);
            delete(obj.deviceObj);
            disp('PicoScope connection closed.')
        end
    end
end

    
        
        