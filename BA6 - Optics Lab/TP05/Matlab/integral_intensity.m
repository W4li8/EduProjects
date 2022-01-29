%close all open figure windows
fclose ('all');

% Read image 1 
I_1 = imread('picture 83.jpg');
% Read image 2
I_2 = imread('picture 84.jpg');
% Read image DARK NOISE
I_D = imread('picture 127.jpg');


% select a channel (here red)
Red_1 = I_1(:,:,1);
Red_2 = I_2(:,:,1);
Dark_Noise = I_D(:,:,1);


% format conversion
Red_1 = double(Red_1);
Red_2 = double(Red_2);
Dark_Noise = double(Dark_Noise);
 
%subtraction  of dark noise - background correction

Red_1 = Red_1 - Dark_Noise;
Red_2 = Red_2 - Dark_Noise;

%surface plot
figure
imagesc(Red_1,[0 255]); colormap(gray);
figure
imagesc(Red_2,[0 255]); colormap(gray);


% integral over intensity
INT_Red_1 = sum(sum(Red_1))
INT_Red_2 = sum(sum(Red_2))
INT_Dark_noise = sum(sum(Dark_Noise))

Ratio=INT_Red_1/INT_Red_2


