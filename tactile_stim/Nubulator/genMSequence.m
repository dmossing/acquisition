function [seq, vals] = genMSequence(m)

if m > 20 || m < 1
    error('m must be between 1 and 20');
end

switch m
    case 1
        indmod = m;
    case {5,11}
        indmod = [m, m-2];
    case 8
        indmod = [m, m-1, m-5, m-6];
    case 9
        indmod = [m, m-4];
    case {10, 17, 20}
        indmod = [m, m-3];
    case 12
        indmod = [m, m-7, m-4, m-3];
    case 13
        indmod = [m, m-4, m-3, m-1];
    case 14
        indmod = [m, m-12, m-11, m-1];
    case 16
        indmod = [m, m-5, m-3, m-2];
    case 18
        indmod = [m, m-7];
    case 19
        indmod = [m, m-6, m-5, m-1];
    otherwise
        indmod = [m, m-1];
end

N = 2^m - 1; % calculate length

seq = zeros(N, m); % initialize vector

seq(1,:) = 1; % first step is all 1's

% Create sequence
for step = 2:N
    seq(step, 1) = mod(sum(seq(step-1, indmod)),2);     % compute modulus for first value
    seq(step, 2:end) = seq(step-1, 1:m-1);              % shift rest of vector
end

% alternative output
if nargout>1
    vals = cellfun(@find, mat2cell(seq, ones(1,size(seq,1)), m), 'UniformOutput', false);
end
