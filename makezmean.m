function zmean = makezmean(fname,zno,framesperz)
ex = load2P(fname,'frames',1);
zmean = zeros(zno,size(ex,1),size(ex,2));
for i=1:zno
    i
    Images = squeeze(load2P(fname,'frames',(i-1)*framesperz+(1:framesperz)));
    zmean(i,:,:) = mean(Images,3);
end
    % sz = size(Images);
% Images = reshape(Images,sz(1),sz(2),framesperz,zno);
% zmean = permute(Images,[4 1 2 3]);