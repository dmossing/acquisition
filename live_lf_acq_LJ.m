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
[rc] = AT_SetEnumString(hndl,'TriggerMode','Internal');
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
warndlg('To Abort the acquisition close the image display.','Starting Acquisition')
disp('Starting acquisition...');
[rc] = AT_Command(hndl,'AcquisitionStart');
AT_CheckWarning(rc);
buf2 = zeros(width,height);
h=imagesc(buf2);
count = 0;
i = 0;
showevery = 100;
fid_stim = fopen('E:\LF2P\Dan\170113\5742\stims.txt','w');
tic
old_stimct = 0;
while(ishandle(h))
    [rc] = AT_QueueBuffer(hndl,imagesize);
    AT_CheckWarning(rc);
    %     [rc] = AT_Command(hndl,'SoftwareTrigger');
    %     AT_CheckWarning(rc);
    [rc,buf] = AT_WaitBuffer(hndl,1000);
    AT_CheckWarning(rc);
    [rc,buf2] = AT_ConvertMono16ToMatrix(buf,height,width,stride);
    AT_CheckWarning(rc);
    dataWriter(['E:\LF2P\Dan\170113\5742\' ddigit(i,4) '.dat'],buf2(:));%taking uint16 inputs
    toc
    tic
    if count < showevery
        count = count+1;
        i = i+1;
    else
        count = 0;
        i = i+1;
        set(h,'CData',buf2);
        drawnow;
    end
    stimct = labjack_get_ctr(lj_obj,lj_h);
    if stimct > old_stimct
        fprintf(fid_stim,'%d\n',i);
        old_stimct = stimct;
    end
end
toc
disp('Acquisition complete');
[rc] = AT_Command(hndl,'AcquisitionStop');
AT_CheckWarning(rc);
[rc] = AT_Flush(hndl);
AT_CheckWarning(rc);
[rc] = AT_Close(hndl);
AT_CheckWarning(rc);
[rc] = AT_FinaliseLibrary();
AT_CheckWarning(rc);
disp('Camera shutdown')
labjack_close(lj_obj,lj_h);
fclose(fid_stim);

% %% local UDP functions
% 
% function H_Stim = udp_open()
% stim_port = 29000;
% H_Stim = udp('128.32.173.24', 'RemotePort', stim_port, ...
%     'LocalPort', stim_port,'BytesAvailableFcn',@process_stim_input);
% fopen(H_Stim);
% end
% 
% function udp_close(H_Stim)
% fclose(H_Stim);
% delete(H_Stim);
% end
% 
% function [started,done] = process_stim_input(a) %,DAQ)
% msg = fgetl(a);
% switch msg(1)
%     case 'G'
%         args = strsplit(msg(2:end),';');
%         foldname_lf = format_fold(args{1});
%         if(~exist(foldname_lf,'dir'))
%             mkdir(foldname_lf);
%         end
%         filename_lf = [foldname_lf args{2}];
%         disp(filename_lf)
%         record_for = floor(1.1*str2num(args{3}))+30;
%         stimmax = str2num(args{4});
%         started = 1;
%         done = 0;
%     case 'S'
%         udp_close(H_Stim);
%         labjack_close(lj_obj,lj_h);
%         disp('finished')
%         started = 1;
%         done = 1;
% end
% end