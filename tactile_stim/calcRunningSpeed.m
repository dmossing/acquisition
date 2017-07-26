function [RunningSpeed,dsamp_Fs] = calcRunningSpeed(distance, Fs, downsamplefactor, Date)

% if datenum(Date,'mm/dd/yy') > datenum('10/21/2014','mm/dd/yy')
    PulsesPerRotation = 360;
% else
%     PulsesPerRotation = 1000; % 1000 pulses per 360 degrees for my rotary encoder
% end
directory = 'C:\Data\Evan';

if ~exist('distance', 'var') || isempty(distance)
    [f,p] = uigetfile({'*.bin'},'Select Running Speed file',directory);
    distance = fullfile(p,f);
end
if ischar(distance)
    file = fopen(distance,'r');
    distance = fread(file,Inf,'uint8');
end
if max(distance) == 1 || max(distance) == 0
    distance = cumsum([distance(1);distance]);
end

if ~exist('Fs', 'var') || isempty(Fs)
    Fs = 30000;
end
if ~exist('downsamplefactor','var')
    downsamplefactor = 10; % downsample factor to speed up calculation
end
    
% Initialize Convolution Kernel
dsamp_Fs = round(Fs/downsamplefactor);
smooth_win = gausswin(dsamp_Fs,23.5/2);
smooth_win = smooth_win/sum(smooth_win);
sw_len = length(smooth_win);
d_smooth_win = [0;diff(smooth_win)]/(1/dsamp_Fs);


% Perform convolution
x_t = downsample(distance, downsamplefactor); %downsample data to speed up computation
x_t = padarray(x_t,sw_len,'replicate');
dx_dt = conv(x_t,d_smooth_win,'same');
dx_dt([1:sw_len,end-sw_len+1:end]) = []; %remove values produced by convolving kernel with padded values

RunningSpeed = dx_dt*360/PulsesPerRotation; % convert to degrees