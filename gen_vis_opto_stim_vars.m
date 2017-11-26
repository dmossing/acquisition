function busse = gen_vis_opto_stim_vars()
busse.gen_result_fn = @gen_vis_opto_result;
busse.gen_conds_fn = @gen_vis_opto_conds;
busse.gen_stim_fn = @gen_vis_opto_stim;
busse.gen_tex_fn = @gen_gratings;

function conds = gen_vis_opto_conds(result)
nConds  =  [length(result.orientations) length(result.opto_targets)]; 
% one extra for no vis stim, one extra for no opto stim
allConds  =  prod(nConds);
conds  =  makeAllCombos(result.orientations,result.opto_targets);

function result = gen_vis_opto_result(result,conds)
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

gratingInfo.Orientation = conds(1,allthecondinds(:)');
gratingInfo.OptoROI = conds(2,allthecondinds(:)');
gratingInfo.Size = result.sizes*ones(1,allTrials);
gratingInfo.tFreq = result.tFreqs*ones(1,allTrials);
gratingInfo.spFreq = result.sFreqs*ones(1,allTrials);
gratingInfo.Contrast = result.contrast*ones(1,allTrials);

result.gratingInfo = gratingInfo;

function thisstim = gen_vis_opto_stim(gratingInfo,trnum)
bin = (gratingInfo.widthLUT(:,1) == gratingInfo.Size(trnum));
thisstim.thiswidth = gratingInfo.widthLUT(bin,2);
thisstim.thissize = gratingInfo.Size(trnum);
thisstim.thisspeed = gratingInfo.tFreq(trnum);
thisstim.thisfreq = gratingInfo.spFreq(trnum);
thisstim.thiscontrast = gratingInfo.Contrast(trnum);
thisstim.thisdeg = gratingInfo.Orientation(trnum);
thisstim.thisroi = gratingInfo.OptoROI(trnum);
thisstim.trnum = trnum;