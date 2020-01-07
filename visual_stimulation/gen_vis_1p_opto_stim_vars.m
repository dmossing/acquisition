function busse = gen_vis_1p_opto_stim_vars()
busse.gen_result_fn = @gen_vis_opto_result;
busse.gen_conds_fn = @gen_vis_opto_conds;
busse.gen_stim_fn = @gen_vis_opto_stim;
busse.gen_tex_fn = @gen_gratings;

function conds = gen_vis_opto_conds(result)
nConds  =  [length(result.orientations) length(result.sizes) length(result.tFreqs) length(result.sFreqs) length(result.contrast) length(result.lights_on)];
allConds  =  prod(nConds);
conds  =  makeAllCombos(result.orientations,result.sizes,result.tFreqs,result.sFreqs,result.contrast,result.lights_on);

function result = gen_vis_opto_result(result,conds)
gratingInfo.gf = 5;%.Gaussian width factor 5: reveal all .5 normal fall off
gratingInfo.Bcol = 128; % Background 0 black, 255 white
gratingInfo.method = 'symmetric';
gratingInfo.gtype = 'box';
width  =  result.PatchRadiusPix;
gratingInfo.widthLUT = [result.sizes(:) width(:)];
gratingInfo.circular = result.circular;

allConds = size(conds,2);

allthecondinds = zeros(allConds,result.repetitions);
for itrial = 1:result.repetitions
    allthecondinds(:,itrial) = randperm(allConds);
end

allTrials = prod(size(allthecondinds));

gratingInfo.Orientation = conds(1,allthecondinds(:)');
gratingInfo.Size = conds(2,allthecondinds(:)');
gratingInfo.tFreq = conds(3,allthecondinds(:)');
gratingInfo.spFreq = conds(4,allthecondinds(:)');
gratingInfo.Contrast = conds(5,allthecondinds(:)');
gratingInfo.lightsOn = conds(6,allthecondinds(:)');

result.gratingInfo = gratingInfo;
result.stimParams = conds(:,allthecondinds(:)');

function thisstim = gen_vis_opto_stim(gratingInfo,trnum,movieDurationFrames)
bin = (gratingInfo.widthLUT(:,1) == gratingInfo.Size(trnum));
thisstim.thiswidth = gratingInfo.widthLUT(bin,2);
thisstim.thissize = gratingInfo.Size(trnum);
thisstim.thisspeed = gratingInfo.tFreq(trnum);
thisstim.thisfreq = gratingInfo.spFreq(trnum);
thisstim.thiscontrast = gratingInfo.Contrast(trnum);
thisstim.thisdeg = gratingInfo.Orientation(trnum);
thisstim.thislightson = gratingInfo.lightsOn(trnum);
thisstim.trnum = trnum;
thisstim.movieDurationFrames = movieDurationFrames;