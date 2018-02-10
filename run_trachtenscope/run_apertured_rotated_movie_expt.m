function run_apertured_rotated_movie_expt(varargin)

p = inputParser;
p.addParameter('modality','2p');
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('repetitions',10);
% p.addParameter('stimduration',1);
p.addParameter('isi',3);
p.addParameter('DScreen',15);
p.addParameter('VertScreenSize',27);
p.addParameter('position',[0,0]);
p.addParameter('sizes',[]);
p.addParameter('contrast',1);
p.addParameter('moviefname','/home/visual-stim/Documents/stims/touch_of_evil/toe_10sec_4x_longer_square_1024');
p.parse(varargin{:});

% choose parameters

result = p.Results;

load(result.moviefname,'frames')

isi = result.isi;
% stimduration = result.stimduration;

% create all stimulus conditions from the single parameter vectors
% nConds  =  [length(result.orientations) length(result.sizes) length(result.tFreqs) length(result.sFreqs) length(result.contrast)];
% allConds  =  prod(nConds);
% conds  =  makeAllCombos(result.orientations,result.sizes,result.tFreqs,result.sFreqs,result.contrast);

assert(strcmp(result.modality,'2p') || strcmp(result.modality,'lf'));

wininfo = gen_wininfo(result);

% movieDurationSecs = result.stimduration;
% movieDurationFrames = round(movieDurationSecs * wininfo.frameRate);

if ~isempty(result.sizes)
    PatchRadiusPix = ceil(result.sizes.*wininfo.PixperDeg/2); % radius!!
    x0 = floor(size(frames,2)/2 + wininfo.xposStim*wininfo.PixperDeg);
    y0 = floor(size(frames,1)/2 - wininfo.yposStim*wininfo.PixperDeg);
end
%
% if ~isempty(find(x0<1)) | ~isempty(find(y0<1))
%     disp('too big for the monitor, dude! try other parameters');
%     return;
% end

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

AssertOpenGL;

% frameRate = Screen('FrameRate',screenNumber);
% if(frameRate == 0)  %if MacOSX does not know the frame rate the 'FrameRate' will return 0.
%     frameRate = 100;
% end
% result.frameRate  =  frameRate;

% [gratingInfo.Orientation,gratingInfo.Contrast,gratingInfo.spFreq,...
%     gratingInfo.tFreq, gratingInfo.Size] = deal(zeros(1,allConds*result.repetitions));
gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
% width  =  PatchRadiusPix;
% gratingInfo.widthLUT = [result.sizes(:) width(:)];
result.gratingInfo = gratingInfo;

%load('GammaTable.mat'); % need to do the gamma correction!!
%CT = (ones(3,1)*correctedTable(:,2)')'/255;
%Screen('LoadNormalizedGammaTable',w, CT);
load('/home/visual-stim/Documents/stims/calibration/gamma_correction_170803','gammaTable2')
Screen('LoadNormalizedGammaTable',wininfo.w,gammaTable2*[1 1 1]);

Screen('DrawTexture',wininfo.w, wininfo.BG);
Screen('TextFont',wininfo.w, 'Courier New');
Screen('TextSize',wininfo.w, 14);
Screen('TextStyle', wininfo.w, 1+2);
% Screen('DrawText', wininfo.w, strcat(num2str(allConds),' Conditions__',...
%     num2str(result.repetitions),' Repeats__',...
%     num2str(allConds*result.repetitions*(isi+stimduration)/60),...
%     ' min estimated Duration.'), 60, 50, [255 128 0]);
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
    pause(1);
    
    Screen('DrawTexture',wininfo.w, wininfo.BG);
    Screen('Flip', wininfo.w);
    result.starttime  =  datestr(now);
    
    t0  =  GetSecs;
    trnum = 0;
    
    thisstim.trnum = 1;
    
    if isempty(result.sizes) %%% GOTO
        aperture = [];
    else
        [xx,yy] = meshgrid(1:size(frames,2),1:size(frames,1));
        aperture = (xx-x0).^2 + (yy-y0).^2 < PatchRadiusPix^2;
    end
    
    conds = [];
    % set up to show stimuli
    lut = {'center + surround','center','surround','center + rotated surround'};
    for istim = 1:result.repetitions,
        theseconds = randperm(4);
        conds = [conds theseconds(:)'];
        for itrial=1:4
            %         thisaperture = aperture;
            %         rotate_surround = false;
            if theseconds(itrial)==1
                thisaperture = [];
                rotate_surround = false;
            elseif theseconds(itrial)==2
                thisaperture = aperture;
                rotate_surround = false;
            elseif theseconds(itrial)==3
                thisaperture = ~aperture;
                rotate_surround = false;
            elseif theseconds(itrial)==4
                thisaperture = aperture;
                rotate_surround = true;
            end
            
            %             thisstim = getStim(result.gratingInfo,trnum);
            %             thisstim.itrial = itrial;
            trialstart = GetSecs-t0;
            thisstim.tex = gen_textures(wininfo,frames,thisaperture,rotate_surround);
            numFrames = numel(thisstim.tex);
            thisstim.movieDurationFrames = numFrames;
            thisstim.movieFrameIndices = mod(0:(thisstim.movieDurationFrames-1), numFrames) + 1;
            result = deliver_stim(result,wininfo,thisstim,d);
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown & KbName(keyCode) == 'p'
                KbWait([],2);
                %wait for all keys to be released and then any key to be pressed again
            end
            thisstim.trnum = thisstim.trnum+1;
        end
    end
end

result.stimParams = conds;%(:,Condnum);
result.stimLUT = lut;
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
        % thisstim just needs to have fields tex, movieDurationFrames, and
        % movieFrameIndices
        w = wininfo.w;
        BG = wininfo.BG;
        prestimtimems = 0;
        
        priorityLevel = MaxPriority(w);
        Priority(priorityLevel);
        
        %--
        Screen('DrawTexture',w,BG);
        % Screen('DrawText', w, ['trial ' int2str(thisstim.trnum) '/' ...
        %     int2str(allConds) 'repetition ' int2str(thisstim.itrial) '/'...
        %     int2str(result.repetitions)], 0, 0, [255,0,0]);
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
end