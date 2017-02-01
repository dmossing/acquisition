function ROIdata = createROIdata(ROIMasks, varargin)

saveOut = false;
saveFile = '';

ImageFile = {''};
ROIdata = [];

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'ImageFile'
                ImageFile = varargin{index+1};
                index = index + 2;
            case 'ROIdata'
                ROIdata = varargin{index+1};
                index = index + 2;
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

if ~exist('ROIMasks', 'var') || isempty(ROIMasks)
    [ROIMasks,p] = uigetfile({'*.segment;*.mat'}, 'Select file with ''mask'' variable:', directory);
    if isnumeric(ROIMasks)
        return
    end
    ROIMasks = fullfile(p, ROIMasks);
end


%% Load masks
if ischar(ROIMasks)
    ROIFile = ROIMasks;
    load(ROIFile, 'mask', 'dim', '-mat');
    if issparse(mask)
        ROIMasks = reshape(full(mask), dim(1), dim(2), size(mask,2));
    else
        Nunique = numel(setdiff(unique(mask),0));
        if size(mask,3)==1 && Nunique > 1
            ROIMasks = zeros(size(mask,1),size(mask,2),Nunique);
            for i=1:Nunique
                ROIMasks(:,:,i) = mask == i;
            end
        else
            ROIMasks = mask;
        end
    end
else
    ROIFile = '';
end
numROIs = size(ROIMasks, 3);


%% Initialize ROIdata structure
if ischar(ROIdata)
    load(ROIdata, 'ROIdata', '-mat');
    if ~exist('ROIdata', 'var')
        ROIdata = [];
    end
end
if isempty(ROIdata)
    ROIdata.filename = ROIFile;
    ROIdata.offset = zeros(1,3);
    ROIdata.imagefiles = ImageFile;
    ROIdata.files = ImageFile;
    offset = 0;
else
    offset = numel(ROIdata.rois);
end


%% Distribute ROIs
for rindex = 1:numROIs
    
    % Identifier & display information
    ROIdata.rois(offset+rindex).label = {};
    ROIdata.rois(offset+rindex).tag = num2str(offset+rindex);
    ROIdata.rois(offset+rindex).color = [];
    ROIdata.rois(offset+rindex).depth = nan;
    ROIdata.rois(offset+rindex).frame = nan;
    
    % ROI information
    ROIdata.rois(offset+rindex).type = 'polygon';
    
    % ROI location
    temp = bwboundaries(ROIMasks(:,:,rindex));
    ROIdata.rois(offset+rindex).vertices = flip(temp{1},2);
    ROIdata.rois(offset+rindex).position = [];
    ROIdata.rois(offset+rindex).mask = [];
    ROIdata.rois(offset+rindex).neuropilmask = [];
    ROIdata.rois(offset+rindex).pixels = sparse(ROIMasks(:,:,rindex));
    temp = regionprops(ROIMasks(:,:,rindex), 'Centroid');
    ROIdata.rois(offset+rindex).centroid = temp.Centroid;
    
end


%% Save output
if saveOut
    if ~exist(saveFile, 'file')
        save(saveFile, 'ROIdata', '-mat', '-v7.3');
    else
        save(saveFile, 'ROIdata', '-mat', '-append');
    end
end