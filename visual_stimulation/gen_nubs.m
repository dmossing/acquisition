% function [tex,trigonframe] = gen_gratings(wininfo,gratingInfo,thisstim)
function thisstim = gen_nubs(wininfo,gratingInfo,thisstim,aperture)
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
thiscross = thisstim.thiscross;
thisnubs = thisstim.thisnubs;
thisaskew = thisstim.thisaskew;
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
spacing = 2*thiswidth+1;
x0nubs = [x0, x0 + spacing, x0,           x0 - spacing, x0          ];
y0nubs = [y0, y0          , y0 - spacing, y0          , y0 + spacing];
numFrames = ceil(frameRate/thisspeed);
if thisdeg < 0
    degs = (1:numFrames)*360/numFrames;
else
    degs = thisdeg*ones(1,numFrames);
end
for i=1:numFrames
%     tic
%     thisdeg = degs(i);
    clear T G;
    phase = (i/numFrames)*2*pi;
    angle = degs(i)*pi/180; %thisdeg*pi/180; % 30 deg orientation.
    if thiscross & thisaskew
        anglebg = angle+pi/4; % angle+pi/2;
    elseif thiscross & ~thisaskew
        anglebg = angle+pi/2;
    else
        anglebg = angle;
    end
    f = (thisfreq)/PixperDeg*2*pi; % cycles/pixel
    a = cos(angle)*f;
    b = sin(angle)*f;
    abg = cos(anglebg)*f;
    bbg = sin(anglebg)*f;
    g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
    if streq(gtype,'sine'),
        G0 = g0.*sin(a*x+b*y+phase);
        G0bg = g0.*sin(abg*x+bbg*y+phase);
    elseif streq(gtype,'box'),
        s = sin(a*x+b*y+phase);
        sbg = sin(abg*x+bbg*y+phase);
        ext = max(max(max(s)),abs(min(min(s))));
        extbg = max(max(max(sbg)),abs(min(min(sbg))));
        G0=ext*((s>0)-(s<0));%.*g0;
        G0bg=extbg*((sbg>0)-(sbg<0));%.*g0;
    end
    if streq(method,'symmetric'),
        incmax = min(255-Bcol,Bcol);
        G = (floor(thiscontrast*(incmax*G0)+Bcol));
        Gbg = (floor(thiscontrast*(incmax*G0bg)+Bcol));
    elseif streq(method,'cut'),
        incmax = max(255-Bcol,Bcol);
        G = (floor(thiscontrast*(incmax*G0)+Bcol));
        Gbg = (floor(thiscontrast*(incmax*G0bg)+Bcol));
        G = max(G,0);G = min(G,255);
        Gbg = max(Gbg,0);Gbg = min(Gbg,255);
    end
    if circular
        se = strel('disk',thiswidth,0);
        G(~se.Neighborhood) = Bcol;
        Gbg(~se.Neighborhood) = Bcol;
    end
    
    T = bg;
    for inub=1
        xn = x0nubs(inub);
        yn = y0nubs(inub);
        if thisnubs(inub) % kludge to allow for nan orientation to mean gray screen!
            T(yn:yn+size(G,2)-1,xn:xn+size(G,2)-1) = G;
        end
    end
    for inub=2:numel(thisnubs)
        xn = x0nubs(inub);
        yn = y0nubs(inub);
        if thisaskew
            nrot = inub-2;
        else
            nrot = 0;
        end
        if thisnubs(inub) % kludge to allow for nan orientation to mean gray screen!
            T(yn:yn+size(G,2)-1,xn:xn+size(G,2)-1) = rot90(Gbg,nrot);
        end
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

