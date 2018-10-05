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
p.addParameter('sFreqs',0.08); % cyc/vis deg
p.addParameter('tFreqs',1); % cyc/sec
p.addParameter('position',[0,0]);
p.addParameter('contrast',1);
p.addParameter('circular',0);
p.parse(varargin{:});

% choose parameters

result = p.Results;

isi = result.isi;
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
stimFolderRemote = '/home/visual-stim/excitation/visual_stim/';
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
runpath = 'C:/Users/Resonant-2/Documents/Dan/remote/running/';
% runpath = '//adesnik2.ist.berkeley.edu/Inhibition/mossing/LF2P/running/';
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

AssertOpenGL;

% frameRate = Screen('FrameRate',screenNumber);
% if(frameRate == 0)  %if MacOSX does not know the frame rate the 'FrameRate' will return 0.
%     frameRate = 100;
% end
% result.frameRate  =  frameRate;

[gratingInfo.Orientation,gratingInfo.Contrast,gratingInfo.spFreq,...
    gratingInfo.tFreq, gratingInfo.Size] = deal(zeros(1,allConds*result.repetitions));
gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
gratingInfo.circular = result.circular;
width  =  PatchRadiusPix;
gratingInfo.widthLUT = [result.sizes(:) width(:)];
result.gratingInfo = gratingInfo;

%load('GammaTable.mat'); % need to do the gamma correction!!
%CT = (ones(3,1)*correctedTable(:,2)')'/255;
%Screen('LoadNormalizedGammaTable',w, CT);
% load('/home/visual-stim/Documents/stims/calibration/gamma_correction_170803','gammaTable2')
load('/home/visual-stim/Documents/stims/calibration/new_old_gamma_table_181003','gammaTable2')
Screen('LoadNormalizedGammaTable',wininfo.w,gammaTable2*[1 1 1]);

Screen('DrawTexture',wininfo.w, wininfo.BG);
Screen('TextFont',wininfo.w, 'Courier New');
Screen('TextSize',wininfo.w, 14);
Screen('TextStyle', wininfo.w, 1+2);
Screen('DrawText', wininfo.w, strcat(num2str(allConds),' Conditions__',...
    num2str(result.repetitions),' Repeats__',...
    num2str(allConds*result.repetitions*(isi+stimduration)/60),...
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
    %     outputSingleScan(daq,[0 1 0]);
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
    
    % set up to show stimuli
    for itrial = 1:result.repetitions,
        tmpcond = conds;
        
%         % randomize direction 50/50%
%         for i = 1:length(orientations)
%             %             rp = randperm((allConds-2)/length(orientations));
% % -2 for the two control conditions with no grating visible
%             
%             rp = randperm((allConds)/length(orientations)); 
% % -2 for the two control conditions with no grating visible
%             thisoriinds = find(tmpcond(1,:) == orientations(i));
%             tmpcond(1,thisoriinds(rp(1:floor(length(rp)/2)))) = orientations(i)+180;
%         end
        
        conddone = 1:size(conds,2);
        while ~isempty(tmpcond)
            %             [kinp,tkinp] = GetChar;
            
            disp('Signal on 2')
            
            trnum = trnum+1;
            trialstart = GetSecs-t0;
            
            % Information to save in datafile:
            thiscondind = ceil(rand*size(tmpcond,2));
            thiscond = tmpcond(:,thiscondind);
            cnum = conddone(thiscondind);
            conddone(thiscondind)  =  [];
            tmpcond(:,thiscondind)  =  [];
            Trialnum(trnum) = trnum;
            Condnum(trnum) = cnum;
            Repnum(trnum) = itrial;
            result = pickNext(result,trnum,thiscond);
            % end save information
            
            thisstim = getStim(result.gratingInfo,trnum);
            thisstim.itrial = itrial;
            
%             thisstim.tex = gen_gratings(wininfo,result.gratingInfo,thisstim);
%             numFrames = numel(thisstim.tex);
            thisstim.movieDurationFrames = movieDurationFrames;
%             thisstim.movieFrameIndices = mod(0:(movieDurationFrames-1), numFrames) + 1;
            thisstim = gen_gratings(wininfo,result.gratingInfo,thisstim);
            
            result = deliver_stim(result,wininfo,thisstim,d);
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown & KbName(keyCode) == 'p'
                KbWait([],2); 
                %wait for all keys to be released and then any key to be pressed again
            end
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
                int2str(allConds) 'repetition ' int2str(thisstim.itrial) '/'...
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
            
            %             disp(['trnum: ' num2str(trnum) '   ts: ' num2str(result.timestamp(trnum))]);
            stimstart  =  GetSecs-t0;
            
            % send stim on trigger
            DaqDOut(d,0,0);
            DaqDOut(d,0,255);
            DaqDOut(d,0,0);
            disp('stim on')
            tic
            % show stimulus
            show_tex(wininfo,thisstim)
            %                 fprintf(H_Run,'')
            toc
            
            DaqDOut(d,0,0);
            DaqDOut(d,0,255);
            DaqDOut(d,0,0);
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
end