classdef MPC_Control_yaw < MPC_Control
  
  methods
    % Design a YALMIP optimizer object that takes a steady-state state
    % and input (xs, us) and returns a control input
    function ctrl_opt = setup_controller(mpc)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % INPUTS
      %   x(:,1) - initial state (estimate)
      %   xs, us - steady-state target
      % OUTPUTS
      %   u(:,1) - input to apply to the system
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      [n,m] = size(mpc.B);
      
      % Steady-state targets (Ignore this before Todo 3.2)
      xs = sdpvar(n, 1);
      us = sdpvar(m, 1);
      
      % SET THE HORIZON HERE
      N = 10; %%%%%%%%%%%%%%%%%%%%%%%%%%VERIRFIER CAAAAAAAAAAAAAAAAAAAAA
      
      % Predicted state and input trajectories
      x = sdpvar(n, N);
      u = sdpvar(m, N-1);
      

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE 

      % NOTE: The matrices mpc.A, mpc.B, mpc.C and mpc.D are 
      %       the DISCRETE-TIME MODEL of your system

      % WRITE THE CONSTRAINTS AND OBJECTIVE HERE
      con = [];
      obj = 0;

      %state is : gamma, d_gamma
      
      %there is no constraints on the state !
      F = zeros(4,2);
      f = zeros(4,1);
 
      %constraints on input only
      G = [1;-1];
      g = [0.2;0.2];
            
      Q = eye(2);
      R = 1;
      
      [~,Qf,~] = dlqr(mpc.A,mpc.B,Q,R);
      for i=1:N-1
         con = con + ((x(:,i+1) - xs) == mpc.A*(x(:,i) - xs) + mpc.B*(u(:,i) - us));
         con = con + (G*(u(:,i)-us) <= g - G*us); %input constraints

         obj = obj + (x(:,i) - xs)'*Q*(x(:,i) - xs);
         obj = obj + (u(:,i) - us)'*R*(u(:,i) - us);
      end
      obj = obj + (x(:,N) - xs)'*Qf*(x(:,N) - xs); 
      
      % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE 
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      
      ctrl_opt = optimizer(con, obj, sdpsettings('solver','gurobi'), ...
        {x(:,1), xs, us}, u(:,1));
    end
    
    
    % Design a YALMIP optimizer object that takes a position reference
    % and returns a feasible steady-state state and input (xs, us)
    function target_opt = setup_steady_state_target(mpc)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % INPUTS
      %   ref    - reference to track
      % OUTPUTS
      %   xs, us - steady-state target
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      % Steady-state targets
      n = size(mpc.A,1);
      xs = sdpvar(n, 1);
      us = sdpvar;
      
      % Reference position (Ignore this before Todo 3.2)
      ref = sdpvar;            
            
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE       
      % You can use the matrices mpc.A, mpc.B, mpc.C and mpc.D
      con = [];
      obj = 0;

      %state is : gamma, d_gamma
      
      %there is no constraints on the state !
      F = zeros(4,2);
      f = zeros(4,1);
      
      %constraints on input only
      G = [1;-1];
      g = [0.2;0.2];
      
      Q = eye(2);
      R = 1;
      
      
      % If the solution exists
      A_new = [eye(n)-mpc.A, -mpc.B; mpc.C 0];
      
      con = [A_new * [xs;us] == [zeros(n,1);ref],...
          (G*us <= g)];
      
      obj   = us'*R*us;
      
      % If not, find the closest one !
      %       con = [(xs == mpc.A*xs + mpc.B*us), (F*xs <= f),(G*us <= g)];
      %       obj = (mpc.C*xs - ref)'*R*(mpc.C*xs - ref);
      
      
      % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE 
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      
      % Compute the steady-state target
      target_opt = optimizer(con, obj, sdpsettings('solver', 'gurobi'), ref, {xs, us});
      
    end
  end
end
