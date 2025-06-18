function coefs_opt = EyeDoctor(DM_size, coef_max, coef_samp, n_max, rad_in, rad_out, cenxy, t_exp)
% Optimize Zernike modes as a function of modal coefficient amplitudes.
% Inputs:
% DM_size: integer, size of deformable mirror
% coef_max: float, maximum coefficient to test Zernike mode amplitudes
% coef_samp: integer, number of coefficient samplings to test between 0 and
% maximum allowed coefficient value
% n_max: integer, maximum radial degree of Zernike modes to optimize
% rad_in: integer, radius of "core" in pixels for either Core Sum or Ring
% Sum metric
% rad_out: integer or NaN, outer radius of "ring" in pixels if using Ring
% Sum metric
% cenxy: 1x2 array or NaN, (x,y) coordinates of initial guess for centroid
% t_exp: float, exposure time in ms
%
% Outputs:
% coefs_opt: 1 x n_max*(n_max+1)/2 array, optimized amplitudes for each
% Zernike mode considered.

coefs_opt = [];
ns = [];
ms = [];
i = 1;

coefs_range = -coef_max:coef_max/coef_samp:coef_max;

% Iterate over radial degrees
for n = 0:n_max
    % Iterate over modes for each radial degree
    for m = -n:2:n
        ns(end+1) = n;
        ms(end+1) = m;
        % Iterate over amplitudes for each radial degree
        metrics = NaN * ones(1, numel(coefs_range)); 
        disp('n = '+string(n)+', m = '+string(m))
        for coef_i = 1:numel(coefs_range)
            coef = coefs_range(coef_i);
            coefs_test = [coefs_opt coef]; % optimal + test coefficients
            aber_sizes = DM_size * ones(size(coefs_test)); % assume aberration fills DM
            offsets = zeros(numel(coefs_test), 2); % assume no offset
            % Set DM to optimal shape thus far with test mode amplitude and
            % compute metric
            DM_shape = MakeZernikeCombined(aber_sizes, coefs_test, ns, ms, DM_size, offsets);
            SetShape(DM_shape, 0);
            image = CamAcquisition(t_exp);
            image = double(image);
            if isnan(rad_out)
                [metric, ~, ~] = CoreSum(image, rad_in, cenxy);
                metrics(coef_i) = metric;
            else
                [metric, ~, ~] = RingSum(image, rad_in, rad_out, cenxy);
                metrics(coef_i) = metric;
            end
        end
        % Optimize metric for this Zernike mode
        p = polyfit(coefs_range, metrics, 2);
        coef_opt = -p(2)/(2*p(1));
        if abs(coef_opt) > coef_max
            coef_opt = 0;
        end
        coefs_opt(end+1) = coef_opt;        
               
        % Left plot
        subplot(1, 2, 1)
        plot(coefs_range, metrics, 'o')
        hold on
        plot(coefs_range, polyval(p, coefs_range))
        xline(coef_opt)        
        xlabel('Amplitude')
        ylabel('Metric')
        pbaspect([1 1 1])
        xlm = xlim;
        ylm = ylim;
        title(sprintf('n = %d, m = %d, amplitude = %0.3e', n, m, coef_opt), ...
            'Units', 'normalized', 'Position', [0.5, 1.1])

        % Right plot
        subplot(1, 2, 2)
        aber_sizes = DM_size * ones(size(coefs_opt)); % assume aberration fills DM
        offsets = zeros(numel(coefs_opt), 2); % assume no offset
        % Set DM to optimal shape thus far with test mode amplitude and
        % compute metric
        DM_shape = MakeZernikeCombined(aber_sizes, coefs_opt, ns, ms, DM_size, offsets);
        SetShape(DM_shape, 0);
        image = CamAcquisition(t_exp);
%         [image_y, image_x] = size(image);
        [~, cenx, ceny] = CoreSum(double(image), rad_in, cenxy);
        imshow(image)
        colorbar
%         colormap default
%         set(gca,'ColorScale','log')
%         set(cbr,'YTick', {10, 100, 255})

        hold on
        theta = 0 : (2 * pi / 10000) : (2 * pi);
        pline_x = rad_in * cos(theta) + cenx;
        pline_y = rad_in * sin(theta) + ceny;
        k = ishold;
        plot(pline_x, pline_y, 'r-', 'LineWidth', 1);
        if ~isnan(rad_out)
            pline_x = rad_out * cos(theta) + cenx;
            pline_y = rad_out * sin(theta) + ceny;
            k = ishold;
            plot(pline_x, pline_y, 'r-', 'LineWidth', 1);
        end
        xlim([cenx-5*rad_in, cenx+5*rad_in]);
        ylim([ceny-5*rad_in, ceny+5*rad_in]);
        pbaspect([1, 1, 1])
        title('Optimized intensity map', 'Units', 'normalized', ...
            'Position', [0.5, 1.1])     
        drawnow
        F(i) = getframe(gcf);
        hold off
        clf
        i = i + 1;
    end
end
% create the video writer with 1 fps
writerObj = VideoWriter(strcat('DM_movies/EyeDoctor_radIn', num2str(rad_in),'_radOut', num2str(rad_out), '.avi'));
writerObj.FrameRate = 0.8;
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

disp('n | m | amplitude')
disp([ns' ms' coefs_opt'])
end



