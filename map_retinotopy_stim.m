function [xpos,ypos] = map_retinotopy_stim(ratio,orientations,DScreen,...
    ScreenType,gratingSize,spFreq,tFreq)

if nargin<2 || isempty(orientations)
    orientations = 0:45:315;
end
if nargin<3 || isempty(DScreen)
    DScreen = 15;
end
if nargin<4 || isempty(ScreenType)
    ScreenType = 'monitor';
end
if nargin<5 || isempty(gratingSize)
    gratingSize = 15;
end
if nargin<6 || isempty(spFreq)
    spFreq = 0.04;
end
if nargin<7 || isempty(tFreq)
    tFreq = 2;
end

% set up DAQ

daq=daq.createSession('ni');
addDigitalChannel(daq,'Dev3','port0/line0','OutputOnly'); % stim trigger
addDigitalChannel(daq,'Dev3','port0/line1','OutputOnly'); % projector LED on
addDigitalChannel(daq,'Dev3','port0/line2','OutputOnly'); % complete stim protocol, move in z

outputSingleScan(daq,[0 0 0]);

frameRate = 60;     % Hz
assert(strcmp(ScreenType,'projector') || strcmp(ScreenType,'monitor'));
if strcmp(ScreenType,'projector')
    xRes = 1024; yRes = 768;
    VertCRTSize = 13;
else
    xRes = 1280; yRes = 1024;
    VertCRTSize = 27;
end

% % dos(['C:\Users\Resonant-2\Downloads\nir cmd-x64\nircmd.exe setdisplay ' num2str(xRes) ' ' num2str(yRes) ' 32']);
% xovy = xRes/yRes;
% % DScreen=15;         % cm
% % VertCRTSize=15;   % cm
% HorzCRTSize=VertCRTSize*xovy;
% VertScreenDimDeg=atand(VertCRTSize/DScreen);
% HorzScreenDimDeg=atand(HorzCRTSize/DScreen); % this is different from Vert*xovy!! We use vertical
% % gratingSize = 15;   %visual degrees
% % orientation = 180;    % degrees
% % spFreq = .04;       % cycles/degree
% % tFreq = 1;          % cycles/s
% 
% PixperDeg=yRes/VertScreenDimDeg;
% Bcol=128;
% numFrames=ceil(frameRate/tFreq);
% sizeGrating = gratingSize*PixperDeg;
% width = round(sizeGrating/2);

try
    screenInfo = genscreenInfo(xRes,yRes,VertCRTSize,DScreen,Bcol);
    
%     screenNumber = max(Screen('Screens'));
%     
%     blI = BlackIndex(screenNumber);
%     whI = WhiteIndex(screenNumber);
%     maxDiff = abs(whI - blI);
%     
%     oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
%     oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
%     
%     window = Screen('OpenWindow', screenNumber, Bcol);
%     
%     %     load('GammaTable.mat');
%     %     CT = (ones(3,1)*correctedTable(:,2)')'/255;
%     %     Screen('LoadNormalizedGammaTable',window, CT);
%     
%     %     HideCursor;
%     
%     [x,y]=meshgrid([-width:width],[-width:width]);
    nori = numel(orientations);
    nCycles = 1;
    numFrames=ceil(nCycles*frameRate/tFreq);
    for j = 1:nori
        gratingInfo = gengratingInfo(gratingSize,spFreq,tFreq,orientations(j),nCycles);
        for i = 1:numFrames
%             phase=(i/numFrames)*2*pi;
%             angle=orientations(j)*pi/180; % 30 deg orientation.
%             f=(spFreq)/PixperDeg*2*pi; % cycles/pixel
%             a=cos(angle)*f;
%             b=sin(angle)*f;
%             g0=exp(-((x/(5*width)).^2)-((y/(5*width)).^2));
%             s=sin(a*x+b*y+phase);
%             ext = max(max(max(s)),abs(min(min(s))));
%             G0=ext*((s>0)-(s<0));%.*g0;
%             incmax=min(255-Bcol,Bcol);
%             G=(floor((incmax*G0)+Bcol));
%             gratingFrame(i,j) = Screen('MakeTexture', window, G);
            gratingFrame(i,j) = gengratingFrame(i,gratingInfo,screenInfo);
        end
        for k = 1:ratio*numFrames
            gratingFrame(numFrames+k,j) = Screen('MakeTexture', window, Bcol*ones(size(G)));
        end
    end
    % generate gray frames for baseline acquisition
    for j = 1:nori
        for i = 1:numFrames
            blankFrame(i,j) = Screen('MakeTexture', window, Bcol*ones(size(G)));
        end
        for k = 1:ratio*numFrames
            blankFrame(numFrames+k,j) = Screen('MakeTexture', window, Bcol*ones(size(G)));
        end
    end
    
    outputSingleScan(daq,[0 1 0])
    outputSingleScan(daq,[1 1 0])
    outputSingleScan(daq,[0 1 0])
    
    blankFrameIndex = 1;
    % Draw the sprite at the new location.
    while oriIndex <= nori
        Screen('DrawTexture', window, blankFrame(blankFrameIndex,oriIndex), gratingRect, CenterRectOnPoint(gratingRect, mX, mY));
        % Call Screen('Flip') to update the screen.  Note that calling
        % 'Flip' after we have both erased and redrawn the sprite prevents
        % the sprite from flickering.
        Screen('Flip', window);
        
        blankFrameIndex = blankFrameIndex + 1;
        if blankFrameIndex > (ratio+1)*numFrames
            blankFrameIndex = 1;
            oriIndex = oriIndex + 1;
        end
    end
    
    outputSingleScan(daq,[0 1 0])
    outputSingleScan(daq,[1 1 0])
    outputSingleScan(daq,[0 1 0])
    
    % ------ Bookkeeping Variables ------
    
    gratingRect = [0 0 sizeGrating sizeGrating]; % The bounding box for our animated sprite
    gratingFrameIndex = 1; % Which frame of the animation should we show?
    oriIndex = 1;
    buttons = 0; % When the user clicks the mouse, 'buttons' becomes nonzero.
    mX = 0; % The x-coordinate of the mouse cursor
    mY = 0; % The y-coordinate of the mouse cursor
    
    % Exit the demo as soon as the user presses a mouse button.
    for i=1:numlocs
        while ~any(buttons)
            % We need to redraw the text or else it will disappear after a
            % subsequent call to Screen('Flip').
            Screen('DrawText', window, 'Move the mouse.  Click to exit', 0, 0, blI);
            
            % Get the location and click state of the mouse.
            previousX = mX;
            previousY = mY;
            [mX, mY, buttons] = GetMouse;
            
            % Draw the sprite at the new location.
            Screen('DrawTexture', window, gratingFrame(gratingFrameIndex,oriIndex), gratingRect, CenterRectOnPoint(gratingRect, mX, mY));
            % Call Screen('Flip') to update the screen.  Note that calling
            % 'Flip' after we have both erased and redrawn the sprite prevents
            % the sprite from flickering.
            Screen('Flip', window);
            
            gratingFrameIndex = gratingFrameIndex + 1;
            if gratingFrameIndex > (ratio+1)*numFrames
                gratingFrameIndex = 1;
                oriIndex = oriIndex + 1;
                if oriIndex > nori
                    oriIndex = 1;
                end
            end
        end
        outputSingleScan(daq,[0 1 0])
        outputSingleScan(daq,[1 1 0])
        outputSingleScan(daq,[0 1 0])
    end
    
    for i=1:10
        outputSingleScan(daq,[0 1 0])
        outputSingleScan(daq,[1 1 0])
        outputSingleScan(daq,[0 1 0])
    end
    
    
    % Revive the mouse cursor.
    ShowCursor;
    
    xpos = round((mX-xRes/2)/PixperDeg)
    ypos = round((yRes/2-mY)/PixperDeg)
    
    % Close screen
    Screen('CloseAll');
    
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
    
catch
    
    % If there is an error in our try block, let's
    % return the user to the familiar MATLAB prompt.
    ShowCursor;
    Screen('CloseAll');
    Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);
    psychrethrow(psychlasterror);
    
end