% Read image 1
I_1 = imread('Picture 8 high gain.jpg');
% select a channel (here red)
Red_1 = I_1(:,:,1);
% format conversion
Red_1 = double(Red_1);

% plot the a line plot from x=(1 x 1600) at the center line at y = 600
CenterLine = Red_1(600:600,1:1600);
figure
plot(CenterLine,'LineWidth',2);
xlabel('position [pxl]')
ylabel('signal [counts]')

% select a Region of Interst RIO with  values between 1 and 1600 in x direction, and the center line in y direction (value 600), choose the left area of the image: here from 10 to 400 in x direction 
CenterLine_left = Red_1(600:600,10:400);

%average over several lines 
% select a region of interest (ROI) with several number of lines N+1 in y direction (horizontal lines are averaged), in the example below x is on the left from 10:400 and the lines that are averaged are 590 tp 610 hence 20 lines, all calculations will be done for this region of interest RIO
N = 0; %The number of lines is N+1

ROI_Red_1_left  = Red_1((600):(600+N),10:400);
%caculate the mean of the RIO over several rows
N_Avg_Red_1_left = mean (ROI_Red_1_left,1);
%plot the averaged line
figure
plot(10:400, N_Avg_Red_1_left,10:400, CenterLine_left,'LineWidth',2);
xlabel('position [pxl]')
ylabel('signal [counts]')

MEAN_red_left = mean(N_Avg_Red_1_left)
STD_red_left = std(N_Avg_Red_1_left)

% repeat for the right side
CenterLine_right = Red_1(600:600,1200:1500);
ROI_Red_1_right  = Red_1((600):(600+N),1200:1500);
%caculate the mean of the RIO over several rows
N_Avg_Red_1_right = mean (ROI_Red_1_right,1);
%plot the averaged line
figure
plot(1200:1500, N_Avg_Red_1_right,1200:1500, CenterLine_right,'LineWidth',2 );
xlabel('position [pxl]')
ylabel('signal [counts]')

MEAN_red_right = mean(N_Avg_Red_1_right)
STD_red_right = std(N_Avg_Red_1_right)
