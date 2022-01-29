% ZERNIKE_CACHE pre-evaluate Zernike polynomials over a grid.
% 
% zstruct = zernike_cache(zstruct, xx, yy)
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function zstruct = zernike_cache(zstruct, xx, yy)

radialtable = zstruct.radialtable;
azimtable = zstruct.azimtable;

[th rh] = cart2pol(xx, yy);

zstruct.xx = xx;
zstruct.yy = yy;
zstruct.th = th;
zstruct.rh = rh;

% exclude points outside the unit circle
suppmap = (rh <= 1);
% suppmap = logical(ones(size(rh)));
zstruct.suppmap = suppmap;
vsuppmap = vec(suppmap);
zstruct.vsuppmap = vsuppmap;
nnzsupp = nnz(suppmap);
zstruct.nnzsupp = nnzsupp;

ncoeff = zstruct.ncoeff;
nel = numel(xx);
zi = zeros(nel, ncoeff);

piston = ones(size(xx));
piston(~suppmap) = -Inf;
zi(:, 1) = vec(piston);

for i=2:ncoeff
    radc = azimtable(i, 1);
    rads = azimtable(i, 2);
    if radc == 0 && rads == 0
        mode = polyval(radialtable(i, :), rh);
    elseif radc ~= 0
        mode = polyval(radialtable(i, :), rh).*...
            cos(radc.*th);
    elseif rads ~= 0
        mode = polyval(radialtable(i, :), rh).*...
            sin(rads.*th);
    else
        throw(MException('VerifyOutput:IllegalInput', 'FIXME'));
    end
    mode(~suppmap) = -Inf;
    zi(:, i) = vec(mode);
end

zstruct.zi = zi;
zstruct.nel = nel;

% J. Wang and D. Silva, "Wave-front interpretation with Zernike
% polynomials," Appl. Opt.  19, 1510-1518 (1980).
ZtZ = zi(vsuppmap, :)'*zi(vsuppmap, :);
zstruct.ZtZ = ZtZ;

end
