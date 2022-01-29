% Read image 1
I_1 = imread('/Users/Filip/Desktop/EPFLite/OPT TP8/3/Contrast_3/Contrast3_ (27).jpg');


% select a channel 
Red_1 = I_1(:,:,1);
%{
%Surface plot
figure
%Averaging parameter (larger number = smoother), 1 = no averaging
size_ave = 31 ;
Red_1_smooth = conv2(Red_1, ones(size_ave)/size_ave.^2, 'same') ;
surf(Red_1_smooth, 'EdgeColor', 'none') ;

%plot the channel
figure 
imagesc(Red_1,[0 255]);
xlabel('position [pixel]')
ylabel('position [pixel]')

%}
% format conversion
Red_1 = double(Red_1);

% select a line of interest ROI (1 x 1600), here center line
CenterLine_Red = Red_1(600:600,1:1599);
%{
%plot a single line
figure 
plot(CenterLine_Red);
xlabel('position [pixel]')
ylabel('signal [counts]')

%average over several lines (vertical)
% select a region of interest ROI with several number of lines N (N x
% 1600), here 200 lines are averaged
ROI_Red_1  = Red_1((600-100):(600+100),1:1599);

%caculate the mean of the RIO over several rows
N_Avg_Red_1 = mean (ROI_Red_1);

%plot the averaged line
figure 
plot(N_Avg_Red_1,'LineWidth',2);
title('averaged signal');
xlabel('position [pixel]')
ylabel('signal [counts]')
axis([0 1600 0 250])

%}


myDir = uigetdir;
myFiles = dir(fullfile(myDir, '*.jpg'));
contrast = zeros(length(myFiles), 1)
for k = 1:length(myFiles)
   baseFileName = myFiles(k).name;
   fullFileName = fullfile(myDir, baseFileName);
   I_1 = imread(fullFileName);
   Red_1 = I_1(:,:,1);
   Red_1 = double(Red_1);
   ROI_Red_1  = Red_1((600-100):(600+100),1:1599);
   N_Avg_Red_1 = mean (ROI_Red_1);
   
   mi = min(N_Avg_Red_1);
   ma = max(N_Avg_Red_1);
   contrast(k) = (ma-mi)/(ma+mi);
   disp(contrast(k));

end
pos = 3.8:0.1:8;
plot(pos, contrast)
   


disp((3.8:0.1:8)')

disp((0.1:0.1:4.3)')
