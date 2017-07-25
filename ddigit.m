function ns = ddigit(n,d)
ns = num2str(n);
gap = d-length(ns);
if gap>0
    ns = [repmat('0',1,gap) ns];
end