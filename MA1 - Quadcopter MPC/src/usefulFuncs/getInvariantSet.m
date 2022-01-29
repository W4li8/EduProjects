function omega_inf = getInvariantSet(P, A, F, f)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%     [n,~] = size(A);
%     [q,m] = size(G);

    omega{1} = P;
    finish = false;
    i = 1;
    while ~finish
        %preSet = projection(Polyhedron([F*A F*B;zeros(q,n) G], [f;g]), [1:n]);
        preSet = Polyhedron(F*A^i, f);
        omega{i+1} = intersect(preSet, omega{i});
        if omega{i+1} == omega{i} 
           finish = true; 
        end
        i = i + 1;
    end
    omega_inf = omega{i};
end

