% Read image 1
I_1 = imread('high.jpg');
% select a channel 
Red_1 = I_1(:,:,1);
Green_1 = I_1(:,:,2);
Blue_1 = I_1(:,:,3);
% format conversion
Red_1 = double(Red_1);
Green_1 = double(Green_1);
Blue_1 = double(Blue_1);
% select a line of interest ROI (1 x 1600), here center line on position 600
CenterLine_Red = Red_1(600:600,1:1599);
CenterLine_Green = Green_1(600:600,1:1599);
CenterLine_Blue = Blue_1(600:600,1:1599);
%plot a single line
figure 
plot(CenterLine_Red);
figure
plot(CenterLine_Green);
figure
plot(CenterLine_Blue);
