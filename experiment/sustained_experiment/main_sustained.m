%% function Essen_RunExperiment
% Run through experiment. Does numRuns runs of attention experiment
% and one run of orientation localizer.

% XXX: XXX
% MAin Task: TR 1.5,    234 images
% Localizer: TR 1.5,    226 images

%--------------------------------------------------------------------------
tic;
cfg = struct();

cfg.do_localizer = 1; % 
cfg.do_mainTask  = 1;
cfg.do_retinotopy= 0;

cfg.debug = 1; % Check debugmode

cfg.computer_environment = 'mri'; % could be "mri", "dummy", "work_station", "behav"
cfg.mri_scanner = 'prisma'; % could be "trio", "avanto","prisma", "essen"

cfg.TR = 2.336; % CAIPI sequence Essen

% cfg.TR = 1.500; % 213 image volumes to be recorded
    
% cfg.TR = 3.408; % TR will determine stimulus timings




cfg = setup_parameters(cfg);

cfg.flicker.numRuns = 6; % Number of runs
cfg.flicker.numTrials = 12 ; % Number of trials in a run
cfg.localizer.numRuns = 2;
% blocks == trials
cfg.localizer.numBlocks = 10; % Total number of stimulus blocks (half as many per orientation)


fprintf('Volumes to record Main Task: %.2f\n',((cfg.flicker.ITI + cfg.flicker.trialLength)*cfg.flicker.numTrials+cfg.flicker.scannerWaitTime)/cfg.TR)
fprintf('Volumes to record Local: %.2f\n',((cfg.localizer.ITI + cfg.localizer.trialLength)*cfg.localizer.numBlocks+cfg.localizer.scannerWaitTime)/cfg.TR)

%%



cfg.writtenCommunication = 1;

fprintf('Setting up parameters \n')

if cfg.debug
    input('!!!DEBUGMODE ACTIVATED!!! - continue with enter')
    Screen('Preference', 'SkipSyncTests', 1)
%          PsychDebugWindowConfiguration;
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
        if cfg.writtenCommunication
            communicateWithSubject(cfg.win,'',200,200,cfg.Lmin_rgb,cfg.background);
        end
    end
    fprintf('Localizer Done\n')
    waitQKey(cfg)
    
end
toc
%% Do main Task
if cfg.do_mainTask
    fprintf('Starting with main Task')
    
    for curRun = numRuns % is a sorted list of runs
        fprintf('Run %i from %i \n',curRun,length(numRuns))
        fprintf('Drawing subject instructions\n')
        
        DrawFormattedText(cfg.win, 'Moving on to main task ...', 'center', 'center');
        
        fprintf('Starting experiment_adaptation\n')
        experiment_flicker_v2(cfg,slice_randomization(randomization,str2num(SID),curRun));
        
        if curRun < max(numRuns)
            text = ['Moving on to run ', num2str(curRun+1), ' of ', num2str(max(numRuns)), '...'];
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
