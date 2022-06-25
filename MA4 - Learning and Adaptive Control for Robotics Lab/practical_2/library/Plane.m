classdef Plane < Shapes
   properties
      normal

   end

   methods
    
       function self = Plane(normal, position, velocity_function, rho)

           param = [];
           param.normal = normal/norm(normal);

           %% ------ Write your code below ------
           %  vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv %

           % Fill the gammaDistance function and the gradientGamma
           % The parameter param.normal is the normalized normal vector

           gammaDistance = @(x, y, z, param) abs(x.*param.normal(1) + y.*param.normal(2) + z.*param.normal(3)) + 1;

           gradientGamma = @(x, y, z, param) param.normal';  

           %  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ 
           %% ------ Write your code above ------

           gamma = gammaDistance;

           self = self@Shapes(gamma, gammaDistance, gradientGamma, param, position, velocity_function, rho)

           self.normal = normal;
       end

       function showShape(self, axisLimit, alpha)
            
            % Generate vertex position from workspace limits
            x = [axisLimit(1) axisLimit(2) axisLimit(2) axisLimit(1)]; 
            y = [axisLimit(4) axisLimit(4) axisLimit(3) axisLimit(3)]; 
            z = (-1/self.normal(3))*(self.normal(1)*(x - self.position(1)) + self.normal(2)*(y - self.position(2)) - self.position(3)); 
            self.patchVal = patch(x, y, z, rand(1, 3), 'FaceAlpha', alpha);

        end



   end

end
