[lj_obj,lj_h] = labjack_open();
cleanup_obj_lj = onCleanup(@() labjack_close(lj_obj,lj_h));
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
moveon = false;
old_stimct = 0;
while(~moveon)
    stimct = labjack_get_ctr(lj_obj,lj_h);
    if stimct > old_stimct
        old_stimct = stimct;
        moveon = true;
    end
end
% warndlg('To Abort the acquisition close the image display twice.','Starting Acquisition')
disp('Starting baseline acquisition...');
[rc] = AT_Command(hndl,'AcquisitionStart');
AT_CheckWarning(rc);
ct = 0;
avg = zeros(width,height);
buf2 = zeros(width,height);
figure(1)
h=imagesc(buf2);
moveon = false;
while(~moveon)
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
    stimct = labjack_get_ctr(lj_obj,lj_h);
    if stimct > old_stimct
        old_stimct = stimct;
        moveon = true;
    end
end
avg = avg/ct;
avg_filt = imgaussfilt(avg,100);
disp('Starting dfof acquisition...');
h=imagesc(buf2,[0 1]);
sofar = zeros(width,height);
moveon = false;
ct = 0;
while(~moveon)
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
    sofar = sofar+dfof;
    stimct = labjack_get_ctr(lj_obj,lj_h);
    if stimct >= old_stimct+1 && stimct < old_stimct+5
        old_stimct = stimct;
        ct = ct+1;
        im{ct} = sofar;
        sofar = zeros(width,height);
        figure(ct+1)
        imagesc(im{ct})
        figure(1)
    elseif stimct >= old_stimct+5
        old_stimct = stimct;
        moveon = true;
    end
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
