
% Read an image
I = imread('C:\Documents and Settings\scharf\My Documents\MATLAB\Picture 44.jpg');

% display an image - shows the coordinates of images points for x and y
figure
imagesc(I);

% convert to B&W - makes a mean of three intensity values for blue, green
% and red
I = mean(I,3);

% select a region of interest ROI 
% x - start x value
% y - start y value  
% w - x range (width)
% h - y range (height)
x = 1;
y = 400;
w = 1599;
h = 1;
I = I(y:y+h,x:x+w);

% vertical average over the ROI - averages over the height h and results a
% vector with lengths w
M = mean(I);

% plot the average profile - plots value against x (w)
figure
plot(M);

