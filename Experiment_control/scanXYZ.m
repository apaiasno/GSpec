function [position_max, axis1_range, axis2_range, axis3_range, power_3D] = scanXYZ_ThorlabsPM101(center, span, sampling, Zaber_params, PM101_params)
% Scans Zabers in XYZ space and records the power at each position with the
% Thorlabs PM101.
% Inputs:
% center: array of 3 values associated with 3-axis position (in mm) on which to 
% center the scan 
% span: array of 3 values associated with 3-axis range (in mm) on either side
% of center over which to scan
% sampling: array of 3 values associated with number of samples to take
% along each of the 3 axes
% Zaber_params: struct with parameters for using the Zaber translation
% stages. Required: default. Optional: COMport, velocity.
% PM101_params: struct with parameters for using the Thorlabs PM101 power
% meter. Required: default. Optional: PM_ind, t_avg, t_timeout, t_update,
% N.
%
% Outputs:
% position: array of 3 values associated with position of maximum measured
% power
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#.log: log file
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#.csv: data 
% file of Zaber positions and measured power
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#_z#.png: plot 
% of scanned power map

% Setup logging directory and filenames
log_dir = strcat('logs\', string(yyyymmdd(datetime('today'))), '\');
if ~exist(log_dir, 'dir')
    mkdir(log_dir)
end

center_str = 'center_';
for i=1:numel(center)
    center_str = center_str + (strrep(string(center(i)), '.', 'p')+'_');
end
span_str = 'span_';
for i=1:numel(range)
    span_str = span_str + (strrep(string(span(i)), '.', 'p')+'_');
end
sampling_str = 'sampling_';
for i=1:numel(range)
    sampling_str = sampling_str + (strrep(string(sampling(i)), '.', 'p')+'_');
end
run_num = numel(dir('logs\20240304\scan_center*span*sampling*run*.log'));
run_str = 'run'+string(run_num);
filename_root = 'scan_'+center_str+span_str+sampling_str+run_str;
filename_log = filename_root+'.log';
filename_csv = filename_root+'.csv';
filename_png = filename_root+'.png';

% Setup Zaber translation devices
if Zaber_params.default
    Zaber = ZABER(Zaber_params.default);
else
    Zaber = ZABER(Zaber_params.default, Zaber_params.COMport);
end
    
% Setup Thorlabs PM101 power meter 
if PM101_params.default
    PM101 = THORLABSPM101(PM101_params.default);
else
    PM101 = THORLABSPM101(PM101_params.default, PM101_params.PM_ind, PM101_params.t_avg, PM101_params.t_timeout);
end
    
% Setup scanning positions
axis1_range = linspace(center(1)-span(1), center(1)+span(1), sampling(1));
axis2_range = linspace(center(2)-span(2), center(2)+span(2), sampling(2));
axis3_range = linspace(center(3)-span(3), center(3)+span(3), sampling(3));

% Begin scanning; for a given focus, scan laterally and build upwards
% without wrapping
power_3D = [];
for i2 = axis2_range % scan in focus
    if Zaber_params.default
        Zaber.moveAbsolute(2, i2, Zaber_params.default);
    else
        Zaber.moveAbsolute(2, i2, Zaber_params.default, Zaber_params.velocity);
    end
    power_2D = [];
    for i3 = axis3_range % scan in y
        if Zaber_params.default
            Zaber.moveAbsolute(3, i3, Zaber_params.default);
        else
            Zaber.moveAbsolute(3, i3, Zaber_params.default, Zaber_params.velocity);
        end
        power_1D = [];
        for i1 = axis1_range % scan in x
            if Zaber_params.default
                Zaber.moveAbsolute(1, i1, Zaber_params.default);
            else
                Zaber.moveAbsolute(1, i1, Zaber_params.default, Zaber_params.velocity);
            end
            pause(1) % let the stages settle
            if PM101_params.default
                power = PM101.readPower(PM101.default);
            else
                power = PM101.readPower(PM101.default, PM101.t_update, PM101.N);
            end
            power_1D = [power_1D power];
        end
        power_2D = [power_2D; power_1D];
    end
    power_3D = [power_3D; power_2D];
end

end
            
            

