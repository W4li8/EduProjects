% ZERNIKE_SURF plot w=Z*c.
% 
% [] = zernike_surf(zstruct, c).
% c                          coefficients
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function [] = zernike_surf(zstruct, c)

surf(zstruct.xx, zstruct.yy, zernike_eval(zstruct, c));
xlabel('x');
ylabel('y');

end
