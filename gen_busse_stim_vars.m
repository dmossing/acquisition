function busse = gen_busse_stim_vars()
busse.gen_result_fn = @gen_busse_result;
busse.gen_conds_fn = @gen_busse_stim;
busse.gen_stim_fn = @gen_busse_conds;
busse.gen_tex_fn = @gen_plaids;

function conds = gen_busse_conds(result)
nConds  =  [1+length(result.contrast) 1+length(result.contrast)]; % one extra for zero contrast
allConds  =  prod(nConds)+2; % two extra for individual full contrast gratings
conds  =  makeAllCombos([0 result.contrast 1],[0 result.contrast 1]);
conds(:,conds(1,:) == 1 & conds(2,:) ~= 0) = [];
conds(:,conds(1,:) ~= 0 & conds(2,:) == 1) = [];

function result = gen_busse_result(result,conds)
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

gratingInfo.Contrast1 = conds(1,allthecondinds(:));
gratingInfo.Contrast2 = conds(2,allthecondinds(:));
gratingInfo.Orientation1 = result.orientations(1)*ones(1,allTrials);
gratingInfo.Orientation2 = result.orientations(2)*ones(1,allTrials);
gratingInfo.Size = result.sizes*ones(1,allTrials);
gratingInfo.tFreq = result.tFreqs*ones(1,allTrials);
gratingInfo.spFreq = result.sFreqs*ones(1,allTrials);

result.gratingInfo = gratingInfo;

function thisstim = gen_busse_stim(gratingInfo,trnum,movieDurationFrames)
bin = (gratingInfo.widthLUT(:,1) == gratingInfo.Size(trnum));
thisstim.thiswidth = gratingInfo.widthLUT(bin,2);
thisstim.thissize = gratingInfo.Size(trnum);
thisstim.thisspeed = gratingInfo.tFreq(trnum);
thisstim.thisfreq = gratingInfo.spFreq(trnum);
thisstim.thiscontrast1 = gratingInfo.Contrast1(trnum);
thisstim.thiscontrast2 = gratingInfo.Contrast2(trnum);
thisstim.thisdeg1 = gratingInfo.Orientation1(trnum);
thisstim.thisdeg2 = gratingInfo.Orientation2(trnum);
thisstim.trnum = trnum;
numFrames = numel(thisstim.tex);
thisstim.movieDurationFrames = movieDurationFrames;
thisstim.movieFrameIndices = mod(0:(movieDurationFrames-1), numFrames) + 1;