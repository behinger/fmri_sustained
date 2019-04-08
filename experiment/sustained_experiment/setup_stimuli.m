function cfg = setup_stimuli(cfg,params)
assert(isfield(cfg,'win'))

assert(isstruct(params))

if ~isfield(params,'phases')
    fprintf('Putting stimulus-phase to 0!\n')
    params.phases = 0;
end
% Will need a different texture for each stimulus phase
cfg.stimTex = zeros(1,length(params.phases)); % Preallocate

for i = 1:length(params.phases)
    
    params.plaid = 0;
    params.phaseGrating = params.phases(i);
    
    stim = makeGaborStimulus(cfg,params);
    
    % catch stimulus with slightly higher spatial freq
    tmp = params.spatialFrequency;
    params.spatialFrequency = [params.spatialFrequency_catch];
    stimCatch = makeGaborStimulus(cfg,params);
    
    params.plaid = i;
    params.spatialFrequency = [params.spatialFrequency_catch params.spatialFrequency_catch];
    maskCatch = makeGaborStimulus(cfg,params);
    params.spatialFrequency = [tmp tmp];

    
    
    stimMask= makeGaborStimulus(cfg,params);
    params.spatialFrequency = [tmp];
    cfg.stimTex(i) = Screen('MakeTexture', cfg.win, stim);
    cfg.stimTexMask(i) = Screen('MakeTexture', cfg.win, stimMask);
    cfg.stimTexCatch(i) = Screen('MakeTexture', cfg.win, stimCatch);
    cfg.stimTexMaskCatch(i) = Screen('MakeTexture', cfg.win, maskCatch);
    
end

cfg.stimsize = size(stim);


% Preload textures into video memory
Screen('PreloadTextures',cfg.win,cfg.stimTex);
fprintf('Textures Preloaded \n')
