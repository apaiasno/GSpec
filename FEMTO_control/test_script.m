file_dir = 'C:\Users\paiasnodkar.1\GSpec\MATLAB\FEMTO_control\Driver\';
loadlibrary(join([file_dir,'LUCI_10_x64.dll']), join([file_dir,'LUCI_10_x64.h']), 'alias', 'LUCI10_lib');
index = calllib('LUCI10_lib', 'EnumerateUsbDevices');
calllib('LUCI10_lib', 'LedOff', index);

gain = 5; % log_10(gain)
% Set pins according to datasheet
noise_flag = 1; % high speed = 0, low noise = 1
ACDC_flag = 0; % AC = 0, DC = 1
if noise_flag
	gain_ind = gain - 3; % log_10(gain) ranges from 5 to 11
else
	gain_ind = gain - 5; % log_10(gain) ranges from 3 to 9
end
gain_input = string(noise_flag) + string(ACDC_flag) + dec2bin(gain_ind, 3);
data_low = str2num('000' + gain_input) ;
data_high = str2num('00000000');

calllib('LUCI10_lib', 'WriteData', index, data_low, data_high);
