function ctrl = ctrl_NMPC(quad)
% CTRL_NMPC Summary of this function goes here
%   Detailed explanation goes here

import casadi.*
opti = casadi.Opti();

N = 10; %%%%%%%%%%%%%%% tune it

% decision variables
X = opti.variable(12,N+1);
U = opti.variable(4,N);
X0 = opti.parameter(12,1);
REF = opti.parameter(4,1); % reference position [x,y,z,yaw]

%%%%%%%%%%%%%% YOUR CODE HERE %%%%%%%%%%%%%%
A = opti.parameter(4, 12);
opti.set_value(A, [0 0 0 0 0 0 0 0 0 1 0 0;
                   0 0 0 0 0 0 0 0 0 0 1 0;
                   0 0 0 0 0 0 0 0 0 0 0 1;
                   0 0 0 0 0 1 0 0 0 0 0 0]);

delta_x = {}; 
for i=1:N+1
    delta_x{end+1} = A*X(:, i) - REF; 
end
DELTA_X = [delta_x{:}];% [4, N+1] vector of columns delta_x, delta_y, delta_z, delta_yaw for each time step.

Q = diag([1, 1, 100, 1/(2*pi)]);

R = diag([2/3, 2/3, 2/3, 2/3]);

new_delta_x = {};
for k = 1: N+1
    new_delta_x{end+1} = delta_x{k}.'*Q*delta_x{k};
end
NEW_DELTA_X = [new_delta_x{:}];% [1, N+1] vector composed of scalar DELTA_X'*Q*DELTA_X for each time step.

new_u = {};
for k = 1: N
    new_u{end+1} = U(:, k).'*R*U(:, k);
end
NEW_U = [new_u{:}];%[1, N] vector composed of scalar U'*R*U for each time step.

opti.minimize( 1*sum(NEW_DELTA_X) + ...
              0.01*sum(NEW_U) - 1*sum(X(7:9))); % can do without speed max/min here

f_discrete_RK4 = @(x,u) RK4(x, u, quad.Ts, @quad.f);
    
opti.subject_to(X(:,1) == X0);
for k=1:N % loop over control intervals
  opti.subject_to(X(:,k+1) == f_discrete_RK4(X(:,k), U(:,k)));
end
% opti.subject_to(-0.035 <= reshape(X(4:5,:), (N+1)*2,1) <= 0.035);

opti.subject_to(0 <= U <= 1.5);
opti.subject_to(-0.5 <= reshape(X(7:9,:),(N+1)*3,1) <= 0.5);
%opti.subject_to(reshape(X(7:9,N+1), 3, 1) == 0);

%%%%%%%%%%%%%% YOUR CODE HERE %%%%%%%%%%%%%%

ctrl = @(x,ref) eval_ctrl(x,ref,opti,X0,REF,X,U);

end
