function plotProjections(omega_inf, name) 
    [~, dim] = size(omega_inf.V);
    
    colors = ['r','g','b','m','y','c'];
    
    if name == 'MPC Control X  '
        axis = ["vel pitch", "pitch", "vel_x", "x"];
    elseif name == 'MPC Control Y  '
        axis = ["vel roll", "roll", "vel_y", "y"]; 
    elseif name == 'MPC Control Z  '
        axis = ["vel z", "z"];    
    elseif name == 'MPC Control Yaw'
        axis = ["vel yaw", "yaw"];   
    end
        
    figure('Name', name)
    
    if dim <= 2
        omega_inf.plot()
        xlabel(axis(1))
        ylabel(axis(2))
    else
        if mod(dim, 2) == 1
            dim = dim + 1;
        end
        
        t = tiledlayout(2,dim/2);
        for cnt=1:dim-1
            nexttile
            omega_inf.projection(cnt:cnt+1).plot('color',colors(cnt))
            xlabel(axis(cnt))
            ylabel(axis(cnt+1))
        end
    end
    

end

