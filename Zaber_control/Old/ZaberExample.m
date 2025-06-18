import zaber.motion.ascii.Connection;
import zaber.motion.Units;

connection = Connection.openSerialPort('COM4');
try
    connection.enableAlerts();

    deviceList = connection.detectDevices();
    fprintf('Found %d devices.\n', deviceList.length);

    device = deviceList(1);

    axis = device.getAxis(1);
    if ~axis.isHomed()
        axis.home();
    end

    % Move to 10mm
    axis.moveAbsolute(10, Units.LENGTH_MILLIMETRES);
    % Move by an additional 5mm
    axis.moveRelative(10, Units.LENGTH_MILLIMETRES);

    connection.close();
catch exception
    connection.close();
    rethrow(exception);
end