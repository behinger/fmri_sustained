function draw_fixationdot(cfg,dotsize,color,colorInside,x,y)
if nargin <=1
    dotsize = [0.05 0.2];
end
if nargin <=2
    color = 0;
end
if nargin<=3
    colorInside = color;
end
if nargin <=4
    x = cfg.width/2;
end
if nargin <=5
    y = cfg.height/2;
end
% Screen('DrawDots', cfg.win, [cfg.width/2, cfg.height/2], dotSize, color);


d1 = dotsize(1); % diameter of outer circle (degrees)
d2 = dotsize(2); % diameter of inner circle (degrees)
[~,ppd] = degrees2pixels(1,cfg.distFromScreen,cfg.pixelsPerCm);

Screen('FillOval', cfg.win, color, [x-d1/2 * ppd, y-d1/2 * ppd, x+d1/2 * ppd, y+d1/2 * ppd], d1 * ppd);
Screen('DrawLine', cfg.win, cfg.background, x-d1/2 * ppd, y, x+d1/2 * ppd, y, min(d2 * ppd,5));
Screen('DrawLine', cfg.win, cfg.background, x, y-d1/2 * ppd, x, y+d1/2 * ppd, min(d2 * ppd,5));
Screen('FillOval', cfg.win, colorInside, [x-d2/2 * ppd, y-d2/2 * ppd, x+d2/2 * ppd, y+d2/2 * ppd], d2 * ppd);

