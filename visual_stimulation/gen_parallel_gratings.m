function tex = gen_parallel_gratings(wininfo,gratingInfo,thisstim)
gf = gratingInfo.gf;%.Gaussian width factor 5: reveal all .5 normal fall off
Bcol = gratingInfo.Bcol; % Background 0 black, 255 white
method = gratingInfo.method;
gtype = gratingInfo.gtype;
circular = gratingInfo.circular;

w = wininfo.w;
PixperDeg = wininfo.PixperDeg;

xRes = wininfo.xRes;
yRes = wininfo.yRes;

xposStim = wininfo.xposStim(thisstim.positionind);
yposStim = wininfo.yposStim(thisstim.positionind);

if isfield(thisstim,'bgsize')
    bgsize = thisstim.bgsize;
    x1 = floor(xRes/2 + xposStim*PixperDeg - bgsize.*PixperDeg/2);
    y1 = floor(yRes/2 - yposStim*PixperDeg - bgsize.*PixperDeg/2);
else
    bgsize = 0;
    x1 = 1;
    y1 = 1;
end

% gtype = 'sine';

frameRate = wininfo.frameRate;
bg = Bcol*ones(yRes,xRes);

thisdeg = thisstim.thisdeg;
thiswidth = thisstim.thiswidth;
thissize = thisstim.thissize;
thiscontrast = thisstim.thiscontrast;
thisfreq = thisstim.thisfreq;
thisspeed = thisstim.thisspeed;
thisgcontrast = thisstim.thisgcontrast;
thisbgwidth = thisstim.thisbgwidth;

x0 = floor(xRes/2 + xposStim*PixperDeg - thissize.*PixperDeg/2);
y0 = floor(yRes/2 - yposStim*PixperDeg - thissize.*PixperDeg/2);

[x,y] = meshgrid([-thiswidth:thiswidth],[-thiswidth:thiswidth]);
[xbg,ybg] = meshgrid([-thisbgwidth:thisbgwidth],[-thisbgwidth:thisbgwidth]);
numFrames = ceil(frameRate/thisspeed);
for i=1:numFrames
    tic
    clear T G;
    phase = (i/numFrames)*2*pi;
    angle = thisdeg*pi/180; % 30 deg orientation.
    f = (thisfreq)/PixperDeg*2*pi; % cycles/pixel
    a = cos(angle)*f;
    b = sin(angle)*f;
    abg = cos(angle)*f;
    bbg = sin(angle)*f;
    g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
    if streq(gtype,'sine'),
        G0 = g0.*sin(a*x+b*y+phase);
        G0bg = g0.*sin(abg*xg+bbg*yg+phase);
    elseif streq(gtype,'box'),
        s = sin(a*x+b*y+phase);
        sbg = sin(abg*xbg+bbg*ybg+phase);
        ext = max(max(max(s)),abs(min(min(s))));
        extbg = max(max(max(sbg)),abs(min(min(sbg))));
        G0=ext*((s>0)-(s<0));%.*g0;
        G0bg=extbg*((sbg>0)-(sbg<0));%.*g0;
    end
    if streq(method,'symmetric'),
        incmax = min(255-Bcol,Bcol);
        G = (floor(thiscontrast*(incmax*G0)+Bcol));
        Gbg = (floor(thisgcontrast*(incmax*G0bg)+Bcol));
    elseif streq(method,'cut'),
        incmax = max(255-Bcol,Bcol);
        G = (floor(thiscontrast*(incmax*G0)+Bcol));
        Gbg = (floor(thisgcontrast*(incmax*G0bg)+Bcol));
        G = max(G,0);G = min(G,255);
        Gbg = max(Gbg,0);Gbg = min(Gbg,255);
    end
    T = bg;
    T(y1:y1+size(Gbg,1)-1,x1:x1+size(Gbg,2)-1) = Gbg;
    if circular
        aux = T(y0:y0+size(G,2)-1,x0:x0+size(G,2)-1);
        se = strel('disk',thiswidth,0);
        aux(se.Neighborhood) = G(se.Neighborhood);
        T(y0:y0+size(G,1)-1,x0:x0+size(G,2)-1) = aux;
    else
        T(y0:y0+size(G,1)-1,x0:x0+size(G,2)-1) = G;
    end
    toc
    tic
    tex(i) = Screen('MakeTexture', w, T);
    toc
end
end

