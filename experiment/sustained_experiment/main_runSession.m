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
cfg.numRuns = 1; % Number of runs
cfg.numTrials = 12 ; % Number of trials in a run
cfg.numRuns_localizer = 1;
cfg.writtenCommunication = 0;

fprintf('Setting up parameters \n')

if cfg.debug
    input('!!!DEBUGMODE ACTIVATED!!! - continue with enter')
    Screen('Preference', 'SkipSyncTests', 1)
%      PsychDebugWindowConfiguration;
end


cfg = setup_parameters(cfg);



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
    setup_randomization_generate(str2num(SID),cfg.numRuns,cfg.numTrials)
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
if cfg.debug
    
    %limit to 8 trials in debugmode
    ix = randomization.trial <=8;
    for fn = fieldnames(randomization)'
        randomization.(fn{1}) = randomization.(fn{1})(ix);
    end
    numRuns = 2; % also limit to 2 runs.
    % => 3.5* 4 * 8 * 2 = 4min total testing time for main experiment
    cfg.flicker.scannerWaitTime = 1;
    cfg.flicker.ITI = 5;

end


%% Do orientation localizer

toc
if cfg.do_localizer
    fprintf('Starting with localizer\n')
    Screen('Flip',cfg.win);
    for curRun = 1:cfg.numRuns_localizer
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
