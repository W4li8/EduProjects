close all;

% fft_example

w = 50e-6;%slit half-width (m) 
L = 0.004536; % vector side length (m), corresponds to the sizte of the detector or screen 
M = 200; %number of samples used for calculation 
dx = L/M; %sample interval (m), corresponding sampling in space 
x = -L/2:dx:L/2-dx; %coordinate vector, corresponding x 
f = rect(x/(2*w)); %signal vector, amplitude vector at the entrance 
figure(1) %plotting the slit amplitude for the whole field 
plot(x,f); %plot f vs x 

figure(2) %plotting the slit amplitude for a zoom into the axis and show sampling  
plot(x,f,'-o'); %plot f vs x 
axis([-0.2 0.2 0 1.5]); 
xlabel('x(m)'); 

figure(3 )%plotting the slit amplitude for a zoom into the axis lotted axainst sampling points, gives the same graph as figure 2 only x axis changed 
plot(f,'-o'); 
axis([80 120 0 1.5]); 
xlabel('index'); 
% Next the  propagation needs to be don by doing a Fourier transform FFT 
% first step is preparing data, a shift of the data is necessary 
f0=fftshift(f); %shift f 

figure(4) %plot of the orginal data but resampled on the vector, needed to do FFT 
plot(f0); 
axis([0 200 0 1.5]); 
xlabel('index'); % Fourier transfrom can be executed 
F0=fft(f0)*dx; %FFT and scale 

figure(5)
plot(abs(F0)); %plot magnitude 
title('magnitude'); 
xlabel('index'); 

figure(6)% Phase of the propagation signal 
plot(angle(F0)); %plot phase 
title('phase'); 
xlabel('index'); % After FFT the signal needs to be shifted back to be centered 
F=fftshift(F0); %center F 
% All calculations were done on a sampled signal, one needs to find the 
% correct axis in space, the frequecy coordinates will be established now 
fx=-1/(2*dx):1/L:1/(2*dx)-(1/L); %freq cords 

figure(7) %Plot of amplitude (magnitude) against the frequency coordinates 
plot(fx,abs(F)); %plot magnitude 
title('magnitude'); 
xlabel('fx (cyc/m)');

figure(8) %Plot of phase against the frequency coordinates 
plot(fx,angle(F)); %plot phase 
title('phase'); 
xlabel('fx (cyc/m)'); 

figure(9) %Plot of intensity against the frequency coordinates 
lambda=0.635e-6;%wavelength 
z=0.093; %prop distance 
lz=lambda*z; 
position_sim = fx*lz; 
plot(position_sim,(abs(F)).^2, 'Linewidth',2); %plot intensity 
title('magnitude'); 
xlabel('position (m)');