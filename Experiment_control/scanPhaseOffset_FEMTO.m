function [axis1_range, axis3_range, offset_range, power_3D] ...
    = scanPhaseOffset_FEMTO(wavelength, zernike_corr, center, span, sampling, ...
    focus, Zaber_params, notes)
% Scans Zabers in XY space and phase offset scaling applied to DM; records the power at
% each position with the FEMTO photoreceiver.
% Inputs:
% wavelength: float associated with assumed wavelength of laser in nm
% zernike_corr: either 1D array or false. If 1D array, defines voltages  for each actuator that
% points are defined relative to; if false, points are defined relative to manufacturer's 
% flat map.
% center: array of 3 values associated with 2-axis (X and Y, axes 1 and 3) position (in mm) 
% and phase offset scaling (1 corresponds to wavelength/4 piston applied to each half of DM)
% on which to center the scan 
% span: array of 3 values associated with 2-axis (in mm) and phase offset range on either
% side of center over which to scan
% sampling: array of 3 values associated with number of samples to take
% along each of the 2 axes and phase offset scan range
% focus: float for position of focus
% Zaber_params: struct with parameters for using the Zaber translation
% stages. Required: default. Optional: COMport, velocity.
% notes: string with notes about the scan
%
% Outputs:
% axis1_range: 1D array of positions scanned by axis 1
% axis3_range: 1D array of positions scanned by axis 3
% offset_range: 1D array of phase offset scalings scanned by DM 
% power_3D: 3D array of powers measured at each position
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#.log: log file
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#.csv: data 
% file of Zaber positions and measured power
% logs/yyyymmdd/scan_center_#_#_#_span_#_#_#_sampling_#_#_#_run#_phaseOffset#.png: plot 
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
disp('Phase offset scaling ('+string(wavelength)+' nm) : '+string(center(3)-span(3)) ...
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
        offset_range = [center(3)];
    else
        offset_range = linspace(center(3)-span(3), center(3)+span(3), sampling(3));
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
    diary off
    for iOff_ind = 1:length(offset_range) % scan in phase offset scaling
        iOff = offset_range(iOff_ind);
        diary_str = '';
        disp('Go to phase offset: '+string(iOff))
        diary_str = diary_str + "Go to offset: "+string(iOff)+"\n";
        flat = zeros(12, 12);
        flat(:,1:6) = -(iOff * wavelength)/4;
        flat(:,7:12) = (iOff * wavelength)/4;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        shape = importdata('C:\Program Files\Boston Micromachines\Shapes\17BW007#083_FLAT_MAP_COMMANDS.txt');
        w = dm.dm.width;
        surface_dm = [0.5; shape(1:w-2); 0.5; shape(w-1:w^2 - w - 2); 0.5; shape(w^2 - w - 1:end); 0.5];
        surface_dm = reshape(surface_dm, w, w);
        flat = flat + surface_dm;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        dm.setZernike([corr_modes], [corr_amps], flat);
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
                table = [table; [i1 i3 iOff power gain]];
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
        title('Phase offset scaling ('+string(wavelength)+' nm) = '+string(iOff))
        colormap(gray);
        colorbar;
%         set(gca, 'XDir','reverse');
        set(gca, 'YDir','normal');
        saveas(gcf, filename_root+'phaseOffset'+string(i_img)+'.png');
        close(gcf);
        
        % Generate gain plot
        disp('Generating gain map plot...')
        figure;
        imagesc(axis1_range, axis3_range, gain_2D);
        axis image; axis square;
        xlabel('x (mm)');
        ylabel('y (mm)');
        title('Phase offset scaling ('+string(wavelength)+' nm) = '+string(iOff))
        colormap(jet);
        colorbar;
        set(gca, 'XDir','reverse');
        set(gca, 'YDir','normal');
        filename_root_gain = log_dir+scan_str+"_gain_"+center_str+span_str+sampling_str;
        saveas(gcf, filename_root_gain+'phaseOffset'+string(i_img)+'.png');
        close(gcf);
        i_img = i_img + 1;
        
        % Calculate maximum power at given amplitude
        power_3D = cat(3, power_3D, power_2D);
        diary off
    end
    diary(filename_log)
    disp(newline)           

    % Disconnect devices
    pico.disconnect();
    Zaber.disconnect();
    luci10.disconnect();

    % Generate data file
    disp('Generating data file...')
    column_titles = {'x' 'y' 'phaseOffset' 'power' 'gain'};
    C = [column_titles; num2cell(table)];
    writecell(C, filename_csv);
    disp(newline)
    
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
            
            

