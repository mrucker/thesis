run '../../paths.m';

test_algos = {
%    @approx_policy_iteration_1;
    @approx_policy_iteration_2;
%    @approx_policy_iteration_3;
    @approx_policy_iteration_4;
};

%plot_i = 2;

samples = 10;

g = .9;
N = 10;
M = 70;
T = 3;

deriv  = 3;
width  = 2;
height = 2;
radius = 0;

OPS     = 30;
ticks   = floor(1000/OPS);
arrive  = 200;
survive = 1000;

[states, movements, targets, actions, state2index, target2index, trans_pre_pmf, trans_post_pmf, trans_targ_pmf] = small_world(deriv, width, height ,radius, ticks, survive, arrive);

trans_targ_cdf = diag(1./sum(trans_targ_pmf,2)) * trans_targ_pmf * triu(ones(size(trans_targ_pmf,2)));

%this seems to be slightly faster but for now I'm not going to do it
%perhaps I can put this logic into small_world?
%save('transition_one', 'transition_one', '-v7.3');
%load('transition_one');

s_1 = @() states(:,randperm(size(states,2),1));
%s_1 = @() states(:,1);

transition_pre  = @(s,a) small_trans_pre (s, a, targets, target2index, trans_targ_cdf);
transition_post = @(s,a) small_trans_post(s, a);

r_basii = small_reward_basii(states, actions, radius, deriv);
v_basii = @(v_states) value_basii_4(v_states, actions, radius);

approx_post_v = {};

a_time = [];
f_time = [];
b_time = [];
v_time = [];

mse_V = [];
mse_P = [];

for i = 1:samples
    r_theta = r_theta_generate(r_basii);
    reward  = @(s) r_basii(:,state2index(s))' * r_theta';

    exact_pre_V  = exact_value_iteration(trans_pre_pmf, r_basii'*r_theta', g, .01, T);
    exact_post_V = trans_post_pmf * exact_pre_V;
    exact_P      = exact_policy_realization(states, actions, exact_pre_V, trans_pre_pmf);

    for a = 1:size(test_algos,1)
        tic;
            [approx_post_v{a}, f_time(i,a), b_time(i,a), v_time(i,a)] = test_algos{a}(s_1, @(s) actions, reward, v_basii, transition_post, transition_pre, g, N, M, T);
        a_time(i,a) = toc;

        mse_V(i,a) = mean(power(approx_post_v{a}(states) - exact_post_V, 2));
        mse_P(i,a) = mean(approx_policy_realization(states, actions, approx_post_v{a}, transition_post) == exact_P);
    end
end

%    clf
%    hold on;
%        scatter(1:size(states,2), exact_post_V                 , [], 'r', 'o');
%        scatter(1:size(states,2), approx_post_v{plot_i}(states), [], 'b', '.');
%    hold off

fprintf('%.3f + %.3f + %.3f = %.3f \n', [mean(f_time); mean(b_time); mean(v_time); mean(a_time)]);
fprintf('MSE = %.3f; MSP = %.3f \n', [mean(mse_V); mean(mse_P)])

%sortrows(vertcat(exact_post_V(30:40)',states(:,30:40))',1)'

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

function r_theta = r_theta_generate(RB)
    max_RW = .5;
    num_RW = size(RB,1)-1;
    rng_RW = max_RW *(1-2*rand(1,num_RW));
    
    r_theta = [rng_RW, .5 * (1 + rand)];
end