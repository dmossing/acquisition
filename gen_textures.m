function tex = gen_textures(wininfo,frames)
nframes = size(frames,3);
w = wininfo.w;
for i=1:nframes
    tex(i) = Screen('MakeTexture', w, frames(:,:,i));
end