function [xs, us] = computeSP(A,B,C,R,F,f,G,g,r)
%COMPUTESP Summary of this function goes here
%   Detailed explanation goes here

nx = size(A,1);
nu = size(B,2);

xs = sdpvar(nx,1);
us = sdpvar(nu,1);

A_new = [eye(nx)-A, -B; C 0];

constraints = [A_new * [xs;us] == [zeros(nx,1);r],...
               (F*xs <= f),...
               (G*us <= g)];

objective   = us'*R*us;

diagnostics = solvesdp(constraints,objective,sdpsettings('verbose',0));

if diagnostics.problem == 0
   % Good! 
elseif diagnostics.problem == 1
    throw(MException('','Infeasible'));
else
    throw(MException('','Something else happened'));
end

end


