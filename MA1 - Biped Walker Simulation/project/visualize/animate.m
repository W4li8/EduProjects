%%
% This function animates the solution of the equations of motion of the
% three link biped. 
% sln is the solution computed by solve_eqns.m
%%
function animate(sln)

figure();
skip = 10;
tic();
num_steps = length(sln.T);
r0 = [0; 0];
for j = 1:num_steps
    Y = sln.Y{j};
    [N, ~] = size(Y);
    for i = 1:skip:N
        q = Y(i, 1:3);
        pause(0.002);
        visualize(q, r0);
        hold off
    end
    [x0, ~, ~, ~] = kin_swf(q);
    r0 = r0 + [x0; 0];
%     pause
end
t_anim = toc();
real_time_factor = sln.T{end}(end) / t_anim;
fprintf('Real time factor:');
disp(real_time_factor);
end
