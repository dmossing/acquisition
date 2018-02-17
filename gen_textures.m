function tex = gen_textures(wininfo,frames,aperture,show_center,show_surround,rotate_center,rotate_surround)
if nargin < 3
    aperture = [];
end
if nargin < 4
    show_center = true; 
    show_surround = false;
    rotate_center = false;
    rotate_surround = false;
end
% if nargin < 4 
%     rotate_surround = false;
% end
nframes = size(frames,3);
w = wininfo.w;
windowframe = 128*ones(wininfo.yRes,wininfo.xRes);
fr_ap = 128*ones(size(frames,1),size(frames,2));
for i=1:nframes
    fr = frames(:,:,i);
    if ~isempty(aperture)
        rotated = rot90(frames(:,:,i));
        if show_surround
            if rotate_surround
                fr_ap = rotated;
            else
                fr_ap = fr;
            end
        end
        if show_center
            if rotate_center
                fr_ap(aperture) = rotated(aperture);
            else
                fr_ap(aperture) = fr(aperture);
            end
        else
            fr_ap(aperture) = 128;
        end
    else
        fr_ap = fr;
    end
    windowframe((wininfo.yRes-size(frames,1))/2+1:(wininfo.yRes+size(frames,1))/2,...
        (wininfo.xRes-size(frames,2))/2+1:(wininfo.xRes+size(frames,2))/2) = fr_ap;
    tex(i) = Screen('MakeTexture', w, windowframe);
end