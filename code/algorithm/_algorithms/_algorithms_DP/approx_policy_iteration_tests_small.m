run('../../paths.m');
fprintf('\n');
close all

samples = 1;

N = 30;
M = 50;
T = 10;
W = 3;

deriv  = 3;
width  = 2;
height = 2;
radius = 0;

gamma = .9;

OPS     = 30;
ticks   = floor(1000/OPS);
arrive  = 200;
survive = 1000;

algos = {
   %@approx_policy_iteration_2, 'algorithm_2'; %(lin ols   regression)
   %@approx_policy_iteration_5, 'algorithm_5'; %(gau ridge regression)
    @approx_policy_iteration_6, 'algorithm_6'; %(gau svm   regression)
    @approx_policy_iteration_7, 'algorithm_7'; %(gau svm   regression with BAKF)
};

[states, movements, targets, actions, state2index, target2index, pre_pmf, post_pmf, targ_pmf] = small_world(deriv, width, height ,radius, ticks, survive, arrive);

targ_cdf = diag(1./sum(targ_pmf,2)) * targ_pmf * triu(ones(size(targ_pmf,2)));

s_1 = @( ) states(:,randperm(size(states,2),1));
s_a = @(s) actions;
v_b = @(s) value_basii_5(s, actions);

transition_pre  = @(s,a) small_trans_pre (s, a, targets, target2index, targ_cdf);
transition_post = @(s,a) small_trans_post(s, a);

f_time = [];
b_time = [];
m_time = [];
a_time = [];

rewards     = cell(1, samples);
exact_Vs    = cell(1, samples);
exact_Ps    = cell(1, samples);
exact_Es    = cell(1, samples);
eval_states = cell(1, samples);

for i = 1:samples

    reward = random_rewards(states, actions);
    reward = reward./max(abs(reward));

    values = exact_value_iteration(pre_pmf, reward, gamma, 0, min(T,30));

    rewards{i}  = @(s) reward(state2index(s));
    exact_Ps{i} = exact_policy_realization(states, actions, values, pre_pmf);

    %exact_Vs{i} is definitely right. I have double and triple checked it
    %(aka, V_a(s_t) = E[V(s_{t+1}) | a, s_t] = \sum_{s' \in S} P(s'|s,a) * V(s_t+1) == post_pmf * V)
    exact_Vs{i} = post_pmf * values; %(aka, post-decision-state value)

    %I have some big doubts about the accuracy of the exact_E values
    %These are only used for evaluation though so semi-close is acceptable
    exact_Es{i} = exact_steady_state(pre_pmf, exact_Ps{i}, W);

    %aka, 10 random states... kind of ugly, but I'm feeling lazy.
    eval_states{i} = [s_1(),s_1(),s_1(),s_1(),s_1(),s_1(),s_1(),s_1(),s_1(),s_1()];

    fprintf('sample %i - R in [%.2f, %.2f], V in [%.2f, %.2f] \n', [i, max(reward), min(reward), max(exact_Vs{i}), min(exact_Vs{i})]);
end

V_mse = zeros(1,samples);
P_mse = zeros(1,samples);
P_val = zeros(1,samples);

for i = 1:samples
    [V_mse(i), P_mse(i), P_val(i)] = result_statistics(states, actions, rewards{i}, gamma, T, eval_states{i}, @(s) exact_Vs{i}(state2index(s)), exact_Vs{i}, exact_Ps{i}, transition_post, transition_pre, state2index);    
end

p_results('exact_value', 0, 0, 0, 0, V_mse, P_mse, P_val);

for a = 1:size(algos,1)

    f_time = zeros(1,samples);
    b_time = zeros(1,samples);
    m_time = zeros(1,samples);
    a_time = zeros(1,samples);

    V_mse = zeros(1,samples);
    P_mse = zeros(1,samples);
    P_val = zeros(1,samples);
    
    for i = 1:samples
        
        [Vf, Xs, Ys, Ks, f_time(i), b_time(i), m_time(i), a_time(i)] = algos{a, 1}(s_1, @(s) actions, rewards{i}, v_basii, transition_post, transition_pre, gamma, N, M, T, W);        
        
        [V_mse(i), P_mse(i), P_val(i)] = result_statistics(states, actions, rewards{i}, gamma, T, eval_states{i}, Vf{N+1}, exact_Vs{i}, exact_Ps{i}, transition_post, transition_pre, state2index);

        if samples < 3
            d_results(algos{a, 2}, Xs, Ys, Ks, v_basii(states), exact_Es{i}, exact_Vs{i});
        end
    end

    p_results(algos{a, 2}, f_time, b_time, m_time, a_time, V_mse, P_mse, P_val);

end

function vb = value_basii_1(ss, actions, radius, deriv, small_reward_basii)
    vb = small_reward_basii(ss, actions, radius, deriv);
end

function vb = value_basii_2(ss, actions, radius, deriv, small_reward_basii)
    rb = small_reward_basii(ss, actions, radius, deriv);
    vb = rb([1:4, end], :);
end

function vb = value_basii_3(states, actions, radius)
    
    state_points  = states(1:2,:);
    world_points  = actions;
    state_targets = states((end-size(world_points,2)+1):end,:);

    p1 = state_points;
    p2 = world_points;

    state_point_distance_matrix = sqrt(dot(p1,p1,1) + dot(p2,p2,1)' - 2*(p2' * p1));

    points_within_radius = state_point_distance_matrix <= radius;
    points_with_targets  = logical(state_targets);

    each_states_touch_count  = sum(points_within_radius&points_with_targets);
    each_states_target_count = sum(state_targets);
    
    vb = [each_states_target_count; each_states_touch_count];
end

function vb = value_basii_4(states, actions, radius)

    state_points  = states(1:2,:);
    world_points  = actions;
    state_targets = states((end-size(world_points,2)+1):end,:);

    p1 = state_points;
    p2 = world_points;

    state_point_distance_matrix = sqrt(dot(p1,p1,1) + dot(p2,p2,1)' - 2*(p2' * p1));

    points_within_radius = state_point_distance_matrix <= radius;
    points_with_targets  = logical(state_targets);

    each_states_touch_count  = sum(points_within_radius&points_with_targets);
    each_states_target_count = sum(state_targets);

    curr_points = repmat(states(1:2,:), [size(world_points,2) 1]);
    prev_points = repmat(states(3:4,:), [size(world_points,2) 1]);

    world_points = reshape(world_points, [], 1);
    
    curr_xy_dist = abs(world_points - curr_points);
    prev_xy_dist = abs(world_points - prev_points);

    points_with_decrease_x = curr_xy_dist(1:2:end,:) < prev_xy_dist(1:2:end,:);
    points_with_decrease_y = curr_xy_dist(2:2:end,:) < prev_xy_dist(2:2:end,:);

    %how many targets did my x distance decrease
    target_x_decrease_count = sum(points_with_decrease_x&points_with_targets);
    
    %how many targets did my y distance decrease
    target_y_decrease_count = sum(points_with_decrease_y&points_with_targets);
    
    %how many targets dyd my x,y distance decrease
    target_xy_decrease_count = sum(points_with_decrease_x&points_with_decrease_y&points_with_targets);

    y_intercept = ones(1, size(states,2));
    
    vb = [y_intercept; states(1:2,:); target_x_decrease_count; target_y_decrease_count; target_xy_decrease_count; each_states_target_count; each_states_touch_count];
end

function vb = value_basii_5(states, actions)

    A = [
        1  0 -1  0  0  0;
        0  1  0 -1  0  0;
        1  0 -2  0  1  0;
        0  1  0 -2  0  1;
    ];

    state_points  = states(1:2,:);
    world_points  = actions;
    state_targets = states((end-size(world_points,2)+1):end,:);
    state_radius  = states(end-size(world_points,2),1);
    
    p1 = state_points;
    p2 = world_points;

    state_point_distance_matrix = sqrt(dot(p1,p1,1) + dot(p2,p2,1)' - 2*(p2' * p1));

    not_touched_last_step = ~all(states(1:2,:) == states(3:4,:));
    points_within_radius  = state_point_distance_matrix <= state_radius;
    points_with_targets   = logical(state_targets);

    curr_points = repmat(states(1:2,:), [size(world_points,2) 1]);
    prev_points = repmat(states(3:4,:), [size(world_points,2) 1]);

    center_point     = (max(world_points, [], 2) + min(world_points, [], 2))/2;

    world_points = reshape(world_points, [], 1);

    curr_xy_dist = abs(world_points - curr_points);
    prev_xy_dist = abs(world_points - prev_points);

    points_with_decrease_x = curr_xy_dist(1:2:end,:) < prev_xy_dist(1:2:end,:);
    points_with_decrease_y = curr_xy_dist(2:2:end,:) < prev_xy_dist(2:2:end,:);

    each_states_target_x_decrease_count  = sum(points_with_decrease_x&points_with_targets);
    each_states_target_y_decrease_count  = sum(points_with_decrease_y&points_with_targets);
    each_states_target_xy_decrease_count = sum(points_with_decrease_x&points_with_decrease_y&points_with_targets&not_touched_last_step);
    each_states_touch_count              = sum(points_within_radius&points_with_targets);
    each_states_target_count             = sum(state_targets);
    each_states_y_intercept              = ones(1, size(states,2));
    each_states_targets                  = state_targets;
    each_states_derivs                   = A * states(1:6,:);
    each_states                          = states;
    each_states_center_vector            = center_point - state_points;
    each_states_movement_towards_targets = [each_states_target_x_decrease_count;each_states_target_y_decrease_count;each_states_target_xy_decrease_count];

    vb = [
        each_states_y_intercept; 
        each_states_derivs; 
        each_states_touch_count; 
        each_states_target_count; 
        each_states_movement_towards_targets;
        each_states_center_vector
    ];
end

function rr = random_rewards(states, actions)

    A = [
        1  0 -1  0  0  0;
        0  1  0 -1  0  0;
        1  0 -2  0  1  0;
        0  1  0 -2  0  1;
    ];

    derivs = A * states(1:6,:);
    
    state_points  = states(1:2,:);
    world_points  = actions;
    state_targets = states((end-size(world_points,2)+1):end,:);
    state_radius  = states(end-size(world_points,2),1);
    
    p1 = state_points;
    p2 = world_points;

    state_point_distance_matrix = sqrt(dot(p1,p1,1) + dot(p2,p2,1)' - 2*(p2' * p1));

    not_touched_last_step = ~all(states(1:2,:) == states(3:4,:));
    points_within_radius  = state_point_distance_matrix <= state_radius;
    points_with_targets   = logical(state_targets);

    each_states_touch_count  = sum(points_within_radius&points_with_targets&not_touched_last_step);    

    deriv_1 = [  1  1 -1 -1] * 10 * (.5-rand);
    deriv_2 = [ -1 -1 -1 -1] * 10 * (.5-rand);
    touched = 1 * 10 * (.5-rand);

    rr = [abs(derivs);abs(derivs).^2;each_states_touch_count]' * [deriv_1,deriv_2,touched]' + 3*rand(size(states,2),1);
end

function ib = intersect_ib(A,B)
    [~, ~, ib] = intersect(A, B, 'rows');
end

function p_results(test_algo_name, f_time, b_time, v_time, a_time, V_mse, P_mse, P_val)
    fprintf('%s -- ', test_algo_name);
    fprintf('f_time = % 7.3f; ', sum(f_time));
    fprintf('b_time = % 7.3f; ', sum(b_time));
    fprintf('v_time = % 7.3f; ', sum(v_time));
    fprintf('a_time = % 7.3f; ', sum(a_time));
    fprintf('MSE = % 6.3f; '     , mean(V_mse));
    fprintf('MSP = %.3f; '     , mean(P_mse));
    fprintf('VAL = %.3f; '     , mean(P_val));
    fprintf('\n');
end

function d_results(test_algo_name, Xs, Ys, Ks, basii, tru_E, tru_V)
    
    [basii, ~, gs] = unique(basii', 'rows');
    
    basii = basii';
    expec = grpstats(tru_E,gs, @(ss) sum(ss));
    value = grpstats(tru_V.*tru_E,gs, @(ss) sum(ss))./expec;

    visits1 = 0:10;
    visits2 = 1:10;
    
    value_x = @(x) value(intersect_ib(x', basii'));
    error_x = @(x,y) abs(value_x(x) - y');
    
    step_visit_count = cell2mat(arrayfun(@(step) [repmat(step, 1, numel(visits1)); visits1; [size(basii,2) - size(Ks{step},2),histc(Ks{step}, visits2)]], 1:5:size(Ks,2), 'UniformOutput', false));
    step_visit_error = cell2mat(arrayfun(@(step) [repmat(step, 1, numel(visits1)); visits1; mean(error_x(Xs{step},Ys{step}) .* (visits1 == Ks{step}')) ], 1:5:size(Ks,2), 'UniformOutput', false));
    
    figure('NumberTitle', 'off', 'Name', test_algo_name);

    subplot(2,1,1);    
    scatter3(step_visit_count(1,:),step_visit_count(2,:),step_visit_count(3,:), '.');
    title('visitation bins')
    
    subplot(2,1,2);
    scatter3(step_visit_error(1,:),step_visit_error(2,:),step_visit_error(3,:), '.');
    title('convergence rate')
end

function [V_mse, P_mse, P_val] = result_statistics(states, actions, reward, gamma, T, eval_states, est_V, tru_Vs, tru_Ps, transition_post, transition_pre, state2index)
    page_size = 10000;

    est_Vs = zeros(size(states,2),1);
    est_Ps = zeros(size(states,2),1);
    
    for page_index = 1:ceil(size(states,2)/page_size)
        page_start    = 1+(page_index-1)*page_size;
        page_stop     = min(page_index*page_size, size(states,2));
        page_indexes  = page_start:page_stop;
        page_states   = states(:,page_indexes);

        est_Vs(page_indexes) = est_V(page_states);
        est_Ps(page_indexes) = approx_policy_realization(page_states, actions, est_V, transition_post);
    end

    V_mse = mean((est_Vs -  tru_Vs).^2);
    P_mse = mean((est_Ps == tru_Ps).^2);
    P_val = evaluate_policy_at_states(est_Ps, eval_states, actions, reward, gamma, T, 100, state2index, transition_pre);
end

function V = evaluate_policy_at_states(policy, states, actions, reward, gamma, T, samples, state2index, transition_pre)
    v = 0;
    for state = states
        v = v + evaluate_policy_at_state(policy, state, actions, reward, gamma, T, samples, state2index, transition_pre);
    end
    
    V = v/size(states,2);
end

function V = evaluate_policy_at_state(policy, state, actions, reward, gamma, T, samples, state2index, transition_pre)

    V = 0;    
    
    for n = 1:samples

        s = state;
        v = 0;
        
        for t = 1:T
            v = v + gamma^(t-1) * reward(s);
            a = actions(:, policy(state2index(s)));
            s = transition_pre(s,a);
        end
        
        V = V + v;
    end
    
    V = V/samples;
end