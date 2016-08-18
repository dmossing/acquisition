function lights_off()
DAQ = daq.createSession('ni');
addDigitalChannel(DAQ,'Dev1','port0/line2','OutputOnly');
addDigitalChannel(DAQ,'Dev1','port1/line1','OutputOnly');
outputSingleScan(DAQ,[0 0]);
end