% ZERNIKE_COMPUTE_EyEx computes matrix an element of matrix
% E, see Dai 1994.
% 
% [Ey Ex] = zernike_compute_EyEx(radrow, azimrow, ...
%     rho_0, theta_0, r_sa)
% radrow                     Zernike radial polynomial
% azimrow                    azimuthal order
% theta_0                    (rho_0, theta_0) subaperture location
% r_sa                       subaperture normalised radius (0, 1]
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft


function [Ey Ex] = zernike_compute_EyEx(radrow, azimrow, ...
    rho_0, theta_0, r_sa)

% rho_0 is in [0 1]
% r_sa is in [0 1]

% Ey Ex must be multiplied with lambda*f/(2*pi*A_sa)

assert(rho_0 >= 0 && rho_0 < 1);
assert(r_sa > 0 && r_sa < 1);

rhoindefint1 = polyint([polyder(radrow) 0]);
rhoindefint2 = polyint(radrow);

theta_a = theta_0 - atan(r_sa/rho_0);
theta_b = theta_0 + atan(r_sa/rho_0);

rho_a = @(x) rho_0.*cos(x - theta_0) - ...
    sqrt((rho_0.^2).*cos(x - theta_0) + ...
    (r_sa.^2) - (rho_0.^2));
rho_b = @(x) rho_0.*cos(x - theta_0) + ...
    sqrt((rho_0.^2).*cos(x - theta_0) + ...
    (r_sa.^2) - (rho_0.^2));

rhoint1a = @(x) polyval(rhoindefint1, rho_a(x));
rhoint1b = @(x) polyval(rhoindefint1, rho_b(x));
rhoint2a = @(x) polyval(rhoindefint2, rho_a(x));
rhoint2b = @(x) polyval(rhoindefint2, rho_b(x));
psi = zernike_radialfun(azimrow);
psider = zernike_radialderfun(azimrow);

integrandx = @(x) ...
    (rhoint1b(x) - rhoint1a(x)).*psi(x).*cos(x) - ...
    (rhoint2b(x) - rhoint2a(x)).*psider(x).*sin(x);

integrandy = @(x) ...
    (rhoint1b(x) - rhoint1a(x)).*psi(x).*sin(x) + ...
    (rhoint2b(x) - rhoint2a(x)).*psider(x).*cos(x);

Ex = quad(integrandx, theta_a, theta_b);
Ey = quad(integrandy, theta_a, theta_b);

end

