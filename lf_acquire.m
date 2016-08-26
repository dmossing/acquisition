function lf_acquire(varargin)
%% initialize inputs and UDP

parse_inputs()
default_inputs()

H_Stim = udp_open();
cleanup_obj_udp = onCleanup(@() udp_close(H_Stim));

lj = labjack_open();
cleanup_obj_lj = onCleanup(@() labjack_close(lj));

%% set camera params

% disp('Andor SDK3 Kinetic Series Acquisition');
[rc] = AT_InitialiseLibrary();
AT_CheckError(rc);
[rc,hndl] = AT_Open(0);
AT_CheckError(rc);
disp('Camera initialized');
[rc] = AT_SetFloat(hndl,'ExposureTime',ExposureTime);
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'CycleMode','Fixed');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'TriggerMode','External Start');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'SimplePreAmpGainControl','12-bit (low noise)');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'PixelEncoding','Mono16');
AT_CheckWarning(rc);
[rc, framerate] = AT_GetFloat(hndl,'FrameRate');
AT_CheckWarning(rc);

[rc,imagesize] = AT_GetInt(hndl,'ImageSizeBytes');
AT_CheckWarning(rc);
[rc,height] = AT_GetInt(hndl,'AOIHeight');
AT_CheckWarning(rc);
[rc,width] = AT_GetInt(hndl,'AOIWidth');
AT_CheckWarning(rc);
[rc,stride] = AT_GetInt(hndl,'AOIStride');
AT_CheckWarning(rc);

%% wait for UDP input

started = 0;

if triggered
    while ~started % wait for UDP msg signalling stim on to be received
        if H_Stim.BytesAvailable
            [started,done] = process_stim_input(H_Stim);
        end
    end
end

frameCount = floor(stimduration*framerate);
rc = AT_SetInt(hndl,'FrameCount',frameCount);
AT_CheckWarning(rc);

disp('ready to acquire')

tic

j=0;
done = 0;
% foldname_lf = 'E:/Dan/LF2P/';
while(~done)
    [rc] = AT_Flush(hndl);
    AT_CheckWarning(rc);
    for X = 1:10
        [rc] = AT_QueueBuffer(hndl,imagesize);
        AT_CheckWarning(rc);
    end
    fid = fopen([foldname_lf ddigit(j,3) '.dat'],'w');
    i=0;
    disp('Starting acquisition...');
    [rc] = AT_Command(hndl,'AcquisitionStart');
    AT_CheckWarning(rc);
    while(i<frameCount)
        [rc,buf] = AT_WaitBuffer(hndl,1000);
        AT_CheckWarning(rc);
        [rc] = AT_QueueBuffer(hndl,imagesize);
        AT_CheckWarning(rc);
        if ~isempty(buf)
            i = i+1;
            fwrite(fid,buf)
        end
        toc
        tic
    end
    done = 0;
    fclose(fid);
    j = j+1;
    disp('Acquisition complete');
    [rc] = AT_Command(hndl,'AcquisitionStop');
    AT_CheckWarning(rc);
    [rc] = AT_Flush(hndl);
    AT_CheckWarning(rc);
end
[rc] = AT_Close(hndl);
AT_CheckWarning(rc);
[rc] = AT_FinaliseLibrary();
AT_CheckWarning(rc);
disp('Camera shutdown');
toc

%% local UDP functions

    function H_Stim = udp_open()
        stim_port = 29000;
        H_Stim = udp('128.32.173.24', 'RemotePort', stim_port, ...
            'LocalPort', stim_port,'BytesAvailableFcn',@process_stim_input);
        fopen(H_Stim);
    end

    function udp_close(H_Stim)
        fclose(H_Stim);
        delete(H_Stim);
    end

    function [started,done] = process_stim_input(a) %,DAQ)
        msg = fgetl(a);
        switch msg(1)
            case 'G'
                args = strsplit(msg(2:end),';');
                foldname_lf = format_fold(args{1});
                if(~exist(foldname_lf,'dir'))
                    mkdir(foldname_lf);
                end
                disp(foldname_lf)
                stimduration = str2double(args{2});
                isi = str2double(args{3});
                started = 1;
                done = 0;
            case 'S'
                udp_close(H_Stim);
                disp('finished')
                started = 1;
                done = 1;
        end
    end

%% local input parsing functions

    function parse_inputs()
        ctr = 1;
        while ctr <= nargin
            switch varargin{ctr}
                case 'ExposureTime'
                    ExposureTime = varargin{ctr+1};
                    ctr = ctr+2;
                case 'triggered'
                    triggered = varargin{ctr+2};
                    ctr = ctr+2;
                otherwise
                    error(sprintf('invalid argument %s',varargin{ctr}))
            end
        end
    end

    function default_inputs()
        % assign to default values
        
        if ~exist('ExposureTime','var') || isempty(ExposureTime)
            ExposureTime = 0.022;
        end
        if ~exist('triggered','var') || isempty(triggered)
            triggered = true;
        end
    end
end