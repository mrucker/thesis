function [r_i, r_p, r_b] = r_basii_4_9()

    LEVELS_N = [3, 3, 12, 6, 8, 1];
    
    r_p = r_perms();

    r_I = I(LEVELS_N);

    r_i = @(states) 1 + r_I'*(statesfun(@r_levels, states)-1);
    r_b = @(states) r_feats(statesfun(@r_levels, states));
end

function rl = r_levels(states)

    s_n = size(states,2);
    tou = touch_features(states);

    if all(all(~tou))
        rl = ones(6, s_n);
    else
        [~,ti] = max(tou,[],1);
        tou(:) = 0;
        tou(sub2ind(size(tou), ti, 1:s_n)) = 1;

        lox = sum(target_x_levels(states) .* tou,1) + all(~tou);
        loy = sum(target_y_levels(states) .* tou,1) + all(~tou);
        vel = sum(cursor_v_levels(states) .* tou,1) + all(~tou);
        acc = sum(cursor_a_levels(states) .* tou,1) + all(~tou);
        dir = sum(cursor_d_levels(states) .* tou,1) + all(~tou);
        tou = 1*(sum(tou,1) == 0) + 2*(sum(tou,1) == 1);

        rl = vertcat(lox, loy, vel, acc, dir, tou);
    end
end

function rf = r_feats(levels)

    assert(all(all(levels>0)), 'bad levels');

    val_to_rad = @(val, den, trn) (val~=-1) .* [cos(trn*pi/den + val*pi/den); sin(trn*pi/den + val*pi/den)];

    x = levels(1,:) - (levels(end,:) == 1);
    y = levels(2,:) - (levels(end,:) == 1);
    v = levels(3,:) - (levels(end,:) == 1);
    a = levels(4,:) - (levels(end,:) == 1);
    d = levels(5,:) - (levels(end,:) == 1);

    rf = [
        val_to_rad(x-1, 2 , 0.0);
        val_to_rad(y-1, 2 , 0.0);
        val_to_rad(v-1, 30, 0.0);
        val_to_rad(a-1, 5 , 0.0);
        val_to_rad(d-1, 4 , 4.5);
        4 * (levels(end,:)==1);
    ];

end

function rp = r_perms()

    LEVELS_N = [3, 3, 12, 6, 8, 1];

    x = 1:LEVELS_N(1);
    y = 1:LEVELS_N(2);
    v = 1:LEVELS_N(3);
    a = 1:LEVELS_N(4);
    d = 1:LEVELS_N(5);
    z = 2;
    
    x_i = 1:size(x,2);
    y_i = 1:size(y,2);
    v_i = 1:size(v,2);
    a_i = 1:size(a,2);
    d_i = 1:size(d,2);
    z_i = 1:size(z,2);

    [z_c, d_c, a_c, v_c, y_c, x_c] = ndgrid(z_i, d_i, a_i, v_i, y_i, x_i);
    
    touch_0 = [zeros(10,1); 4];
    touch_1 = r_feats([
        x(:,x_c(:));
        y(:,y_c(:));
        v(:,v_c(:));
        a(:,a_c(:));
        d(:,d_c(:));
        z(:,z_c(:))
    ]);

    rp = horzcat(touch_0, touch_1);

end

function tx = target_x_levels(states)

    LEVELS_N = [3, 3, 12, 6, 8, 1];

    lvl_x = bin_levels(states(12:3:end,1), states(09,1)/LEVELS_N(1), 1, LEVELS_N(1));

    tx = repmat(lvl_x, 1, size(states,2));
end

function ty = target_y_levels(states)

    LEVELS_N = [3, 3, 12, 6, 8, 1];

    lvl_y = bin_levels(states(13:3:end,1), states(10,1)/LEVELS_N(2), 1, LEVELS_N(2));

    ty = repmat(lvl_y, 1, size(states,2));
end

function cv = cursor_v_levels(states)

    LEVELS_N = [3, 3, 12, 6, 8, 1];

    trg_n = (size(states,1) - 11)/3;
    lvl_v = bin_levels(vecnorm(states(3:4,:)), 6, 1, LEVELS_N(3));

    cv = repmat(lvl_v, trg_n, 1);
end

function ca = cursor_a_levels(states)

    LEVELS_N = [3, 3, 12, 6, 8, 1];
    
    trg_n = (size(states,1) - 11)/3;
    lvl_a = bin_levels(vecnorm(states(5:6,:)), 20, 1, LEVELS_N(4));

    ca = repmat(lvl_a, trg_n, 1);
end

function cd = cursor_d_levels(states)

    LEVELS_N = [3, 3, 12, 6, 8, 1];

    min_level = 1;
    max_level = LEVELS_N(5);
    bin_size  = 2*pi/LEVELS_N(5);

    vals = atan2(-states(4,:), states(3,:)) + pi;

    cd = bin_levels(vals, bin_size, min_level, max_level);
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

function tt = touch_features(states)
    r2 = states(11, 1).^2;

    [cd, pd] = distance_features(states);

    ct = cd <= r2;
    pt = pd <= r2;
    nt = states(14:3:end, 1) <= 30; %in theory this could be 33 (aka, one observation 30 times a second)

    tt = ct&(~pt|nt);
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