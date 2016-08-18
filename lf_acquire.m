function lf_acquire(varargin)
%% initialize inputs and UDP

parse_inputs()
default_inputs()

H_Stim = udp_open();

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
[rc] = AT_SetEnumString(hndl,'PixelEncoding','Mono12');
AT_CheckWarning(rc);
[rc, framerate] = AT_GetFloat(hndl,'FrameRate');

[rc,imagesize] = AT_GetInt(hndl,'ImageSizeBytes');
AT_CheckWarning(rc);
[rc,height] = AT_GetInt(hndl,'AOIHeight');
AT_CheckWarning(rc);
[rc,width] = AT_GetInt(hndl,'AOIWidth');
AT_CheckWarning(rc);
[rc,stride] = AT_GetInt(hndl,'AOIStride');
AT_CheckWarning(rc);
for X = 1:10
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
end

disp('ready to acquire')

%% wait for UDP input

started = 0;

while(~started) % wait for UDP msg signalling stim on to be received
    if H_Stim.BytesAvailable
        [started,done] = process_stim_input(H_Stim);
    end
end

frameCount_stim = floor(stimduration/framerate);
frameCount_baseline = floor((isi-saving_factor*stimduration)/(1+saving_factor)/framerate);


% prompt = {'Enter Acquisition name','Enter number of images'};
% dlg_title = 'Configure acquisition';
% num_lines = 1;
% def = {'acquisition','10'};
% answer = inputdlg(prompt,dlg_title,num_lines,def);

tic
% filename = cell2mat(answer(1));
% frameCount = str2double(cell2mat(answer(2)));

[rc] = AT_SetInt(hndl,'FrameCount',frameCount);
AT_CheckWarning(rc);

disp('Starting acquisition...');
[rc] = AT_Command(hndl,'AcquisitionStart');
AT_CheckWarning(rc);
j=0;
while(~done)
    fid = fopen([foldname_lf ddigit(j,3) '.dat'],'w');
    i=0;
    while(i<frameCount)
        [rc,buf] = AT_WaitBuffer(hndl,AT_INFINITY);
        AT_CheckWarning(rc);
        [rc] = AT_QueueBuffer(hndl,imagesize);
        AT_CheckWarning(rc);
        %     [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
        %     AT_CheckWarning(rc);
        %
        %     thisFilename = strcat(filename, num2str(i+1), '.tiff');
        %     disp(['Writing Image ', num2str(i+1), '/',num2str(frameCount),' to disk']);
        %     imwrite(buf2,thisFilename) %saves to current directory
        fwrite(fid,buf)
        i = i+1;
        toc
        tic
    end
    fclose(fid);
    j = j+1;
end
disp('Acquisition complete');
[rc] = AT_Command(hndl,'AcquisitionStop');
AT_CheckWarning(rc);
[rc] = AT_Flush(hndl);
AT_CheckWarning(rc);
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
                case 'saving_factor'
                    saving_factor = varargin{ctr+1};
                    ctr = ctr+2;
                otherwise
                    error(sprintf('invalid argument %s',varargin{ctr}))
            end
        end
    end

    function default_inputs()
        % assign to default values
        
        if ~exist('ExposureTime','var') || isempty(ExposureTime)
            ExposureTime = 0.05;
        end
        if ~exist('saving_factor','var') || isempty(saving_factor)
            saving_factor = 1.0;
            % empirical constant; acq_time*saving_factor >= saving_time
        end
    end
end