function gratingFrame = gengratingFrame(t,gratingInfo,screenInfo)

orientation = gratingInfo.orientation;
gratingSize = gratingInfo.gratingSize;
spFreq = gratingInfo.spFreq;
tFreq = gratingInfo.tFreq;

PixperDeg = screenInfo.PixperDeg;
Bcol = screenInfo.Bcol;
window = screenInfo.window;
frameRate = screenInfo.frameRate;

sizeGrating = gratingSize*PixperDeg;
width = round(sizeGrating/2);

[x,y]=meshgrid([-width:width],[-width:width]);

phase=(t/frameRate*tFreq)*2*pi;
angle=orientation*pi/180; % 30 deg orientation.
f=(spFreq)/PixperDeg*2*pi; % cycles/pixel
a=cos(angle)*f;
b=sin(angle)*f;
g0=exp(-((x/(5*width)).^2)-((y/(5*width)).^2));
s=sin(a*x+b*y+phase);
ext = max(max(max(s)),abs(min(min(s))));
G0=ext*((s>0)-(s<0));%.*g0;
incmax=min(255-Bcol,Bcol);
G=(floor((incmax*G0)+Bcol));
gratingFrame = Screen('MakeTexture', window, G);