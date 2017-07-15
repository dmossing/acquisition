function h=moveLinearMotor(absolute_pos_in_mm,h)

zaber_resolution = 0.1905; % microns per step

if ~exist('absolute_pos_in_mm','var')
    absolute_pos_in_mm = 0;
elseif isempty(absolute_pos_in_mm)
    return
end

if ~exist('h','var')
    h=serial('com3','BaudRate',9600); % create com port handle
    try
        fopen(h); % open com port
    catch % port already open in other program
        ports=instrfind;
        fclose(ports); % close all open ports
        fopen(h); % open com port
    end
end


absolute_pos_in_microsteps = absolute_pos_in_mm*(1/zaber_resolution)*1000; % convert position to # of steps
[d3 d4 d5 d6] = entryToBits(absolute_pos_in_microsteps); % convert position to digital output
goto = [1 20 d3 d4 d5 d6]; % format output

fwrite(h,goto); % write to motor
% fclose(h); % close com port