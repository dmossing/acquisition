function getSignals(fname)
i = 1;
fns{i} = fname;
ROIFile = [fns{i}, '.rois'];
ROIdata = sbxDistribute(fns{i}, 'Save', 'SaveFile', ROIFile); % intialize struct
createMasks(ROIdata, 'Save', 'SaveFile', ROIFile); % create ROI masks
if ~strfind(fns{i},'depth')
    config = load2PConfig([fns{i}, '.sbx']);
    [~, Data, Neuropil, ~] = extractSignals([fns{i},'.sbx'], ROIFile, 'all', 'Save', 'SaveFile', ROIFile, 'MotionCorrect', [fns{i},'.align'], 'Frames', 1:config.Frames-1);
else
    strbase = strsplit(fns{i},'_depth');
    strbase = strbase{1};
    config = load2PConfig([strbase, '.sbx']);
    [~, Data, Neuropil, ~] = extractSignals([strbase,'.sbx'], ROIFile, 'all', 'Save', 'SaveFile', ROIFile, 'MotionCorrect', [fns{i},'.align'], 'Frames', 1:config.Frames-1,'Depth',i);
end
save(ROIFile, 'Data', 'Neuropil', '-mat', '-append');