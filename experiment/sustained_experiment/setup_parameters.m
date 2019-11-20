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
cfg.sustained = struct();
cfg.sustained.stimSize = 12; % Diameter in degrees
cfg.sustained.refOrient = [45, 135]; % orientations for stimuli are 45 and 135 degrees
cfg.sustained.spatialFrequency = 1; % cpd
cfg.sustained.phases = linspace(0,2*pi,25);
cfg.sustained.phases(end) = []; %delete last one as 0 = 2*pi
cfg.sustained.spatialFrequency_catch = 1.25;

cfg.sustained.contrast = 1; % max contrast
cfg.sustained.start_linear_decay_in_degree = 0.5;


cfg.sustained.trialLength = 8;
cfg.sustained.trialLengthfullTR = ceil(8/cfg.TR)*cfg.TR; %
cfg.sustained.scannerWaitTime = cfg.TR * 3; % Time to wait after scan pulse - must be multiple of TR


% cfg.sustained.stimdur.sustained = cfg.sustained.trialLength; % test 
% cfg.sustained.stimdur.interrupt_slow = [0.1,0.4]; % stim vs. break
% cfg.sustained.stimdur.interrupt_fast = [0.1,0.1]; % stim vs. mask


cfg.sustained.ITI = round(14/cfg.TR)*cfg.TR;%2*cfg.TR;

cfg.sustained.dotSize = 1.5*[0.25 0.06]; % Size of fixation dot in pixels
% cfg.sustained.increment = 0.25; % Increment to increase thresholds by

cfg.sustained.targetsPerTrial = 1.5; % on average we will have 1.5 flicker per Trial
cfg.sustained.targetsTimeDelta = 2;%s flicker have to be at least distance of 2s
cfg.sustained.targetsColor = 0.4; % percent
cfg.sustained.targetsDuration = 0.1;% flicker for 100ms



cfg.localizer = cfg.sustained;
cfg.localizer.orientation = [45 135];


cfg.localizer.stimBlockLength = round(16/cfg.TR)*cfg.TR; %
cfg.localizer.offBlockLength = round(122/cfg.TR)*cfg.TR; %

cfg.localizer.scannerWaitTime = cfg.TR * 4; % Time to wait after scan pulse - must be multiple of TR
    
cfg.localizer.stimPerBlock = round(cfg.localizer.stimBlockLength * 2); % Present stimuli at 2Hz (ish)

cfg.localizer.stimPres = cfg.localizer.stimBlockLength/(cfg.localizer.stimPerBlock*2); % Time individual stimulus is on for
cfg.localizer.ISI = cfg.localizer.stimPres; % Time between stimuli
cfg.localizer.phases = [pi, 2*pi]; % Will alternate phase, phases are chosen so that the fixation dot is always visible

cfg.localizer.sustainedPerTrial = 2; % on average we will have 4 flicker per block
cfg.localizer.sustainedTimeDelta = 1;%s flicker have to be at least distance of 2s
cfg.localizer.sustainedColor = 0.4; % percent
cfg.localizer.sustainedDuration = 0.1;% flicker for 100ms

cfg.retinotopy = cfg.sustained();
cfg.retinotopy.sustainedRate = 6; % set flicker rate, in Hz (i.e. 2 textures every xHz)

cfg.retinotopy.cycleTime = round(35/cfg.TR)*cfg.TR; %

cfg.retinotopy.scannerWaitTime = cfg.TR * 3; % Time to wait after scan pulse - must be multiple of TR
    
cfg.retinotopy.sustainedColor = 1;

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
