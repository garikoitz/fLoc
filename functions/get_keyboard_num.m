function k = get_keyboard_num
% Checks to make sure that the laptop keyboard is used in case another
% device connected at the scanner also has the usageName Keyboard
% (keyboardID should be set to the productID of the native keyboard).
% Written by KGS Lab
% Edited by AS 8/2014

% change to productID number of native keyboard
% trigger box is identified as keyboard and it is 257 / the one sending s
% the real keyboard BCBL is 545
% 834 is tiger's MAC
% 5648 is tiger's steelseries
% 671 is tiger's bluetooth
keyboard_id = 671; k = 0; d = PsychHID('Devices');
for nn = 1:length(d)
    if (d(nn).productID == keyboard_id) && strcmp(d(nn).usageName, 'Keyboard');
        k = nn;
        break
    end
end
if k == 0
    fprintf('\nKeyboard not found.\n');
end

end
