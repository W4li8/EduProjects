%SHWFS_GET_CENTRES     Gets the spots centres.
%   centres = sh_get_centres(img, shstruct, myfuncentroid) gets the
%   pixel coordinates of the spots from an image in doubles of
%   the Shack-Hartmann wavefront sensor. centres(:, 1) are
%   the displacements in Y (left to right). centres(:, 2) are
%   the displacements in X (top to bottom). Displacements
%   are ordered according shstruct.enumeration. centres(i, 1)
%   corresponds to the i-th spot (shstruct.enumeration(i)).
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft
function centres = shwfs_get_centres(img, shstruct, ...
    myfuncentroid)

nspots = shstruct.nspots;
ordgrid = shstruct.ord_sqgrid;

centres = zeros(nspots, 2);

for ith=1:nspots
    cc = ordgrid(ith, :);

    % images are height by width!
    if (shstruct.use_bg)
        subimage = img(cc(3):cc(4), cc(1):cc(2)) - ...
            shstruct.bg(cc(3):cc(4), cc(1):cc(2));
    else
        subimage = img(cc(3):cc(4), cc(1):cc(2));
    end
    
    iimin = min(min(subimage));
    iimax = max(max(subimage));
    level = (iimax - iimin)*shstruct.percent + iimin;

    dd = myfuncentroid(subimage, level);
    centres(ith, :) = [cc(1)+dd(2)-1 cc(3)+dd(1)-1];
end

end
