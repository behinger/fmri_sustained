% Draw stimulus and wait for a couple of seconds...

%--------------------------------------------------------------------------
% Add functions to path
addpath('.\..\..\Functions');
addpath(genpath('.\..\..\Toolbox'));
% Add java memory cleaner
javaaddpath(which('MatlabGarbageCollector.jar'))

%--------------------------------------------------------------------------
% Set up key experiment parameters
whichScreen = max(Screen('Screens')); %Screen ID
% set resolution to 1024x768 60hz
oldRes = SetResolution(whichScreen,1024,768,60);

background = calibrate_lum(1, 'work_station','prisma');

distFromScreen = 64;

params = struct();
params.stimSize = 20; % Diameter in degrees
params.orientation = [45, 135]; % Orientations we will used
params.sf = 1; % cpd
params.contrast = 1; % 100% contrast
params.numBlocks = 30; % Total number of stimulus blocks (half as many per orientation)
params.stimBlockLength = 14.7; % Stimulus block length in seconds
params.stimPerBlock = 30; % Present stimuli at 2Hz (ish)
params.offBlockLength = 14.7; % Off block length in seconds
params.stimPres = .245; % Time individual stimulus is on for
params.ISI = .245; % Time between stimuli
params.phases = [pi, 2*pi]; % Will alternate phase
%params.centreSize = degrees2pixels(1,distFromScreen, pixelsPerCm, whichScreen); % Radius of whole in centre of stimulus in degrees
% Not using pixelsPerCm here, degrees2pixels will measure this for itself.
% Seems more flexible in case of resolution differences.
params.centreSize = degrees2pixels(1,distFromScreen, [], whichScreen); % Radius of whole in centre of stimulus in degrees
params.dotSize = 4; % Size of fixation dot in pixels
params.scannerWaitTime = 10.5; % Time to wait after scan pulse - must be multiple of TR

%--------------------------------------------------------------------------
% Open window
[window, rect] = Screen('OpenWindow',whichScreen);
HideCursor(window);
% Get resolution of screen
x = rect(3);
y = rect(4);
% Change font
Screen('TextFont',window, 'Arial');
Screen('TextSize',window, 20);
% Fill screen with mid-grey background
Screen('FillRect', window, background);

stim = makeStimulus_am(1,params.stimSize,1,1,'work_station','prisma');
stimTex = Screen('MakeTexture', window, stim);

Screen('DrawTexture',window,stimTex);
Screen('Flip',window);

pause(3);

% Close window
Screen('Close');
Screen('Closeall');
SetResolution(whichScreen,oldRes);

% Clean up
try
    jheapcl; % clean the java heap space
catch
    disp('Could not clean java heap space');
end