function revcorr = gen_revcorr_busse_stim_vars()
revcorr.gen_result_fn = @gen_revcorr_result;
revcorr.gen_conds_fn = @gen_revcorr_conds;
revcorr.gen_stim_fn = @gen_revcorr_stim;
revcorr.gen_tex_fn = @gen_revcorr_tex;

function conds = gen_revcorr_conds(result)
conds = zeros(1,result.repetitions);

function result = gen_revcorr_result(result,conds)
gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
width  =  result.PatchRadiusPix;
gratingInfo.widthLUT = [result.sizes(:) width(:)];

allConds = size(conds,2);

% allTrials = prod(size(allthecondinds));

% gratingInfo.Contrast = result.contrast*ones(1,allTrials); %conds(1,allthecondinds(:));
% gratingInfo.Contrast = conds(2,allthecondinds(:));

conds1  =  makeAllCombos([0 result.contrast 1],[0 result.contrast 1]);
conds1(:,conds1(1,:) == 1 & conds1(2,:) ~= 0) = [];
conds1(:,conds1(1,:) ~= 0 & conds1(2,:) == 1) = [];

gratingInfo.Contrast1 = conds1(1,:);
gratingInfo.Contrast2 = conds1(2,:);
gratingInfo.Orientation1 = result.orientations(1)*ones(1,result.repetitions);
gratingInfo.Orientation2 = result.orientations(2)*ones(1,result.repetitions);
% gratingInfo.Orientation = result.orientations(2)*ones(1,allTrials);
gratingInfo.Size = result.sizes*ones(1,result.repetitions);
% gratingInfo.tFreq = result.tFreqs*ones(1,allTrials);
gratingInfo.spFreq = result.sFreqs*ones(1,result.repetitions);
% gratingInfo.oriRes = numel(result.orientations);
gratingInfo.nCombos = size(conds1,2);
gratingInfo.phaseRes = result.expt_info.phase_res;
gratingInfo.showEachFor = round(result.frameRate/result.expt_info.stim_rate);
gratingInfo.stimno = round(result.stimduration * result.expt_info.stim_rate);
gratingInfo.comboInd = datasample(1:gratingInfo.nCombos,gratingInfo.stimno);
gratingInfo.phaseInd = datasample(1:gratingInfo.phaseRes,gratingInfo.stimno);
gratingInfo.tFreq = result.frameRate/result.expt_info.phase_res;

result.gratingInfo = gratingInfo;

function thisstim = gen_revcorr_stim(gratingInfo,trnum,movieDurationFrames)
bin = (gratingInfo.widthLUT(:,1) == gratingInfo.Size(trnum));
thisstim.thiswidth = gratingInfo.widthLUT(bin,2);
thisstim.thissize = gratingInfo.Size(trnum);
thisstim.thisfreq = gratingInfo.spFreq(trnum);
% thisstim.thiscontrast = gratingInfo.Contrast(trnum);
thisstim.trnum = trnum;
% numFrames = numel(thisstim.tex);
thisstim.movieDurationFrames = movieDurationFrames;
thisstim.thisspeed = gratingInfo.tFreq;
linearized = (gratingInfo.comboInd-1)*gratingInfo.phaseRes+gratingInfo.phaseInd;
linearized = repmat(linearized,gratingInfo.showEachFor,1);
% order is orientation changes slowly, phase changes quickly.
thisstim.movieFrameIndices = linearized(:)';
trigs = [ones(1,gratingInfo.stimno); zeros(gratingInfo.showEachFor-1,gratingInfo.stimno)];
thisstim.trigonframe = trigs(:);


function thisstim = gen_revcorr_tex(wininfo,gratingInfo,thisstim)
thisstim.thisdeg1 = gratingInfo.Orientation1;
thisstim.thisdeg2 = gratingInfo.Orientation2;
thisstim.thiscontrast1 = gratingInfo.Contrast1(1);
thisstim.thiscontrast2 = gratingInfo.Contrast2(1);
stima = gen_plaids(wininfo,gratingInfo,thisstim);
tex = stima.tex(:);
for i=2:gratingInfo.nCombos
    thisstim.thiscontrast1 = gratingInfo.Contrast1(i);
    thisstim.thiscontrast2 = gratingInfo.Contrast2(i);
    stima = gen_plaids(wininfo,gratingInfo,thisstim);
    tex = [tex stima.tex(:)];
end
thisstim.tex = tex(:)';