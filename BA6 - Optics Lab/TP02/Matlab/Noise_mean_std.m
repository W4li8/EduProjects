% Read image 1
I_1 = imread('Picture 8 high gain.jpg');
% select the red channel 
Red_1 = I_1(:,:,1);

% format conversion
Red_1 = double(Red_1);
% mean intensity and standard deviation is calculated 
MEAN_red = mean(mean(Red_1))
STD_red = mean(std(Red_1))

% select the green channel 
Green_1 = I_1(:,:,2);
% format conversion
Green_1 = double(Green_1);
% mean intensity
MEAN_green =mean(mean(Green_1))
STD_green =mean(std(Green_1))

% select the blue channel 
blue_1 = I_1(:,:,3);
% format conversion
blue_1 = double(blue_1);
% mean intensity
MEAN_blue =mean(mean(blue_1))
STD_blue =mean(std(blue_1))
