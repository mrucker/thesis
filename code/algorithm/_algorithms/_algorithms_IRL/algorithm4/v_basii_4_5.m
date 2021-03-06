function [v_i, v_p, v_b] = v_basii_4_5()
    
    LEVELS_N = [3 3 3 3 8 3 6];
           
    v_I = I(LEVELS_N);

    v_p = v_perms();
    v_i = @(states) v_I'*(statesfun(@v_levels, states)-1) + 1;
    v_b = @(states) statesfun(@v_feats, states);    
end

function vl = v_levels(states)

    l_x = cursor_x_levels(states);
    l_y = cursor_y_levels(states);
    l_v = cursor_v_levels(states);
    l_a = cursor_a_levels(states);
    l_d = cursor_d_levels(states);
    [l_t,l_n] = target_t_n_levels(states);

    vl = vertcat(l_x, l_y, l_v, l_a, l_d, l_t, l_n);
end

function [vf] = v_feats(states)

    LEVELS_N = [3 3 3 3 8 3 6];    

    val_to_d = @(val,den      ) val/den;
    val_to_e = @(val,  n      ) double(1:n == val')';
    val_to_r = @(val, den, trn) [cos(trn*pi/den + val*pi/den); sin(trn*pi/den + val*pi/den)];

    levels = v_levels(states);

    x_n = LEVELS_N(1);
    y_n = LEVELS_N(2);
    v_n = LEVELS_N(3);
    a_n = LEVELS_N(4);
    d_n = LEVELS_N(5);
    t_n = LEVELS_N(6);
    n_n = LEVELS_N(7);

    x = levels(1,:);
    y = levels(2,:);
    v = levels(3,:);
    a = levels(4,:);
    d = levels(5,:);
    t = levels(6,:);
    n = levels(7,:);

    vf = [
        val_to_d(x-1,x_n-1     );
        val_to_d(y-1,y_n-1     );
        val_to_d(v-1,v_n-1     );
        val_to_d(a-1,a_n-1     );
        val_to_r(d-1,d_n/2, 4.5);
        val_to_e(t-0,t_n-0     );
        val_to_d(n-1,n_n-1     );
    ];

end

function rp = v_perms()

    LEVELS_N = [3 3 3 3 8 3 6];

    val_to_d = @(val,den      ) val/den;
    val_to_e = @(val,  n      ) double(1:n == val')';
    val_to_r = @(val, den, trn) [cos(trn*pi/den + val*pi/den); sin(trn*pi/den + val*pi/den)];

    x_n = LEVELS_N(1);
    y_n = LEVELS_N(2);
    v_n = LEVELS_N(3);
    a_n = LEVELS_N(4);
    d_n = LEVELS_N(5);
    t_n = LEVELS_N(6);
    n_n = LEVELS_N(7);
    
    x_f = cell2mat(arrayfun(@(L) val_to_d(L-1, x_n-1     ), 1:x_n, 'UniformOutput', false));
    y_f = cell2mat(arrayfun(@(L) val_to_d(L-1, y_n-1     ), 1:y_n, 'UniformOutput', false));
    v_f = cell2mat(arrayfun(@(L) val_to_d(L-1, v_n-1     ), 1:v_n, 'UniformOutput', false));
    a_f = cell2mat(arrayfun(@(L) val_to_d(L-1, a_n-1     ), 1:a_n, 'UniformOutput', false));
    d_f = cell2mat(arrayfun(@(L) val_to_r(L-1, d_n/2, 4.5), 1:d_n, 'UniformOutput', false));
    t_f = cell2mat(arrayfun(@(L) val_to_e(L-0, t_n-0     ), 1:t_n, 'UniformOutput', false));
    n_f = cell2mat(arrayfun(@(L) val_to_d(L-1, n_n-1     ), 1:n_n, 'UniformOutput', false));

    x_i = 1:size(x_f,2);
    y_i = 1:size(y_f,2);
    v_i = 1:size(v_f,2);
    a_i = 1:size(a_f,2);
    d_i = 1:size(d_f,2);
    t_i = 1:size(t_f,2);
    n_i = 1:size(n_f,2);
    
    [n_c, t_c, d_c, a_c, v_c, y_c, x_c] = ndgrid(n_i, t_i, d_i, a_i, v_i, y_i, x_i);

    rp = [
        x_f(:,x_c(:));
        y_f(:,y_c(:));
        v_f(:,v_c(:));
        a_f(:,a_c(:));
        d_f(:,d_c(:));
        t_f(:,t_c(:));
        n_f(:,n_c(:));
    ];
end

function cx = cursor_x_levels(states)
    LEVELS_N = [3 3 3 3 8 3 6];

    min_level = 1;
    max_level = LEVELS_N(1);
    bin_size  = states(9,1)/max_level;

    cx = bin_levels(states(1,:), bin_size, min_level, max_level);
end

function cy = cursor_y_levels(states)
    LEVELS_N = [3 3 3 3 8 3 6];

    min_level = 1;
    max_level = LEVELS_N(2);
    bin_size  = states(10,1)/max_level;

    cy = bin_levels(states(2,:), bin_size, min_level, max_level);
end

function cv = cursor_v_levels(states)
    LEVELS_N = [3 3 3 3 8 3 6];

    cv = bin_levels(vecnorm(states(3:4,:)), 25, 1, LEVELS_N(3));
end

function ca = cursor_a_levels(states)
    LEVELS_N = [3 3 3 3 8 3 6];

    ca = bin_levels(vecnorm(states(5:6,:)), 25, 1, LEVELS_N(4));
end

function cd = cursor_d_levels(states)
    LEVELS_N = [3 3 3 3 8 3 6];

    min_level = 1;
    max_level = LEVELS_N(5);
    bin_size  = max_level*pi/2; 

    vals = atan2(-states(4,:), states(3,:)) + pi;
    
    cd = bin_levels(vals, bin_size, min_level, max_level);
end

function [tt, tn] = target_t_n_levels(states)
    
    LEVELS_N = [3 3 3 3 8 3 6];
    
    r2 = states(11, 1).^2;
    
    [cd, pd] = distance_features(states);

    ct = cd <= r2;
    pt = pd <= r2;
    nt = states(14:3:end, 1) <= 30; %in theory this could be 33 (aka, one observation 30 times a second)

    enter_target = any(ct&(~pt|nt),1);
    leave_target = any(~ct&pt     ,1);

    approach_n = sum(cd < pd,1);

    tt = [1 2 3] * [ (~enter_target & ~leave_target); (enter_target); (~enter_target & leave_target ); ];
    tn = bin_levels(approach_n, 1, 1, LEVELS_N(7));
end

%% Probably don't need to change %%
function v = I(n)
    n = [n, 1]; %add one for easier computing
    v = arrayfun(@(i) prod(n(i:end)), 2:numel(n))';
end

function sf = statesfun(func, states)
    if iscell(states)
        sf = cell2mat(cellfun(func, states, 'UniformOutput',false));
    else
        sf = func(states);
    end
end

function bl = bin_levels(vals, bin_size, min_level, max_level)

    %fastest
    bl = ceil(vals/bin_size);
    bl = max (bl, min_level);
    bl = min (bl, max_level);
    
    %%second fastest
    %bl = min(ceil((vals+.01)/bin_s), bin_n);
    %%second fastest
    
    %%third fastest
    %[~, bl] = max(vals <= [1:bin_n-1, inf]' * bin_s);
    %%third fastest

    %%fourth fastest (close 3rd)
    %r_bins = [   1:bin_n-1, inf]' * bin_s;
    %l_bins = [0, 1:bin_n-1     ]' * bin_s;
    
    %bin_ident = l_bins <= vals & vals < r_bins;
    %bl = (1:bin_n) * bin_ident;
    %%fourth fastest (close 3rd)
    
    %%fifth fastest
    %bins = (1:bin_n-1) * bin_s;
    %bl = discretize(vals,[0,bins,inf]);
    %%fifth fastest
end

function [cd, pd] = distance_features(states)
    cp = states(1:2,:);
    pp = states(1:2,:) - states(3:4,:);   
    tp = [states(12:3:end, 1)';states(13:3:end, 1)'];

    dtp = dot(tp,tp,1);
    dcp = dot(cp,cp,1);
    dpp = dot(pp,pp,1);

    cd = dcp+dtp'-2*(tp'*cp);
    pd = dpp+dtp'-2*(tp'*pp);
end

%% Probably don't need to change %%