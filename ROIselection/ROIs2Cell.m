function CellData = ROIs2Cell(ROIs, varargin)

ROIindex = [];

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case 'ROIindex'
                ROIindex = varargin{index+1};
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

if ~exist('ROIs', 'var') || isempty(ROIs)
elseif ischar(ROIs)
    ROIs = {ROIs};
end
numDataSets = numel(ROIs)/2;

if isnumeric(ROIindex)
    ROIindex = {ROIindex};
end


%% Load data
if iscellstr(ROIs)
    ROIFiles = ROIs;
    for findex = 1:numel(ROIs)
        load(ROIFiles{findex}, 'ROIdata', '-mat');
        ROIs{findex} = ROIdata;
    end
end
numStim = numel(ROIs{1}.rois(1).curve)-1;


%% Determine ROIs to pull out
if isempty(ROIindex)
    ROIindex = cell(1,numDataSets);
    for findex = 1:numDataSets
        ROIindex{findex} = 1:numel(ROIs{2*findex-1}.rois);
    end
end
numROIs = cellfun(@numel, ROIindex);


%% Convert to cell array

% a = gatherROIdata(ROIs, 'Raw', ':', 'none', ROIindex(:), FileIndex(:));

CellData = cell(sum(numROIs), numStim*2);
roiindex = 1;
for findex = 1:numDataSets
    for rindex = 1:numROIs(findex)
        CellData(roiindex, 1:numStim) = ROIs{findex}.rois(ROIindex{findex}(rindex)).Raw(2:end);
        CellData(roiindex, numStim+1:end) = ROIs{2*findex}.rois(ROIindex{findex}(rindex)).Raw(2:end);
        roiindex = roiindex + 1;
    end
end
