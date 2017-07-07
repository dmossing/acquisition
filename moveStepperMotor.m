function triggers = moveStepperMotor(RelativeAngle, samplingFrequency, indexStep, indexDir, DAQ, numOutPorts)
% RelativeAngle <0 means CW movement, and >0 means CCW

baseangle = 0.09; %length of a single microstep in degrees
analog = true;

%% Parse input arguments
if ~exist('RelativeAngle', 'var') || isempty(RelativeAngle)
    RelativeAngle = 30;
end

if ~exist('samplingFrequency', 'var') || isempty(samplingFrequency)
    samplingFrequency = 30000;
end

if ~exist('indexStep', 'var') || isempty(indexStep)
    indexStep = 1;
end

if ~exist('indexDir', 'var') || isempty(indexDir)
    indexDir = 2;
end

if ~exist('DAQ', 'var') || isempty(DAQ)
    DAQ = false;
elseif isequal(DAQ, true)
    DAQ = daq.createSession('ni'); % initialize session
    DAQ.Rate = samplingFrequency;
    if analog
        [~,id] = DAQ.addAnalogOutputChannel('Dev1',0:1,'Voltage');
    else
        [~,id] = DAQ.addDigitalChannel('Dev1','port0/line4:5','OutputOnly');
    end
    DAQ.Channels(id(1)).Name = 'O_MotorStep';
    DAQ.Channels(id(2)).Name = 'O_MotorDir';
    clearDAQ = true;
end

if ~exist('numOutPorts', 'var') || isempty(numOutPorts)
    numOutPorts = 2;
end

Slow = 20;      % # of zeros in slowest step (sets start and end speed of movement)
Fast = 9;      % # of zeros in fastest step (sets maximum speed allowed)
N = 4;         % # of repititions at each accel/deccel speed
speedStep = 1; % # of zeros to add between each accel/deccel speed increment

%% Create step triggers

numSteps = abs(round(RelativeAngle*1/baseangle)); %number of microsteps motor will make

% Create acceleration and decceleration steps
speeds = Slow:-speedStep:Fast+1; % accel/deccel speeds
speeds = repelem(speeds,N);      % replicate each speed # of times each will occur
stepScan = cumsum([1,speeds]);   % scan index of each high value (step)
accel = zeros(max(stepScan),1);  % initialize accel vector
accel(stepScan) = 1;             % set step scans to be high
if 2*sum(accel) > numSteps % acceleration and decceleration alone will move further than requested
    stepID = floor(numSteps/2);         % determine on what step to stop accelerating
    accel = accel(1:stepScan(stepID));  % trim acceleration vector
    Fast = speeds(stepID);              % recognize fastest speed reached
end
deccel = flip(accel);            % decceleration is inverse of acceleration
 
% Create center steps
numStepsMiddle = numSteps - (sum(accel) + sum(deccel)); % determine # of steps for bar to travel at fastest speed
steps = repmat([1;zeros(Fast,1)],numStepsMiddle,1);     % create vector for bar moving at fastest speed (not accelerating nor deccelerating)

% Create final trigger vector
stepTriggers = cat(1,0,accel,zeros(Fast,1),steps,deccel,0); % create final vector to move bar

%% Create output
triggers = zeros(numel(stepTriggers), numOutPorts);
triggers(:,indexStep) = stepTriggers;


%% Set direction
if RelativeAngle < 0 % CW
    triggers(1:end-1,indexDir) = 1;
end

%% Digital to analog
if analog
    triggers = 5*triggers;
end

%% Move motor
if ~isequal(DAQ, false)
    DAQ.queueOutputData(triggers);
    DAQ.startForeground;
    if exist('clearDAQ', 'var')
        clear DAQ
    end
end