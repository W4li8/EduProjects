%% 
% This function defines the event function.
% In the three link biped, the event occurs when the swing foot hits the
% ground.
%%
function [value,isterminal,direction] = event_func(t, y)
q = y(1:3);
dq = y(4:6);

[~, z_swf, ~, ~] = kin_swf(q, dq);
value = z_swf + 0.001; % * cos(q(1)) + 0.0001;
isterminal = 1;
direction = -1;

end
