function shape = MakeShape(points)
% Converts mapping of DM actuators --> value to a DM shape
% Inputs:
% points: 2D array (DM size x 2), first column is indices of actuators and
% second column is value to offset by relative to flat map
%
% Outputs:
% shape: 1D array of actuator values readable by DM
% fID = fopen('..\DM_shapes\DM_flat.txt', 'r');
fID = fopen('C:\Program Files\Boston Micromachines\Shapes\DM_flat.txt', 'r');

shape = fscanf(fID, '%f');
points_size = size(points);
points_size = points_size(1);
DM_size = numel(shape);
for i = 1:points_size
    if (points(i,1) < 1) || (points(i,1) > DM_size)
        error('ValueError: actuator index '+string(i)+' must be between 1 and '+string(DM_size)+'.')
    else
        shape(points(i,1)) = shape(points(i,1)) + points(i,2);
%         shape(points(i,1)) = 0.5 + points(i,2);
    end
end

if (min(shape, [], 'all') < 0) || (max(shape, [], 'all') > 1)
    error("ValueError: input shape must have values between 0 and 1.")
end








