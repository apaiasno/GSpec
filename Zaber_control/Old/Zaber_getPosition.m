function position = Zaber_getPosition(device)
% Returns the current position of all 3 axes of the Zaber translation
% stages.
% Inputs:
% device: object associated with the Zaber translation stages
%
% Outputs:
% position: array of absolute positions of all 3 axes

% Imports
import zaber.motion.ascii.Connection;
import zaber.motion.Units;

position = [];
for axis_ind = 1:3
    axis = device.getAxis(axis_ind);
    position = [position axis.getPosition(Units.LENGTH_MILLIMETRES)];
end

disp("Position (x, focus, y):")
disp(position)
end
    