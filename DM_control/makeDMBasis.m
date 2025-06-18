function DM_basis = makeDMBasis(t_cam, t_pause, value)
% Makes a deformable mirror basis matrix.
% Inputs:
% offset: float, float between 0 and 0.5, represents value added to actuator 
% in its flat state
% 
% Outputs:
% DM_basis: matrix, basis images for each actuator

% Properties
num_actuators = 140;
num_pixels = 768 * 1024;

% Take flat image
shape = MakeShape([1 value]);
SetShape(shape, 0);
pause(t_pause)
total = 0;
while total == 0
    img_flat = CamAcquisition(t_cam);
    total = sum(img_flat, 'all');
end

% Make image deviation from flat for each actuator
DM_basis = NaN(num_pixels, 140);
for i = 1:num_actuators
    disp('Actuator: '+string(i));
    shape = MakeShape([i value]);
    SetShape(shape, 0);
    pause(t_pause)
    total = 0;
    while total == 0
        img = CamAcquisition(t_cam);
        total = sum(img, 'all');
    end
    img = (img-img_flat)/value;
    save('DM_basis/Actuator_'+string(i)+'_offset'+string(value)+'.mat', 'img')
    disp(' ')
    pixels = numel(img);
    img = img.';
    img = img(:);
    DM_basis(:, i) = img;
end
save('DM_basis/DM_basis_offset'+string(value)+'.mat', 'img');