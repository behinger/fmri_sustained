function [flickers45,flickers45Timings,flickers135,flickers135Timings,flickersOff,flickersOffTimings] = setup_flickertimings_localizer(params)

% BEHINGER
% I kept this script from Sam Lawrence. It is not very nicely programmed
% but I think it works. I improved it slightly bit.


%--------------------------------------------------------------------------
% Generate lists of how many fixation colour changes there should be in
% each block, and when they should occur.
% Will have 1, 2, 3, or 4 fixation flickers in a block.

possibleFlickers = randi(4,1,params.numBlocks);
flickers45 = Shuffle(possibleFlickers); % Randomise order for each condition
flickers135 = Shuffle(possibleFlickers);
% twice as many off blocks so need twice as many flickers
flickersOff = Shuffle(repmat(possibleFlickers,1,2));
% Possible times fixation could flicker
possibleTimes = (params.stimPres:params.ISI+params.stimPres:params.stimBlockLength-(params.ISI+params.stimPres));
% Decide on timings for each condition
flickers45Timings = cell(1,length(flickers45));
flickers135Timings = flickers45Timings;
flickersOffTimings = cell(1,length(flickersOff));
for i = 1:length(flickers45)
    % Choose four timings at random
    % Make sure two flickers don't happen in a row
    flag = 1;
    while flag == 1
        ind = sort(randperm(length(possibleTimes),flickers45(i)));
        switch flickers45(i)
            case 1
                flag = 0;
            case 2
                if ind(2) == ind(1) + 1
                    % Do nothing, go round again
                else
                    flag = 0;
                end
            case 3
                if ind(2) == ind(1) + 1 || ind(3) == ind(2) + 1
                    % Do nothing, go round again
                else
                    flag = 0;
                end
            case 4
                if ind(2) == ind(1) + 1 || ind(3) == ind(2) + 1 || ind(4) == ind(3)+1
                    % Do nothing, go round again
                else
                    flag = 0;
                end
        end
    end
    flickers45Timings{i} = ind;
end

for i = 1:length(flickers135)
    % Choose four timings at random
    % Make sure two flickers don't happen in a row
    flag = 1;
    while flag == 1
        ind = sort(randperm(length(possibleTimes),flickers135(i)));
        switch flickers135(i)
            case 1
                flag = 0;
            case 2
                if ind(2) == ind(1) + 1
                    % Do nothing, go round again
                else
                    flag = 0;
                end
            case 3
                if ind(2) == ind(1) + 1 || ind(3) == ind(2) + 1
                    % Do nothing, go round again
                else
                    flag = 0;
                end
            case 4
                if ind(2) == ind(1) + 1 || ind(3) == ind(2) + 1 || ind(4) == ind(3)+1
                    % Do nothing, go round again
                else
                    flag = 0;
                end
        end
    end
    flickers135Timings{i} = ind;
end

for i = 1:length(flickersOff)
    % Choose four timings at random
    % Going to flicker on the second for off blocks (easier), so block length -1 in
    % next line to avoid flickering right at the end
    clear ind
    ind = sort(randperm(round(params.offBlockLength-1),flickersOff(i)));
    
    flickersOffTimings{i} = ind;
end