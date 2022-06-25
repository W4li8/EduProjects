%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Copyright (C) 2020 Learning Algorithms and Systems Laboratory, EPFL,
%    Switzerland
%   Author: Aude Billard
%   email:   aude.billard@epfl.ch
%   website: lasa.epfl.ch
%    
%   Permission is granted to copy, distribute, and/or modify this program
%   under the terms of the GNU General Public License, version 2 or any
%   later version published by the Free Software Foundation.
%
%   This program is distributed in the hope that it will be useful, but
%   WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
%   Public License for more details
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    MIT Press book 
%    Learning for Adaptive and Reactive Robot Control
%    Chapter 8 -  Dynamical system based compliant control: 
%                 Programming exercises 1 & 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize system
clear; close all; clc;

x_limits = [-5, 5];
y_limits = [-5, 5];
nb_gridpoints = 30;

% mesh domain
[X, Y] = meshgrid(linspace(x_limits(1), x_limits(2), nb_gridpoints), ...
                  linspace(y_limits(1), y_limits(2), nb_gridpoints));

x_dot = zeros(nb_gridpoints);
y_dot = zeros(nb_gridpoints);

%% Compute and Draw Nominal Linear DS
A = [-1, 0; 
     0, -1];  %% Linear DS with stable attractor 
x01 = [0; 0];  
b1 = -A*x01;   % Attractor coordinate are at Ax+b=0 

% Compute the DS
for i=1:nb_gridpoints
    for j=1:nb_gridpoints

        w = A * [X(i,j); Y(i,j)] + b1; 
        x_dot(i,j) = w(1);
        y_dot(i,j) = w(2); 
    end
end

% Plot DS
f = figure(1); 
screensize = get(groot, 'Screensize');
f.Position = [0.2  * screensize(3), 0.1  * screensize(4), 0.6 * screensize(3), 0.8 * screensize(4)]; 
subplot(2,2,1); hold on; 
plot_ds(X, Y, x_dot, y_dot, x01, 'Nominal Linear DS', 'streamslice');


%% Exercise 2.2.1 - Limit Cycle

x1 = [0; 0]; % Coordinate of modulator
sigma = 0.5; % Kernel width for effect of modulator
radius = 2; 
theta = pi/2;
vel_control = 10 ; % augment velocity in limit cycle

for i=1:nb_gridpoints
    for j=1:nb_gridpoints

       gamma=exp(-((1/sigma^2)*(norm([X(i,j) ; Y(i,j)] - x1) -radius)^2)); %*sign(norm([X(i,j) Y(i,j)])-radius); 
       M=[cos((theta)*gamma) -sin((theta)*gamma) 
           sin((theta)*gamma)  cos((theta)*gamma)];

        w = vel_control * M * (A * [X(i,j); Y(i,j)] + b1); 
        x_dot(i,j) = w(1);
        y_dot(i,j) = w(2);
    end
end

% Plot DS
subplot(2,2,3); hold on; 
plot_ds(X, Y, x_dot, y_dot, x01, ...
    'Modulated DS with limit cycle (converging to attractor)', 'streamslice', x1);


%% Exercise 2.2.1 - Limit Cycle (Variant)

% This is another possible limit cycle implementation, where the system
% diverges from the attractor to converges to the limit cycle

x1 = [0; 0]; % Coordinate of modulator
radius = 2.5; % Radius of the limit cycle

for i=1:nb_gridpoints
    for j=1:nb_gridpoints

        phi = max([pi * ( 1 - ( norm([X(i,j); Y(i,j)] - x1)/(2*radius))) ; 0]); % angle of rotation

        M1 = [cos(phi), -sin(phi);
              sin(phi),  cos(phi)];  % Modulation Matrix

        w = M1 * (A * [X(i,j); Y(i,j)] + b1); 
        x_dot(i,j) = w(1);
        y_dot(i,j) = w(2);
    end
end

% Plot DS
subplot(2,2,4); hold on; 
plot_ds(X, Y, x_dot, y_dot, x01, ...
    'Modulated DS with limit cycle (diverging from attractor)', 'streamslice', x1);

%% Exercise 2.2.2- create Unstable point 

x1 = [2; -2]; % Unstable point coordinate
sigma = 1; % Kernel width for effect of modulator

for i=1:nb_gridpoints
    for j=1:nb_gridpoints

       gamma1 = exp(-(1 / sigma^2) * norm([X(i,j); Y(i,j)] - x1)^2); % RBF to enforce locality
       M1 = [1 - 4*gamma1, 0; 
              0, 1 - 4*gamma1];% Modulation Matrix 

        w = M1 * (A * [X(i,j); Y(i,j)] + b1); 
        x_dot(i,j) = w(1);
        y_dot(i,j) = w(2); 
    end
end

% Plot DS
subplot(2,2,2); hold on;
plot_ds(X, Y, x_dot, y_dot, x01, ...
    'Modulated DS with unstable point', 'streamslice', x1);

%% Plotting functions

function plot_ds(x, y, x_dot, y_dot, x0, titleName, type, x_target)
% PLOT_DS  Plot a dynamical system on a grid.
%   PLOT_DS(X, Y, X_DOT, Y_DOT, X0, TITLENAME, TYPE, X_TARGET) where the 
%   arrays X,Y define the coordinates for X_DOT,Y_DOT and are monotonic and
%   2-D plaid (as if produced by MESHGRID), plots a dynamical system with
%   attractor(s) X0 given as 2xN vector data and name TITLENAME.
%
%   The variable TYPE is one of 'streamslice', 'streamline' and defines the
%   plotting style of the DS.
%
%   The optional variable X_TARGET given as 2xN vector data can be used to
%   plot additional points of interest (e.g. local modulation points).
    
    title(titleName)
    [~, h] = contourf(x, y, sqrt(x_dot.^2 + y_dot.^2), 80);
    set(h, 'LineColor', 'none');
    colormap('summer');
    c_bar = colorbar;
    c_bar.Label.String = 'Absolute velocity';
    if exist('type', 'var')
        if strcmp(type, 'streamline')
            h_stream = streamline(x, y, x_dot, y_dot, x(1:3:end, 1:3:end), y(1:3:end, 1:3:end));
        elseif strcmp(type, 'streamslice')
            h_stream = streamslice(x, y, x_dot, y_dot, 2, 'method', 'cubic');
        else
            error('Unsupported plot type');
        end
    else
        error("Set plot type ('streamline' or 'streamslice')");
    end
    set(h_stream, 'LineWidth', 1);
    set(h_stream, 'color', [0. 0. 0.]);
    set(h_stream, 'HandleVisibility', 'off');
    axis equal;

    scatter(x0(1, :), x0(2, :), 100, 'r*', 'LineWidth', 2);

    if exist('x_target', 'var')
        scatter(x_target(1, :), x_target(2, :), 100, 'bd', 'LineWidth', 2);
    end
end