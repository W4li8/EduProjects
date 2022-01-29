% close images
fclose ('all');
% Read image 1
I_1 = imread('picture 128.jpg');
% select the red channel 
R_1 = I_1(:,:,1);
% format conversion
R_1 = double(R_1);
% background subtraction 1 - mean intensity
R_1 = R_1 - mean(mean(R_1));
% select region of interest ROI (200 x 200)
R_1_ROI = R_1(501:700,701:900);

% Read image 2
I_2 = imread('picture 130.jpg');
% select the red channel 
R_2 = I_2(:,:,1);
% format conversion
R_2 = double(R_2);
% background subtraction 1 - mean intensity
R_2 = R_2 - mean(mean(R_2));
% select region of interest ROI (200 x 200)
R_2_ROI = R_2(501:700,701:900);

% plot selection
%figure
%imagesc(R_1_ROI);
% axis description
%xlabel('position')
%ylabel('position')

% crosscorrelation
A_R_1 = xcorr2(R_1_ROI,R_2_ROI);

% plot crosscorrelation
figure
imagesc(A_R_1);
% axis description
xlabel('position')
ylabel('position')
% select center line
% definition of axis value 100 -300 (center at 200)
CenterLine_horizontal= A_R_1(200:200,100:300);

%plot a single line
figure
plot(CenterLine_horizontal);
% axis description
xlabel('position')
ylabel('signal')
% axis scaling to max y value
xlim ([0 200])
ylim ([0 max(max(A_R_1))])
