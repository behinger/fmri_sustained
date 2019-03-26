function grating = makeLineGrating(contrast,stimSize,inner_rad,spatialFrequency,lumPol,barWidth,phase,distFromScreen,environment,scanner,whichScreen)
% Function to generate line grating stimulus with annulus mask.
% Basically the same as makeLinePlaid but only half the plaid
%
% USAGE: plaid = makeLinePlaid(contrast,stimSize,inner_rad,spatialFrequency,lumPol,barWidth,phase,distFromScreen,environment,scanner,whichScreen)
% contrast = stimulus contrast between 0 and 1
% stimSize = stimulus diameter in degrees of visual angle
% inner_rad = inner annulus radius in degrees
% spatialFrequency = spatial frequency in cycles/degree
% lumPol = luminance polarity. If 1, bars are white, if 2 bars are black
% barWidth = width of bars in degrees
% phase = phase of bars between 0 and 1
% distFromScreen = viewing distance in cm
% environtment = presentation environment (e.g. 'behav' or 'mri' etc.)
% scanner = scanner used for project (e.g. 'prisma' or 'essen')
% whichScreen = PsychToolBox window pointer
%
% 08/11/2017 samlaw wrote it.

% Calculate some stimulus parameters
nCycles = stimSize*spatialFrequency; % number of cycles 
stimSize = degrees2pixels(stimSize, distFromScreen, [], whichScreen);
inner_rad = degrees2pixels(inner_rad, distFromScreen, [], whichScreen);

% Luminance settings
[background, Lmin_rgb, Lmax_rgb] = calibrate_lum(contrast, environment, scanner);

% Bar width defined seperately for horizontal and vertical bars (also
% determines space between bars given we are working within a confined
% space)
barWidth = degrees2pixels(barWidth, distFromScreen, [], whichScreen);
interBar = round((stimSize/nCycles)-barWidth); % Space between bars

% Calculate indices for horizontal bars
barInd = repmat([ones(1,barWidth),zeros(1,interBar)],stimSize,nCycles);
% Phase shift
barInd = circshift(barInd, [0 round(phase*(barWidth+interBar))]);

% Possible that fitting desired number of evenly spaced bars and desired
% width into stimulus size isn't pixel perfect. If necessary, crop excess
% pixels or add extra pixels to the end of the stimulus (last space between
% bars) to match stimulus size. Errors should be a small number of pixels
% that won't affect the end stimulus too much.
if size(barInd,2) > stimSize
    discrepancy = size(barInd,2) - stimSize;
    barInd(:,end-(discrepancy-1):end) = [];
elseif size(barInd,2) < stimSize
    discrepancy = stimSize - size(barInd,2);
    barInd(:,end+1:end+discrepancy) = background;
end

% Form plaid stimulus
grating = zeros(stimSize, stimSize);
% Insert bars to plaid, depending on luminance polarity
switch lumPol
    case 1
        grating(barInd == 1) = 1;
    case 2
        grating(barInd == 1) = -1;
end

% Because the difference between Lmax_rgb and background is not equal to
% the difference between Lmin_rgb and background (the differences are equal
% in luminance, but not in rgb), correct the range of the positive values
% of stimulusMatrix.
rgb_range_up = Lmax_rgb - background;
rgb_range_down = background - Lmin_rgb;
rgb_range_up_down_ratio = rgb_range_up/rgb_range_down;
grating(grating > 0) = grating(grating > 0) * rgb_range_up_down_ratio;

% Generate and apply annulus mask
annulus = makeLinearMaskCircleAnn(stimSize, stimSize, inner_rad, degrees2pixels(0.5), (stimSize/2));
grating = grating.*annulus;
grating = background + rgb_range_down * grating;

% Done!
end