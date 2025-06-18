function [position_max, power_max, axis1_range, axis3_range, Zernike_range, power_3D] ...
    = scanZernike_FEMTO(zernike_mode, DC, center, span, sampling, ...
    focus, Zaber_params)
% Scans Zabers in XY space and amplitude of Zernike mode applied to DM; records the power at
% each position with the FEMTO photoreceiver.
% Inputs:
% zernike_mode: pair of integers referring to Zernike mode to apply to DM
% DC: either 1D array or false. If 1D array, defines voltages  for each actuator that
% points are defined relative to; if false, points are defined relative to manufacturer's 
% flat map.
% center: array of 3 values associated with 2-axis (X and Y, axes 1 and 3) position (in mm) 
% and Zernike amplitude on which to center the scan 
% span: array of 3 values associated with 2-axis (in mm) and Zernike amplitude range on either
% side of center over which to scan
% sampling: array of 3 values associated with number of samples to take
% along each of the 2 axes and Zernike mode scan range
% focus: float for position of focus
% Zaber_params: struct with parameters for using the Zaber translation
% stages. Required: default. Optional: COMport, velocity.
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

ns = zernike_mode(1);
ms = zernike_mode(2);
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
disp(filename_root)
disp('Axis 1 (x): '+string(center(1)-span(1))+' mm to '+string(center(1)+span(1))+' mm')
disp('Axis 3 (y): '+string(center(2)-span(2))+' mm to '+string(center(2)+span(2))+' mm')
disp('Zernike mode ('+string(ns)+', '+string(ms)+') : '+string(center(3)-span(3)) ...
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

% setup LUCI10
luci10 = LUCI10(true);
luci10.setGain(false, 3, 1, 1); % false, gain, 1 = low noise, 1 = DC

% Setup Picoscope 
disp('Setting up Picoscope...')
pico = PICOSCOPE2204A();
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
    Zaber.moveAbsolute(2, focus, Zaber_params.default)

    % Begin scanning; for a given focus, scan laterally and build upwards
    % without wrapping
    disp('Begin scanning...')
    power_3D = [];
    table = [];
    i_img = 0;
    diary off
    diary_str = '';
    for iZ = Zernike_range % scan in Zernike mode amplitude
        disp('Go to Zernike mode ('+string(ns)+', '+string(ms)+') : '+string(iZ))
        diary_str = diary_str + "Go to Zernike mode ("+string(ns)+", "+string(ms)+") : "+string(iZ)+"\n";
        points = DM.MakeZernikePoints(12, iZ, ns, ms, 12, [0,0]);
        dm.setPoints(points, 0, DC);
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
                disp(' Go to X (axis 1): '+string(i1)+' mm')
                if Zaber_params.default
                    move_str = Zaber.moveAbsolute(1, i1, Zaber_params.default);
                else
                    move_str = Zaber.moveAbsolute(1, i1, Zaber_params.default, Zaber_params.velocity);
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
        % Generate plot
        disp('Generating power map plot...')
        figure;
        imagesc(axis1_range, axis3_range, power_2D);
        xlabel('x (mm)');
        ylabel('y (mm)');
        title('Zernike ('+string(ns)+', '+string(ms)+') = '+string(iZ));
        colormap(gray);
        colorbar;
        set(gca, 'XDir','reverse');
        set(gca, 'YDir','normal');
        saveas(gcf, filename_root+'zernike'+string(i_img)+'.png');
        close(gcf);
        i_img = i_img + 1;

        disp(newline)
        
        power_3D = cat(3, power_3D, power_2D);
    end
    disp(newline)

    % Disconnect devices
    Zaber.disconnect();
    PM101.disconnect();
    disp(newline)

    % Generate data file
    disp('Generating data file...')
    csvwrite(filename_csv, table);
    disp(newline)

%     Generate plots
%     disp('Generating power map plots...')
%     for i=1:sampling(2)
%         figure;
%         imagesc(axis1_range, axis3_range, reshape(power_3D(:,i,:), [sampling(1) sampling(3)]));
%         xlabel('x (mm)');
%         ylabel('y (mm)');
%         title('Focus = '+string(axis2_range(i))+' mm');
%         colormap(gray);
%         colorbar;
%         set(gca, 'XDir','reverse');
%         set(gca, 'YDir','normal');
%         saveas(gcf, filename_root+'focus'+strrep(string(axis2_range(i)), '.', 'p')+'.png');
%         close(gcf);
%     end
%     disp(newline)

    % Determine position of maximum power
    disp('Determining position of maximum power...')
    [power_max, ind_max] = max(power_3D(:));
    [ind_max_1, ind_max_2, ind_max_3] = ind2sub(size(power_3D), ind_max);
    position_max = [axis1_range(ind_max_1) axis3_range(ind_max_2) Zernike_range(ind_max_3)];
    disp('Maximum power (in '+string(PM101.test_meter.meterPowerUnit)+'): '+num2str(power_max))
    disp('Maximum power position (in mm): '+string(num2str(position_max)))
    
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
            
            

