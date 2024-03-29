disp('Andor SDK3 Live Mode Example');
[rc] = AT_InitialiseLibrary();
AT_CheckError(rc);
[rc,hndl] = AT_Open(0);
AT_CheckError(rc);
disp('Camera initialized');
[rc] = AT_SetFloat(hndl,'ExposureTime',0.01);
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
% 
% height = 128;
% width = 128;
% rc = AT_SetInt(hndl,'AOIHeight',height);
% AT_CheckWarning(rc);
% rc = AT_SetInt(hndl,'AOIWidth',width);
% AT_CheckWarning(rc);
% rc = AT_SetBool(hndl,'VerticallyCentreAOI',1);
% AT_CheckWarning(rc);

[rc,height] = AT_GetInt(hndl,'AOIHeight');
AT_CheckWarning(rc);
[rc,width] = AT_GetInt(hndl,'AOIWidth');
AT_CheckWarning(rc);
[rc,stride] = AT_GetInt(hndl,'AOIStride'); 
AT_CheckWarning(rc);
% warndlg('To Abort the acquisition close the image display.','Starting Acquisition')    
disp('Starting acquisition...');
[rc] = AT_Command(hndl,'AcquisitionStart');
AT_CheckWarning(rc);
buf2 = zeros(width,height);
h2=figure(1);
figure(2)
acc = zeros(width,height);
h=imagesc(acc);
axis equal off
while(ishandle(h2))
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
    [rc] = AT_Command(hndl,'SoftwareTrigger');
    AT_CheckWarning(rc);
    [rc,buf] = AT_WaitBuffer(hndl,1000);
    AT_CheckWarning(rc);
    [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    AT_CheckWarning(rc);
    acc = acc+double(buf2);
    set(h,'CData',acc);
    drawnow;
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
