function params = get_default_params()

% Encoder
params.ppr = 1024;

% Pump control
params.duration_per_pulse_ms = 15; % ms
params.num_pulses = 4;

% Trial timings
params.max_trial_duration = 60; % s
params.quiescent_period_duration = 1; % s
params.post_trial_cursor_on_duration = 1; % s

% Note (2024 Dec 10):
% Shikano argues that we should not be calling drawnow in rapid succession.
% What happens if we call drawnow at a rate faster than the frame rate of
% the iPad screen (60 Hz)? The post_drawnow_delay will prevent successive
% drawnow calls from occuring faster than 60 Hz.
% params.post_drawnow_delay = 0.0168; % 0.017 works , 0.016 OK but risky, 0.0165 realistic, 0.0168 (21Hz) best?

params.post_drawnow_delay = 0.0045;