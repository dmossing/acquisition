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

blI = BlackIndex(screenNumber);
whI = WhiteIndex(screenNumber);
maxDiff = abs(whI - blI);

oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);

screenInfo.window = Screen('OpenWindow', screenNumber, Bcol);