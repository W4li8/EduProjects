classdef VerticalEllipsoid < Shapes
   properties
      ellipseAxes

   end

   methods
    
       function self = VerticalEllipsoid(axes, position, velocity_function, rho)

           param = [];
           param.ellipseAxes = axes;
           
           %% ------ Write your code below ------
           %  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv %

           % Fill the gamma functions and the gradient
           % The parameter param.ellipseAxes is a 3D vector with the three
           % semi-axes of an ellipse

           gamma = @(x, y, z, param) sqrt((x/param.ellipseAxes(1)).^2 + (y/param.ellipseAxes(2)).^2 + (z/param.ellipseAxes(3)).^2);
           gradientGamma = @(x, y, z, param) [2*x/param.ellipseAxes(1); 2*y/param.ellipseAxes(2); 2*z/param.ellipseAxes(3)];

           % To complete in TASK 4 (approximation)
           gammaDistance = @(x, y, z, param) abs(sqrt(x.^2 + y.^2 + z.^2) .* (1 - 1/gamma(x, y, z, param))) + 1;
           %  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
           %% ------ Write your code above ------


           self = self@Shapes(gamma, gammaDistance, gradientGamma, param, position, velocity_function, rho)

           self.ellipseAxes = axes;
       end

   end

end
