function summary_arr = mapRF2p()
% Display real-time histogram in Scanbox

summary_arr = []; % this will be an array with the average intensity of the current FOV given a stim at each location

% Prepare the figure for display

close all;
h=figure(1);
h.MenuBar = 'None';
h.NumberTitle = 'off';
h.Name = 'Scanbox ChA real time average';
drawnow;

% Open memory-mapped file to have access to image stream

mmfile = memmapfile('scanbox.mmap','Writable',true, ...
    'Format', { 'int16' [1 16] 'header' } , 'Repeat', 1);

% Some parameters for display

nframes = 10; % how often we want to display histogram
nbins = 128; % how many bins in the histogram
margin = 20; % size of the margins to crop around the central ROI

% Start processing until Scanbox stops...

frmno = 0;

flag = 1; % Necessary to set image format the first time

done = 0;

started = 0;

i=[]; j=[];

Nx=0; Ny=0;

%% set up UDP connection to take in and store stim information

H_Stim = udp_open();

while(~started) % wait for UDP msg signalling stim on to be received
    if H_Stim.BytesAvailable
        process_stim_input(H_Stim)
    end
end

while(~done)
    if H_Stim.BytesAvailable
        process_stim_input(H_Stim)
    end
    while(mmfile.Data.header(1)<0) % wait for a new frame to arrive
        if(mmfile.Data.header(1) == -2) % exit if Scanbox finished acquiring data\
            udp_close(H_Stim);
            return;
        end
    end
    
    if(flag) % First time? Format chA according to lines/columns in header
        mmfile.Format = {'int16' [1 16] 'header' ; ...
            'uint16' double([mmfile.Data.header(2) mmfile.Data.header(3)]) 'chA'};
        mchA = double(mmfile.Data.chA);
        flag = 0;
    end
    
    %if(mod(frmno,nframes==0)) % update histogram every nframes frames
    %    imhist(intmax('uint16')-mmfile.Data.chA(margin:end-margin,margin:end-margin),nbins); % display histogram
    %    drawnow;
    %end
    mchA = mchA + double(mmfile.Data.chA);
    frmno = frmno+1;
    if(mod(frmno,nframes==0)) % update histogram every nframes frames
        imagesc(mchA/frmno/(2^24)) % display histogram
        drawnow;
    end
    
    mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
end

clear('mmfile') % close memory-mapped file

figure(2)
imagesc(summary_arr)

%%% local UDP functions

    function H_Stim = udp_open()
        stim_port = 26000; % this is the designated port for stim PC - scanbox PC communication
        H_Stim = udp('128.32.173.24', 'RemotePort', stim_port, ...
            'LocalPort', stim_port,'BytesAvailableFcn',@process_stim_input);
        fopen(H_Stim);
    end

    function udp_close(H_Stim) 
        fclose(H_Stim);
        delete(H_Stim);
    end

    function process_stim_input(a) %,DAQ)
        msg = fgetl(a);
        switch msg(1)
            case 'R'
                % reset: take as input the size of the array of locations that will be probed
                map_sz = strsplit(msg(2:end),',');
                Ny = str2num(map_sz{1}); Nx = str2num(map_sz{2});
                summary_arr = zeros(Ny,Nx);
                started = 1;
                disp('starting RF mapping')
            case 'N'
                % read in information on where the stimulus is currently located
                if ~isempty(i)
                    figure(1)
                    subplot(Ny,Nx,sub2ind([Nx Ny],j,i))
                    imagesc(mchA/frmno/(2^24))
                    summary_arr(i,j) = mean(mchA(:))/frmno;
                end
                mchA = zeros(512,796);
                map_loc = msg(2:end);
                map_loc = strsplit(map_loc,',');
                i = str2num(map_loc{1}); j = str2num(map_loc{2});
                frmno = 0;
                disp(sprintf('next location: (%d,%d)',i,j))
            case 'S'
                % stop mapping, return max to stim PC
                summary_arr(i,j) = mean(mchA(:))/frmno;
                figure(1)
                subplot(Ny,Nx,sub2ind([Nx Ny],j,i)) % flip indices for visualization purposes
                imshow(mchA/frmno/(2^24))
                summary_arr(i,j) = mean(mchA(:))/frmno;
                [imax,jmax] = find(summary_arr == max(summary_arr(:)),1);
                pause(5)
                fprintf(H_Stim,sprintf('M%d,%d',imax,jmax));
                disp(sprintf('M%d,%d',imax,jmax))
                udp_close(H_Stim);
                disp('finished')
                done = 1;
        end
    end

%%%

end
