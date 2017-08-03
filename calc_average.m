% Simply rolling average plug-in for Scanbox
 
% Open memory mapped file -- define just the header first
 
mmfile = memmapfile('scanbox.mmap','Writable',true, ...
    'Format', { 'int16' [1 16] 'header' } , 'Repeat', 1);
flag = 1;
 
% Define the forgetting factor  0 < delta <= 1
 
delta = 0.9;  % this will generate an exponential decaying memory window: lambda^n
 
% Process all incoming frames until Scanbox stops
 
while(true)
    
    while(mmfile.Data.header(1)<0) % wait for a new frame...
        if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            return;
        end
    end
     
    display(sprintf('Frame %06d',mmfile.Data.header(1))); % print frame# being processed
     
    if(flag) % first time? Format chA according to lines/columns in data
        mmfile.Format = {'int16' [1 16] 'header' ; ...
            'uint16' double([mmfile.Data.header(2) mmfile.Data.header(3)]) 'chA'};
        N = 1;
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        flag = 0;
        ih = imagesc(mchA); % setup display
        axis off;           % remove axis
        colormap gray;      % use gray colormap
        truesize            % true image size
    else
        N = N+1;
        mchA = mchA*(N-1)/N + double(intmax('uint16')-mmfile.Data.chA)*1/N;
        ih.CData = mchA;
    end
     
    mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
     
    drawnow limitrate;
     
end
 
clear(mmfile); % close the memory mapped file
close all;     % close all figures