function plaid = makeLinePlaid(contrast,stimSize,inner_rad,spatialFrequency,lumPol,HbarWidth,Hphase,VbarWidth,Vphase,distFromScreen, pix_per_cm,environment,scanner,whichScreen)
% Function to generate line plaid stimulus similar to Kamitani & Tong,
% 2005, Nature Neuroscience, within an annulus mask
%
% USAGE: plaid = makeLinePlaid(contrast,stimSize,inner_rad,spatialFrequency,barColour,HbarWidth,Hphase,VbarWidth,Vphase,distFromScreen,environment,scanner,whichScreen)
% contrast = stimulus contrast between 0 and 1
% stimSize = stimulus diameter in degrees of visual angle
% inner_rad = inner annulus radius in degrees
% spatialFrequency = spatial frequency in cycles/degree
% lumPol = luminance polarity. If 1, vertical bars black and horizontal
% bars white, if 2, vice versa.
% HbarWidth = width of horizontal bars in degrees
% Hphase = phase of horizontal bars between 0 and 1
% VbarWidth = width of vertical bars in degrees
% Vphsae = phase of vertical bars between 0 and 1
% distFromScreen = viewing distance in cm
% environtment = presentation environment (e.g. 'behav' or 'mri' etc.)
% scanner = scanner used for project (e.g. 'prisma' or 'essen')
% whichScreen = PsychToolBox window pointer
%
% 26/10/2017 samlaw wrote it.

% Calculate some stimulus parameters
nCycles = stimSize*spatialFrequency; % number of cycles 
stimSize = degrees2pixels(stimSize, distFromScreen, pix_per_cm, whichScreen);
inner_rad = degrees2pixels(inner_rad, distFromScreen, pix_per_cm, whichScreen);

% Luminance settings
[background, Lmin_rgb, Lmax_rgb] = calibrate_lum(contrast, environment, scanner);

% Bar width defined seperately for horizontal and vertical bars (also
% determines space between bars given we are working within a confined
% space)
HbarWidth = degrees2pixels(HbarWidth, distFromScreen, pix_per_cm, whichScreen);
HinterBar = round((stimSize/nCycles)-HbarWidth); % Space between bars

VbarWidth = degrees2pixels(VbarWidth, distFromScreen, pix_per_cm, whichScreen);
VinterBar = round((stimSize/nCycles)-VbarWidth); % Space between bars

% Calculate indices for horizontal bars
HbarInd = repmat([ones(HbarWidth,1);zeros(HinterBar,1)],nCycles,stimSize);
% Phase shift
HbarInd = circshift(HbarInd, [round(Hphase*(HbarWidth+HinterBar)) 0]);

% Possible that fitting desired number of evenly spaced bars and desired
% width into stimulus size isn't pixel perfect. If necessary, crop excess
% pixels or add extra pixels to the end of the stimulus (last space between
% bars) to match stimulus size. Errors should be a small number of pixels
% that won't affect the end stimulus too much.
if size(HbarInd,1) > stimSize
    discrepancy = size(HbarInd,1) - stimSize;
    HbarInd(end-(discrepancy-1):end,:) = [];
elseif size(HbarInd,1) < stimSize
    discrepancy = stimSize - size(HbarInd,1);
    HbarInd(end+1:end+discrepancy,:) = background;
end

% Same process for vertical bars
VbarInd = repmat([ones(1,VbarWidth),zeros(1,VinterBar)],stimSize,nCycles);
VbarInd = circshift(VbarInd, [0 round(Vphase*(VbarWidth+VinterBar))]);

if size(VbarInd,2) > stimSize
    discrepancy = size(VbarInd,2) - stimSize;
    VbarInd(:,end-(discrepancy-1):end) = [];
elseif size(VbarInd,2) < stimSize
    discrepancy = stimSize - size(VbarInd,2);
    VbarInd(:,end+1:end+discrepancy) = background;
end

% Form plaid stimulus
plaid = zeros(stimSize, stimSize);
% Insert bars to plaid, depending on luminance polarity
switch lumPol
    case 1
        plaid(HbarInd == 1) = 1;
        plaid(VbarInd == 1) = -1;
    case 2
        plaid(HbarInd == 1) = -1;
        plaid(VbarInd == 1) = 1;
end
% Make overlap between bars gray
plaid(HbarInd == 1 & VbarInd == 1) = 0;

% Because the difference between Lmax_rgb and background is not equal to
% the difference between Lmin_rgb and background (the differences are equal
% in luminance, but not in rgb), correct the range of the positive values
% of stimulusMatrix.
rgb_range_up = Lmax_rgb - background;
rgb_range_down = background - Lmin_rgb;
rgb_range_up_down_ratio = rgb_range_up/rgb_range_down;
plaid(plaid > 0) = plaid(plaid > 0) * rgb_range_up_down_ratio;

% Generate and apply annulus mask
annulus = makeLinearMaskCircleAnn(stimSize, stimSize, inner_rad, degrees2pixels(0.5, distFromScreen, pix_per_cm, whichScreen), (stimSize/2));
plaid = plaid.*annulus;
plaid = background + rgb_range_down * plaid;

% Done!
end