function solidFrame = gensolidFrame(screenInfo,L,color)
if nargin < 2
    L = 1;
end
if nargin < 3
    color = screenInfo.Bcol;
end
solidFrame = Screen('MakeTexture', screenInfo.window, color*ones(L));
end
