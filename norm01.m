function [mnNorm] = norm01(mn)
if min(size(mn))==1
    mn = mn(:)';
end
mnNorm = zeros(size(mn));
for i=1:size(mn,1)
    normfact = (max(mn(i,:))-min(mn(i,:)));
    mnNorm(i,:) = (mn(i,:)-min(mn(i,:)))/normfact;
end