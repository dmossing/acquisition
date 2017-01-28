function locs = tileScreen(gratingSize,screenInfo)
sizeGrating = screenInfo.PixperDeg*gratingSize;
Ny = floor(screenInfo.yRes/sizeGrating);
Nx = floor(screenInfo.xRes/sizeGrating);
% grid = [Ny,Nx];
locs = zeros(Ny,Nx,2);
for i=1:Ny
    for j=1:Nx
        locs(i,j,:) = [yRes,xRes]/2 +[i-(Ny+1)/2,j-(Nx+1)/2]*sizeGrating;
    end
end
