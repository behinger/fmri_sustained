function gaborPatch = makeGaborStimulus(cfg,params)
% spatialFrequency: cycles/degree
% samlaw V2 edit 30/03/2017 - inner_degree and start_linear_decay_in_degree
% now input arguments

assert(all(isfield(params,{'contrast','stimSize','phaseGrating','spatialFrequency','start_linear_decay_in_degree'})))

[~, Lmin_rgb, Lmax_rgb] = calibrate_lum(params.contrast, cfg.computer_environment,cfg.mri_scanner);

width = degrees2pixels(params.stimSize, cfg.distFromScreen, cfg.pixelsPerCm);
inner_degree=cfg.flicker.dotSize(1)*0.8;

size_inner_most_circle = degrees2pixels(inner_degree, cfg.distFromScreen, cfg.pixelsPerCm);
start_linear_decay = degrees2pixels(params.start_linear_decay_in_degree, cfg.distFromScreen,cfg.pixelsPerCm);

nCycles = params.stimSize.*params.spatialFrequency; % number of cycles in a stimulus

% compute the pixels per grating period
pixelsPerGratingPeriod = width ./ nCycles;

spatialFrequency = 1 ./ pixelsPerGratingPeriod; % How many periods/cycles are there in a pixel?
radiansPerPixel = spatialFrequency .* (2 * pi); % = (periods per pixel) * (2 pi radians per period)



halfWidthOfGrid = width / 2;
widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  % widthArray is used in creating the meshgrid.

% Creates a two-dimensional square grid.  For each element i = i(x0, y0) of
% the grid, x = x(x0, y0) corresponds to the x-coordinate of element "i"
% and y = y(x0, y0) corresponds to the y-coordinate of element "i"
[x y] = meshgrid(widthArray);


if isfield(params,'radial')&& params.radial
    
    dist = sqrt(x.^2+y.^2);
    
    stimulusMatrix = sin(radiansPerPixel*dist+params.phaseGrating);
elseif isfield(params,'pinkNoiseFiltered')&&params.pinkNoiseFiltered
    %%
    dist = sqrt(x.^2+y.^2);
    p = rand(size(dist))*2*pi;
    stimulusMatrix = real(ifft2(fftshift(dist>nCycles-1&dist<nCycles+1).*exp(1i*p)));
    %     d = zeros(size(dist));
    
    %     d(514,531) = 1;
    %     d(531,531) = 1;
    %     d(531,514) = 1;
    %     d(514,514) = 1;
    
    %     stimulusMatrix = real(ifft2(fftshift(d).*exp(1i*p)));
    
    stimulusMatrix = stimulusMatrix - min(stimulusMatrix(:));
    
    stimulusMatrix = stimulusMatrix./max(stimulusMatrix(:)); % between 0 and 1
    stimulusMatrix = stimulusMatrix.*2 - 1; %between -1 and 1
    
    %         figure,imagesc(stimulusMatrix)
elseif isfield(params,'plaid') && params.plaid>0
    % params.plaid contains an integer from 1:length(params.phases), we
    % want to generate alle possible combinations in a
%     tmp = sqrt(length(params.phases));
%     phase_x = linspace(0,2*pi,floor(tmp)+1);
%     phase_x = phase_x(1:end-1);
%     phase_y = linspace(0,2*pi,ceil(tmp)+1);
%     phase_y = phase_y(1:end-1);
%     [phase_x,phase_y] = meshgrid(phase_x,phase_y);
    
%     assert(length(phase_x(:))==length(params.phases))
%     stimulusMatrix = (sin(radiansPerPixel * x+phase_x(params.plaid)) + sin(radiansPerPixel*y+phase_y(params.plaid)))/2;

    stimulusMatrix = (sin(radiansPerPixel(1) * x+params.phaseGrating+pi) + sin(radiansPerPixel(2)*y+params.phaseGrating+pi))/2;
    
else
    % Creates a sinusoidal grating, where the period of the sinusoid is
    % approximately equal to "pixelsPerGratingPeriod" pixels.
    % Note that each entry of gratingMatrix varies between minus one and
    % one; -1 <= gratingMatrix(x0, y0)  <= 1
    
    % the grating is oriented vertically unless otherwise specified.
    
    stimulusMatrix = sin(radiansPerPixel * x + params.phaseGrating);
    
end
% Because the difference between Lmax_rgb and background is not equal to
% the difference between Lmin_rgb and background (the differences are equal
% in luminance, but not in rgb), correct the range of the positive values
% of stimulusMatrix.
rgb_range_up = Lmax_rgb - cfg.background;
rgb_range_down = cfg.background - Lmin_rgb;
rgb_range_up_down_ratio = rgb_range_up/rgb_range_down;
stimulusMatrix(stimulusMatrix > 0) = stimulusMatrix(stimulusMatrix > 0) * rgb_range_up_down_ratio;

% Make a fading annulus, to use as a mask.
annulusMatrix = makeLinearMaskCircleAnn(width+1,width+1,size_inner_most_circle,start_linear_decay,width/2);



stimulusMatrix = stimulusMatrix .* annulusMatrix;

%Make the grating
gaborPatch = cfg.background + rgb_range_down * stimulusMatrix;


% c = contrastGrating
% background
% Lmax_rgb
% Lmin_rgb
% Lmax = max(max(gaborPatch))
% Lmin = min(min(gaborPatch))
% Lmean = mean(mean(gaborPatch))
