disp('Andor SDK3 Live Mode Example');
[rc] = AT_InitialiseLibrary();
AT_CheckError(rc);
[rc,hndl] = AT_Open(0);
AT_CheckError(rc);
disp('Camera initialized');
[rc] = AT_SetFloat(hndl,'ExposureTime',0.05);
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'CycleMode','Continuous');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'TriggerMode','Software');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'SimplePreAmpGainControl','16-bit (low noise & high well capacity)');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'PixelEncoding','Mono16');
AT_CheckWarning(rc);
[rc,imagesize] = AT_GetInt(hndl,'ImageSizeBytes');
AT_CheckWarning(rc);
[rc,height] = AT_GetInt(hndl,'AOIHeight');
AT_CheckWarning(rc);
[rc,width] = AT_GetInt(hndl,'AOIWidth');
AT_CheckWarning(rc);
[rc,stride] = AT_GetInt(hndl,'AOIStride'); 
AT_CheckWarning(rc);
% warndlg('To Abort the acquisition close the image display twice.','Starting Acquisition')    
disp('Starting baseline acquisition...');
[rc] = AT_Command(hndl,'AcquisitionStart');
AT_CheckWarning(rc);
ct = 0;
avg = zeros(width,height);
buf2 = zeros(width,height);
figure(1)
h=imagesc(buf2);
while(ishandle(h))
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
    [rc] = AT_Command(hndl,'SoftwareTrigger');
    AT_CheckWarning(rc);
    [rc,buf] = AT_WaitBuffer(hndl,1000);
    AT_CheckWarning(rc);
    [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    AT_CheckWarning(rc);
    set(h,'CData',buf2);
    drawnow;
    avg = avg + double(buf2);
    ct = ct + 1;
end
avg = avg/ct;
avg_filt = imgaussfilt(avg,100);
disp('Starting dfof acquisition...');
h=imagesc(buf2,[0 1]);
ct = 0;
sofar = zeros(width,height);
while(ishandle(h))
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
    [rc] = AT_Command(hndl,'SoftwareTrigger');
    AT_CheckWarning(rc);
    [rc,buf] = AT_WaitBuffer(hndl,1000);
    AT_CheckWarning(rc);
    [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    AT_CheckWarning(rc);
    dfof = (double(buf2) - avg)./avg_filt;
    set(h,'CData',dfof);
    drawnow;
    ct = ct+1;
    sofar = sofar+dfof;
%     if ct > 200
%         avg = sofar/ct;
%         avg_filt = imgaussfilt(avg,100);
%         ct = 0;
%         sofar = zeros(width,height);
%     end
end

im1 = sofar;
figure(2)
imagesc(im1)

figure(1)
h=imagesc(buf2,[0 1]);
ct = 0;
sofar = zeros(width,height);
while(ishandle(h))
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
    [rc] = AT_Command(hndl,'SoftwareTrigger');
    AT_CheckWarning(rc);
    [rc,buf] = AT_WaitBuffer(hndl,1000);
    AT_CheckWarning(rc);
    [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    AT_CheckWarning(rc);
    dfof = (double(buf2) - avg)./avg_filt;
    set(h,'CData',dfof);
    drawnow;
    ct = ct+1;
    sofar = sofar+dfof;
%     if ct > 200
%         avg = sofar/ct;
%         avg_filt = imgaussfilt(avg,100);
%         ct = 0;
%         sofar = zeros(width,height);
%     end
end

im2 = sofar;
figure(3)
imagesc(im2)

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
