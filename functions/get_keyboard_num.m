function k = get_keyboard_num
% Checks to make sure that the laptop keyboard is used in case another
% device connected at the scanner also has the usageName Keyboard
% (keyboardID should be set to the productID of the native keyboard).
% Written by KGS Lab
% Edited by AS 8/2014

% change to productID number of native keyboard
% trigger box is identified as keyboard and it is 257 / the one sending s
% trigger box locationID is 34680832 / 
% it is actually highly dependent on the location! put the starttech port
% to iMAC first usb, and put the box usb to the second port, it is 336789504
% for iMac_M4, using the 2nd type-c port with the 23240 anker, it is 34799616;
% the real keyboard BCBL is 545
% 834 is tiger's MAC
% 5648 is tiger's steelseries
% 671 is tiger's bluetooth
keyboard_id = 257; k = 0; d = PsychHID('Devices');

if keyboard_id == 257
    %disp('S_key is being specified')
    locationID = 34799616;
    for nn = 1:length(d)
        if (d(nn).productID == keyboard_id) && (d(nn).locationID == locationID) && strcmp(d(nn).usageName, 'Keyboard');
            k = nn;
            break
        end
    end
else
    for nn = 1:length(d)
        if (d(nn).productID == keyboard_id) && (strcmp(d(nn).usageName, 'Keyboard'))
            k = nn;
        end
    end
end 
if k == 0
    fprintf('\nKeyboard not found.\n');
end

end
