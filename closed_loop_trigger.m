function closed_loop_trigger

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

global mmfile
global dsesh

dsesh.outputSingleScan([0])
dsesh.outputSingleScan([1])

% wait to hear desired number of triggers
triginfo_recvd = false;
while ~triginfo_recvd
    
    %     while(mmfile.Data.header(1)<0) % wait for a new frame...
    %         if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
    %             dsesh.outputSingleScan([0])
    %             return;
    %         end
    %     end
    awaitFrame;
    triginfo_recvd = mmfile.Data.header(4);
    if triginfo_recvd
        disp('received TTL')
        sock = msconnect(server,3000);
        trigno = msrecv(sock);
        showfirst = msrecv(sock);
        numToTrigOn = msrecv(sock);
        roifile = msrecv(sock);
        frames_to_avg = msrecv(sock); % only used if ~showfirst
        frames_to_baseline = msrecv(sock);
        deadframes = msrecv(sock);
        silentframes = msrecv(sock);
        updateevery = msrecv(sock);
        threshhi = msrecv(sock);
        threshlo = msrecv(sock);
        dsesh.outputSingleScan([1])
        dsesh.outputSingleScan([0])
        msclose(sock)
    end
    %     mmfile.Data.header(1) = -1;
end

%%


msk = false(512,796,numToTrigOn);
% trigbuffer = ones(100,1);

if showfirst
    for roino = 1:numToTrigOn
        pause(2)
        accumulated = zeros(512,796);
        disp('initiating handshake')
        performHandshake; %(dsesh,mmfile)
        disp('done')
        
%         on = false;
%         onandoff = false;
        off = false;
        offandon = false;
        offandonandoff = false;
        while ~offandonandoff
            awaitFrame;
            if off
                offandon = mmfile.Data.header(4);
                if offandon
                    off = false;
                    disp('goes up')
                end
            elseif offandon
                offandonandoff = ~mmfile.Data.header(4);
                if offandonandoff
                    offandon = false;
                    disp('goes down')
                end
            else
                off = ~mmfile.Data.header(4);
            end
%         prevHeader = false;
%         
%         while ~onandoff % wait until the stim has turned on and off
%             awaitFrame;
%             if on
%                 onandoff = ~mmfile.Data.header(4) && ~prevHeader;
%                 on = ~onandoff;
%                 if onandoff
%                     disp('goes down')
%                 end
%             else
%                 on = mmfile.Data.header(4) && prevHeader;
%                 if on
%                     disp('goes up')
%                 end
%             end
%             prevHeader = mmfile.Data.header(4);
            %             while(mmfile.Data.header(1)<0) % wait for a new frame...
            %                 if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            %                     dsesh.outputSingleScan([0])
            %                     return;
            %                 end
            %                 if on
            %                     onandoff = ~mmfile.Data.header(4);
            %                     on = ~onandoff;
            %                 else
            %                     on = mmfile.Data.header(4);
            %                 end
            %             end
            
            %             display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
            
            if(flag) % first time? Format chA according to lines/columns in data
                mmfile.Format = {'int16' [1 16] 'header' ; ...
                    'uint16' double([mmfile.Data.header(2) mmfile.Data.header(3)]) 'chA'};
                mchA = double(intmax('uint16')-mmfile.Data.chA);
%                 if on
                if offandon
                    accumulated = mchA;
                else
                    accumulated = zeros(size(mchA));
                end
                flag = 0;
            else
                mchA = double(intmax('uint16')-mmfile.Data.chA);
%                 if on
                if offandon
                    accumulated = accumulated + mchA;
                end
            end
%             subplot(1,2,1)
            imagesc(accumulated)
%             trigbuffer = [trigbuffer(2:end); mmfile.Data.header(4)];
%             subplot(1,2,2)
%             plot(trigbuffer)
%             drawnow limitrate;
            % mmfile.Data.header(1) = -1;
        end
        
        % select ROI
        imagesc(accumulated);
        goon = false; % show finished selecting ROIs by hitting RETURN
        while ~goon
            obj = imfreehand;
            pos = obj.getPosition;
            msk(:,:,roino) = msk(:,:,roino) | poly2mask(pos(:,1),pos(:,2),size(mchA,1),size(mchA,2));
            pause;
            currkey = get(gcf,'CurrentKey');
            if strcmp(currkey,'return')
                goon = true;
            end
        end
    end
    performHandshake; %(dsesh,mmfile)
else
    accumulated = zeros(512,796);
    %     frames_to_avg = 300;
    ctr = 0;
    while ctr < frames_to_avg
        
        %         while(mmfile.Data.header(1)<0) % wait for a new frame...
        %             if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
        %                 dsesh.outputSingleScan([0])
        %                 return;
        %             end
        %         end
        awaitFrame;
        %         display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
        
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
        
        %         mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
        
        drawnow limitrate;
        
        ctr = ctr+1;
    end
    
    % select ROI
    imagesc(accumulated);
    for roino=1:numToTrigOn
        goon = false; % show finished selecting ROIs by hitting RETURN
        while ~goon
            obj = imfreehand;
            pos = obj.getPosition;
            msk(:,:,roino) = msk(:,:,roino) | poly2mask(pos(:,1),pos(:,2),size(mchA,1),size(mchA,2));
            pause;
            currkey = get(gcf,'CurrentKey');
            if strcmp(currkey,'return')
                goon = true;
            end
        end
    end
end

roibds = cell(numToTrigOn,1);
for roino=1:numToTrigOn
    roibds{roino} = bwboundaries(msk(:,:,roino));
    roibds{roino} = cell2mat(roibds{roino});
end

% acquire baseline data
ctr = 0;
% frames_to_baseline = 500;
baseline_trace = nan(frames_to_baseline,numToTrigOn);
dots = {'m','r','g'};
while ctr < frames_to_baseline
    
    %     while(mmfile.Data.header(1)<0) % wait for a new frame...
    %         if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
    %             dsesh.outputSingleScan([0])
    %             return;
    %         end
    %     end
    awaitFrame;
    
    %     display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
    
    mchA = double(intmax('uint16')-mmfile.Data.chA);
    
    subplot(1,1+numToTrigOn,1)
    imagesc(mchA)
    hold on;
    for roino=1:numToTrigOn
        scatter(roibds{roino}(:,2),roibds{roino}(:,1),[dots{roino} '.'])
    end
    hold off;
    for roino = 1:numToTrigOn
        subplot(1,1+numToTrigOn,1+roino)
        baseline_trace(ctr+1,roino) = sum(mchA(msk(:,:,roino)));
        plot(1:frames_to_baseline,baseline_trace(:,roino),[dots{roino} '-'])
    end
    
    %     mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
    
    drawnow limitrate;
    
    ctr = ctr+1;
end

% trigger on that ROI lighting up

trigctr = 0;
fcurrent = 0;
% deadframes = 50;
% silentframes = 15;
fbuffer = baseline_trace;
first = true;
% updateevery = 500;
% updatectr = 0;

% threshhi = 0.9;
% threshlo = 0.7;
fcutoffhi = prctile(fbuffer,100*threshhi);
fcutofflo = prctile(fbuffer,100*threshlo);
fcurrent = zeros(1,numToTrigOn);
skipout = false;
sincelasttrigger = 0;

while trigctr < trigno
    sincelasttrigger = sincelasttrigger+1;
    whichtrig = rem(trigctr,numToTrigOn+1);
    if whichtrig<numToTrigOn
        trigroino = 1+whichtrig;
%         sincelasttrigger = 0;
        % deliver a stim when the neuron is active
        while fcurrent(trigroino) < fcutoffhi(trigroino) || sincelasttrigger < deadframes
            %             while(mmfile.Data.header(1)<0) % wait for a new frame...
            %                 if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            %                     return;
            %                 end
            %             end
            awaitFrame;
            if rem(sincelasttrigger,updateevery)==0 %rem(updatectr,updateevery)==0
                if first
                    first = false;
                else
                    fcutoffhi = prctile(fbuffer,100*threshhi);
                    fcutofflo = prctile(fbuffer,100*threshlo);
                end
            end
%             updatectr = updatectr+1;
            
            %         display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
            
            mchA = double(intmax('uint16')-mmfile.Data.chA);
            for roino=1:numToTrigOn
                fcurrent(roino) = sum(mchA(msk(:,:,roino)));
            end
            subplot(1,1+numToTrigOn,1)
            imagesc(mchA)
            hold on;
            for roino=1:numToTrigOn
                scatter(roibds{roino}(:,2),roibds{roino}(:,1),[dots{roino} '.'])
            end
            hold off;
            fbuffer = [fbuffer(2:end,:); fcurrent];
            for roino=1:numToTrigOn
                subplot(1,1+numToTrigOn,1+roino)
                plot(fbuffer(:,roino),[dots{roino} '-'])
                hold on;
                plot(fcutoffhi(roino)*ones(size(fbuffer,1),1),'g')
                plot(fcutofflo(roino)*ones(size(fbuffer,1),1),'b')
                hold off;
            end
            
            %             mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
            
            drawnow limitrate;
            sincelasttrigger = sincelasttrigger+1;
        end
        sincelastresponse = 0;
    else
        % deliver a stim when the neuron has been silent awhile
        while sincelastresponse < silentframes || sincelasttrigger < deadframes
            %         while(mmfile.Data.header(1)<0) % wait for a new frame...
            %             if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            %                 dsesh.outputSingleScan([0])
            %                 return;
            %             end
            %         end
            awaitFrame;
            if rem(sincelasttrigger,updateevery)==0 %rem(updatectr,updateevery)==0
                fcutoffhi = prctile(fbuffer,100*threshhi);
                fcutofflo = prctile(fbuffer,100*threshlo);
            end
%             updatectr = updatectr+1;
            
            %         display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
            
            mchA = double(intmax('uint16')-mmfile.Data.chA);
            for roino=1:numToTrigOn
                fcurrent(roino) = sum(mchA(msk(:,:,roino)));
            end
            subplot(1,1+numToTrigOn,1)
            imagesc(mchA)
            hold on;
            for roino=1:numToTrigOn
                scatter(roibds{roino}(:,2),roibds{roino}(:,1),[dots{roino} '.'])
            end
            hold off;
            fbuffer = [fbuffer(2:end,:); fcurrent];
            for roino=1:numToTrigOn
                subplot(1,1+numToTrigOn,1+roino)
                plot(fbuffer(:,roino),[dots{roino} '-'])
                hold on;
                plot(fcutoffhi(roino)*ones(size(fbuffer,1),1),'g')
                plot(fcutofflo(roino)*ones(size(fbuffer,1),1),'b')
                hold off;
            end
            
            %         mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
            
            drawnow limitrate;
%             sincelasttrigger = sincelasttrigger+1;
            if all(fcurrent < fcutofflo)
                sincelastresponse = sincelastresponse+1;
            else
                sincelastresponse = 0;
            end
        end
    end
    disp(num2str(trigctr))
    performHandshake; %(dsesh,mmfile)
    sincelasttrigger = 0;
    trigctr = trigctr+1;
end

save(roifile,'msk')

over = false;
while ~over
    %     while(mmfile.Data.header(1)<0) % wait for a new frame...
    %         if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
    %             dsesh.outputSingleScan([0])
    %             return;
    %         end
    %     end
    over = awaitFrame;
end

clear mmfile; % close the memory mapped file
close all;     % close all figures
dsesh.release

    function performHandshake %dsesh,mmfile)
        dsesh.outputSingleScan([0])
        dsesh.outputSingleScan([1])
        handshk = false;
        twoinarow = false;
        while ~twoinarow %%% NEW MAYBE SAFER %~handshk ORIGINAL
            %             mmfile.Data.header(1) = -1;
            while(mmfile.Data.header(1)<0) % wait for a new frame...
                if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                    dsesh.outputSingleScan([0])
                    return;
                end
            end
            % handshk = mmfile.Data.header(4); ORIGINAL
            %%% NEW MAYBE SAFER
            if ~handshk
                handshk = mmfile.Data.header(4);
            else
                twoinarow = mmfile.Data.header(4);
                if ~twoinarow
                    handshk = false;
                end
            end
            %%% NEW MAYBE SAFER
            mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
        end
        dsesh.outputSingleScan([1])
        dsesh.outputSingleScan([0])
    end

    function over = awaitFrame
        over = false;
        %         mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
        while(mmfile.Data.header(1)<0) % wait for a new frame...
            if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
                dsesh.outputSingleScan([0])
                over = true;
                return;
            end
        end
        display(sprintf('Frame %06d',mmfile.Data.header(1)));
        mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
    end
% that fn. replaces this:
% SEND TTL PULSE
%     dsesh.outputSingleScan([0])
%     dsesh.outputSingleScan([1])
%     handshook = false;
%     while ~handshook
%         while(mmfile.Data.header(1)<0) % wait for a new frame...
%             if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
%                 dsesh.outputSingleScan([0])
%                 return;
%             end
%         end
%         handshook = mmfile.Data.header(4);
%         mmfile.Data.header(1) = -1;
%     end
%     dsesh.outputSingleScan([1])
%     dsesh.outputSingleScan([0])

end