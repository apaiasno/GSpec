function [Data] = CamAcquisition(t_exp)
% Communicates with ThorCam (DCU223M) to take image.
% Inputs:
% t_exp: float, exposure time in ms
%
% Outputs:
% Data: 2D array of image intensity values
try
    % Add NET assembly
    % May need to change specific location of library
    NET.addAssembly('C:\Program Files\Thorlabs\Scientific Imaging\DCx Camera Support\Develop\DotNet\uc480DotNet.dll');
    % Create camera object handle
    cam = uc480.Camera;
    % Open the 1st available camera
    cam.Init(0);
    % Set display mode to bitmap (DiB)
    cam.Display.Mode.Set(uc480.Defines.DisplayMode.DiB);
    % Set color mode to 8-bit RGB
    cam.PixelFormat.Set(uc480.Defines.ColorMode.Mono8);
    % % Set offset for black level correction
    % cam.BlackLevel.Offset.Set(30);
    % % Set value of the digital gamma correction
%     cam.Gamma.Software.Set(200);
    % Set trigger mode to software (single image acquisition)
    cam.Trigger.Set(uc480.Defines.TriggerMode.Software);
    % Allocate image memory
    [~, MemId] = cam.Memory.Allocate(true);
    % Obtain image information
    [~, Width, Height, Bits, ~] = cam.Memory.Inquire(MemId);
    % Trying is_Convert to set pixel format
%     cam.is_SetSaturation(MemId, 100, 100);
    % Set exposure time
    cam.Timing.Exposure.Set(t_exp);
    total = 0;
    
    %  % Acquire image
    % cam.Acquisition.Freeze(uc480.Defines.DeviceParameter.Wait);
    % % Copy image from memory
    % [~, tmp] = cam.Memory.CopyToArray(MemId);
    
    while total == 0
        % Acquire image
        cam.Acquisition.Freeze(uc480.Defines.DeviceParameter.Wait);
        % Copy image from memory
        [~, tmp] = cam.Memory.CopyToArray(MemId);
        % Reshape image
        Data = reshape(uint16(tmp), [Bits/8, Width, Height]);
        Data = uint16(prod(Data, 1));
        total = sum(Data, 'all');
    end
    s = size(Data);
    Data = reshape(Data, s(2), s(3));
    Data = Data';
    % Close camera
    cam.Exit;
catch e
    disp(e.identifier)
    disp(e.message)
    cam.Exit;
end
end