function [xpos,ypos] = map_retinotopy_2p_spinning(varargin) %(ratio,orientations,DScreen,...
%     ScreenType,gratingSize,spFreq,tFreq,nreps)

p = inputParser;
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('repetitions',3);
p.addParameter('ratio',1);
p.addParameter('DScreen',15);
p.addParameter('VertScreenSize',27);
p.addParameter('sizes',10);
p.addParameter('grid',1)
p.addParameter('contrast',1);
p.addParameter('orientations',0:45:315);
p.addParameter('spFreq',0.08); % cyc/vis deg
p.addParameter('tFreq',2); % cyc/sec
p.parse(varargin{:});

result = p.Results;
% set up DAQ

user_quit = false;

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

%set up scanbox communication

sb_ip = '128.32.173.30'; % SCANBOX ONLY: for UDP
sb_port = 7000; % SCANBOX ONLY: for UDP

% initialize connection
H_Scanbox = udp(sb_ip, 'RemotePort', sb_port); % create udp port handle
fopen(H_Scanbox);

% clean up udp connection in case of Ctrl-C
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

d = configure_mcc_daq;

wininfo = gen_wininfo(result);

% % write filename

fprintf(H_Run,sprintf('G%s/%s_%s_%s.bin', runfolder, base, depth, fileindex));
fprintf(H_Scanbox,'G'); %go

DaqDOut(d,0,0);
DaqDOut(d,0,255);

handshook = false;
while ~handshook
    TTLin = DaqDIn(d);
    handshook = max(TTLin)>=128;
end

% set up msocket

srvsock = mslisten(3000);

% pause(3)
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
% xRes = 1280; yRes = 1024;
% VertCRTSize = 27;
% end

Bcol = wininfo.Bcol;
% screenInfo = genscreenInfo(wininfo.xRes,wininfo.yRes,result.VertScreenSize,result.DScreen,wininfo.frameRate,wininfo.Bcol);
window = wininfo.w; % screenInfo.window;

load('/home/visual-stim/Documents/stims/calibration/new_old_gamma_table_181003','gammaTable2')
Screen('LoadNormalizedGammaTable',wininfo.w,gammaTable2*[1 1 1]);

try
    Screen('DrawTexture',wininfo.w, wininfo.BG);
    Screen('Flip', wininfo.w);
    locs = tileScreen(result.sizes,wininfo,result.grid); %screenInfo);
    [ny,nx,~] = size(locs);
    nori = numel(result.orientations);
    [indy,indx] = meshgrid(1:ny,1:nx);
    order = randperm(ny*nx);
    locinds = [indy(order); indx(order)]';
    locinds = repmat(locinds,result.repetitions,1);
    result.locs = locs;
    result.locinds = locinds;
    
    % % % SEND THIS (locinds) TO OTHER PC VIA MSOCKET
    %     pause(1)
    %     mssend([ny,nx])
    pause(1)
    mssend(sock,locinds)
    
    nCycles = 0.5;
    numEach = ceil(nCycles*frameRate/result.tFreq);
    numFrames = nori*numEach;
    sizeGrating = ceil(result.sizes*wininfo.PixperDeg);
    for j = 1:nori
        start = (j-1)*numEach;
        gratingInfo = gengratingInfo(result.sizes,result.spFreq,result.tFreq,result.orientations(j));
        for i = 1:numEach
            gratingFrame(start+i) = gengratingFrame(i,gratingInfo,wininfo);
        end
    end
    for k = 1:result.ratio*numFrames
        gratingFrame(numFrames+k) = gensolidFrame(wininfo,sizeGrating);
    end
    % generate gray frames for baseline acquisition
    for j = 1:nori
        for i = 1:numFrames
            blankFrame(i) = gensolidFrame(wininfo);
        end
        for k = 1:result.ratio*numFrames
            blankFrame(numFrames+k) = gensolidFrame(wininfo);
        end
    end
    
    user_quit = did_you_quit(user_quit);
    
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
        if blankFrameIndex > (result.ratio+1)*numFrames
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
    for repindex=1:result.repetitions
        for i=1:numel(order)
            if ~user_quit
                user_quit = did_you_quit(user_quit);
                % ------ Bookkeeping Variables ------
                gratingRect = [0 0 sizeGrating sizeGrating]; % The bounding box for our animated sprite
                gratingFrameIndex = 1; % Which frame of the animation should we show?
                %         oriIndex = indo(order(i));
                % We need to redraw the text or else it will disappear after a
                % subsequent call to Screen('Flip').
                Screen('DrawTexture',wininfo.w, wininfo.BG);
                Screen('Flip', wininfo.w);
                Screen('DrawText', window, 'Click to exit', 0, 0, wininfo.blI);
                mY = locs(indy(order(i)),indx(order(i)),1);
                mX = locs(indy(order(i)),indx(order(i)),2);
                % Draw the sprite at the new location.
                DaqDOut(d,0,0);
                DaqDOut(d,0,255);
                DaqDOut(d,0,127);
                while gratingFrameIndex < (result.ratio)*numFrames
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
                while gratingFrameIndex < (result.ratio+1)*numFrames
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
    PixperDeg = wininfo.PixperDeg;
    xpos = round((locs(:,:,2)-wininfo.xRes/2)/wininfo.PixperDeg)
    ypos = round((wininfo.yRes/2-locs(:,:,1))/wininfo.PixperDeg)
    
    % Close screen
    Screen('CloseAll');
    save(fnameLocal, 'result');
    save(fnameRemote, 'result');
    
    % Restore preferences
    %     Screen('Preference', 'VisualDebugLevel', screenInfo.oldVisualDebugLevel);
    %     Screen('Preference', 'SuppressAllWarnings', screenInfo.oldSupressAllWarnings);
    
catch
    disp('error')
    % If there is an error in our try block, let's
    % return the user to the familiar MATLAB prompt.
    ShowCursor;
    Screen('CloseAll');
    %     Screen('Preference', 'VisualDebugLevel', screenInfo.oldVisualDebugLevel);
    %     Screen('Preference', 'SuppressAllWarnings', screenInfo.oldSupressAllWarnings);
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
    terminate_udp(H_Scanbox)
    terminate_udp(H_Run)
    save(fnameLocal, 'result');
    save(fnameRemote, 'result');
end

function terminate_udp(handle)
fprintf(handle,'S');
fclose(handle);
delete(handle);

function user_quit = did_you_quit(user_quit)
% function not working rn! just returns 'false'
[keyIsDown, secs, keyCode] = KbCheck;
user_quit = false;
% if keyIsDown && KbName(keyCode) == 'q'
%     user_quit = true;
% end