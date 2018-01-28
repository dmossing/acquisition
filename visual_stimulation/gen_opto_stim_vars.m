function opto = gen_opto_stim_vars()
opto.gen_result_fn = @gen_opto_result;
opto.gen_conds_fn = @gen_opto_conds;
opto.gen_stim_fn = @gen_opto_stim;

function conds = gen_opto_conds(result)
nConds  =  [length(result.opto_targets) length(result.opto_amplitude) length(result.opto_duration)]; 
% one extra for no vis stim, one extra for no opto stim
allConds  =  prod(nConds);
conds  =  makeAllCombos(result.opto_targets,result.opto_amplitude,result.opto_duration);

function result = gen_opto_result(result,conds)

allConds = size(conds,2);

allthecondinds = zeros(allConds,result.repetitions);
for itrial = 1:result.repetitions,
    allthecondinds(:,itrial) = randperm(allConds);
end

allTrials = numel(allthecondinds);

roiInfo.OptoROI = conds(1,allthecondinds(:)');
roiInfo.Amplitude = conds(2,allthecondinds(:)');
roiInfo.Duration = conds(3,allthecondinds(:)');

result.roiInfo = roiInfo;

function thisstim = gen_opto_stim(roiInfo,trnum)
thisstim.thisroi = roiInfo.OptoROI(trnum);
thisstim.thisamplitude = roiInfo.Amplitude(trnum);
thisstim.thisduration = roiInfo.Duration(trnum);
thisstim.trnum = trnum;