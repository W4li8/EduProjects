function I = imagepreparation(fn,r,xc,yc);
%function I = imagepreparation(fn,r,xc,yc);
%
% Prepare image for Hartman-Shack wavefront sensor scripts
%
% require
%    fn    file name string
%    r     pupil radius, pixel
%    xc    pupil center x-coordinate, pixel
%    yc    pupil center y-coordinate, pixel
%
% return
%    I     the image
%
% Eric Logean
% Mai 13, 2013
 
adumax = 255; %maximum number of counts needed for normalization

I = imread(fn);
I = double(I(:,:,1))./adumax; %data conversion and normalization

% circular are definition with radius r
[ymax xmax] = size(I);
[X Y] = meshgrid([1:1:xmax]-xc,[1:1:ymax]-yc);
[T R] = cart2pol(X,Y);
I(find(R>=r)) = 0;

imagesc(I); axis equal;colormap (gray);
