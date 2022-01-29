function results = analyse(sln, parameters, to_plot)

% calculate gait quality metrics (distance, step frequency, step length,
% velocity, etc.)

%compute step lenght, distance, step frequency and create time event vector
step_length = [];
distance = [];
step_frequency = [];
time_event = [];
for k = 1: length(sln.YE)-1
    [x_h1, ~, ~, ~] = kin_hip(sln.YE{1, k}(1, 1:3), sln.YE{1, k}(1, 4:6));
    if k == 1
        step_length = [0];
        distance = [step_length];
        step_frequency = [1/(sln.TE{1, k+1} - sln.TE{1, k})];
        time_event = sln.TE{1, 1};
    else
        step_length = [step_length; 2*x_h1];
        distance = [distance; distance(k-1) + step_length(k)];
        step_frequency = [step_frequency; 1/(sln.TE{1, k+1} - sln.TE{1, k})];
        time_event = [time_event, sln.TE{1, k}];
    end
end

%compute velocity, average_velocity, angles, angles_velocity, hip position and create time vector
velocity = [];
average_velocity = [];
angles = [];
angles_velocity = [];
hip_position = [];
time = [];
for k = 1: length(sln.Y)
   [length_Y_1_k, ~] = size(sln.Y{1, k});
   for i = 1: length_Y_1_k
       [x_h, z_h, dx_h, dz_h] = kin_hip(sln.Y{1, k}(i, 1:3), sln.Y{1, k}(i, 4:6));
       velocity = [velocity; [dx_h, dz_h]];
       angles = [angles; sln.Y{1, k}(i, 1:3)];
       angles_velocity = [angles_velocity; sln.Y{1, k}(i, 4:6)];
       hip_position = [hip_position; [x_h, z_h]];
       time = [time, sln.T{1, k}(i)];
   end
end
average_velocity = repmat([mean(velocity(:, 1)), mean(velocity(:, 2))], length(velocity), 1);
velocity = [velocity, average_velocity];

% calculate actuation (you can use the control function)
u = [];
for k = 1: length(sln.Y)
    [length_Y_1_k, ~] = size(sln.Y{1, k});
    for i = 1: length_Y_1_k
        u_new = control(sln.T{1, k}(i), sln.Y{1, k}(i, 1:3), sln.Y{1, k}(i, 4:6), sln.Y{1, 1}(1, 1:3), sln.Y{1, 1}(1, 4:6), length(sln.YE), parameters);
        u = [u; u_new.'];
    end
end


if to_plot
    % plot the angles
    figure('Name', 'angles vs time');
    plot(time, angles);
    legend('q1', 'q2', 'q3');
    
    figure('Name', 'angle velocity vs angle');
    plot(angles, angles_velocity);
    legend('q1', 'q2', 'q3');
    
    % plot the hip position
    figure('Name', 'hip position');
    plot(time, hip_position);
    legend('x position', 'z position');
    
    % plot instantaneous and average velocity
    figure('Name', 'velocity');
    plot(time, velocity);
    legend('instantaneous x', 'instantaneous z', 'average x', 'average z');
    
    %plot frequency with steps
    figure('Name', 'frequency with steps');
    plot([2: length(sln.TE)], step_frequency);
    
    %plot step length with steps
    figure('Name', 'step length with steps');
    plot([2: length(sln.TE)], step_length);
    
    %plot distance with time
    figure('Name', 'distance with time');
    plot(time_event, distance);
    
    % plot projections of the limit cycle
    %?????
   
    % plot actuation
    figure('Name', 'actuation');
    plot(time, u);
    legend('u1', 'u2');
    
end

results = {step_length, distance, step_frequency, velocity, average_velocity, angles, angles_velocity, hip_position, u};

end