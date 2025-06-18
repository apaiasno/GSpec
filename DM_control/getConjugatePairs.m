function [img1, img2] = getConjugatePairs(t_cam, t_pause, value)
% Takes conjugate pair images for EFC.
% Inputs:
% DM_size: integer, number of DM actuators
% t_cam: float, camera exposure time (in milliseconds)
% t_pause: float, time to pause between shaping DM and taking image (in
% seconds)
% value: float, float between 0 and 0.5, represents upper limit of value 
% added to actuator in its flat state
%
% Outputs:
% Saves images to:
% C:\Users\paiasnodkar.1\Documents\GSpec\DM_operation\conjugatePairs

% Properties
num_actuators = 140;
num_pixels = 768 * 1024;

% Generate DM random map
actuators = 1:num_actuators;
actuators_1 = horzcat(actuators', value*rand(num_actuators, 1));
actuators_2 = horzcat(actuators', value*rand(num_actuators, 1));

% Take conjugate difference image 1
disp('Taking image 1...')
% Positive
shape = MakeShape(actuators_1);
SetShape(shape, 0);
pause(t_pause)
total = 0;
while total == 0
    img_1_pos = CamAcquisition(t_cam);
    total = sum(img_1_pos, 'all');
end
save('conjugatePairs/Image1_offset'+string(value)+'_pos.mat', 'img_1_pos');
% Negative
shape = MakeShape([actuators_1(:,1) -actuators_1(:,2)]);
SetShape(shape, 0);
pause(t_pause)
total = 0;
while total == 0
    img_1_neg = CamAcquisition(t_cam);
    total = sum(img_1_neg, 'all');
end
save('conjugatePairs/Image1_offset'+string(value)+'_neg.mat', 'img_1_neg');
disp(' ')

% Take conjugate difference image 2
disp('Taking image 2...')
% Positive
shape = MakeShape(actuators_2);
SetShape(shape, 0);
pause(t_pause)
total = 0;
while total == 0
    img_2_pos = CamAcquisition(t_cam);
    total = sum(img_2_pos, 'all');
end
save('conjugatePairs/Image2_offset'+string(value)+'_pos.mat', 'img_2_pos');
% Negative
shape = MakeShape([actuators_2(:,1) -actuators_2(:,2)]);
SetShape(shape, 0);
pause(t_pause)
total = 0;
while total == 0
    img_2_neg = CamAcquisition(t_cam);
    total = sum(img_2_neg, 'all');
end
save('conjugatePairs/Image1_offset'+string(value)+'_neg.mat', 'img_2_neg');
disp(' ')

% Take difference images
img_1_diff = img_1_pos - img_1_neg;
img_2_diff = img_2_pos - img_2_neg;
save('conjugatePairs/Image1_offset'+string(value)+'_diff.mat', 'img_1_diff');
save('conjugatePairs/Image2_offset'+string(value)+'_diff.mat', 'img_2_diff');
end

