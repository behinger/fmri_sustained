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

% These keys are used if the bitsi_buttonbox is used over USB
% cfg.keys = [KbName('y') KbName('r') KbName('b') KbName('g') 49, 50, 51, 52]; %copied from essen_localiser_v4
KbName('UnifyKeyNames')
cfg.keys = [89 82 66 71 97 98 99 100 101]; %KbName sometimes does not work?!?
cfg.flicker = struct();
cfg.flicker.stimSize = 12; % Diameter in degrees
cfg.flicker.refOrient = [45, 135]; % orientations for stimuli are 45 and 135 degrees
cfg.flicker.spatialFrequency = 1; % cpd
cfg.flicker.phases = linspace(0,2*pi,13);
cfg.flicker.phases(end) = []; %delete last one as 0 = 2*pi
cfg.flicker.spatialFrequency_catch = 1.25;

cfg.flicker.contrast = 1; % max contrast
cfg.flicker.start_linear_decay_in_degree = 0.5;



cfg.flicker.trialLength = round(16/cfg.TR)*cfg.TR; %
cfg.flicker.scannerWaitTime = cfg.TR * 3; % Time to wait after scan pulse - must be multiple of TR


% cfg.flicker.stimdur.sustained = cfg.flicker.trialLength; % test 
% cfg.flicker.stimdur.interrupt_slow = [0.1,0.4]; % stim vs. break
% cfg.flicker.stimdur.interrupt_fast = [0.1,0.1]; % stim vs. mask


cfg.flicker.ITI = round(12/cfg.TR)*cfg.TR;%2*cfg.TR;

cfg.flicker.dotSize = 1.5*[0.25 0.06]; % Size of fixation dot in pixels
% cfg.flicker.increment = 0.25; % Increment to increase thresholds by

cfg.flicker.targetsPerTrial = 1.5; % on average we will have 1.5 flicker per Trial
cfg.flicker.targetsTimeDelta = 2;%s flicker have to be at least distance of 2s
cfg.flicker.targetsColor = 0.4; % percent
cfg.flicker.targetsDuration = 0.1;% flicker for 100ms



cfg.localizer = cfg.flicker;
cfg.localizer.orientation = [45 135];


cfg.localizer.stimBlockLength = round(16/cfg.TR)*cfg.TR; %
cfg.localizer.offBlockLength = round(12/cfg.TR)*cfg.TR; %

cfg.localizer.scannerWaitTime = cfg.TR * 4; % Time to wait after scan pulse - must be multiple of TR
    
cfg.localizer.stimPerBlock = round(cfg.localizer.stimBlockLength * 2); % Present stimuli at 2Hz (ish)

cfg.localizer.stimPres = cfg.localizer.stimBlockLength/(cfg.localizer.stimPerBlock*2); % Time individual stimulus is on for
cfg.localizer.ISI = cfg.localizer.stimPres; % Time between stimuli
cfg.localizer.phases = [pi, 2*pi]; % Will alternate phase, phases are chosen so that the fixation dot is always visible

cfg.localizer.flickerPerTrial = 2; % on average we will have 4 flicker per block
cfg.localizer.flickerTimeDelta = 1;%s flicker have to be at least distance of 2s
cfg.localizer.flickerColor = 0.4; % percent
cfg.localizer.flickerDuration = 0.1;% flicker for 100ms

cfg.retinotopy = cfg.flicker();
cfg.retinotopy.flickerRate = 6; % set flicker rate, in Hz (i.e. 2 textures every xHz)

cfg.retinotopy.cycleTime = round(35/cfg.TR)*cfg.TR; %

cfg.retinotopy.scannerWaitTime = cfg.TR * 3; % Time to wait after scan pulse - must be multiple of TR
    
cfg.retinotopy.flickerColor = 1;

cfg.retinotopy.numCycles = 6;
if cfg.debug
    cfg.retinotopy.numCycles=2;
end
cfg.retinotopy.RingsOrWedges = [3]; %1 expanding ring, 2 contracting rings, 3 wedges

cfg = setup_environment(cfg);

cfg.bitsi_scanner   = nan;
cfg.bitsi_buttonbox = nan;
if cfg.mriPulse == 1
    try
                delete(instrfind)

        cfg.bitsi_scanner   = Bitsi_Scanner('/dev/ttyS0');
        cfg.bitsi_buttonbox = Bitsi_Scanner('/dev/ttyS5');
        fprintf('Bitsi Scanner initialized\n')
        cfg.bitsi_scanner.clearResponses()
        cfg.bitsi_buttonbox.clearResponses()
    catch
     
        fprintf('Could not initialize bitsi\n')
    end
end
