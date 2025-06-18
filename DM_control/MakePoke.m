function shape = MakePoke(ind, value)
% Sets all DM actuators to a fixed value
% Inputs:
% ind: integer between 1 and size of DM, represents index of actuator to
% poke
% value: float between 0 and 0.5, represents value added to actuator in its
% flat state
%
% Outputs:
% N/A
% fID = fopen('..\DM_shapes\DM_flat.txt', 'r');
fID = fopen('C:\Program Files\Boston Micromachines\Shapes\DM_flat.txt', 'r');
shape = fscanf(fID, '%f');
shape(ind) = shape(ind) + value;