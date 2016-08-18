%
% Demonstrates talking to a EI-1050 probes using MATLAB, .NET and the UD
% driver.
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
    
    %Open the first found LabJack UE9.
    [ljerror, ljhandle] = ljudObj.OpenLabJack(LabJack.LabJackUD.DEVICE.UE9, LabJack.LabJackUD.CONNECTION.USB, '0', true, 0);
    
    %Set the Data line to FIO0
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.SHT_DATA_CHANNEL, 0, 0);
    
    %Set the Clock line to FIO1
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_CONFIG, LabJack.LabJackUD.CHANNEL.SHT_CLOCK_CHANNEL, 1, 0);
    
    %Set FIO2 to output-high to provide power to the EI-1050.
    ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PUT_DIGITAL_BIT, 2, 1, 0);
    
    %Connections for probe:
    %	Red (Power)         FIO2
    %	Black (Ground)      GND
    %	Green (Data)        FIO0
    %	White (Clock)       FIO1
    %	Brown (Enable)      FIO2
    
    %Now, an add/go/get block to get the temp & humidity at the same time.
    %Request a temperature reading from the EI-1050.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.SHT_GET_READING, LabJack.LabJackUD.CHANNEL.SHT_TEMP, 0, 0, 0);
    
    %Request a humidity reading from the EI-1050.
    ljudObj.AddRequest(ljhandle, LabJack.LabJackUD.IO.SHT_GET_READING, LabJack.LabJackUD.CHANNEL.SHT_RH, 0, 0, 0);
    
    %Execute the requests.  Will take about 0.5 seconds with a USB high-high
    %or Ethernet connection, and about 1.5 seconds with a normal USB connection.
    ljudObj.GoOne(ljhandle);
    
    %Get the temperature reading.
    [ljerror, dblValue] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.SHT_GET_READING, LabJack.LabJackUD.CHANNEL.SHT_TEMP, 0);
    disp(['Temp Probe A = ' num2str(dblValue) ' deg K']);
    disp(['Temp Probe A = ' num2str((dblValue-273.15)) ' deg C']);
    disp(['Temp Probe A = ' num2str((((dblValue-273.15)*1.8)+32)) ' deg F']);
    
    %Get the humidity reading.
    [ljuderror, dblValue] = ljudObj.GetResult(ljhandle, LabJack.LabJackUD.IO.SHT_GET_READING, LabJack.LabJackUD.CHANNEL.SHT_RH, 0);
    disp(['RH Probe A = ' num2str(dblValue) ' percent']);
catch e
    showErrorMessage(e)
end