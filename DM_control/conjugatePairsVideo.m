function conjugatePairsVideo(offset)
% Makes a video of the conjugate pair images for a given offset.
% Inputs:
% offset: float, float between 0 and 0.5, represents value added to actuator 
% in its flat state
% 
% Outputs:
% Video: DM_movies/conjugatePairs_offset*.avi

for i = 1:140
    img1 = load('conjugatePairs/Actuator_'+string(i)+'_offset'+string(offset)+'_pos.mat');
    img2 = load('conjugatePairs/Actuator_'+string(i)+'_offset'+string(offset)+'_neg.mat');
    figure(1)  
    imshow([img1.img, img2.img])
    F(i) = getframe(gcf) ;
    drawnow
end
% create the video writer with 1 fps
writerObj = VideoWriter('DM_movies/conjugatePairs_offset_FP_'+string(offset)+'.avi');
writerObj.FrameRate = 10;
% set the seconds per image
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