
% Read an image
I = imread('Picture 8 high gain.jpg');

% display an image
figure 
imagesc(I);

% convert to B&W
I = mean(I,3);

figure 
imagesc(I,[0 255]); colormap(gray);

% select a region of interest ROI
%starting point x
x = 240;
%starting point y
y = 200;
%width w in x direction
w = 40;
%height h in y direction
h = 60;

%region select
I = I(y:y+h,x:x+w);

%plot region of interest
figure 
imagesc(I,[0 255]); colormap(gray);

% mean intensity
MEAN_ROI = mean(mean(I))
STD_ROI = mean(std(I))



