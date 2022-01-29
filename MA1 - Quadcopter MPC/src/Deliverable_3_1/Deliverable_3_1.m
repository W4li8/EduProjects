%% Deliverable 3.1
close all

Ts = 1/5;
quad = Quad(Ts);

[xs, us] = quad.trim();
sys_lin = quad.linearize(xs, us);
[sys_x, sys_y, sys_z, sys_yaw] = quad.decompose(sys_lin, xs, us);

mpc_x = MPC_Control_x(sys_x, Ts);
mpc_y = MPC_Control_y(sys_y, Ts);
mpc_z = MPC_Control_z(sys_z, Ts);
mpc_yaw = MPC_Control_yaw(sys_yaw, Ts);


x = [0;0;0;2];
y = [0;0;0;2];
z = [0;2];
yaw = [0;pi/4];


histx = [x];
histy = [y];
histz = [z];
histyaw = [yaw];

size = 50; 
for cnt=1:size-1
    ux = mpc_x.get_u(x);
    uy = mpc_y.get_u(y);
    uz = mpc_z.get_u(z);
    uyaw = mpc_yaw.get_u(yaw);
    
    x = mpc_x.A * x + mpc_x.B * ux;
    y = mpc_y.A * y + mpc_y.B * uy;
    z = mpc_z.A * z + mpc_z.B * uz;
    yaw = mpc_yaw.A * yaw + mpc_yaw.B * uyaw;
    
    histx = [histx,x] ;
    histy = [histy,y] ;
    histz = [histz,z] ;
    histyaw = [histyaw,yaw] ;
    
end

%Plot for X controller
figure('Name', 'Controller for X')
h1 = plot(linspace(1,size,size), histx(1,:), 'color', 'r'); hold on;
h2 = plot(linspace(1,size,size), histx(2,:), 'color', 'g');
h3 = plot(linspace(1,size,size), histx(3,:), 'color', 'b');
h4 = plot(linspace(1,size,size), histx(4,:), 'color', 'k');
h5 = plot(xlim, 0.035*[1 1], '-.',  'color', 'k');
h6 = plot(xlim, -0.035*[1 1], '-.', 'color', 'k');
legend([h1 h2 h3 h4], {'Vel Pitch [rad/s]', 'Pitch [rad]', 'Vel X [m/s]', 'X [m]'}, 'FontSize', 18)
xlabel('Number of steps')
ylim([-0.75,2.1])
grid on 

%Plot for Y controller
figure('Name', 'Controller for Y')
h1 = plot(linspace(1,size,size), histy(1,:), 'color', 'r'); hold on;
h2 = plot(linspace(1,size,size), histy(2,:), 'color', 'g');
h3 = plot(linspace(1,size,size), histy(3,:), 'color', 'b');
h4 = plot(linspace(1,size,size), histy(4,:), 'color', 'k');
h5 = plot(xlim, 0.035*[1 1], '-.',  'color', 'k');
h6 = plot(xlim, -0.035*[1 1], '-.', 'color', 'k');
legend([h1 h2 h3 h4], {'Vel Roll [rad/s]', 'Roll [rad]', 'Vel Y [m/s]', 'Y [m]'}, 'FontSize', 18)
xlabel('Number of steps')
ylim([-0.75,2.1])
grid on 

%Plot for Z controller
figure('Name', 'Controller for Z')
h1 = plot(linspace(1,size,size), histz(1,:), 'color', 'r'); hold on;
h2 = plot(linspace(1,size,size), histz(2,:), 'color', 'g');
legend([h1 h2], {'Vel Z [m/s]', 'Z [m]'}, 'FontSize', 18)
xlabel('Number of steps')
ylim([-1.5,2.1])
grid on 

%Plot for YAW controller
figure('Name', 'Controller for Yaw')
h1 = plot(linspace(1,size,size), histyaw(1,:), 'color', 'r'); hold on;
h2 = plot(linspace(1,size,size), histyaw(2,:), 'color', 'g');
legend([h1 h2], {'Vel Yaw [rad/s]', 'Yaw [rad]'}, 'FontSize', 18)
xlabel('Number of steps')
ylim([-0.5,0.9])
grid on 




