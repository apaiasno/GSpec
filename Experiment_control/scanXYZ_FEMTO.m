function [position_max, power_max, axis1_range, axis2_range, axis3_range, power_3D] = scanXYZ_FEMTO(center, span, sampling, Zaber_params, notes)
% Scans Zabers in XYZ space and records the power at each position with the
% FEMTO photoreceiver.
% Inputs:
% center: array of 3 values associated with 3-axis position (in mm) on which to 
% center the scan 
% span: array of 3 values associated with 3-axis range (in mm) on either side
% of center over which to scan
% sampling: array of 3 values associated with number of samples to take
% along each of the 3 axes
% Zaber_params: struct with parameters for using the Zaber translation
% stages. Required: default. Optional: COMport, velocity.
% notes: string with notes about the scan
%
% Outputs:
% position_max: 1D array of 3 values associated with position of maximum measured
% power
% power_max: float value of maximum power measured
% axis1_range: 1D array of positions scanned by axis 1
% axis2_range: 1D array of positions scanned by axis 2
% axis3_range: 1D array of positions scanned by axis 3
% power_3D: 3D array of powers measured at each position
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#.log: log file
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#.csv: data 
% file of Zaber positions and measured power
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#_z#.png: plot 
% of scanned power map

clc;
close all;

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
scan_num = numel(dir('logs\'+string(yyyymmdd(datetime('today')))+'\scan*center*span*sampling*.log'));
scan_str = 'scan'+string(scan_num)+'_';
filename_root = log_dir+scan_str+center_str+span_str+sampling_str;
filename_log = filename_root+'.log';
filename_csv = filename_root+'.csv';

diary(filename_log)
disp(filename_root);
disp('Notes: '+string(notes))
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

% setup LUCI10
luci10 = LUCI10(true);
luci10.setGain(false, 3, 1, 1); % false, gain, 1 = low noise, 1 = DC

% Setup Picoscope 
disp('Setting up Picoscope...')
pico = PICOSCOPE2204A();
disp(newline)

try
    % Setup scanning positions
    if sampling(1) == 1
        axis1_range = [center(1)];
    else
        axis1_range = linspace(center(1)-span(1), center(1)+span(1), sampling(1));
    end
    
    if sampling(2) == 1
        axis2_range = [center(2)];
    else
        axis2_range = linspace(center(2)-span(2), center(2)+span(2), sampling(2));
    end
    
    if sampling(3) == 1
        axis3_range = [center(3)];
    else
        axis3_range = linspace(center(3)-span(3), center(3)+span(3), sampling(3));
    end

    % Begin scanning; for a given focus, scan laterally and build upwards
    % without wrapping
    disp('Begin scanning...')
    power_3D = [];
    table = [];
    i_img = 0;
    diary off
    for i2_ind = 1:length(axis2_range) % scan in focus
        i2 = axis2_range(i2_ind);
        diary_str = '';
        disp("Go to FOCUS (axis 2), "+string(i2_ind)+"/"+string(length(axis2_range)) ...
            +': '+string(i2)+' mm')
        diary_str = diary_str + "Go to FOCUS (axis 2): "+string(i2)+" mm \n";
        if Zaber_params.default
            load("Zaber_defaults.mat", "velocity");
            move_str = Zaber.moveAbsolute(2, i2, false, velocity, false);
            diary_str = diary_str + move_str + " \n";
        else
            move_str = Zaber.moveAbsolute(2, i2, Zaber_params.default, Zaber_params.velocity, ...
                false);
            diary_str = diary_str + move_str + " \n";
        end
        power_2D = [];
        gain_2D = [];
        for i3_ind = 1:length(axis3_range) % scan in y
            i3 = axis3_range(i3_ind);
            disp('Row: '+string(i3_ind)+'/'+string(length(axis3_range)))
            diary_str = diary_str + "Go to Y (axis 3): "+string(i3)+" mm \n";
            if Zaber_params.default
                load("Zaber_defaults.mat", "velocity");
                move_str = Zaber.moveAbsolute(3, i3, false, velocity, false);
                diary_str = diary_str + move_str + " \n";
            else
                move_str = Zaber.moveAbsolute(3, i3, Zaber_params.default, ...
                    Zaber_params.velocity, false);
                diary_str = diary_str + move_str + " \n";
            end
            power_1D = [];
            gain_1D = [];
            for i1 = axis1_range % scan in x
                diary_str = diary_str + "Go to X (axis 1): "+string(i1)+" mm \n";
                if Zaber_params.default
                    load("Zaber_defaults.mat", "velocity");
                    move_str = Zaber.moveAbsolute(1, i1, false, velocity, false);
                    diary_str = diary_str + move_str + " \n";
                else
                    move_str = Zaber.moveAbsolute(1, i1, Zaber_params.default, ...
                        Zaber_params.velocity, false);
                    diary_str = diary_str + move_str + " \n";
                end
%                 pause(0.05) % let the stages settle
                [power, gain] = pico.autoReadPicoscope(luci10);
                diary_str = diary_str + sprintf('Power: %.10f, gain: %d\r', power, gain);
                power_1D = [power_1D power];
                gain_1D = [gain_1D gain];
                table = [table; [i1 i2 i3 power gain]];
            end
            power_2D = [power_2D; power_1D];
            gain_2D = [gain_2D; gain_1D];
        end
        fileID = fopen(filename_log,'A');
        fprintf(fileID, diary_str);
        fclose('all');
        diary(filename_log)
        
        % Generate power plot
        disp('Generating power map plot...')
        figure;
        imagesc(axis1_range, axis3_range, power_2D);
        axis image; axis square;
        xlabel('x (mm)');
        ylabel('y (mm)');
        title('Focus = '+string(i2)+' mm');
        colormap(gray);
        colorbar;
%         set(gca, 'XDir','reverse');
        set(gca, 'YDir','normal');
        saveas(gcf, filename_root+'focus'+string(i_img)+'.png');
        close(gcf);
        
        % Generate gain plot
        disp('Generating gain map plot...')
        figure;
        imagesc(axis1_range, axis3_range, gain_2D);
        axis image; axis square;
        xlabel('x (mm)');
        ylabel('y (mm)');
        title('Focus = '+string(i2)+' mm');
        colormap(jet);
        colorbar;
%         set(gca, 'XDir','reverse');
        set(gca, 'YDir','normal');
        filename_root_gain = log_dir+scan_str+"_gain_"+center_str+span_str+sampling_str;
        saveas(gcf, filename_root_gain+'focus'+string(i_img)+'.png');
        i_img = i_img + 1;
        close(gcf);

        disp(newline)
        
        power_3D = cat(3, power_3D, power_2D);
        diary off
    end
    diary(filename_log)
    disp(newline)

    % Disconnect devices
    pico.disconnect();
    Zaber.disconnect();
    luci10.disconnect();
    disp(newline)

    % Generate data file
    disp('Generating data file...')
    column_titles = {'x' 'focus' 'y' 'power' 'gain'};
    C = [column_titles; num2cell(table)];
    writecell(C, filename_csv);
    disp(newline)

    % Determine position of maximum power
    disp('Determining position of maximum power...')
    [power_max, ind_max] = max(power_3D(:));
    [ind_max_1, ind_max_2, ind_max_3] = ind2sub(size(power_3D), ind_max);
    position_max = 'cat';
    position_max = [axis1_range(ind_max_2) axis2_range(ind_max_3) axis3_range(ind_max_1)];
    disp("Maximum power: "+num2str(power_max))
    disp("Maximum power position (in mm): "+string(num2str(position_max)))
    
    disp('End of run.')
catch exception
    pico.disconnect();
    Zaber.disconnect();
    luci10.disconnect();
    diary off
    rethrow(exception);  
end

% Finish logging
diary off
end
            
            

