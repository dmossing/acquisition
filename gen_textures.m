function tex = gen_textures(wininfo,frames,aperture)
if nargin < 3
    aperture = [];
end
nframes = size(frames,3);
w = wininfo.w;
windowframe = 128*ones(wininfo.yRes,wininfo.xRes);
fr_ap = 128*ones(size(frames,1),size(frames,2));
for i=1:nframes
    fr = frames(:,:,i);
    if ~isempty(aperture)
        fr_ap(aperture) = fr(aperture);
    else
        fr_ap = fr;
    end
    windowframe((wininfo.yRes-size(frames,1))/2+1:(wininfo.yRes+size(frames,1))/2,...
        (wininfo.xRes-size(frames,2))/2+1:(wininfo.xRes+size(frames,2))/2) = fr_ap;
    tex(i) = Screen('MakeTexture', w, windowframe);
end