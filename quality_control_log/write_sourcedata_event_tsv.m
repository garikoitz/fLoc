% this is for clean and make the file name of the sourcedata folder
% votclocsequence and votclocsession .mat consistant
% write vistasoft-compatible parfile for each run
function session = write_sourcedata_event_tsv(session)
    disp('Start to writing event_tsv files');
    session.event = cell(1, session.num_runs);
    % list of conditions and plotting colors
    conds = ['Baseline' session.sequence.stim_conds];
    stim_cat = ['baseline' session.sequence.stim_set1];
    duration= session.sequence.stim_per_block*session.sequence.stim_duty_cycle;
    % write information about each block on a separate line
    for rr = 1:session.num_runs
        block_onsets = session.sequence.block_onsets(:, rr);
        block_conds = session.sequence.block_conds(:, rr);
        cond_names = stim_cat(block_conds + 1);
        parts_id=split(session.id, '_');
        fname = [parts_id{1}  '_' parts_id{2} '_' parts_id{3} '_run-' num2str(rr, '%02d') '_events.tsv'];
        %if it is using after the experiment
        sourcedata_dir = '/bcbl/home/public/Gari/VOTCLOC/main_exp/BIDS/sourcedata';
        subses = 'sub-04/ses-01';
        fpath = fullfile(sourcedata_dir, subses, session.id, fname);
        fid = fopen(fpath, 'w');
        fprintf(fid, 'onset\tduration\ttrial_type\n');
        for bb = 1:length(block_onsets)
            fprintf(fid, '%.2f\t%d\t%s\n', block_onsets(bb), duration, cond_names{bb});
        end
        fclose(fid);
        session.event{rr} = fpath;
    end
end   

