% Open memory mapped file -- define just the header first

mmfile = memmapfile('scanbox.mmap','Writable',true, ...
    'Format', { 'int16' [1 16] 'header' } , 'Repeat', 1);
flag = 1;

close all

%%

% Process all incoming frames until Scanbox stops

% msocket connection to visual stim PC
server = '128.32.173.6';
disp('waiting on TTL')

%% initialize DAQ, which we'll need to send the ttl signals

dsesh = daq.createSession('ni');
dsesh.addDigitalChannel('Dev1','port1/line0','OutputOnly');
dsesh.outputSingleScan([0])
dsesh.outputSingleScan([1])

% wait to hear desired number of triggers
triginfo_recvd = false;
while ~triginfo_recvd

    while(mmfile.Data.header(1)<0) % wait for a new frame...
        if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            dsesh.outputSingleScan([0])
            return;
        end
    end
    triginfo_recvd = mmfile.Data.header(4);
    if triginfo_recvd
        disp('received TTL')
        sock = msconnect(server,3000);
        trigno = msrecv(sock);
        dsesh.outputSingleScan([1])
        dsesh.outputSingleScan([0])
    end
    mmfile.Data.header(1) = -1;
end

msclose(sock)

%%

frames_to_avg = 100;
ctr = 0;

moveon = false;

accumulated = zeros(512,796);

while ctr < frames_to_avg
    
    while(mmfile.Data.header(1)<0) % wait for a new frame...
        if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            dsesh.outputSingleScan([0])
            return;
        end
    end
    
    display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
    
    if(flag) % first time? Format chA according to lines/columns in data
        mmfile.Format = {'int16' [1 16] 'header' ; ...
            'uint16' double([mmfile.Data.header(2) mmfile.Data.header(3)]) 'chA'};
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        accumulated = mchA;
        flag = 0;
    else
        accumulated = accumulated + double(intmax('uint16')-mmfile.Data.chA);
    end
    
    imagesc(mchA)
    
    mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
    
    drawnow limitrate;
    
    ctr = ctr+1;
end

% select ROI
imagesc(accumulated);
obj = imfreehand;
pos = obj.getPosition;
msk = poly2mask(pos(:,1),pos(:,2),size(mchA,1),size(mchA,2));

% acquire baseline data
ctr = 0;
frames_to_baseline = 500;
baseline_trace = nan(frames_to_baseline,1);
while ctr < frames_to_baseline
    
    while(mmfile.Data.header(1)<0) % wait for a new frame...
        if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            dsesh.outputSingleScan([0])
            return;
        end
    end
    
    display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
    
    mchA = double(intmax('uint16')-mmfile.Data.chA);
    
    subplot(1,2,1)
    imagesc(mchA)
    subplot(1,2,2)
    baseline_trace(ctr+1) = sum(mchA(msk));
    plot(1:frames_to_baseline,baseline_trace)
    
    mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
    
    drawnow limitrate;
    
    ctr = ctr+1;
end

threshhi = 0.9;
fcutoffhi = prctile(baseline_trace,100*threshhi);
threshlo = 0.7;
fcutofflo = prctile(baseline_trace,100*threshlo);

% trigger on that ROI lighting up

trigctr = 0;
fcurrent = 0;
deadframes = 50;
silentframes = 50;
fbuffer = baseline_trace;
first = true;
while trigctr < trigno
    sincelasttrigger = 0;
    % deliver a stim when the neuron is active
    while fcurrent < fcutoffhi || sincelasttrigger < deadframes
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                return;
            end
        end
        
        %         display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
        
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        fcurrent = sum(mchA(msk));
        subplot(1,2,1)
        imagesc(mchA)
        hold on;
        plot(pos(:,1),pos(:,2),'r')
        hold off;
        subplot(1,2,2)
        fbuffer = [fbuffer(2:end); fcurrent];
        plot(fbuffer)
        hold on;
        plot(fcutoffhi*ones(size(fbuffer)),'g')
        plot(fcutofflo*ones(size(fbuffer)),'b')
        hold off;
        
        mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
        
        drawnow limitrate;
        sincelasttrigger = sincelasttrigger+1;
    end
    disp(num2str(trigctr))
    % SEND TTL PULSE
    dsesh.outputSingleScan([0])
    dsesh.outputSingleScan([1])
    handshook = false;
    while ~handshook
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                dsesh.outputSingleScan([0])
                return;
            end
        end
        handshook = mmfile.Data.header(4);
        mmfile.Data.header(1) = -1; 
    end
    dsesh.outputSingleScan([0])
    sincelastresponse = 0;
    sincelasttrigger = 0;
    trigctr = trigctr+1;
    % deliver a stim when the neuron has been silent awhile
    while sincelastresponse < silentframes || sincelasttrigger < deadframes
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                dsesh.outputSingleScan([0])
                return;
            end
        end
        
        %         display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
        
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        fcurrent = sum(mchA(msk));
        subplot(1,2,2)
        fbuffer = [fbuffer(2:end); fcurrent];
        plot(fbuffer)
        hold on;
        plot(fcutoffhi*ones(size(fbuffer)),'g')
        plot(fcutofflo*ones(size(fbuffer)),'b')
        hold off;
        
        mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
        
        drawnow limitrate;
        sincelasttrigger = sincelasttrigger+1;
        if fcurrent < fcutofflo
            sincelastresponse = sincelastresponse+1;
        else
            sincelastresponse = 0;
        end
    end
    disp(num2str(trigctr))
    % SEND TTL PULSE
    dsesh.outputSingleScan([0])
    dsesh.outputSingleScan([1])
    handshook = false;
    while ~handshook
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                dsesh.outputSingleScan([0])
                return;
            end
        end
        handshook = mmfile.Data.header(4);
        mmfile.Data.header(1) = -1; 
    end
    dsesh.outputSingleScan([0])
    sincelasttrigger = 0;
    trigctr = trigctr+1;
end

while true
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                dsesh.outputSingleScan([0])
                return;
            end
        end
end

clear mmfile; % close the memory mapped file
close all;     % close all figures
dsesh.release