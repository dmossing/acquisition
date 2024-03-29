function [xpos,ypos] = map_retinotopy_2p_offline(varargin) %(ratio,orientations,DScreen,...
%     ScreenType,gratingSize,spFreq,tFreq,nreps)

p = inputParser;
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('repetitions',1);
p.addParameter('rate',2);
p.addParameter('DScreen',15);
p.addParameter('VertScreenSize',27);
p.addParameter('sizes',10);
p.addParameter('grid',2)
p.addParameter('contrast',1);
p.addParameter('orientations',0:45:315);
p.addParameter('spFreq',0.08); % cyc/vis deg
p.addParameter('tFreq',2); % cyc/sec
p.addParameter('range',[-15 15 -15 15])
p.addParameter('include_inverse',1)
p.parse(varargin{:});

result = p.Results;
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
% fnameRemote  =  strcat(resDirRemote,result.animalid,'_',result.depth,'_',nexp,'.mat');
result.nexp = nexp;

base = result.animalid;
depth = result.depth;
fileindex = result.nexp;
runpath = 'C:/Users/Resonant-2/Documents/Dan/remote/running/';
% runpath = '//adesnik2.ist.berkeley.edu/excitation/mossing/LF2P/running/';
runfolder = [runpath dstr '/' base];
if ~exist(runfolder,'dir')
    mkdir(runfolder)
end

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

d = DaqFind;
err = DaqDConfigPort(d,0,0);
DaqDOut(d,0,0);

% % write filename

fprintf(H_Run,sprintf('G%s/%s_%s_%s.bin', runfolder, base, depth, fileindex));
fprintf(H_Scanbox,'G'); %go


frameRate = 60;     % Hz

wininfo = gen_wininfo(result);

Bcol = wininfo.Bcol;
window = wininfo.w; % screenInfo.window;
try
    Screen('DrawTexture',wininfo.w, wininfo.BG);
    Screen('Flip', wininfo.w);
    locs = tileSubScreen(result.sizes,wininfo,result.grid,result.range);
    [ny,nx,~] = size(locs);
    nori = numel(result.orientations);
    [indy,indx,indori] = meshgrid(1:ny,1:nx,1:nori);
    indy = [NaN; indy(:)];
    indx = [NaN; indx(:)];
    indori = [NaN; indori(:)];
    nstims = (1+result.include_inverse)*(ny*nx*nori+1);
    order = zeros(result.repetitions*nstims,1); % *2 for inverted and not; +1 for gray and full contrast screens
    for i=1:result.repetitions
        order((i-1)*nstims+1:i*nstims) = randperm(nstims);
    end
    % 0 : uniform. 1:ny*nx : stim location
    spaceorder = rem(order-1,nstims/(1+result.include_inverse))+1;
    inverted = (order > nstims/(1+result.include_inverse));
    locinds = [indy(spaceorder), indx(spaceorder), indori(spaceorder)];
    result.locs = locs;
    result.locinds = locinds;
    result.inverted = inverted;
    
    nCycles = 1;
    numEach = ceil(nCycles*frameRate/result.tFreq);
    numFrames = round(frameRate/result.rate);
    sizeGrating = ceil(result.sizes*wininfo.PixperDeg);
    for j = 1:nori
        gratingInfo = gengratingInfo(result.sizes,result.spFreq,result.tFreq,result.orientations(j));
        for i = 1:numEach
            gratingInfo.fullScreen = true;
            gratingFrame(j,i) = gengratingFrame(i,gratingInfo,wininfo);
            gratingInfo.fullScreen = false;
            gratingFrameSmall(j,i) = gengratingFrame(i,gratingInfo,wininfo);
        end
    end

    gratingInfo.fullScreen = true;

    grayFrame = Screen('MakeTexture', window, Bcol*ones(round(sizeGrating)));
    
    figRect = [0 0 sizeGrating sizeGrating]; % The bounding box for our animated sprite
    oriIndex = 1;
    blankFrameIndex = 1;
    buttons = 0; % When the user clicks the mouse, 'buttons' becomes nonzero.
    mX = 0; % The x-coordinate of the mouse cursor
    mY = 0; % The y-coordinate of the mouse cursor
    
    %     for repindex=1:result.repetitions
    for i=1:numel(order)
        % ------ Bookkeeping Variables ------
        figRect = [0 0 sizeGrating sizeGrating]; % The bounding box for our animated sprite
        gratingFrameIndex = 1; % Which frame of the animation should we show?
        %         oriIndex = indo(order(i));
        % We need to redraw the text or else it will disappear after a
        % subsequent call to Screen('Flip').
        Screen('DrawTexture',wininfo.w, wininfo.BG);
        Screen('Flip', wininfo.w);
        Screen('DrawText', window, 'Click to exit', 0, 0, wininfo.blI);
        if ~isnan(indy(spaceorder(i)))
            mY = locs(indy(spaceorder(i)),indx(spaceorder(i)),1);
            mX = locs(indy(spaceorder(i)),indx(spaceorder(i)),2);
            mOri = indori(spaceorder(i));
        else
            mY = NaN;
            mX = NaN;
            mOri = NaN;
        end
        % Draw the sprite at the new location.
        DaqDOut(d,0,0);
        DaqDOut(d,0,255);
        DaqDOut(d,0,0);
        if inverted(i)
            while gratingFrameIndex < numFrames
                if ~isnan(mX)
                    Screen('DrawTexture', window, gratingFrame(mOri,gratingFrameIndex));
                    Screen('DrawTexture', window, grayFrame, figRect, CenterRectOnPoint(figRect, mX, mY));
                else
                    Screen('DrawTexture', window, gratingFrame(1,gratingFrameIndex)); % 0 degree baseline for full screen grating!
                end
                % Call Screen('Flip') to update the screen.  Note that calling
                % 'Flip' after we have both erased and redrawn the sprite prevents
                % the sprite from flickering.
                Screen('Flip', window);
                gratingFrameIndex = gratingFrameIndex + 1;
            end

        else
            Screen('DrawTexture',wininfo.w, wininfo.BG);
            while gratingFrameIndex < numFrames
                if ~isnan(mX)
                    Screen('DrawTexture', window, gratingFrameSmall(mOri,gratingFrameIndex), figRect, CenterRectOnPoint(figRect, mX, mY));
                end
                % Call Screen('Flip') to update the screen.  Note that calling
                % 'Flip' after we have both erased and redrawn the sprite prevents
                % the sprite from flickering.
                Screen('Flip', window);
                gratingFrameIndex = gratingFrameIndex + 1;
            end

        end
        %         end
    end
    DaqDOut(d,0,0);
    DaqDOut(d,0,255);
    DaqDOut(d,0,0);
    
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
%     save(fnameRemote, 'result');
    
catch
    disp('error')
    % If there is an error in our try block, let's
    % return the user to the familiar MATLAB prompt.
    ShowCursor;
    Screen('CloseAll');

    psychrethrow(psychlasterror);

    terminate_udp(H_Scanbox)
    terminate_udp(H_Run)
    save(fnameLocal, 'result');
%     save(fnameRemote, 'result');
end

function terminate_udp(handle)
fprintf(handle,'S');
fclose(handle);
delete(handle);