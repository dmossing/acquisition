function ROIdata = sbxDistribute(fname, varargin)

saveOut = false;
saveFile = '';

%% Parse input arguments
if ~exist('fname', 'var') || isempty(fname)
    [fname,p] = uigetfile({'*.segment'},'Select segment file:',directory);
    if isnumeric(fname)
        return
    end
    fname = fullfile(p, fname);
    fname = fname(1:end-8);
end

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


%% Create MCdata variable
vars = whos(matfile([fname,'.align']));
if ~any(strcmp({vars(:).name}, 'MCdata'))
    load([fname, '.align'], 'T', '-mat');
    MCdata.T = T;
    MCdata.type = 'Translation';
    MCdata.date = datestr(now);
    MCdata.FullFilename = [fname, '.sbx'];
    MCdata.Channel2AlignFrom = 1;
    MCdata.Parameters = [];
    save([fname, '.align'], 'MCdata', '-append', '-mat');
end


%% Create ROIdata
ROIdata = createROIdata([fname,'.segment'], 'ImageFile', {[fname,'.sbx']});


%% Distribute ROI signals
if exist([fname, '.signals'], 'file')
    load([fname, '.signals'], 'sig', 'pil', '-mat');
    for rindex = 1:numel(ROIdata.rois)
        ROIdata.rois(rindex).rawdata = sig(:,rindex)';
        ROIdata.rois(rindex).rawneuropil = pil(:,rindex)';
    end
end


%% Save ROIdata to file
if saveOut
    if ~exist(saveFile, 'file')
        save(saveFile, 'ROIdata', '-mat', '-v7.3');
    else
        save(saveFile, 'ROIdata', '-mat', '-append');
    end
end