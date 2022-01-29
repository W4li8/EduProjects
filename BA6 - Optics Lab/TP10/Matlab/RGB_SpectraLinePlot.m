% Read image
I = imread('Picture 123-500.jpg');

figure
imagesc(I)

% convert to RGB signals
I_B = I(:,:,3);
I_G = I(:,:,2);
I_R = I(:,:,1);

%average over several lines (vertical)
% select a region of interest ROI y_start, y_end with several number of lines here 30 lines are averaged
%normalization of intensity by devision through the maximum

y_start = 655; 
y_end = 670;

ROI_Line_B  = I_B(y_start:y_end,1:1599);
N_Avg_Line_B = mean(ROI_Line_B)/nanmax(mean(ROI_Line_B));

ROI_Line_G  = I_G(y_start:y_end,1:1599);
N_Avg_Line_G = mean(ROI_Line_G)/nanmax(mean(ROI_Line_G));

ROI_Line_R  = I_R(y_start:y_end,1:1599);
N_Avg_Line_R = mean(ROI_Line_R)/nanmax(mean(ROI_Line_R));

%plot the averaged lines all at once 
figure 
plot(1:1:1599, N_Avg_Line_B,'b-',1:1:1599, N_Avg_Line_G,'g-',1:1:1599, N_Avg_Line_R,'r-','LineWidth',2);

xlabel('position [pixel]')
ylabel('signal [counts]')