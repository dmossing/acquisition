function [ljudObj, ljhandle] = labjack_open()
ljasm = NET.addAssembly('LJUDDotNet'); %Make the UD .NET assembly visible in MATLAB
ljudObj = LabJack.LabJackUD.LJUD;

try
    %Read and display the UD version.
    disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])
    
    %Open the first found LabJack U3.
    [ljerror, ljhandle] = ljudObj.OpenLabJack(LabJack.LabJackUD.DEVICE.U3, LabJack.LabJackUD.CONNECTION.USB, '0', true, 0);
    
    %Start by using the pin_configuration_reset IOType so that all
    %pin assignments are in the factory default condition.
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PIN_CONFIGURATION_RESET, 0, 0, 0);
    
    %First requests to configure the timer and counter.  These will be
    %done with and add/go/get block.
    
    %Set the timer/counter pin offset to 4, which will put the first
    %timer/counter on FIO4.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.TIMER_COUNTER_PIN_OFFSET, 4, 0, 0);
    
    %Enable Counter1.  It will use FIO4.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_COUNTER_ENABLE, 1, 1, 0, 0);
    
    %Execute the requests.
    ljudObj.GoOne(ljhandle);
    
    %Get all the results just to check for errors.
    [ljerror, ioType, channel, dblValue, dummyInt, dummyDbl] = ljudObj.GetFirstResult(ljhandle, 0, 0, 0, 0, 0);
    
    finished = false;
    while finished == false
        try
            [ljerror, ioType, channel, dblValue, dummyInt, dummyDbl] = ljudObj.GetNextResult(ljhandle, 0, 0, 0, 0, 0);
        catch e
            if(isa(e, 'NET.NetException'))
                eNet = e.ExceptionObject;
                if(isa(eNet, 'LabJack.LabJackUD.LabJackUDException'))
                    %If we get an error, report it.  If the error is NO_MORE_DATA_AVAILABLE we are done
                    if(eNet.LJUDError == LabJack.LabJackUD.LJUDERROR.NO_MORE_DATA_AVAILABLE)
                        finished = true;
                    end
                end
            end
            %Report non NO_MORE_DATA_AVAILABLE error.
            if(finished == false)
                throw(e)
            end
        end
    end
catch e
    showErrorMessage(e)
end