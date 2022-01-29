%read an image 1200x1600 
Original = imread('Picture 318.jpg'); 

%define a square region of interest with the distortion in the middle

figure
imagesc(Original)
title('original with distortion')
xlabel('position [pixel]')
ylabel('position [pixel]')

%define a square region of interest with the center of distortion in the middle
center_point_x = 600; % attention this is the vertical direction
center_point_y = 800; % attention this is the horizontal direction
image_size = 800;

% Note: Maximum "image_size" is given by distance center to border 

I  = Original((center_point_x-(image_size/2)):(center_point_x+(image_size/2)),(center_point_y-(image_size/2)):(center_point_y+(image_size/2)));

% Pplot the region of interest
figure
subplot(121)
imshow(I)
title('region of interest')
xlabel('position [pixel]')
ylabel('position [pixel]')

% In what follows the radial distortion is corrected via transformation in
% radial coordinates - multiplication - back transformation

imid= round(size(I,2)/2); % Find index of middle element
[nrows,ncols] = size(I);
[xi,yi] = meshgrid(1:ncols,1:nrows);

xt = xi(:) - imid;
yt = yi(:) - imid;
%transformation in polar coordinates
[theta,r] = cart2pol(xt,yt);


% Try varying the amplitude of the cubic term. This "a" value has to be
% noted in the reported. please give a two number precission. The sign is
% important
a = -0.0000001; 

%Transformation (stretching) of the polar coordinate image - quadratic coorection 
s = r + a*r.^3;

% back transformation polar - cartesian, resampling
[ut,vt] = pol2cart(theta,s);
u = reshape(ut,size(xi)) + imid;
v = reshape(vt,size(yi)) + imid;

tmap_B = cat(3,u,v);
resamp = makeresampler('linear','fill');

I_distortion_corrected = tformarray(I,[],resamp,[2 1],[1 2],[],tmap_B,.3);

% Plot of corrected image
subplot(122)
imshow(I_distortion_corrected)
title('distortion corrected')
xlabel('position [pixel]')
ylabel('position [pixel]')
