%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Class:     Psych 221/EE 362
% File:      ZernikePolynomial
% Author:    Patrick Maeda
% Purpose:   Calculate and Plot Zernike Polynomials
% Date:      03.03.03	
%	
% Matlab 6.1:  03.04.03
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file calculates and plots the Zernike Polynomial specified by:
% n = highest power or order of the radial polynomial term, [a positive integer]
% m = azimuthal frequency of the sinusoidal component, [a signed integer]
% for a given n, m can take on the values -n, -n+2, -n+4,..., n-4, n-2, n
% d = pupil diameter = 2 for normalized pupil coordinates
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
n=2                 %[INPUT] highest power or order of the radial polynomial term
m=-2                 %[INPUT] azimuthal frequency of the sinusoidal component
j=0.5*(n*(n+2)+m)   %mode number (0 to 36) from single indexing scheme
d=2;                %pupil diameter
PupilDiameter=d
PupilRadius=d/2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Set-up normalized x,y grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xn=-1:0.02:1;   %normalized x-coordinates
yn=-1:0.02:1;   %normalized y-coordinates

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute Zernike polynomial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

z=zernike(n,m,xn,yn,d);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot Zernike polynomial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
subplot(2,1,1)
z=rot90(z);
z=flipud(z);
imagesc(xn,yn,z);
%colormap gray
axis xy
axis square
%set(gca, 'TickDir', 'out')
title(['Zernike Polynomial  Z^{', num2str(m),'}_{', num2str(n),'}'],'FontSize', 10);
xlabel('Normalized x pupil coordinate');
ylabel('Normalized y pupil coordinate');

%figure
subplot(2,1,2)
mesh(xn,yn,z)
%view(-37.5,45) 
title(['Zernike Polynomial  Z^{', num2str(m),'}_{', num2str(n),'}'],'FontSize', 10);
xlabel('Normalized x pupil coordinate');
ylabel('Normalized y pupil coordinate');
zlabel('Amplitude');
colormap('default')
%colormap([0.8 0 0])

