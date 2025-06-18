figure;
imagesc(axis1_range, axis3_range, power_3D);
axis image; axis square;
xlabel('x (mm)');
ylabel('y (mm)');
colormap(gray);
colorbar;
daspect([1 1 1]);
viscircles([8.1 16.5; 5.8 16.5], [0.7; 0.7]);
[X, Y] = meshgrid(axis1_range, axis3_range);
left = ((X-5.8).^2 + (Y-16.5).^2 < 0.7.^2);
right = ((X-8.1).^2 + (Y-16.5).^2 < 0.7.^2);
disp('Left:')
sum(power_3D(left))
disp('Right:')
sum(power_3D(right))
disp('Center:')
[(8.1+5.8)/2 16.5]