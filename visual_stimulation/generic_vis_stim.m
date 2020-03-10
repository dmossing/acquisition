function [xpos,ypos] = map_retinotopy_2p_spinning(varargin) %(ratio,orientations,DScreen,...
%     ScreenType,gratingSize,spFreq,tFreq,nreps)

p = inputParser;
p.addParameter('animalid','Mfake');
p.addParameter('depth','000');
p.addParameter('repetitions',3);
p.addParameter('ratio',1);
p.addParameter('DScreen',15);
p.addParameter('VertScreenSize',27);
p.addParameter('sizes',10);
p.addParameter('grid',1)
p.addParameter('contrast',1);
p.addParameter('orientations',0:45:315);
p.addParameter('spFreq',0.08); % cyc/vis deg
p.addParameter('tFreq',2); % cyc/sec
p.parse(varargin{:});

result = p.Results;
load('C:\Users\shine\Documents\Dan\calibration\current_screen_params.mat','VertScreenSize','current_gamma_table')
result.VertScreenSize = VertScreenSize;
% set up DAQ

wininfo = gen_wininfo(result);

Bcol = wininfo.Bcol;
% screenInfo = genscreenInfo(wininfo.xRes,wininfo.yRes,result.VertScreenSize,result.DScreen,wininfo.frameRate,wininfo.Bcol);
window = wininfo.w; % screenInfo.window;

% load('/home/visual-stim/Documents/stims/calibration/new_old_gamma_table_181003','gammaTable2')
load(current_gamma_table,'gammaTable2')
Screen('LoadNormalizedGammaTable',wininfo.w,gammaTable2*[1 1 1]);

luminance = 0:16:255;
[mX, mY, buttons] = GetMouse;
for itex=1:numel(luminance)
    this_tex = Screen('MakeTexture', window, luminance(itex)*ones(wininfo.yRes,wininfo.xRes));
    Screen('DrawTexture', window, this_tex)%gratingFrame(gratingFrameIndex), gratingRect, CenterRectOnPoint(gratingRect, mX, mY));
    % Call Screen('Flip') to update the screen.  Note that calling
    % 'Flip' after we have both erased and redrawn the sprite prevents
    % the sprite from flickering.
    Screen('Flip', window);
    pause(5);
%     while any(buttons)
%         [mX, mY, buttons] = GetMouse;
%     end
%     gratingFrameIndex = gratingFrameIndex + 1;
end
sca
