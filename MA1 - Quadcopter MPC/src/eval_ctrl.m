function u = eval_ctrl(x,ref,opti,X0,REF,X,U)
%EVAL_CTRL Summary of this function goes here
%   Detailed explanation goes here


% set initial state and reference
opti.set_value(X0, x);
opti.set_value(REF,ref);

%setup solver NLP
ops = struct('ipopt', struct('print_level',0,'tol',1e-3), 'print_time', false);
opti.solver('ipopt', ops);

% solve optimization problem
sol = opti.solve();
assert(sol.stats.success == 1, 'Error computing optimal input');

u = opti.value(U(:,1));

% Use the current solution to speed up the next optimization
opti.set_initial(sol.value_variables());
opti.set_initial(opti.lam_g, sol.value(opti.lam_g));
end
