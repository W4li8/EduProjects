% Read images
I_1 = imread('picture 183.jpg');
I_2 = imread('picture 184.jpg');
I_3 = imread('picture 185.jpg');

% select a channel (here red)
Red_1 = I_1(:,:,1);
Red_2 = I_2(:,:,1);
Red_3 = I_3(:,:,1);

% format conversion
Red_1 = double(Red_1);
Red_2 = double(Red_2);
Red_3 = double(Red_3);

%visiualize the image to define region of interest

figure
imagesc(Red_1) 
xlabel('position')
ylabel('position')
%figure
%imagesc(Red_2) 
%xlabel('position')
%ylabel('position')
%figure
%imagesc(Red_3)
%xlabel('position')
%ylabel('position')


% select a line of interest ROI (1 x 1600), here center line at y = 600,
% x is from 1 to 1600)
x_center = 773;
y_center = 617;
CenterLine_1 = Red_1(y_center:y_center,1:1600);
CenterLine_2 = Red_2(y_center:y_center,1:1600);
CenterLine_3 = Red_3(y_center:y_center,1:1600);
%plot a single line

figure 
subplot(311);
plot(1:1:1600,CenterLine_1,'b-');
xlabel('position')
ylabel('intensity')
axis([1 1600 0 255]);
subplot(312);
plot(1:1:1600,CenterLine_2,'r-');
xlabel('position')
ylabel('intensity')
axis([1 1600 0 255]);
subplot(313);
plot(1:1:1600,CenterLine_3,'g-');
xlabel('position')
ylabel('intensity')
axis([1 1600 0 255]);

%average over several lines 
% select a region of interest ROI with several number of lines N (N x
% 1600), x goes from 1 to 1600, averages will by taken over Roi_y from
% y_center-ROI_y to y_center+ROI_y!

ROI_y = 5; 
ROI_Red_1  = Red_1((y_center-ROI_y):(y_center+ROI_y),1:1600);
ROI_Red_2  = Red_2((y_center-ROI_y):(y_center+ROI_y),1:1600);
ROI_Red_3  = Red_3((y_center-ROI_y):(y_center+ROI_y),1:1600);

%caculate the mean of the RIO over several rows
N_Avg_Red_1 = mean (ROI_Red_1)/max(mean (ROI_Red_1));
N_Avg_Red_2 = mean (ROI_Red_2)/max(mean (ROI_Red_2));
N_Avg_Red_3 = mean (ROI_Red_3)/max(mean (ROI_Red_3));

position=(1:1:1600)*2.835e-6-x_center*2.835e-6;
plot_width=200*2.835e-6;
%plot the averaged line

figure 
subplot(311);
plot(position,N_Avg_Red_1,'b-');
xlabel('position')
ylabel('normalized intensity')
axis([(-plot_width) (+plot_width) 0 1]);
subplot(312);
plot(position,N_Avg_Red_2,'r-');
xlabel('position')
ylabel('normalized intensity')
axis([(-plot_width) (+plot_width) 0 1]);
subplot(313);
plot(position,N_Avg_Red_3,'g-');
xlabel('position')
ylabel('normalized intensity')
axis([(-plot_width) (+plot_width) 0 1]);




