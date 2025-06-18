FEMTO_norm_635nm = 0.65;
for i = linspace(1, 100, 100) 
    luci10.setGain(false, 9, 1, 1); % false, gain, 1 = low noise, 1 = DC
    pause(5);
    [numSamples, overflow, signal] = pico.readSignal();
    % signal from mV to V, then averaged across samples, then V to W, then normalized for wavelength
    disp('Before conversion: '+string(mean(signal))+' mV')
    signal = (mean(signal * 10^(-3)) / (10^(luci10.log_gain))) * FEMTO_norm_635nm;
    disp('Signal: '+string(signal * 10^3)+' mW')
end
