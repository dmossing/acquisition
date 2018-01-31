zret = retzscore(dfof_ret);
K = 1:200:1901; L = 1:200:1901;
zr = cell(length(K),length(L));
for i=1:length(K), 
    for j=1:length(L), 
        zr{i,j} = squeeze(mean(mean(zret(K(i):K(i)+100,L(j):L(j)+100,:,:),1),2)); 
    end; 
end
for i=1:length(K), 
    i, 
    for j=1:length(L), 
        subplot(length(K),length(L),(i-1)*length(L)+j), imagesc(zr{i,j}); 
        axis equal off; 
    end; 
end