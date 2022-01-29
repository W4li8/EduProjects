% close images
fclose ('all');

% Read image 1
I_1 = imread('picture 96.jpg');


% select a channel (here red)
Red_1 = I_1(:,:,1);

% format conversion
Red_1 = double(Red_1);

%visiualize the image to define region of interest

imagesc(Red_1) 
%mesh(Red_1)
xlabel('position')
ylabel('position')

 
% select a line of interest ROI (1 x 1600), center of peak, 
Line_number = 620;
Line = Red_1(Line_number:Line_number,1:1600);
 
%plot a single line
figure 
plot(Line)
xlabel('position')
ylabel('intensity')
axis([1 1600 0 255])
 




