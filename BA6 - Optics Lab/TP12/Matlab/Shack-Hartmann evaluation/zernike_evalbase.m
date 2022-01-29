% ZERNIKE_EVALBASE evaluate Z_i in polar coordinates.
% 
% y = zernike_evalbase(zstruct, ind, rh, th).
% ind                        base index
% rh                         rho table
% th                         theta table
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function y = zernike_evalbase(zstruct, ind, rh, th)

radialtable = zstruct.radialtable;
azimtable = zstruct.azimtable;

if ind == 1
    y = 1;
else
    radc = azimtable(ind, 1);
    rads = azimtable(ind, 2);
    if radc == 0 && rads == 0
        y = polyval(radialtable(ind, :), rh);
    elseif radc ~= 0
        y = polyval(radialtable(ind, :), rh).*...
            cos(radc.*th);
    elseif rads ~= 0
        y = polyval(radialtable(ind, :), rh).*...
            sin(rads.*th);
    else
        throw(MException('VerifyOutput:IllegalInput', 'FIXME'));
    end
end

end
