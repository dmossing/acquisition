function combos = makeAllCombos(varargin)
Nvars = numel(varargin);
Neach = cellfun(@numel,varargin);
Ncombos = prod(Neach);
combos = zeros(Nvars,Ncombos);
for j=1:Ncombos
    for i=1:Nvars
        ind = mod(floor((j-1)/prod([1 Neach(1:i-1)])),Neach(i))+1;
        combos(i,j) = varargin{i}(ind);
    end
end