% SHWFS_MAKE_DAI calibrate modal wavefront estimator
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft
function [shstruct] = shwfs_make_dai(shstruct)

ncoefs = shstruct.dai_n_zernike;
zstruct = zernike_table(ncoefs);

subapradius_m = shstruct.sa_radius_m;

figure(18);
imshow(shstruct.shflat);
hold on;
l = linspace(0, 2*pi);
r = subapradius_m/shstruct.camera_pixsize;
for i=1:shstruct.nspots
    c = shstruct.ord_centres(i, :);
    cc = shstruct.ord_sqgrid(i, :);
    plot(c(1), c(2), 'oy');
    plot(c(1) + r*cos(l), c(2) + r*sin(l));
    text(c(1), c(2), sprintf('%d', i), 'Color', 'r');
    rectangle('Position', ...
        [cc(1) cc(3) cc(2)-cc(1)+1 cc(4)-cc(3)+1], ...
        'LineWidth', 1, 'EdgeColor','y');
end
title('subapertures');

% centre
c = shstruct.ord_centres(shstruct.sa_centralspot, :);
plot(c(1), c(2), 'xm', 'MarkerSize', 13);

% pupil
r = shstruct.pupil_radius_m/shstruct.camera_pixsize;
plot(c(1) + r*cos(l), c(2) + r*sin(l), 'y');


%% [sy; sx] = E*z
fprintf('wait, computing matrices...\n');
E = zernike_compute_E(zstruct, shstruct);
fprintf('   done!\n');
shstruct.dai_E1 = E(:, 2:end);
shstruct.dai_zstruct = zstruct;
E1 = shstruct.dai_E1;
whos E1,
fprintf('cond(E1) %.4f\n', cond(E1));
fprintf('rank(E1) %.4f\n', rank(E1));

end





