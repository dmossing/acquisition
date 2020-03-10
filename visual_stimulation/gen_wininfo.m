function wininfo = gen_wininfo(result)
% xRes = 1024; 
% yRes = 768;
% xRes = 1280; % Dell 170S monitors
% yRes = 1024;
if isfield(result,'isi_luminance')
    Bcol = round(255*result.isi_luminance);
else
    Bcol = 128;
end
screenNumber = 0;
blI = BlackIndex(screenNumber);
whI = WhiteIndex(screenNumber);
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

[w,~] = PsychImaging('OpenWindow',screenNumber,Bcol); %Screen('OpenWindow',screenNumber);

VertScreenDimDeg = atand(result.VertScreenSize/result.DScreen); % in visual degrees
PixperDeg = yRes/VertScreenDimDeg;
try
    xposStim = result.position(:,1);
    yposStim = result.position(:,2);
catch
    xposStim = NaN;
    yposStim = NaN;
end
frameRate = Screen('FrameRate',screenNumber);

wininfo.xRes = xRes;
wininfo.yRes = yRes;
wininfo.w = w;
wininfo.window = w;
wininfo.PixperDeg = PixperDeg;
wininfo.xposStim = xposStim;
wininfo.yposStim = yposStim;
wininfo.frameRate = frameRate;
wininfo.Bcol = Bcol;
wininfo.blI = blI;
wininfo.whI = whI;
wininfo.screenNumber = screenNumber;

bg = ones(yRes,xRes)*Bcol;
wininfo.BG = Screen('MakeTexture', wininfo.w, bg);
end