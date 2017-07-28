% Open memory mapped file -- define just the header first

mmfile = memmapfile('scanbox.mmap','Writable',true, ...
    'Format', { 'int16' [1 16] 'header' } , 'Repeat', 1);
flag = 1;

% Simply rolling average plug-in for Scanbox

% Process all incoming frames until Scanbox stops

% msocket connection to visual stim PC
server = '128.32.173.6';
disp('waiting on TTL')

trig_ctr = 0;
old_trig = 0;

moveon = false;

while(true)
    
    while(mmfile.Data.header(1)<0) % wait for a new frame...
        if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            return;
        end
    end
    if ~moveon
        moveon = mmfile.Data.header(4);
        if moveon
            disp('received TTL')
            sock = msconnect(server,3000);
            locinds = msrecv(sock);
            ns = max(locinds);
            ny = ns(1); nx = ns(2);
            N = zeros(ny,nx);
            disp('received locinds')
            avg_by_loc = cell(ny,nx);
            for i=1:ny
                for j=1:nx
                    avg_by_loc{i,j} = zeros(size(mchA));
                    subplot(ny,nx,(i-1)*nx+j)
                    ih(i,j) = imagesc(avg_by_loc{i,j}); % setup display
                    axis off;           % remove axis
                    colormap gray;      % use gray colormap
                    truesize            % true image size
                end
            end
        end
    else
        new_trig = mmfile.Data.header(4);
        if new_trig && ~old_trig
            trig_ctr = trig_ctr+1;
            ii = locinds(trig_ctr,1);
            jj = locinds(trig_ctr,2);
        end
        old_trig = new_trig;
    end
    
    display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
    
    if(flag) % first time? Format chA according to lines/columns in data
        mmfile.Format = {'int16' [1 16] 'header' ; ...
            'uint16' double([mmfile.Data.header(2) mmfile.Data.header(3)]) 'chA'};
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        flag = 0;
    elseif moveon
        N(ii,jj) = N(ii,jj)+1;
        avg_by_loc{ii,jj} = avg_by_loc{ii,jj}*(N(ii,jj)-1)/N(ii,jj) + double(intmax('uint16')-mmfile.Data.chA)*1/N(ii,jj);
        ih(ii,jj).CData = avg_by_loc{ii,jj};
    end
    
    mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
    
    drawnow limitrate;
    
end

clear(mmfile); % close the memory mapped file
close all;     % close all figures