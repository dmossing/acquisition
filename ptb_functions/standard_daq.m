function d = standard_daq(n)
% set up DAQ
% up to 3 channels: first is stim trigger, second is complete stim protocol/move in z, third is projector LED on 

if ~exist('n','var') || isempty(n)
    n = 1;
end

d=daq.createSession('ni');
addDigitalChannel(d,'Dev3','port0/line0','OutputOnly'); % stim trigger
if n>1
    addDigitalChannel(d,'Dev3','port0/line2','OutputOnly'); % complete stim protocol, move in z
end
if n>2
    addDigitalChannel(d,'Dev3','port0/line1','OutputOnly'); % projector LED on
end
