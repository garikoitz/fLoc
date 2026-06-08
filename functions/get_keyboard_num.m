function k = get_keyboard_num
% Checks to make sure that the laptop keyboard is used in case another
% device connected at the scanner also has the usageName Keyboard
% (keyboardID should be set to the productID of the native keyboard).
% Written by KGS Lab
% Edited by AS 8/2014

% change to productID number of native keyboard
% Linux box productID 8467 12314
% the linux box keyboard is 24729
% the NNL s-keys is 257
keyboard_id = 257;
k = 0;
d = PsychHID('Devices');

% --- diagnostic: print all connected devices so you can verify the productID ---
fprintf('\n--- Connected HID devices ---\n');
for ii = 1:length(d)
    fprintf('  [%d] productID=%d  usageName=%-12s  product=%s\n', ...
        ii, d(ii).productID, d(ii).usageName, d(ii).product);
end
fprintf('-----------------------------\n');
% ------------------------------------------------------------------------------

% Match by productID
for nn = 1:length(d)
    if d(nn).productID == keyboard_id
        k = nn;
        break
    end
end

if k == 0
    error('Keyboard with productID %d not found. Check the device list above and update keyboard_id if needed.', keyboard_id);
end

fprintf('\nKeyboard device index: %d\n', k);

end
