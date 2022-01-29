% You can set any hyper parameters of the control function here; you may or
% may not want to use the step_number as the input of the function. 
function parameters = control_hyper_parameters(step_number)
kd1 = 77.05;                     
kp1 = 457.5;
kd2 = 5;
kp2 = 161;
alpha = 10.4 * pi / 180;


% st - h - sw - t
k1 = 100;
k2 = 200;
k3 = 250;
k4 = 50;
k5 = 100;
k6 = 200;
k7 = 250;
k8 = 50;
k9 = 100;
k10 = 200;
k11 = 250;
k12 = 50;

b1 = 5;
b2 = 50;
b3 = 50;
b4 = 5;
b5 = 5;
b6 = 50;
b7 = 50;
b8 = 5;
b9 = 5;
b10 = 50;
b11 = 50;
b12 = 5;


parameters = [k1, k2, k3, k4, k5, k6, k7, k8, k9, k10, k11, k12, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12]';
%parameters = [kd1, kp1, kd2, kp2, alpha]';
end
