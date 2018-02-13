function wininfo = gen_wininfo(result)
% xRes = 1024; 
% yRes = 768;
% xRes = 1280; % Dell 170S monitors
% yRes = 1024;
Bcol = 128;
screenNumber = 0;
scaleby = 0.5;
xRes = RectWidth(Screen('Rect', screenNumber))*scaleby;
yRes = RectHeight(Screen('Rect', screenNumber))*scaleby;
fitSize = [xRes,yRes];
% 
PsychImaging('PrepareConfiguration');

PsychImaging('AddTask', 'General', 'UsePanelFitter', fitSize, 'Aspect');

Screen('Preference', 'VBLTimestampingMode', -1);
% Screen('Preference','SkipSyncTests', 1); %%% TEMPORARY
Screen('Preference','SkipSyncTests', 0);

% Center small framebuffer inside big framebuffer. Scale it up to
% maximum size while preserving aspect ration of the original
% framebuffer:

[w,~] = PsychImaging('OpenWindow',screenNumber); %Screen('OpenWindow',screenNumber);

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