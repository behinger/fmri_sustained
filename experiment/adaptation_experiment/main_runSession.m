% function Essen_RunExperiment
% Run through experiment. Does numRuns runs of attention experiment
% and one run of orientation localizer.

% adapt: 40 Trials x 4*TR (3.504s) x 6 runs  = 3363s = 56min
% retinotop: 11 x TR x 6 cycles = 230 = 4 min (too short?)
% localizer: 30 x 4*TR = 360 = 6 min
%
%--------------------------------------------------------------------------
cfg = struct();
cfg.do_localizer = 0;

cfg.do_mainTask  = 1;
cfg.do_retinotopy= 1;
cfg.CAIPI = 1;

cfg.debug = 0; % Check debugmode
if cfg.debug
    input('!!!DEBUGMODE ACTIVATED!!! - continue with enter')
     PsychDebugWindowConfigur5ation;
end

cfg.computer_environment = 'mri'; % could be "mri", "dummy", "work_station", "behav"
cfg.mri_scanner = 'essen'; % could be "trio", "avanto","prisma", "essen"

fprintf('Setting up parameters \n')
cfg = setup_parameters(cfg);


% Subject ID
SID = input('Enter subject ID:','s');
assert(isnumeric(str2num(SID)))
try
tmp = load(sprintf('randomizations/subject%s_variables.mat',SID));
    fprintf('Loading Randomization from disk\n')

catch
    fprintf('Generating Randomization\n')
    setup_randomization_generate(str2num(SID))
    tmp = load(sprintf('randomizations/subject%s_variables.mat',SID));

end
randomization = tmp.randomization; % just to be sure the import was successful


whichScreen = max(Screen('Screens')); %Screen ID
fprintf('Starting Screen\n')
cfg = setup_window(cfg,whichScreen);
% Run through attention runs
numRuns = sort(unique(randomization.run));
if cfg.debug
    
    %limit to 8 trials in debugmode
    ix = randomization.trial <=4;
    for fn = fieldnames(randomization)'
        randomization.(fn{1}) = randomization.(fn{1})(ix);
    end
    numRuns = 2; % also limit to 2 runs.
    % => 3.5* 4 * 8 * 2 = 4min total testing time for main experiment
    
end


%% Do orientation localizer


if cfg.do_localizer
    fprintf('Starting with localizer\n')
    Screen('Flip',cfg.win);
    experiment_localizerOrientation(cfg,randomization.subject(1));
    fprintf('Localizer Done\n')
    waitQKey

end
communicateWithSubject(cfg.win,'',200,200,cfg.Lmin_rgb,cfg.background);

%% Do main Task
if cfg.do_mainTask
    fprintf('Starting with main Task')
    
    for curRun = 4 %numRuns % is a sorted list of runs 
        fprintf('Run %i from %i \n',curRun,length(numRuns))
        fprintf('Drawing subject instructions\n')

        DrawFormattedText(cfg.win, 'Moving on to main task ...', 'center', 'center');
        
        fprintf('Starting experiment_adaptation\n')
        experiment_adaptation(cfg,slice_randomization(randomization,str2num(SID),curRun));
        
        if curRun < numRuns
            text = ['Moving on to run ', num2str(curRun+1), ' of ', num2str(numRuns), '...'];
            DrawFormattedText(cfg.win, text, 'center', 'center');
            Screen('Flip',cfg.win);
            waitQKey
            
        end
            communicateWithSubject(cfg.win,'',200,200,cfg.Lmin_rgb,cfg.background);

    end

end

%% Do retinotopy
if cfg.do_retinotopy
    fprintf('Starting with retinotopy')
    DrawFormattedText(cfg.win, 'Moving on to Retinotopy localizer...', 'center', 'center');
    Screen('Flip',cfg.win);
    waitQKey
    experiment_retinotopy(cfg,randomization.subject(1))
end
% -----------------------------------------------------------------
% call function to close window and clean up

safeQuit;

function safeQuit

% Close window
Screen('Close');
Screen('Closeall');
%
% Clean up
try
    jheapcl; % clean the java heap space
catch
    disp('Could not clean java heap space');
end

disp('Quit safely');
end

function waitQKey
fprintf('press Q to safequit ... ')

for waitTime = 1:5
    fprintf('%i..',waitTime)
    % Safe quit routine - hold q to quit
    WaitSecs(1);
    [keyPr,~,key,~] = KbCheck;
    key = find(key);
    if keyPr == 1 && strcmp(KbName(key(1)), 'q')
        inp = input('Are you sure you want to quit the MAIN experiment (y/n)','s');
        if strcmp(inp,y)
        safeQuit;
        return
        end
    end
    
end
fprintf(' - SafeQuit End \n')

end
% end