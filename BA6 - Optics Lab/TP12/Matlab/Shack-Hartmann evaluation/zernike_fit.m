% ZERNIKE_FIT estimate c from w=Z*c.
% 
% [zc er reler map] = zernike_fit(zstruct, w).
% chat                       estimate of c
% er                         w - Z*chat
% rer                        relative error
% map                        used support
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function [chat er rer map] = zernike_fit(zstruct, w)

if (size(w, 2) == 1)
    assert(size(w, 1) == numel(zstruct.xx));
else
    assert(size(w, 1) == size(zstruct.xx, 1));
    assert(size(w, 2) == size(zstruct.xx, 2));
    w = reshape(w, numel(zstruct.xx), 1);
end

% consider only the unit circle and finite values
map = logical(isfinite(w).*zstruct.vsuppmap);
Ztw = zstruct.zi(map, :)'*w(map);
chat = zstruct.ZtZ\Ztw;

if nargout >= 2
    er = w - zstruct.zi*chat;
    er(~map) = -Inf;
end

if nargout >= 3
    rer = norm(er(map))/norm(w(map));
end

end
