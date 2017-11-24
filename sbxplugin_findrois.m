eta = input('forgetting rate: \n'); % rate at which the old rolling avg will exponentially decay

[FileName,PathName,FilterIndex] = uigetfile('*.rois');
load([PathName FileName],'-mat','ROIdata')
outlines = {ROIdata.rois(:).vertices};
outlines = cell2mat(outlines(:));

[FileName,PathName,FilterIndex] = uigetfile('*.mat');
load([PathName FileName],'img')
% scatter(outlines(:,1),outlines(:,2),'m.')
% hold on

% Calibration plug-in for Scanbox

% Open memory mapped file -- define just the header first

mmfile = memmapfile('scanbox.mmap','Writable',true, ...
    'Format', { 'int16' [1 16] 'header' } , 'Repeat', 1);
flag = 1;

% Process all incoming frames until Scanbox stops

while(true)
    
    while(mmfile.Data.header(1)<0) % wait for a new frame...
        if(mmfile.Data.header(1) == -2) % exit if Scanbox stopped
            return;
        end
    end
        
    if(flag) % first time? Format chA according to lines/columns in data
        mmfile.Format = {'int16' [1 16] 'header' ; ...
            'uint16' double([mmfile.Data.header(2) mmfile.Data.header(3)]) 'chA'};
        mchA = double(intmax('uint16')-mmfile.Data.chA);
        flag = 0;
    else
%         mchA = (1-eta)*mchA + eta*max(double(intmax('uint16')-mmfile.Data.chA),mchA);
        newframe = max(double(intmax('uint16')-mmfile.Data.chA),mchA);
%         mchA = (1-eta)*mchA + eta*double(intmax('uint16')-mmfile.Data.chA);
        mchA = (1-eta)*mchA + eta*newframe;
    end
    
    mmfile.Data.header(1) = -1; % signal Scanbox that frame has been consumed!
    
    subplot(1,2,1)
    imagesc(mchA)
    hold on
    scatter(outlines(:,1),outlines(:,2),'m.')
    hold off
    subplot(1,2,2)
%     I = imfuse(intmax('uint16')-mmfile.Data.chA,img);
    I = imfuse(mchA,img);
    imshow(I)
    drawnow limitrate
    
end
% hold off

clear(mmfile); % close the memory mapped file
close all;     % close all figures
