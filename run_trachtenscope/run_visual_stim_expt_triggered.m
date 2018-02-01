function run_visual_stim_expt_triggered(varargin)

p = inputParser;
p.addParameter('modality','2p');
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('orientations',[0 90]);
p.addParameter('repetitions',10);
p.addParameter('stimduration',1);
% p.addParameter('isi',3);
p.addParameter('DScreen',15);
p.addParameter('VertScreenSize',27);
p.addParameter('sizes',25);
p.addParameter('sFreqs',0.08); % cyc/vis deg
p.addParameter('tFreqs',2); % cyc/sec
p.addParameter('position',[0,0]);
p.addParameter('contrast',[0 1]);
p.addParameter('showfirst',false)
p.addParameter('numToTrigOn',1)
p.addParameter('frames_to_avg',300)
p.addParameter('frames_to_baseline',500)
p.addParameter('deadframes',50)
p.addParameter('silentframes',15)
p.addParameter('updateevery',300)
p.addParameter('threshhi',0.9)
p.addParameter('threshlo',0.7)
p.parse(varargin{:});

% choose parameters

result = p.Results;

% isi = result.isi;
stimduration = result.stimduration;

% create all stimulus conditions from the single parameter vectors
nConds  =  [length(result.orientations) length(result.sizes) length(result.tFreqs) length(result.sFreqs) length(result.contrast)];
allConds  =  prod(nConds);
% result.allConds = allConds;
% repPerCond  =  allConds./nConds;
conds  =  makeAllCombos(result.orientations,result.sizes,result.tFreqs,result.sFreqs,result.contrast);

assert(strcmp(result.modality,'2p') || strcmp(result.modality,'lf'));

wininfo = gen_wininfo(result);

movieDurationSecs = result.stimduration;
movieDurationFrames = round(movieDurationSecs * wininfo.frameRate);

PatchRadiusPix = ceil(result.sizes.*wininfo.PixperDeg/2); % radius!!

x0 = floor(wininfo.xRes/2 + (wininfo.xposStim - result.sizes/2)*wininfo.PixperDeg);
y0 = floor(wininfo.yRes/2 + (-wininfo.yposStim - result.sizes/2)*wininfo.PixperDeg);

if ~isempty(find(x0<1)) | ~isempty(find(y0<1))
    disp('too big for the monitor, dude! try other parameters');
    return;
end

% do stimulus data file management
% stimfolder = 'C:/Users/Resonant-2/Documents/Dan/StimData/';
stimFolderRemote = 'smb://adesnik2.ist.berkeley.edu/mossing/LF2P/StimData/';
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
runpath = '//adesnik2.ist.berkeley.edu/Inhibition/mossing/LF2P/running/';
runfolder = [runpath dstr '/' base];
if ~exist(runfolder,'dir')
    mkdir(runfolder)
end
if strcmp(result.modality,'2p')
    
    % set up scanbox communication
    
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
    
else
    
    lf_ip = '128.32.19.203';
    lf_port = 29000;
    
    % initialize connection
    H_lf = udp(lf_ip, 'RemotePort', lf_port);
    fopen(H_lf);
    
    cleanup_udp_lf = onCleanup(@() terminate_udp(H_lf));
    runpath = '//E:LF2P/ ... NEED TO FILL IN';
    fprintf(H_lf,sprintf('G%s/%s_%s_%s.dat', runfolder, base, depth, fileindex));
end

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

% set up DAQ

d = DaqFind;
err = DaqDConfigPort(d,0,0);
err = DaqDConfigPort(d,1,1);
trigOut1 = 8; % this is the trig registering when stim turns on/off
trigOut2 = 7; % this trig is used for online processing
trigIn = 8; % this trig comes from the online processing DAQ
writeMCC(d,[]); % set all output channels to 0

AssertOpenGL;

[gratingInfo.Orientation,gratingInfo.Contrast,gratingInfo.spFreq,...
    gratingInfo.tFreq, gratingInfo.Size] = deal(zeros(1,2*allConds*result.repetitions));
gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
width  =  PatchRadiusPix;
gratingInfo.widthLUT = [result.sizes(:) width(:)];
result.gratingInfo = gratingInfo;

load('/home/visual-stim/Documents/stims/calibration/gamma_correction_170803','gammaTable2')
Screen('LoadNormalizedGammaTable',wininfo.w,gammaTable2*[1 1 1]);

Screen('DrawTexture',wininfo.w, wininfo.BG);
Screen('TextFont',wininfo.w, 'Courier New');
Screen('TextSize',wininfo.w, 14);
Screen('TextStyle', wininfo.w, 1+2);
Screen('DrawText', wininfo.w, strcat(num2str(2*allConds),' Conditions__',...
    num2str(result.repetitions),' Repeats__',...
    num2str(2*allConds*result.repetitions*stimduration/60),...
    ' min estimated Duration.'), 60, 50, [255 128 0]);
Screen('DrawText', wininfo.w, strcat('Filename:',fnameLocal,...
    '    Hit any key to continue / q to abort.'), 60, 70, [255 128 0]);
Screen('Flip',wininfo.w);

FlushEvents;
[kinp,tkinp] = GetChar;
if kinp == 'q'|kinp == 'Q',
    Screen('CloseAll');
    Priority(0);
else
    Screen('DrawTexture',wininfo.w, wininfo.BG);
    Screen('Flip', wininfo.w);
    fprintf(H_Scanbox,'G'); %go
    trigLvl = 0;
    while trigLvl < 1
        trigLvl = readMCC(d,trigIn); % DaqDIn(d,1);
    end
    disp('received trigger')
    
    % % tell the other PC to open up a socket
    writeMCC(d,[]);
    writeMCC(d,trigOut2);
    srvsock = mslisten(3000);
    
    pause(3)
    % % assume the other PC has responded by requesting a connection by this
    % % point
    sock = msaccept(srvsock);
    mssend(sock,(result.numToTrigOn+1)*allConds*result.repetitions)
    mssend(sock,result.showfirst)
    mssend(sock,result.numToTrigOn)
    mssend(sock,sprintf('%s/%s_%s_%s_trigroi.mat', base, base, depth, fileindex));
    mssend(sock,result.frames_to_avg)
    mssend(sock,result.frames_to_baseline)
    mssend(sock,result.deadframes)
    mssend(sock,result.silentframes)
    mssend(sock,result.updateevery)
    mssend(sock,result.threshhi)
    mssend(sock,result.threshlo)
    
    msclose(srvsock);
    writeMCC(d,[]);
    showfirst = result.showfirst;
    numToTrigOn = result.numToTrigOn;
    
%     pause(3)
    
    result.starttime  =  datestr(now);
    
    t0  =  GetSecs
    trnum = 0;
    
    if showfirst
        gi = gratingInfo;
        gi.Size = result.sizes(1);
        gi.tFreq = result.tFreqs(1);
        gi.spFreq = result.sFreqs(1);
        gi.Contrast = 1;
%         gi.widthLUT = gratingInfo.widthLUT;
%         gi.gf = gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
% gratingInfo.Bcol = 128; % Background 0 black, 255 white
% gratingInfo.method = 'symmetric';
% gratingInfo.gtype = 'box';
        
        for i=1:numel(result.orientations)
            gi.Orientation = result.orientations(i);
            thisstim = getStim(gi,1);
            thisstim.tex = gen_gratings(wininfo,gi,thisstim);
            numFrames = numel(thisstim.tex);
            thisstim.movieDurationFrames = movieDurationFrames;
            thisstim.movieFrameIndices = mod(0:(movieDurationFrames-1), numFrames) + 1;
            disp('awaiting handshake')
            awaitHandshake(d,trigIn,trigOut2); %%HANDSHAKE
            pause(2)
            disp(['showing stim ' num2str(i)])
            tic
            writeMCC(d,[]);
            writeMCC(d,trigOut2);
            show_tex(wininfo,thisstim);
            pause(1)
            writeMCC(d,trigOut2);
            writeMCC(d,[]);
            toc
            Screen('DrawTexture',wininfo.w, wininfo.BG);
            Screen('Flip', wininfo.w);
        end
        
        awaitHandshake(d,trigIn,trigOut2); %%HANDSHAKE
    end
    
    % set up to show stimuli
    for itrial = 1:result.repetitions
%         tmpcondEven = conds;
%         tmpcondOdd = conds;
        tmpcond = cell(result.numToTrigOn+1,1);
%         oddTrial = true;
        
        conddone = cell(result.numToTrigOn+1,1);
        for i=1:result.numToTrigOn+1
            conddone{i} = 1:size(conds,2);
            tmpcond{i} = conds;
        end
%         conddoneOdd = 1:size(conds,2);
%         conddoneEven = 1:size(conds,2);
        while any(~cellfun(@isempty,conddone)) %(~isempty(tmpcondOdd) || ~isempty(tmpcondEven)) || ~isempty
            
            trnum = trnum+1;
            trialstart = GetSecs-t0;
            
            % Information to save in datafile:
%             if rem
%                 thiscondind = ceil(rand*size(tmpcondOdd,2));
%                 thiscond = tmpcondOdd(:,thiscondind);
%                 cnum = conddoneOdd(thiscondind);
%                 conddoneOdd(thiscondind)  =  [];
%                 tmpcondOdd(:,thiscondind)  =  [];
%             else
%                 thiscondind = ceil(rand*size(tmpcondEven,2));
%                 thiscond = tmpcondEven(:,thiscondind);
%                 cnum = conddoneEven(thiscondind);
%                 conddoneEven(thiscondind)  =  [];
%                 tmpcondEven(:,thiscondind)  =  [];
%             end
            whichkind = rem(trnum-1,result.numToTrigOn+1)+1;
            thiscondind = ceil(rand*size(tmpcond{whichkind},2));
            thiscond = tmpcond{whichkind}(:,thiscondind);
            cnum = conddone{whichkind}(thiscondind);
            conddone{whichkind}(thiscondind)  =  [];
            tmpcond{whichkind}(:,thiscondind)  =  [];
%                 thiscond = tmpcondOdd(:,thiscondind);
%                 cnum = conddoneOdd(thiscondind);
%                 conddoneOdd(thiscondind)  =  [];
%                 tmpcondOdd(:,thiscondind)  =  [];
            
            Trialnum(trnum) = trnum;
            Condnum(trnum) = cnum;
            Repnum(trnum) = itrial;
            result = pickNext(result,trnum,thiscond);
            % end save information
            
            thisstim = getStim(result.gratingInfo,trnum);
            thisstim.itrial = itrial;
            
            thisstim.tex = gen_gratings(wininfo,result.gratingInfo,thisstim);
            numFrames = numel(thisstim.tex);
            thisstim.movieDurationFrames = movieDurationFrames;
            thisstim.movieFrameIndices = mod(0:(movieDurationFrames-1), numFrames) + 1;
            
            awaitHandshake(d,trigIn,trigOut2);
            
            disp('delivering stim')
            result = deliver_stim(result,wininfo,thisstim,d,trigOut1);
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown & KbName(keyCode) == 'p'
                KbWait([],2);
                %wait for all keys to be released and then any key to be pressed again
            end
%             oddTrial = ~oddTrial;
        end
    end
    
    result.stimParams = conds(:,Condnum);
    result.dispInfo.xRes  =  wininfo.xRes;
    result.dispInfo.yRes  =  wininfo.yRes;
    result.dispInfo.DScreen  =  result.DScreen;
    result.dispInfo.VertScreenSize  =  result.VertScreenSize;
    
    save(fnameLocal, 'result');
    save(fnameRemote, 'result');
    
    Screen('DrawTexture',wininfo.w,wininfo.BG);
    Screen('DrawText', wininfo.w, sprintf('Done. Press any key.', 300,40,[255 0 0]));
    Screen('Flip', wininfo.w);
    
    FlushEvents;
    [kinp,tkinp] = GetChar;
    Screen('CloseAll');
    Priority(0);
    
end

% % stop imaging
if strcmp(result.modality,'2p')
    terminate_udp(H_Scanbox)
end
terminate_udp(H_Run)
msclose(sock)

%% that running computer should stop monitoring

% STOP ACQUISITION ON SCANBOX !!!

    function terminate_udp(handle)
        fprintf(handle,'S');
        fclose(handle);
        delete(handle);
    end

    function result = deliver_stim(result,wininfo,thisstim,d,trigOut)
        w = wininfo.w;
        BG = wininfo.BG;
        prestimtimems = 0;
        
        priorityLevel = MaxPriority(w);
        Priority(priorityLevel);
        
        %--
        Screen('DrawTexture',w,BG);
        Screen('DrawText', w, ['trial ' int2str(thisstim.trnum) '/' ...
            int2str(allConds) 'repetition ' int2str(thisstim.itrial) '/'...
            int2str(result.repetitions)], 0, 0, [255,0,0]);
        Screen('Flip', w);
        
        Screen('DrawTexture',w,BG);
        fliptime  =  Screen('Flip', w);
        WaitSecs(max(0,prestimtimems/1000));
        
        % last flip before movie starts
        Screen('DrawTexture',w,BG);
        fliptime  =  Screen('Flip', w);
        result.timestamp(thisstim.trnum)  =  fliptime - t0;
        
        % disp(['trnum: ' num2str(trnum) '   ts: ' num2str(result.timestamp(trnum))]);
        stimstart  =  GetSecs-t0;
        
        % send stim on trigger
        writeMCC(d,[]);
        writeMCC(d,trigOut);
        writeMCC(d,[]);
        disp('stim on')
        tic
        % show stimulus
        show_tex(wininfo,thisstim)
        %                 fprintf(H_Run,'')
        toc
        
        writeMCC(d,[]);
        writeMCC(d,trigOut);
        writeMCC(d,[]);
        disp('stim off')
        
        stimt = GetSecs-t0-stimstart;
        Screen('DrawTexture',w,BG);
        Screen('Flip', w);
        Screen('Close',thisstim.tex(:));
    end

    function result = pickNext(result,trnum,thiscond)
        result.gratingInfo.Orientation(trnum) = thiscond(1);
        % don't do this anymore, now happens while building conds: +((randi(2)-1)*180);
        result.gratingInfo.Size(trnum) = thiscond(2);
        result.gratingInfo.tFreq(trnum) = thiscond(3);
        result.gratingInfo.spFreq(trnum) = thiscond(4);
        result.gratingInfo.Contrast(trnum) = thiscond(5);
    end

    function thisstim = getStim(gratingInfo,trnum)
        bin = (gratingInfo.widthLUT(:,1) == gratingInfo.Size(trnum));
        thisstim.thiswidth = gratingInfo.widthLUT(bin,2);
        thisstim.thisdeg = gratingInfo.Orientation(trnum);
        thisstim.thissize = gratingInfo.Size(trnum);
        thisstim.thisspeed = gratingInfo.tFreq(trnum);
        thisstim.thisfreq = gratingInfo.spFreq(trnum);
        thisstim.thiscontrast = gratingInfo.Contrast(trnum);
        thisstim.trnum = trnum;
    end

    function writeMCC(d,chanlist)
        nchan = 8;
        output = zeros(1,nchan);
        output(chanlist) = 1;
        DaqDOut(d,0,bi2de(output));
    end

    function input = readMCC(d,chanlist)
        nchan = 8;
        data = DaqDIn(d);
        try
            input = de2bi(data(2),nchan); % port B is read out to 2nd element of data
            input = input(chanlist);
        catch
            input = zeros(size(chanlist));
        end
    end

    function awaitHandshake(d,trigIn,trigOut)
        writeMCC(d,[]);
        trig_recvd = 0;
        while ~trig_recvd
            trig_recvd = readMCC(d,trigIn);
        end
        writeMCC(d,trigOut);
        while trig_recvd
%             disp('awaiting trig off')
            trig_recvd = readMCC(d,trigIn);
        end
        writeMCC(d,[]);
    end
end