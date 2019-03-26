function grating = makeBRGrating(blackBackground, colour, contrast, stimSize, inner_rad, spatialFrequency, barWidth, phase, distFromScreen, pix_per_cm, environment, scanner, whichScreen)
% Makes red/green square-wave plaid stimulus comprising orthogonal red and
% green gratings for use in binocular rivalry experiment.
%
% USAGE:
% plaid = makeBRPlaid(blackBackground, redContrast, greenContrast,
% stimSize, inner_rad, spatialFrequency, barWidth, redPhase, greenPhase,
% distFromScreen, environment, scanner, whichScreen)
%
% blackBackground = flag. If set to 1 background will be black rather than
% mid-gray
% redContrast = contrast of red grating between 0 and 1
% greenContrast = contrast of green grating between 0 and 1
% stimSize = stimulus diameter in degrees of visual angle
% inner_rad = inner radius of annulus mask in degrees
% spatialFrequency = spatial frequency of gratings in cpd
% barWidth = width of bars in degrees
% redPhase = phase of red grating between 0 and 1
% greenPhase = phase of green grating between 0 and 1
% distFromScrene = distance from screen in cm
% environment = presentation environment (e.g. 'behavioural' or 'mri')
% scanner = MRI scanner used for project (e.g. 'prisma' or 'essen')
% whichScreen = screen pointer
%
% 17/01/2018 SJDL wrote it.


% Calculate some stimulus parameters
nCycles = stimSize*spatialFrequency; % number of cycles
stimSize = degrees2pixels(stimSize, distFromScreen, pix_per_cm, whichScreen);
inner_rad = degrees2pixels(inner_rad, distFromScreen, pix_per_cm, whichScreen);

% Luminance settings
[background, min_rgb, max_rgb] = calibrate_lum(contrast, environment, scanner);
if blackBackground == 1
    background = 0;
end

% Because the difference between Lmax_rgb and background is not equal to
% the difference between Lmin_rgb and background (the differences are equal
% in luminance, but not in rgb), correct the range of the positive values
% of stimulusMatrix.
rgb_range_up = max_rgb - background;
rgb_range_down = background - min_rgb;
rgb_range_up_down_ratio = rgb_range_up/rgb_range_down;

% Bar width (alsodetermines space between bars given we are working within
% a confined space)
barWidth = degrees2pixels(barWidth, distFromScreen, pix_per_cm, whichScreen);
interBar = round((stimSize/nCycles)-barWidth); % Space between bars

% Calculate indices for green bars
barInd = repmat([ones(barWidth,1);zeros(interBar,1)],nCycles,stimSize);
assignin('base','barInd',barInd);
% Phase shift
barInd = circshift(barInd, [round(phase*(barWidth+interBar)) 0]);

% Possible that fitting desired number of evenly spaced bars and desired
% width into stimulus size isn't pixel perfect. If necessary, crop excess
% pixels or add extra pixels to the end of the stimulus (last space between
% bars) to match stimulus size. Errors should be a small number of pixels
% that won't affect the end stimulus too much.
if size(barInd,1) > stimSize
    discrepancy = size(barInd,1) - stimSize;
    barInd(end-(discrepancy-1):end,:) = [];
elseif size(barInd,1) < stimSize
    discrepancy = stimSize - size(barInd,1);
    barInd(end+1:end+discrepancy,:) = background;
end

% Form grating stimuli that will be combined into plaid
redGrating = zeros(stimSize, stimSize);
greenGrating = redGrating;
blueGrating = redGrating;

% Insert red bars
if blackBackground == 0
    switch colour
        case 'red'
            redGrating(barInd == 1) = 1;
            redGrating(redGrating > 0) = redGrating(redGrating > 0) * rgb_range_up_down_ratio;
        case 'green'
            greenGrating(barInd == 1) = 1;
            greenGrating(greenGrating > 0) = greenGrating(greenGrating > 0) * rgb_range_up_down_ratio;
        case 'blue'
            blueGrating(barInd == 1) = 1;
            blueGrating(blueGrating > 0) = blueGrating(blueGrating > 0) * rgb_range_up_down_ratio;
    end
else
    switch colour
        case 'red'
            redGrating(barInd == 1) = 255 * contrast;
        case 'green'
            greenGrating(barInd == 1) = 255 * contrast;
        case 'blue'
            blueGrating(barInd == 1) = 255 * contrast;
    end
end

% Combine into plaid
grating = redGrating;
grating(:,:,2) = greenGrating;
grating(:,:,3) = blueGrating;

% Generate and apply annulus mask
annulus = makeLinearMaskCircleAnn(stimSize, stimSize, inner_rad, degrees2pixels(0.5, distFromScreen, pix_per_cm, whichScreen), (stimSize/2));
annulus = repmat(annulus,[1,1,3]);
grating = grating.*annulus;

if blackBackground == 0
    grating(:,:,1) = background + rgb_range_down * grating(:,:,1);
    grating(:,:,2) = background + rgb_range_down * grating(:,:,2);
    grating(:,:,3) = background + rgb_range_down * grating(:,:,3);
end

grating = uint8(grating);
% Done!
end
