function my_list = Create_pseudo_randomised_list(list,repeats)
% Function to generate a list of numbers from a to b, repeated c times, and
% shuffle it, ensuring no more than 3 of the same number in a row. For
% generating a pseudu-random list of trial types

% Written by SL, 21/01/14
%
% Edit SL 10/10/16 - now supply one instance of list to be repeated rather
% than start and end - more flexible, allows for non integer lists

% Create array of a series of repeated numbers
my_list = repmat(list,1,repeats);

% Shuffle it
my_list = Shuffle(my_list);

for i = 4:length(my_list)
     % Look for 4 repeats in a row
     if my_list(i) == my_list(i-1) && my_list(i) == my_list(i-2) && my_list(i) == my_list(i-3)
         % If we find it, there is a CRIME!
         crime =1;
         % Initiate a start time for use in case we get caught in the while
         % loop
         startTime = GetSecs;
         % While there is still a CRIME
         while crime == 1
             % Shuffle the remainder of the list
             my_list(i:end) = Shuffle(my_list(i:end));
             % If we haven't solved the CRIME
             if my_list(i) == my_list(i-1) && my_list(i) == my_list(i-2) && my_list(i) == my_list(i-3)
                 %Do nothing
             else
                 % NO CRIME! Break out of loop and continue iterating down
                 % the list on the hunt for more CRIMES
                 crime = 0;
             end
             % If we've got stuck in while loop, which can happen if we end
             % up with lots of the same number at the end, start all over
             % again
             if GetSecs >= startTime+2;
                 i = 4;
             end
         end
     end
end

end