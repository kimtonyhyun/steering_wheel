function params = get_default_params()

% Encoder
params.ppr = 1024;
params.gain = 1; % Gain=1 --> One turn of wheel covers 1/2 of screen width

% Pump control
params.duration_per_pulse_ms = 15; % ms
params.num_pulses = 4;

% Trial timings
params.max_trial_duration = 60; % s
params.quiescent_period_duration = 1; % s
params.post_trial_cursor_on_duration = 1; % s
