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
    
    stim = makeStimulus(cfg,params);

    
    cfg.stimTex(i) = Screen('MakeTexture', cfg.win, stim);
    tmp = params;
    tmp.plaid = 1;
    stimPlaid = makeStimulus(cfg,tmp);
    cfg.stimTexPlaid(i) = Screen('MakeTexture',cfg.win,stimPlaid);
%     tmp.pinkNoise = 1;
%     stimPinkNoise = makeStimulus(cfg,tmp);



    
%     cfg.stimTexPinkNoise(i) = Screen('MakeTexture',cfg.win,stimPinkNoise);
    
end
stimMask= stim;
stimMask(:) = cfg.background;
cfg.stimTexMask = Screen('MakeTexture', cfg.win, stimMask);


cfg.stimsize = size(stim);


% Preload textures into video memory
Screen('PreloadTextures',cfg.win,cfg.stimTex);
fprintf('Textures Preloaded \n')
