function show_tex_trig(wininfo,thisstim,d)
% thisstim just needs to have fields tex, movieDurationFrames, and
% movieFrameIndices
DaqDOut(d,0,0);
DaqDOut(d,0,255);
DaqDOut(d,0,0);
for i = 1:thisstim.movieDurationFrames
    Screen('DrawTexture', wininfo.w, thisstim.tex(thisstim.movieFrameIndices(i)));
    Screen('Flip', wininfo.w);
    if thisstim.trigonframe(i)
        DaqDOut(d,0,0);
        DaqDOut(d,0,255);
        DaqDOut(d,0,0);
    end
end
DaqDOut(d,0,0);
DaqDOut(d,0,255);
DaqDOut(d,0,0);