function show_tex(wininfo,thisstim)
for i = 1:movieDurationFrames
    Screen('DrawTexture', wininfo.w, thisstim.tex(thisstim.movieFrameIndices(i)));
    Screen('Flip', wininfo.w);
end