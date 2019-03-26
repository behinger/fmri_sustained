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
    params.radial = 0;
    params.plaid = 0;
    params.pinkNoiseFiltered = 0;
    params.phaseGrating = params.phases(i);
    params.contrast = 0.5;
    stim = makeGaborStimulus(cfg,params);
    
    % catch stimulus with slightly higher spatial freq
    tmp = params.spatialFrequency;
    params.spatialFrequency = params.spatialFrequency_catch;
    stimCatch = makeGaborStimulus(cfg,params);
    params.spatialFrequency = tmp;
    
    params.contrast = 1;
    %     params.radial = 1;
%     params.pinkNoiseFiltered = 1;
    params.plaid = i;
    stimMask= makeGaborStimulus(cfg,params);
    cfg.stimTex(i) = Screen('MakeTexture', cfg.win, stim);
    cfg.stimTexMask(i) = Screen('MakeTexture', cfg.win, stimMask);
    cfg.stimTexCatch(i) = Screen('MakeTexture', cfg.win, stimCatch);
end



% Preload textures into video memory
Screen('PreloadTextures',cfg.win,cfg.stimTex);
fprintf('Textures Preloaded \n')
