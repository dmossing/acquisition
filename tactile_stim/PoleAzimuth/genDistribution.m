function out = genDistribution(N,input,varargin)
% N is an integer that specifies the number of values requested

Distribution = 'grid'; % 'grid' or 'random'
Weights = {}; %{[.1,.6,.9,1,1,.9,.6,.1],[1,1]}; % values between 0 to 1, numel>=2
sample = 'block'; % wReplacement, woReplacement, block
verbose = false;


%% Check input arguments
if ~exist('N','var') || isempty(N)
    N = 100;
end

if isempty(varargin)
    varargin = {[0,1]};
end

index = 1;
while index<=length(varargin)
    switch varargin{index}
        case {'Distribution','distribution','dist'}
            Distribution = varargin{index+1};
            index = index + 2;
        case {'Weights','weights'}
            Weights = varargin{index+1};
            index = index + 2;
        case {'Sample','sample'}
            sample = varargin{index+1};
            index = index + 2;
        case {'Verbose','verbose'}
            verbose = true;
            index = index + 1;
        otherwise
            warning('Argument ''%s'' not recognized',varargin{index});
            index = index + 1;
    end
end

if ~iscell(Weights)
    Weights = {Weights};
end

if strcmp(Distribution, 'random') && N == 0
    N = 1000;
    warning('Distribution->''random'' & N=0 => setting N to be 1000'); 
end
        
%% Generate points
numDims = size(input,1);
if numel(Weights)==1 && numDims>1           %only one dimension of weights given
    Weights = repmat(Weights,1,numDims);    %replicate weights for other dimensions
end

switch Distribution
    case 'grid' % create a evenly spaced distribution (grid)
        if numDims == 1
            out = linspace(0,1,input(1,3))';
            if ~isempty(Weights)
                Weights = interp1(0:1/(numel(Weights{1})-1):1, Weights{1}, out);
            end
        else
            [X,Y] = meshgrid(linspace(0,1,input(1,3)),linspace(0,1,input(2,3)));
            out = [X(:),Y(:)];
            if ~isempty(Weights)
                Weights = {interp1(0:1/(numel(Weights{1})-1):1, Weights{1}, linspace(0,1,input(1,3))), interp1(0:1/(numel(Weights{2})-1):1, Weights{2}, linspace(0,1,input(2,3)))};
                [X,Y] = meshgrid(Weights{1},Weights{2});
                Weights = prod([X(:),Y(:)],2);
            end
        end
    case 'random' % create a distribution to take samples from
        if numDims == 1
            out = (0:1/10000:1)';
            if ~isempty(Weights)
                Weights = interp1(0:1/(numel(Weights{1})-1):1, Weights{1}, out);
            end
        else
            [X,Y] = meshgrid(0:1/10000:1,0:1/10000:1);
            out = [X(:),Y(:)];
            if ~isempty(Weights)
                Weights = {interp1(0:1/(numel(Weights{1})-1):1, Weights{1}, 0:1/10000:1), interp1(0:1/(numel(Weights{2})-1):1, Weights{2}, 0:1/10000:1)};
                [X,Y] = meshgrid(Weights{1},Weights{2});
                Weights = prod([X(:),Y(:)],2);
            end
        end
    case 'uniform' % randomly sample from a unifrom distribution
        out = rand(N,numDims);
    case 'normal' % randomly sample from a gaussian distribution
        out = randn(N,numDims);
end

% % Scale to be between 0 and 1 (guarantees a point on each extreme - otherwise its completely unlikely except for grid)
% out = bsxfun(@minus, out, min(out));
% out = bsxfun(@rdivide, out, max(out));

% Scale 0 to 1 to requested min and max
for dindex = 1:numDims
    out(:,dindex) = out(:,dindex)*(input(dindex,2)-input(dindex,1)) + input(dindex,1);
end

% Produce the desired number of outputs
if N ~= 0
    % Validity Checks
    n = size(out,1);
    switch sample
        case 'woReplacement'
            if N > n % need more options than samples
                sample = 'wReplacement';
            end
        case 'block'
            if N < n % need less options than samples
                sample = 'woReplacement';
            end
    end
    
    % Sample from distribution
    switch sample
        
        case 'wReplacement'
            if ~isempty(Weights) % sample with weights
                out = datasample(out, N, 1, 'Replace', true, 'Weights', Weights);
            else % sample randomly
                out = datasample(out, N, 1, 'Replace', true);
            end
            
        case 'woReplacement'
            if ~isempty(Weights) % sample with weights
                out = datasample(out, N, 1, 'Replace', false, 'Weights', Weights);
            else % sample randomly
                out = datasample(out, N, 1, 'Replace', false);
            end
            
        case 'block'
            T = floor(N/n);
            out = cat(1, repmat(out,T,1), datasample(out, rem(N,n), 1, 'Replace', false));
    end
end


%% Check result
if verbose
    nbins = 20;
    figure;
    if numDims == 1
        subplot(1,2,1); plot(out,'k.'); axis tight; ylabel('Value'); xlim([input{1}(1),input{1}(2)]);
        subplot(1,2,2); histogram(out,nbins); axis tight; xlabel('X Position'); ylabel('count'); xlim([input{1}(1),input{1}(2)]);
    elseif numDims == 2
        subplot(1,3,1); plot(out(:,1),out(:,2),'k.'); axis tight; xlabel('X'); ylabel('Y');
        xlim([input{1}(1),input{1}(2)]); ylim([input{2}(1),input{2}(2)]);
        subplot(1,3,2); histogram(out(:,1),nbins); axis tight; xlabel('X Position'); ylabel('count'); xlim([input{1}(1),input{1}(2)]);
        subplot(1,3,3); histogram(out(:,2),nbins); axis tight; xlabel('Y Position'); ylabel('count'); xlim([input{2}(1),input{2}(2)]);
    end
end

