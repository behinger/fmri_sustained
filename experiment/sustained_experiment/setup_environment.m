function cfg = setup_environment(cfg)
assert(isfield(cfg,'computer_environment'))
assert(isfield(cfg,'mri_scanner'))

[cfg.background, cfg.Lmin_rgb, cfg.Lmax_rgb] = calibrate_lum(1, cfg.computer_environment,cfg.mri_scanner);
cfg.mriPulse = 0; % Flag to determine if we are going to wait for an MRI pulse before starting
% Gets turned to 1 if environment is MRI by default

% Monitor settings for each environment
switch cfg.computer_environment
    case 't480s'
        cfg.distFromScreen = 60;
        cfg.pixelsPerCm = 82.67;
    case 'work_station'
        cfg.distFromScreen = 68;
        cfg.pixelsPerCm = 33.7;
    case 'dummy'
        cfg.distFromScreen = 80;
        cfg.pixelsPerCm = 26.7;
        cfg.mriPulse = 1; % Flag for waiting for mriPulse
    case 'mri'
        switch cfg.mri_scanner
            case 'prisma'
                cfg.distFromScreen = 90;
            case 'essen'
                cfg.distFromScreen = 130;
        end
        cfg.pixelsPerCm = 27.74;
        cfg.mriPulse = 1; % Flag for waiting for mriPulse
    case 'behav'
        cfg.distFromScreen = 64;
        cfg.pixelsPerCm = 26.7;
end

end