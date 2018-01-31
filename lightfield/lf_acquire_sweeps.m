function lf_acquire_sweeps(varargin)
%% initialize inputs and UDP

parse_inputs(varargin{:})
default_inputs()

%% set camera params

% disp('Andor SDK3 Kinetic Series Acquisition');
[rc] = AT_InitialiseLibrary();
AT_CheckError(rc);
[rc,hndl] = AT_Open(0);
AT_CheckError(rc);
disp('Camera initialized');
[rc] = AT_SetFloat(hndl,'ExposureTime',ExposureTime);
AT_CheckWarning(rc);
if triggered
    [rc] = AT_SetEnumString(hndl,'CycleMode','Continuous');
    AT_CheckWarning(rc);
    [rc] = AT_SetEnumString(hndl,'TriggerMode','External Start');
    AT_CheckWarning(rc);
else
    [rc] = AT_SetEnumString(hndl,'CycleMode','Fixed');
    AT_CheckWarning(rc);
    [rc] = AT_SetEnumString(hndl,'TriggerMode','Internal');
    AT_CheckWarning(rc);
end
[rc] = AT_SetEnumString(hndl,'SimplePreAmpGainControl','12-bit (low noise)');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'PixelEncoding','Mono12'); % need to make sure I can still read this
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

if triggered
    H_Stim = udp_open();
    cleanup_obj_udp = onCleanup(@() udp_close(H_Stim));
    [lj_obj,lj_h] = labjack_open();
    cleanup_obj_lj = onCleanup(@() labjack_close(lj_obj,lj_h));
end

%% wait for UDP input

started = 0;

if triggered
    while ~started % wait for UDP msg signalling stim on to be received
        if H_Stim.BytesAvailable
            [started,done] = process_stim_input(H_Stim);
        end
    end
end
checkevery = record_for;

if ~triggered
    frameCount = floor(checkevery*framerate);
    sweepCount = 2;
    rc = AT_SetInt(hndl,'FrameCount',frameCount);
    AT_CheckWarning(rc);
end

disp('ready to acquire')

tic

done = 0;
[rc] = AT_Flush(hndl);
AT_CheckWarning(rc);
for X = 1:2000
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
end
fid_im = fopen([foldname_lf filename_lf '.dat'],'w');
if triggered
    fid_stim = fopen([foldname_lf filename_lf '.ctr'],'w');
end

closefiles = onCleanup(@() fclose('all'));

disp('Starting acquisition...');
% while ~done
% record of the stim counter var for each frame

% [rc] = AT_Command(hndl,'AcquisitionStop');
% AT_CheckWarning(rc);
tic
if triggered
    while ~done
        stimct=0;
        i=0;
        [rc] = AT_Command(hndl,'AcquisitionStart');
        AT_CheckWarning(rc);
        while stimct < trigpersweep && i < 5000
            [rc,buf] = AT_WaitBuffer(hndl,1000);
            AT_CheckWarning(rc);
            [rc] = AT_QueueBuffer(hndl,imagesize);
            AT_CheckWarning(rc);
            if ~isempty(buf)
                fwrite(fid_im,buf,'uint8')
                stimct = labjack_get_ctr(lj_obj,lj_h);
                i = i+1;
            end
            toc
            tic
        end
        [rc] = AT_Command(hndl,'AcquisitionStop');
        AT_CheckWarning(rc);
        [rc] = AT_Flush(hndl);
        AT_CheckWarning(rc);
        if H_Stim.BytesAvailable
            [started,done] = process_stim_input(H_Stim);
        end
    end
else
    s=0;
    while s < sweepCount
        toc
        tic
        i=0;
        [rc] = AT_Command(hndl,'AcquisitionStart');
        AT_CheckWarning(rc);
        while i < frameCount
            [rc,buf] = AT_WaitBuffer(hndl,1000);
            AT_CheckWarning(rc);
            [rc] = AT_QueueBuffer(hndl,imagesize);
            AT_CheckWarning(rc);
            if ~isempty(buf)
                fwrite(fid_im,buf,'uint8')
                i = i+1;
            end
            toc
            tic
            [rc] = AT_Command(hndl,'AcquisitionStop');
            AT_CheckWarning(rc);
            [rc] = AT_Flush(hndl);
            AT_CheckWarning(rc);
        end
        s = s+1;
    end
end
toc
% end
fclose(fid_im);
if triggered
    fclose(fid_stim);
end
disp('Acquisition complete');

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
                filename_lf = [foldname_lf args{2}];
                disp(filename_lf)
%                 record_for = floor(1.1*str2num(args{3}))+30;
                trigpersweep = str2num(args{3});
                started = 1;
                done = 0;
            case 'S'
                udp_close(H_Stim);
                labjack_close(lj_obj,lj_h);
                disp('finished')
                started = 1;
                done = 1;
        end
    end


%% local input parsing functions

    function parse_inputs(varargin)
        ctr = 1;
        while ctr <= nargin
            switch varargin{ctr}
                case 'ExposureTime'
                    ExposureTime = varargin{ctr+1};
                    ctr = ctr+2;
                case 'triggered'
                    triggered = varargin{ctr+1};
                    ctr = ctr+2;
                case 'foldname'
                    foldname_lf = format_fold(varargin{ctr+1});
                    ctr = ctr+2;
                case 'filename'
                    filename_lf = varargin{ctr+1};
                    ctr = ctr+2;
                case 'duration'
                    record_for = varargin{ctr+1};
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
        % 'duration' will set the length of the recording if not triggered
        if ~triggered && (~exist('record_for','var') || isempty(record_for))
            record_for = 60;
        end
        if ~triggered && (~exist('foldname_lf','var') || isempty(foldname_lf))
            foldname_lf = 'E:/LF2P/Dan/test/';
        end
        if ~triggered && (~exist('filename_lf','var') || isempty(filename_lf))
            filename_lf = 'fake';
        end
        if ~triggered
            if(~exist(foldname_lf,'dir'))
                mkdir(foldname_lf);
            end
        end
    end
end