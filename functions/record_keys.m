function [keys, is_empty] = record_keys(start_time, dur, device_num)
% Collects all keypresses for a given duration (in secs).
% Written by KGS Lab
% Edited by AS 8/2014

% Checking a specific device index with KbCheck is unreliable on this
% setup (same issue worked around in get_key.m), so we listen to all
% devices and filter out the scanner trigger key ('s') so its continuous
% pulses are not mistaken for participant responses.
trigger_key = 's';

% wait until keys are released
keys = [];
while KbCheck(-1) %device_num
    if (GetSecs - start_time) > dur
        break
    end
end

% check for pressed keys
while 1
    [key_is_down, ~, key_code] = KbCheck(-1); %device_num
    if key_is_down
        pressed_key = KbName(key_code);
        if ~ismember(trigger_key, pressed_key)
            keys = [keys pressed_key];
        end
        while KbCheck(-1) %device_num
            if (GetSecs - start_time) > dur
                break
            end
        end
    end
    if (GetSecs - start_time) > dur
        break
    end
end

% label null responses and store multiple presses as an array
if isempty(keys)
    is_empty = 1;
elseif iscell(keys)
    keys = num2str(cell2mat(keys));
    is_empty = 0;
else
    is_empty = 0;
end

end
