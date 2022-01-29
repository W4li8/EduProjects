% fft_example

% simulation of the diffraction pattern 

w = 2e-6; %rectangle half-width (m)
L = 4.4e-3; %vector side length (m)
M = 10000; %number of samples
dx = L/M; %sample interval (m)
x = -L/2:dx:L/2-dx; %coordinate vector

p = 20e-6; %grating_period

dutycyle=2*w/p*100; %grating width translated in dutycicle 0..100

f = rect(x/(2*w)); %original signal vector of the rectangle
f_grating = (square((x/p+0)*2*pi+(pi*dutycyle/100),dutycyle)+1)/2; %normalized signal vector for the grating (values between 0 and 1)


f0=fftshift(f); %shift f
f0_grating=fftshift(f_grating); %shift f
F0=fft(f0)*dx; %FFT and scale
F0_grating=fft(f0_grating)*dx; %FFT and scale
F=fftshift(F0); %center F
F_grating=fftshift(F0_grating); %center F
fx=-1/(2*dx):1/L:1/(2*dx)-(1/L); %freq cords

figure(1)
lambda=0.635e-6;%wavelength
focal_lengths= 3.6e-3; %focal lengths
position_sim = fx*focal_lengths*lambda;
plot(position_sim ,(abs(F)/max(abs(F))).^2,'b-',position_sim,(abs(F_grating)/max(abs(F_grating))).^2,'r-','linewidth',1); %plot magnitude after propagation
title('magnitude');
xlabel('position (m)');
axis([-L/4 L/4 0 1])

%preparation of the measured data

I_1 = imread('picture 334.jpg');
Red_1 = I_1(:,:,1);
Red_1 = double(Red_1);
%visiualize the image to define region of interest
figure(2)
imagesc(Red_1) 
xlabel('position')
ylabel('position')
%definition of center position for scaling
x_center = 769;
y_center = 566;

CenterLine_1 = Red_1(y_center:y_center,1:1600);

%preparation of a centred scaling of the measurement
position=(1:1:1600)*2.835e-6-x_center*2.835e-6;
figure(3)
plot(position,CenterLine_1/max(CenterLine_1),'b-');
xlabel('position')
ylabel('normalized intensity')
axis([-L/4 L/4 0 1])

%plot measurement and simulation together
figure(4)
plot(position,CenterLine_1/max(CenterLine_1),'b-',position_sim,(abs(F_grating)/max(abs(F_grating))).^2,'r-','LineWidth',2);
xlabel('position [m]')
ylabel('normalized intensity')
axis([-L/4 L/4 0 1])
