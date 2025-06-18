function Zaber_moveRelative(device, axis_ind, position_rel, default, velocity)
% Moves a Zaber translation stage of a specific axis by a relative distance.
% Inputs:
% device: object associated with the Zaber translation stages
% axis_ind: integer index of Zaber axis to move
% position_rel: float of absolute position (between 0 and max translation)
% in mm to move stage to
% default: boolean; True if read defaults from Zaber_defaults.mat, False if
% defining additional parameters manually
% velocity (default: 2 mm/s): float of speed (less than 2 mm/s) in mm/s at which to
% move stage 
%
% Outputs:
% None

% Imports
import zaber.motion.ascii.Connection;
import zaber.motion.Units;

% Set default values
if default
     % Read in default COMport value
      load("Zaber_defaults.mat", "velocity");
end

% Check limits
if velocity > 2
    error("ValueError: input velocity must be less than 2 mm/s.")
end

try
    axis = device.getAxis(axis_ind);
    % Precaution to prevent ~VIGOROUS SHAKING~
    axis.getSettings().set('maxspeed', velocity, Units.VELOCITY_MILLIMETRES_PER_SECOND)
    
    % Home axis if necessary
    if ~axis.isHomed()
        axis.home();
    end

    % Check limits
    position_current = axis.getPosition(Units.LENGTH_MILLIMETRES);
    disp('Current position: '+string(position_current)+' mm')
    if (position_rel + position_current < 0) || (position_rel + position_current > 25)
        error("ValueError: input position_abs must have value between 0 and 25 mm.")
    end
    
    % Move
    axis.moveRelative(position_rel, Units.LENGTH_MILLIMETRES, 1, velocity, Units.VELOCITY_MILLIMETRES_PER_SECOND);
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