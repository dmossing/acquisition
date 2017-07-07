function locs = tileScreen(gratingSize,screenInfo)
sizeGrating = screenInfo.PixperDeg*gratingSize;
yRes = screenInfo.yRes;
xRes = screenInfo.xRes;
Ny = floor(yRes/sizeGrating);
Nx = floor(xRes/sizeGrating);
% grid = [Ny,Nx];
locs = zeros(Ny,Nx,2);
for i=1:Ny
    for j=1:Nx
        locs(i,j,:) = [yRes,xRes]/2 +[i-(Ny+1)/2,j-(Nx+1)/2]*sizeGrating;
    end
end
