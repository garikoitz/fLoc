function b = get_box_num
% Checks connected USB devices and returns the device number corresponding
% to the scanner button box (box_id should be set the the productID of
% the button box used locally).
% Written by KGS Lab
% Edited by AS 8/2014

% change to productID number of local button box
% box_id 12 is for BCBL   % box 12 is the response box
% 834 is tiger's MAC
% 5648 is tiger's steelseries
% 671 is tiger's bluetooth keyboard

% it seems that when using tiger's mac, only 834 keyboard is working,
% I use 5648 as input but it is not useful
box_id = 834; b = 0; d = PsychHID('Devices');
for nn = 1:length(d)
    if (d(nn).productID == box_id) && (strcmp(d(nn).usageName, 'Keyboard'))
        b = nn;
    end
end
if b == 0
    fprintf('\nButton box not found.\n');
end

end


%{
d = PsychHID('Devices');
for nn = 1:length(d)
    if strcmp(d(nn).usageName, 'Keyboard')
        disp(d(nn))
    end
end
%}