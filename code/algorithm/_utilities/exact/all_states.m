function [states, state2index] = all_states(w, h, r)

xs = (1:w)';
ys = (1:h)';

all_xy = vertcat(reshape(repmat(xs',h,1), [1,w*h]), repmat(ys',1,w));

movements = zeros(8, (w*h)^4);
i = 0;


%this represents all potential movements
for xy1 = all_xy
    for xy2 = all_xy
        for xy3 = all_xy
            for xy4 = all_xy
                i = i+1;                
                movements(:,i) = vertcat(xy1,xy2,xy3,xy4);
                %movements(:,i) = reshape(horzcat(xy1,xy2,xy3,xy4) * A' , [8, 1]);
            end
        end
    end
end

%this represents all potential target positions

targets = dec2bin((1:2^((w-2*r)*(h-2*r)))-1)' - '0';

%combining all movements and targets

move_cnt = size(movements,2);
targ_cnt = size(targets,2);

moves_for_each_targ = reshape(repmat(movements,[targ_cnt,1]), [8 move_cnt * targ_cnt]);
targs_for_each_move = repmat(targets, [1 move_cnt]);
whr_for_moves_targs = repmat([w;h;r], [1, targ_cnt * move_cnt]);

%a given movement pattern indexes me by target count
%[m1,m1,m1,m2,m2,m2]
%[t1,t2,t3,t1,t2,t3]

move_index_map = [h*(w*h)^3 (w*h)^3 h*(w*h)^2 (w*h)^2 h*(w*h)^1 (w*h)^1 h*(w*h)^0 (w*h)^0];
targ_index_map = power(2, ((w-2*r)*(h-2*r) - 1):-1:0);

state_move_index = @(s) move_index_map * (s(1:8,:)    - ones(8,1)) + 1;
state_targ_index = @(s) targ_index_map * (s(12:end,:)            ) + 1;

states    = vertcat(moves_for_each_targ, whr_for_moves_targs, targs_for_each_move);
state2index = @(s) (state_move_index(s) - 1) * targ_cnt + state_targ_index(s);

assert(all(state2index(states) == 1:size(states,2)), 'There is a problem with the state to index function. This will brake the one step matrix.')

end