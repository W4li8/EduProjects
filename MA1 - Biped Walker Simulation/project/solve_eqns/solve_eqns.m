%% Solve equations of motion 
% Note: eqns.m defines the equations of motion to be solved by this script
% This function returns the time vector T, the solution Y, the event time
% TE, solution at the event time YE.
% q0, dq0 are the initial angles and angular velocities, num_steps are the
% number of steps the robot is supposed to take
% As an example you can use q0 = [pi/6; -pi/3; 0] and dq0 = [0;0;8]. 

function sln = solve_eqns(q0, dq0, num_steps, parameters)

options = odeset('RelTol',1e-5, 'Events', @event_func);
h = 0.001; % time step
tmax = 2; % max time that we allow for a single step
tspan = 0:h:tmax;
y0 = [q0; dq0];
t0 = 0;

% we define the solution as a structure to simplify the post-analyses and
% animation, we initialize it to null
sln.T = {};
sln.Y = {};
sln.TE = {};
sln.YE = {};


for i = 1:num_steps
    [T, Y, TE, YE] = ode45(@(t, y) eqns(t, y, y0, i, parameters), t0 + tspan, y0, options);
    sln.T{i} = T;
    sln.Y{i} = Y;
    sln.TE{i} = TE;
    sln.YE{i} = YE;

    if T(end) == tmax
        break
    end
    
    if (length(YE) == 0)
        break
    end
        
    % Impact map
    q_m = YE(1:3)';
    dq_m = YE(4:6)';
    [q_p, dq_p] = impact(q_m, dq_m);
    
    y0 = [q_p; dq_p];
    t0 = T(end);
    
end
end


