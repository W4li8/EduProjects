clear all;
clc;
close all;

% estimate
load shstruct;

r = 400;
fn ='Picture 1cm.jpg';
xc = 844; %centre position x to be taken from the evaluation before
yc = 594; %centre position y to be taken from the evaluation before

I = imagepreparation(fn,r,xc,yc);
img = shstruct.K*(I);

[zhatrad er] = shwfs_dai_estimate_rad(img, shstruct, @centroid);

% plot
zstruct = shstruct.dai_zstruct;
dd = linspace(-1, 1, 80);
[xx yy] =  meshgrid(dd, dd);
zstruct = zernike_cache(zstruct, xx, yy);

zcs = [0; zhatrad];
sel = 1:size(zhatrad, 1);
plot(sel, zcs(sel), 'x', 'MarkerSize', 32);
varrad = sum(zcs(2:end).^2);
strehl = exp(-sum(zcs(2:end).^2));
title(sprintf('norm(s - se) %.8f strehl %.3f varrad %f norminf %.4f', norm(er), strehl, varrad,...
    norm(zcs(2:end), inf)));
set(gca, 'XTick', sel);
xlabel('zernike coeff');
ylabel('rad');
grid on;

figure(2);
zernike_surf(zstruct, zcs);
% view(2);
zlabel('rad');
shading interp;

