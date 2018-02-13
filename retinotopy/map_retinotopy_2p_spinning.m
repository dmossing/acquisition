function [xpos,ypos] = map_retinotopy_2p_spinning(ratio,orientations,DScreen,...
    ScreenType,gratingSize,spFreq,tFreq,nreps)

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
    gratingSize = 10;
end
if nargin<6 || isempty(spFreq)
    spFreq = 0.08;
end
if nargin<7 || isempty(tFreq)
    tFreq = 2;
end
if nargin<8 || isempty(nreps)
    nreps = 1;
end

% set up DAQ

% do stimulus data file management
% stimfolder = 'C:/Users/Resonant-2/Documents/Dan/StimData/';
stimFolderRemote = '/home/mossing/excitation/mossing/visual_stim/';
stimFolderLocal = '/home/visual-stim/Documents/StimData/';
dstr = yymmdd(date);
resDirRemote = [stimFolderRemote dstr '/' result.animalid '/'];
if ~exist(resDirRemote,'dir')
    mkdir(resDirRemote)
end
resDirLocal = [stimFolderLocal dstr '/' result.animalid '/'];
if ~exist(resDirLocal,'dir')
    mkdir(resDirLocal)
end

nexp  =  ddigit(length(dir(fullfile(resDirLocal,'*.mat'))),3);
fnameLocal  =  strcat(resDirLocal,result.animalid,'_',result.depth,'_',nexp,'.mat');
fnameRemote  =  strcat(resDirRemote,result.animalid,'_',result.depth,'_',nexp,'.mat');
result.nexp = nexp;

base = result.animalid;
depth = result.depth;
fileindex = result.nexp;
runpath = '//adesnik2.ist.berkeley.edu/excitation/mossing/LF2P/running/';
runfolder = [runpath dstr '/' base];
if ~exist(runfolder,'dir')
    mkdir(runfolder)
end
% if strcmp(result.modality,'2p')

set up scanbox communication

sb_ip = '128.32.173.30'; % SCANBOX ONLY: for UDP
sb_port = 7000; % SCANBOX ONLY: for UDP

initialize connection
H_Scanbox = udp(sb_ip, 'RemotePort', sb_port); % create udp port handle
fopen(H_Scanbox);

clean up udp connection in case of Ctrl-C
cleanup_udp_Scanbox = onCleanup(@() terminate_udp(H_Scanbox));

% write filename
fprintf(H_Scanbox,sprintf('A%s',base));
fprintf(H_Scanbox,sprintf('U%s',depth));
fprintf(H_Scanbox,sprintf('E%s',fileindex));

% else
%
%     lf_ip = '128.32.19.203';
%     lf_port = 29000;
%
%     % initialize connection
%     H_lf = udp(lf_ip, 'RemotePort', lf_port);
%     fopen(H_lf);
%
%     cleanup_udp_lf = onCleanup(@() terminate_udp(H_lf));
%     runpath = '//E:LF2P/ ... NEED TO FILL IN';
%     fprintf(H_lf,sprintf('G%s/%s_%s_%s.dat', runfolder, base, depth, fileindex));
% end

% set up running comp communication

run_ip = '128.32.19.202'; % for UDP
run_port = 25000; % for UDP

% initialize connection
H_Run = udp(run_ip, 'RemotePort', run_port, 'LocalPort', run_port); % create udp port handle
fopen(H_Run);

% clean up udp connection in case of Ctrl-C
cleanup_udp_Run = onCleanup(@() terminate_udp(H_Run));

base = result.animalid;
depth = result.depth;
fileindex = result.nexp;

% % write filename

fprintf(H_Run,sprintf('G%s/%s_%s_%s.bin', runfolder, base, depth, fileindex));
fprintf(H_Scanbox,'G'); %go

% daq=daq.createSession('ni');
% addDigitalChannel(daq,'Dev3','port0/line0','OutputOnly'); % stim trigger
% addDigitalChannel(daq,'Dev3','port0/line1','OutputOnly'); % projector LED on
% addDigitalChannel(daq,'Dev3','port0/line2','OutputOnly'); % complete stim protocol, move in z
d = DaqFind;
err = DaqDConfigPort(d,0,0);

% set up msocket

srvsock = mslisten(3000);
% % tell the other PC to open up a socket
% % outputSingleScan(daq,[0 0 0]);
% % outputSingleScan(daq,[1 0 0]);
% % outputSingleScan(daq,[0 0 0]);
DaqDOut(d,0,0);
DaqDOut(d,0,255);

pause(1)
% % assume the other PC has responded by requesting a connection by this
% % point
sock = msaccept(srvsock);
msclose(srvsock);

DaqDOut(d,0,255);
DaqDOut(d,0,0);

frameRate = 60;     % Hz
% assert(strcmp(ScreenType,'projector') || strcmp(ScreenType,'monitor'));
% if strcmp(ScreenType,'projector')
%     xRes = 1024; yRes = 768;
%     VertCRTSize = 13;
% else
% %     xRes = 1024; yRes = 768;
xRes = 1280; yRes = 1024;
VertCRTSize = 27;
% end

Bcol = 128;
screenInfo = genscreenInfo(xRes,yRes,VertCRTSize,DScreen,frameRate,Bcol);
window = screenInfo.window;
try
    
    locs = tileScreen(gratingSize,screenInfo);
    [ny,nx,~] = size(locs);
    nori = numel(orientations);
    [indy,indx] = meshgrid(1:ny,1:nx);
    order = randperm(ny*nx);
    locinds = [indy(order); indx(order)]';
    locinds = repmat(locinds,nreps,1);
    
    % % % SEND THIS (locinds) TO OTHER PC VIA MSOCKET
    %     pause(1)
    %     mssend([ny,nx])
    pause(1)
    mssend(sock,locinds)
    
    nCycles = 0.5;
    numEach = ceil(nCycles*frameRate/tFreq);
    numFrames = nori*numEach;
    sizeGrating = ceil(gratingSize*screenInfo.PixperDeg);
    for j = 1:nori
        start = (j-1)*numEach;
        gratingInfo = gengratingInfo(gratingSize,spFreq,tFreq,orientations(j));
        for i = 1:numEach
            gratingFrame(start+i) = gengratingFrame(i,gratingInfo,screenInfo);
        end
    end
    for k = 1:ratio*numFrames
        gratingFrame(numFrames+k) = gensolidFrame(screenInfo,sizeGrating);
    end
    % generate gray frames for baseline acquisition
    for j = 1:nori
        for i = 1:numFrames
            blankFrame(i) = gensolidFrame(screenInfo);
        end
        for k = 1:ratio*numFrames
            blankFrame(numFrames+k) = gensolidFrame(screenInfo);
        end
    end
    
    %     outputSingleScan(daq,[0 1 0])
    %     outputSingleScan(daq,[1 1 0])
    %     outputSingleScan(daq,[0 1 0])
    
    gratingRect = [0 0 sizeGrating sizeGrating]; % The bounding box for our animated sprite
    oriIndex = 1;
    blankFrameIndex = 1;
    buttons = 0; % When the user clicks the mouse, 'buttons' becomes nonzero.
    mX = 0; % The x-coordinate of the mouse cursor
    mY = 0; % The y-coordinate of the mouse cursor
    % Draw the sprite at the new location.
    while oriIndex <= nori
        Screen('DrawTexture', window, blankFrame(blankFrameIndex), [0 0 1 1], CenterRectOnPoint([0 0 1 1], mX, mY));
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
    %     outputSingleScan(daq,[0 1 0])
    %     outputSingleScan(daq,[1 1 0])
    %     outputSingleScan(daq,[0 1 0])
    %     pause(0.5)
    %     outputSingleScan(daq,[0 1 0])
    %     outputSingleScan(daq,[1 1 0])
    %     outputSingleScan(daq,[0 1 0])
    %     numlocs = 5;
    
    % Exit the demo as soon as the user presses a mouse button.
    for repindex=1:nreps
        for i=1:numel(order)
            % ------ Bookkeeping Variables ------
            gratingRect = [0 0 sizeGrating sizeGrating]; % The bounding box for our animated sprite
            gratingFrameIndex = 1; % Which frame of the animation should we show?
            %         oriIndex = indo(order(i));
            % We need to redraw the text or else it will disappear after a
            % subsequent call to Screen('Flip').
            Screen('DrawText', window, 'Click to exit', 0, 0, screenInfo.blI);
            mY = locs(indy(order(i)),indx(order(i)),1);
            mX = locs(indy(order(i)),indx(order(i)),2);
            % Draw the sprite at the new location.
            DaqDOut(d,0,0);
            DaqDOut(d,0,255);
            DaqDOut(d,0,127);
            while gratingFrameIndex < (ratio)*numFrames
                Screen('DrawTexture', window, gratingFrame(gratingFrameIndex), gratingRect, CenterRectOnPoint(gratingRect, mX, mY));
                % Call Screen('Flip') to update the screen.  Note that calling
                % 'Flip' after we have both erased and redrawn the sprite prevents
                % the sprite from flickering.
                Screen('Flip', window);
                gratingFrameIndex = gratingFrameIndex + 1;
            end
            DaqDOut(d,0,127);
            DaqDOut(d,0,255);
            DaqDOut(d,0,0);
            while gratingFrameIndex < (ratio+1)*numFrames
                Screen('DrawTexture', window, gratingFrame(gratingFrameIndex), gratingRect, CenterRectOnPoint(gratingRect, mX, mY));
                % Call Screen('Flip') to update the screen.  Note that calling
                % 'Flip' after we have both erased and redrawn the sprite prevents
                % the sprite from flickering.
                Screen('Flip', window);
                gratingFrameIndex = gratingFrameIndex + 1;
            end
            %         outputSingleScan(daq,[0 1 0])
            %         outputSingleScan(daq,[1 1 0])
            %         outputSingleScan(daq,[0 1 0])
        end
    end
    
    for i=1:10
        %         outputSingleScan(daq,[0 1 0])
        %         outputSingleScan(daq,[1 1 0])
        %         outputSingleScan(daq,[0 1 0])
        DaqDOut(d,0,0);
        DaqDOut(d,0,255);
        DaqDOut(d,0,0);
    end
    msclose(sock);
    terminate_udp(H_Scanbox)
    terminate_udp(H_Run)
    
    % Revive the mouse cursor.
    ShowCursor;
    PixperDeg = screenInfo.PixperDeg;
    xpos = round((locs(:,:,2)-xRes/2)/PixperDeg)
    ypos = round((yRes/2-locs(:,:,1))/PixperDeg)
    
    % Close screen
    Screen('CloseAll');
    
    % Restore preferences
    Screen('Preference', 'VisualDebugLevel', screenInfo.oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', screenInfo.oldSupressAllWarnings);
    
catch
    disp('error')
    % If there is an error in our try block, let's
    % return the user to the familiar MATLAB prompt.
    ShowCursor;
    Screen('CloseAll');
    Screen('Preference', 'VisualDebugLevel', screenInfo.oldVisualDebugLevel);
    Screen('Preference', 'SuppressAllWarnings', screenInfo.oldSupressAllWarnings);
    psychrethrow(psychlasterror);
    
    for i=1:10
        %         outputSingleScan(daq,[0 1 0])
        %         outputSingleScan(daq,[1 1 0])
        %         outputSingleScan(daq,[0 1 0])
        DaqDOut(d,0,0);
        DaqDOut(d,0,255);
        DaqDOut(d,0,0);
    end
    msclose(sock);
end

    function terminate_udp(handle)
        fprintf(handle,'S');
        fclose(handle);
        delete(handle);
    end