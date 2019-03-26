function [background, Lmin_rgb, Lmax_rgb] = calibrate_lum(contrast,environment,scanner)
% some RGB & corresponding luminance levels from the dummy scanner screen,
% with brightness (+30%) and contrast (+0%) toned down and the cardboard
% screen in place to prevent high levels of background lighting.
rgb = [0        30      60      90      120     150     180     190     210     220     230     240     250     255];


if strcmp(environment,'dummy')
    %     % luminance values measured for the dummy scanner monitor.
    %     lum1 = [0.16     1.2     3.9     9.5     18.6    29.5    43.5    49.5    62      68      75.5    83      91      95];
    %     lum2 = [0.17     1.4     4.7     10.2    19.1    31      47.6    54      68.7    74.8    82      88.8    96.2    100];
    %     lum3 = [0.15    1.23    4.0     9.1     17.3    28.8    44.6    51.2    64.3    70.8    78      85.3    92.6    97.6];
    %     lum = mean([lum1 ; lum2; lum3]);
    %     % new luminance values measurements for the dummy scanner monitor: it
    %     % turns out horizontal flipping changes the colours somewhat...
    %     % NVidia desktop colour settings: brightness +30%, contrast +20%.
    %     lum(1,:) = [0.13    0.18    1.87    6.30    15.1    27.3    46.3    55.0    70.0    78.0    86.9    95.9    107     112];
    %     lum(2,:) = [0.12    0.16    1.77    5.80    13.8    25.6    44.0    52.0    68.2    75.7    83.5    93.7    105     111];
    % another new set of values:  measurements for the dummy scanner
    % monitor with standard desktop settings, since the new MRI beamer is a lot brighter than the old one.
    lum(1,:) = [0.12    0.36    3.25    9.88    21.75   43.3    70.0    75.5    97.4    110     126     140     152     158];
    lum = mean(lum,1);
elseif strcmp(environment,'mri') || strcmp(environment,'work_station')
    %luminance values measured for the MRI projector.
    switch scanner
        case 'trio'
     % new TRIO measurement, after beamer was repaired (17-01-2012).
            lum(1,:) = [0.27  4.1    24.6   63.8   109     163     224     243     286     302     317     326     326     327];
            lum = mean(lum,1);
        case 'avanto'
     % AVANTO measurement, 17-01-2012.
            lum(1,:) = [1.1   2.2    15.1   40.4   73.5    113     160     177     213     231     251     270     292     303];
            lum = mean(lum,1);
        case 'prisma'   
     % PRISMA (peter kok      
            lum(1,:) = [0.19    2.30    16.5    46.1    88.5    135.5   192     210     250     270     297     311     330     338];
            lum = mean(lum,1);
        case 'essen'
            % Luminance measurements by Sam Lawrence and Levan Bokeria on
            % 08/03/2017. As dark as possible - lights off (scanner room 
            % and control room), door almost closed
            lum(1,:) = [1.765    7.58    36.2    134    335    579   902.5     1045     1320     1545     1735     1870     2210     2350];
            lum = mean(lum,1);
    end

    % new luminance values: new beamer.
elseif strcmp(environment,'behav') || strcmp(environment,'t480s')
    % luminance values for the monitor in behavioural lab 1.
    % resolution = 1024 x 768, brightness = +50%, contrast = +50%, gamma = +9%
    % monitor setting: brightness = 50, contrast = 75 (auto adjusted)
    %lum(1,:) =     [0.2      2.30    9       18      35      53      80      91      110     115     132     136     151     156];
    
    % Measure my samlaw 07/03/2017
    lum(1,:) = [0.18 3.23 11.815 18.7 31.5 50.7 71.3 77.05 90.55 96.9 103 116 135.5 133];
    lum = mean(lum,1);
end

% interpolate over the whole rgb range
lum = interp1(rgb,lum,0:255,'spline');


%middle of the luminance range:
medium_lum = (min(lum) + max(lum))/2;
background = 256;
%what colour should the background be? medium luminance, or darker?
while lum(background) > medium_lum%/2
    background = background - 1;
end

if exist('contrast', 'var')
    Lmin = medium_lum - (medium_lum-min(lum))*contrast;
    Lmax = medium_lum + (max(lum)-medium_lum)*contrast;
    Lmin_rgb = 1;
    while lum(Lmin_rgb) < Lmin
        Lmin_rgb = Lmin_rgb + 1;
    end
    Lmax_rgb = 255;
    while lum(Lmax_rgb) > Lmax
        Lmax_rgb = Lmax_rgb - 1;
    end
    
end

%plot(0:255,lum)

