function screenInfo = genscreenInfo(xRes,yRes,VertCRTSize,DScreen,frameRate,Bcol)
% try
xovy = xRes/yRes;
HorzCRTSize=VertCRTSize*xovy;
VertScreenDimDeg=atand(VertCRTSize/DScreen);
HorzScreenDimDeg=atand(HorzCRTSize/DScreen); % this is different from Vert*xovy!! We use vertical
PixperDeg=yRes/VertScreenDimDeg;

screenInfo.PixperDeg = PixperDeg;
screenInfo.Bcol = Bcol;
screenInfo.frameRate = frameRate;

screenNumber = max(Screen('Screens'));
screenInfo.screenNumber = screenNumber;

blI = BlackIndex(screenNumber);
whI = WhiteIndex(screenNumber);
screenInfo.blI = blI;
screenInfo.whI = whI;
screenInfo.maxDiff = abs(whI - blI);

screenInfo.oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
screenInfo.oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);

screenInfo.window = Screen('OpenWindow', screenNumber, Bcol);