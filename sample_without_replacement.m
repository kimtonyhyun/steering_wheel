function [x0, x0_list] = sample_without_replacement(x0_list)

ind = randi(length(x0_list));
x0 = x0_list(ind);
x0_list(ind) = [];