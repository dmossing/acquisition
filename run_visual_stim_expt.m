% function run_visual_stim_expt(modality,animalid,depth,screenNumber,orientations,repetitions,...
%     stimduration,isi,DScreen,VertScreenSize,sizes,cyclesPerVisDeg,cyclesPerSecond,...
%     position, zplanes)

function run_visual_stim_expt(varargin)

ctr = 1;
while ctr <= nargin
    switch varargin{ctr}
        case 'modality'
            modality = varargin{ctr+1};
            ctr = ctr+2;
        case 'animalid'
            animalid = varargin{ctr+1};
            ctr = ctr+2;
        case 'depth'
            depth = varargin{ctr+1};
            ctr = ctr+2;
        case 'screenNumber'
            screenNumber = varargin{ctr+1};
            ctr = ctr+2;
        case 'orientations'
            orientations = varargin{ctr+1};
            ctr = ctr+2;
        case 'repetitions'
            repetitions = varargin{ctr+1};
            ctr = ctr+2;
        case 'stimduration'
            stimduration = varargin{ctr+1};
            ctr = ctr+2;
        case 'isi'
            isi = varargin{ctr+1};
            ctr = ctr+2;
        case 'DScreen'
            DScreen = varargin{ctr+1};
            ctr = ctr+2;
        case 'VertScreenSize'
            VertScreenSize = varargin{ctr+1};
            ctr = ctr+2;
        case 'sizes'
            sizes = varargin{ctr+1};
            ctr = ctr+2;
        case 'cyclesPerVisDeg'
            cyclesPerVisDeg = varargin{ctr+1};
            ctr = ctr+2;
        case 'cyclesPerSecond'
            cyclesPerSecond = varargin{ctr+1};
            ctr = ctr+2;
        case 'position'
            position = varargin{ctr+1};
            ctr = ctr+2;
        case 'zplanes'
            zplanes = varargin{ctr+1};
            ctr = ctr+2;
        case 'ScreenType'
            ScreenType = varargin{ctr+1};
            ctr = ctr+2;
        otherwise
            error(sprintf('invalid argument %s',varargin{ctr}))
    end
end

% assign to default values
if ~exist('modality','var') || isempty(modality)
    modality = '2p';
end

if ~exist('animalid','var') || isempty(animalid)
    animalid = 'M5266';
end

if animalid(1)=='M'
    species = 'mouse';
elseif animalid(1)=='F'
    species = 'fish';
else
    error('invalid animal id')
end


if ~exist('depth','var') || isempty(depth)
    depth = '000';
end

if ~exist('screenNumber','var') || isempty(screenNumber)
    screenNumber = 0;
end

if ~exist('orientations','var') || isempty(orientations)
    orientations = 0:45:315;
end

if ~exist('repetitions','var') || isempty(repetitions)
    repetitions = 10;
end

if ~exist('stimduration','var') || isempty(stimduration)
    stimduration = 1;
end

if ~exist('isi','var') || isempty(isi)
    isi = 3;
end

if ~exist('DScreen','var') || isempty(DScreen)
    switch species
        case 'mouse'
            DScreen = 15;
        case 'fish'
            DScreen = 1;
    end
end

if ~exist('VertScreenSize','var') || isempty(VertScreenSize)
    switch species
        case 'mouse'
            VertScreenSize = 27;
        case 'fish'
            VertScreenSize = 2;
    end
end

if ~exist('sizes','var') || isempty(sizes)
    switch species
        case 'mouse'
            sizes = 25;
        case 'fish'
            sizes = 30;
    end
end

if ~exist('cyclesPerVisDeg','var') || isempty(cyclesPerVisDeg)
    cyclesPerVisDeg = 0.04;
end

if ~exist('cyclesPerSecond','var') || isempty(cyclesPerSecond)
    cyclesPerSecond = 2;
end

if ~exist('position','var') || isempty(position)
    position = [0,0];
end

if ~exist('zplanes','var') || isempty(zplanes)
    zplanes = 1;
end

if ~exist('ScreenType','var') || isempty(ScreenType)
    ScreenType = 'monitor';
end

% lights_off;

% choose parameters

w = whos;
w = {w.name};
for i=1:numel(w)
    result.(w{i}) = eval(w{i});
end

xposStim = position(1);
yposStim = position(2);

% RF
gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off

Bcol = 128; % Background 0 black, 255 white
method = 'symmetric';
%method = 'cut';

%TODO circular aperture
gtype = 'box';
% gtype = 'sine';

light = [0];          % light on
contrast  = 1;
prestimtimems  =  0;
result.lightStamp  =  [];

% create all stimulus conditions from the single parameter vectors
nConds  =  [length(orientations) length(sizes) length(light)];
allConds  =  prod(nConds);
repPerCond  =  allConds./nConds;
conds  =  [	reshape(repmat(orientations,repPerCond(1),1)',1,allConds);
    reshape((sizes'*ones(1,allConds/(nConds(2))))',1,allConds);
    repmat(reshape((light'*ones(1,allConds/(nConds(2)*nConds(3))))',1,allConds/nConds(2)),1,nConds(2));];

assert(strcmp(ScreenType,'projector') || strcmp(ScreenType,'monitor'));
assert(strcmp(modality,'2p') || strcmp(modality,'lf'));
if strcmp(ScreenType,'projector')
    xRes = 1024; yRes = 768;
else
    xRes = 1280; yRes = 1024;
end
% dos(['C:/Users/Resonant-2/Downloads/nircmd-x64/nircmd.exe setdisplay ' num2str(xRes) ' ' num2str(yRes) ' 32']);

VertScreenDimDeg = atand(VertScreenSize/DScreen); % in visual degrees
PixperDeg = yRes/VertScreenDimDeg;

PatchRadiusPix = ceil(sizes.*PixperDeg/2); % radius!!

x0 = floor(xRes/2 + xposStim*PixperDeg - sizes.*PixperDeg/2);
y0 = floor(yRes/2 - yposStim*PixperDeg - sizes.*PixperDeg/2);

if ~isempty(find(x0<1)) | ~isempty(find(y0<1))
    disp('too big for the monitor, dude! try other parameters');
    return;
end

% do stimulus data file management
% stimfolder = 'C:/Users/Resonant-2/Documents/Dan/StimData/';
stimfolder = 'smb://adesnik2.ist.berkeley.edu/mossing/LF2P/StimData/';
dstr = yymmdd(date);
resDir = [stimfolder dstr '/' result.animalid '/LF2P/'];
if ~exist(resDir,'dir')
    mkdir(resDir)
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
% runpath = '//adesnik2.ist.berkeley.edu/Inhibition/mossing/LF2P/running/';
% runfolder = [runpath dstr '/' base];
% if ~exist(runfolder,'dir')
%     mkdir(runfolder)
% end
fprintf(H_Run,sprintf('G%s/%s_%s_%s.bin', runfolder, base, depth, fileindex));

% % set up audio indicator
%
% ori_tones = logspace(log10(220),log10(440),numel(orientations)+1);
% ori_tones = ori_tones(1:end-1);

% set up DAQ

% daq=daq.createSession('ni');
% addDigitalChannel(daq,'Dev3','port0/line0','OutputOnly'); % stim trigger
% addDigitalChannel(daq,'Dev3','port0/line1','OutputOnly'); % projector LED on
% addDigitalChannel(daq,'Dev3','port0/line2','OutputOnly'); % complete stim protocol, move in z
% ard = arduino();
% configurePin(ard,'D2','DigitalOutput');
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
[w,rect] = Screen('OpenWindow',screenNumber);

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
    for jz = 1:result.zplanes,
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
                Zplane(trnum) = jz;
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
                thislight  =  thiscond(3);
                thiscontrast = contrast;
                thisfreq = cyclesPerVisDeg;
                thisspeed = cyclesPerSecond;
                
                ii = find(sizes==thissize) ;
                thiswidth = width(ii);
                %             thisxwidth = floor(1.4*width(ii));
                [x,y] = meshgrid([-thiswidth:thiswidth],[-thiswidth:thiswidth]);
                
                numFrames = ceil(frameRate/thisspeed);
                clear tex;
                for i=1:numFrames
                    clear T G;
                    phase = (i/numFrames)*2*pi;
                    angle = thisdeg*pi/180; % 30 deg orientation.
                    f = (thisfreq)/PixperDeg*2*pi; % cycles/pixel
                    a = cos(angle)*f;
                    b = sin(angle)*f;
                    g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
                    if streq(gtype,'sine'),
                        G0 = g0.*sin(a*x+b*y+phase);
                    elseif streq(gtype,'box'),
                        s = sin(a*x+b*y+phase);
                        ext = max(max(max(s)),abs(min(min(s))));
                        G0=ext*((s>0)-(s<0));%.*g0;
                    end
                    if streq(method,'symmetric'),
                        incmax = min(255-Bcol,Bcol);
                        G = (floor(thiscontrast*(incmax*G0)+Bcol));
                    elseif streq(method,'cut'),
                        incmax = max(255-Bcol,Bcol);
                        G = (floor(thiscontrast*(incmax*G0)+Bcol));
                        G = max(G,0);G = min(G,255);
                    end
                    
                    T = bg;
                    T(y0(ii):y0(ii)+size(G,2)-1,x0(ii):x0(ii)+size(G,2)-1) = G;
                    tex(i) = Screen('MakeTexture', w, T);
                end
                
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
                %             playtone(ori_tones(cnum),stimduration);
%                 outputSingleScan(daq,[0 1 0])
%                 outputSingleScan(daq,[1 1 0])
%                 outputSingleScan(daq,[0 1 0])
%                 writeDigitalPin(ard,'D2',0)
%                 writeDigitalPin(ard,'D2',1)
%                 writeDigitalPin(ard,'D2',0)
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
                
%                 outputSingleScan(daq,[0 1 0])
%                 outputSingleScan(daq,[1 1 0])
%                 outputSingleScan(daq,[0 1 0])
%                 writeDigitalPin(ard,'D2',0)
%                 writeDigitalPin(ard,'D2',1)
%                 writeDigitalPin(ard,'D2',0)
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
%         outputSingleScan(daq,[0 1 0])
%         outputSingleScan(daq,[0 1 1])
%         outputSingleScan(daq,[0 1 0])
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
    
    
%     outputSingleScan(daq,[0 0 0])
%     clear ard;
end

% % stop imaging
if strcmp(modality,'2p')
    terminate_udp(H_Scanbox)
end
terminate_udp(H_Run)

%fprintf(H_Scanbox,'S'); %stop
%fclose(H_Scanbox);
%delete(H_Scanbox);
%fprintf(H_Run,'S'); % somehow need to wait for a signal from stim computer
%% that running computer should stop monitoring
%fclose(H_Run);
%delete(H_Run);

% STOP ACQUISITION ON SCANBOX !!!

    function terminate_udp(handle)
        fprintf(handle,'S');
        fclose(handle);
        delete(handle);
    end

end

