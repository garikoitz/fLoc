% quantify performance in stimulus task
function session = score_task_usebackup(session, run_num)
    %{
     Use the backup to score the task and generate a tsv and this should
     merge with the xlsx of subses list on google doc
    %}
    sdc = session.sequence.stim_duty_cycle;
    fpw = session.wait_dur / sdc;
    resp_presses = session.responses(run_num).press;   % 0=press, 1=no press
    resp_correct = session.sequence.task_probes(:, run_num);
    probe_idxs   = find(resp_correct);

    % Build the hit_windows
    hit_windows = false(size(resp_correct));
    for ww = 1:ceil(fpw)
        validIdx = probe_idxs + ww - 1;
        validIdx(validIdx > length(resp_presses)) = []; % avoid out-of-bounds
        hit_windows(validIdx) = true;
    end

    % Separate the arrays
    hit_resp_windows = resp_presses(hit_windows);
    fa_resp_windows  = resp_presses(~hit_windows);

    % Reshape hits into [fpw, #probes]
    hitMatrix = reshape(hit_resp_windows, fpw, []);
    
    % If there's at least one '0' in that column => press => "hit"
    hitsPerWindow = sum(any(hitMatrix == 0, 1));  % how many columns had a 0?

    session.hit_cnt(run_num) = hitsPerWindow;
    % For false alarms, count how many are '0' in fa_resp_windows
    session.fa_cnt(run_num)  = sum(fa_resp_windows == 0);
end