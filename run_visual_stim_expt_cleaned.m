function run_visual_stim_expt_cleaned(varargin)

p = inputParser;
p.addParameter('modality','2p');
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('orientations',0:45:315);
p.addParameter('repetitions',10);
p.addParameter('stimduration',1);
p.addParameter('isi',3);
p.addParameter('DScreen',15);
p.addParameter('VertScreenSize',27);
p.addParameter('sizes',25);
p.addParameter('sFreqs',0.04); % cyc/vis deg
p.addParameter('tFreqs',2); % cyc/sec
p.addParameter('position',[0,0]);
p.parse(varargin{:});

% choose parameters

result = p.Results;

% create all stimulus conditions from the single parameter vectors
nConds  =  [length(result.orientations) length(result.sizes) length(result.tFreqs) length(result.sFreqs)];
allConds  =  prod(nConds);
repPerCond  =  allConds./nConds;
conds  =  makeAllCombos(result.orientations,result.sizes,result.tFreqs,result.sFreqs);

assert(strcmp(modality,'2p') || strcmp(modality,'lf'));

wininfo = gen_wininfo(result);

PatchRadiusPix = ceil(result.sizes.*wininfo.PixperDeg/2); % radius!!

x0 = floor(wininfo.xRes/2 + (wininfo.xposStim - result.sizes/2)*wininfo.PixperDeg);
y0 = floor(wininfo.yRes/2 + (-wininfo.yposStim - result.sizes/2)*wininfo.PixperDeg);

if ~isempty(find(x0<1)) | ~isempty(find(y0<1))
    disp('too big for the monitor, dude! try other parameters');
    return;
end

% do stimulus data file management
% stimfolder = 'C:/Users/Resonant-2/Documents/Dan/StimData/';
stimfolder = 'smb://adesnik2.ist.berkeley.edu/mossing/LF2P/StimData/';
dstr = yymmdd(date);
resDirLocal = [stimfolder dstr '/' result.animalid '/LF2P/'];
if ~exist(resDirLocal,'dir')
    mkdir(resDirLocal)
end

nexp  =  ddigit(length(dir(fullfile(resDir,'*.mat'))),3);
fname  =  strcat(resDir,result.animalid,'_',result.depth,'_',nexp,'.mat');
result.nexp = nexp;

base = result.animalid;
depth = result.depth;
fileindex = result.nexp;
runpath = '//adesnik2.ist.berkeley.edu/Inhibition/mossing/LF2P/running/';
runfolder = [runpath dstr '/' base];
if ~exist(runfolder,'dir')
    mkdir(runfolder)
end
if strcmp(modality,'2p')
    
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

AssertOpenGL;

frameRate = Screen('FrameRate',screenNumber);
if(frameRate == 0)  %if MacOSX does not know the frame rate the 'FrameRate' will return 0.
    frameRate = 100;
end
result.frameRate  =  frameRate;

white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
gray = (white+black)/2;
if round(gray) == white
    gray = black;
end

Screen('Preference', 'VBLTimestampingMode', -1);
Screen('Preference','SkipSyncTests', 0);
[w,~] = Screen('OpenWindow',screenNumber);

%load('GammaTable.mat'); % need to do the gamma correction!!
%CT = (ones(3,1)*correctedTable(:,2)')'/255;
%Screen('LoadNormalizedGammaTable',w, CT);

bg = ones(yRes,xRes)*Bcol;
BG = Screen('MakeTexture', w, bg);

Screen('DrawTexture',w, BG);
Screen('TextFont',w, 'Courier New');
Screen('TextSize',w, 14);
Screen('TextStyle', w, 1+2);
Screen('DrawText', w, strcat(num2str(allConds),' Conditions__',num2str(result.repetitions),' Repeats__',num2str(allConds*result.repetitions*(isi+stimduration)/60),' min estimated Duration.'), 60, 50, [255 128 0]);
Screen('DrawText', w, strcat('Filename:',fname,'    Hit any key to continue / q to abort.'), 60, 70, [255 128 0]);
Screen('Flip',w);

FlushEvents;
[kinp,tkinp] = GetChar;
if kinp == 'q'|kinp == 'Q',
    Screen('CloseAll');
    Priority(0);
else
    %     outputSingleScan(daq,[0 1 0]);
    % start imaging
    if strcmp(modality,'2p')
        fprintf(H_Scanbox,'G'); %go
    end
    pause(5);
    
    Screen('DrawTexture',w, BG);
    Screen('Flip', w);
    result.starttime  =  datestr(now);
    
    width  =  PatchRadiusPix;
    
    t0  =  GetSecs;
    trnum = 0;
    
    % set up to show stimuli
    for itrial = 1:result.repetitions,
        tmpcond = conds;
        
        % randomize direction 50/50%
        for i = 1:length(orientations)
            %             rp = randperm((allConds-2)/length(orientations)); % -2 for the two control conditions with no grating visible
            
            rp = randperm((allConds)/length(orientations)); % -2 for the two control conditions with no grating visible
            thisoriinds = find(tmpcond(1,:) == orientations(i));
            tmpcond(1,thisoriinds(rp(1:floor(length(rp)/2)))) = orientations(i)+180;
        end
        
        conddone = 1:size(conds,2);
        while ~isempty(tmpcond)
            %             outputSingleScan(daq,[0,0])
            %             [kinp,tkinp] = GetChar;
            
            disp('Signal on 2')
            
            trnum = trnum+1;
            trialstart = GetSecs-t0;
            thiscondind = ceil(rand*size(tmpcond,2));
            thiscond = tmpcond(:,thiscondind);
            disp(num2str(thiscond))
            cnum = conddone(thiscondind);conddone(thiscondind)  =  [];
            
            % Information to save in datafile:
            Trialnum(trnum) = trnum;
            Condnum(trnum) = cnum;
            Repnum(trnum) = itrial;
            Orientation(trnum) = thiscond(1); % don't do this anymore, now happens while building conds: +((randi(2)-1)*180);
            Size(trnum) = thiscond(2);
            Lgt(trnum)  =  thiscond(3);
            spFreq(trnum) = cyclesPerVisDeg;
            tFreq(trnum) = cyclesPerSecond;
            Contrast(trnum) = contrast;
            % end save information
            
            tmpcond(:,thiscondind)  =  [];
            thisdeg = Orientation(trnum);
            thissize = thiscond(2);
            thiscontrast = contrast;
            thisfreq = cyclesPerVisDeg;
            thisspeed = cyclesPerSecond;
            
            ii = find(sizes==thissize) ;
            thiswidth = width(ii);
            thisstim.thisdeg = thisdeg;
            thisstim.thissize = thissize;
            thisstim.thiscontrast = contrast;
            thisstim.thisfreq = cyclesPerVisDeg;
            thisstim.thisspeed = cyclesPerSecond;
            
            tex = gen_gratings(wininfo,thisstim);
            
            movieDurationSecs = stimduration;
            movieDurationFrames = round(movieDurationSecs * frameRate);
            movieFrameIndices = mod(0:(movieDurationFrames-1), numFrames) + 1;
            priorityLevel = MaxPriority(w);
            Priority(priorityLevel);
            
            %--
            Screen('DrawTexture',w,BG);
            Screen('DrawText', w, ['trial ' int2str(trnum) '/' int2str(allConds) 'repetition ' int2str(itrial) '/' int2str(result.repetitions)], 0, 0, [255,0,0]);
            
            
            Screen('Flip', w);
            
            WaitSecs(max(0,isi-((GetSecs-t0)-trialstart)));
            
            Screen('DrawTexture',w,BG);
            fliptime  =  Screen('Flip', w);
            WaitSecs(max(0,prestimtimems/1000));
            
            % last flip before movie starts
            Screen('DrawTexture',w,BG);
            fliptime  =  Screen('Flip', w);
            result.timestamp(trnum)  =  fliptime - t0;
            
            %             disp(['trnum: ' num2str(trnum) '   ts: ' num2str(result.timestamp(trnum))]);
            stimstart  =  GetSecs-t0;
            
            %STIMULATION
            if thislight
                Screen('DrawTexture',w,BG);
                fliptime  =  Screen('Flip', w);
                %                 % send light trigger
                
            end
            
            % send stim on trigger
            DaqDOut(d,0,0);
            DaqDOut(d,0,255);
            DaqDOut(d,0,0);
            disp('stim on')
            tic
            % show stimulus
            for i = 1:movieDurationFrames
                Screen('DrawTexture', w, tex(movieFrameIndices(i)));
                Screen('Flip', w);
            end
            %                 fprintf(H_Run,'')
            toc
            
            DaqDOut(d,0,0);
            DaqDOut(d,0,255);
            DaqDOut(d,0,0);
            disp('stim off')
            
            
            stimt = GetSecs-t0-stimstart;
            result.lightStamp  =  [result.lightStamp, fliptime-t0];
            Screen('DrawTexture',w,BG);
            Screen('Flip', w);
            Screen('Close',tex(:));
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown & KbName(keyCode) == 'p'
                KbWait([],2); %wait for all keys to be released and then any key to be pressed again
            end
        end
    end
    
    %     result.stimulusIndex  =  Condnum;
    result.stimParams = conds(:,Condnum);
    gratingInfo.Orientation  =  Orientation; gratingInfo.Contrast  =  Contrast; gratingInfo.spFreq  =  spFreq;
    gratingInfo.tFreq  =  tFreq; gratingInfo.size = Size;
    gratingInfo.gf  =  gf; gratingInfo.Bcol  =  Bcol; gratingInfo.method  =  method;
    result.isi  =  isi; result.stimduration  =  stimduration;
    result.dispInfo.xRes  =  xRes; result.dispInfo.yRes  =  yRes;
    result.dispInfo.DScreen  =  DScreen; result.dispInfo.VertScreenSize  =  VertScreenSize;
    result.light  =  Lgt;
    result.delaySV  =  prestimtimems;
    
    result.gratingInfo  =  gratingInfo;
    
    save(fname, 'result');
    
    Screen('DrawTexture',w,BG);
    Screen('DrawText', w, sprintf('Done. Press any key.', 300,40,[255 0 0]));
    Screen('Flip', w);
    
    FlushEvents;
    [kinp,tkinp] = GetChar;
    Screen('CloseAll');
    Priority(0);
    
end

% % stop imaging
if strcmp(modality,'2p')
    terminate_udp(H_Scanbox)
end
terminate_udp(H_Run)

%% that running computer should stop monitoring

% STOP ACQUISITION ON SCANBOX !!!

    function terminate_udp(handle)
        fprintf(handle,'S');
        fclose(handle);
        delete(handle);
    end
end