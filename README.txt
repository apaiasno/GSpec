This README describes the functionality of the MATLAB codebase contained herein for hardware control of the GSpec fiber nulling testbed.

Experiment_control/
===================

This directory contains various functions and scripts combining all hardware components for running fiber nulling experiments. One feature that has not been implmented but might be useful to include is a running routine for automated null tracking.

scan_XYZ_FEMTO.m
----------------
Scans Zaber translation stages in XYZ space and records the power at each position with the FEMTO photoreceiver. Automatically saves a log, CSV table of data, plot of scanned power map, and plot of gain adopted at each scanned point in the subfolder logs/yyyymmdd/, where yyyymmdd corresponds to the date of measurement.

Adjust input parameters defined in scan_XYZ_FEMTO_script.m: 
- notes: Description of experiment
- center: central position (x, focus, y) along each Zaber axis for scanning
- span: +/- range to scan along each axis in mm (typically around 0.01 mm for the xy axes in DAFN experiment)
- sampling: number of scan samples along each axis
- flat: underlying DM shape, e.g. phase knife
- zernike_corr: pairs of zernike mode indices and amplitudes

scanPhaseOffset_FEMTO.m
-----------------------
Scans Zaber translation stages in XY space and phase knife offsets to optimize null fringe visibility. Automatically saves a log, CSV table of data, plot of scanned power map, and plot of gain adopted at each scanned point in the subfolder logs/yyyymmdd/, where yyyymmdd corresponds to the date of measurement.

Adjust input parameters defined in scanPhaseOffset_script.m:
- notes: Description of experiment
- center: center position (x, y, scale) along xy Zaber axis for scanning and scale factor for phase knife offset
- span: +/- range to scan along xy Zaber axis and scale factors for phase knife offset
- sampling: number of scan samples along each parameter
- focus: fixed position for focus axis
- wavelength: wavelength to use for calculating optimal phase knife offset
- zernike_corr: pairs of zernike mode indices and amplitudes

scanZernike_FEMTO.m
-------------------
Scans Zaber translation stages in XY space and amplitudes for a given Zernike mode. Useful for optimization of Zernike modes. Automatically saves a log, CSV table of data, plot of scanned power map, and plot of gain adopted at each scanned point in the subfolder logs/yyyymmdd/, where yyyymmdd corresponds to the date of measurement. 

Adjust input parameters defined in scanZernike_FEMTO_script.m:
- notes: Description of experiment
- center: center position (x, y, amp) along xy Zaber axis for scanning and amplitude of a specified Zernike mode
- span: +/- range to scan along xy Zaber axis and Zernike amplitudes
- sampling: number of scan samples along each parameter
- focus: fixed position for focus axis
- zernike_mode: OSA index of Zernike mode to scan in amplitude
- zernike_corr: pairs of zernike mode indices and amplitudes for correction
- flat: underlying 2D map, e.g. zeros to maximize coupling in unmasked/constructive interference configurations, or phase knife to minimize null in destructive interference configuration


*** Versions of the scan_XYZ, scanPhaseOffset, and scanZernike scripts using the Thorlabs PM101 power meter can also be found in this directory ***

plotNullingProfile.m
--------------------
Extracts 1D profile through null from scan_XYZ scripts. Plots 2D map with null marked, 1D crosscut horizontal profile through null, and diagnostic plots of 1D profiles along the vertical direction through the null and at the outskirts of the scanned region.

Adjust input parameters:
- data_dir: directory in which the scanned data of interest lives
- scan: string of the form 'scanN_*.csv;, where N is the scan number of the data of interest
- y_check: number of rows above and below the row in the 2D coupling map at which peak coupling is maximized to search for the minimum null - null_guess: initial guess of x position of null


plotNullingProfile_phaseOffset.m
--------------------------------
Same as plotNullingProfile.m, except for scanPhaseOffset data instead of scan_XYZ.

plotZernikeNulls.m
------------------
Same as plotNullingProfile.m, except for scanZernike data instead of scan_XYZ.


*** The following notes provide information on the specific hardware modules. If you initialize and interact with hardware in the MATLAB IDE, make sure to disconnect them before running any of the above scripts or once you are done using the hardware. ***


DM_control/
===========
This directory contains the MATLAB class for controlling the Boston Micromachines 140-actuator Multi-DM as well as older (obsolete) scripts for DM control and  miscellaneous scripts for taking images with the CCD. The most relevant files are listed below.

DM.m
----
MATLAB class to control the Boston Micromachines deformable mirror (Multi-DM)

Object methods:

DM: Construct an instance of this class and sets up DM device to flat map provided by manufacturer.
>>> dm = DM()

sendShape: Sets all DM actuators to an input shape (140 x 1 actuator voltage values).
>>> shape = 0.5 * ones(140)
>>> dm.sendShape(shape) % sets all actuator voltages to 0.5

setFlat: Sets DM to manufacturer-provided flat map.
>>> dm.setFlat() % sets all actuator voltages to their corresponding flat map values (typically between 0.35 and 0.65 or so)

setZero: Sets all DM actuators to 0.
>>> dm.setZero() % setsi all actuator voltages to 0

setPoints: Sets specified DM actuators (first column in array of points) to voltage values (second column) relative to flat map
>>> points = [[14, 0.2], [31, -0.2], [79, 0.1]] % sets all actuator voltages to their corresponding flat map values except for increasing actuator 14 by 0.2, decreasing actuator 31 by 0.2, and increasing actuator 79 by 0.1 relative to the flat map.

setZernike: Sets DM to user-defined Zernike modes.
>>> flat = zeros(12, 12);
>>> flat(:, 1:6) = -635/4;
>>> flat(:, 7:12) = 635/4;
>>> dm.setZernike([3, 5, 8], [-40, 10, 80], flat) % sets actuator voltages to a linear combination of oblique astigmatism with -40 nm wavefront RMS amplitude, vertical astimatism with 10 nm wavefront RMS amplitude, and 80 nm wavefront RMS amplitude. The third argument specifies an underlying structure of a phase knife in units of nm upon which to superimpose the Zernike modes.

plotSurface: Plots current 2D surface of DM and outputs the plotted 2D array (corners filled in with 0.5)
>>> surface_dm = dm.plotSurface()

disconnect: Closes the connection with the Multi-DM.
>>> dm.disconnect()

Static methods:

MakeShape: converts an array of point pairs (actuator, voltage) to a 2D shape array.
>>> points = [[3, 0.2], [19, -0.1]]
>>> shape = DM.MakeShape(points, false) % generates a shape from the flat map with actuator 3 raised by 0.2 and actuator 19 lowered by 0.1 in voltage

MakeZernikePoints: obsolete.
 

FEMTO_control/
==============
This directory contains the MATLAB class for controlling the FEMTO photoreceiver with the LUCI10 USB control interface.

LUCI10.m
--------
MATLAB class to control the gain and device settings of the FEMTO photoreceiver using the LUCI10 USB control interface.

Object methods:

LUCI10: Construct an instance of this class and sets up the gain, noise, and AC/DC settings of the FEMTO.
>>> luci10 = LUCI10(true) % sets FEMTO to default parameters of log gain = 3, noise = low, and ACDC = AC.
OR
>>> luci10 = LUCI10(false, 11, 0, 0) % sets FEMTO to highest log gain = 11, noise = high (for speed), and ACDC = AC

setGain: sets gain and FEMTO read-in settings  
>>> luci10.setGain(6, 1, 0) % sets FEMTO to log gain = 6, noise = low, and ACDC = AC

disconnect: disconnects LUCI10 controller
>>> luci10.disconnect()

PicoScope_control/
==================
This directory contains the MATLAB class for controlling the PicoScope oscilloscope for digitally reading the FEMTO signals.

PICOSCOPE2204A.m
----------------
MATLAB class to control the PicoScope 2204A for communication with the FEMTO receiver.
Any time you restart MATLAB or reconnect the device to power, run any of the example files in: 'C:\Users\paiasnodkar.1\AppData\Roaming\MathWorks\MATLAB Add-Ons\Hardware Supports\PicoScope 2000 Series MATLAB Generic Instrument Driver\examples'.

PICOSCOPE2204A: Constructs an instance of this class.
>>> pico = PICOSCOPE2204A() 

readSignal: Reads signal from channel A of PicoScope.
>>> readVal = pico.readSignal() %

autoReadPicoscope: Integrates communication with LUCI10 for reading FEMTO to automate the process of iteratively reading the power measurement and updating the gain settings of the FEMTO.
>>> [readVal, gain] = pico.autoReadPicoscop(luci10) % takes in LUCI10 object to read from FEMTO

maxGainReadPicoscope: Not sure why this was written, it looks identical to autoReadPicoscope.

disconnect: Closes the connection with the PicoScope2204A 
>>> pico.disconnect()

Zaber_control/
==============
This directory contains the MATLAB class for controlling the Zaber translation stages.

Zaber.m
-------
MATLAB class to control the Zaber translation stages. x: axis 1, y: axis 3, focus: axis 2
Axis ranges are set to 0 - 25 mm (full range) for axis 1 (x) and axis 3 (y); 0 - 20 mm for axis 2 (focus) to avoid collision with the cage system.
Use the Zaber Launcher GUI application to calibrate the stages.

ZABER: Constructs an instance of this class.
>>> zaber = ZABER(true) % Sets to default parameters of COMport = 4, print new position after every motion, and stage velocity = 1 mm/s
OR
>>> zaber = ZABER(false, 4, false, 5) % Sets COMport = 4, suppress printing out new position after every translation, and stage velocity = 5 mm/s

home: Homes the specified axis after it has been disconnected from power.
zaber.home(1) % homes the x-translation axis.

getPosition: prints the current position of the stages
>>> zaber.getPosition() % prints out (x, focus, y) coordinates of the translation stages in mm

moveAbsolute: moves specified axis to specified absolute position. Values range from 0 - 25 for axis 1/3 (x/y), and 0 - 20 for axis 3 (focus), else an error will be raised.
>>> zaber.moveAbsolute(3, 10, true) % moves axis 3 (y) to 10 mm along axis at default speed of 1 mm/s and with output printing enabled
OR
>>> zaber.moveAbsolute(3, 10, false, 5, false) % move axis 3 (y) to 10 mm along axis at speed of 5 mm/s and with output printing disabled.

moveRelative: moves specified axis to new position relative to current position. Values can be both negative and positive but an error will be raised if the value specified
>>> zaber.moveRelative(3, -5, true) % move axis 3 (y) backwards (should move up for this axis) by 10 mm at default speed of 1 mm/s and with output printing enabled
OR
>>> zaber.moveRelative(3, -5, false, 5, false) % move axis 3 (y) backwards (should move up for this axis) by 10 m at 5 mm/s and with output printing disabled.

disconnect: Closes connection with Zabers.
>>> zaber.disconnect()


