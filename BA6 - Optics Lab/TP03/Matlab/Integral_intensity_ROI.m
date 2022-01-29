%close all open figure windows
fclose ('all');
% Read image 1 
I_1 = imread('2.jpg');
% select a channel (here red)
Red_1 = I_1(:,:,1);
% format conversion
Red_1 = double(Red_1);
% plot the whole field to allow to find the position of the intensity peak
figure
imagesc(Red_1,[0 255]); colormap(gray);

%define a region of interest ROI ? NEEDS TO BE CHANGED WITH YOUR VALUES
Red_1_ROI = Red_1(240:300,350:500);
%plot region of interest for control 
figure
imagesc(Red_1_ROI,[0 255]); colormap(gray);

% integral over region of intensity
INT_Red_1_ROI = sum(sum(Red_1_ROI))
