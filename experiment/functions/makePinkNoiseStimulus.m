function [stimPinkNoise] = makePinkNoiseStimulus(cfg,params)


[~, Lmin_rgb, Lmax_rgb] = calibrate_lum(params.contrast, cfg.computer_environment,cfg.mri_scanner);
stimulusMatrix= pinkNoise2d(size(stim),-1);
rgb_range_up = Lmax_rgb - cfg.background;
rgb_range_down = cfg.background - Lmin_rgb;
rgb_range_up_down_ratio = rgb_range_up/rgb_range_down;
stimulusMatrix(stimulusMatrix > 0) = stimulusMatrix(stimulusMatrix > 0) * rgb_range_up_down_ratio;

% Make a fading annulus, to use as a mask.
annulusMatrix = makeLinearMaskCircleAnn(width+1,width+1,size_inner_most_circle,start_linear_decay,width/2);



stimulusMatrix = stimulusMatrix .* annulusMatrix;

%Make the grating
stimPinkNoise= cfg.background + rgb_range_down * stimulusMatrix;
