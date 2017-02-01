function ROIdata = sparsifyROIdata(ROIdata, varargin)

saveOut = false;
saveFile = '';

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Save', 'save'}
                saveOut = true;
                index = index + 1;
            case {'SaveFile', 'saveFile'}
                saveFile = varargin{index+1};
                index = index + 2;
            otherwise
                warning('Argument ''%s'' not recognized',varargin{index});
                index = index + 1;
        end
    catch
        warning('Argument %d not recognized',index);
        index = index + 1;
    end
end

%% Load in data
if ischar(ROIdata)
    ROIFile = ROIdata;
    load(ROIFile, 'ROIdata', '-mat');
    if saveOut && isempty(saveFile)
        saveFile = ROIFile;
    end
end

%% Sparsify data
for rindex = 1:numel(ROIdata.rois)
    ROIdata.rois(rindex).pixels = logical(sparse(ROIdata.rois(rindex).pixels));
    ROIdata.rois(rindex).mask = logical(sparse(ROIdata.rois(rindex).mask));
    ROIdata.rois(rindex).neuropilmask = logical(sparse(ROIdata.rois(rindex).neuropilmask));
end

%% Save output
if saveOut && ~isempty(saveFile)
    if ~exist(saveFile, 'file')
        save(saveFile, 'ROIdata', '-mat', '-v7.3');
    else
        save(saveFile, 'ROIdata', '-mat', '-append');
    end
    fprintf('ROIdata saved to file: %s\n', saveFile);
end