function [appearance,appearanceFixation,appearanceAfterFixation,...
    appearanceJitter,RT,responses]=THALENT_CONTEXTUAL(imgList,duration,...
    fixation,deviceIDTrigger,deviceID,keyTrigger,keyCodes,keyNames)
% A simple EyeLink integration demo that records eye movements passively 
% while an image is presented on the screen. Each trial ends when the
% space bar or a button is pressed.
%
% Usage:
% Eyelink_SimplePicture(screenNumber)
%
% screenNumber is an optional parameter which can be used to pass a specific value to Screen('OpenWindow', ...)
% If screenNumber is not specified, or if isempty(screenNumber) then the default:
% screenNumber = max(Screen('Screens'));
% will be used.

% Bring the Command Window to the front if it is already open
if ~IsOctave; commandwindow; end

% % Use default screenNumber if none specified
% if (nargin < 1)
%     screenNumber = [];
% end

screenNumber = [];

% define the scanList for the box response
scanList=zeros(1,256);
scanList(keyCodes) = 1;

% define the scanList for the trigger
scanListTrigger=zeros(1,256);
scanListTrigger(keyTrigger) = 1; % 22 is the 's'

% define the appearance variable
appearance=zeros(length(imgList),1);
appearanceFixation=appearance;
appearanceJitter=appearance;
appearanceAfterFixation=appearance;
% define the reaction time variable
RT=zeros(length(imgList),1);
% define the response variable
responses=cell(length(imgList),1);

% get the images only
[~,name,ext] = fileparts(imgList);
images=strcat(name,ext);

try
    %% STEP 1: INITIALIZE EYELINK CONNECTION; OPEN EDF FILE; GET EYELINK TRACKER VERSION
    
    % Initialize EyeLink connection (dummymode = 0) or run in "Dummy Mode" without an EyeLink connection (dummymode = 1);
    dummymode = 0;
    
    % Optional: Set IP address of eyelink tracker computer to connect to.
    % Call this before initializing an EyeLink connection if you want to use a non-default IP address for the Host PC.
    %Eyelink('SetAddress', '10.10.10.240');
    
    EyelinkInit(dummymode); % Initialize EyeLink connection
    status = Eyelink('IsConnected');
    if status < 1 % If EyeLink not connected
        dummymode = 1; 
    end
       
    % Open dialog box for EyeLink Data file name entry. File name up to 8 characters
    prompt = {'Enter EDF file name (up to 8 characters)'};
    dlg_title = 'Create EDF file';
    def = {'demo'}; % Create a default edf file name
    answer = inputdlg(prompt, dlg_title, 1, def); % Prompt for new EDF file name    
    % Print some text in Matlab's Command Window if a file name has not been entered
    if  isempty(answer)
        fprintf('Session cancelled by user\n')
        error('Session cancelled by user'); % Abort experiment (see cleanup function below)
    end    
    edfFile = answer{1}; % Save file name to a variable    
    % Print some text in Matlab's Command Window if file name is longer than 8 characters
    if length(edfFile) > 8
        fprintf('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)\n');
        error('Filename needs to be no more than 8 characters long (letters, numbers and underscores only)');
    end
 
    % Open an EDF file and name it
    failOpen = Eyelink('OpenFile', edfFile);
    if failOpen ~= 0 % Abort if it fails to open
        fprintf('Cannot create EDF file %s', edfFile); % Print some text in Matlab's Command Window
        error('Cannot create EDF file %s', edfFile); % Print some text in Matlab's Command Window
    end
    
    % Get EyeLink tracker and software version
    % <ver> returns 0 if not connected
    % <versionstring> returns 'EYELINK I', 'EYELINK II x.xx', 'EYELINK CL x.xx' where 'x.xx' is the software version
    ELsoftwareVersion = 0; % Default EyeLink version in dummy mode
    [ver, versionstring] = Eyelink('GetTrackerVersion');
    if dummymode == 0 % If connected to EyeLink
        % Extract software version number. 
        [~ ,vnumcell] = regexp(versionstring,'.*?(\d)\.\d*?','Match','Tokens'); % Extract EL version before decimal point
        ELsoftwareVersion = str2double(vnumcell{1}{1}); % Returns 1 for EyeLink I, 2 for EyeLink II, 3/4 for EyeLink 1K, 5 for EyeLink 1KPlus, 6 for Portable Duo         
        % Print some text in Matlab's Command Window
        fprintf('Running experiment on %s version %d\n', versionstring, ver );
    end
    % Add a line of text in the EDF file to identify the current experimemt name and session. This is optional.
    % If your text starts with "RECORDED BY " it will be available in DataViewer's Inspector window by clicking
    % the EDF session node in the top panel and looking for the "Recorded By:" field in the bottom panel of the Inspector.
    preambleText = sprintf('RECORDED BY Psychtoolbox demo %s session name: %s', mfilename, edfFile);
    Eyelink('Command', 'add_file_preamble_text "%s"', preambleText);
    
    
    %% STEP 2: SELECT AVAILABLE SAMPLE/EVENT DATA
    % See EyeLinkProgrammers Guide manual > Useful EyeLink Commands > File Data Control & Link Data Control
    
    % Select which events are saved in the EDF file. Include everything just in case
    Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
    % Select which events are available online for gaze-contingent experiments. Include everything just in case
    Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,FIXUPDATE,INPUT');
    % Select which sample data is saved in EDF file or available online. Include everything just in case
    if ELsoftwareVersion > 3  % Check tracker version and include 'HTARGET' to save head target sticker data for supported eye trackers
        Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');
        Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');
    else
        Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,GAZERES,BUTTON,STATUS,INPUT');
        Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
    end
    
    %% STEP 3: OPEN GRAPHICS WINDOW
    
    % Open experiment graphics on the specified screen
    if isempty(screenNumber)
        screenNumber = max(Screen('Screens')); % Use default screen if none specified
    end
    window = Screen('OpenWindow', screenNumber, [133 133 133]); % Open graphics window
    Screen('Flip', window);
    % Return width and height of the graphics window/screen in pixels
    [width, height] = Screen('WindowSize', window);
    %% check th next lines
%     width = 1280;
%     height = 1024;
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------      LOAD FIXATION DOT       --------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

imgDataFixation = imread(fixation); % Read image from file
imgTextureFixation = Screen('MakeTexture',window, imgDataFixation); % Convert image file to texture

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%--------------------     LOAD VISUAL SEARCHES     --------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert all images to textures
stimTextures=zeros(size(imgList));
for stim=1:length(stimTextures)
    imgName = char(imgList(stim)); % Get image file name for current trial
    if contains(imgName,'fixation')
        continue
    else
        imgData = imread(imgName); % Read image from file
        stimTextures(stim) = Screen('MakeTexture',window,imgData); % Convert image file to texture     
    end
end

    %% STEP 4: SET CALIBRATION SCREEN COLOURS/SOUNDS; PROVIDE WINDOW SIZE TO EYELINK HOST & DATAVIEWER; SET CALIBRATION PARAMETERS; CALIBRATE
    
    % Provide EyeLink with some defaults, which are returned in the structure "el".
    el = EyelinkInitDefaults(window);
    % set calibration/validation/drift-check(or drift-correct) size as well as background and target colors. 
    % It is important that this background colour is similar to that of the stimuli to prevent large luminance-based 
    % pupil size changes (which can cause a drift in the eye movement data)
    el.calibrationtargetsize = 3;% Outer target size as percentage of the screen
    el.calibrationtargetwidth = 0.7;% Inner target size as percentage of the screen
    el.backgroundcolour = [133 133 133];% RGB grey
    el.calibrationtargetcolour = [0 0 0];% RGB black
    % set "Camera Setup" instructions text colour so it is different from background colour
    el.msgfontcolour = [0 0 0];% RGB black
        
    % Use an image file instead of the default calibration bull's eye targets. 
    % Commenting out the following two lines will use default targets:
    el.calTargetType = 'image';
    el.calImageTargetFilename = [pwd '/' 'fixTarget.jpg'];
    
    % Set calibration beeps (0 = sound off, 1 = sound on)
    el.targetbeep = 0;  % sound a beep when a target is presented
    el.feedbackbeep = 0;  % sound a beep after calibration or drift check/correction
    
%     returnKey=KbName('return');
%     el.return = KbName(returnKey());
    
    % You must call this function to apply the changes made to the el structure above
    EyelinkUpdateDefaults(el);
    
    % Set display coordinates for EyeLink data by entering left, top, right and bottom coordinates in screen pixels
    Eyelink('Command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
    % Write DISPLAY_COORDS message to EDF file: sets display coordinates in DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Pre-trial Message Commands
    Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);    
    % Set number of calibration/validation dots and spread: horizontal-only(H) or horizontal-vertical(HV) as H3, HV3, HV5, HV9 or HV13
    Eyelink('Command', 'calibration_type = HV13'); % horizontal-vertical 13-points
    % Set the proportion area to calibrate
    Eyelink('Command','calibration_area_proportion = 0.715 0.94')
    
    %%%%%%%%%%%%%%%%% Uncomment following lines if area to calibrate must be defined
%     Eyelink('command', 'generate_default_targets = NO');
%     % STEP 5.1 modify calibration and validation target locations
%     Eyelink('command','calibration_samples = 6');
%     Eyelink('command','calibration_sequence = 0,1,2,3,4,5');
%     Eyelink('command','calibration_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
%         width/2,height/2,  width/2,height*0.2,  width/2,height - height*0.2,  width*0.2,height/2,  width - width*0.2,height/2 );
%     Eyelink('command','validation_samples = 5');
%     Eyelink('command','validation_sequence = 0,1,2,3,4,5');
%     Eyelink('command','validation_targets = %d,%d %d,%d %d,%d %d,%d %d,%d',...
%         width/2,height/2,  width/2,height*0.2,  width/2,height - height*0.2,  width*0.2,height/2,  width - width*0.2,height/2 );

% check if there is a command to directly change the area to calibrate
%     Eyelink('Command');

    % Allow a supported EyeLink Host PC button box to accept calibration or drift-check/correction targets via button 5
    Eyelink('Command', 'button_function 5 "accept_target_fixation"');
    % Hide mouse cursor
    HideCursor(screenNumber);
    % Start listening for keyboard input. Suppress keypresses to Matlab windows.
    ListenChar(-1);
    Eyelink('Command', 'clear_screen 0'); % Clear Host PC display from any previus drawing
    % Prepare grey background on backbuffer
    Screen('FillRect', window, el.backgroundcolour);
    % Put EyeLink Host PC in Camera Setup mode for participant setup/calibration
    EyelinkDoTrackerSetup(el);
    
    
    %% STEP 5: TRIAL LOOP.

Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before recording
Eyelink('StartRecording'); % Start tracker recording

TriggerIsDown=0;
Screen('DrawTexture', window, imgTextureFixation); %Draw the texture
Screen('Flip', window);

while ~TriggerIsDown
    [TriggerIsDown,~,~]=PsychHID('KbCheck',deviceIDTrigger,scanListTrigger);
    if TriggerIsDown
        t0 = GetSecs;
        Screen('DrawTexture', window, imgTextureFixation); %Draw the texture
        Screen('Flip', window); % Present stimulus
        WaitSecs(3.994); % Dummy Scans
        %WaitSecs(0.02); % Allow some time to record a few samples before presenting first stimulus
        for i = 1:length(imgList)
            Eyelink('Command', 'record_status_message "TRIAL %d/%d"', i, length(imgList));
            if strcmp(images{i},'fixationDot.png')
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %----------------------------- SHOW JITTER ----------------------------%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Screen('DrawTexture', window, imgTextureFixation); %Draw the texture
                [~, RtFixation]=Screen('Flip', window); % Present stimulus
                appearanceJitter(i)=(RtFixation-t0)*1000;
                Eyelink('Message', 'Jitter display: %d ms',round(RtFixation-t0)*1000);
                WaitSecs(duration(i))
                WaitSecs(0.005); % Allow some time before ending the trial  
            else
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %-------------------- SHOW FIXATION DOT FOR 500 ms --------------------%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Screen('DrawTexture', window, imgTextureFixation); %Draw the texture
                [~, RtFixation]=Screen('Flip', window); % Present stimulus
                appearanceFixation(i)=(RtFixation-t0)*1000;
                Eyelink('Message', 'Fixation display: %d ms',round(RtFixation-t0)*1000);
                WaitSecs(0.4944)

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %------------------- SHOW VISUAL SEARCH FOR 2750 ms -------------------%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Screen('DrawTexture', window, stimTextures(i)); % Prepare image texture on backbuffer
                [~, RtStart] = Screen('Flip', window); % Present stimulus
                appearance(i)=(RtStart-t0)*1000;
                % Write message to EDF file to mark the start time of stimulus presentation.
                Eyelink('Message', 'Stimuli display: %d ms, %s',round(appearance(i)),images{i});
                kcheck = 0;
                tic;
                while toc < 2.744 %2.75
                    [keyIsDown,RtEnd,keyCode] = PsychHID('KbCheck',deviceID,scanList);
                    if keyIsDown
                        if kcheck==0
                            % store the response
                            responses{i}=keyNames{keyCodes == find(keyCode==1)};
                            % Write message to EDF file to mark the spacebar press time
                            Eyelink('Message', 'KEY_PRESSED: %s',responses{i});
                            RT(i)=(RtEnd-RtStart)*1000;% Calculate RT from stimulus onset
                            Eyelink('Message', 'REACTION_TIME: %d',round(RT(i)));
                            kcheck=1;
                        end

                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %-------------------- SHOW FIXATION DOT FOR 750 ms --------------------%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Screen('DrawTexture', window, imgTextureFixation); %Draw the texture
                [~, RtFixation]=Screen('Flip', window); % Present stimulus
                appearanceAfterFixation(i)=(RtFixation-t0)*1000;
                Eyelink('Message', 'After fixation display: %d ms',round(RtFixation-t0)*1000);
                WaitSecs(0.7444) 
                WaitSecs(0.005); % Allow some time before ending the trial  
                % Clear Screen() textures that were initialized for each trial iteration
                Screen('Close', stimTextures(i));
            end
        end % End trial loop
        
        Eyelink('Message', 'End of experiment');
        
        % show 5 seconds in the end
        Screen('DrawTexture', window, imgTextureFixation); %Draw the texture
        [~, RtFixation]=Screen('Flip', window); % Present stimulus
        Eyelink('Message', 'Final: %d ms',round(RtFixation-t0)*1000);
        WaitSecs(7.9944)
        Eyelink('Message', 'The end');
        
        Screen('Flip', window);
    end
end
Eyelink('StopRecording'); % Stop tracker recording    
    %% STEP 6: CLOSE EDF FILE. TRANSFER EDF COPY TO DISPLAY PC. CLOSE EYELINK CONNECTION. FINISH UP
    
    % Put tracker in idle/offline mode before closing file. Eyelink('SetOfflineMode') is recommended.
    % However if Eyelink('Command', 'set_idle_mode') is used, allow 50ms before closing the file as shown in the commented code:
    % Eyelink('Command', 'set_idle_mode');% Put tracker in idle/offline mode
    % WaitSecs(0.05); % Allow some time for transition    
    Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
    Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
    WaitSecs(0.5); % Allow some time before closing and transferring file
    Eyelink('CloseFile'); % Close EDF file on Host PC
    % Transfer a copy of the EDF file to Display PC
    transferFile; % See transferFile function below
catch % If syntax error is detected
    % Print error message and line number in Matlab's Command Window
    psychrethrow(psychlasterror);
end
cleanup;

% Cleanup function used throughout the script above
    function cleanup
        try
            Screen('CloseAll'); % Close window if it is open
        end
        Eyelink('Shutdown'); % Close EyeLink connection
        ListenChar(0); % Restore keyboard output to Matlab
        ShowCursor; % Restore mouse cursor
        if ~IsOctave; commandwindow; end; % Bring Command Window to front
    end

% Function for transferring copy of EDF file to the experiment folder on Display PC.
% Allows for optional destination path which is different from experiment folder
    function transferFile
        try
            if dummymode ==0 % If connected to EyeLink
                % Show 'Receiving data file...' text until file transfer is complete
                Screen('FillRect', window, el.backgroundcolour); % Prepare background on backbuffer
                Screen('DrawText', window, 'Receiving data file...', 5, height-35, 0); % Prepare text
                Screen('Flip', window); % Present text
                fprintf('Receiving data file ''%s.edf''\n', edfFile); % Print some text in Matlab's Command Window
                
                % Transfer EDF file to Host PC
                % [status =] Eyelink('ReceiveFile',['src'], ['dest'], ['dest_is_path'])
                %status = Eyelink('ReceiveFile');
                % Optionally uncomment below to change edf file name when a copy is transferred to the Display PC
                % % If <src> is omitted, tracker will send last opened data file.
                % % If <dest> is omitted, creates local file with source file name.
                % % Else, creates file using <dest> as name.  If <dest_is_path> is supplied and non-zero
                % % uses source file name but adds <dest> as directory path.
                % newName = ['Test_',char(datetime('now','TimeZone','local','Format','y_M_d_HH_mm')),'.edf'];                
                newName = [edfFile,'_',char(datetime('now','TimeZone','local')),'.edf'];  
                status = Eyelink('ReceiveFile', [], newName, 0);
                
                % Check if EDF file has been transferred successfully and print file size in Matlab's Command Window
                if status > 0
                    fprintf('EDF file size: %.1f KB\n', status/1024); % Divide file size by 1024 to convert bytes to KB
                end
                % Print transferred EDF file path in Matlab's Command Window
                fprintf('Data file ''%s.edf'' can be found in ''%s''\n', edfFile, pwd);
            else
                fprintf('No EDF file saved in Dummy mode\n');
            end
        catch % Catch a file-transfer error and print some text in Matlab's Command Window
            fprintf('Problem receiving data file ''%s''\n', edfFile);
            psychrethrow(psychlasterror);
        end
    end
end

%% now write the file
% 
% [pathstr,name,ext] = fileparts(imgList)
% 
% table(images,"VariableNames", ...
%     ["image" "appearance (ms)" "response time (ms)" "response" ...
%     "correct response" "general accuracy (%)"]);
% 
% log.write(u'image,appearance (ms),appearance optSeq (ms),response time (ms),response,correct response,correct response 2,general accuracy (%)')
% 
% for i=1:length(response)
%     if(ismissing(R(i)))
%         R(i)={"Nil"};
%     else
%         continue;
%     end
% end