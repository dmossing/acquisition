disp('Andor SDK3 Kinetic Series Example');
[rc] = AT_InitialiseLibrary();
AT_CheckError(rc);
[rc,hndl] = AT_Open(0);
AT_CheckError(rc);
disp('Camera initialized');
[rc] = AT_SetFloat(hndl,'ExposureTime',0.022);
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'CycleMode','Fixed');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'TriggerMode','Internal');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'SimplePreAmpGainControl','12-bit (low noise)');
AT_CheckWarning(rc);
[rc] = AT_SetEnumString(hndl,'PixelEncoding','Mono12');
AT_CheckWarning(rc);


prompt = {'Enter Acquisition name','Enter number of images'};
dlg_title = 'Configure acquisition';
num_lines = 1;
def = {'acquisition','10'};
answer = inputdlg(prompt,dlg_title,num_lines,def);

tic
filename = cell2mat(answer(1));
frameCount = str2double(cell2mat(answer(2)));

[rc] = AT_SetInt(hndl,'FrameCount',frameCount);
AT_CheckWarning(rc);

[rc,imagesize] = AT_GetInt(hndl,'ImageSizeBytes');
AT_CheckWarning(rc);
[rc,height] = AT_GetInt(hndl,'AOIHeight');
AT_CheckWarning(rc);
[rc,width] = AT_GetInt(hndl,'AOIWidth');  
AT_CheckWarning(rc);
[rc,stride] = AT_GetInt(hndl,'AOIStride'); 
AT_CheckWarning(rc);
[rc] = AT_Flush(hndl);
AT_CheckWarning(rc);
for X = 1:10
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
end
disp('Starting acquisition...');
[rc] = AT_Command(hndl,'AcquisitionStart');
AT_CheckWarning(rc);

i=0;
thisFid = fopen('E:\Dan\LF2P\F160817A_000_000.dat','w')
while(i<frameCount)
    [rc,buf] = AT_WaitBuffer(hndl,1000);
    AT_CheckWarning(rc);
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
%     [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
%     AT_CheckWarning(rc);
    
%     thisFilename = strcat(filename, num2str(i+1), '.tiff');
    disp(['Writing Image ', num2str(i+1), '/',num2str(frameCount),' to disk']);
%     imwrite(buf2,thisFilename) %saves to current directory
    fwrite(thisFid,buf);
    

    i = i+1;
    toc
    tic
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
fclose(thisFid)
toc