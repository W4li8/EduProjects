function objective_value = optimziation_fun(parameters)

% extract parameters q0, dq0 and x
q0 = parameters(1:3);
dq0 = parameters(4:6);
x = parameters(7:end);

% run simulation
num_steps = 5; % the higher the better, but slow
sln = solve_eqns(q0, dq0, num_steps, x);

% handle case when model falls (e.g., objective_value = 1000)
for k = 1:num_steps
    if isempty(sln.TE{k}) % stance leg switch times
        objective_value = 1000;
        return
    end
end

results = analyse(sln, x, false);

% calculate metrics such as distance, mean velocity and cost of transport
max_actuation = 30;
average_velocity = results{5};
distance = results{2};
hip_position = results{8};
u = results{9};

% handle corner case when model walks backwards (e.g., objective_value = 1000)
bitte = 0; 
A = [];
B = [];
for k = 1: length(sln.T)
    A = [A; sln.T{1, k}];
end
for k = 1: length(sln.TE)
    B = [B; sln.TE{1, k}];
end
for i = 1: num_steps
    [~, idx, ~] = intersect(A, B);
    bitte = bitte + (u(idx(i), 1)^2 + u(idx(i), 2)^2);
end
% sumx = sum(sum(u.^2));

effort = 1/(2 * num_steps * max_actuation^2)*bitte;
CoT = effort/(distance(end) - distance(1));
w1 = 1;
w2 = 1;
objective_value = w1*abs(0 - average_velocity(1, 2)) + w2*CoT; %change for z velocity as defined in the slides

%handle corner case when model walks backwards (eg. objective_value = 1000)
if average_velocity(1, 1) < 0
    objective_value = 1000;
end

if CoT < 0
    objective_value = 1000;
end

% handle case when model falls (e.g., objective_value = 1000)
for k = 1: length(hip_position)
    if hip_position(k, 2) < 0
        objective_value = 1000;
    end
end

end

