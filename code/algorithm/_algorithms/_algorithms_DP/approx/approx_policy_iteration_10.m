function [Pf, Vf, Xs, Ys, Ks, As, f_time, b_time, v_time, a_time] = approx_policy_iteration_10(s_1, actions, reward, value_basii, trans_post, trans_pre, gamma, N, M, T, W)

    a_start = tic;

    g_row = [gamma.^(0:T-1), zeros(1,W-1)];
    g_mat = zeros(W,size(g_row,2));

    for w = 1:W
        g_mat(w, :) = circshift(g_row,w-1);
    end
    
    f_time = 0;
    b_time = 0;
    v_time = 0;

    If = cell(1, N+1);
    Vf = cell(1, N+1);
    Pf = cell(1, N+1);
    Xs = cell(1, N*M);
    Ys = cell(1, N*M);
    Ks = cell(1, N*M);
    As = cell(1, N*M);

    X = [];
    Y = [];
    K = [];
    A = [];
    S = [];

    %one for every value_basii
    %updated for entire life of program
    epsilon = [];
    beta    = [];
    nu      = [];
    sig_sq  = [];
    alpha   = [];
    eta     = [];
    lambda  = [];

    Vf{1} = @(xi) 3*ones(size(xi,2),1);
    If{1} = @(xi) Vf{1}(xi);

    for n = 1:N 

        X_s_m = cell(1, M);
        X_b_m = cell(1, M);
        X_r_m = cell(1, M);

        if n == 1
            init_states = arrayfun(@(m) s_1(), 1:M, 'UniformOutput', false);
        else
            init_states = all_states(randi(numel(init_states),1,M));
        end
        
        t_start = tic;
        parfor m = 1:M 

            s_a = init_states{m};
            s_t = trans_pre(s_a, []);
            
            X_b_m{m} = [];
            X_r_m{m} = [];

            X_s_m{m} = {s_t}; 
            X_b_m{m}(:,1) = value_basii(s_a);
            X_r_m{m}(:,1) = reward(s_t);
            
            for t = 1:((T-1)+(W-1))

                action_matrix = actions(s_t);

                post_states = trans_post(s_t, action_matrix);
                post_basii  = value_basii(post_states);
                post_values = If{n}(post_basii);
                post_std    = 1 * ones(size(post_states,2),1);

                if ~isempty(X)
                    [~, ib, ix] = intersect(post_basii', X', 'rows');
                    post_std(ib) = sqrt(S(ix));
                end

                post_values = post_values + 2*post_std;

                a_m = max(post_values);
                a_i = find(post_values == a_m);
                a_i = a_i(randi(length(a_i)));

                s_a = post_states(:,a_i);
                s_t = trans_pre(s_a, []);

                X_s_m{m} = horzcat(X_s_m{m}, s_t);
                X_b_m{m}(:,t+1) = post_basii(:,a_i);
                X_r_m{m}(:,t+1) = reward(s_t);
 
            end
        end
        f_time = f_time + toc(t_start);

        if n == 1
            all_states = horzcat(X_s_m{:});
        else
            all_states = horzcat(all_states, X_s_m{:});
        end
        
        t_start = tic;
        for m = 1:M
            X_base = X_b_m{m};
            X_rewd = X_r_m{m};

                for w = 1:W
                    i = coalesce_if_true(~isempty(X), @() all(X == X_base(:,w)));
                    y = g_mat(w,:) * X_rewd';
                    k = coalesce_if_empty(K(i),0);

                    if any(i)
                        %these step size calculations taken from Pg. 446-447 in
                        %Approximate Dynamic Programming by Powell in 2011
                        e = Y(i) - y;
                        
                        if(e == 0 && k > 2)
                            %for some reason I keep getting 0 error in my
                            %estimate, even after four iterations. This in turn
                            %causes my estimate of my estimators bias (b) 
                            %and the estimate of its variance (v) to become
                            %zero in some cases making my stepsize (a) NaN.
                            %to combat this I'll add a small perturbation
                            %with zero mean. That way the bias will be
                            %small but still existant
                            e = .5*(.5 - rand);
                        end
                        
                        b = (1-eta(i))*beta(i) + eta(i)*e;
                        v = (1-eta(i))*nu(i) + eta(i)*(e^2);
                        s = (v - b^2)/(1+lambda(i));

                        if(k > 2)
                            assert(~( (s/v) > 10000 || any(isnan([e, b, v, s, s/v])) || any(isinf([e, b, v, s, s/v])) ))
                        end
                        
                        epsilon(i) = e;
                        beta(i)    = b;
                        nu(i)      = v;
                        sig_sq(i)  = s;

                        Y(i) = (1-alpha(i))*Y(i) + alpha(i)*y;
                        K(i) = k + 1;
                        A(i) = alpha(i);
                        S(i) = sig_sq(i);

                        l = ((1-alpha(i))^2)*lambda(i) + alpha(i)^2;

                        %the book suggests k <= 2... but it just seems to take longer
                        %for my particlar setup to get an estimate of the bias
                        if (k <= 2)
                            a = 1/(k+1);
                        else
                            a = 1 - (s/v);
                        end

                        if(k == 1)
                            e = 1;
                        else
                            e = eta(i)/(1+eta(i)-.05);
                        end

                        %while it seems incorrect... I think it is ok for
                        %alpha to be less than one... I think... any([a,e] < 0)
                        assert(~( any(1 < [a,e]) || any(isnan([a, e, l])) || any(isinf([a, e, l]))));

                        alpha(i)  = a;
                        eta(i)    = e;
                        lambda(i) = l;

                    else
                        Y = [Y, y];
                        X = [X, X_base(:,w)];
                        K = [K, 1];
                        A = [A, 1];
                        S = [S, 2];

                        %for all intents and purposes this is the 0th 
                        %(aka, initialization) step from the algorithm
                        epsilon = [epsilon;0]; %simply reserving space, this value isn't used
                        beta    = [beta;0];    % we don't use for a few iterations
                        nu      = [nu;0];      % we don't use for a few iterations
                        alpha   = [alpha;1];
                        eta     = [eta;1];
                        lambda  = [lambda;0];  % we don't use for a few iterations  

                    end
                end

                Xs{(n-1)*M + m} = X;
                Ys{(n-1)*M + m} = Y;
                Ks{(n-1)*M + m} = K;
                As{(n-1)*M + m} = A;
        end
        b_time = b_time + toc(t_start);
        
        t_start = tic;
            model = fitrsvm(X',Y','KernelFunction','gaussian', 'Standardize',true);
   
            If{n+1} = @(vb) predict(model, vb');
            Vf{n+1} = @(ss) predict(model, value_basii(ss)');
            Pf{n+1} = policy_function(actions, Vf{n+1}, trans_post);
            
        v_time = v_time + toc(t_start);
    end
    
    a_time = toc(a_start);
end