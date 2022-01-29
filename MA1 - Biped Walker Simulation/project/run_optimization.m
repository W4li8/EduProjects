clc;
clear;
close all;

%% optimize
% optimize the initial conditions and controller hyper parameters

% use fminsearch and optimset to control the MaxIter
options = optimset('PlotFcns',@optimplotfval); %, 'MaxIter', 1000, 'MaxFunEvals', 1000);

%% simulate solution
% extract parameters
q0 = [pi/9; -pi/9; 0];
dq0 = [0; 0; 8];
arr = [];


args = [randi(200);randi(200);randi(200);randi(200);randi(200);randi(200);
        randi(200);randi(200);randi(200);randi(200);randi(200);randi(200);
        randi(50);randi(50);randi(50);randi(50);randi(50);randi(50);
        randi(50);randi(50);randi(50);randi(50);randi(50);randi(50)]

% x0 = [q0; dq0; control_hyper_parameters()];
x0 = [q0; dq0; args];

x = fminsearch(@optimziation_fun, x0, options)

q0 = x(1:3);
dq0 = x(4:6);
x_opt = x(7:end);

%arr = [arr; x];

%% simulate
num_steps = 10;
sln = solve_eqns(q0, dq0, num_steps, x_opt);
animate(sln);
results = analyse(sln, x_opt, true);

pause
close all;
