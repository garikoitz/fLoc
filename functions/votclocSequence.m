classdef votclocSequence
    
    properties
        lang        % stimulus langauge
        num_runs    % number of runs in experiment
        stim_onsets % onset times of each stimulus in a run
        stim_names  % sequence of stimulus fildnames
        task_probes % index of stimuli that are task probes
    end
    
    properties (Hidden)
        stim_set     % stimulus set/s (1 = standard, 2 = alternate, 3 = both)
        task_num     % task number (1 = 1-back, 2 = 2-back, 3 = oddball)
        block_onsets % block onsets relative to beginning of run (seconds)
        block_conds  % block conditions labels
    end
    
    properties (Constant)
        % for kids now we are going to use RWvsPER, so will only maintain
        % RealWords and Scrambled
        %stim_conds = {'Bodies' 'RealWords' 'Faces' 'FalseFonts' 'ConsonantStrings' 'Srambled'};
        stim_conds = {'RealWords' 'Srambled'};
        stim_per_block = 12;   % number of stimuli in a block
        stim_duty_cycle = 0.5; % duration of stimulus duty cycle (s)
        run_kids = true;
    end
    
    properties (Constant, Hidden)
        % JP
        % stim_set1 = {'body' 'JP_word1' 'adult' 'JP_FF1' 'JP_CB1'};
        % stim_set2 = {'limb' 'JP_word2' 'child' 'JP_CS1' 'JP_SC1'};
        % EU
        % stim_set1 = {'body' 'EU_word1' 'adult' 'EU_FF1' 'EU_CB1'};
        % stim_set2 = {'limb' 'EU_word2' 'child' 'EU_CS1' 'EU_SC1'};
        % ES
        % stim_set1 = {'bodylimb' '_RW' 'face' 'ES_FF' 'ES_CS' 'ES_SC'};
        % stim_set2 = {'limb' 'ES_word' 'child' 'ES_CS' 'ES_SC'};

        % stim_set1 = {'body' 'chars' 'adult' 'instrument' 'corridor'};
        % stim_set2 = {'limb' 'numbers' 'child' 'car' 'house'};
        block_per_active_cond = 15;
        block_per_rest_cond = 6;
        stim_per_set = 80; % because now for CN FF there are only 52
        task_names = {'1back' '2back' 'oddball'};
        task_freq = 0.5;
    end
    
    properties (Dependent)
        task_name % descriptor for each task number
        run_dur   % run duration (seconds)
        stim_dur  % stimulus duration (seconds)
        isi_dur   % interstimulus interval duration (seconds)
    end
    
    properties (Dependent, Hidden)
        stim_set1 % dynamically generate stimulus set based on lang
        stim_set2 % dynamically generate stimulus set based on lang
        num_conds % number of conditions in experiment
        run_sets  % stimulus set used in each run
        
    end
    
    methods
         
        % class constructor
        function seq = votclocSequence(lang, stim_set, num_runs, task_num)
            if nargin < 1
                % default language will be EU
                seq.lang = 'EU';
            else
                seq.lang=lang;
            end
            if nargin < 2
                seq.stim_set = 1;
            else
                seq.stim_set = stim_set;
            end
            if nargin < 3
                seq.num_runs = 5;
            else
                seq.num_runs = num_runs;
            end
            if nargin < 4
                seq.task_num = 1;
            else
                seq.task_num = task_num;
            end
        end
        
        % get name of task
        function task_name = get.task_name(seq)
            task_name = seq.task_names{seq.task_num};
        end

        % get run duration given stimulus duty cycle
        function run_dur = get.run_dur(seq)
            block_dur = seq.stim_per_block * seq.stim_duty_cycle; % 12 * 0.5 = 6s
            % inner blocks: 2 active conds * 15 blocks + 6 rest blocks = 36
            % + 2 padding blocks (start + end)
            % total = 38 blocks
            num_blocks = seq.num_conds * seq.block_per_active_cond ...
                    + seq.block_per_rest_cond ...
                    + 2; % padding
            run_dur = block_dur * num_blocks; % 6 * 38 = 228s
        end

        
        % get ISI duration given task
        function isi_dur = get.isi_dur(seq)
            if seq.task_num == 3
                isi_dur = 0;
            else
                isi_dur = 0.2;
            end
        end
        
        % get stimulus duration given ISI
        function stim_dur = get.stim_dur(seq)
            stim_dur = seq.stim_duty_cycle - seq.isi_dur;
        end
        
        % get number of experimental conditions including baseline
        function num_conds = get.num_conds(seq)
            num_conds = length(seq.stim_conds); % 2 (RealWords, Scrambled)
        end

        
        % get image sets for each run given selection
        function run_sets = get.run_sets(seq)
            switch seq.stim_set
                case 1
                    run_sets = repmat(seq.stim_set1, seq.num_runs, 1);
                case 2
                    run_sets = repmat(seq.stim_set2, seq.num_runs, 1);
                case 3
                    run_sets = [seq.stim_set1; seq.stim_set2];
                    cat_iters = ceil(seq.num_runs / 2);
                    run_sets = repmat(run_sets, cat_iters, 1);
                    run_sets = run_sets(1:seq.num_runs, :);
                otherwise
                    error('Invalid stim_set argument.');
            end
        end
        
        % dynamically generate stimulus set based on lang
        % function stim_set1 = get.stim_set1(seq)
        %     stim_set1= {...
        %         'bodylimb1' ...
        %         sprintf('%s_RW1',seq.lang) ...
        %         'face1' ...
        %         sprintf('%s_FF1',seq.lang) ...
        %         sprintf('%s_CS1',seq.lang) ...
        %         sprintf('%s_SC1',seq.lang) ...
        %         };
        % end
        % function stim_set2 = get.stim_set2(seq)
        %     stim_set2= {...
        %         'bodylimb2' ...
        %         sprintf('%s_RW2',seq.lang) ...
        %         'face2' ...
        %         sprintf('%s_FF2',seq.lang) ...
        %         sprintf('%s_CS2',seq.lang) ...
        %         sprintf('%s_SC2',seq.lang) ...
        %         };
        % end

        % get new stimulis set for kids condition: RW and SC only
        function stim_set1 = get.stim_set1(seq)
            stim_set1= {...
                sprintf('%s_RW1',seq.lang) ...
                sprintf('%s_SC1',seq.lang) ...
                };
        end
        % get new stimulis set for kids condition: RW and SC only
        function stim_set2 = get.stim_set2(seq)
            stim_set2= {...
                sprintf('%s_RW2',seq.lang) ...
                sprintf('%s_SC2',seq.lang) ...
                };
        end        
        % get total number of stim of one set in each run
        %{
        function stim_per_set = get.stim_per_set(seq)
            stim_per_set=seq.block_per_active_cond*seq.stim_per_block;
        end
    %}
              

        % generate randomized stimulus sequences and insert task probes
        function seq = make_runs(seq)

            % --- Derived counts ---
            num_active_blocks = seq.num_conds * seq.block_per_active_cond; % 2*15 = 30
            num_inner_blocks  = num_active_blocks + seq.block_per_rest_cond; % 30+6 = 36
            num_total_blocks  = num_inner_blocks + 2; % +2 padding = 38
            block_dur = seq.stim_per_block * seq.stim_duty_cycle; % 6s

            % -------------------------------------------------------
            % 1. Build shuffled stimulus number pools per category
            % -------------------------------------------------------
            % Each active condition uses block_per_active_cond * stim_per_block
            % = 15 * 12 = 180 images per category per run.
            [unique_cats, ~, idxs] = unique(seq.run_sets(:));
            unique_cats = unique_cats';
            cnts = accumarray(idxs(:), 1, [], @sum)'; % times each category appears across runs

            % total images needed per category across all runs
            stim_per_cat = cnts * seq.stim_per_block * seq.block_per_active_cond;
            cycles_per_cat = ceil(stim_per_cat / seq.stim_per_set);

            % randomize stimulus numbers, cycling through full permutations
            % to minimize image repetition
            stim_nums = cell(1, length(cycles_per_cat));
            for cc = 1:length(cycles_per_cat)
                for cy = 1:cycles_per_cat(cc)
                    stim_nums{cc} = [stim_nums{cc} randperm(seq.stim_per_set)];
                end
            end
            % trim to exact count needed
            stim_nums = cellfun(@(X, Y) X(1:Y), stim_nums, ...
                num2cell(stim_per_cat), 'uni', false);

            % -------------------------------------------------------
            % 2. Get block condition order for each run
            % -------------------------------------------------------
            % block_conds: num_inner_blocks x num_runs matrix
            % values: 0 = baseline, 1 = cond1 (RW), 2 = cond2 (SC)
            if seq.run_kids
                block_conds = make_orders_kids(seq.num_conds, ...
                    seq.block_per_active_cond, seq.block_per_rest_cond, seq.num_runs);
            else
                block_conds = make_orders(seq.num_conds, ...
                    seq.block_per_active_cond, seq.block_per_rest_cond, seq.num_runs);
            end
            % add padding baseline blocks at start and end
            block_conds = [zeros(1, seq.num_runs); ...
                        block_conds; ...
                        zeros(1, seq.num_runs)];
            % block_conds is now num_total_blocks x num_runs

            % block onsets (same for all runs)
            block_onsets = repmat((0:block_dur:seq.run_dur - block_dur)', 1, seq.num_runs);

            % -------------------------------------------------------
            % 3. Map blocks to stimulus filenames
            % -------------------------------------------------------
            stim_mat = cell(seq.stim_per_block, num_total_blocks, seq.num_runs);
            for rr = 1:seq.num_runs
                % cat_list: index 1 = 'baseline', index 2+ = active categories
                cat_list = ['baseline' seq.run_sets(rr, :)];
                % map block condition indices to category names
                cat_seq = cat_list(block_conds(:, rr) + 1);
                % MATLAB note: cat_seq is 1 x num_total_blocks, repmat across stim_per_block rows
                stim_mat(:, :, rr) = repmat(cat_seq, seq.stim_per_block, 1);
            end

            % assign image numbers from the shuffled pools
            stim_cat_list = reshape(stim_mat, [], 1);
            stim_num_list = zeros(size(stim_cat_list));
            for cc = 1:length(unique_cats)
                cat_idxs = find(strcmp(unique_cats{cc}, stim_mat));
                stim_num_list(cat_idxs) = stim_nums{cc};
            end

            % build filename strings
            stim_num_list = num2cell(stim_num_list);
            stim_num_list = cellfun(@(X) ['-' num2str(X) '.jpg'], ...
                stim_num_list, 'uni', false);
            stim_num_list = strrep(stim_num_list, '-0.jpg', ''); % baseline gets no number
            stim_list = cellfun(@(X, Y) [X Y], stim_cat_list, stim_num_list, 'uni', false);

            % -------------------------------------------------------
            % 4. Insert task probes
            % -------------------------------------------------------
            probes_per_run = floor(seq.task_freq * num_active_blocks); % floor(0.5 * 30) = 15

            if seq.task_num == 2
                % 2-back: probe position must be >= 3
                probe_pos = randi(seq.stim_per_block - 3, [probes_per_run seq.num_runs]) + 2;
            else
                % 1-back or oddball: probe position must be >= 2
                probe_pos = randi(seq.stim_per_block - 2, [probes_per_run seq.num_runs]) + 1;
            end

            probe_stim_mat = zeros(seq.stim_per_block, num_total_blocks, seq.num_runs);
            for rr = 1:seq.num_runs
                % select random active blocks to receive probes
                active_block_idxs = shuffle(find(block_conds(:, rr) > 0));
                xi = probe_pos(:, rr);
                yi = sort(active_block_idxs(1:probes_per_run));
                zi = repmat(rr, probes_per_run, 1);
                run_probe_idxs = sub2ind(size(probe_stim_mat), xi, yi, zi);
                probe_stim_mat(run_probe_idxs) = 1;
            end

            probe_stim_idxs = find(probe_stim_mat);
            if seq.task_num == 1
                % 1-back: replace probe with copy of previous stimulus
                probe_stim_names = stim_list(probe_stim_idxs - 1);
            elseif seq.task_num == 2
                % 2-back: replace probe with copy of stimulus 2 positions back
                probe_stim_names = stim_list(probe_stim_idxs - 2);
            else
                % oddball: replace with random alien-on-scrambled image
                oddball_nums = num2cell(randi(8, ...
                    probes_per_run * seq.num_runs, 1));
                probe_stim_names = cellfun(@(X) ['aliens-scrambled_alien_' num2str(X) '.jpg'], ...
                    oddball_nums, 'uni', false);
            end
            stim_list(probe_stim_idxs) = probe_stim_names;

            % -------------------------------------------------------
            % 5. Reshape into per-run outputs
            % -------------------------------------------------------
            num_stim_per_run = seq.stim_per_block * num_total_blocks; % 12 * 38 = 456
            stim_names  = reshape(stim_list, num_stim_per_run, seq.num_runs);
            stim_onsets = repmat((0:seq.stim_duty_cycle:seq.run_dur - seq.stim_duty_cycle)', ...
                1, seq.num_runs);
            task_probes = reshape(probe_stim_mat, num_stim_per_run, seq.num_runs);

            % -------------------------------------------------------
            % 6. Store results
            % -------------------------------------------------------
            seq.block_onsets = block_onsets;
            seq.block_conds  = block_conds;
            seq.stim_onsets  = stim_onsets;
            seq.stim_names   = stim_names;
            seq.task_probes  = task_probes;
        end
    end
    
end

