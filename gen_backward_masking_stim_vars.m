function bw = gen_backward_masking_stim_vars()
bw.gen_result_fn = @gen_backward_masking_result;
bw.gen_conds_fn = @gen_backward_masking_conds;
bw.gen_stim_fn = @gen_backward_masking_stim;
bw.gen_tex_fn = @gen_backward_masking_gratings;

function conds = gen_backward_masking_conds(result)
nConds  =  [length(result.orientations) length(result.orientations)];
% one extra for no vis stim, one extra for no opto stim
allConds  =  prod(nConds);
if ~isfield(result.expt_info,'orientations1')
    result.expt_info.orientations1 = result.orientations;
end
if ~isfield(result.expt_info,'orientations2')
    result.expt_info.orientations2 = result.orientations;
end
conds  =  makeAllCombos(result.expt_info.orientations1,result.expt_info.orientations2);

function result = gen_backward_masking_result(result,conds)
gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
width  =  result.PatchRadiusPix;
gratingInfo.widthLUT = [result.sizes(:) width(:)];

allConds = size(conds,2);

allthecondinds = zeros(allConds,result.repetitions);
for itrial = 1:result.repetitions,
    allthecondinds(:,itrial) = randperm(allConds);
end

allTrials = prod(size(allthecondinds));

gratingInfo.Orientation1 = conds(1,allthecondinds(:)');
gratingInfo.Orientation2 = conds(2,allthecondinds(:)');
gratingInfo.Size = result.sizes*ones(1,allTrials);
gratingInfo.tFreq = result.tFreqs*ones(1,allTrials);
gratingInfo.spFreq = result.sFreqs*ones(1,allTrials);
gratingInfo.Contrast = result.contrast*ones(1,allTrials);
gratingInfo.Stim1Frames = result.expt_info.stim1frames*ones(1,allTrials);

result.gratingInfo = gratingInfo;

function thisstim = gen_backward_masking_stim(gratingInfo,trnum,movieDurationFrames)
bin = (gratingInfo.widthLUT(:,1) == gratingInfo.Size(trnum));
thisstim.thiswidth = gratingInfo.widthLUT(bin,2);
thisstim.thissize = gratingInfo.Size(trnum);
thisstim.thisspeed = gratingInfo.tFreq(trnum);
thisstim.thisfreq = gratingInfo.spFreq(trnum);
thisstim.thiscontrast = gratingInfo.Contrast(trnum);
thisstim.thisdeg1 = gratingInfo.Orientation1(trnum);
thisstim.thisdeg2 = gratingInfo.Orientation2(trnum);
% thisstim.thisroi = gratingInfo.OptoROI(trnum);
thisstim.trnum = trnum;
thisstim.movieDurationFrames = movieDurationFrames;

function thisstim = gen_backward_masking_gratings(wininfo,gratingInfo,thisstim)
gratingInfo.Orientation(thisstim.trnum) = gratingInfo.Orientation1(thisstim.trnum);
thisstim.thisdeg = thisstim.thisdeg1;
stim1 = gen_gratings(wininfo,gratingInfo,thisstim);
gratingInfo.Orientation(thisstim.trnum) = gratingInfo.Orientation2(thisstim.trnum);
thisstim.thisdeg = thisstim.thisdeg2;
stim2 = gen_gratings(wininfo,gratingInfo,thisstim);
thisstim.tex = [stim2.tex stim1.tex]; % hope tex are row vectors!
numFrames = numel(stim2.tex);
assert(numFrames==numel(stim1.tex));
thisstim.movieFrameIndices = mod(0:(thisstim.movieDurationFrames-1), numFrames) + 1;
thisstim.movieFrameIndices(1:gratingInfo.Stim1Frames) = ...
    thisstim.movieFrameIndices(1:gratingInfo.Stim1Frames)+numFrames;
thisstim.trigonframe = false(thisstim.movieDurationFrames,1);
thisstim.trigonframe(1+gratingInfo.Stim1Frames) = true;