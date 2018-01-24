function tex = gen_textures(wininfo,frames,aperture)
if nargin < 3
    aperture = [];
end
nframes = size(frames,3);
w = wininfo.w;
fr_ap = 128*ones(wininfo.yRes,wininfo.xRes);
for i=1:nframes
    fr = frames(:,:,i);
    if ~isempty(aperture)
        fr_ap(aperture) = fr(aperture);
    else
        fr_ap = fr;
    end
    tex(i) = Screen('MakeTexture', w, fr_ap);
end