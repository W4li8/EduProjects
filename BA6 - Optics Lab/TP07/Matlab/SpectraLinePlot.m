% Read image 1
I = imread('picture 209.jpg');

% display an image
%imagesc(I);

% convert to B&W
I_BW = mean(I,3);

% plot the image

figure 
imagesc(I_BW,[0 255]);
xlabel('position [pixel]')
ylabel('position [pixel]')
title('intensity')


% select a line of interest ROI (1 x 1600)here line at 540
CenterLine = I_BW(540:540,1:1599);

%plot a single line
figure 
plot(CenterLine);
xlabel('position [pixel]')
ylabel('signal [counts]')
title('single line plot')


%average over several lines (vertical)
% select a region of interest ROI with several number of lines, here 30 lines are averaged
ROI_Line  = I_BW(530:560,1:1599);

%caculate the mean of the RIO obver several rows
N_Avg_Line = mean(ROI_Line);

%plot the averaged line
figure 
plot(N_Avg_Line,'LineWidth',2);
title('averaged signal');
xlabel('position [pixel]')
ylabel('signal [counts]')


