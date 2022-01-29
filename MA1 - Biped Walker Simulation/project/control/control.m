function u = control(t, q, dq, q0, dq0, step_number, parameters)
%% Robot Parameters
% Robot definition
% m1 = 7; m2 = 7; m3 = 17;
l1 = 0.5; l2 = 0.5; l3 = 0.35;
% Generalised coordinates
q1 = q(1); q2 = q(2); q3 = q(3); dq1 = dq(1); dq2 = dq(2); dq3 = dq(3); 

%% Abstraction
% World coordinates
x = 1; z = 2;
% time = t;
% Notation -> st: stance leg, h: hip, sw: swing leg, t: torso
st = 1; h = 2; sw = 3; t = 4;

%% Position p: [st[x;z], h[x;z], sw[x;z], t[x;z]] and Velocity v: dp
p = [
    0, l1*sin(q1), l1*sin(q1)-l2*sin(q2), l1*sin(q1)+l3*sin(q3);
    0, l1*cos(q1), l1*cos(q1)-l2*cos(q2), l1*cos(q1)+l3*cos(q3)
];
v = [
    0,  l1*cos(q1)*dq1,  l1*cos(q1)*dq1-l2*cos(q2)*dq2,  l1*cos(q1)*dq1+l3*cos(q3)*dq3;
    0, -l1*sin(q1)*dq1, -l1*sin(q1)*dq1+l2*sin(q2)*dq2, -l1*sin(q1)*dq1-l3*sin(q3)*dq3
];
%
%% Finite State Machine
% Walk parameters
step = 0.5;
speed = 0.8;
alfa = 10.4 * pi / 180;
% k: spring cst, pd: desired position, b: damper cst, vd: desired speed
% st - h - sw - t
% k = parameters(1:4); %[ 0; 0; 0; 200]; ;
% pd = [
%     p(x,st),         p(x,h),       p(x,st)+step,     0.5*(p(x,sw)-p(x,st))+l3*sin(alfa);
%     p(z,st),         p(z,h),       p(z,h),              p(z,h)+l3*cos(alfa)
%     ];
% b = parameters(5:8); %[ 0; 5; 5; 10];
% vd = [
%     v(x,st),    1,       2*v(x,h),       v(x,t);
%     v(z,st),    v(z,h),       v(z,sw),        v(z,t)
%     ];


%% Version FSM qui marche pas
% st - h - sw - t
if p(x,sw) < p(x,st)
    k = parameters(1:4);
    pd = [0,    0,     p(x,st)+step,     p(x,h);
          0,    0.5,   0.05,             p(z,h)+l3*cos(alfa)];
      
    b = parameters(13:16);
    vd = [0,  speed,  2*speed,  0;
          0,  0,      0,        0    ]; 
      
elseif p(x,sw) > p(x,st) & p(x,sw) < p(x,st)+0.95*step
    k = parameters(5:8);
    pd = [0,    0,     p(x,st)+step,     p(x,h);
          0,    0.5,   0.05,             p(z,h)+l3*cos(alfa)];
      
    b = parameters(17:20);
    vd = [0,  0,    2*speed,  0;
          0,  0,    0,        0]; 
else
    k = parameters(9:12);
    pd = [0,    0,     p(x,st)+step,    p(x,h);
          0,    0.5,   0.0,             p(z,h)+l3*cos(alfa)];
      
    b = parameters(21:24);
    vd = [0,  0,    2*speed,  0;
          0,  0,    0,        0]; 
end

% k = parameters(1:4); %[ 0; 0; 0; 200]; 
% pd = [
%     p(x,st),         p(x,h)+1,       p(x,st)+step,     p(x,h);%0.5*(p(x,sw)-p(x,st))+l3*sin(alfa);
%     p(z,st),         p(z,h),       p(z,sw),              p(z,h)+l3*cos(alfa)     
% ];
% b = parameters(5:8); %[ 0; 5; 5; 10]; 
% vd = [
%     v(x,st),    speed,       v(x,sw),       v(x,t);
%     v(z,st),    v(z,h),       v(z,sw),        v(z,t)
% ];
% pd = p; pd(x,t) = p(x,h); p(z,t) = p(z,h)+l3;
% vd = v; vd(x,h) = 1; vd(x,sw) = 2;

%% Virtual Model Control
% Jacobian matrices
Jst = [          0,           0,          0;           0,          0,           0];
Jh  = [ l1*cos(q1),           0,          0; -l1*sin(q1),          0,           0];
Jsw = [ l1*cos(q1), -l2*cos(q2),          0; -l1*sin(q1), l2*sin(q2),           0];
Jt  = [ l1*cos(q1),           0, l3*cos(q3); -l1*sin(q1),          0, -l3*sin(q3)];

% Virtual forces 
fst = k(st)*(pd(:,st)-p(:,st)) + b(st)*(vd(:,st)-v(:,st));
fh  = k(h) *(pd(:,h )-p(:,h )) + b(h) *(vd(:,h )-v(:,h ));
fsw = k(sw)*(pd(:,sw)-p(:,sw)) + b(sw)*(vd(:,sw)-v(:,sw));
ft  = k(t) *(pd(:,t )-p(:,t )) + b(t) *(vd(:,t )-v(:,t ));

% Control law
B = [ 1, 0; 0, -1; 1, -1];
J = [Jh; Jsw; Jt];
f = [fh; fsw; ft]; %f = f.*[f>0.01];
u = B\J.'*f;
% disp([p',reshape(f,4,2)]);
%% Physical limitations
% kd1 = parameters(1);
% kp1 = parameters(2);
% kd2 = parameters(3);
% kp2 = parameters(4);
% alpha = parameters(5);
% 
% u1 = kp1 * (q(3) - alpha) + kd1 * dq(3);
% u2 = kp2 * (-q(2) - q(1)) + kd2 * (-dq(2) - dq(1)); 
% % 
% % %saturate the output torque
% u = [u1; u2];

% Saturate the output torque
u = max(min(u, 30), -30); 
% if abs(u)>29
%     disp(u); 
% end
end
