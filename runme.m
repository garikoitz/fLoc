function runme(name, lang, trigger, stim_set, num_runs, task_num, use_eyelink, start_run)
%{ 
Prompts experimenter for session parameters and executes functional localizer experiment used 
to define regions in high-level visual cortex selective to faces, places, bodies, and printed characters.

Inputs (optional):
  1) name -- session-specific identifier (e.g., particpant's initials)
  2) language -- language of the participant (e.g., CN, ES, JP, AT, FR, IT)
  3) trigger -- option to trigger scanner (0 = no, 1 = yes)
  4) stim_set -- stimulus set (1 = standard, 2 = alternate, 3 = both) % for
  VOTCLOC we will always use 1. because we already combine Faces catagory
  and Limbs catagory into a big stimulus set
  5) num_runs -- number of runs (stimuli repeat after 2 runs/set)
  6) task_num -- which task (1 = 1-back, 2 = 2-back, 3 = oddball)
  7) use_eyelink -- options to use eyelink (0 = no, 1 = yes )
  8) start_run -- run number to begin with (if sequence is interrupted)


To run the experiment use:
========
20260215    
scan VOTCLOC_kids sub-01_ses-01
This means: 
participant name:S1_s1_sub-01_ses-01
language: EU (Basque)
trigger: 0 (no)
stim_set: 1 (standard)
num_runs: 2
task_num: 3 (oddball)
use_eyelink: 0 (No)
runme('S1_s1_sub-01_ses-01','EU',0,1,2,3,0);

TK was always scanned with lights on.
A couple of times scanner B was stopped with reconstruction errors, we
restarted the functional in the correct scanner option and that was it.
 There where a couple of times that the scan was started but the log or not
 or whatever. They will have less amount of scans, so not convert and
 that's it. The rest seems to be ok. 


========
20260506 
runme('s2_s1_sub-02_ses-01','EU',0,1,2,3,0);

========
20260512 
runme('s3_s1_sub-03_ses-01','EU',0,1,2,3,0);


FOR WORD HEIGHT CALCULATION
===========================

BCBL
----
Screen resolution: 
Screen size: heigth: 41, width:55 %measured 0916 2024
Screen distance: 
Square inside screen: height: 31 cm ; width: 33 cm
The CB are size is: height: 6 cm; word 4cm

(This one needs to change because I measure it wrong! )


****
For the eyetracker, it will take the first 5 elements of the subject name
you input, so try to give all the info within 5 elements, and the n put the
note after
sub-01_ses-01_Language_IT  etc
you can do: s1_1
if it is sub10 put SX_sX
****

Ask participant to press red button which is number 4

Then start the sequence on MRI MRI will pulse s to the prompt

# To end the process: 
cmd+0: to be in the command line
shift+cmd+0: to go  back to the editor
shift+return: 

# to stop the experiment
ctrl-c
sca
Screen('Close')



Version 0.0.2/2024
Yongning Lei (t.lei@bcbl.eu)
Basque Center on Cognition Brain and Language
Was derived from Anthony Stigliani (astiglia@stanford.edu)
%}

%% add paths and check inputs

% session name
if nargin < 1
    name = [];
    while isempty(deblank(name))
        name = input('Subject initials : ', 's');
    end
end

% session lang
if nargin < 3
    lang = [];
    while isempty(deblank(lang))
        lang = input('Testing language : ', 's');
    end
end
% option to trigger scanner
if nargin < 3
    trigger = -1;
    while ~ismember(trigger, 0:1)
        sca
        trigger = input('Trigger scanner? (0 = no, 1 = yes) : ');
    end
end

% which stimulus set/s to use
if nargin < 4
    stim_set = -1;
    while ~ismember(stim_set, 1:3)
        stim_set = input('Which stimulus set? (1 = standard, 2 = alternate, 3 = both) : ');
    end
end

% number of runs to generate
if nargin < 5
    num_runs = -1;
    while ~ismember(num_runs, 1:24)
        num_runs = input('How many runs? : ');
    end
end

% which task to use
if nargin < 6
    task_num = -1;
    while ~ismember(task_num, 1:3)
        task_num = input('Which task? (1 = 1-back, 2 = 2-back, 3 = oddball) : ');
    end
end
if nargin < 7
    use_eyelink = -1;
        while ~ismember(use_eyelink, 0:1)
            use_eyelink = input('Use Eyetracker? (0 = no, 1 = yes) : ');
        end
end
% which run number to begin executing (default = 1)
if nargin < 8
    start_run = 1;
end


%% initialize session object and execute experiment

% setup votclocSession and save session information
session = votclocSession(name, lang, trigger ,stim_set, num_runs, task_num, use_eyelink);
session = load_seqs(session);
session_dir = (fullfile(session.exp_dir, 'data', session.id));

script_session_ID=sprintf("########### Session ID is %s ########### \n", session.id);
disp(script_session_ID);
% print the number of TR in the command to help checking the sequence
seq=session.sequence;
TR=2;
onset_dur=seq.stim_dur+seq.isi_dur;
num_of_stim=length(seq.stim_onsets);

NORDIC_scans=1;
dummy_scans=5;
%counter down is in sec
count_down=session.count_down; 
num_of_TR=dummy_scans+count_down/TR-dummy_scans+round(num_of_stim/(TR/onset_dur))+NORDIC_scans;

script_TR=sprintf("########### Total volumns for this experiment is %i ########### \n", num_of_TR);
disp(script_TR);

if ~exist(session_dir, 'dir') == 7
    mkdir(session_dir);
end
fpath = fullfile(session_dir, [session.id '_votclocSession.mat']);
save(fpath, 'session', '-v7.3');

% execute all runs from start_run to num_runs and save parfiles
fname = [session.id '_votclocSession.mat'];
%disp('###### fname is')
%ddisp(fname)
fpath = fullfile(session.exp_dir, 'data', session.id, fname);

for rr = start_run:num_runs
    script_startrun=sprintf("########### The current run is %i ########### \n", rr);
    disp(script_startrun);
    session = run_exp(session, rr);
    save(fpath, 'session', '-v7.3');
end
%write_parfiles(session);
write_event_tsv(session);

end
