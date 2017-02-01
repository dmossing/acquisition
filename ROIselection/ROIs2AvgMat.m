function [Data, StimID] = ROIs2AvgMat(ROIdata, varargin)


FrameIndex = [];
ROIindex = [1 inf];
TrialIndex = [1 inf];

saveOut = false;
saveFile = '';

%% Parse input arguments
index = 1;
while index<=length(varargin)
    try
        switch varargin{index}
            case {'FrameIndex', 'Frames', 'frames'}
                FrameIndex = varargin{index+1};
                index = index + 2;
            case {'TrialIndex', 'Trials', 'trials'}
                TrialIndex = varargin{index+1};
                index = index + 2;
            case {'ROIindex', 'ROIs', 'rois'}
                ROIindex = varargin{index+1};
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

if ~exist('ROIdata', 'var')
    [ROIdata, p] = uigetfile({'*.rois;*.mat'}, 'Select ROI file', directory);
    if ~ROIdata
        return
    else
        ROIdata = fullfile(p, ROIdata);
    end
end


%% Load file
if ischar(ROIdata)
    ROIFile = ROIdata;
    load(ROIFile, 'ROIdata', '-mat');
end


%% Determine parameters
if ROIindex(end) == inf
    ROIindex = [ROIindex(1:end-1), ROIindex(end-1)+1:numel(ROIdata.rois)];
end
numROIs = numel(ROIindex);

if TrialIndex(end) == inf
    TrialIndex = [TrialIndex(1:end-1), TrialIndex(end-1)+1:numel(ROIdata.DataInfo.StimID)];
end

if isempty(FrameIndex)
    FrameIndex = [ROIdata.DataInfo.numFramesBefore+1, ROIdata.DataInfo.numFramesBefore+mode(ROIdata.DataInfo.numStimFrames(TrialIndex))];
end


%% Format data
[H, W] = size(ROIdata.rois(ROIindex(1)).dFoF);
Data = reshape([ROIdata.rois(ROIindex).dFoF], H, W, numROIs);
Data = mean(Data(TrialIndex,FrameIndex(1):FrameIndex(2),:), 2);
Data = permute(Data, [3,1,2]);
StimID = ROIdata.DataInfo.StimID(TrialIndex)';


%% Save output
if saveOut
    if ~exist(saveFile, 'file')
        save(saveFile, 'Data', 'StimID', '-mat', '-v7.3');
    else
        save(saveFile, 'Data', 'StimID', '-mat', '-append');
    end
end

