
% Read an image 
I = imread('Picture 2.jpg');

% display an image
figure
imagesc(I);

% convert to B&W
I = mean(I,3);

% select a region of interest ROI, averaging will be over h=100 lines in
% this example.
x = 1;
y = 200;
w = 1599;
h = 400;
I = I(y:y+h,x:x+w);

%control plot to check the quality of the regoin of interest. Assure that
%the features are vertical!!
figure
image(I);
xlabel('position')
ylabel('position')


% vertical average over the ROI
M = mean(I);

% plot the average profile
figure
plot(M);
xlabel('position')
ylabel('intensity')

