function zret = retzscore(dfof_ret)
sz = size(dfof_ret); 
d = reshape(dfof_ret,sz(1)*sz(2),sz(3)*sz(4)); 
dz = zscore(d); 
zret = reshape(dz,sz(1),sz(2),sz(3),sz(4));