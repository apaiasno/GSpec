function [readVal, gain] = autoReadPicoscope(luci10, Pico, gain, low_noise_flag, DC_flag)
luci10.setGain(false, gain, low_noise_flag, DC_flag); % false, gain, 1 = low noise, 1 = DC
signal = Pico.readSignal();
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
        if gain >= 9
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
        luci10.setGain(false, gain, low_noise_flag, DC_flag);
        
        % Check power at new gain 
        readVal = mean(Pico.readSignal());        
    end
    readVal = readVal / 10^gain;
    % New gain setting is done; exit
    return
end
if readVal > modBoundHigh
    % Initial gain was too high
    while readVal > modBoundHigh
        if gain <= 3
            % Gain is already at minimum
            if readVal > modBoundHigh
                % Warn if power is still outside of bounds
                warning(['Femto gain is at Minimum but power is still too High\n' ...
                      ' Current Gain = ~10^%i   |  Current Power = %f'], ...
                      gain, readVal)
            end
            readVal = readVal / 10^gain
            % Exit function
            return
        end
        
        % Decrease the gain
        gain = gain - 1;
        
        % Change gain
        luci10.setGain(false, gain, low_noise_flag, DC_flag);
        
        % Check power at new gain 
        readVal = mean(Pico.readSignal());     
    end
    readVal = readVal / 10^gain;
    return
end

end

