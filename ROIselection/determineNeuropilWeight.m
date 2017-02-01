function [NeuropilWeight, ROIdata] = determineNeuropilWeight(ROIdata, ROIindex, varargin)

type = 'individual'; % 'same' or 'individual'
maxWeight = .65;
outlierWeight = 8; % # of std dev's
FrameIndex = [2 inf];
directory = cd;

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'Type','type'}
                type = varargin{index+1};
                index = index + 2;
            case {'Max','max'}
                maxWeight = varargin{index+1};
                index = index + 2;
            case 'FrameIndex'
                FrameIndex = varargin{index+1};
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

if ~exist('ROIdata','var') || isempty(ROIdata)
    [ROIdata, p] = uigetfile({'*.rois;*.mat'},'Choose ROI file',directory);
    if isnumeric(ROIdata)
        return
    end
    ROIdata = fullfile(p,ROIdata);
end

if ~exist('ROIindex', 'var') || isempty(ROIindex)
    ROIindex = [1 inf];
end

if maxWeight > 1    % Neuropil can never contaminate more than the Neuropil's value (assuming Neuropil measurement is accurate)
    maxWeight = 1;  % a weight lower than 1 assumes some contamination is blocked out
end


%% Load ROIs
if ischar(ROIdata)
    ROIFile = ROIdata;
    load(ROIFile, 'ROIdata', '-mat');
end
totalFrames = numel(ROIdata.rois(1).rawdata);

% Determine ROIs to compute weights for
if ROIindex(end) == inf
    ROIindex = [ROIindex(1:end-1), ROIindex(1:end-1)+1:numel(ROIdata.rois)];
end
numROIs = numel(ROIindex);

% Determine frames to pull from
if FrameIndex(end) == inf
    FrameIndex = [FrameIndex(1:end-1), FrameIndex(1:end-1)+1:totalFrames];
end


%% Calculate minimal Neuropil Weight

% Compute ratio of fluorescence to neuropil
Data = reshape([ROIdata.rois(ROIindex).rawdata], totalFrames, numROIs)./reshape([ROIdata.rois(ROIindex).rawneuropil], totalFrames, numROIs);

% Keep only requested frames
Data = Data(FrameIndex, :);

% Remove outliers
Data(bsxfun(@ge, abs(bsxfun(@minus, Data, nanmean(Data))), outlierWeight * nanstd(Data))) = NaN;


%% Calculate individual weights
% Assumes when ratio of Neuropil to Data is largest that all of Data's
% signal is a result of Neuropil contamination; this ensures no ROI's
% fluorescence goes below 0 as a result of neuropil subtraction
switch type
    
    case 'same'
        NeuropilWeight = repmat(nanmin(Data(:)), numROIs, 1);
        % NeuropilWeight = repmat(prctile(Data(:), 1), numROIs, 1);
        
    case 'individual'
        NeuropilWeight = nanmin(Data)';
        
end
NeuropilWeight(NeuropilWeight > maxWeight) = maxWeight; % rectify top of range (some neurons will always have baseline signal so previous assumption can't be made)


