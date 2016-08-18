%
% Basic command/response example using the MATLAB, .NET and the UD driver.
%
% support@labjack.com
%

clc %Clear the MATLAB command window
clear %Clear the MATLAB variables

ljasm = NET.addAssembly('LJUDDotNet'); %Make the UD .NET assembly visible in MATLAB
ljudObj = LabJack.LabJackUD.LJUD;

try
    %Read and display the UD version.
    disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

    %Open the first found LabJack U6.
    [ljerror, ljhandle] = ljudObj.OpenLabJack(LabJack.LabJackUD.DEVICE.U6, LabJack.LabJackUD.CONNECTION.USB, '0', true, 0);
    
    %First some configuration commands.  These will be done with the ePut
    %function which combines the add/go/get into a single call.
    
    %Configure the resolution of the analog inputs (pass a non-zero value for quick sampling).
    %See section 2.6 / 3.1 for more information.
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.AIN_RESOLUTION, 0, 0);
    
    %Configure the analog input range on channels 2 and 3 for bipolar 10v (LJ_rgBIP10V = 2).
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_AIN_RANGE, 2, 2, 0);
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_AIN_RANGE, 3, 2, 0);
    
    %Enable Counter0 which will appear on FIO0 (assuming no other
    %program has enabled any timers or Counter1).
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_COUNTER_ENABLE, 0, 1, 0);
    
    %Now we add requests to write and read I/O.  These requests
    %will be processed repeatedly by go/get statements in every
    %iteration of the while loop below.
    
    %Request AIN2 and AIN3.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, 2, 0, 0, 0);
    
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_AIN, 3, 0, 0, 0);
    
    %Set DAC0 to 2.5 volts.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_DAC, 0, 2.5, 0, 0);
    
    %Read digital input FIO1.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_DIGITAL_BIT, 1, 0, 0, 0);
    
    %Set digital output FIO2 to output-high.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.PUT_DIGITAL_BIT, 2, 1, 0, 0);
    
    %Read digital inputs FIO3 through FIO7.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_DIGITAL_PORT, 3, 0, 5, 0);
    
    %Request the value of Counter0.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.GET_COUNTER, 0, 0, 0, 0);
    
    requestedExit = false;
    while requestedExit == false
        %Execute the requests.
        ljudObj.GoOne(ljhandle);
        
        %Get all the results.  The input measurement results are stored.  All other
        %results are for configuration or output requests so we are just checking
        %whether there was an error.
        [ljerror, ioType, channel, dblValue, dummyInt, dummyDbl] = ljudObj.GetFirstResult(ljhandle, 0, 0, 0, 0, 0);
        
        finished = false;
        while finished == false
            switch ioType
                case int32(LabJack.LabJackUD.IO.GET_AIN)
                    switch int32(channel)
                        case 2
                            value2 = dblValue;
                        case 3
                            value3 = dblValue;
                    end
                case int32(LabJack.LabJackUD.IO.GET_DIGITAL_BIT)
                    valueDIBit = dblValue;
                case int32(LabJack.LabJackUD.IO.GET_DIGITAL_PORT)
                    valueDIPort = dblValue;
                case int32(LabJack.LabJackUD.IO.GET_COUNTER)
                    valueCounter = dblValue;
            end
            
            try
                [ljerror, ioType, channel, dblValue, dummyInt, dummyDbl] = ljudObj.GetNextResult(ljhandle, 0, 0, 0, 0, 0);
            catch e
                if(isa(e, 'NET.NetException'))
                    eNet = e.ExceptionObject;
                    if(isa(eNet, 'LabJack.LabJackUD.LabJackUDException'))
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
        disp(['AIN2 = ' num2str(value2)])
        disp(['AIN3 = ' num2str(value3)])
        disp(['FIO1 = ' num2str(valueDIBit)])
        disp(['FIO3-FIO7 = ' num2str(valueDIPort)]) %Will read 31 if all 5 lines are pulled-high as normal.
        disp(['Counter0 (FIO0) = ' num2str(valueCounter)])
        
        str = input('Press Enter to go again or (q) and then Enter to quit ','s');
        if(str == 'q')
            requestedExit = true;
        end
    end
catch e
    showErrorMessage(e)
end