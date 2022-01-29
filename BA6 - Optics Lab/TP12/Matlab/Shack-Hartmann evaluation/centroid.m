function [ret] = centroid(im, thr)

% global select;

if (nargin < 2)
    thr = 0;
end

[w h] = size(im);

mass = 0;
sumx = 0;
sumy = 0;

for x=1:w
    for y=1:h
        val = im(x, y);
        if (val >= thr)
            sumx = sumx + val*x;
            sumy = sumy + val*y;
            mass = mass + val;
        end
    end
end


ret = [sumx/mass sumy/mass];
% ret = round(ret);

% if select
% figure(12);
% imshow(im);
% hold on;
% plot(ret(2), ret(1), 'xr');
% pause(0.1);
% end

end
