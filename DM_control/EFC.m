function [E_ab_real, E_ab_imag] = EFC(value)
% Performs the EFC algorithm for wavefront sensing.
% Inputs:
% value: float, float between 0 and 0.5, represents upper limit of value 
% added to actuator in its flat state
%
% Outputs:
% E_ab_real, E_ab_imag: 2D arrays, real and imaginary components of wavefront
% electric field

img_1_diff = load('conjugatePairs/Image1_offset'+string(value)+'_diff.mat');
img_1_diff = img_1_diff.img_1_diff;
img_2_diff = load('conjugatePairs/Image2_offset'+string(value)+'_diff.mat');
img_2_diff = img_2_diff.img_2_diff;
