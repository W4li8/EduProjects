% ZERNIKE_TABLE create tables for zernike polynomials up
% to radial order n. Zernike polynomials are ordered according
% to Mahajan:94.
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function zstruct = zernike_table(n)

% @article{Mahajan:94, 
% author = {Virendra N. Mahajan}, 
% journal = {Appl. Opt.}, 
% keywords = {},
% number = {34}, 
% pages = {8121--8121}, 
% publisher = {OSA},
% title = {Zernike Circle Polynomials and Optical Aberrations of Systems with Circular Pupils}, 
% volume = {33}, 
% month = {Dec},
% year = {1994},
% url = {http://ao.osa.org/abstract.cfm?URI=ao-33-34-8121},
% doi = {10.1364/AO.33.008121},
% abstract = {Zernike circle polynomials, their numbering scheme, and relationship to balanced optical aberrations of systems with circular pupils are discussed.},
% }

tot = (n + 1)*(n + 2)/2;

radialtable = zeros(tot, n + 1);
azimtable = zeros(tot, 2);

radialtable(1, end) = 1;

count = 2;
for ni=1:n
    mi = rem(ni, 2);
    while mi <= ni
        if mi == 0
            radialtable(count, :) = sqrt(ni + 1)*...
                zernike_rho_n_m(ni, mi, n);
            azimtable(count, :) = [0 0];
            count = count + 1;
        else
            radialtable(count + 0, :) = sqrt(2*(ni + 1))*...
                zernike_rho_n_m(ni, mi, n);
            radialtable(count + 1, :) = sqrt(2*(ni + 1))*...
                zernike_rho_n_m(ni, mi, n);
            if rem(count, 2)
                azimtable(count + 0, :) = [0 mi];
                azimtable(count + 1, :) = [mi 0];
            else
                azimtable(count + 0, :) = [mi 0];
                azimtable(count + 1, :) = [0 mi];
            end
            
            count = count + 2;
        end
    
    mi = mi + 2;
    end
end

zstruct = struct();
zstruct.radialtable = radialtable;
zstruct.azimtable = azimtable;
zstruct.ncoeff = tot;

    function z = zernike_rho_n_m(n, m, ord)
        z = zeros(1, ord + 1);
        for s=0:((n - m)/2)
            z(ord + 1 - (n - 2*s)) = ...
                (((-1)^s)*factorial(n - s))/...
                (factorial(s)*factorial((n + m)/2 - s)*...
                factorial((n - m)/2 - s));
        end
    end
end
