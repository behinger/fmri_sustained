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
    params.phaseGrating = params.phases(i);
    stim = makeGaborStimulus(cfg,params);
    cfg.stimTex(i) = Screen('MakeTexture', cfg.win, stim);
end

% Preload textures into video memory
Screen('PreloadTextures',cfg.win,cfg.stimTex);
fprintf('Textures Preloaded \n')
