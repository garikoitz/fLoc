function orders = make_orders_kids(num_active_conds, blocks_per_active_cond, blocks_per_rest_cond, num_orders)
% Generates counterbalanced block orders for kids VOTCLOC design.
%
% Inputs:
%   num_active_conds      - number of active conditions (e.g., 2 for RW + SC)
%   blocks_per_active_cond - blocks per active condition (e.g., 15)
%   blocks_per_rest_cond   - number of rest/baseline blocks (e.g., 6)
%   num_orders             - number of orders to generate (= num_runs)
%
% Output:
%   orders - (num_blocks x num_orders) matrix
%            0 = baseline, 1 = cond1 (RW), 2 = cond2 (SC), etc.
%
% Based on original make_orders by KGS Lab.
% Rewritten for kids design with unequal active/rest block counts.

% total number of inner blocks (no padding)
num_blocks = num_active_conds * blocks_per_active_cond + blocks_per_rest_cond;

% total number of condition labels (active + baseline)
num_labels = num_active_conds + 1; % e.g., 3: baseline(1), RW(2), SC(3)

% generate specified number of condition orders
orders = zeros(num_blocks, num_orders);
for oo = 1:num_orders

    % build initial order vector:
    % baseline = label 1, active conds = labels 2, 3, ...
    order = [];
    % baseline blocks
    order = [order; ones(blocks_per_rest_cond, 1)];
    % active condition blocks
    for cc = 1:num_active_conds
        order = [order; repmat(cc + 1, blocks_per_active_cond, 1)];
    end
    order = shuffle(order);

    % set up goal transition matrix
    % ideal: each label-to-label transition is equally likely
    goal = ones(num_labels, num_labels) * ((num_blocks - 1) / (num_labels^2));

    % minimize difference between goal and current transition history
    max_iter = 100000;
    for iter = 1:max_iter
        % get energy for the current design
        history = get_history(order, num_labels);
        old_energy = sum(sum(abs(history - goal)));

        % make a random swap
        a = randi(num_blocks);
        b = randi(num_blocks);
        if order(a) == order(b)
            continue; % skip if swapping same condition
        end
        new = order;
        new(a) = order(b);
        new(b) = order(a);

        % calculate energy of new design
        new_energy = sum(sum(abs(get_history(new, num_labels) - goal)));

        % accept if energy improves (or equals at low energy)
        if new_energy < old_energy
            order = new;
        elseif new_energy == old_energy && rand < 0.1
            order = new; % occasional lateral move to escape local minima
        end

        % good enough — stop
        if old_energy < 2
            break;
        end
    end

    % shift labels: baseline=1 → 0, RW=2 → 1, SC=3 → 2
    orders(:, oo) = order - 1;
end

end


%% ---- Helper function ----
function history = get_history(order, num_labels)
% Compute transition count matrix for a condition sequence.
%
% history(i,j) = number of times label j follows label i

history = zeros(num_labels, num_labels);
for ii = 1:(length(order) - 1)
    history(order(ii), order(ii+1)) = history(order(ii), order(ii+1)) + 1;
end
end