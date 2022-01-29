% SHWFS_MAKE_FINE_GRID
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft
function [shstruct] = shwfs_make_fine_grid(shstruct)

shflat = shstruct.shflat;

%% get centres with coarse grid
figure;
imshow(shflat);
hold on;

nspots = shstruct.nspots;
centres = zeros(nspots, 2);
img = shstruct.shflat;

for i=1:nspots
    cc = shstruct.squaregrid{i};

    % images are height by width!
    if (shstruct.use_bg)
        subimage = img(cc(3):cc(4), cc(1):cc(2)) - ...
            shstruct.bg(cc(3):cc(4), cc(1):cc(2));
    else
        subimage = img(cc(3):cc(4), cc(1):cc(2));
    end
    
    iimin = min(min(subimage));
    iimax = max(max(subimage));
    level = (iimax - iimin)*shstruct.percent + iimin;

    dd = centroid(subimage, level);
    centres(i, :) = [cc(1)+dd(2)-1 cc(3)+dd(1)-1];
end


%%
figure(1);
for i=1:nspots
    cc = shstruct.squaregrid{i};

    % images are height by width!
    rectangle('Position', ...
        [cc(1) cc(3) cc(2)-cc(1)+1 cc(4)-cc(3)+1], ...
        'LineWidth', 1, 'EdgeColor','b');
    plot(centres(i, 1), centres(i, 2), 'xr');
end

shstruct.centres = centres;

fprintf('any non finite? %d\n', any(any(isfinite(centres) == 0)));
fprintf('min(min(shflat)) %f\n', min(min(shflat)));
fprintf('max(max(shflat)) %f\n', max(max(shflat)));
fprintf('min(min(exp(shflat))) %f\n', min(min(exp(shflat))));
fprintf('max(max(exp(shflat))) %f\n', max(max(exp(shflat))));

%% guess central spot
norms = zeros(nspots, nspots);
for i=1:nspots
    for j=1:nspots
        norms(i, j) = norm(centres(i, :) - centres(j, :));
    end
end
lnorms = sum(norms, 2);
[~, icentralspot] = min(lnorms);
% estimate radius
mins = zeros(nspots, 1);
for i=1:nspots
    [~, sel] = sort(norms(i, :));
    mins(i) = norms(i, sel(2));
end
radius = mean(mins)/2*shstruct.multiply_est_radius;
shstruct.icentralspot = icentralspot;

hold on;
spotxy = centres(icentralspot, :);
plot(spotxy(1), spotxy(2), 'yo');

figure(54);
plot(mins, 'o');
xlabel('spot number');
ylabel('radius');

% estimate pupil radius
shstruct.est_pupil_radius_m = ...
    max(norms(icentralspot, :))*...
    shstruct.camera_pixsize;

shstruct.squaregrid_coarse = shstruct.squaregrid;
shstruct.squaregrid_radius_coarse = shstruct.squaregrid_radius;
shstruct.squaregrid_radius = radius;

for i=1:nspots
    c = centres(i, :);
    minx = c(1) - radius;
    maxx = c(1) + radius;
    miny = c(2) - radius;
    maxy = c(2) + radius;
    shstruct.squaregrid{i} = round([minx maxx miny maxy]);
end

%% draw fine grid
centres = zeros(nspots, 2);
img = shstruct.shflat;
for i=1:nspots
    cc = shstruct.squaregrid{i};

    % images are height by width!
    if (shstruct.use_bg)
        subimage = img(cc(3):cc(4), cc(1):cc(2)) - ...
            shstruct.bg(cc(3):cc(4), cc(1):cc(2));
    else
        subimage = img(cc(3):cc(4), cc(1):cc(2));
    end
    
    iimin = min(min(subimage));
    iimax = max(max(subimage));
    level = (iimax - iimin)*shstruct.percent + iimin;

    dd = centroid(subimage, level);
    centres(i, :) = [cc(1)+dd(2)-1 cc(3)+dd(1)-1];
end
grid = shstruct.squaregrid;
nspots = shstruct.nspots;

figure(2);
imshow(shflat);
hold on;
title('fine grid');
for i=1:nspots
    cc = grid{i};
    rectangle('Position', ...
        [cc(1) cc(3) cc(2)-cc(1)+1 cc(4)-cc(3)+1], ...
        'LineWidth', 1, 'EdgeColor','b');
    plot(centres(i, 1), centres(i, 2), 'xr');
    text(cc(1), cc(3), ...
        sprintf('%d', i), 'Color', 'g');
end


%% unused, code for zonal is outdated
shstruct.enumeration = 1:shstruct.nspots;
shstruct.ord_centres = shstruct.centres(shstruct.enumeration, :);
shstruct.ord_sqgrid = zeros(size(shstruct.ord_centres, 1), 4);
for i=1:length(shstruct.enumeration)
    shstruct.ord_sqgrid(i, :) = ...
        shstruct.squaregrid{shstruct.enumeration(i)};
end


end
