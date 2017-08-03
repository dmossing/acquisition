function wininfo = gen_wininfo(result)
xRes = 1280; 
yRes = 1024;
Bcol = 128;
screenNumber = 0;

Screen('Preference', 'VBLTimestampingMode', -1);
Screen('Preference','SkipSyncTests', 0);
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
wininfo.Bcol = Bcol;
wininfo.screenNumber = screenNumber;

bg = ones(yRes,xRes)*Bcol;
wininfo.BG = Screen('MakeTexture', wininfo.w, bg);
end