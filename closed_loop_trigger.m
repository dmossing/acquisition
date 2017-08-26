% Open memory mapped file -- define just the header first

mmfile = memmapfile('scanbox.mmap','Writable',true, ...
    'Format', { 'int16' [1 16] 'header' } , 'Repeat', 1);
flag = 1;

%%

% Process all incoming frames until Scanbox stops

% % msocket connection to visual stim PC
% server = '128.32.173.6';
% disp('waiting on TTL')

frames_to_avg = 100;
ctr = 0;

moveon = false;

accumulated = zeros(512,796);

while ctr < frames_to_avg
    
    while(mmfile.Data.header(1)<0) % wait for a new frame...
        if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
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
imshow(accumulated);
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
threshlo = 0.6;
fcutoffhi = prctile(baseline_trace,100*threshlo);

% trigger on that ROI lighting up

trigctr = 0;
trigno = 20;
fcurrent = 0;
deadframes = 30;
silentframes = 75;
while trigctr < trigno
    % deliver a stim when the neuron is active
    while fcurrent < fcutoffhi || sincelasttrigger < deadframes
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                return;
            end
        end
        
        display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
        
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        fcurrent = sum(mchA(msk));
        sincelasttrigger = sincelasttrigger+1;
    end
    disp('triggering')
    % SEND TTL PULSE; WILL HAVE TO SEE HOW TO DO THIS ON 2P RIG
    sincelastresponse = 0;
    sincelasttrigger = 0;
    trigctr = trigctr+1;
    % deliver a stim when the neuron has been silent awhile
    while sincelastresponse < silentframes || sincelasttrigger < deadframes
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                return;
            end
        end
        
        display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
        
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        fcurrent = sum(mchA(msk));
        sincelasttrigger = sincelasttrigger+1;
        if fcurrent < fcutofflo
            sincelastresponse = sincelastresponse+1;
        else
            sincelastresponse = 0;
        end
    end
    disp('triggering')
    % SEND TTL PULSE; WILL HAVE TO SEE HOW TO DO THIS ON 2P RIG
    sincelasttrigger = 0;
    trigctr = trigctr+1;
end

clear(mmfile); % close the memory mapped file
close all;     % close all figures