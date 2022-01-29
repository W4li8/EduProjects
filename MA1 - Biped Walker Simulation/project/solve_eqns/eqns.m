function dy = eqns(t, y, y0, step_number, parameters)
% n this is the dimension of the ODE, note that n is 2*DOF, why? 
% y1 = q1, y2 = q2, y3 = q3, y4 = dq1, y5 = dq2, y6 = dq3
% y0 is the states right after impact

q = [y(1); y(2); y(3)];
dq = [y(4); y(5); y(6)];

q0 = [y0(1); y0(2); y0(3)];
dq0 = [y0(4); y0(5); y0(6)];

M = eval_M(q);
C = eval_C(q, dq);
G = eval_G(q);
B = eval_B();

u = control(t, q, dq, q0, dq0, step_number, parameters); 

n = 6;   
dy = zeros(n, 1);
dy(1) = y(4);
dy(2) = y(5);
dy(3) = y(6);
dy(4:6) = M \ (-C*dq - G + B*u);

end