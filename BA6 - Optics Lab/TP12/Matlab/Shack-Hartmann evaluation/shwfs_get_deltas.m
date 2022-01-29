% SHWFS_GET_DELTAS
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft
function deltas = shwfs_get_deltas(img, shstruct, centroid)

centres = shstruct.ord_centres;
moved = shwfs_get_centres(img, shstruct, centroid);

deltas = moved - centres;

end

