% function [tex,trigonframe] = gen_gratings(wininfo,gratingInfo,thisstim)
function thisstim = gen_gratings(wininfo,gratingInfo,thisstim,aperture)
if nargin < 4
    aperture = [];
end
gf = gratingInfo.gf;%.Gaussian width factor 5: reveal all .5 normal fall off
Bcol = gratingInfo.Bcol; % Background 0 black, 255 white
method = gratingInfo.method;
gtype = gratingInfo.gtype;
circular = gratingInfo.circular;
% gtype = 'sine';

xRes = wininfo.xRes;
yRes = wininfo.yRes;
w = wininfo.w;
PixperDeg = wininfo.PixperDeg;
xposStim = wininfo.xposStim;
yposStim = wininfo.yposStim;
frameRate = wininfo.frameRate;
bg = Bcol*ones(yRes,xRes);

thisdeg = thisstim.thisdeg;
thiswidth = thisstim.thiswidth;
thissize = thisstim.thissize;
thiscontrast = thisstim.thiscontrast;
thisfreq = thisstim.thisfreq;
thisspeed = thisstim.thisspeed;
if numel(xposStim)>1
    thisx = thisstim.thisx;
    thisy = thisstim.thisy;
    x0 = floor(xRes/2 + thisx*PixperDeg - thissize.*PixperDeg/2);
    y0 = floor(yRes/2 - thisy*PixperDeg - thissize.*PixperDeg/2);
% if isnan(thisdeg) % kludge to allow for nan orientation to mean gray screen!
%     thiscontrast = 0;
% end
else
    x0 = floor(xRes/2 + xposStim*PixperDeg - thissize.*PixperDeg/2);
    y0 = floor(yRes/2 - yposStim*PixperDeg - thissize.*PixperDeg/2);
end

[x,y] = meshgrid([-thiswidth:thiswidth],[-thiswidth:thiswidth]);
numFrames = ceil(frameRate/thisspeed);
for i=1:numFrames
%     tic
    clear T G;
    phase = (i/numFrames)*2*pi;
    angle = thisdeg*pi/180; % 30 deg orientation.
    f = (thisfreq)/PixperDeg*2*pi; % cycles/pixel
    a = cos(angle)*f;
    b = sin(angle)*f;
    g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
    if streq(gtype,'sine'),
        G0 = g0.*sin(a*x+b*y+phase);
    elseif streq(gtype,'box'),
        s = sin(a*x+b*y+phase);
        ext = max(max(max(s)),abs(min(min(s))));
        G0=ext*((s>0)-(s<0));%.*g0;
    end
    if streq(method,'symmetric'),
        incmax = min(255-Bcol,Bcol);
        G = (floor(thiscontrast*(incmax*G0)+Bcol));
    elseif streq(method,'cut'),
        incmax = max(255-Bcol,Bcol);
        G = (floor(thiscontrast*(incmax*G0)+Bcol));
        G = max(G,0);G = min(G,255);
    end
    if circular
        se = strel('disk',thiswidth,0);
        G(~se.Neighborhood) = Bcol;
    end
    
    T = bg;
    if ~isnan(thisdeg) % kludge to allow for nan orientation to mean gray screen!
        T(y0:y0+size(G,2)-1,x0:x0+size(G,2)-1) = G;
    end
%     toc
%     tic
%     tex(i) = Screen('MakeTexture', w, T);
%     toc
    thisstim.tex(i) = Screen('MakeTexture', w, T);
end
thisstim.trigonframe = false(numFrames,1);
thisstim.movieFrameIndices = mod(0:(thisstim.movieDurationFrames-1), numFrames) + 1;
end

