classdef VerticalCylinder < Shapes
   properties
      radius

   end

   methods
    
       function self = VerticalCylinder(radius, position, velocity_function, rho)

           param = [];
           param.radius = radius;

           %% ------ Write your code below ------
           %  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv %

           % Fill the gamma functions and the gradient
           % The parameter param.radius is the radius of the cylinder

           gamma = @(x, y, z, param) sqrt(x.^2 + y.^2)/param.radius;
           gradientGamma = @(x, y, z, param) [2*x; 2*y; 0];

           % To complete in TASK 4
           gammaDistance = @(x, y, z, param) abs(sqrt(x.^2 + y.^2) .* (1 - 1/gamma(x, y, z, param))) + 1;

           %  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
           %% ------ Write your code above ------

           self = self@Shapes(gamma, gammaDistance, gradientGamma, param, position, velocity_function, rho)

           self.radius = radius;

       end

   end

end
