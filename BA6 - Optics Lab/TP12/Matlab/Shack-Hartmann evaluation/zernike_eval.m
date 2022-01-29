% ZERNIKE_EVAL evaluate w=Z*c.
% 
% [w wv] = zernike_eval(zstruct, zc).
% returns the value of Phi evaluated over the pupil in
% a surface, w or vectorised form wv=vec(w).
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function [w wv] = zernike_eval(zstruct, zc)

if nargout == 1
    w = reshape(zstruct.zi*zc, size(zstruct.xx));
elseif nargout == 2
    w =[];
    wv = zstruct.zi*zc;
end

end
