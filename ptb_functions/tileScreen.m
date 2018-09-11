function locs = tileScreen(gratingSize,screenInfo,grid)
if nargin < 3
    grid = 1;
end
sizeGrating = screenInfo.PixperDeg*gratingSize;
yRes = screenInfo.yRes;
xRes = screenInfo.xRes;
Ny = floor((yRes/sizeGrating-1)*grid);
Nx = floor((xRes/sizeGrating-1)*grid);
% grid = [Ny,Nx];
locs = zeros(Ny,Nx,2);
for i=1:Ny
    for j=1:Nx
        locs(i,j,:) = [yRes,xRes]/2 +[i-(Ny+1)/2,j-(Nx+1)/2]*sizeGrating/grid;
    end
end
