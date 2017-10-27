function [x,y] = spiral_scan_dpm(radAmp,radFreq,azFreq,samplingRate)
% first number in volts; last three numbers in Hz or kHz as desired.
% returns one cycle of spiral scanning
dt = 1/samplingRate;
T = 1/radFreq;
t = 0:dt:T-dt;
envelope = radAmp*(1-t/T);
x = envelope.*cos(2*pi*azFreq*t);
y = envelope.*sin(2*pi*azFreq*t);