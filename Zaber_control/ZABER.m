classdef ZABER < matlab.mixin.Copyable
    % Zaber: MATLAB class to control Zaber translation stages
    % 
    % Functions
    % ZABER: Construct an instance of this class and sets up Zaber 
    % translation devices.
    % home: Homes (sends back to position 0) a Zaber translation stage 
    % of a specific axis.
    % moveAbsolute: Moves a Zaber translation stage of a specific axis 
    % to an absolute position.
    % moveRelative: Moves a Zaber translation stage of a specific axis 
    % by a relative distance.
    % getPosition: Returns the current position of all 3 axes of the Zaber translation
    % stages.
    % disconnect: Closes the connection with the Zaber translation devices.
    
    properties
        device; % object associated with the Zaber translation stages
        connection; % object associated with communicating to the serial port
        position; % array of absolute positions of all 3 axes 
    end
    
    methods
        function obj = ZABER(default, COMport, print_output)
            % Construct an instance of this class and sets up Zaber translation devices.
            % Inputs:
            % default: boolean; True if read defaults from Zaber_defaults.mat, False if
            % defining additional parameters manually
            % COMport (default: 4): integer of Zaber communication port
            % print_output (default: True): boolean; True if details of
            % movement should printed out to command window, else False.
            %
            % Outputs:
            % obj: ZABER object
            
            % Imports
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;

            % Set default values
            if default
                 % Read in default COMport value
                  load("Zaber_defaults.mat", "COMport", "print_output");
            end

            connection = Connection.openSerialPort('COM'+string(COMport));
            try
                % Connect to axis
                connection.enableAlerts();

                deviceList = connection.detectDevices();
                fprintf('Found %d devices.\n', deviceList.length);

                device = deviceList(1);
                obj.device = device;
                obj.connection = connection;
                
                for axis_ind = 1:3
                    axis = obj.device.getAxis(axis_ind);
                    % Home axis if necessary
                    if ~axis.isHomed()
                        disp('Homing axis '+string(axis_ind))
                        home(obj, axis_ind);
                    end
                end
                
                getPosition(obj, print_output); 
                
            catch exception
                connection.close();
                rethrow(exception);
            end
        end
        
        function home(obj, axis_ind)
            % Homes (sends back to position 0) a Zaber translation stage of a specific axis.
            % Inputs:
            % obj: ZABER object 
            % axis_ind: integer index of Zaber axis to move
            %
            % Outputs:
            % None
            
            % Imports
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;

            try
                axis = obj.device.getAxis(axis_ind);

                % Home axis
                axis.home();
                if axis_ind == 1
                    disp('Position of axis 1 (x): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm')
                elseif axis_ind == 2
                    disp('Position of axis 2 (focus): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm')
                else
                    disp('Position of axis 3 (y): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm')
                end
                
                getPosition(obj); 

            catch exception
                rethrow(exception);
            end
        end
        
        function disp_str = getPosition(obj, default, print_output)
            % Returns the current position of all 3 axes of the Zaber translation
            % stages.
            % Inputs:
            % obj: ZABER object
            % default: boolean; True if read defaults from Zaber_defaults.mat, False if
            % defining additional parameters manually
            % print_output (default: True): boolean; True if details of
            % movement should printed out to command window, else False.
            %
            % Outputs:
            % position: array of absolute positions of all 3 axes
            
            % Imports
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;
            
            % Set default values
            if default
                 % Read in default values
                  load("Zaber_defaults.mat", "print_output");
            end

            obj.position = [];
            for axis_ind = 1:3
                axis = obj.device.getAxis(axis_ind);
                obj.position = [obj.position axis.getPosition(Units.LENGTH_MILLIMETRES)];
            end 
            
            disp_str = "Position (x, focus, y): "+num2str(obj.position);
            if print_output
                disp(disp_str);
            end
        end
        
        function disp_str = moveAbsolute(obj, axis_ind, position_abs, default, ...
                velocity, print_output)
            % Moves a Zaber translation stage of a specific axis to an absolute
            % position.
            % Inputs:
            % obj: ZABER object
            % axis_ind: integer index of Zaber axis to move
            % position_abs: float of absolute position (between 0 and max translation)
            % in mm to move stage to
            % default: boolean; True if read defaults from Zaber_defaults.mat, False if
            % defining additional parameters manually
            % velocity (default: 5 mm/s): float of speed (between 0 and 250 mm/s) in mm/s at which to
            % move stage 
            % print_output (default: True): boolean; True if details of
            % movement should printed out to command window, else False.
            %
            % Outputs:
            % None

            % Imports
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;

            % Set default values
            if default
                 % Read in default COMport value
                  load("Zaber_defaults.mat", "velocity", "print_output");
            end

            % Check limits
            if (position_abs < 0) || (((axis_ind ~= 2) && (position_abs > 25)) || (axis_ind == 2) && (position_abs > 20))
                error("ValueError: input position_abs must have value between 0 and 25 mm (20 mm for axis 2).")
            end
            if velocity > 10
                error("ValueError: input velocity must be less than 10 mm/s.")
            end

            try
                axis = obj.device.getAxis(axis_ind);
                % Precaution to prevent ~V I O L E N T vIbRaTiOnS~
                axis.getSettings().set('maxspeed', velocity, Units.VELOCITY_MILLIMETRES_PER_SECOND)

                % Home axis if necessary
                if ~axis.isHomed()
                    axis.home();
                end

                % Move
                axis.moveAbsolute(position_abs, Units.LENGTH_MILLIMETRES, 1, velocity, Units.VELOCITY_MILLIMETRES_PER_SECOND);
                if axis_ind == 1
                    disp_str = 'Position of axis 1 (x): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm';
                    if print_output
                        disp(disp_str)
                    end
                elseif axis_ind == 2
                    disp_str = 'Position of axis 2 (focus): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm';
                    if print_output
                        disp(disp_str)
                    end
                else
                    disp_str = 'Position of axis 3 (y): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm';
                    if print_output
                        disp(disp_str)
                    end
                end
                
                position_str = getPosition(obj, false, print_output);
                disp_str = disp_str + "\n" + position_str;

            catch exception
                rethrow(exception);
            end
        end
        
        function disp_str = moveRelative(obj, axis_ind, position_rel, default, velocity, print_output)
            % Moves a Zaber translation stage of a specific axis by a relative distance.
            % Inputs:
            % obj: ZABER object 
            % axis_ind: integer index of Zaber axis to move
            % position_rel: float of absolute position (between 0 and max translation)
            % in mm to move stage to
            % default: boolean; True if read defaults from Zaber_defaults.mat, False if
            % defining additional parameters manually
            % velocity (default: 5 mm/s): float of speed (less than 10 mm/s) in mm/s at which to
            % move stage 
            % print_output (default: True): boolean; True if details of
            % movement should printed out to command window, else False.
            %
            % Outputs:
            % None

            % Imports
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;

            % Set default values
            if default
                 % Read in default values
                  load("Zaber_defaults.mat", "velocity", "print_output");
            end

            % Check limits
            if velocity > 10
                error("ValueError: input velocity must be less than 10 mm/s.")
            end

            try
                axis = obj.device.getAxis(axis_ind);
                % Precaution to prevent ~VIGOROUS SHAKING~
                axis.getSettings().set('maxspeed', velocity, Units.VELOCITY_MILLIMETRES_PER_SECOND)

                % Home axis if necessary
                if ~axis.isHomed()
                    axis.home();
                end

                % Check limits
                position_current = axis.getPosition(Units.LENGTH_MILLIMETRES);
                disp('Current position: '+string(position_current)+' mm')
                position_abs = position_rel + position_current;
                if (position_abs < 0) || (((axis_ind ~= 2) && (position_abs > 25)) || (axis_ind == 2) && (position_abs > 20))
                    error("ValueError: input position_abs must have value between 0 and 25 mm (20 mm for axis 2).")
                end

                % Move
                axis.moveRelative(position_rel, Units.LENGTH_MILLIMETRES, 1, velocity, Units.VELOCITY_MILLIMETRES_PER_SECOND);
                if axis_ind == 1
                    disp_str = 'Position of axis 1 (x): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm';
                    if print_output
                        disp(disp_str)
                    end
                elseif axis_ind == 2
                    disp_str = 'Position of axis 2 (focus): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm';
                    if print_output
                        disp(disp_str)
                    end
                else
                    disp_str = 'Position of axis 3 (y): '+string(axis.getPosition(Units.LENGTH_MILLIMETRES))+' mm';
                    if print_output
                        disp(disp_str)
                    end
                end
                
                position_str = getPosition(obj, false, print_output);
                disp_str = disp_str + "\n" + position_str;

            catch exception
                rethrow(exception);
            end
        end
        
        function disconnect(obj)
            % Closes the connection with the Zaber translation devices.
            % Inputs:
            % obj: ZABER object 
            %
            % Outputs:
            % None
            
            % Imports
            import zaber.motion.ascii.Connection;
            import zaber.motion.Units;

            obj.connection.close()
            disp('Zaber connection closed.');
        end
    end
end

    
        
        