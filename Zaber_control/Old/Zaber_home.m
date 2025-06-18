function Zaber_home(device, axis_ind)
% Homes (sends back to position 0) a Zaber translation stage of a specific axis.
% Inputs:
% device: object associated with the Zaber translation stages
% axis_ind: integer index of Zaber axis to move
%
% Outputs:
% None

% Imports
import zaber.motion.ascii.Connection;
import zaber.motion.Units;

try
    axis = device.getAxis(axis_ind);
    
    % Home axis
    axis.home();
    if axis_ind == 1
        disp('Position of axis 1 (x): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm')
    elseif axis_ind == 2
        disp('Position of axis 2 (focus): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm')
    else
        disp('Position of axis 3 (y): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm')
    end

catch exception
    rethrow(exception);
end

end