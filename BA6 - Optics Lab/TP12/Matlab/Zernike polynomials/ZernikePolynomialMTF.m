%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Class:     Psych 221/EE 362
% File:      ZernikePolynomialMTF
% Author:    Patrick Maeda
% Purpose:   Calculate and Plot MTF of Zernike Polynomials
% Date:      03.04.03	
%	
% Matlab 6.1:  03.04.03
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file calculates and plots the MTF of the Zernike Polynomial specified by:
% n = highest power or order of the radial polynomial term, [a positive integer]
% m = azimuthal frequency of the sinusoidal component, [a signed integer]
% for a given n, m can take on the values -n, -n+2, -n+4,..., n-4, n-2, n
% d = pupil diameter in mm
% Wrms = rms wavefront error coefficient in microns
% lambda = wavelength in nm
%
% The Zernike Polynomial definitions used are derived from:
% Thibos, L., Applegate, R.A., Schweigerling, J.T., Webb, R., VSIA Standards Taskforce Members,
% "Standards for Reporting the Optical Aberrations of Eyes"
% OSA Trends in Optics and Photonics Vol. 35, Vision Science and its Applications,
% Lakshminarayanan,V. (ed) (Optical Society of America, Washington, DC 2000), pp: 232-244. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Zernike polynomial selection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Zernike Polynomial radial order n, azimuthal frequency m, and mode number j')
n=7                 %[INPUT] highest power or order of the radial polynomial term
m=-1                 %[INPUT] azimuthal frequency of the sinusoidal component
j=0.5*(n*(n+2)+m)   %mode number (0 to 36) from single indexing scheme

disp('Pupil Diameter (mm), RMS Wavefront Error (micron), and Wavelength (nm)')
d=7;                     %[INPUT] pupil diameter in mm (3 to 8 mm)
PupilDiameter=d
Wrms=0.2                 %[INPUT] rms wavefront error coefficient in microns
lambda=570               %[INPUT] wavelength in nm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert to consistent units for calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Wrms=Wrms*1e-3;          %rms wavefront error coefficient in mm
lambda=lambda*1e-6;      %wavelength in mm
dw=d/lambda;             %pupil diameter in number of wavelengths
PRw=0.5*dw;              %pupil radius in number of wavelengths
apw=pi*PRw^2;            %pupil area in wavelength^2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set-up x,y grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xwmin=-15000;  %minimum x-coordinate in number of wavelengths
xwmax=15000;   %maximum x-coordinate in number of wavelengths
ywmin=-15000;  %minimum y-coordinate in number of wavelengths
ywmax=15000;   %maximum y-coordinate in number of wavelengths
dxw=150;       %x-coordinate pixel width in number of wavelengths
dyw=150;       %y-coordinate pixel width in number of wavelengths

xw=xwmin:dxw:xwmax;   %x-coordinates in number of wavelengths
yw=ywmin:dyw:ywmax;   %y-coordinates in number of wavelengths
Imax=length(xw);
Jmax=length(yw);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set-up circular pupil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for I=1:Imax    
    for J=1:Jmax
       P(I,J)=(sqrt(xw(I)^2+yw(J)^2) <= PRw);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute Zernike polynomial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

z=zernike(n,m,xw,yw,dw);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Compute PSF, OTF, and MTF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PSF0=fft2(P)/apw;
PSF=fft2((P.*exp(-i*2*pi*Wrms*z/lambda)))/apw;
PSF0=PSF0.*conj(PSF0);
PSF=PSF.*conj(PSF);
OTF0=fft2(PSF0);
OTF0=OTF0/max(max(OTF0));
OTF=fft2(PSF);
OTF=OTF/max(max(OTF));
OTF0=fftshift(OTF0);
OTF=fftshift(OTF);
MTF0=abs(OTF0);
MTF0=rot90(MTF0);
MTF=abs(OTF);
MTF=rot90(MTF);
MTF0=flipud(MTF0);
MTF=flipud(MTF);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot MTF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sxmin=-15000;    %minimum sx-coordinate in radians
sxmax=15000;     %maximum sx-coordinate in radians
symin=-15000;    %minimum sy-coordinate in radians
symax=15000;     %maximum sy-coordinate in radians
dsx=150;     %sx-coordinate pixel width in radians
dsy=150;     %sy-coordinate pixel width in radians
sx=sxmin:dsx:sxmax;   %sx-coordinates in radians
sy=symin:dsy:symax;   %sy-coordinates in radians

figure
subplot(2,1,1)
contour(sx*pi/180,sy*pi/180,MTF0)
%axis([0 0.5*sxmax*pi/180 0 0.5*symax*pi/180 0 1])
xlabel('s_{x} (cycle/deg)')
ylabel('s_{y} (cycle/deg)')
title(['MTF of Zero Aberration System, ',...
        num2str(PupilDiameter), ' mm pupil'], 'FontSize', 10);
%colormap gray

%figure
subplot(2,1,2)
contour(sx*pi/180,sy*pi/180,MTF)
%axis([0 0.5*sxmax*pi/180 0 0.5*symax*pi/180 0 1])
xlabel('s_{x} (cycle/deg)')
ylabel('s_{y} (cycle/deg)')
title(['MTF of Z ^{', num2str(m),'}_{', num2str(n),'} ,',...
       ' RMS Wavefront Error = ', num2str(Wrms/lambda),'\lambda'],'FontSize', 10);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Plot MTF Cross-sections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sxaxismax=0.15*sxmax*pi/180;
syaxismax=0.15*symax*pi/180;

figure
subplot(2,2,1)
plot(sx*pi/180,MTF0((Imax+1)/2,:))
xlabel('s_{x} (cycle/deg)')
ylabel('Contrast')
axis([0 sxaxismax 0 1])
axis square
title(['MTF of Zero Aberration System, ',...
        num2str(PupilDiameter), 'mm pupil'], 'FontSize', 10);
subplot(2,2,2)
plot(sy*pi/180,MTF0(:, (Jmax+1)/2))
xlabel('s_{y} (cycle/deg)')
ylabel('Contrast')
axis([0 syaxismax 0 1])
axis square
title(['MTF of Zero Aberration System, ',...
        num2str(PupilDiameter), 'mm pupil'], 'FontSize', 10);
subplot(2,2,3)
plot(sx*pi/180,MTF((Imax+1)/2,:))
xlabel('s_{x} (cycle/deg)')
ylabel('Contrast')
axis([0 sxaxismax 0 1])
axis square
title(['MTF of Z ^{', num2str(m),'}_{', num2str(n),'} ,',...
       ' RMS Error = ', num2str(Wrms/lambda),'\lambda'],'FontSize', 10);
subplot(2,2,4)
plot(sy*pi/180,MTF(:, (Jmax+1)/2))
xlabel('s_{y} (cycle/deg)')
ylabel('Contrast')
axis([0 syaxismax 0 1])
axis square
title(['MTF of Z ^{', num2str(m),'}_{', num2str(n),'} ,',...
       ' RMS Error = ', num2str(Wrms/lambda),'\lambda'],'FontSize', 10);

