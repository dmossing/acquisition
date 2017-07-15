function out = genDistribution2(N,varargin)
% N is an integer that specifies the number of values requested

Distribution = 'constant'; % uniform, normal, specific, constant
Weights = {[.1,.6,.9,1,1,.9,.6,.1],[1,1]}; % values between 0 to 1, numel>=2
sample = 'blcok'; % wReplacement, woReplacement, block
verbose = false;


%% Check input arguments
if ~exist('N','var') || isempty(N)
    N = 100;
end

if isempty(varargin)
    varargin = {[0,1]};
end

input = {};
index = 1;
while index<=length(varargin)
    if isnumeric(varargin{index})
        input{end+1} = varargin{index};
        index = index + 1;
    else
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
end


%% Generate points
numDims = numel(input);
switch Distribution
    case 'uniform' % randomly sample from a unifrom distribution
        out = rand(N,numDims);
    case 'normal' % randomly sample from a gaussian distribution
        out = randn(N,numDims);
    case 'specific' % create a distribution to take weighted samples from
        if ~iscell(Weights)
            Weights = {Weights};
        end
        if numel(Weights)==1 && numDims>1
            Weights = repmat(Weights,1,numDims);
        end
        tempDist = cell(numDims,1);
        tempWeights = cell(numDims,1);
        for dindex = 1:numDims
            if numel(input{dindex})>2 %specified number of points along axis
                tempDist{dindex} = 0:1/(input{dindex}(3)-1):1;
            else
                tempDist{dindex} = 0:1/10000:1;
            end
            Xw = 0:1/(numel(Weights{dindex})-1):1;
            tempWeights{dindex} = interp1(Xw, Weights{dindex}, tempDist{dindex});
        end
        if numDims == 1
            out = tempDist{1};
            Weights = tempWeights{1};
        else
            [X,Y] = meshgrid(tempDist{1},tempDist{2});
            out = [X(:),Y(:)];
            [X,Y] = meshgrid(tempWeights{1},tempWeights{2});
            Weights = prod([X(:),Y(:)],2);
        end
    case 'constant' % create a evenly spaced distribution (grid)
        if numDims == 1
            if N == 0 && numel(input{1})>2
                out = linspace(0,1,input{1}(3))';
            else  
                out = linspace(0,1,N)';
            end
        else %if numDims > 1
            temp = repmat(N^(1/numDims), 1, numDims);
            for dindex = 1:numDims
                if numel(input{dindex})>2
                    temp(dindex) = input{dindex}(3);
                end
            end
            if numDims == 2
                [X,Y] = meshgrid(linspace(0,1,temp(1)),linspace(0,1,temp(2)));
                out = [X(:),Y(:)];
            elseif numDims == 3
                [X,Y,Z] = meshgrid(linspace(0,1,temp(1)),linspace(0,1,temp(2)),linspace(0,1,temp(3)));
                out = [X(:),Y(:),Z(:)];
            end
        end
end

% % Scale to be between 0 and 1 (guarantees a point on each extreme - otherwise its completely unlikely except for grid)
% out = bsxfun(@minus, out, min(out));
% out = bsxfun(@rdivide, out, max(out));

% Scale 0 to 1 to requested min and max
for dindex = 1:numDims
    out(:,dindex) = out(:,dindex)*(input{dindex}(2)-input{dindex}(1)) + input{dindex}(1);
end

% Produce the desired number of outputs
if N ~= 0
    n = size(out,1);
    % Checks
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
    
    switch sample
        
        case 'wReplacement'
            switch Distribution
                case 'specific' % sample with weights
                        out = datasample(out, N, 1, 'Replace', true, 'Weights', Weights);
                otherwise % sample randomly
                        out = datasample(out, N, 1, 'Replace', true);
            end
            
        case 'woReplacement'
            switch Distribution
                case 'specific' % sample with weights
                        out = datasample(out, N, 1, 'Replace', false, 'Weights', Weights);
                otherwise % sample randomly
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

