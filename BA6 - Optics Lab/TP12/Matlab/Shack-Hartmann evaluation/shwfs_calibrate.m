% Calibrate SHWFS with reference images
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

clear;
clc;
close all;

%% parameters
shstruct = struct();
shstruct.calibration_date = datestr(now, 'yyyymmddHHMMSS');
shstruct.K = 1;                    % gain scaling image intensity
shstruct.use_bg = 0;               % subtract background from images
shstruct.thresh_binary_img = 0.5; % threshold for binary image
shstruct.npixsmall = 8;            % remove objects less than npixsmall
shstruct.strel_rad = 8;            % strel ratio (image processing)
shstruct.coarse_grid_radius = 16;  % radius for coarse grid
shstruct.percent = 0.2;            % used when computing the centroid
shstruct.multiply_est_radius = 1/sqrt(2); % scale estimated radius in the fine grid
shstruct.lambda = 632.8e-9;        % operation wavelength

%% lenslet documentation
shstruct.totlenses = 227;
shstruct.flength = 3.77e-3;
shstruct.pitch = 250e-6;

%% camera documentation and image preparation
shstruct.camera_pixsize = 2.835*1e-6;
shstruct.maxinteger = 2^8-1;       % maximum integer value for the image

% ADDED
r = 400;
fn = 'Picture 5cm.jpg';
xc = 844;
yc = 594;

%% flat mirror reference
I = imagepreparation(fn,r,xc,yc);
shflat = shstruct.K*(I);
%figure(1);
%imshow(shflat);
%title('flat mirror');
iimin = min(min(shflat));
iimax = max(max(shflat));
fprintf('[iimin iimax] = [%d %d]\n', iimin, iimax);
fprintf('$ press any key to continue or Ctrl-C to stop\n');
pause;
%% background
%load bg.mat; % or bg = shstruct.K*(double(imread(black_picture_file))/shstruct.maxinteger);
bg = shstruct.K*(double(zeros(size(I))));
%figure(1);
%imshow(bg);
%title('background');

shstruct.shflat = shflat;
shstruct.bg = bg;

save shstruct.blank.mat shstruct;

%fprintf('$ press any key to continue or Ctrl-C to stop\n');
%pause;
%% coarse grid with image processing
clc;
close all;

load shstruct.blank.mat;
shstruct = shwfs_make_coarse_grid(shstruct);
save shstruct.coarse.mat shstruct;

fprintf('$ press any key to continue or Ctrl-C to stop\n');
pause;

%% finer grid
close all;
clc;

load shstruct.coarse.mat;
shstruct = shwfs_make_fine_grid(shstruct);
save shstruct.fine.mat shstruct;

fprintf('$ press any key to continue or Ctrl-C to stop\n');
pause;

%% Dai modal wavefront estimation
close all;
clc;

load shstruct.fine.mat;

% params Dai modal wavefront estimation
shstruct.sa_radius_m = shstruct.pitch/2;
shstruct.pupil_radius_m = 1.1*shstruct.est_pupil_radius_m;
shstruct.sa_centralspot = shstruct.icentralspot;
shstruct.dai_n_zernike = 5;  % maximum radial degree of the Zernike modes

shstruct = shwfs_make_dai(shstruct);
save shstruct.dai.mat shstruct;


%% save results
fprintf('$ press any key to save the results or Ctrl-C to stop\n');
pause;

save shstruct.mat shstruct;
fprintf('$ saved shstruct.mat\n');
