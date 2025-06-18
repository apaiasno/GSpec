%% Set up path
if ispc
    addpath('C:\Program Files\Boston Micromachines\Bin64\Matlab')
else
    addpath(fullfile('/opt','Boston Micromachines','lib','Matlab'))
end

% ATTENTION: change this string to match the serial number of your hardware
serialNumber = 'HVA140_0000';

%% Open the connection to the driver
[err_code, dm] = BMCOpenDM(serialNumber);
fprintf('Opened dm with %d actuators.\r', dm.size);

%% Stop/clear sequencing
BMCEnableSequence(dm, 0, false);

%% Stop/clear dithering
BMCEnableDither(dm, 0, false);

%% Configure sequence of N frames
% Bug in SDK only allows dm.size values
sequence_length = 4096;
frame_size = dm.size;
num_frames = floor(sequence_length / frame_size);
frame_rate = 10;
fprintf('Will begin sequence test with %d frames at %d Hz.\r', num_frames, frame_rate);
seq = zeros(1, sequence_length);
for frame = 1:num_frames
   seq((frame-1) * frame_size + frame) = 0.6; 
   seq((frame-1) * frame_size + (frame + 1)) = 0.8; 
end

err_code = BMCConfigureSequence(dm, seq, num_frames, frame_size, 0.05);
disp(BMCGetErrorString(err_code))

err_code = BMCEnableSequence(dm, frame_rate, true);
disp(BMCGetErrorString(err_code))

pause(15);

disp('Sequence test complete.');

%% Stop/clear sequencing
BMCEnableSequence(dm, 0, false);

%% Configure Dither pattern and waveform
x = 0:0.01:pi;
waveform = (1 - sin(x)) * 0.6;
num_frames = numel(waveform);
frame_rate = 100;
fprintf('Will begin dither test with %d frames at %d Hz.\r', num_frames, frame_rate);
actuator_pattern = ones(1, dm.size);

err_code = BMCConfigureDither(dm, waveform, actuator_pattern);
disp(BMCGetErrorString(err_code))

err_code = BMCEnableDither(dm, frame_rate, true);
disp(BMCGetErrorString(err_code))

pause(50);

disp('Dither test complete.');

%% Stop/clear dithering
BMCEnableDither(dm, 0, false);

%% Clean up: Close the driver
BMCCloseDM(dm);
