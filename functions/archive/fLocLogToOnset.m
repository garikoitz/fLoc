function fLocLogToOnset(floc_dir,floc_log_folder_name,output_format)
%fLocLogToOnset Summary of this function goes here
%   This function is used to generate the onset files for 
%   Kepa SPM analysis, It will tak floc_log_folder_name, go to the folder and then
%   look for: runx.par
%           : fLoc_sequence
%           : and it will create a file with outputname called onset

% according to the floc_log_folder_name, get the dataset
% all_logs=dir(fullfile(floc_dir,'data',floc_log_folder_name));
%{
floc_dir='/Users/tiger/toolboxes/fLoc'
floc_log_folder_names=dir(fullfile(floc_dir,'data'))

% Use arrayfun to find lengths of each name
nameLengths = arrayfun(@(x) length(x.name), floc_log_folder_names);

% Create a logical index for names with 10 or more characters
longNameIndex = nameLengths >= 10;

% Filter the struct to only include rows with names of sufficient length
all_sessions = floc_log_folder_names(longNameIndex);

for i= 1: length(all_sessions)
floc_log_folder_name=all_sessions(i).name
fLocLogToOnset(floc_dir,floc_log_folder_name,'BIDS')
end;
%}




%floc_dir='/Users/tiger/toolboxes/fLoc'
flocsequence_fname=dir(fullfile(floc_dir,'data',floc_log_folder_name, '*fLocSequence.mat')).name;

part_to_remove='_fLocSequence.mat';
% fname=strrep(listing.name,part_to_remove,'');

% get the subject ID define by experimenter
subID_array=[split(floc_log_folder_name,'_')];
subID=subID_array{3};
sesID=subID_array{4};
num_of_run=6;
sequence=load(flocsequence_fname).seq;

% get onset and stimuli matrix.
stimuli_orig=sequence.stim_names;
onset_orig=sequence.stim_onsets;
task_probe=sequence.task_probes;

% modify stimulis and onset times
stimuli_reshape=reshape(stimuli_orig,[2736, 1]);

stimuli_nameonly=cellfun(@(x) [strsplit(x, '-')], stimuli_reshape, 'UniformOutput', false);



final_stimuli=cellfun(@(x) x{1}, stimuli_nameonly, 'UniformOutput', false);
stimuli_nonumbers=regexprep(final_stimuli, '[12]', '');

task_probe_reshape=reshape(task_probe,[2736, 1]);

for i = 1:length(task_probe_reshape)
    if task_probe_reshape(i) == 1
        final_stimuli{i} = [final_stimuli{i} "_OBTask"];  % Append ' task' to the existing string
    end
end


onset_reshape=reshape(onset_orig,[2736, 1]);
onset_reshape_addtime=onset_reshape;
% Create the offset for each run
% Increment each subsequent run by 228 more than the previous run
offsetIncrement = 228;
offsets = (0:(num_of_run - 1)) * offsetIncrement;

% Apply the offsets to each run in the array
for run = 1:num_of_run
    % Calculate the range of indices for this run
    startIndex = (run - 1) * size(onset_orig,1) + 1;
    endIndex = run * size(onset_orig,1);

    % Apply the offset
    onset_reshape_addtime(startIndex:endIndex) = onset_reshape_addtime(startIndex:endIndex) + offsets(run);
end

% Create the array for runs
runs = repelem(1:num_of_run,  size(stimuli_orig,1))';
% create the array for subs
subID_col= repmat(subID, 2736, 1);

%% make the onset table
if strcmp(output_format,'SPM')
    onset_table = table(subID_col, runs, stimuli_nonumbers, onset_reshape, ...
        'VariableNames', {'SubjectID', 'Run', 'Cond', 'Onset'});

    a=mkdir(fullfile(floc_dir,"onset_spm"));

    block_index=1:12:size(onset_table,1); 

    shrinked_table=onset_table(block_index,:);
    % Write the table to an Excel file
    filename = sprintf('%s_%s_onset.xls', subID, sesID);

    writetable(shrinked_table,fullfile(floc_dir,"onset_spm", filename));


elseif strcmp(output_format,'BIDS')
    task_name='fLoc';
    
    duration=repmat(6, 2736, 1);
    onset_table = table(onset_reshape, duration, stimuli_nonumbers,  ...
        'VariableNames', {'onset', 'duration', 'trial_type'});
    b=mkdir(fullfile(floc_dir,"onset_bids"));

    block_index=1:12:size(onset_table,1); 
    
    
    shrinked_table=onset_table(block_index,:);
    

    run_nums=1:6;

    for i = run_nums
        run_table=shrinked_table(1+38*(i-1):38*i,:);
        % Write the table to an Excel file
        filename = sprintf('%s_%s_task-%s_run-%02i_events.tsv', subID, sesID, task_name, i);
        writetable(run_table,fullfile(floc_dir,"onset_bids", filename), 'Delimiter', '\t', 'FileType', 'text') ;
    end
     
    
end



end



