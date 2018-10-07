function runLoopedAcquisition(varargin)

p = inputParser;
p.addParameter('animalid','Mfake');
p.addParameter('baseDepth','000');
p.addParameter('depths',[0 30 60]);
p.addParameter('numFrames',10000);

result = p.Results;

dstr = yyyymmdd(datetime('now'));
hSI.hScan2D.logFilePath = ['E:/Dan/' dstr(3:end) '/' result.animalid '/']

hSI.hScan2D.logFileStem = [result.baseDepth];

set_default_si_settings;

hSI = evalin('base','hSI');
assert(strcmpi(hSI.acqState,'idle'));

hSI.userZs = result.depths;

hSI.extTrigEnable = 1;
hSI.hChannels.loggingEnable = 1;
hSI.hFastZ.numVolumes = result.numFrames;
hSI.startLoop();