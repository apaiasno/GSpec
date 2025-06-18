% Read in data
data_dir = string(pwd) + '\logs\20240426\';
scan = 'scan4_*.csv';
zmode = 18;
filename = dir(data_dir + scan);
filename = data_dir + filename.name;
T = readtable(filename);
amps = unique(T.(1));
maps = [];
powers = [];
power_min = min(T.(4));
power_max = max(T.(4));

x = linspace(min(T.(2)), max(T.(2)), 15);
y = linspace(min(T.(3)), max(T.(3)), 15);

% Extract data for each amplitude and store
for i = 1:numel(amps)
    t = T(T.(1) == amps(i), :);
    X = t.(2);
    Y = t.(3);
    Z = t.(4);
    powers = [powers; max(Z)];
    
    [Xi,Yi] = meshgrid(x,y);
    Zi = griddata(X,Y,Z,Xi,Yi);
    maps = cat(3, maps, Zi);    
end

title_size = 18;
label_size = 16;
tick_size = 14;
marker_size = 16;
for i = 1:numel(amps)
    % Left figure
    figure('position', [0, 0, 1000, 500]);
    tiledlayout(1, 2);
    nexttile
    plot(amps, powers, 'o', 'MarkerSize', marker_size);
    hold on;
    plot(amps(i), powers(i), 'ro', 'MarkerSize', marker_size);
    scatter(amps(i), powers(i), 15*marker_size, 'ro', 'filled');
    xlabel('RMS amplitude (nm)', 'FontSize', label_size);
    ylabel('Maximum power (W)', 'FontSize', label_size);
    pbaspect([1 1 1]);
    title('Zernike mode = '+string(zmode)+', RMS amplitude = \color{red}'+string(amps(i))+' nm', ...
        'Units', 'normalized', 'Position', [0.5, 1.1, 0], ...
        'FontSize', title_size);   
    ax = gca;
    ax.FontSize = tick_size; 
    
    % Right figure
    Zi = maps(:, :, i);    
    nexttile
    imagesc(x, y, Zi);
    xlabel('x (mm)', 'FontSize', label_size);
    ylabel('y (mm)', 'FontSize', label_size);
    colormap(gray);
    colorbar;
    caxis([power_min, power_max])
    set(gca, 'XDir','reverse');
    set(gca, 'YDir','normal');
    title('Coupling map', 'Units', 'normalized', 'Position', [0.5, 1.1, 0],...
        'FontSize', title_size);
    ax = gca;
    ax.FontSize = tick_size; 
    pbaspect([1, 1, 1])
    hold off;
    
    % For making gif
    drawnow
    F(i) = getframe(gcf);
    hold off
    
    close(gcf);
end

% create the video writer and set fps
writerObj = VideoWriter(string(pwd)+'\Experiment_control\gifs\ZernikeOptimization_Z'+string(zmode)+'.avi',...
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



