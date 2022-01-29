% ZERNIKE_SURF2 plot w=Z*c.
% 
% [th rh] = zernike_surf2(zstruct, c, xx, yy, th, rh).
% c                          coefficients
% xx                         xx grid
% yy                         yy grid
% [th rh] = cart2pol(xx, yy)
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function [th rh] = zernike_surf2(zstruct, c, xx, yy, th, rh)

if ~exist('th', 'var')
    [th rh] = cart2pol(xx, yy);
end

radialtable = zstruct.radialtable;
azimtable = zstruct.azimtable;

zz = c(1)*ones(size(th));
for i=2:size(azimtable, 1)
    radc = azimtable(i, 1);
    rads = azimtable(i, 2);
    if radc == 0 && rads == 0
        zz = zz + c(i)*polyval(radialtable(i, :), rh);
    elseif radc ~= 0
        zz = zz + c(i)*polyval(radialtable(i, :), rh).*...
            cos(radc.*th);
    elseif rads ~= 0
        zz = zz + c(i)*polyval(radialtable(i, :), rh).*...
            sin(rads.*th);
    else
        throw(MException('VerifyOutput:IllegalInput', 'FIXME'));
    end
end

surf(xx, yy, zz);
xlabel('x');
ylabel('y');
view(2);


end
