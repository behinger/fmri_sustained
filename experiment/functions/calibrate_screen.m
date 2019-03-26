% Script to use when measuring/calibrating screen/luminance/colours

clear all

try
    background = 0;
    
    cyan =      [0      255     255];
    blue =      [0      0       255];
    pink =      [255    0       255];
    yellow =    [255    255     0];
    orange =    [255    128     0];
    violet =    [128    0       255];
    green =     [0      255     0];
    
    calibrated_cyan =   [20     195     195];
    calibrated_blue =   [173    173     225];
    calibrated_pink =   [255    150     255];
    calibrated_yellow = [174    174     0];
    calibrated_orange = [255    175     47];
    calibrated_violet = [243    115     255];
    calibrated_green =  [0      247     0];
    
    % samlaw gray_values =  [0    30      60      90      120     150     180     190     200     210     220     230     240     250     255];
    gray_values =  [0    30      60      90      120     150     180     190     210     220     230     240     250     255];
    %Define the keys
    KbName('UnifyKeyNames');
    key_space = KbName('space');
    key_cyan = KbName('c');
    key_blue = KbName('b');
    key_pink = KbName('p');
    key_yellow = KbName('y');
    key_orange = KbName('o');
    key_violet = KbName('v');
    key_green = KbName('g');
    key_min = KbName('-_');
    key_plus = KbName('=+');
    key_escape = KbName('escape');
    key_return = KbName('return');
    
    cur_colour = 'gray';
    cur_gray = 1;
    cur_rgb = [gray_values(cur_gray) gray_values(cur_gray) gray_values(cur_gray)];
    
    %Open window and do useful stuff
    [window,width,height] = openScreen();
    
    wrapat = 55;
    vspacing = 1.5;
    % samlaw Screen('TextFont',window, 'Arial');
    Screen('TextFont',window, '-misc-liberation sans narrow-medium-i-condensed--0-0-0-0-p-0-iso8859-1');
    % samlaw Screen('TextSize',window, 14);
    Screen('FillRect', window, cur_rgb);
    text = sprintf('colour = %s, rgb = %d %d %d',cur_colour,cur_rgb);
    DrawFormattedText(window, text, 10, 10, [255 0 0], wrapat,0,0,vspacing);
    Screen('Flip', window);
    
    WaitSecs(.1);
    %Wait for button press
    while 1
        [keyIsDown,secs,keyCode]=KbCheck;
        if keyIsDown
            if keyCode(key_space)
                cur_colour = 'gray';
                cur_gray = 1;
                cur_rgb = [gray_values(cur_gray) gray_values(cur_gray) gray_values(cur_gray)];
            elseif keyCode(key_cyan)
                cur_colour = 'cyan';
                cur_rgb = cyan;
            elseif keyCode(key_blue)
                cur_colour = 'blue';
                cur_rgb = blue;
            elseif keyCode(key_pink)
                cur_colour = 'pink';
                cur_rgb = pink;
            elseif keyCode(key_yellow)
                cur_colour = 'yellow';
                cur_rgb = yellow;
            elseif keyCode(key_orange)
                cur_colour = 'orange';
                cur_rgb = orange;
            elseif keyCode(key_violet)
                cur_colour = 'violet';
                cur_rgb = violet;
            elseif keyCode(key_green)
                cur_colour = 'green';
                cur_rgb = green;
            elseif keyCode(key_min)
                if strcmp(cur_colour,'gray')
                    if cur_gray > 1
                        cur_gray = cur_gray - 1;
                    end
                    cur_rgb = [gray_values(cur_gray) gray_values(cur_gray) gray_values(cur_gray)];
                else
                    cur_rgb = cur_rgb - 1;
                    cur_rgb(cur_rgb < 0) = 0;
                end
            elseif keyCode(key_plus)
                if strcmp(cur_colour,'gray')
                    if cur_gray < length(gray_values)
                        cur_gray = cur_gray + 1;
                    end
                    cur_rgb = [gray_values(cur_gray) gray_values(cur_gray) gray_values(cur_gray)];
                else
                    cur_rgb = cur_rgb + 1;
                    cur_rgb(cur_rgb > 255) = 255;
                end
            elseif keyCode(key_escape)
                break;
            elseif keyCode(key_return)
                oval_size = 50;
                Screen('FillRect', window, background);
                
                dest_square = [width/2-oval_size/2 - 200, height/2-oval_size/2 - 200, width/2+oval_size/2 - 200, height/2+oval_size/2 - 200];
                Screen('FillOval', window, calibrated_cyan, dest_square);
                %                 dest_square = [width/2-oval_size/2, height/2-oval_size/2 - 200, width/2+oval_size/2, height/2+oval_size/2 - 200];
                %                 Screen('FillOval', window, calibrated_green, dest_square);
                dest_square = [width/2-oval_size/2 + 200, height/2-oval_size/2 - 200, width/2+oval_size/2 + 200, height/2+oval_size/2 - 200];
                Screen('FillOval', window, calibrated_pink, dest_square);
                
                %                 dest_square = [width/2-oval_size/2 - 200, height/2-oval_size/2, width/2+oval_size/2 - 200, height/2+oval_size/2];
                %                 Screen('FillOval', window, calibrated_yellow, dest_square);
                %                 dest_square = [width/2-oval_size/2, height/2-oval_size/2, width/2+oval_size/2, height/2+oval_size/2];
                %                 Screen('FillOval', window, calibrated_orange, dest_square);
                %                 dest_square = [width/2-oval_size/2 + 200, height/2-oval_size/2, width/2+oval_size/2 + 200, height/2+oval_size/2];
                %                 Screen('FillOval', window, calibrated_violet, dest_square);
                
                %                 dest_square = [width/2-oval_size/2, height/2-oval_size/2 + 200, width/2+oval_size/2, height/2+oval_size/2 + 200];
                %                 Screen('FillOval', window, calibrated_blue, dest_square);
                
                Screen('Flip', window);
                WaitSecs(1);
                KbWait;
                
            end
            Screen('FillRect', window, cur_rgb);
            text = sprintf('colour = %s, rgb = %d %d %d',cur_colour,cur_rgb);
            DrawFormattedText(window, text, 10, 10, [255 0 0], wrapat,0,0,vspacing);
            Screen('Flip', window);
            WaitSecs(.1);
        end
    end
    
    %End. Close all windows
    Screen('CloseAll');
    
catch aloha
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end