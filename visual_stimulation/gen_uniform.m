function thisstim = gen_uniform(wininfo,gratingInfo,thisstim,aperture)
if nargin < 4
    aperture = [];
end
Bcol = gratingInfo.Bcol; % Background 0 black, 255 white
% circular = gratingInfo.circular;

xRes = wininfo.xRes;
yRes = wininfo.yRes;
w = wininfo.w;
% PixperDeg = wininfo.PixperDeg;
% xposStim = wininfo.xposStim;
% yposStim = wininfo.yposStim;
frameRate = wininfo.frameRate;
bg = Bcol*ones(yRes,xRes);

% thiswidth = thisstim.thiswidth;
% thissize = thisstim.thissize;
% if numel(xposStim)>1
%     thisx = thisstim.thisx;
%     thisy = thisstim.thisy;
%     x0 = floor(xRes/2 + thisx*PixperDeg - thissize.*PixperDeg/2);
%     y0 = floor(yRes/2 - thisy*PixperDeg - thissize.*PixperDeg/2);
% % if isnan(thisdeg) % kludge to allow for nan orientation to mean gray screen!
% %     thiscontrast = 0;
% % end
% else
%     x0 = floor(xRes/2 + xposStim*PixperDeg - thissize.*PixperDeg/2);
%     y0 = floor(yRes/2 - yposStim*PixperDeg - thissize.*PixperDeg/2);
% end

% [x,y] = meshgrid([-thiswidth:thiswidth],[-thiswidth:thiswidth]);
numFrames = 1; 
for i=1:numFrames

    clear T G;
    
%     if circular
%         se = strel('disk',thiswidth,0);
%         G(~se.Neighborhood) = Bcol;
%     end
    
%     T = bg;
%     T(y0:y0+size(G,2)-1,x0:x0+size(G,2)-1) = G;
    
    T = round(255*thisstim.thisintensity)*ones(yRes,xRes);

    thisstim.tex(i) = Screen('MakeTexture', w, T);
end
thisstim.trigonframe = false(numFrames,1);
thisstim.movieFrameIndices = mod(0:(thisstim.movieDurationFrames-1), numFrames) + 1;
end

