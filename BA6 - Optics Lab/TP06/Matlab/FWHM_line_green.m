% close images
fclose ('all');

% Read image 1
I_1 = imread('picture 73.jpg');


% select a channel (here red)
Green_1 = I_1(:,:,2);

% format conversion
Green_1 = double(Green_1);

%visiualize the image to define region of interest

imagesc(Green_1) 
%mesh(Green_1)
xlabel('position')
ylabel('position')

 
% select a line in x direction of interest ROI (1 x 1600), center of peak, 
Line_number = 200;
Line = Green_1(Line_number:Line_number,1:1600);
 
%plot a single line
figure 
plot(Line)
xlabel('position')
ylabel('intensity')
axis([1 1600 0 255])
 




