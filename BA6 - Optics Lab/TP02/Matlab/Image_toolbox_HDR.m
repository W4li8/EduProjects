%create a list of images to be used in HDR  
files = {'picture 43.jpg', 'picture 44.jpg'};

% define the list of relative exposure time 
expTimes = [2, 1];
 
%compose the image with optin 'relative exposure' 
%exif data would be used if available attached to the file for composition of the image

hdr = makehdr(files, 'RelativeExposure', expTimes ./ expTimes(1));

%Render high dynamic range image for viewing
rgb = tonemap(hdr);

figure; imshow(rgb)