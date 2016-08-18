function [xpos,ypos] = mapRFstim(varargin)
%{
map RF using real time image acquisition from scanbox. Communicate with scanbox computer via UDP.
valid inputs (defaults):
'animalid'
'depth'
'screenNumber'
'orientations'
'repetitions'
'stimduration'
'isi'
'DScreen'
'VertScreenSize'
'sizes'
'cyclesPerVisDeg'
'cyclesPerSecond'
'ScreenType'
%}

%% initialize parameters

parse_inputs()

default_inputs()

frameRate = 60;     % Hz
assert(strcmp(ScreenType,'projector') || strcmp(ScreenType,'monitor'));
if strcmp(ScreenType,'projector')
    xRes = 1024; yRes = 768;
    VertCRTSize = 16;
else
    xRes = 1400; yRes = 1050;
    VertCRTSize = 27;
end
dos(['C:\Users\Resonant-2\Downloads\nircmd-x64\nircmd.exe setdisplay ' num2str(xRes) ' ' num2str(yRes) ' 32']);

%% find stim locations

xovy = xRes/yRes;
HorzCRTSize=VertCRTSize*xovy;
VertScreenDimDeg=atand(VertCRTSize/DScreen);
HorzScreenDimDeg=atand(HorzCRTSize/DScreen); % this is different from Vert*xovy!! We use vertical

PixperDeg=yRes/VertScreenDimDeg;
numFrames=ceil(frameRate/tFreq);
Bcol=128;
sizeGrating = gratingSize*PixperDeg;
width = round(sizeGrating/2);

ypositions = floor(mod(yRes,sizeGrating)/2)+(1:sizeGrating:yRes);
Ny = numel(ypositions);
xpositions = floor(mod(xRes,sizeGrating)/2)+(1:sizeGrating:xRes);
Nx = numel(xpositions);

%% initialize UDP connection, say you've started

H_2p = udp_open()

% while(~started) % wait for UDP msg signalling stim on to be received
%     if H_2p.BytesAvailable
%         process_stim_input(H_2p)
%     end
% end

fprintf(H_Stim,sprintf('R%d,%d',Ny,Nx));

%% deliver stims

try
    blI = BlackIndex(screenNumber);
    whI = WhiteIndex(screenNumber);
    maxDiff = abs(whI - blI);
    
    oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
    oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
    
    window = Screen('OpenWindow', screenNumber, Bcol);
    
    %     load('GammaTable.mat');
    %     CT = (ones(3,1)*correctedTable(:,2)')'/255;
    %     Screen('LoadNormalizedGammaTable',window, CT);
    
    %     HideCursor;
    
    [x,y]=meshgrid([-width:width],[-width:width]);
    nori = numel(orientations);
    for j = 1:nori
        for i = 1:numFrames
            phase=(i/numFrames)*2*pi;
            
            angle=orientations(j)*pi/180; % 30 deg orientation.
            f=(spFreq)/PixperDeg*2*pi; % cycles/pixel
            a=cos(angle)*f;
            b=sin(angle)*f;
            g0=exp(-((x/(5*width)).^2)-((y/(5*width)).^2));
            s=sin(a*x+b*y+phase);
            ext = max(max(max(s)),abs(min(min(s))));
            G0=ext*((s>0)-(s<0));%.*g0;
            incmax=min(255-Bcol,Bcol);
            G=(floor((incmax*G0)+Bcol));
            gratingFrame(i,j) = Screen('MakeTexture', window, G);
        end
    end
    
    % ------ Bookkeeping Variables ------
    
    gratingRect = [0 0 sizeGrating sizeGrating]; % The bounding box for our animated sprite
    gratingFrameIndex = 1; % Which frame of the animation should we show?
    oriIndex = 1;
    buttons = 0; % When the user clicks the mouse, 'buttons' becomes nonzero.
    mX = 0; % The x-coordinate of the mouse cursor
    mY = 0; % The y-coordinate of the mouse cursor
    
    % Exit the demo as soon as the user presses a mouse button.
    for i=1:Ny
        for j=1:Nx
            for oriIndex=1:nori
                for gratingFrameIndex=1:numFrames
                    fprintf(H_Stim,sprintf('N%d,%d',i,j));
                    pause(1)
                    mY = ypositions(i);
                    mX = xpositions(j);
                    % We need to redraw the text or else it will disappear after a
                    % subsequent call to Screen('Flip').
                    %         Screen('DrawText', window, 'Move the mouse.  Click to exit', 0, 0, blI);
                    %
                    %         % Get the location and click state of the mouse.
                    %         previousX = mX;
                    %         previousY = mY;
                    %         [mX, mY, buttons] = GetMouse;
                    
                    % Draw the sprite at the new location.
                    Screen('DrawTexture', window, gratingFrame(gratingFrameIndex,oriIndex), gratingRect, CenterRectOnPoint(gratingRect, mX, mY));
                    % Call Screen('Flip') to update the screen.  Note that calling
                    % 'Flip' after we have both erased and redrawn the sprite prevents
                    % the sprite from flickering.
                    Screen('Flip', window);
                    
                    %         gratingFrameIndex = gratingFrameIndex + 1;
                    %         if gratingFrameIndex > numFrames
                    %             gratingFrameIndex = 1;
                    %             oriIndex = oriIndex + 1;
                    %             if oriIndex > nori
                    %                 oriIndex = 1;
                    %             end
                    %         end
                end
            end
        end
    end
    
    %% say you've stopped and listen for stim position
    
    fprintf(H_Stim,'S')
    
    done = 0;
    while(~done)
        if H_2p.BytesAvailable
            process_2p_output(H_2p)
            done = 1;
        end
    end
    
    %     % Revive the mouse cursor.
    %     ShowCursor;
    
    %     xpos = round((mX-xRes/2)/PixperDeg)
    %     ypos = round((yRes/2-mY)/PixperDeg)
    
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
dos('C:\Users\Resonant-2\Downloads\nircmd-x64\nircmd.exe setdisplay 1920 1080 32');

%% local udp functions

    function H_2p = udp_open()
        twop_port = 26000; % this is the designated port for stim PC - scanbox PC communication
        H_2p = udp('128.32.173.32', 'RemotePort', twop_port, ...
            'LocalPort', stim_port,'BytesAvailableFcn',@process_2p_output);
        fopen(H_2p);
    end

    function udp_close(H_2p)
        fclose(H_2p);
        delete(H_2p);
    end

    function process_2p_output(a) %,DAQ)
        msg = fgetl(a);
        switch msg(1)
            case 'M'
                % reset: take as input the size of the array of locations that will be probed
                output = msg(2:end);
                coords = strsplit(output,',');
                imax = str2num(coords{1});
                jmax = str2num(coords{2});
                xpos = round(xpositions(jmax)/PixPerDeg);
                ypos = round(ypositions(imax)/PixPerDeg);
            otherwise
                error('invalid response from 2p computer')
        end
    end

%% local input parsing functions

    function parse_inputs()
        ctr = 1;
        while ctr <= nargin
            switch varargin{ctr}
                case 'orientations'
                    orientations = varargin{ctr+1};
                    ctr = ctr+2;
                case 'DScreen'
                    DScreen = varargin{ctr+1};
                    ctr = ctr+2;
                case 'ScreenType'
                    ScreenType = varargin{ctr+1};
                    ctr = ctr+2;
                case 'gratingSize'
                    gratingSize = varargin{ctr+1};
                    ctr = ctr+2;
                case 'spFreq'
                    spFreq = varargin{ctr+1};
                    ctr = ctr+2;
                case 'tFreq'
                    tFreq = varargin{ctr+1};
                    ctr = ctr+2;
                otherwise
                    error(sprintf('invalid argument %s',varargin{ctr}))
            end
        end
    end

    function default_inputs()
        % assign to default values
        
        if ~exist('orientations','var') || isempty(orientations)
            orientations = 0:45:315;
        end
        if ~exist('DScreen','var') || isempty(DScreen)
            DScreen = 15;
        end
        if ~exist('ScreenType','var') || isempty(ScreenType)
            ScreenType = 'projector';
        end
        if ~exist('gratingSize','var') || isempty(gratingSize)
            gratingSize = 45;
        end
        if ~exist('spFreq','var') || isempty(spFreq)
            spFreq = 0.08;
        end
        if ~exist('tFreq','var') || isempty(tFreq)
            tFreq = 1;
        end
        
    end

end
