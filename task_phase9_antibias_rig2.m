% this code deals with in-demand screen refreshes
% Goal position is recorded every trial (preparing for reversal tasks)
% Cursor indicator on the screen flashes every time when the cursor position is updated
% Cursor position is updated only when there is a change in x.
% Gain is similar to phase 5 (90 deg), 7 start positions per side (dissociate wheel speed encoding and cursor position encoding)

sca; % Close Psychtoolbox screen
close all;
clear;

% cd('C:\Users\octopus\Documents\steering_wheel_task');

a = arduino('COM3');

%%

clearvars -except a;

params = get_default_params;
params.duration_per_pulse_ms = 30;
params.num_pulses = 2;

num_trials = 3;
'Phase 9'

params.x0_list = [-1 -1 1 1 -1 -1 1 1]; 
params.x0_list_label = {'Left','Left','Right','Right', 'Left','Left','Right','Right'}; %s minimum,
params.x0_d_list = [0.15 0.17 0.23 0.26 0.58]; %s minimum,
params.x0_d_list =  [0.40 0.60 0.80 1 1.2 1.4 1.6]*0.58; % 0.2320    0.3480    0.4640    0.5800    0.6960    0.8120    0.9280  %%[0.25 0.5 0.75 1 1.25 1.5 1.75]*0.58; % 0.1450    0.2900    0.4350    0.5800    0.7250    0.8700    1.0150-almost edge
params.xGoal = 0;
params.xFail = 1.16;

% Gain of 1 means that one full turn of the wheel is required to cover HALF
% of the screen width.
params.gain = 2.32;%:90deg(0.58/0.25) 1.74%:120deg(0.58/0.33); 1.1666;%:180deg %xtimes gain from screen edge to center(gain=1;0.58 turn to center from x0=0.58). gain=0.58/x 

sound_hit = audioread('sound/10kHz_500ms_fadein.mp3');
sound_miss = audioread('sound/White_500ms.mp3');
Fs = 44100;

% Preallocate results
results = initialize_results_v2(num_trials);

%%

flush(a); % Serial line may have garbage from previous interactions
clear screen;

screen = ScreenPTB();

% task start
a.start_behavior_clock;
pause(2);

trial_number = 0;

while trial_number < num_trials
    trial_number = trial_number + 1;
    fprintf('%s: Trial %d\n', datestr(now), trial_number);
    
    x0 = randi(2) - 1.5;
    xGoal = params.xGoal;
    xFail = params.xFail * sign(x0);
    
    if (x0 > 0)
        fprintf('  - RIGHT start from x0 = %.3f\n', x0);
    else
        fprintf('  - LEFT start from x0 = %.3f\n', x0);
    end

    screen.draw_blank;

    % Quiescent period
    %------------------------------------------------------------
    fprintf('  - Entering quiescent period for a minimum of %.3f s... ',...
        params.quiescent_period_duration);
    a.get_encoder_count_silent; % Resets the counter
    
    tic;
    t = 0;
    t_qp_threshold = params.quiescent_period_duration;
    while (t < t_qp_threshold)
        t = toc;
        count = a.get_encoder_count_silent;
        
        if abs(count) > 6 % Roughly +/-2 deg of wheel, assuming ppr=1024
            t_qp_threshold = t + params.quiescent_period_duration;
        end
    end
    fprintf('Total duration was %.3f s\n', t_qp_threshold);
    
    % For preallocation, assume that sampling rate is slower than 1 ms
    cursor_trajectory = zeros(params.max_trial_duration * 1e3, 2); % Format: [Time(s) CursorPosition]
    ts = zeros(params.max_trial_duration *1e3, 1);
    counts = zeros(params.max_trial_duration * 1e3, 1);

    a.get_encoder_count_silent; % Resets the counter
    
    % Show cursor
    %------------------------------------------------------------
    tic;
    a.set_screen_ttl(1);
    screen.draw_cursor_at(x0);
    
    trial_result = 'Timeout';
    t = 0;     
    ind = 0; % Index of Arduino 'get_encoder_count'
    x_prev = x0;
    trial_done = false;

    while t < params.max_trial_duration  
        ind = ind + 1;
        
        t = toc;
        count = a.get_encoder_count();
        
        if count ~= 0 % Encoder reports movement
            x = x_prev + params.gain * (count / params.ppr);
            
            if x*x_prev<=0; x=0; end
            if abs(x)>=0.58*2; x=0.58*2*x/abs(x); end

            screen.draw_cursor_at(x);  % update the cursor position
                        
            if ((x0 < xGoal) && (x >= xGoal)) || ((x0 > xGoal) && (x <= xGoal))
                % Cursor crossed the origin ==> Success
                sound(sound_hit, Fs);
                a.dispense(params.duration_per_pulse_ms, params.num_pulses);
                trial_result = 'Hit';
                trial_done = true;
            elseif abs(x) >= abs(xFail)
                % Cursor is out of screen ==> Failure
                sound(sound_miss, Fs);
                trial_result = 'Miss';
                trial_done = true;
            end
            
            x_prev = x;
        end % Encoder reports movement

        % Log the 'get_encoder_count' interaction
        cursor_trajectory(ind,:) = [t x_prev];
        ts(ind) = t;
        counts(ind) = count;

        if trial_done
            break;
        end
    end

    fprintf('  - Result: %s!\n', trial_result);
    pause(params.post_trial_cursor_on_duration);
    screen.draw_blank;
    a.set_screen_ttl(0);
    
    % Sound for timeout
    if trial_result(1) == 'T'
        sound(sound_miss, Fs);
    end

    % Trim trial data
    cursor_trajectory = cursor_trajectory(1:ind,:);
    ts = ts(1:ind);
    counts = counts(1:ind);   
    
    % Store results. This should match the preallocated format defined in
    % 'initialize_results_v2'
    %------------------------------------------------------------
    results(trial_number).x0 = x0;
    results(trial_number).xGoal = xGoal;
    results(trial_number).xFail = xFail;
    results(trial_number).quiescent_period_duration = t_qp_threshold;
    results(trial_number).stimulus_duration = cursor_trajectory(end,1);
    results(trial_number).cursor_trajectory = cursor_trajectory;
    results(trial_number).result = trial_result;
    results(trial_number).ts = ts;
    results(trial_number).counts = counts;
    
    % ITI (Store results & ITI flipped on 230816)
    %------------------------------------------------------------
    iti = generate_iti;
    results(trial_number).iti = iti;
    fprintf('  - Waiting an ITI of %.3f s\n', iti);
    pause(iti);    
end

%%
a.stop_behavior_clock;
a.set_screen_ttl(0);
clear screen;

% Save results to file
timestamp = datestr(now, 'yymmdd-HHMMSS');
results_filename = sprintf('Results_phase9_AB_flash_%s.mat', timestamp);
% save(results_filename, 'results', 'params', 'num_trials');

