function [position_max, power_max, axis1_range, axis2_range, axis3_range, power_3D] = scanXYZ_ThorlabsPM101(center, span, sampling, Zaber_params)
% Scans Zabers in XYZ space and records zero power because there is no powermeter.
% Inputs:
% center: array of 3 values associated with 3-axis position (in mm) on which to 
% center the scan 
% span: array of 3 values associated with 3-axis range (in mm) on either side
% of center over which to scan
% sampling: array of 3 values associated with number of samples to take
% along each of the 3 axes
% Zaber_params: struct with parameters for using the Zaber translation
% stages. Required: default. Optional: COMport, velocity.
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
for i=1:numel(span)
    span_str = span_str + (strrep(string(span(i)), '.', 'p')+'_');
end
sampling_str = 'sampling_';
for i=1:numel(sampling)
    sampling_str = sampling_str + (strrep(string(sampling(i)), '.', 'p')+'_');
end
run_num = numel(dir('logs\20240304\scan_center*span*sampling*run*.log'));
run_str = 'run'+string(run_num);
filename_root = log_dir+'scan_'+center_str+span_str+sampling_str+run_str;
filename_log = filename_root+'.log';
filename_csv = filename_root+'.csv';

diary(filename_log)
disp(filename_root)
disp('Axis 1 (x): '+string(center(1)-span(1))+' mm to '+string(center(1)+span(1))+' mm')
disp('Axis 2 (focus): '+string(center(2)-span(2))+' mm to '+string(center(2)+span(2))+' mm')
disp('Axis 3 (y): '+string(center(3)-span(3))+' mm to '+string(center(3)+span(3))+' mm')
disp(newline)

% Setup Zaber translation devices
disp('Setting up Zaber translation devices...')
if Zaber_params.default
    Zaber = ZABER(Zaber_params.default);
else
    Zaber = ZABER(Zaber_params.default, Zaber_params.COMport);
end
disp(newline)

% % Setup Thorlabs PM101 power meter 
% disp('Setting up Thorlabs PM101 power meter...')
% if PM101_params.default
%     PM101 = THORLABSPM101(PM101_params.default);
% else
%     PM101 = THORLABSPM101(PM101_params.default, PM101_params.PM_ind, PM101_params.t_avg, PM101_params.t_timeout);
% end
% disp(newline)

try
    % Setup scanning positions
    axis1_range = linspace(center(1)-span(1), center(1)+span(1), sampling(1));
    axis2_range = linspace(center(2)-span(2), center(2)+span(2), sampling(2));
    axis3_range = linspace(center(3)-span(3), center(3)+span(3), sampling(3));

    % Begin scanning; for a given focus, scan laterally and build upwards
    % without wrapping
    disp('Begin scanning...')
    power_3D = [];
    table = [];
    for i2 = axis2_range % scan in focus
        disp('Go to FOCUS (axis 2): '+string(i2)+' mm')
        if Zaber_params.default
            Zaber.moveAbsolute(2, i2, Zaber_params.default);
        else
            Zaber.moveAbsolute(2, i2, Zaber_params.default, Zaber_params.velocity);
        end
        power_2D = [];
        for i3 = axis3_range % scan in y
            disp('Go to Y (axis 3): '+string(i3)+' mm')
            if Zaber_params.default
                Zaber.moveAbsolute(3, i3, Zaber_params.default);
            else
                Zaber.moveAbsolute(3, i3, Zaber_params.default, Zaber_params.velocity);
            end
            power_1D = [];
            for i1 = axis1_range % scan in x
                disp(' Go to X (axis 1): '+string(i1)+' mm')
                if Zaber_params.default
                    Zaber.moveAbsolute(1, i1, Zaber_params.default);
                else
                    Zaber.moveAbsolute(1, i1, Zaber_params.default, Zaber_params.velocity);
                end
                pause(1) % let the stages settle
%                 if PM101_params.default
%                     power = PM101.readPower(PM101_params.default);
%                 else
%                     power = PM101.readPower(PM101_params.default, PM101_params.t_update, PM101_params.N);
%                 end
                power = 0.0
                disp(newline)
                power_1D = [power_1D power];
                table = [table; [i1 i2 i3 power]];
            end
            power_2D = [power_2D; power_1D];
        end
        power_3D = [power_3D; power_2D];
    end
    power_3D = reshape(power_3D, sampling);
    disp(newline)

    % Disconnect devices
    Zaber.disconnect();
%     PM101.disconnect();
    disp(newline)

    % Generate data file
    disp('Generating data file...')
    csvwrite(filename_csv, table);
    disp(newline)

    % Generate plots
    disp('Generating power map plots...')
    for i=1:sampling(2)
        figure;
        imagesc(axis1_range, axis3_range, reshape(power_3D(:,i,:), [sampling(1) sampling(3)]));
        xlabel('x (mm)');
        ylabel('y (mm)');
        title('Focus = '+string(axis2_range(i))+' mm');
        colormap(gray);
        colorbar;
        set(gca, 'XDir','reverse');
        set(gca, 'YDir','normal');
        saveas(gcf, filename_root+'focus'+strrep(string(axis2_range(i)), '.', 'p')+'.png');
        close(gcf);
    end
    disp(newline)

    % Determine position of maximum power
    disp('Determining position of maximum power...')
    [power_max, ind_max] = max(power_3D(:));
    [ind_max_1, ind_max_2, ind_max_3] = ind2sub(size(power_3D), ind_max);
    position_max = [axis1_range(ind_max_1) axis2_range(ind_max_2) axis3_range(ind_max_3)];
    disp('Maximum power: '+num2str(power_max))
    disp('Maximum power position (in mm): '+string(num2str(position_max)))
    
    disp('End of run.')
catch exception
    Zaber.disconnect();
%     PM101.disconnect();
    rethrow(exception);  
    diary off
end

% Finish logging
diary off
end
            
            

