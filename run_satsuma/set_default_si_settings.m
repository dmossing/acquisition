function set_default_si_settings
hSI = evalin('base','hSI');
assert(strcmpi(hSI.acqState,'idle'));
hSI.hRoiManager.scanZoomFactor = 1.5; % define the zoom factor
hSI.hFastZ.actuatorLag = 0.02; % sec
hSI.hFastZ.flybackTime = 0.02;
hSI.hFastZ.enable = 1;
hSI.hFastZ.waveformType = 'step';
hSI.hFastZ.useArbitraryZs = 1;
hSI.hFastZ.userZs = 0;
hSI.hScan2D.keepResonantScannerOn = 1;