default = false;
gain = 3;
low_noise_flag = 1;
DC_flag = 1;
luci = LUCI10(default, gain, low_noise_flag, DC_flag);
[readVal, gain] = autoReadPicoscope(luci, pico, gain, low_noise_flag, DC_flag);
disp([readVal, gain, readVal * 10^gain])