function [FMTO_scale, s] = VFN_FMTO_setAutoGain(s, readVal, FMTO_scale)
% VFN_FMTO_setAutoGain Function for automatically setting the gain:
%   Takes in a power reading and changes the gain accordingly to ensure
%   that future reads are within reasonable bounds on the Femto PM. If 
%   the reading is already within bounds, nothing is done.
%
%   - Assumes the gain setting is set to "high-speed" on the Femto
%
%   - The daq session (s) needs to be modified and then restarted so the
%       the code tries to return a session with the same parameters.
%           *** You can add parameters at the beginning of the "Perform
%           Change" section.
%       Uses VFN_setUpFMTO
%
%   - The code shoots to intelligently place the new reading within bounds:
%       If readVal < modBoundLow, the gain will be increased until 
%         newVal > 1  
%       If readVal > modBoundHigh, the gain will be decreased until 
%         newVal < 1
%   
%       Current Mod Bounds:     [0.1 V < readVal < 9.5 V]
%
%   EXAMPLE:______
%   [FMTO_scale, s] = VFN_FMTO_setAutoGain(s, readVal, FMTO_scale)
%       s:          An NI daq session
%       readVal:    A recent reading to use as a starting point 
%       FMTO_scale: Current femto scale setting defined by: 10^FMTO_scale

modBoundLow     = 0.1; % Volts
modBoundHigh    = 9.5; % Volts

%% Determine if change is needed
% Check that s variable is correct
if ~isa(s, 'daq.ni.Session')
    error('The first argument must be an ni daq session')
end

if readVal > modBoundLow && readVal < modBoundHigh
    % Do nothing since within bounds
    return
end

%% Perform change

%-- Save the current session parameters (You can add more parameters here
%as needed for your application. These should be whatever you are defining
%when VFN_setUpFMTO gets called)
Nrate = s.Rate;             % [samples/second]
Nread = s.NumberOfScans;    % Number of samples at a given location

%Modify current session to allow output
s.Rate = 10; s.DurationInSeconds = 0.2;
% Add digitial channel (suppressing known warning)
warning('off', 'daq:Session:onDemandOnlyChannelsAdded')   
addDigitalChannel(s, 'Dev1', 'Port0/Line0:4', 'OutputOnly');
warning('on', 'daq:Session:onDemandOnlyChannelsAdded')

if readVal < modBoundLow
    % Initial gain was too low
    while readVal < .8
        if FMTO_scale >= 11;
            % Gain is already at maximum
            if readVal < modBoundLow
                % Warn if power is still outside of bounds
                warning(['Femto gain is at Maximum but power is still low\n' ...
                      ' Current Gain = ~10^%i   |  Current Power = %f'], ...
                      FMTO_scale, readVal)
            end
            % Set FMTO settings back to original
            VFN_setUpFMTO
            % Exit function
            return
        end
        
        % Increase the gain
        FMTO_scale = FMTO_scale + 1;
        
        % Translate new gain setting to binary
        cmd = de2bi(FMTO_scale-5,3);
        
        % Change gain
        outputSingleScan(s, [cmd,1,0])
        
        % Check power at new gain 
        read = nan(10,1);
        for i = 1:length(read)
            read(i) = s.inputSingleScan;
        end
        readVal = mean(read(:));        
    end
    % New gain setting is done; exit
    VFN_setUpFMTO    
    return
end
if readVal > modBoundHigh
    % Initial gain was too high
    while readVal > 1
        if FMTO_scale <= 5;
            % Gain is already at minimum
            if readVal > modBoundHigh
                % Warn if power is still outside of bounds
                warning(['Femto gain is at Minimum but power is still too High\n' ...
                      ' Current Gain = ~10^%i   |  Current Power = %f'], ...
                      FMTO_scale, readVal)
            end
            % Set FMTO settings back to original
            VFN_setUpFMTO
            % Exit function
            return
        end
        
        % Decrease the gain
        FMTO_scale = FMTO_scale - 1;
        
        % Translate new gain setting to binary
        cmd = de2bi(FMTO_scale-5,3);
        
        % Change gain
        outputSingleScan(s, [cmd,1,0])
        
        % Check power at new gain 
        read = nan(10,1);
        for i = 1:length(read)
            read(i) = s.inputSingleScan;
        end
        readVal = mean(read(:));        
    end
    % New gain setting is done
    VFN_setUpFMTO    
    return
end

end