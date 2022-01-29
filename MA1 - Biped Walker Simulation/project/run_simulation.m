clc;
clear;
close all;

%% run simulation
q0 = [pi/9; -pi/9; 0];
dq0 = [0; 0; 8]; 
num_steps = 10;
default_parameters = control_hyper_parameters();

% q0 = [0.2884; -0.3133; 0.0008]
% dq0 = [0.0005; 0.0010; 4.1357]
% default_parameters = [94.8665; 573.6218; 5.1181; 196.8010; 0.0787]


sln = solve_eqns(q0, dq0, num_steps, default_parameters);
animate(sln);
%analyse(sln, default_parameters, true);
