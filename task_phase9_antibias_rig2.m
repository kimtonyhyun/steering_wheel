sca; % Close Psychtoolbox screen
close all;
clear;

% cd('C:\Users\octopus\Documents\steering_wheel_task');

a = arduino('COM3');

sound_hit = audioread('sound/10kHz_500ms_fadein.mp3');
sound_miss = audioread('sound/White_500ms.mp3');
Fs = 44100;

%%

clearvars -except a sound_hit sound_miss Fs;

% Gain is similar to phase 5 (90 deg)
% 7 start positions per side (dissociate wheel speed encoding and cursor position encoding)
fprintf('* * * PHASE 9 * * *\n');

params = get_default_params;

params.duration_per_pulse_ms = 30;
params.num_pulses = 2;

params.gain = 2.32; % gain=1: One turn of wheel --> 1/2 of screen width

params.x0_list = [-1 -1 1 1 -1 -1 1 1]; 
params.x0_d_list = [0.40 0.60 0.80 1 1.2 1.4 1.6]*0.58;
params.xGoal = 0;
params.xFail = 1.16;

% Preallocate results
num_trials = 300;
results = initialize_results_v2(num_trials);

%%

flush(a); % Serial line may have garbage from previous interactions
clear screen;

screen = ScreenPTB();

% HOLD down the ESCAPE key to halt trials gracefully. We check for the 
% escape key at the end of each trial (i.e. at the time of ITI)
escape_key = KbName('Escape');

% task start
a.start_behavior_clock;
pause(2);

trial_number = 0;

while trial_number < num_trials
    trial_number = trial_number + 1;
    fprintf('%s: Trial %d\n', datestr(now), trial_number);
    
    x0 = randi(2) - 1.5; % Either -0.5 or 0.5
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
            
            if (x*x_prev) <= 0
                % Cursor crossed the origin ==> Success                
                trial_result = 'Hit';
                trial_done = true;

                x = 0; % Clamp
            end
            if abs(x) >= abs(xFail)
                % Cursor is out of screen ==> Failure
                trial_result = 'Miss';
                trial_done = true;

                x = xFail * sign(x); % Clamp
            end

            screen.draw_cursor_at(x);  % update the cursor position                        
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

    % Process trial result
    %------------------------------------------------------------
    switch trial_result(1)
        case 'H'
            sound(sound_hit, Fs);
            a.dispense(params.duration_per_pulse_ms, params.num_pulses);
        case 'M'
            sound(sound_miss, Fs);
        case 'T'
            sound(sound_miss, Fs);
    end
    fprintf('  - Result: %s!\n', trial_result);
    pause(params.post_trial_cursor_on_duration);
    a.set_screen_ttl(0);
    screen.draw_blank; % Do this after setting Screen TTL = 0

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
    iti = generate_iti;
    results(trial_number).iti = iti;
    fprintf('  - Waiting an ITI of %.3f s\n', iti);
    pause(iti);

    % Check if we should stop trials
    [~, ~, keyCode] = KbCheck;
    if keyCode(escape_key)
        fprintf('%s: ESCAPE key detected. Finished after %d trials.\n',...
            datestr(now), trial_number);
        break;
    end
end

%%
a.stop_behavior_clock;
a.set_screen_ttl(0);
clear screen;

% Save results to file
timestamp = datestr(now, 'yymmdd-HHMMSS');
results_filename = sprintf('Results_phase9_AB_flash_%s.mat', timestamp);
% save(results_filename, 'results', 'params', 'num_trials');

