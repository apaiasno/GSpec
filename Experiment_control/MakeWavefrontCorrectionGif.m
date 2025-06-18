% Setup
zernike_corr = [[3 -32.9529]; [4 26.7214]; [5 73.4771]; [6 1.3653]; ...
    [7 -53.8629]; [8 51.0775]; [9 16.3461]; [10 -0.6583]; [11 0.4933]; ...
    [12 -33.5076]; [13 1.5508]; [14 11.5012] ...
];
notes = 'Scan for wavefront correction gif.';
zernike_base = false;
num_modes = size(zernike_corr);
num_modes = num_modes(1);
center = [21.632    20.0783    6.032];
span = [0.005, 0.01, 0.005];
sampling = [15 1 15];
Zaber_params.default = true;
PM101_params.default = true;
powers = [];
PSF_maps = [];
DM_maps = [];

% Collect data
dm = DM();
for i = 1:num_modes
    % Set up DM
    zernike_base = zernike_corr(1:i, :);
    dm.setZernike(zernike_base(:,1), zernike_base(:,2));
    w = dm.dm.width;
    shape = dm.shape;
    surface = [NaN; shape(1:w-2); NaN; shape(w-1:w^2 - w - 2); NaN; shape(w^2 - w - 1:end); NaN];
    surface = reshape(surface, w, w);
    % Run scan
    [position_max, power_max, axis1_range, axis2_range, axis3_range, power_3D] = ...
        scanXYZ_ThorlabsPM101(center, span, sampling, Zaber_params, PM101_params, notes);
    powers = [powers; power_max];
    PSF_maps = cat(3, PSF_maps, power_3D);
    DM_maps = cat(3, DM_maps, surface);
end

% Plot
title_size = 18;
label_size = 16;
tick_size = 14;
marker_size = 16;
power_min = min(PSF_maps, [], 'all');
power_max = max(PSF_maps, [], 'all');
DM_min = min(DM_maps, [], 'all');
DM_max = max(DM_maps, [], 'all');
cMap = interp1([0; 0.5; 1], [0 0 1; 1 1 1; 1 0 0], linspace(0, 1, 256)); % Define red-blue colormap
for i = 1:num_modes
    % Left figure
    figure('position', [0, 0, 1200, 500]);
    ax1 = subplot(1, 3, 1);
    zmode = zernike_corr(i, 1);
    amp = zernike_corr(i, 2);
    plot(zernike_corr(2:end, 1), powers(2:end), 'ko', 'MarkerSize', marker_size);
    hold on;
    if i >= 2
        plot(zernike_corr(i, 1), powers(i), 'o', 'MarkerSize', marker_size, 'Color', "#77AC30");
        scatter(zernike_corr(i, 1), powers(i), 15*marker_size, 'o', 'filled', 'MarkerFaceColor', "#77AC30");
    end
    xlabel('Zernike mode', 'FontSize', label_size);
    ylabel('Maximum power (W)', 'FontSize', label_size);
    if i == 1
        title('No correction', ...
            'Units', 'normalized', 'Position', [0.5, 1.1, 0], ...
            'FontSize', title_size); 
    else
        title(['Zernike mode = \color{DarkGreen}'+string(zmode)+newline+'\color{black}RMS amplitude = \color{DarkGreen}'+string(round(amp,1))+' nm'], ...
            'Units', 'normalized', 'Position', [0.5, 1.1, 0], ...
            'FontSize', title_size);   
    end
    pbaspect([1 1 1]);
    ax = gca;
    ax.FontSize = tick_size; 
    
    % Middle figure
    DM_i = DM_maps(:, :, i);
    ax2 = subplot(1, 3, 2);
    ax2.Position(1)=0.39;
    p = imagesc(DM_i);
    axis image off
    set(p, 'AlphaData', ~isnan(DM_i));
    colormap(ax2, cMap);
    colorbar;
    caxis([DM_min, DM_max]);
    ax = gca;
    ax.FontSize = tick_size; 
    title('DM map', 'Units', 'normalized', 'Position', [0.5, 1.1, 0],...
        'FontSize', title_size);
    pbaspect([1 1 1]);
    
    % Right figure
    Zi = PSF_maps(:, :, i);    
    ax3 = subplot(1, 3, 3);
    imagesc(axis1_range, axis3_range, Zi);
    xlabel('x (mm)', 'FontSize', label_size);
    ylabel('y (mm)', 'FontSize', label_size);
    colormap(ax3, gray);
    colorbar;
    caxis([power_min, power_max]);
    set(gca, 'XDir','reverse');
    set(gca, 'YDir','normal');
    title('Coupling map', 'Units', 'normalized', 'Position', [0.5, 1.1, 0],...
        'FontSize', title_size);
    ax = gca;
    ax.FontSize = tick_size; 
    pbaspect([1 1 1]);
    hold off;
    
    % For making gif
    drawnow
    F(i) = getframe(gcf);
    hold off
    
    close(gcf);
end

% create the video writer and set fps
writerObj = VideoWriter(string(pwd)+'\Experiment_control\gifs\WavefrontCorrection.avi',...
    'Uncompressed AVI');
writerObj.FrameRate = 1.5;
% open the video writer
open(writerObj);
% write the frames to the video
for i=1:length(F)
    % convert the image to a frame
    frame = F(i) ;    
    writeVideo(writerObj, frame);
end
% close the writer object
close(writerObj);
