function run_opto_stim_expt(varargin)

p = inputParser;
p.addParameter('modality','2p');
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('repetitions',10);
p.addParameter('isi',3);
p.addParameter('opto_duration',100);
p.addParameter('opto_amplitude',1.0);
p.addParameter('opto_targets',[nan 1:3]);
p.addParameter('gen_stim_vars_fn',@gen_opto_stim_vars);
p.parse(varargin{:});

% choose parameters

result = p.Results;

AssertOpenGL;

stim_vars = result.gen_stim_vars_fn();

isi = result.isi;

% create all stimulus conditions from the single parameter vectors
conds = stim_vars.gen_conds_fn(result);
allConds = size(conds,2);

assert(strcmp(result.modality,'2p') || strcmp(result.modality,'lf'));

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

% prepare optogenetic stims
%%%

% "r<int>"      Set the SLM spot radius to <int> pixels,  eg, "r10"
% "p<int>"      Set the pulse width of the stimulation to <int> msec; eg, "p20"
% "s"           Stimulate (currently selected cell)
% "l<float>"    Set SLM laser amplitude; eg, "l0.5" (float number between 0.0 and 5.0).      
% "h"           Compute SLM phase of currently defined ROIs
% "i<int>"   	Select ROI #i (you should have previously asked to compute
% the phases)

%%%
% fprintf(H_Scanbox,'r1')
% fprintf(H_Scanbox,'h');


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

result = stim_vars.gen_result_fn(result,conds);

FlushEvents;
[kinp,tkinp] = GetChar;
if kinp == 'q'|kinp == 'Q',
else
    %     outputSingleScan(daq,[0 1 0]);
    % start imaging
    if strcmp(result.modality,'2p')
        disp('got here')
        fprintf(H_Scanbox,'G'); %go
    end
    pause(3);
    
    t0  =  GetSecs;
    trnum = 0;
    
    % set up to show stimuli
    for itrial = 1:result.repetitions,
        for istim = 1:allConds
            %             [kinp,tkinp] = GetChar;
            
            disp('Signal on 2')
            
            trnum = trnum+1;
            trialstart = GetSecs-t0;
            
            % Information to save in datafile:
%             thiscondind = allthecondinds(istim,itrial);
%             thiscond = conds(:,thiscondind);
            cnum = istim;
            Trialnum(trnum) = trnum;
            Condnum(trnum) = cnum;
            Repnum(trnum) = itrial;
%             result = pickNext(result,trnum,thiscond);
            % end save information
            
            thisstim = stim_vars.gen_stim_fn(result.roiInfo,trnum);
            thisstim.itrial = itrial;
            
            result = deliver_stim(result,thisstim,d);
            
            [keyIsDown, secs, keyCode] = KbCheck;
            if keyIsDown & KbName(keyCode) == 'p'
                KbWait([],2); 
                %wait for all keys to be released and then any key to be pressed again
            end
        end
    end
    
    result.stimParams = conds(:,Condnum);
    
    save(fnameLocal, 'result');
    save(fnameRemote, 'result');
    
    [kinp,tkinp] = GetChar;
    
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

    function result = deliver_stim(result,thisstim,d)
            prestimtimems = 0;
                        
            WaitSecs(max(0, result.isi-((GetSecs-t0)-trialstart)));
            
            WaitSecs(max(0,prestimtimems/1000));
            
            stimstart  =  GetSecs-t0;
            
            % send stim on trigger
            DaqDOut(d,0,0);
            DaqDOut(d,0,255);
            DaqDOut(d,0,0);
            disp('stim on')
%             tic
            if ~isnan(thisstim.thisroi)
                fprintf(H_Scanbox,['p' num2str(uint16(thisstim.thisduration))])
                fprintf(H_Scanbox,['l' num2str(thisstim.thisamplitude)])
                fprintf(H_Scanbox,['i' num2str(thisstim.thisroi)])
                fprintf(H_Scanbox,'s')
            end
%             toc
            
            DaqDOut(d,0,0);
            DaqDOut(d,0,255);
            DaqDOut(d,0,0);
            disp('stim off')
            
            stimt = GetSecs-t0-stimstart;
    end
end