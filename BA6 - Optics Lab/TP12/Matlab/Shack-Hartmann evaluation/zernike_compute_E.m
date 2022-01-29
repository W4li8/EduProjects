% ZERNIKE_COMPUTE_E computes matrix E, see Dai 1994.
% 
% E = zernike_compute_E(zstruct, shstruct)
% shstruct.pupil_radius_m    pupil radius
% shstruct.sa_radius_m       subapertura radius
%
% Author Jacopo Antonello, jack at antonello dot org
% 20130125
% Technische Universiteit Delft

function E = zernike_compute_E(zstruct, shstruct)

% @conference{dai:562,
% author = {Guang-Ming Dai},
% editor = {Mark A. Ealey and Fritz Merkle},
% collaboration = {},
% title = {Modified Hartmann-Shack wavefront sensing and iterative wavefront reconstruction},
% publisher = {SPIE},
% year = {1994},
% journal = {Adaptive Optics in Astronomy},
% volume = {2201},
% number = {1},
% pages = {562-573},
% location = {Kailua, Kona, HI, USA},
% url = {http://link.aip.org/link/?PSI/2201/562/1},
% doi = {10.1117/12.176040}
% }

% @article{Primot:90, 
% author = {J. Primot and G. Rousset and J. C. Fontanella}, 
% journal = {J. Opt. Soc. Am. A}, 
% keywords = {},
% number = {9}, 
% pages = {1598--1608}, 
% publisher = {OSA},
% title = {Deconvolution from wave-front sensing: a new technique for compensating turbulence-degraded images}, 
% volume = {7}, 
% month = {Sep},
% year = {1990},
% url = {http://josaa.osa.org/abstract.cfm?URI=josaa-7-9-1598},
% doi = {10.1364/JOSAA.7.001598},
% abstract = {A new technique of high-resolution imaging through atmospheric turbulence is described. As in speckle interferometry, short-exposure images are recorded, but in addition the associated wave fronts are measured by a Hartmann-Shack wave-front sensor. The wave front is used to calculate the point-spread function. The object is then estimated from the correlation of images and point-spread functions by a deconvolution process. An experimental setup is described, and the first laboratory results, which prove the capabilities of the method, are presented. A signal-to-noise-ratio calculation, permitting a first comparison with the speckle interferometry, is also presented.},
% }

pupil_radius_m = shstruct.pupil_radius_m;
sa_radius_m = shstruct.sa_radius_m;
csa_ind = shstruct.sa_centralspot;
ncoefs = zstruct.ncoeff;
nspots = shstruct.nspots;
ord_centres = shstruct.ord_centres;
pixsize = shstruct.camera_pixsize;

radtab = zstruct.radialtable;
azimtab = zstruct.azimtable;

E = zeros(2*shstruct.nspots, ncoefs);

sac = ord_centres(csa_ind, :);
rho_sa = sa_radius_m/pupil_radius_m;

kk = pupil_radius_m/(pi*(sa_radius_m^2));

for i=1:nspots
    y0x0 = (ord_centres(i, :) - sac)*pixsize;
    rho_0 = norm(y0x0)/(pupil_radius_m);
    theta_0 = atan2(y0x0(1), y0x0(2));
    if rho_0 > 1
        throw(MException('VerifyOutput:IllegalInput', ...
            'The aperture radius is too small, use a larger pupil_radius_m'));
    end
    
    for zi=2:ncoefs
        radtabrow = radtab(zi, :);
        azimtabrow = azimtab(zi, :);
        
        [ey ex] = zernike_compute_EyEx(...
            radtabrow, azimtabrow, ...
            rho_0, theta_0, rho_sa);
        % average over [0 1] rho pupil
        E(i, zi) = kk*ey;
        E(i + nspots, zi) = kk*ex;
    end
end

end
