% SHWFS_MAKE_COARSE_GRID
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft
function [shstruct] = shwfs_make_coarse_grid(shstruct)

bg = shstruct.bg;
shflat = shstruct.shflat;

% tunable parameters
use_bg = shstruct.use_bg;
thresh = shstruct.thresh_binary_img;
npixsmall = shstruct.npixsmall;
strel_rad = shstruct.strel_rad;
shstruct.bg = bg;
radius = shstruct.coarse_grid_radius;



%% thresh = graythresh(shflat);
if use_bg
    bw = im2bw(shflat - bg, thresh);
else
    bw = im2bw(shflat, thresh);
end
figure;
imshow(bw);
title('binary image');

%% remove small objects
bw = bwareaopen(bw, npixsmall);
figure;
imshow(bw);
title('remove small objects 1');

%% remove edges
se = strel('disk',strel_rad);
bw = imclose(bw, se);
figure;
imshow(bw);
title('remove small objects 2');

%%
cc = bwconncomp(bw, 4);
s = regionprops(cc, 'Centroid');

nspots = length(s);
hold on;
for k = 1:nspots
    c = s(k).Centroid;
    plot(c(1), c(2), 'ro');
end


roundgrid = cell(1, nspots);
squaregrid = cell(1, nspots);


figure(13);
imshow(shflat);

[h w] = size(bw);
for k=1:nspots
    iilist = [];
    c = s(k).Centroid;

    c = round(c);
    minx = c(1) - radius;
    maxx = c(1) + radius;
    miny = c(2) - radius;
    maxy = c(2) + radius;

    box = [minx maxx miny maxy];
    squaregrid{k} = box;
    figure(13);
    hold on;
    rectangle('Position', [minx miny maxx-minx+1 maxy-miny+1], ...
        'LineWidth', 2, 'EdgeColor','b');
    figure(15);

    % image is height times width!
    subfigure = shflat(box(3):box(4), box(1):box(2));
    imshow(subfigure);
    pause(0.05);
end

figure(13);
title('evaluate coarse grid result');

shstruct.nspots = nspots;
shstruct.roundgrid = roundgrid;
shstruct.squaregrid_radius = radius;
shstruct.squaregrid = squaregrid;

fprintf('$ selected nspots = %d\n', shstruct.nspots);
fprintf('$ the red circles must not overlap!\n');
fprintf('$ tune the image processing parameters to get more or less spots\n');


end

