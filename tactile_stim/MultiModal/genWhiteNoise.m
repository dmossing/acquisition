function out = genWhiteNoise(N,dur,Power)

if ~exist('N','var') || isempty(N)
    N = 100;
end
if ~exist('dur','var') || isempty(dur)
    dur = 30000*1.5;
end
if ~exist('power','var') || isempty(Power)
    Power = 0;
end

out = wgn(dur,N,Power);

% TEST
% sound(out(:,1));