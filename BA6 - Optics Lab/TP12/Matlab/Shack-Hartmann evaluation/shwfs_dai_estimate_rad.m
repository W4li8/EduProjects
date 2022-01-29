% SHWFS_DAI_ESTIMATE_RAD
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function [zrad2 er] = shwfs_dai_estimate_rad(img, shstruct, centroid)

lambda = shstruct.lambda;
flen = shstruct.flength;
ps = shstruct.camera_pixsize;

s = vec(ps*shwfs_get_deltas(img, shstruct, centroid));

E1 = flen*(shstruct.dai_E1);
zrad = (E1\s);

se = E1*zrad;
er = s - se;

zrad2 = ((2*pi)/(lambda))*zrad;

end

