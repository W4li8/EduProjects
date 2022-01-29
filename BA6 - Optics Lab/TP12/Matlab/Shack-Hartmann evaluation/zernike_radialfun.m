% ZERNIKE_RADIALFUN returns the
% radial function given a radial table row.
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function y = zernike_radialfun(radialtablerow)

radc = radialtablerow(1);
rads = radialtablerow(2);

if radc == 0 && rads == 0
    y = @(x) 1;
elseif radc ~= 0
    y = @(x) cos(radc.*x);
elseif rads ~= 0
    y = @(x) sin(rads.*x);
else
    throw(MException('VerifyOutput:IllegalInput', 'FIXME'));
end

end
