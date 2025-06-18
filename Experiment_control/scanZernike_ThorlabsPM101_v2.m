function [amp_opt, position_max, power_max, axis1_range, axis3_range, Zernike_range, power_3D] ...
    = scanZernike_ThorlabsPM101_v2(zernike_mode, zernike_corr, center, span, sampling, ...
    focus, flat, Zaber_params, PM101_params, notes)
% Scans Zabers in XY space and amplitude of Zernike mode applied to DM; records the power at
% each position with the Thorlabs PM101.
% Inputs:
% zernike_mode: integer referring to Zernike mode OSA index to scan with DM
% zernike_corr:  false (no correction); or 2D array (n x 2) with pairs of values indicating corrective 
% Zernike mode OSA indices and corresponding amplitudes to keep fixed throughout the scan.
% center: array of 3 values associated with 2-axis (X and Y, axes 1 and 3) position (in mm) 
% and Zernike amplitude on which to center the scan 
% span: array of 3 values associated with 2-axis (in mm) and Zernike amplitude range on either
% side of center over which to scan
% sampling: array of 3 values associated with number of samples to take
% along each of the 2 axes and Zernike mode scan range
% focus: float for position of focus
% flat: 2D surface array (in units of nm) to describe base DM map on top of
% which Zernike modes are applied
% Zaber_params: struct with parameters for using the Zaber translation
% stages. Required: default. Optional: COMport, velocity.
% PM101_params: struct with parameters for using the Thorlabs PM101 power
% meter. Required: default. Optional: PM_ind, t_avg, t_timeout, t_update,
% N.
% notes: string with notes about the scan
%
% Outputs:
% position_max: 1D array of 3 values associated with position of maximum measured
% power
% power_max: float value of maximum power measured
% Zernike_range: 1D array of positions scanned by DM in Zernike mode
% amplitude
% axis1_range: 1D array of positions scanned by axis 1
% axis3_range: 1D array of positions scanned by axis 3
% power_3D: 3D array of powers measured at each position
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
    center_str = center_str + (strrep(strrep(string(center(i)), '.', 'p'), '-', 'n')+'_');
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
disp(filename_root)
disp('Notes: '+string(notes))
disp('Axis 1 (x): '+string(center(1)-span(1))+' mm to '+string(center(1)+span(1))+' mm')
disp('Axis 3 (y): '+string(center(2)-span(2))+' mm to '+string(center(2)+span(2))+' mm')
disp('Zernike mode ('+string(zernike_mode)+') : '+string(center(3)-span(3)) ...
    +' to '+string(center(3)+span(3)))
disp(newline)

% Setup Zaber translation devices
disp('Setting up Zaber translation devices...')
if Zaber_params.default
    Zaber = ZABER(Zaber_params.default);
else
    Zaber = ZABER(Zaber_params.default, Zaber_params.COMport);
end
disp(newline)

% Setup Thorlabs PM101 power meter 
disp('Setting up Thorlabs PM101 power meter...')
if PM101_params.default
    PM101 = THORLABSPM101(PM101_params.default);
else
    PM101 = THORLABSPM101(PM101_params.default, PM101_params.PM_ind, PM101_params.t_avg, PM101_params.t_timeout);
end
disp(newline)

% Setup Boston Micromachines Multi-DM
dm = DM();

try
    % Setup scanning positions
    if sampling(1) == 1
        axis1_range = [center(1)];
    else
        axis1_range = linspace(center(1)-span(1), center(1)+span(1), sampling(1));
    end
    
    if sampling(2) == 1
        axis3_range = [center(2)];
    else
        axis3_range = linspace(center(2)-span(2), center(2)+span(2), sampling(2));
    end
    
    if sampling(3) == 1
        Zernike_range = [center(3)];
    else
        Zernike_range = linspace(center(3)-span(3), center(3)+span(3), sampling(3));
    end
    
    % Move to optimal focus
    Zaber.moveAbsolute(2, focus, Zaber_params.default);
    
    % Set up fixed Zernike corrections to apply throughput scan
    if ~zernike_corr
        corr_modes = [];
        corr_amps = [];
    else
        corr_modes = zernike_corr(:, 1);
        corr_amps = zernike_corr(:, 2);    
    end
    
    % Begin scanning; for a given focus, scan laterally and build upwards
    % without wrapping
    disp('Begin scanning...')
    power_3D = [];
    table = [];
    i_img = 0;
    amps_max = [];
    for iZ_ind = 1:length(Zernike_range) % scan in Zernike mode amplitude
        iZ = Zernike_range(iZ_ind);
        diary_str = '';
        disp('Go to Zernike mode ('+string(ns)+', '+string(ms)+') : '+string(iZ))
        diary_str = diary_str + "Go to Zernike mode ("+string(ns)+", "+string(ms)+") : "+string(iZ)+"\n";
        dm.setZernike([corr_modes; zernike_mode], [corr_amps; iZ], flat);
        power_2D = [];
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
                if PM101_params.default
                    power = PM101.readPower(PM101_params.default);
                else
                    power = PM101.readPower(PM101_params.default, PM101_params.t_update, PM101_params.N);
                end
                disp(newline)
                power_1D = [power_1D power];
                table = [table; [iZ i1 i3 power]];
            end
            power_2D = [power_2D; power_1D];
        end
        fileID = fopen(filename_log,'A');
        fprintf(fileID, diary_str);
        fclose('all');
        diary(filename_log)
        
        % Generate plot
        disp('Generating power map plot...')
        figure;
        imagesc(axis1_range, axis3_range, power_2D);
        xlabel('x (mm)');
        ylabel('y (mm)');
        title('Zernike ('+string(zernike_mode)+') = '+string(iZ)+' nm');
        colormap(gray);
        colorbar;
        set(gca, 'XDir','reverse');
        set(gca, 'YDir','normal');
        saveas(gcf, filename_root+'zernike'+string(i_img)+'.png');
        close(gcf);
        i_img = i_img + 1;
        
        % Calculate maximum power at given amplitude
        amps_max = [amps_max max(power_2D, [], 'all')];        
        power_3D = cat(3, power_3D, power_2D);
        diary off
    end
    diary(filename_log)
    disp(newline) 

    % Disconnect devices
    Zaber.disconnect();
    PM101.disconnect();
    disp(newline)

    % Generate data file
    disp('Generating data file...')
    column_titles = {'x' 'y' 'zernike' 'power'};
    C = [column_titles; num2cell(table)];
    writecell(C, filename_csv);
    disp(newline)

    % Generate plot of maximum power vs. Zernike mode amplitude
    % Optimize metric for this Zernike mode
    disp('Generating optimization plot...')
    p = polyfit(Zernike_range, amps_max, 2);
    amp_opt = -p(2)/(2*p(1));
    if (amp_opt < min(Zernike_range)) || (amp_opt > max(Zernike_range))
        amp_opt = 0;
    end    
    % Make plot
    figure;
    plot(Zernike_range, amps_max, 'o');
    hold on;
    plot(Zernike_range, polyval(p, Zernike_range));
    xline(amp_opt);
    xlabel('RMS amplitude (nm)');
    ylabel('Maximum power (W)');
    pbaspect([1 1 1]);
    title(sprintf('Zernike mode = %d, amplitude = %0.3e', zernike_mode, amp_opt));    
    saveas(gcf, filename_root+'optimization.png');

    % Determine position of maximum power
    disp('Determining position of maximum power...')
    [power_max, ind_max] = max(power_3D(:));
    [ind_max_1, ind_max_2, ind_max_3] = ind2sub(size(power_3D), ind_max);
    position_max = [axis1_range(ind_max_2) axis3_range(ind_max_1) Zernike_range(ind_max_3)];
    disp("Maximum power (in "+string(PM101.test_meter.meterPowerUnit)+"): "+num2str(power_max))
    disp("Maximum power position (in mm): "+string(num2str(position_max)))
    disp("Optimal amplitude (in nm): "+string(num2str(amp_opt)))
    
    disp('End of run.')
catch exception
    Zaber.disconnect();
    PM101.disconnect();
    dm.disconnect();
    rethrow(exception);  
    diary off
end

% Finish logging
diary off
end
            
            

