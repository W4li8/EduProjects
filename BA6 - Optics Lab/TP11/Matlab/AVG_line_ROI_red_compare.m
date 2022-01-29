% Read image 1
I_1 = imread('picture 3.jpg');
 
% select a channel (here red)
Red_1 = I_1(:,:,1);
 
% format conversion
Red_1 = double(Red_1);
 
%visiualize the image to define region of interest
 
imagesc(Red_1) 
xlabel('position')
ylabel('position')
 
 
% select a line of interest ROI (1 x 1600), here center line at y = 600,
% x is from 1 to 1600)
y_center = 620;
CenterLine = Red_1(y_center:y_center,1:1600);
%plot a single line
 
%figure 
%plot(CenterLine);
%xlabel('position')
%ylabel('intensity')
 
%average over several lines 
% select a region of interest ROI with several number of lines N (N x
% 1600), x goes from 1 to 1600, averages will by taken over Roi_y from
% y_center-ROI_y to y_center+ROI_y!
 
ROI_y = 50; 
ROI_Red_1  = Red_1((y_center-ROI_y):(y_center+ROI_y),1:1600);
 
%caculate the mean of the RIO over several rows
N_Avg_Red_1 = mean (ROI_Red_1);
position=(-800:1:799)*2.835e-6;
 
%plot the averaged line
figure 
plot(position,N_Avg_Red_1/max(N_Avg_Red_1),'b-',position_sim-8e-5,(abs(F)/max(abs(F))).^2,'r-','LineWidth',3);
xlabel('position [m]')
ylabel('normalized intensity')

