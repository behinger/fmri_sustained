function gaborPatch = makeStimulus_am(contrastGrating,sizeGrating,phaseGrating,spatialFrequency,environment,scanner)
% spatialFrequency: cycles/degree

% Get distance from screen 
global distFromScreen;

%width = degrees2pixels(sizeGrating, distFromScreen, pixelsPerCm);
% Not using pixelsPerCm here, degrees2pixels will measure this for itself.
% Seems more flexible in case of resolution differences.
width = degrees2pixels(sizeGrating, distFromScreen, [], whichScreen);

nCycles = sizeGrating*spatialFrequency; % number of cycles in a stimulus

% compute the pixels per grating period
pixelsPerGratingPeriod = width / nCycles;

spatialFrequency = 1 / pixelsPerGratingPeriod; % How many periods/cycles are there in a pixel?
radiansPerPixel = spatialFrequency * (2 * pi); % = (periods per pixel) * (2 pi radians per period)

%gray = 127;

% adjust contrast
% black = 0;
% absoluteDifferenceBetweenBlackAndGray = abs(gray - black);
[background, Lmin_rgb, Lmax_rgb] = calibrate_lum(contrastGrating, environment, scanner);
virtual_background = (Lmin_rgb+Lmax_rgb)/2;
rgb_range = Lmax_rgb - virtual_background;

halfWidthOfGrid = width / 2;
widthArray = (-halfWidthOfGrid) : halfWidthOfGrid;  % widthArray is used in creating the meshgrid.

% Creates a two-dimensional square grid.  For each element i = i(x0, y0) of
% the grid, x = x(x0, y0) corresponds to the x-coordinate of element "i"
% and y = y(x0, y0) corresponds to the y-coordinate of element "i"
[x y] = meshgrid(widthArray);

% Creates a sinusoidal grating, where the period of the sinusoid is 
% approximately equal to "pixelsPerGratingPeriod" pixels.
% Note that each entry of gratingMatrix varies between minus one and
% one; -1 <= gratingMatrix(x0, y0)  <= 1

% the grating is oriented vertically unless otherwise specified.

%stimulusMatrix = (2*rand(width+1, width+1)-1); % with noise
%stimulusMatrix = zeros(width+1,width+1); % without noise

stimulusMatrix = sin(radiansPerPixel * x + phaseGrating);
%gratingMatrix = contrastGrating * gratingMatrix;

%stimulusMatrix = stimulusMatrix + gratingMatrix;
%stimulusMatrix = 2*Scale(stimulusMatrix)-1;

annulusMatrix = ones(width+1, width+1);
for i=1:width+1
    for j=1:width+1
        if ((width/2 - i)^2 + (width/2 - j)^2) > (width/2)^2
            annulusMatrix(i,j) = 0;
        end
    end
end

%stimulusMatrix = stimulusMatrix .* annulusMatrix;
%Make the grating
gaborPatch = virtual_background + rgb_range * stimulusMatrix;
%Make it round
gaborPatch = gaborPatch .* annulusMatrix;
%Give the background the right colour
annulusMatrix = abs(annulusMatrix - 1) * background;
gaborPatch = gaborPatch + annulusMatrix;


% c = contrastGrating
% background
% virtual_background
% Lmax = max(max(gaborPatch))
% Lmin = min(min(gaborPatch))
