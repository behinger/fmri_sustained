function plaid = makeBRPlaid(blackBackground, redContrast, greenContrast, stimSize, inner_rad, spatialFrequency, barWidth, redPhase, greenPhase, distFromScreen, environment, scanner, whichScreen)
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
stimSize = degrees2pixels(stimSize, distFromScreen, [], whichScreen);
inner_rad = degrees2pixels(inner_rad, distFromScreen, [], whichScreen);

% Luminance settings
[background, Rmin_rgb, Rmax_rgb] = calibrate_lum(redContrast, environment, scanner);
if blackBackground == 1
    background = 0;
end
[~, Gmin_rgb, Gmax_rgb] = calibrate_lum(greenContrast, environment, scanner);

% Bar width (alsodetermines space between bars given we are working within
% a confined space)
barWidth = degrees2pixels(barWidth, distFromScreen, [], whichScreen);
interBar = round((stimSize/nCycles)-barWidth); % Space between bars

% Calculate indices for green bars
greenBarInd = repmat([ones(barWidth,1);zeros(interBar,1)],nCycles,stimSize);
% Phase shift
greenBarInd = circshift(greenBarInd, [round(greenPhase*(barWidth+interBar)) 0]);

% Possible that fitting desired number of evenly spaced bars and desired
% width into stimulus size isn't pixel perfect. If necessary, crop excess
% pixels or add extra pixels to the end of the stimulus (last space between
% bars) to match stimulus size. Errors should be a small number of pixels
% that won't affect the end stimulus too much.
if size(greenBarInd,1) > stimSize
    discrepancy = size(greenBarInd,1) - stimSize;
    greenBarInd(end-(discrepancy-1):end,:) = [];
elseif size(greenBarInd,1) < stimSize
    discrepancy = stimSize - size(greenBarInd,1);
    greenBarInd(end+1:end+discrepancy,:) = background;
end

% Same process for red bars
redBarInd = repmat([ones(1,barWidth),zeros(1,interBar)],stimSize,nCycles);
redBarInd = circshift(redBarInd, [0 round(redPhase*(barWidth+interBar))]);

if size(redBarInd,2) > stimSize
    discrepancy = size(redBarInd,2) - stimSize;
    redBarInd(:,end-(discrepancy-1):end) = [];
elseif size(redBarInd,2) < stimSize
    discrepancy = stimSize - size(redBarInd,2);
    redBarInd(:,end+1:end+discrepancy) = background;
end

% Form grating stimuli that will be combined into plaid
redGrating = zeros(stimSize, stimSize);
greenGrating = redGrating;
blueGrating = redGrating; % This will be left as zeros for the blue gun

% Insert red bars
redGrating(redBarInd == 1) = 1;
greenGrating(greenBarInd == 1) = 1;

% Because the difference between Lmax_rgb and background is not equal to
% the difference between Lmin_rgb and background (the differences are equal
% in luminance, but not in rgb), correct the range of the positive values
% of stimulusMatrix.

% Insert red bars
if blackBackground == 0
    % Red grating
    Rrgb_range_up = Rmax_rgb - background;
    Rrgb_range_down = background - Rmin_rgb;
    Rrgb_range_up_down_ratio = Rrgb_range_up/Rrgb_range_down;
    redGrating(redGrating > 0) = redGrating(redGrating > 0) * Rrgb_range_up_down_ratio;
    
    % Green grating
    Grgb_range_up = Gmax_rgb - background;
    Grgb_range_down = background - Gmin_rgb;
    Grgb_range_up_down_ratio = Grgb_range_up/Grgb_range_down;
    greenGrating(greenGrating > 0) = greenGrating(greenGrating > 0) * Grgb_range_up_down_ratio;
else
    % Red grating
    redGrating(redBarInd == 1) = 255 * redContrast;
    
    % Green grating
    greenGrating(greenBarInd == 1) = 255 * greenContrast;
end

% Combine into plaid
plaid = redGrating;
plaid(:,:,3) = greenGrating;
plaid(:,:,2) = blueGrating;

% Generate and apply annulus mask
annulus = makeLinearMaskCircleAnn(stimSize, stimSize, inner_rad, degrees2pixels(0.5), (stimSize/2));
annulus = repmat(annulus,[1,1,3]);
plaid = plaid.*annulus;

if blackBackground == 0
    plaid(:,:,1) = background + Rrgb_range_down * plaid(:,:,1);
    plaid(:,:,2) = background + Grgb_range_down * plaid(:,:,2);
    plaid(:,:,3) = background + Rrgb_range_down * plaid(:,:,3);
end

plaid = uint8(plaid);
% Done!
end
