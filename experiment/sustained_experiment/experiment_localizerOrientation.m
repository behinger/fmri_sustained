function experiment_localizerOrientation(cfg,subject)
% Run localiser to identify voxels with preference for 45 or 135 degree
% orientations.
%
% Alternate between blocks of 45deg and 135deg gratings, with fixation
% blocks in between. Flicker grating on and off during block. Luminance
% detection task at fixation throughout.
%
% 13/10/2016 SJDL wrote it.
%
% 02/11/2016 V2 edit - timings adjusted for TR = 1050ms, also stimuli
% smoothed with Gaussian kernel (SD = 1 pixel) to soften hard edges
%
% 03/11/2016 V3 edit = using a different function to generate stimuli that
% smoothes the edges of the stimulus.
%
% Essen version designed to run in Essen, has longer TR
%
% 01/05/2017 V5 edit - designed to be called by another script that
% iterates through runs, so we don't have to enter expt info and relaunch
% between every run.


%--------------------------------------------------------------------------
% Set up queue for recording button presses

%--------------------------------------------------------------------------

outFile = fullfile('.','MRI_data',sprintf('s%i',subject), sprintf('LOCALIZER_MRI_S%d.mat',subject));
mkdir(fileparts(outFile))
Screen('FillRect', cfg.win, cfg.background);

%--------------------------------------------------------------------------
% Generate stimulus textures
Screen('DrawText',cfg.win,'Generating textures...', 100, 100);
Screen('Flip',cfg.win);
params = cfg.localizer;
cfg = setup_stimuli(cfg,params);
%--------------------------------------------------------------------------
setup_kbqueue(0,params); % 0 = deviceID

%--------------------------------------------------------------------------
% Preallocate some variables for storing information
misses = 0;
hits = 0;

%--------------------------------------------------------------------------
% Wait for mouse click to begin
clicks = 0;
Screen('FillRect',cfg.win,cfg.background);
fprintf('Drawing Instructions \n')
instructions = 'Look towards the dot in the centre of the screen at all times\n\nPress the button with your index finger when this dot flashes\n\nRun length: 10 minutes';
Screen('DrawText',cfg.win,'Waiting for mouse click...', 100, 100);
DrawFormattedText(cfg.win, instructions, 'center', 'center');
Screen('Flip',cfg.win);

fprintf('Instructions: waiting for mouse click (waiting for ScanTrigger after this)')
while clicks < 1
    clicks = GetClicks(cfg.win);
end
fprintf('... click \n')
%--------------------------------------------------------------------------
% Flicker randomization
[flickers45,flickers45Timings,flickers135,flickers135Timings,flickersOff,flickersOffTimings] = setup_flickertimings_localizer(params);

%--------------------------------------------------------------------------
% Wait to detect first scanner pulse before starting experiment
if cfg.mriPulse == 1
    Screen('DrawText',cfg.win,'Waiting for mri pulse...', 100, 100);
    Screen('Flip',cfg.win);
    waitForScanTrigger_KB;
end



%--------------------------------------------------------------------------
% MAIN TRIAL LOOP

% Begin presenting stimuli
cfg.phases = repmat([1, 2], 1, round(params.stimPerBlock/2));%+1); % For indexing stimulus phase % +1 to avoid crashes when odd number of stim per block
% Start with fixation cross
draw_fixationdot(cfg,params.dotSize)
startTime = Screen('Flip',cfg.win); % Store time experiment started
expectedTime = 0; % This will record what the expected event duration should be

% Start recording key presses
KbQueueStart;

for blockNum = 1:params.numBlocks
    fprintf('Localizer (%i/%i):',blockNum,params.numBlocks)
    for stimNum = 1:params.stimPerBlock
        % Check for button presses in previous off block
        % (if on first stim of not the first block)
        if blockNum > 1 && stimNum == 1
            checkFixationResponse(2, blockNum - 1);
        end
        
        fprintf(',%i',stimNum)
        % Stimulus Block
        % If on first stim of first block need to wait for scanner wait time
        if blockNum == 1 && stimNum == 1
            expectedTime = expectedTime + params.scannerWaitTime;
        elseif stimNum == 1
            % If on first stim of this block need to wait for fixation block
            % length
            % Need to calculate how much time we spent on flickers and wait
            % the remainder of offBlockLength
            expectedTime = expectedTime + params.offBlockLength - (params.ISI+flickersOffTimings{blockNum-1}(end));
        else % Otherwise just wait for ISI
            expectedTime = expectedTime + params.ISI;
        end
        
        %
        % Present first stimulus
        % 135deg if on even block
        if mod(blockNum,2) == 0
            Screen('DrawTexture', cfg.win, cfg.stimTex(cfg.phases(stimNum)), [], [], params.orientation(2));
        else % Otherwise 45deg
            Screen('DrawTexture', cfg.win, cfg.stimTex(cfg.phases(stimNum)), [], [], params.orientation(1));
        end
        
        draw_fixationdot(cfg,params.dotSize)
        Screen('DrawingFinished', cfg.win);
        Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);
        
        
        
        % Return to fixation after stimulus presentation time
        expectedTime = expectedTime + params.stimPres;
        % Find out if fixation should be changing this trial
        if mod(blockNum,2) == 0 % Even blocks, 135deg
            if find(flickers135Timings{round(blockNum/2)} == stimNum) >= 1
                draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
            else
                draw_fixationdot(cfg,params.dotSize,0,0)
                
            end
        else % Odd blocks, 45deg
            if find(flickers45Timings{round(blockNum/2)} == stimNum) >= 1
                draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
            else
                draw_fixationdot(cfg,params.dotSize,0,0)
            end
        end
        Screen('DrawingFinished', cfg.win);
        Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);
        
        % Safe quit mechanism (hold q to quit)
        [keyPr,~,key,~] = KbCheck;
        % && instead of & causes a crash here, for some reason - some
        % interaction with keyboard queue, I think
        if keyPr == 1 & any(strcmp(KbName(key),'q'))
            save_and_quit;
            return
        end
    end
    
    % During off blocks, flicker fixation when we are supposed to
    for fl = 1:length(flickersOffTimings{blockNum})
        if fl == 1
            expectedTime = expectedTime + params.ISI + flickersOffTimings{blockNum}(fl);
        else
            expectedTime = expectedTime + (flickersOffTimings{blockNum}(fl) - (flickersOffTimings{blockNum}(fl-1) + params.ISI));
        end
        draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
        Screen('DrawingFinished', cfg.win);
        Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);
        
        if fl == 1
            % At this point check for button presses in previous stim block
            checkFixationResponse(1, blockNum);
        end
        % Flick back after .25s (equal to ISI)
        expectedTime = expectedTime + params.ISI;
        draw_fixationdot(cfg,params.dotSize,0,0)
        Screen('DrawingFinished', cfg.win);
        Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);  
    end
end

% Make sure we wait for last fixation block before stopping
expectedTime = expectedTime + params.offBlockLength - (flickersOffTimings{blockNum}(end) + params.ISI);
endTime = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);

% Check for button presses for last off block
checkFixationResponse(2, blockNum);

Priority(0); % Reset priority

disp(['Time elapsed was ',num2str(endTime - startTime),' seconds']);
disp(['(Should be ',num2str(expectedTime),' seconds)']);

% -----------------------------------------------------------------
% call function to save results, close cfg.win and clean up

save_and_quit;

    function save_and_quit
        
        % Save results
        save(outFile, 'flickers45Timings', 'flickers135Timings', 'flickersOffTimings', 'hits', 'misses');
        try
            jheapcl; % clean the java heap space
        catch
            disp('Could not clean java heap space');
        end
        
        % Close keyboard queue
        KbQueueStop;
        KbQueueRelease;
        
        disp('Quit safely');
    end

% Function for checking button presses
    function checkFixationResponse(blockType,blockInd)
        
        % For blockType, 1 = stim block and 2 = off block
        
        % Check how many flickers there were
        if blockType == 1 % Stimulus block
            if mod(blockInd,2) == 0 % 135 degrees
                numFlickers = length(flickers135Timings{round(blockInd/2)});
            else % 45 degrees
                numFlickers = length(flickers45Timings{round(blockInd/2)});
            end
        elseif blockType == 2 % Off block
            numFlickers = length(flickersOffTimings{blockInd});
        end
        
        % Check how many button presses
        % KbEventGet records the oldest event and stores how many are
        % remaining, so will determine number of responses as number
        % remaining plus one (to include the one recorded by calling
        % EventGet) over two (because both key press and release is
        % recorded)
        [press, nremaining] = KbEventGet;
        if isempty(press)
            numPresses = 0;
        else
            numPresses = round((nremaining + 1)/2);
            
        end
        misses_thisTrial = numFlickers - numPresses;
        hits_thisTrial = numFlickers - misses_thisTrial;
        
        % Update hit and miss counters
        hits = hits + hits_thisTrial;
        misses = misses + misses_thisTrial;
        if blockType ~=2
            fprintf(' hits:%i, misses:%i\n',hits,misses)
        end
        % Flushing the queue doesn't seem to do anything, going to close
        % and it open a new one for next time. Presumably this is more
        % efficient than reading each event off the queue one by one in a
        % loop until it is empty...
        setup_kbqueue(0,params);
        KbQueueStart;
    end
end