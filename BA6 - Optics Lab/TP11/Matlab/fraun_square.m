%fraun_circ - Fraunhofer irradiance plot

L=0.2; %side length (m)
M=250; %# samples
dx=L/M; %sample interval
x=-L/2:dx:L/2-dx; y=x; %coords
[X,Y]=meshgrid(x,y);

w=1e-3; %x half-width
lambda=0.635e-6;%wavelength
z=50; %prop distance
k=2*pi/lambda; %wavenumber
lz=lambda*z;

%irradiance
I2=(4*w^2/lz)^2.* (sinc(2*w/lz*X).* sinc(2*w/lz*Y)).^2;

figure(1) %irradiance image
imagesc(x,y,nthroot(I2,2));
xlabel('x (m)'); ylabel('y (m)');
colormap('gray');
axis square;
axis xy;

figure(2) %x-axis profile
plot(x,I2(M/2+1,:));
xlabel('x(m)'); ylabel('Irradiance');