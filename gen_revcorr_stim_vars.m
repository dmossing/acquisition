function revcorr = gen_revcorr_stim_vars()
revcorr.gen_result_fn = @gen_revcorr_result;
revcorr.gen_conds_fn = @gen_revcorr_stim;
revcorr.gen_stim_fn = @gen_revcorr_conds;
revcorr.gen_tex_fn = @gen_revcorr_tex;

function conds = gen_revcorr_conds(result)
conds  =  0;

function result = gen_revcorr_result(result,conds)
gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
width  =  PatchRadiusPix;
gratingInfo.widthLUT = [result.sizes(:) width(:)];

allConds = size(conds,2);

allthecondinds = zeros(allConds,result.repetitions);
for itrial = 1:result.repetitions,
    allthecondinds(:,itrial) = randperm(allConds);
end

allTrials = prod(size(allthecondinds));



gratingInfo.Contrast = result.contrast*ones(1,allTrials); %conds(1,allthecondinds(:));
% gratingInfo.Contrast = conds(2,allthecondinds(:));
gratingInfo.Orientation = result.orientations;
% gratingInfo.Orientation = result.orientations(2)*ones(1,allTrials);
gratingInfo.Size = result.sizes*ones(1,allTrials);
% gratingInfo.tFreq = result.tFreqs*ones(1,allTrials);
gratingInfo.spFreq = result.sFreqs*ones(1,allTrials);
gratingInfo.oriRes = numel(result.orientations);
gratingInfo.phaseRes = result.expt_info.phase_res;
gratingInfo.showEachFor = found(result.frameRate/result.expt_info.stim_rate);
gratingInfo.stimno = round(result.stimduration * result.expt_info.stim_rate);
gratingInfo.oriInd = datasample(1:gratingInfo.oriRes,gratingInfo.stimno);
gratingInfo.phaseInd = datasample(1:gratingInfo.phaseRes,gratingInfo.stimno);

result.gratingInfo = gratingInfo;

function thisstim = gen_revcorr_stim(gratingInfo,trnum,movieDurationFrames)
bin = (gratingInfo.widthLUT(:,1) == gratingInfo.Size(trnum));
thisstim.thiswidth = gratingInfo.widthLUT(bin,2);
thisstim.thissize = gratingInfo.Size(trnum);
thisstim.thisfreq = gratingInfo.spFreq(trnum);
thisstim.thiscontrast = gratingInfo.Contrast(trnum);
thisstim.trnum = trnum;
numFrames = numel(thisstim.tex);
thisstim.movieDurationFrames = movieDurationFrames;
linearized = (gratingInfo.oriInd-1)*gratingInfo.phaseRes+gratingInfo.phaseInd;
linearized = repmat(linearized,gratingInfo.showEachFor,1);
% order is orientation changes slowly, phase changes quickly.
thisstim.movieFrameIndices = linearized(:)';


function thisstim = gen_revcorr_tex(wininfo,gratingInfo,thisstim)
thisstim.thisdeg = gratingInfo.Orientation(1);
tex = gen_gratings(wininfo,gratingInfo,thisstim)';
for i=2:gratingInfo.oriInd
    tex(:,i) = gen_gratings(wininfo,gratingInfo,thisstim);
end
tex = tex(:)';
thisstim.tex = tex;