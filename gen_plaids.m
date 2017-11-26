% function [tex,trigonframe] = gen_plaids(wininfo,result,thisstim)
function thisstim = gen_plaids(wininfo,result,thisstim)
gf = gratingInfo.gf;%.Gaussian width factor 5: reveal all .5 normal fall off
Bcol = gratingInfo.Bcol; % Background 0 black, 255 white
method = gratingInfo.method;
gtype = gratingInfo.gtype;
% gtype = 'sine';

xRes = wininfo.xRes;
yRes = wininfo.yRes;
w = wininfo.w;
PixperDeg = wininfo.PixperDeg;
xposStim = wininfo.xposStim;
yposStim = wininfo.yposStim;
frameRate = wininfo.frameRate;
bg = Bcol*ones(yRes,xRes);

thiswidth = thisstim.thiswidth;
thissize = thisstim.thissize;
thiscontrast1 = thisstim.thiscontrast1;
thiscontrast2 = thisstim.thiscontrast2;
thisdeg1 = thisstim.thisdeg1;
thisdeg2 = thisstim.thisdeg2;
thisfreq = thisstim.thisfreq;
thisspeed = thisstim.thisspeed;

x0 = floor(xRes/2 + xposStim*PixperDeg - thissize.*PixperDeg/2);
y0 = floor(yRes/2 - yposStim*PixperDeg - thissize.*PixperDeg/2);

[x,y] = meshgrid([-thiswidth:thiswidth],[-thiswidth:thiswidth]);
numFrames = ceil(frameRate/thisspeed);
for i=1:numFrames
%     tic
    clear T G;
    phase = (i/numFrames)*2*pi;
    f = (thisfreq)/PixperDeg*2*pi; % cycles/pixel
    angle = thisdeg1*pi/180; % grating 1
    a = cos(angle)*f;
    b = sin(angle)*f;
    g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
    if streq(gtype,'sine'),
        G01 = g0.*sin(a*x+b*y+phase);
    elseif streq(gtype,'box'),
        s = sin(a*x+b*y+phase);
        ext = max(max(max(s)),abs(min(min(s))));
        G01=ext*((s>0)-(s<0));%.*g0;
    end
    angle = thisdeg2*pi/180; % grating 2
    a = cos(angle)*f;
    b = sin(angle)*f;
    g0 = exp(-((x/(gf*thiswidth)).^2)-((y/(gf*thiswidth)).^2));
    if streq(gtype,'sine'),
        G02= g0.*sin(a*x+b*y+phase);
    elseif streq(gtype,'box'),
        s = sin(a*x+b*y+phase);
        ext = max(max(max(s)),abs(min(min(s))));
        G02=ext*((s>0)-(s<0));%.*g0;
    end
%     if streq(method,'symmetric'),
%         incmax = min(255-Bcol,Bcol);
%         G = (floor(thiscontrast1*(incmax*G01)+thiscontrast2*(incmax*G02)+Bcol));
%     elseif streq(method,'cut'),
%         incmax = max(255-Bcol,Bcol);
%         G = (floor(thiscontrast1*(incmax*G01)+thiscontrast2*(incmax*G02)+Bcol));
%         G = max(G,0);G = min(G,255);
%     end
    if streq(method,'symmetric'),
        incmax = min(255-Bcol,Bcol);
        G = (floor(thiscontrast1*(incmax*G01)+thiscontrast2*(incmax*G02)+Bcol));
    elseif streq(method,'cut'),
        incmax = max(255-Bcol,Bcol);
        G = (floor(thiscontrast1*(incmax*G01)+thiscontrast2*(incmax*G02)+Bcol));
        G = max(G,0);G = min(G,255);
    end
    
    T = bg;
    T(y0:y0+size(G,2)-1,x0:x0+size(G,2)-1) = G;
%     toc
%     tic
%     tex(i) = Screen('MakeTexture', w, T);
    thisstim.tex(i) = Screen('MakeTexture', w, T);
%     toc
end
thisstim.trigonframe = false(numFrames,1);
thisstim.movieFrameIndices = mod(0:(thisstim.movieDurationFrames-1), numFrames) + 1;
end

