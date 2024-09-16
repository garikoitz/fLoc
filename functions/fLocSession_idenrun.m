classdef fLocSession_idenrun
    
    properties
        name      % participant initials or id string
        date      % session date
        trigger   % option to trigger scanner (0 = no, 1 = yes)
        num_runs  % number of runs in experiment
        sequence  % session fLocSequence object
        responses % behavioral response data structure
        parfiles  % paths to vistasoft-compatible parfiles
        use_eyelink % option to use eyelink in scanner (0 = no, 1 = yes)
    end
    
    properties (Hidden)
        stim_set  % stimulus set/s (1 = standard, 2 = alternate, 3 = both)
        task_num  % task number (1 = 1-back, 2 = 2-back, 3 = oddball)
        input     % device number of input used for resonse collection
        keyboard  % device number of native computer keyboard
        hit_cnt   % number of hits per run
        fa_cnt    % number of false alarms per run
    end
    
    properties (Constant)
        count_down = 12; % pre-experiment countdown (secs)
        stim_size = 768; % size to display images in pixels
    end
    
    properties (Constant, Hidden)
        task_names = {'1back' '2back' 'oddball'};
        exp_dir = fileparts(fileparts(which(mfilename, 'class')));
        fix_color = [255 0 0]; % fixation marker color (RGB)
        text_color = 255;      % instruction text color (grayscale)
        blank_color = 128;     % baseline screen color (grayscale)
        wait_dur = 1;          % seconds to wait for response
    end
    
    properties (Dependent)
        id        % session-specific id string
        task_name % descriptor for each task number
        el % eyelink initializer
    end
    
    properties (Dependent, Hidden)
        hit_rate     % proportion of task probes detected in each run
        instructions % task-specific instructions for participant
        dummymode % if eyelink is connected or not
        edfFile % the eyelink log file
    end
    
    methods
        
        % class constructor
        % name='test_tlei'; trigger=0; stim_set=1; num_runs=3; task_num=1; run_num=1;)
        function session = fLocSession_idenrun(name, trigger, stim_set, num_runs, task_num, use_eyelink)
            session.name = deblank(name);
            session.trigger = trigger;
            session.use_eyelink=use_eyelink;
            if nargin < 3
                session.stim_set = 3;
            else
                session.stim_set = stim_set;
            end
            if nargin < 4
                session.num_runs = 4;
            else
                session.num_runs = num_runs;
            end
            if nargin < 5
                session.task_num = 3;
            else
                session.task_num = task_num;
            end
            session.date = date;
            session.hit_cnt = zeros(1, session.num_runs);
            session.fa_cnt = zeros(1, session.num_runs);
        end
        
        % get session-specific id string
        function id = get.id(session)
            par_str = [session.name '_' session.date];
            exp_str = [session.task_name '_' num2str(session.num_runs) 'runs'];
            id = [par_str '_' exp_str];
        end
        
        % get name of task
        function task_name = get.task_name(session)
            task_name = session.task_names{session.task_num};
        end
        
        % get hit rate for task
        function hit_rate = get.hit_rate(session)
            num_probes = sum(session.sequence.task_probes);
            hit_rate = session.hit_cnt ./ num_probes;
        end
        
        % get instructions for participant given task
        function instructions = get.instructions(session)
            if session.task_num == 1
                instructions = 'Fixate. Press a button when an image repeats on sequential trials.';
            elseif session.task_num == 2
                instructions = 'Fixate. Press a button when an image repeats with one intervening image.';
            else
                instructions = 'Fixate. Press a button when a scrambled image appears.';
            end
        end
        
        % define/load stimulus sequences for this session
        function session = load_seqs(session)
            fname = [session.id '_fLocSequence.mat'];
            fpath = fullfile(session.exp_dir, 'data', session.id, fname);
            % make stimulus sequences if not already defined for session
            if ~exist(fpath, 'file')
                seq = fLocSequence_idenrun(session.stim_set, session.num_runs, session.task_num);
                seq = make_runs(seq);
                mkdir(fileparts(fpath));
                save(fpath, 'seq', '-v7.3');
            else
                load(fpath);
            end
            session.sequence = seq;
        end
        
        % register input devices
        function session = find_inputs(session)
            laptop_key = get_keyboard_num;
            button_key = get_box_num;
            % BCBL, seems that we need to set trigger to 1, because we are
            % actually using trigger box of scanner
            if session.trigger == 1 && button_key ~= 0
                session.keyboard = laptop_key;
                session.input = button_key;
            else
                % Okazaki: from the same usb the response box and the
                % keyboard is comming, being 5 de trigger of scanner and
                % 1,2,3,4 the button numbers. Make the input 5                
                % session.keyboard = button_key;
                % session.input = button_key;
                
                % BCBL: keyboard is keyboard, already assign the trigger box as keyboard
				% assign the response box as button_key/input/box
                % BCBL: get s from keyboard
                % get 4 from input
				session.keyboard = laptop_key; %laptop_key; % button_key % ;
                session.input = button_key;  %laptop_key; %button_key;
            end
        end
        

        % execute a run of the experiment
        function session = run_exp(session, run_num)
            % get timing information and initialize response containers
            session = find_inputs(session); k = session.input;
            sdc = session.sequence.stim_duty_cycle;
            stim_dur = session.sequence.stim_dur;
            isi_dur = session.sequence.isi_dur;
            stim_names = session.sequence.stim_names(:, run_num);
            stim_dir = fullfile(session.exp_dir, 'stimuli');
            tcol = session.text_color; bcol = session.blank_color; fcol = session.fix_color;
            resp_keys = {}; resp_press = zeros(length(stim_names), 1);
            % setup screen and load all stimuli in run
            
            [window_ptr, center] = do_screen;
            center_x = center(1); center_y = center(2); s = session.stim_size / 2;
            stim_rect = [center_x - s center_y - s center_x + s center_y + s];
            img_ptrs = [];
            for ii = 1:length(stim_names)
                if strcmp(stim_names{ii}, 'baseline')
                    img_ptrs(ii) = 0;
                else
                    cat_dir = stim_names{ii}(1:find(stim_names{ii} == '-') - 1);
                    img = imread(fullfile(stim_dir, cat_dir, stim_names{ii}));
                    img_ptrs(ii) = Screen('MakeTexture', window_ptr, img);
                end
            end
            % start experiment triggering scanner if applicable
            if session.trigger == 0
                Screen('FillRect', window_ptr, bcol);
                Screen('Flip', window_ptr);
                DrawFormattedText(window_ptr, session.instructions, 'center', 'center', tcol);
                Screen('Flip', window_ptr);
                get_key('s', session.keyboard);
            elseif session.trigger == 1
                Screen('FillRect', window_ptr, bcol);
                Screen('Flip', window_ptr);
                DrawFormattedText(window_ptr, session.instructions, 'center', 'center', tcol); % 'flipHorizontal', 1);
                Screen('Flip', window_ptr);
                while 1
                    get_key('s', session.keyboard);
                    [status, ~] = start_scan;
                    if status == 0
                        break
                    else
                        message = 'Trigger failed.';
                        DrawFormattedText(window_ptr, message, 'center', 'center', fcol);
                        Screen('Flip', window_ptr);
                    end
                end
            end
            %% if use eyelink, initialize eyelink and record things
            % if use_eyelink, start recording eyelink, otherwise, no
            if session.use_eyelink
                [session.el,session.dummymode, session.edfFile]=init_eyelink(session) ;
                disp("eyelink initialized ")
                Eyelink('SetOfflineMode');% Put tracker in idle/offline mode before recording
                Eyelink('StartRecording'); % Start tracker recording
                
                % display countdown numbers
                [cnt_time, rem_time] = deal(session.count_down + GetSecs);
                cnt = session.count_down;
                while rem_time > 0
                    if floor(rem_time) <= cnt
                        DrawFormattedText(window_ptr, num2str(cnt), 'center', 'center', tcol);
                        Screen('Flip', window_ptr);
                        cnt = cnt - 1;
                    end
                    rem_time = cnt_time - GetSecs;
                end
                
                start_time = GetSecs;
                for ii = 1:length(stim_names)
                    Eyelink('Command', 'record_status_message "TRIAL %d/%d"', ii, length(stim_names));
                    % display blank screen if baseline and image if stimulus
                    if strcmp(stim_names{ii}, 'baseline')
                        [~, RtFixation]=Screen('FillRect', window_ptr, bcol);
                        draw_fixation(window_ptr, center, fcol);
                        Eyelink('Message', 'Fixation display: %d ms',round(RtFixation-start_time)*1000);
                    else
                        [~, RtStart]=Screen('DrawTexture', window_ptr, img_ptrs(ii), [], stim_rect);
                        draw_fixation(window_ptr, center, fcol);
                        Eyelink('Message', 'Stimuli display: %d ms, %s',round((RtStart-start_time)*1000),stim_names{ii});
                    end
                    Screen('Flip', window_ptr);
                    % collect responses
                    ii_press = []; ii_keys = [];
                    [keys, ie] = record_keys(start_time + (ii - 1) * sdc, stim_dur, k);
                    ii_keys = [ii_keys keys]; ii_press = [ii_press ie];
                    % display ISI if necessary
                    if isi_dur > 0
                        Screen('FillRect', window_ptr, bcol);
                        draw_fixation(window_ptr, center, fcol);
                        [keys, ie] = record_keys(start_time + (ii - 1) * sdc + stim_dur, isi_dur, k);
                        ii_keys = [ii_keys keys]; ii_press = [ii_press ie];
                        Screen('Flip', window_ptr);
                    end
                    resp_keys{ii} = ii_keys;
                    resp_press(ii) = min(ii_press);
                    Eyelink('Message', 'End of experiment');
                end
            %% if don't use_eyelink, it's like before
            else
                % main display loop
                % display countdown numbers
                [cnt_time, rem_time] = deal(session.count_down + GetSecs);
                cnt = session.count_down;
                while rem_time > 0
                    if floor(rem_time) <= cnt
                        DrawFormattedText(window_ptr, num2str(cnt), 'center', 'center', tcol);
                        Screen('Flip', window_ptr);
                        cnt = cnt - 1;
                    end
                    rem_time = cnt_time - GetSecs;
                end
                start_time = GetSecs;
                for ii = 1:length(stim_names)
                    % display blank screen if baseline and image if stimulus
                    if strcmp(stim_names{ii}, 'baseline')
                        Screen('FillRect', window_ptr, bcol);
                        draw_fixation(window_ptr, center, fcol);
                    else
                        Screen('DrawTexture', window_ptr, img_ptrs(ii), [], stim_rect);
                        draw_fixation(window_ptr, center, fcol);
                    end
                    Screen('Flip', window_ptr);
                    % collect responses
                    ii_press = []; ii_keys = [];
                    [keys, ie] = record_keys(start_time + (ii - 1) * sdc, stim_dur, k);
                    ii_keys = [ii_keys keys]; ii_press = [ii_press ie];
                    % display ISI if necessary
                    if isi_dur > 0
                        Screen('FillRect', window_ptr, bcol);
                        draw_fixation(window_ptr, center, fcol);
                        [keys, ie] = record_keys(start_time + (ii - 1) * sdc + stim_dur, isi_dur, k);
                        ii_keys = [ii_keys keys]; ii_press = [ii_press ie];
                        Screen('Flip', window_ptr);
                    end
                    resp_keys{ii} = ii_keys;
                    resp_press(ii) = min(ii_press);
                end
            
            end
            if session.use_eyelink==1
                Eyelink('StopRecording'); % Stop tracker recording
                Eyelink('SetOfflineMode'); % Put tracker in idle/offline mode
                Eyelink('Command', 'clear_screen 0'); % Clear Host PC backdrop graphics at the end of the experiment
                WaitSecs(0.5); % Allow some time before closing and transferring file
                Eyelink('CloseFile'); % Close EDF file on Host PC
                % Transfer a copy of the EDF file to Display PC
                transferFile; % See transferFile function below
            end

            % store responses
            session.responses(run_num).keys = resp_keys;
            session.responses(run_num).press = resp_press;
            fname = [session.id '_backup_run' num2str(run_num) '.mat'];
            fpath = fullfile(session.exp_dir, 'data', session.id, fname);
            save(fpath, 'resp_keys', 'resp_press', '-v7.3');
            % analyze response data and display performance
            session = score_task(session, run_num);
            num_probes = num2str(sum(session.sequence.task_probes(:, run_num)));
            hit_cnt = num2str(session.hit_cnt(run_num));
            fa_cnt = num2str(session.fa_cnt(run_num));
            hit_rate = num2str(session.hit_rate(run_num) * 100);
            hit_str = ['Hits: ' hit_cnt '/' num_probes ' (' hit_rate '%)'];
            fa_str = ['False alarms: ' fa_cnt];
            Screen('FillRect', window_ptr, bcol);
            Screen('Flip', window_ptr);
            score_str = [hit_str '\n' fa_str];
            DrawFormattedText(window_ptr, score_str, 'center', 'center', tcol);
            Screen('Flip', window_ptr);
            
            % FOR OKAZAKI we will use 4, which is the control box red
            % button
            % For rest of places we can maintain 5 as the generic one
            % get_key('4', session.keyboard);
            % FOR BCBL it is 4 the red button from response box
            get_key('4', session.input);
            ShowCursor;
            Screen('CloseAll');
        end
        
        % quantify performance in stimulus task
        function session = score_task(session, run_num)
            sdc = session.sequence.stim_duty_cycle;
            fpw = session.wait_dur / sdc;
            % get response time windows for task probes
            resp_presses = session.responses(run_num).press;
            resp_correct = session.sequence.task_probes(:, run_num);
            probe_idxs = find(resp_correct);
            hit_windows = zeros(size(resp_correct));
            for ww = 1:ceil(fpw)
                hit_windows(probe_idxs + ww - 1) = 1;
            end
            hit_resp_windows = resp_presses(hit_windows == 1);
            fa_resp_windows = resp_presses(hit_windows == 0);
            % count hits and false alarms
            session.hit_cnt(run_num) = sum(max(reshape(hit_resp_windows, fpw, [])));
            session.fa_cnt(run_num) = sum(fa_resp_windows);
        end
        
        % write vistasoft-compatible parfile for each run
        function session = write_parfiles(session)
            session.parfiles = cell(1, session.num_runs);
            % list of conditions and plotting colors
            conds = ['Baseline' session.sequence.stim_conds];
            cols = {[1 1 1] [0 0 1] [0 0 0] [1 0 0] [.8 .8 0] [0 1 0]};
            % write information about each block on a separate line
            for rr = 1:session.num_runs
                block_onsets = session.sequence.block_onsets(:, rr);
                block_conds = session.sequence.block_conds(:, rr);
                cond_names = conds(block_conds + 1);
                cond_cols = cols(block_conds + 1);
                fname = [session.id '_fLoc_run' num2str(rr) '.par'];
                fpath = fullfile(session.exp_dir, 'data', session.id, fname);
                fid = fopen(fpath, 'w');
                for bb = 1:length(block_onsets)
                    fprintf(fid, '%d \t %d \t', block_onsets(bb), block_conds(bb));
                    fprintf(fid, '%s \t', cond_names{bb});
                    fprintf(fid, '%i %i %i \n', cond_cols{bb});
                end
                fclose(fid);
                session.parfiles{rr} = fpath;
            end
        end
        % funciton to close EDF file
        function transferFile(session)
            try
                if session.dummymode ==0 % If connected to EyeLink
                    % Show 'Receiving data file...' text until file transfer is complete
                    Screen('FillRect', window, session.el.backgroundcolour); % Prepare background on backbuffer
                    Screen('DrawText', window, 'Receiving data file...', 5, height-35, 0); % Prepare text
                    Screen('Flip', window); % Present text
                    fprintf('Receiving data file ''%s.edf''\n', session.edfFile); % Print some text in Matlab's Command Window
                    
                    % Transfer EDF file to Host PC
                    % [status =] Eyelink('ReceiveFile',['src'], ['dest'], ['dest_is_path'])
                    %status = Eyelink('ReceiveFile');
                    % Optionally uncomment below to change edf file name when a copy is transferred to the Display PC
                    % % If <src> is omitted, tracker will send last opened data file.
                    % % If <dest> is omitted, creates local file with source file name.
                    % % Else, creates file using <dest> as name.  If <dest_is_path> is supplied and non-zero
                    % % uses source file name but adds <dest> as directory path.
                    % newName = ['Test_',char(datetime('now','TimeZone','local','Format','y_M_d_HH_mm')),'.edf'];                
                    newName = [session.edfFile,'_',char(datetime('now','TimeZone','local')),'.edf'];  
                    status = Eyelink('ReceiveFile', [], newName, 0);
                    
                    % Check if EDF file has been transferred successfully and print file size in Matlab's Command Window
                    if status > 0
                        fprintf('EDF file size: %.1f KB\n', status/1024); % Divide file size by 1024 to convert bytes to KB
                    end
                    % Print transferred EDF file path in Matlab's Command Window
                    fprintf('Data file ''%s.edf'' can be found in ''%s''\n', session.edfFile, pwd);
                else
                    fprintf('No EDF file saved in Dummy mode\n');
                end
            catch % Catch a file-transfer error and print some text in Matlab's Command Window
                fprintf('Problem receiving data file ''%s''\n', session.edfFile);
                psychrethrow(psychlasterror);
            end
        end
    
    end
end

