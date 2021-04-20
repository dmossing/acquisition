function locs = tileSubScreen(gratingSize,screenInfo,grid,range)
% gratingSize: size of gratings in visual angle
% screenInfo: generated by gen_wininfo
% grid: 1/(spacing between patches to show), in units of patch width
% range: desired range of center locations of patches, in visual degrees. 
%   [x(leftmost) x(rightmost) y(bottom) y(top)]
if nargin < 3
    grid = 1;
end
sizeGrating = screenInfo.PixperDeg*gratingSize;
yRes = screenInfo.yRes;
xRes = screenInfo.xRes;
locx_angle = range(1):gratingSize/grid:range(2);
yavg = 0.5*(range(3)+range(4));
locy_angle = range(3):gratingSize/grid:range(4);
locy_angle = locy_angle - 2*yavg;
Ny = numel(locx_angle);
Nx = numel(locy_angle);
locs = zeros(Ny,Nx,2);
for i=1:Ny
    for j=1:Nx
        locs(i,j,:) = [yRes,xRes]/2 + [locy_angle(i),locx_angle(j)]*screenInfo.PixperDeg; % [-locy_angle(i),locx_angle(j)] 10/31-12/9
    end
end
