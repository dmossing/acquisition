function run_visual_stim_sweeps_portable(varargin)

%%% MAKE CHANGES TO THIS PART
stimFolderRemote = '/home/visual-stim/excitation/visual_stim/';
stimFolderLocal = '/home/visual-stim/Documents/StimData/';
runFolder = 'Z:/mossing/running/';
gammaFile = '/home/visual-stim/Documents/stims/calibration/gamma_correction_170803';
setupAcquisitionFn = @sb_setup_fn;
startAcquisitionFn = @sb_start_fn;
stopAcquisitionFn = @sb_stop_fn;
sendTTLFn = @send_ttl_fn;
setupDaqFn = setup_daq_fn;

    function sb_start_fn()
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
        
        thisRunFolder = [runFolder dstr '/' base];
        if ~exist(thisRunFolder,'dir')
            mkdir(thisRunFolder)
        end
        
        % initialize connection
        H_Run = udp(run_ip, 'RemotePort', run_port, 'LocalPort', run_port); % create udp port handle
        fopen(H_Run);
        
        % clean up udp connection in case of Ctrl-C
        cleanup_udp_Run = onCleanup(@() terminate_udp(H_Run));
        
        fprintf(H_Run,sprintf('G%s/%s_%s_%s.bin', runfolder, base, depth, fileindex));
        
    end

    function sb_stop_fn()
        terminate_udp(H_Scanbox)
    end

    function d = setup_daq_fn()
        % set up DAQ
        d = DaqFind;
        err = DaqDConfigPort(d,0,0);
    end

    function send_ttl_fn(d)
        DaqDOut(d,0,0);
        DaqDOut(d,0,255);
        DaqDOut(d,0,0);
    end
%%%

p = inputParser;
% p.addParameter('modality','2p');
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('orientations',0:45:315);
p.addParameter('repetitions',10);
p.addParameter('stimduration',1);
p.addParameter('isi',3);
p.addParameter('DScreen',15);
p.addParameter('VertScreenSize',27);
p.addParameter('sizes',25);
p.addParameter('sFreqs',0.08); % cyc/vis deg
p.addParameter('tFreqs',1); % cyc/sec
p.addParameter('position',[0,0]);
p.addParameter('contrast',1);
p.addParameter('circular',0);
p.parse(varargin{:});

% choose parameters

result = p.Results;

setupAcquisitionFn();
d = setupDaqFn();

% create all stimulus conditions from the single parameter vectors
nConds  =  [length(result.orientations) length(result.sizes) length(result.tFreqs) length(result.sFreqs) length(result.contrast)];
result.allConds  =  prod(nConds);
result.conds  =  makeAllCombos(result.orientations,result.sizes,result.tFreqs,result.sFreqs,result.contrast);

% assert(strcmp(result.modality,'2p') || strcmp(result.modality,'lf'));

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

startAcquisitionFn()

% % write filename

AssertOpenGL;

[gratingInfo.Orientation,gratingInfo.Contrast,gratingInfo.spFreq,...
    gratingInfo.tFreq, gratingInfo.Size] = deal(zeros(1,result.allConds*result.repetitions));
% gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
gratingInfo.circular = result.circular;
width  =  PatchRadiusPix;
gratingInfo.widthLUT = [result.sizes(:) width(:)];
result.gratingInfo = gratingInfo;

load(gammaFile,'gammaTable2')
Screen('LoadNormalizedGammaTable',wininfo.w,gammaTable2*[1 1 1]);

Screen('DrawTexture',wininfo.w, wininfo.BG);
Screen('TextFont',wininfo.w, 'Courier New');
Screen('TextSize',wininfo.w, 14);
Screen('TextStyle', wininfo.w, 1+2);
Screen('DrawText', wininfo.w, strcat(num2str(result.allConds),' Conditions__',...
    num2str(result.repetitions),' Repeats__',...
    num2str(result.allConds*result.repetitions*(result.isi+result.stimduration)/60),...
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
    % start imaging
    if strcmp(result.modality,'2p')
        fprintf(H_Scanbox,'G'); %go
    end
    pause(5);
    
    Screen('DrawTexture',wininfo.w, wininfo.BG);
    Screen('Flip', wininfo.w);
    result.starttime  =  datestr(now);
    
    t0  =  GetSecs;
    trnum = 0;
    stimParams = [];
    % set up to show stimuli
    for itrial = 1:result.repetitions,
        theseinds = randperm(result.allConds);
        theseconds = result.conds(:,theseinds);
        stimParams = [stimParams theseconds];
        for istim = 1:result.allConds,
            %             [kinp,tkinp] = GetChar;
            
            disp('Signal on 2')
            
            trnum = trnum+1;
            trialstart = GetSecs-t0;
            
            % Information to save in datafile:
            thiscond = theseconds(istim);
            result = pickNext(result,trnum,thiscond);
            % end save information
            
            thisstim = getStim(result.gratingInfo,trnum);
            thisstim.itrial = itrial;
            
            thisstim.movieDurationFrames = movieDurationFrames;
            thisstim = gen_gratings(wininfo,result.gratingInfo,thisstim);
            
            result = deliver_stim(result,wininfo,thisstim,d);
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown & KbName(keyCode) == 'p'
                KbWait([],2);
                %wait for all keys to be released and then any key to be pressed again
            end
        end
    end
    
    result.stimParams = stimParams; %conds(:,Condnum);
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
stopAcquisitionFn()
terminate_udp(H_Run)

%% that running computer should stop monitoring

% STOP ACQUISITION ON SCANBOX !!!

    function terminate_udp(handle)
        fprintf(handle,'S');
        fclose(handle);
        delete(handle);
    end

    function result = deliver_stim(result,wininfo,thisstim,d)
        w = wininfo.w;
        BG = wininfo.BG;
        prestimtimems = 0;
        
        priorityLevel = MaxPriority(w);
        Priority(priorityLevel);
        
        %--
        Screen('DrawTexture',w,BG);
        Screen('DrawText', w, ['trial ' int2str(thisstim.trnum) '/' ...
            int2str(result.allConds) 'repetition ' int2str(thisstim.itrial) '/'...
            int2str(result.repetitions)], 0, 0, [255,0,0]);
        Screen('Flip', w);
        
        WaitSecs(max(0, result.isi-((GetSecs-t0)-trialstart)));
        
        Screen('DrawTexture',w,BG);
        fliptime  =  Screen('Flip', w);
        WaitSecs(max(0,prestimtimems/1000));
        
        % last flip before movie starts
        Screen('DrawTexture',w,BG);
        fliptime  =  Screen('Flip', w);
        result.timestamp(thisstim.trnum)  =  fliptime - t0;
        
        stimstart  =  GetSecs-t0;
        
        % send stim on trigger
        
        sendTTLfn(d)
        
        disp('stim on')
        tic
        % show stimulus
        show_tex(wininfo,thisstim)
        toc
        
        sendTTLfn(d)
        
        disp('stim off')
        
        stimt = GetSecs-t0-stimstart;
        Screen('DrawTexture',w,BG);
        Screen('Flip', w);
        Screen('Close',thisstim.tex(:));
    end

    function result = pickNext(result,trnum,thiscond)
        result.gratingInfo.Orientation(trnum) = thiscond(1);
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

end