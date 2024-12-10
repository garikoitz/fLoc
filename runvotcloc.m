function runvotcloc(name, lang, trigger, stim_set, num_runs, task_num, use_eyelink, start_run)
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

Run fLocMINI using this command: 
runme('okazaki_pilot_01_initials, 0, 3, 4, 1, start_run) % Edit if interrupted


20240129 MORNING
runme('okazaki_multisite_20240129_DT', 0, 3, 6, 1): scanner B
runme('okazaki_multisite_20240129_ST', 0, 3, 6, 1): scanner B

20240129 AFTERNOON
runme('okazaki_multisite_20240129_TM_B', 0, 3, 6,1);  scanner B
runme('okazaki_multisite_20240129_TK_B', 0, 3, 6,1);  scanner B

20240130 MORNING
runme('okazaki_multisite_20240130_ST_B', 0, 3, 6, 1): scanner B
runme('okazaki_multisite_20240130_DT_B', 0, 3, 6, 1): scanner B

20240130 AFTERNOON
runme('okazaki_multisite_20240130_TK_B', 0, 3, 6,1);  scanner B
runme('okazaki_multisite_20240130_TM_B', 0, 3, 6,1);  scanner B

TK was always scanned with lights on.
A couple of times scanner B was stopped with reconstruction errors, we
restarted the functional in the correct scanner option and that was it.
 There where a couple of times that the scan was started but the log or not
 or whatever. They will have less amount of scans, so not convert and
 that's it. The rest seems to be ok. 


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

VIENNA
------
Screen resolution: 
Screen size: 
Screen distance: 

OKAZAKI
-------
Screen resolution: 1280 x 1024
Screen size: 391mm →13.1deg 
Screen distance: 1704mm 
Outside gray square: w: 43cm, h: 32.5cm
Inside stimulus size (phase scrambled size): w: 26cm, h: 24.5
The height of letters it was aprox 3.5, checkerboards height: 4cm

it seems that pixels are not rectangular, same image in the console display
was: outside grey square: w: 37.5cm, h: 30 cm
inside phase scrambles square: 22.5cm per side

TAMAGAWA
--------
Screen resolution: 1920 x 1080
Screen size: vertical 239mm, horiz: 420mm 
Screen distance: 854mm
See photo of square inside screen: h: 169 mm ; v: 169 mm
Outside square: The phase scrambled are size is: h:421
v:242mm


========
20240911
--------
runvotcloc('test_newseq', 0, 1, 5, 1);
## the stimulus set is using first set, not things combined. 


========
20240916
--------
runvotcloc('test_newname', 0, 1, 3, 1, 0);

========
20240917
--------
runvotcloc('test_eylink_msg01', 0, 1, 3, 1, 1);


runvotcloc('test_eylink_luo01', 0, 1, 10, 1, 1);

runvotcloc('TLEI_test', 0, 1, 10, 1, 1)
========
20241025
runvotcloc('iderun_testLUO', 0, 1, 6, 1, 1)
上次的note 不知道在哪了
第二次重新进入的时候，有没有调整idrun的run数？
========
20241029
runvotcloc('sprun_testLUO', 0, 3, 6, 1, 1)
test sprun 6 run, equal to 3 complementary run, 
also gonna test if eye_link works well

========
20241111
New FEATURE BCBL: I add lang to the runvotcloc parametes, from now on there
will be 8 parameters

========
20241113
scan Jessi testing
runvotcloc('Jessi_ES','ES',0,1,5,1,1)
========
20241114
scan Daiki multisite
runvotcloc('Daiki_multisite','JP',0,1,10,1,1)

========
20241126
scan VOTCLOC sub-03_ses-01
runvotcloc('sub3s01','IT',0,1,10,1,1)

========
20241128
scan VOTCLOC sub-08_ses-01
runvotcloc('S8_s1_sub-08_ses-01','IT',0,1,10,1,1)

========
20241129
scan VOTCLOC sub-01_ses-01
runvotcloc('S1_s1_sub-01_ses-01','ES',0,1,10,1,1)

========
20241203
scan VOTCLOC sub-04_ses-01
runvotcloc('S4_s1_sub-06_ses-01','AT',0,1,10,1,1);

========
20241203
scan VOTCLOC sub-03_ses-02
runvotcloc('S3_s2_sub-03_ses-02','IT',0,1,10,1,1)





#####




BCBL
========

****
For the eyetracker, it will take the first 5 elements of the subject name
you input, so try to give all the info within 5 elements, and then put the
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

script_TR=sprintf("########### \n Total volumns for this experiment is %i \n ########### \n", num_of_TR);
disp(script_TR);

if ~exist(session_dir, 'dir') == 7
    mkdir(session_dir);
end
fpath = fullfile(session_dir, [session.id '_votclocSession.mat']);
save(fpath, 'session', '-v7.3');

% execute all runs from start_run to num_runs and save parfiles
fname = [session.id '_votclocSession.mat'];
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
