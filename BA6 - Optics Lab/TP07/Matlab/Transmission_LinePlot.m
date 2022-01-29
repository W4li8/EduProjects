% Read image 1
I_signal = imread('picture 208.jpg');
I_white = imread('picture 207.jpg');

% convert to B&W
I_signal_BW = mean(I_signal,3);
I_white_BW = mean(I_white,3);

% show an image to adjust line positions
figure 
imagesc(I_white_BW,[0 255]);
xlabel('position [pixel]')
ylabel('position [pixel]')
figure 
imagesc(I_signal_BW,[0 255]);
xlabel('position [pixel]')
ylabel('position [pixel]')



%average over several lines (vertical)
% select a region of interest ROI with several number of lines from
% y_start to y_end
%caculate the mean of the RIO obver several rows
%one has also to choose the wavlengt range, we go from 300pxl to 463 pxl
 
y_start = 530; 
y_end = 560;
x_start = 1;
x_end = 1600;

ROI_Line_white  = I_white_BW(y_start:y_end,x_start:x_end);
N_Avg_Line_white = mean(ROI_Line_white);

ROI_Line_signal  = I_signal_BW(y_start:y_end,x_start:x_end);
N_Avg_Line_signal = mean(ROI_Line_signal);

%calculate the transmission

Transmission = N_Avg_Line_signal./N_Avg_Line_white;

%plot the Transmission
figure 
plot(Transmission,'LineWidth',2);
title('averaged signal');
xlabel('position [pixel]')
ylabel('signal [counts]')

