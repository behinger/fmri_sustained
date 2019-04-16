%% function Essen_RunExperiment
% Run through experiment. Does numRuns runs of attention experiment
% and one run of orientation localizer.

% XXX: XXX
% retinotop: 11 x TR x 6 cycles = 230 = 4 min (too short?)
% Localizer: (2phases*6TR + 4waitTR) * 12 trials = 192 volumes = 6.16min
% with TR2.3
% Task: (2phases*6TR + 4WaitTR) * 12 trials = 192 volumes => ~6.16min with TR=2.3
%--------------------------------------------------------------------------
tic;
cfg = struct();

cfg.do_localizer = 1; % 4 runs
cfg.do_mainTask  = 1;
cfg.do_retinotopy= 0;

cfg.debug = 0; % Check debugmode

cfg.computer_environment = 'dummy'; % could be "mri", "dummy", "work_station", "behav"
cfg.mri_scanner = 'prisma'; % could be "trio", "avanto","prisma", "essen"

% 3T TR should be 3.2 or 3.8 (WB)
cfg.CAIPI = 1;
cfg = setup_parameters(cfg);


cfg.flicker.numRuns = 5; % Number of runs
cfg.flicker.numTrials = 12 ; % Number of trials in a run
cfg.localizer.numRuns = 2;
% blocks == trials
cfg.localizer.numBlocks = 12; % Total number of stimulus blocks (half as many per orientation)

cfg.writtenCommunication = 0;

fprintf('Setting up parameters \n')

if cfg.debug
    input('!!!DEBUGMODE ACTIVATED!!! - continue with enter')
    Screen('Preference', 'SkipSyncTests', 1)
         PsychDebugWindowConfiguration;
end





% Subject ID
if cfg.debug
    SID = '98';
else
    SID = input('Enter subject ID:','s');
end
assert(isnumeric(str2num(SID)))

try
    if cfg.debug
        % force randomization regen
        error
    end
    tmp = load(sprintf('randomizations/subject%s_variables.mat',SID));
    fprintf('Loading Randomization from disk\n')
    
catch
    fprintf('Generating Randomization\n')
    setup_randomization_generate(str2num(SID),cfg.flicker.numRuns,cfg.flicker.numTrials)
    tmp = load(sprintf('randomizations/subject%s_variables.mat',SID));
    
end
randomization = tmp.randomization; % just to be sure the import was successful

% change the number of generated stimuli to the randomization number
% this is a bit awkward here, but if we want balanced randomized phases we
% need to do it here.
cfg.flicker.phases = linspace(0,2*pi,1+length(unique(randomization.phase)));
cfg.flicker.phases = cfg.flicker.phases(1:end-1);


whichScreen = max(Screen('Screens')); %Screen ID
fprintf('Starting Screen\n')
cfg = setup_window(cfg,whichScreen);
% Run through attention runs
numRuns = sort(unique(randomization.run));

%% Do orientation localizer

toc
if cfg.do_localizer
    fprintf('Starting with localizer\n')
    Screen('Flip',cfg.win);
    for curRun = 1:cfg.localizer.numRuns
        experiment_localizerOrientation(cfg,randomization.subject(1),curRun);
    end
    fprintf('Localizer Done\n')
    waitQKey(cfg)
    
end
toc
if cfg.writtenCommunication
    communicateWithSubject(cfg.win,'',200,200,cfg.Lmin_rgb,cfg.background);
end
%% Do main Task
if cfg.do_mainTask
    fprintf('Starting with main Task')
    
    for curRun = numRuns % is a sorted list of runs
        fprintf('Run %i from %i \n',curRun,length(numRuns))
        fprintf('Drawing subject instructions\n')
        
        DrawFormattedText(cfg.win, 'Moving on to main task ...', 'center', 'center');
        
        fprintf('Starting experiment_adaptation\n')
        experiment_flicker_v2(cfg,slice_randomization(randomization,str2num(SID),curRun));
        
        if curRun < numRuns
            text = ['Moving on to run ', num2str(curRun+1), ' of ', num2str(numRuns), '...'];
            DrawFormattedText(cfg.win, text, 'center', 'center');
            Screen('Flip',cfg.win);
            waitQKey(cfg)
            
        end
        if cfg.writtenCommunication
            communicateWithSubject(cfg.win,'',200,200,cfg.Lmin_rgb,cfg.background);
        end
        toc
    end
    
end

%% Do retinotopy
if cfg.do_retinotopy
    fprintf('Starting with retinotopy')
    DrawFormattedText(cfg.win, 'Moving on to Retinotopy localizer...', 'center', 'center');
    Screen('Flip',cfg.win);
    waitQKey(cfg)
    experiment_retinotopy(cfg,randomization.subject(1))
end
% -----------------------------------------------------------------
% call function to close window and clean up
toc
safeQuit(cfg);
