% Read image 1
I_1 = imread('picture 73.jpg');


% select a channel (here green)
Green_2 = I_1(:,:,2);

% format conversion
Green_2 = double(Green_2);

%visiualize the image to define region of interest

imagesc(Green_2) 
xlabel('position')
ylabel('position')

 
% select a line of interest ROI (1 x 1600), use the position of the center of the peak, 
Line_number = 571;
x_vector = 1:1:1599;
Line = Green_2(Line_number:Line_number,1:1599);

%plot a cos4theta curve with two parameter : distance pinhole camera and
%max intensity, detector size 4.35,  

distance = 1.3;
peak_position_x = 735;

theta = atan((x_vector-peak_position_x)*4.536/1600/distance);

cos4theta = 122 * (cos(theta).^4);

%plot a single line
figure 
plot(1:1:1599,cos4theta,'r-',1:1:1599,Line,'g-','LineWidth',2)
xlabel('position')
ylabel('intensity')
axis([1 1600 0 255])
 




