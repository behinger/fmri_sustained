function cfg = setup_parameters(cfg)


assert(isstruct(cfg))

% Add functions to path
addpath('.')
addpath('./../functions');
addpath('./../functions/jheapcl');
% Add java memory cleaner
try
    javaaddpath(which('MatlabGarbageCollector.jar'))
end


% Set up key experiment parameters


if cfg.CAIPI
    cfg.TR = 3.504; % CAIPI?
    cfg.TR = 2.336;
    %     fprintf('XXXXXXXXXXXXXXXXXXXXXXXX setup_parameters.m Change TR to correct value XXXXXXXXXXXXXXXXXXX\n')
else
    cfg.TR = 3.408; % TR will determine stimulus timings
end

cfg.adapt = struct();
cfg.adapt.stimSize = 12; % Diameter in degrees
cfg.adapt.refOrient = [45, 135]; % reference stimuli are 45 and 135 degrees
cfg.adapt.spatialFrequency = 1; % cpd
cfg.adapt.contrast = 1; % max contrast
cfg.adapt.start_linear_decay_in_degree = 0.5;

cfg.adapt.stim1Pres = .5; % Reference stimulus presentation time
cfg.adapt.stim2Pres = .5; % Reference stimulus presentation time
cfg.adapt.ISI = .25; % Interval between reference stimuli
if cfg.CAIPI
    cfg.adapt.trialLength = cfg.TR * 6; %
    cfg.adapt.scannerWaitTime = cfg.TR * 4; % Time to wait after scan pulse - must be multiple of TR
else
    cfg.adapt.trialLength = cfg.TR * 4; %
    cfg.adapt.scannerWaitTime = cfg.TR * 3; % Time to wait after scan pulse - must be multiple of TR
end

cfg.adapt.ITI = cfg.adapt.trialLength - (cfg.adapt.stim1Pres+cfg.adapt.stim2Pres+cfg.adapt.ISI); % Time between trials

cfg.adapt.dotSize = 1.5*[0.25 0.06]; % Size of fixation dot in pixels
cfg.adapt.phases = linspace(0,2*pi,11);
cfg.adapt.phases = cfg.adapt.phases(1:end-1);
cfg.adapt.increment = 0.25; % Increment to increase thresholds by

cfg.adapt.flickerPerTrial = 1; % on average we will have one flicker per ~10s
cfg.adapt.flickerTimeDelta = 2;%s flicker have to be at least distance of 2s
cfg.adapt.flickerColor = 1; % percent
cfg.adapt.flickerDuration = 0.25;% flicker for 100ms

cfg.adapt.keys = [KbName('y') KbName('r') KbName('b') KbName('g') 49, 50, 51, 52]; %copied from essen_localiser_v4

cfg.localizer = struct();
cfg.localizer.stimSize = 12; % Diameter in degrees
cfg.localizer.orientation = [45, 135]; % Orientations we will used
cfg.localizer.spatialFrequency = 1; % cpd
cfg.localizer.contrast = 1; % 100% contrast
cfg.localizer.start_linear_decay_in_degree = 0.5;
cfg.localizer.numBlocks = 20; % Total number of stimulus blocks (half as many per orientation)
if cfg.debug
    cfg.localizer.numBlocks=5;
end
if cfg.CAIPI
    cfg.localizer.stimBlockLength = cfg.TR * 6; % Stimulus block length in seconds
    cfg.localizer.offBlockLength = cfg.TR * 6; % Off block length in seconds
    
    cfg.localizer.scannerWaitTime = cfg.TR * 4; % Time to wait after scan pulse - must be multiple of TR
    
else
    cfg.localizer.stimBlockLength = cfg.TR * 4; % Stimulus block length in seconds
    cfg.localizer.offBlockLength = cfg.TR * 4; % Off block length in seconds
    
    cfg.localizer.scannerWaitTime = cfg.TR * 3; % Time to wait after scan pulse - must be multiple of TR
    
end
cfg.localizer.stimPerBlock = round(cfg.localizer.stimBlockLength * 2); % Present stimuli at 2Hz (ish)

cfg.localizer.stimPres = cfg.localizer.stimBlockLength/(cfg.localizer.stimPerBlock*2); % Time individual stimulus is on for
cfg.localizer.ISI = cfg.localizer.stimPres; % Time between stimuli
cfg.localizer.phases = [pi, 2*pi]; % Will alternate phase, phases are chosen so that the fixation dot is always visible
cfg.localizer.dotSize = 1.5*[0.25 0.06]; % Size of fixation dot in pixels

cfg.localizer.flickerPerTrial = 2; % on average we will have 4 flicker per block
cfg.localizer.flickerTimeDelta = 1;%s flicker have to be at least distance of 2s
cfg.localizer.flickerColor = 1; % percent
cfg.localizer.flickerDuration = 0.25;% flicker for 100ms

cfg.localizer.keys = [KbName('y') KbName('r') KbName('b') KbName('g') 49, 50, 51, 52]; %copied from essen_localiser_v4

cfg.retinotopy = struct();
cfg.retinotopy.stimSize = 12; % Diameter in degrees
cfg.retinotopy.flickerRate = 6; % set flicker rate, in Hz (i.e. 2 textures every xHz)
if cfg.CAIPI
    cfg.retinotopy.cycleTime = cfg.TR * 17; % how long one complete cycle should last, in seconds
    cfg.retinotopy.scannerWaitTime = cfg.TR * 4; % Time to wait after scan pulse - must be multiple of TR
    
else
    cfg.retinotopy.cycleTime = cfg.TR * 11; % how long one complete cycle should last, in seconds
    cfg.retinotopy.scannerWaitTime = cfg.TR * 3; % Time to wait after scan pulse - must be multiple of TR
    
end
cfg.retinotopy.flickerColor = 1;
cfg.retinotopy.dotSize = 1.5*[0.25 0.06];
cfg.retinotopy.numCycles = 6;
if cfg.debug
    cfg.retinotopy.numCycles=2;
end
cfg.retinotopy.RingsOrWedges = [3]; %1 expanding ring, 2 contracting rings, 3 wedges
cfg.retinotopy.keys = [KbName('y') KbName('r') KbName('b') KbName('g') 49, 50, 51, 52]; % copied from Retinotopc_maping_withTask
cfg = setup_environment(cfg);

if cfg.mriPulse == 1
    try
        if ispc
        cfg.bitsi = Bitsi_Scanner('com1');
        else
            cfg.bitsi = Bitsi_Scanner('/dev/ttyS0'); % ttyS5
        end
        fprintf('Bitsi Scanner initialized\n')
        
    catch
        cfg.bitsi = nan;
        fprintf('Could not initialize bitsi\n')
    end
end
