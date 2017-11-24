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

function thisstim = gen_busse_stim(gratingInfo,trnum)
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

% function tex = gen_plaids(wininfo,result,thisstim)
% gf = gratingInfo.gf;%.Gaussian width factor 5: reveal all .5 normal fall off
% Bcol = gratingInfo.Bcol; % Background 0 black, 255 white
% method = gratingInfo.method;
% gtype = gratingInfo.gtype;
% % gtype = 'sine';
% 
% xRes = wininfo.xRes;
% yRes = wininfo.yRes;
% w = wininfo.w;
% PixperDeg = wininfo.PixperDeg;
% xposStim = wininfo.xposStim;
% yposStim = wininfo.yposStim;
% frameRate = wininfo.frameRate;
% bg = Bcol*ones(yRes,xRes);
% 
% thiswidth = thisstim.thiswidth;
% thissize = thisstim.thissize;
% thiscontrast1 = thisstim.thiscontrast1;
% thiscontrast2 = thisstim.thiscontrast2;
% thisdeg1 = thisstim.thisdeg1;
% thisdeg2 = thisstim.thisdeg2;
% thisfreq = thisstim.thisfreq;
% thisspeed = thisstim.thisspeed;
% 
% x0 = floor(xRes/2 + xposStim*PixperDeg - thissize.*PixperDeg/2);
% y0 = floor(yRes/2 - yposStim*PixperDeg - thissize.*PixperDeg/2);
% 
% [x,y] = meshgrid([-thiswidth:thiswidth],[-thiswidth:thiswidth]);
% numFrames = ceil(frameRate/thisspeed);
% for i=1:numFrames
% %     tic
%     clear T G;
%     phase = (i/numFrames)*2*pi;
%     f = (thisfreq)/PixperDeg*2*pi; % cycles/pixel
%     angle = thisdeg1*pi/180; % grating 1
%     a = cos(angle)*f;
%     b = sin(angle)*f;
%     g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
%     if streq(gtype,'sine'),
%         G01 = g0.*sin(a*x+b*y+phase);
%     elseif streq(gtype,'box'),
%         s = sin(a*x+b*y+phase);
%         ext = max(max(max(s)),abs(min(min(s))));
%         G01=ext*((s>0)-(s<0));%.*g0;
%     end
%     angle = thisdeg2*pi/180; % grating 2
%     a = cos(angle)*f;
%     b = sin(angle)*f;
%     g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
%     if streq(gtype,'sine'),
%         G02= g0.*sin(a*x+b*y+phase);
%     elseif streq(gtype,'box'),
%         s = sin(a*x+b*y+phase);
%         ext = max(max(max(s)),abs(min(min(s))));
%         G02=ext*((s>0)-(s<0));%.*g0;
%     end
%     if streq(method,'symmetric'),
%         incmax = min(255-Bcol,Bcol);
%         G = (floor(thiscontrast1*(incmax*G01)+thiscontrast2*(incmax*G02)+Bcol));
%     elseif streq(method,'cut'),
%         incmax = max(255-Bcol,Bcol);
%         G = (floor(thiscontrast1*(incmax*G01)+thiscontrast2*(incmax*G02)+Bcol));
%         G = max(G,0);G = min(G,255);
%     end
%     
%     T = bg;
%     T(y0:y0+size(G,2)-1,x0:x0+size(G,2)-1) = G;
%     tex(i) = Screen('MakeTexture', w, T);
% end