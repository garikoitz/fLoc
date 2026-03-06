%{
This script is to batch processing the fLoc logs, it will read the folder
name, 
1. check if folder name is consistant with the fLoc datadir name, if not
will rename it in the votclocSession.mat and make it consistant, also it
will read the date from the xlsx file online, and according to that do the
renaming, so everything will have a double check

2. will check if there are backupruns.mat, if so will calculate the
accuracy and FA and exported it as a txt file and put under the datadir

3. will check if there are _backup.mat for votclocSession and
votclocSequence, if not will create one so we always have all info

4. will output the events.tsv if they are not inplace

%}



% first get the basedir
sourcedata_dir = '/bcbl/home/public/Gari/VOTCLOC/main_exp/BIDS/sourcedata';
% read the schedule table remeber to format the sub and ses id to 01 
T = readtable(fullfile(sourcedata_dir,'subses_schedule.csv'));
T.date.Format = 'dd-MMM-yyyy';
%% the looping logic
% from sub ses list, get the fLoc specific dir that are equivlent to
% data/sub-xx_ses-xx
% right now, hardcoded sub and ses
subs = arrayfun(@(x) sprintf('%02d', x), 1:11, 'UniformOutput', false);
% first run the general sess, there are others like 08rerun etc
sess = arrayfun(@(x) sprintf('%02d', x), 1:10, 'UniformOutput', false);
% there are some rerun stuff not here, so will do it manually

% build the looping logic
for subI=1:length(subs)
    for sesI = 1:length(sess)
        sub = subs{subI};
        ses = sess{sesI};
        sprintf('working on sub-%s ses-%s \n',sub, ses );
    end;
end;

%% load the session for checking
subses_sourcedata = fullfile(sourcedata_dir,['sub-' sub],['ses-' ses]);
d = dir(fullfile(subses_sourcedata, ['sub-' sub '_' 'ses-' ses '*']));
d = d([d.isdir]);
floc_log_dir = fullfile(d.folder,d.name);
% get the session.mat
session_mat_d = dir(fullfile(floc_log_dir,'*votclocSession.mat'));
session_mat_path = fullfile(session_mat_d.folder, session_mat_d.name);
session = load(session_mat_path).session;
disp('Successfully load the votcloc sequence and session object')

% check 
% 1. if the folder name under sourcedata/sub-/ses-/xxxx_fLoc_XXXX matches
% the sub and ses id
floc_log_name = d.name;

% 2. check the date if match
row = (compose("%02d",T.sub) == sub) & (compose("%02d",T.ses) == ses);
date_from_log = T.date(row);
% 3. need to rename it if needed
%% when starting, create a backup of the source votclocSession and
% votclocSequence.mat and make the new things
targ_session_name = strrep(session_mat_path, 'Session.mat','Session_backup.mat');
src_seq_name = strrep(session_mat_path, 'Session.mat','Sequence.mat');
targ_seq_name = strrep(src_seq_name, 'Sequence.mat','Sequence_backup.mat');

% backup the orig session.mat
if ~isfile(targ_session_name)
    copyfile(session_mat_path, targ_session_name,'f');
    disp("succesfully backed up the session.mat")
else
    disp("backup of session.mat is already there")
end
% backup the orig sequence.mat
if ~isfile(targ_seq_name)
    copyfile(src_seq_name, targ_seq_name,'f');
    disp("succesfully backed up the sequence.mat")
else
    disp("backup of sequence.mat is already there")
end
%% check if the sesssion.id and session.name is equals to the dir name)
session_file_name = session_mat_d.name;
seq_file_name = strrep(session_file_name,'Session.mat','Sequence.mat');
session_id_name = [session.id '_votclocSession.mat'];
seq_id_name = [session.id '_votclocSequence.mat'];
% for session.mat, we also need to check it the name matches with the run
name = session.name ; 
disp(name);

if strcmp(session_file_name, session_id_name)
    disp('session.mat save name and orig are the same, do nothing')
else
    disp('session.mat save name and org name are different, will use save name')
    save(fullfile(session_mat_d.folder,session_id_name),'session', '-v7.3')
end

% for sequence, only need to save it with new name
if strcmp(seq_file_name, seq_id_name)
    disp('sequence.mat save name and orig are the same, do nothing')
else
    disp('sequence.mat save name and org name are different, will use save name')
    save(fullfile(session_mat_d.folder,seq_id_name),'sequence', '-v7.3')
end
%%
% edit the score_task_use_backup function to get a csv storing the hit rate
% and the false alarms
run_num=1
backup_runs = dir(fullfile(floc_log_dir,'*backup_run*.mat'));
backup_name = backup_runs(1).name
%%
% also create the events.tsv if not exists