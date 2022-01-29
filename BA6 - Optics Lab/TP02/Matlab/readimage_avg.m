% Read two images I1 and I2 with different exposure levels

I1 = imread('C:\Documents and Settings\scharf\My Documents\MATLAB\Picture 46.jpg');
I2 = imread('C:\Documents and Settings\scharf\My Documents\MATLAB\Picture 47.jpg');

% display an image
%figure
%imagesc(I1);
%figure
%imagesc(I2);

% convert to B&W
I1 = mean(I1,3);
I2 = mean(I2,3);

% display an images in black and white
figure
imagesc(I1,[0 255]); colormap(gray);
figure
imagesc(I2,[0 255]); colormap(gray);

% add images and plot
I3 = I1+I2;
figure
imagesc(I3,[0 510]); colormap(gray);

