function [x0_list, new_num_L, new_num_R] = generate_x0_list_antibias(past_x0_list, past_results)
% Generate an uneven number of left vs. right start trials, taking into
% account the directional bias of the animal.
%
% See example usage and outputs below.

L_trials = past_x0_list < 0;
R_trials = past_x0_list > 0;

num_trials_in_batch = length(past_x0_list);

% Count the number of non-Hits
check_for_not_H = @(x) ~strcmp(x(1), 'H');
num_L_fails = sum(cellfun(check_for_not_H, past_results(L_trials), 'UniformOutput', true));
num_R_fails = sum(cellfun(check_for_not_H, past_results(R_trials), 'UniformOutput', true));

% Shikano algorithm for antibias
num_L_fails = max([0.5 num_L_fails]);
num_R_fails = max([0.5 num_R_fails]);
new_num_L = round(num_trials_in_batch * num_L_fails / (num_L_fails + num_R_fails));
new_num_R = num_trials_in_batch - new_num_L;

x0_list = ones(1, num_trials_in_batch);
x0_list(1:new_num_L) = -1;

end

% Example outputs:
%
% x0_list = generate_x0_list_antibias([-1 -1 -1 -1 1 1 1 1], {'Hit', 'Hit', 'Miss', 'Miss', 'Hit', 'Hit', 'Miss', 'Miss'})
% x0_list =
%     -1    -1    -1    -1     1     1     1     1
%
% x0_list = generate_x0_list_antibias([-1 -1 -1 -1 1 1 1 1], {'Hit', 'Hit', 'Hit', 'Hit', 'Miss', 'Miss', 'Miss', 'Miss'})
% x0_list =
%     -1     1     1     1     1     1     1     1
%
% x0_list = generate_x0_list_antibias([-1 -1 -1 -1 1 1 1 1], {'Miss', 'Miss', 'Miss', 'Miss', 'Hit', 'Hit', 'Hit', 'Hit'})
% x0_list =
%     -1    -1    -1    -1    -1    -1    -1     1
%
% x0_list = generate_x0_list_antibias([-1 -1 -1 -1 1 1 1 1], {'Miss', 'Hit', 'Hit', 'Hit', 'Hit', 'Hit', 'Hit', 'Hit'}) 
% x0_list =
%     -1    -1    -1    -1    -1     1     1     1