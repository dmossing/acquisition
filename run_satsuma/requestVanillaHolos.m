function requestVanillaHolos(varargin)

p = inputParser;
p.addParameter('animalid','Mfake');
p.addParameter('baseDepth','000');
p.addParameter('maxSourcesPerPlane',50);
p.addParameter('depths',[0 30 60]);
p.addParameter('d',[]);
p.addParameter('sockSI2Ephys',[]);

result = p.Results;

if isempty(result.d)
    d = daq.createSession('ni')
else
    d = result.d;
end
if isempty(result.sockSI2Ephys)
    [sockSI2Ephys,sockEphys2SI] = establishMSocketSI(d);
else
    sockSI2Ephys = result.sockSI2Ephys;
end

set_default_si_settings;

assert(strcmpi(hSI.acqState,'idle'));
hSI = evalin('base','hSI');

hSI.userZs = result.depths;

dstr = yyyymmdd(datetime('now'));
hSI.hScan2D.logFilePath = ['E:/Dan/' dstr(3:end) '/' result.animalid '/']

hSI.hScan2D.logFileStem = ['holoRequestImg_' result.baseDepth];

inp = input('Ensure wavelength is set to 1020 nm and hit "enter"');

hSI.extTrigEnable = 0;
hSI.hChannels.loggingEnable = 1;
hSI.hFastZ.numVolumes = 100;
hSI.startGrab();

inp = input('When happy, hit "enter"');

ctr = sprintf('%05d',hSI.hScan2D.logFileCounter-1); % -1 to look at most recently saved file

filename = [hSI.hScan2D.logFilePath hSI.hScan2D.logFileStem '_' ctr '.tif'];

img = ScanImageTiffReader(filename).data();

data = mean(img,4); % not sure what the index should be on this one.

% need to convert 'img' to cell array of length nplanes = 3

% define options
Opts.maxSourcesPerPlane = 50;
Opts.channel = 'red';

if strcmp(Opts.channel,'red');
    channel = 1;
elseif strcmp(Opts.channel,'green');
    channel = 2;
else
    disp('Error - select red or green');
end

for n = 1:numel(img);
imgData(:,:,n) = single(img{n}(:,:,channel));
end
Zplanes = hSI.hFastZ.userZs;
%% 
[sources]=extractROIsTest(imgData,Opts);
imagingScanfield = hSI.hRoiManager.currentRoiGroup.rois(1).scanfields(1);
i=0;
for n = 1:numel(sources);
    theSources=sources{n};
    for k = 1:size(theSources,3);
        mask = theSources(:,:,k);
        intsf = scanimage.mroi.scanfield.fields.IntegrationField.createFromMask(imagingScanfield,mask);
        intsf.threshold = 100;
        introi = scanimage.mroi.Roi();
        introi.discretePlaneMode=1;
        introi.add(Zplanes(n), intsf);
        introi.name = ['ROI ' num2str(i+1) ];%' Depth ' num2str(zDepth(n))];
        hSI.hIntegrationRoiManager.roiGroup.add(introi);
        i=i+1;
    end
end
disp(['Added ' num2str(i) ' sources to integration']);

%%
holoRequest = function_CloseLoop_SeedTargets(i, -12, 0); % holoRequest is saved here
selectAllROIs;

%%
sendMSocket(holoRequest,sockSI2Ephys,d)