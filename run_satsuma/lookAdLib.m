function lookAdLib(varargin)

p = inputParser;
p.addParameter('depths',[0 30 60]);

result = p.Results;

set_default_si_settings;

hSI = evalin('base','hSI');
assert(strcmpi(hSI.acqState,'idle'));

hSI.userZs = result.depths;

hSI.extTrigEnable = 0;
hSI.hChannels.loggingEnable = 0;
hSI.hFastZ.numVolumes = 10000;
hSI.startGrab();