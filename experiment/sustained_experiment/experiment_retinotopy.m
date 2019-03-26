function [] = experiment_retinotopy(cfg,subjectid)
% RingsOrWedges - Expanding Rings (1), Contracting Rings (2), Wedges (3)
% numCycles - how many times the stimulus should repeat
%
% This version will include a colour change detection task at fixation
%

params = cfg.retinotopy;

% ---------------------------------------------------------------------------

outFile = fullfile('.','MRI_data',sprintf('s%i',subjectid), sprintf('RETINO_MRI_S%d.mat',subjectid));
mkdir(fileparts(outFile))



%--------------------------------------------------------------------------
% Set up queue for recording button presses
setup_kbqueue(0,params); % 0 = deviceID

%--------------------------------------------------------------------------

% Open a full screen cfg.win
%%
% Set timing durations (depends on 60Hz monitor)

% ---------------------------------------------------------------------------
% Define basic parameters
% length of side of square stimulus matrix
% Not using pixelsPerCm here, degrees2pixels will measure this for itself.
% Seems more flexible in case of resolution differences.
size = degrees2pixels(params.stimSize,cfg.distFromScreen, cfg.pixelsPerCm);
numRings = (4)*2; % how many ring pairs are shown - change the (4) bit
% (1 ring pair = sinusoid between 0 and 2pi, i.e. white then black)
numSegments = 24; % how many segments a ring is split into

% Calculate properties of an individual segment
angSeg = (2*pi)/numSegments; % angle of a segement (think theta)
lenSeg = pi; % length of a segment (think rho)

% ---------------------------------------------------------------------------
% First, create checkerboard pattern

% [Note, will be using 1 = white, -1 = black, 0 = gray]

% generate a grid with the correct range
[x,y] = meshgrid(linspace(-(numRings*pi),(numRings*pi),size));
% turn this into polar co-ordinates
[theta,rho] = cart2pol(x,y);

% adjust theta so that it's in a nicer range
theta = rot90(theta,-1);
theta = fliplr(theta + pi);

% transform the polar co-ordinates into sine patterns
% (rho becomes rings, theta becomes 'star' shaped)
sinRho = sin(rho);
sinTheta = sin((numSegments/2)*theta);

% combine and turn to 1s and -1s
rcPattern = sign(sinRho.*sinTheta);

% cast into signed integer
rcPattern = int8(rcPattern);

% Outer boundary never needed, so set that to gray now
% (i.e. everything outside the last complete ring = gray)
rcPattern(rho > (numRings*pi)) = 0;

% ---------------------------------------------------------------------------
% Generate the full set of textures (and  then inversed textures)

switch params.RingsOrWedges
    case 1 % Expanding Rings
        Tex = zeros(size,size,numRings,'int8');
        nRings = 3; % how many rings to show at once
        numTex = numRings; % how many textures there'll be in total
        for i = 1:numRings
            tempPat = rcPattern;
            tempPat(rho <= (i-1)*lenSeg & rho > (i-1-(numRings-nRings))*lenSeg) = 0;
            tempPat(rho > (i+(nRings-1))*lenSeg) = 0;
            Tex(:,:,i) = tempPat;
        end
    case 2 % Contracting Rings
        Tex = zeros(size,size,numRings,'int8');
        nRings = 3; % how many rings to show at once
        numTex = numRings; % how many textures there'll be in total
        for i = 1:numRings
            tempPat = rcPattern;
            tempPat(rho > (numRings-(i-1))*lenSeg & rho <= ((2*numRings)-((i-1)+nRings))*lenSeg) = 0;
            tempPat(rho <= (numRings-(nRings+(i-1)))*lenSeg) = 0;
            Tex(:,:,i) = tempPat;
        end
    case 3 % Wedges
        Tex = zeros(size,size,numSegments,'int8');
        nSeg = 6; % how many segments to show at once
        numTex = numSegments; % how many textures there'll be in total
        for i = 1:(numSegments)
            tempPat = rcPattern;
            tempPat(theta <= (i-1)*angSeg & theta > (i-1-(numSegments-nSeg))*angSeg) = 0;
            tempPat(theta > (i+(nSeg-1))*angSeg) = 0;
            Tex(:,:,i) = tempPat;
        end
end

% create polarity reversed textures
invTex = Tex .* -1;

% change ranges from [-1 0 +1] to [0 background 255]
Tex = uint8(Tex+1) .* cfg.background;
invTex = uint8(invTex+1) .* cfg.background;

% calculate how long each texture should be shown for
numRev = round((params.cycleTime/numTex)*params.flickerRate); % how many contrast reversals should there be per texture
texDur = params.cycleTime/numTex/numRev/2; % time to show each texture in seconds

% ---------------------------------------------------------------------------
% get textures ready for presentation

% Generate the indices of the textures that need to be drawn on the screen
TexInd = zeros(1,numTex);
invTexInd = zeros(1,numTex);
for i = 1:numTex
    TexInd(i) = Screen('MakeTexture',cfg.win,Tex(:,:,i));
    invTexInd(i) = Screen('MakeTexture',cfg.win,invTex(:,:,i));
end

% Preload the textures to VRAM
Screen('PreloadTextures',cfg.win,[TexInd invTexInd]);


% ---------------------------------------------------------------------------
% Determine when fixation will change colour
numStim = params.numCycles*numTex*numRev; % Total number of stimuli
fixReversals = zeros(1,numStim);
howOftenToReverse = 30; % Colour will change numStim / n times
fixReversals(randperm(howOftenToReverse,1)) = 1;
for i = howOftenToReverse:howOftenToReverse:numStim-howOftenToReverse
    fixReversals(randperm(howOftenToReverse,1)+i) = 1;
end
reversalInd = find(fixReversals == 1);
fixColour = ones(1,numStim);
for i = 1:2:length(reversalInd)
    try
        fixColour(reversalInd(i):reversalInd(i+1)) = 2;
    catch
        fixColour(reversalInd(i):end) = 2;
    end
end

% ===========================================================================
% about to draw stuff...

% Wait for mouse click before starting
clicks = 0;
fprintf('Drawing Instructions\n')
instructions = 'Look towards the cross in the centre of the screen at all times\n\nPress the button with your index finger when the cross changes colour\n\nRun length: 5 minutes';
Screen('FillRect', cfg.win,cfg.background);
Screen('DrawText',cfg.win,'Waiting for mouse click...', 100, 100);
DrawFormattedText(cfg.win, instructions, 'center', 'center');
Screen('Flip',cfg.win);
draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
fprintf('Instructions: waiting for mouse click (waiting for ScanTrigger after this)...')
while clicks < 1
    clicks = GetClicks(cfg.win);
end
fprintf('..click\n')

% wait for scanner trigger if doing that
if cfg.mriPulse == 1
    Screen('DrawText',cfg.win,'Waiting for mri pulse...', 100, 100);
    Screen('Flip',cfg.win);
    % get crosshair ready for next flip
    draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
    waitForScanTrigger_KB;
end

% start the clock
tic;

% wait for scanner to 'warm up' (typically e.g. 9 or 10 sec)
startTime = Screen('Flip',cfg.win);
draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
expectedTime = startTime + params.scannerWaitTime;
Screen('Flip',cfg.win,expectedTime - cfg.halfifi);
expectedTime = expectedTime - texDur; % so don't wait to show first texture

% Start recording key presses
KbQueueStart;

% draw the stimuli
stimNum = 1; % Will be used to track which stimulus we are on
for i = 1:params.numCycles % do all this once for every complete cycle
    fprintf('Retinotopy cycle %i / %i \n',i,params.numCycles)
    for j = 1:numTex % do this once for each individual texture (e.g wedge segment)
        for k = 1:numRev % do this once for every contrast reversal
            expectedTime = expectedTime + texDur; % so don't wait to show first texture
            Screen('DrawTexture',cfg.win,TexInd(j));
            switch fixColour(stimNum)
                case 1
                    draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
                case 2
                    draw_fixationdot(cfg,params.dotSize,0);
            end
            Screen('Flip',cfg.win,expectedTime + cfg.halfifi);
            
            expectedTime = expectedTime + texDur; % so don't wait to show first texture
            Screen('DrawTexture',cfg.win,invTexInd(j));
            switch fixColour(stimNum)
                case 1
                    draw_fixationdot(cfg,params.dotSize,0,params.flickerColor*cfg.Lmax_rgb)
                case 2
                    draw_fixationdot(cfg,params.dotSize,0);
            end
            Screen('Flip',cfg.win,expectedTime + cfg.halfifi);
            % Increment stimNum
            stimNum = stimNum + 1;
            % Safe quit mechanism (hold q to quit)
            [keyPr,~,key,~] = KbCheck;
            key = find(key);
            if keyPr == 1 && strcmp(KbName(key(1)),'q')
                Screen('CloseAll');
                try
                    jheapcl;
                end
                disp('Quit safely');
                return
            end
        end
    end
end
% make sure last texture shown for appropriate length of time
expectedTime = expectedTime + texDur; % so don't wait to show first texture
Screen('Flip',cfg.win,expectedTime - cfg.halfifi);

% count how many times subject pressed a button
% Check how many flickers there were
[press, nremaining] = KbEventGet;
% Check how many button presses
% /2 because one press = 2 bytes - round just in case we get an
% error from an odd number of bytes on the line, but that shouldn't
% happen.
numPresses = round((nremaining + 1)/2);
numReversals = length(reversalInd);
if numPresses < numReversals
    hits = numPresses;
    misses = numReversals - numPresses;
    falseAlarms = 0;
elseif numPresses > numReversals
    hits = numReversals;
    falseAlarms = numPresses - numReversals;
    misses = 0;
else
    hits = numPresses;
    misses = 0;
    falseAlarms = 0;
end

% end the clock and print time on screen
toc
disp(['(Should be ' num2str((params.numCycles*params.cycleTime)+params.scannerWaitTime) ' seconds)']);

% Save results
save(outFile, 'reversalInd', 'numReversals', 'numPresses', 'hits', 'misses', 'falseAlarms','cfg','subjectid');


try
    jheapcl;
end

end