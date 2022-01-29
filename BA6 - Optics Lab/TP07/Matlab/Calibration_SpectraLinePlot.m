% Read image 500
I_500 = imread('picture 192.jpg');
% Read image 550
I_550 = imread('picture 191.jpg');
% Read image 600
I_600 = imread('picture 193.jpg');
% Read image 650
I_650 = imread('picture 194.jpg');
% Read image 700
I_700 = imread('picture 195.jpg');


% convert to B&W
I_BW_500 = mean(I_500,3);
I_BW_550 = mean(I_550,3);
I_BW_600 = mean(I_600,3);
I_BW_650 = mean(I_650,3);
I_BW_700 = mean(I_700,3);

% plot image for 550

figure 
imagesc(I_BW_550,[0 255]);
xlabel('position [pixel]')
ylabel('position [pixel]')


%average over several lines (vertical)
% select a region of interest ROI y_start, y_end with several number of lines here 30 lines are averaged

y_start = 500; 
y_end = 530;

ROI_Line_500  = I_BW_500(y_start:y_end,1:1599);
N_Avg_Line_500 = mean(ROI_Line_500);

ROI_Line_550  = I_BW_550(y_start:y_end,1:1599);
N_Avg_Line_550 = mean(ROI_Line_550);

ROI_Line_600  = I_BW_600(y_start:y_end,1:1599);
N_Avg_Line_600 = mean(ROI_Line_600);

ROI_Line_650  = I_BW_650(y_start:y_end,1:1599);
N_Avg_Line_650 = mean(ROI_Line_650);

ROI_Line_700  = I_BW_700(y_start:y_end,1:1599);
N_Avg_Line_700 = mean(ROI_Line_700);


%plot the averaged lines all at once 
figure 
plot(1:1:1599, N_Avg_Line_500,'b-',1:1:1599, N_Avg_Line_550,'g-',1:1:1599, N_Avg_Line_600,'y-',1:1:1599, N_Avg_Line_650,'r-',1:1:1599, N_Avg_Line_700,'c','LineWidth',2);
xlabel('position [pixel]')
ylabel('signal [counts]')