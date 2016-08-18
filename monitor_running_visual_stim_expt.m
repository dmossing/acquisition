function monitor_running_visual_stim_expt()
try
    done = 0;
    DAQ = [];
    H_RunDataFile = [];
    H_Stim = udp_open();
    cleanup_udp_Stim = onCleanup(@(), udp_close(H_Stim));
    while ~done
        if H_Stim.BytesAvailable
            done = process_stim_input(H_Stim);%,DAQ);
        end
        pause(0.5)
    end
    copyfile(fname_run,fname_cp)
catch
    udp_close(H_Stim);
    fclose(H_RunDataFile)
end

function H_Stim = udp_open()
stim_port = 25000;
H_Stim = udp('128.32.173.24', 'RemotePort', stim_port, ...
    'LocalPort', stim_port,'BytesAvailableFcn',@process_stim_input);
fopen(H_Stim);
end

function udp_close(H_Stim)
fclose(H_Stim);
delete(H_Stim);
end

function [done] = process_stim_input(a) %,DAQ)
msg = fgetl(a);
switch msg(1)
    case 'G'
        fname_run = msg(2:end);
        subpath = strsplit(fname_run,'running/');
        subpath = subpath{2};
        subfold = strsplit(subpath,'/');
        fname_only = subfold{3};
        subfold = strjoin(subfold(1:2),'/');
        copypath = 'C:/Users/Resonant-2/Documents/Dan/running/';
        mkdir([copypath subfold])
        fname_cp = [copypath subfold '/' fname_only];
        disp(fname_run)
        fid = fopen(fname_run,'w')
        fclose(fid)
%         clear DAQ
        [DAQ,H_RunDataFile] = monitor_running(fname_run);
        disp('now monitoring')
        done = 0;
    case 'S'
        % stop monitoring running, close file, close UDP communication
        DAQ.stop;
        clear DAQ
        fclose(H_RunDataFile);
        udp_close(H_Stim);
        disp('finished')
        done = 1;
end
end
end

% assign to default values
% stim_port = 25000;
% H_Stim = udp('128.32.173.24', 'RemotePort', stim_port, ...
%     'LocalPort', stim_port,'BytesAvailableFcn',@process_stim_input);
% fopen(H_Stim);

% fname_run = '';
% while isempty(fname_run)
%     fname_run = fscanf(H_Stim); % get full path to desired running file via UDP
% end
%
% % set up DAQ
% fname_run = fname_run(1:end-1);
% disp(fname_run)
% fid = fopen(fname_run,'w')
% fclose(fid)
% clear DAQ
% [DAQ,H_RunDataFile] = monitor_running(fname_run);
% disp('now monitoring')

% % wait for stop signal
%
% stopnow = '';
% while isempty(stopnow)
%     stopnow = fscanf(H_Stim);
% end

% % stop monitoring running, close file, close UDP communication
% DAQ.stop;
% fclose(H_RunDataFile);
% delete(H_RunDataFile);
% fclose(H_Stim);
% delete(H_Stim);
% disp('finished')

% if(~isempty(sb_server))
%     udp_close;
% end
% sb_server=udp('localhost', 'LocalPort', 7000,'BytesAvailableFcn',@udp_cb);

% fopen(sb_server);

