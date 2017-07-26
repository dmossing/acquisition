function wininfo = gen_wininfo(result)
xRes = 1280; 
yRes = 1024;
screenNumber = 0;
[w,~] = Screen('OpenWindow',screenNumber);
VertScreenDimDeg = atand(result.VertScreenSize/result.DScreen); % in visual degrees
PixperDeg = yRes/VertScreenDimDeg;
xposStim = result.position(1);
yposStim = result.position(2);
frameRate = Screen('FrameRate',screenNumber);

wininfo.xRes = xRes;
wininfo.yRes = yRes;
wininfo.w = w;
wininfo.PixperDeg = PixperDeg;
wininfo.xposStim = xposStim;
wininfo.yposStim = yposStim;
wininfo.frameRate = frameRate;
end