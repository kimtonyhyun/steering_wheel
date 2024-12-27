% made for YYY's attempt to use a PLS decoder, May 26th, 2023
% Tony's development, 12/08, 2024

clear all; close all;
cd('C:\Users\octopus\Documents\steering_wheel_task');

a   = arduino('COM7');  %a = arduino('COM7');in rig3
bmi2 = arduino_BMI('COM4'); % Arm2 BMI command
%bmi3 = arduino_BMI('COM6'); % Arm3or4 BMI command

screen = Screen_v2();

% check the cursor type
figure
I = imagesc(screen.cursor_image);daspect([1 1 1])
colormap(gray);colorbar;

%%

clearvars -except a bmi2 bmi3 screen;

params = get_default_params;

Microscope_Hz = 30  %8.52 % % galvo:8 Hz. resonant:30 Hz?
num_trials = 300;
"BMI (Phase9) 1-arm driven"

params.x0_list = [-1 -1 1 1 -1 -1 1 1]; 
params.x0_list_label = {'Left','Left','Right','Right', 'Left','Left','Right','Right'}; %s minimum,
%params.x0_d_list = [0.58]; 
params.x0_d_list =  [0.40 0.60 0.80 1 1.2 1.4 1.6]*0.58; % 0.2320    0.3480    0.4640    0.5800    0.6960    0.8120    0.9280  %%[0.25 0.5 0.75 1 1.25 1.5 1.75]*0.58; % 0.1450    0.2900    0.4350    0.5800    0.7250    0.8700    1.0150-almost edge
params.quiescent_period_duration =  0.1;  0.3; 1; % s  0.1;
params.xGoal = 0;
params.xFail = 1.16;
params.Microscope_Hz = Microscope_Hz;

% Gain of 1 means that one full turn of the wheel is required to cover HALF
% of the screen width.
params.gain =  2.32; % in case gain=0.01, 58 counts to goal (X from 0.58 to 0.00 or 1.16). 

sound_hit = audioread('sound/10kHz_500ms_fadein.mp3');
sound_miss = audioread('sound/White_500ms.mp3');
Fs = 44100;

% Preallocate results
results = initialize_results(num_trials);

%%  
params.duration_per_pulse_ms = 30;
params.num_pulses = 4;

% Note (2024 Dec 10):
% Shikano argues that we should not be calling drawnow in rapid succession.
% What happens if we call drawnow at a rate faster than the frame rate of
% the iPad screen (60 Hz)? The post_drawnow_delay will prevent successive
% drawnow calls from occuring faster than 60 Hz.
params.post_drawnow_delay = 0.0168; % 0.017 works , 0.016 OK but risky, 0.0165 realistic, 0.0168 (21Hz) best?

%%
flush(a); % Serial line may have garbage from previous interactions
flush(bmi2); 
%flush(bmi3); 
screen.hide_cursor;

% task start
a.start_behavior_clock;
pause(2);

trial_number = 0;

% randomization block
x0_list_temp = params.x0_list;  %start_location_remaining
x0_list_temp_label = params.x0_list_label
%Antibias
Log_temp = zeros(8,2) + NaN;

while trial_number < num_trials
    trial_number = trial_number + 1;
    fprintf('%s: Trial %d\n', datestr(now), trial_number);
    
    % Select the initial cursor position
    %------------------------------------------------------------   
    if isempty(x0_list_temp)
        x0_list_antibias = [];
        x0_list_label_antibias = [];
        %Left 
        Log_temp_L = Log_temp(find(Log_temp(:,1)==-1),2);
        Unhit_L    = max([0.5 length(find(Log_temp_L<1))]);
        Log_temp_R = Log_temp(find(Log_temp(:,1)== 1),2);
        Unhit_R    = max([0.5 length(find(Log_temp_R<1))]);
        N_L = round(8 * Unhit_L /(Unhit_L+ Unhit_R));
        N_R = 8 - N_L;
        for nl = 1:N_L;
            x0_list_antibias(1,nl) = -1;
            x0_list_label_antibias{1,nl} =  'Left';
        end
        for nl = N_L+1:8;
            x0_list_antibias(1,nl) = 1;
            x0_list_label_antibias{1,nl} =  'Right';
        end        
        x0_list_temp = x0_list_antibias; %Params.start_location_list;
        x0_list_temp_label = x0_list_label_antibias %Params.start_location_list_label;
    end
    ind = randi(length(x0_list_temp));
    x0_pre = x0_list_temp(ind);
    position_label = x0_list_temp_label{ind};
    x0_list_temp(ind) = [];
    x0_list_temp_label(ind) = [];
    ind = randi(length(params.x0_d_list));
    Distance = params.x0_d_list(ind);
    x0 = x0_pre * Distance;
    xGoal = params.xGoal;
    xFail = params.xFail * x0 / abs(x0);
    
    screen.set_cursor_position(x0);
    if (x0 < 0)
        fprintf('  - LEFT start from x0 = %.3f (%.3f)\n', x0, round(x0/0.58,2));
    else
        fprintf('  - RIGHT start from x0 = %.3f (%.3f)\n', x0, round(x0/0.58,2));
    end

    % Quiescent period
    %------------------------------------------------------------
    fprintf('  - Entering quiescent period for a minimum of %.3f s... ',...
    params.quiescent_period_duration);
    bmi2.reset_encoder_count;
    %bmi3.reset_encoder_count;
    
    tic;
    t = 0;
    t_qp_threshold = params.quiescent_period_duration;
    while (t < t_qp_threshold)
        t = toc;
        count2 = bmi2.get_encoder_count_silent;        
        
        %count3 = bmi3.get_encoder_count;
        %[t count2 count3 ];

        if (abs(count2) > 0) %||  (abs(count3) > 0) % Roughly +/-2 deg of wheel, assuming ppr=1024
            t_qp_threshold = t + params.quiescent_period_duration;
        end
    end
    fprintf('Total duration was %.3f s\n', t_qp_threshold);
    
    % For preallocation, assume that sampling rate is slower than 1 ms
    cursor_trajectory = zeros(params.max_trial_duration * 1e3, 2); % Format: [Time(s) CursorPosition]
    ts = zeros(params.max_trial_duration * 1e3, 1);
    screen_indicator = zeros(params.max_trial_duration * 1e3, 1);
    BMI_counts = zeros(params.max_trial_duration * 1e3, 1);
    BMI_counts_integ = zeros(params.max_trial_duration * 1e3, 1);
    
    a.reset_encoder_count;
    bmi2.reset_encoder_count;
    %bmi3.reset_encoder_count;flush(bmi3); 
   
    % Show cursor
    %------------------------------------------------------------
    tic;
    a.set_screen_ttl(1);
    screen.set_cursor_position(x0);
    screen.show_cursor; % Screen indicator is also made visible
    drawnow;
    pause(params.post_drawnow_delay);
    indicator_on = true;
    
    trial_result = 'Timeout';
    t = 0; 
    ind = 0;
    x_pre = x0;
    trial_done = false;
    
    while t < params.max_trial_duration    
        % Index of interaction with the BMI Arduino
        ind = ind + 1;
        
        % Note: BMI Arduino resets counter automatically
        %       after 'get_encoder_count'
        t = toc;
        count2 = bmi2.get_encoder_count();
        
        %count3 = bmi3.get_encoder_count();
        count  = count2 ;%+ count3; %sqrt(count2^2 + count3^2);
        %[t count2 count3 count];
                
        %x = x0 + params.gain * (count / params.ppr);
        x = x_pre +  params.gain * (512 * count / params.ppr) / Microscope_Hz  ; % 0.05 is the scan interval(s), If motion, the scan is done at 20Hz or so, 
               
        % Update the screen if the cursor position has changed
        if x ~= x_pre

            if x*x_pre<=0; x=0; end
            if abs(x)>=0.58*2; x=0.58*2*x/abs(x);end

            screen.set_cursor_position(x); % update the cursor position

            indicator_on = ~indicator_on; % Toggle on every frame update
            if indicator_on
                screen.h_cursor_indicator.Visible = 'on';              
            else
                screen.h_cursor_indicator.Visible = 'off';
            end
            drawnow;            

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
            
            pause(params.post_drawnow_delay);
            x_pre = x; 
        end % Cursor position has changed

        % Log the 'get_encoder_count' interaction
        ts(ind) = t;
        cursor_trajectory(ind,:) = [t x]; % Leave t in for backwards compatibility
        screen_indicator(ind,:) = indicator_on; 
        BMI_counts(ind) = count2;
        BMI_counts_integ(ind) = count;
        
        if trial_done
            break;
        end
    end % Intra-trial loop
    
    cursor_trajectory = cursor_trajectory(1:ind,:);
    ts = ts(1:ind,:);
    screen_indicator = screen_indicator(1:ind,:);
    BMI_counts = BMI_counts(1:ind,:);
    BMI_counts_integ = BMI_counts_integ(1:ind,:);
    fprintf('  - Result: %s!\n', trial_result);
    pause(params.post_trial_cursor_on_duration);
    screen.hide_cursor;
    a.set_screen_ttl(0);
    
    %sound for timeout
    if trial_result(1) == 'T'
        sound(sound_miss, Fs);
    end
    
    %Antibias
    Log_temp(1:7,:) =  Log_temp (2:end,:);
    Log_temp(8,1)  =  x0_pre;
    if trial_result(1) == 'H'
        Log_temp(8,2)  =  1; 
    elseif trial_result(1) == 'M'
        Log_temp(8,2)  =  -1; 
    else
        Log_temp(8,2)  =  0; 
    end
    
    % Store results
    %------------------------------------------------------------
    results(trial_number).x0 = x0;
    results(trial_number).xGoal = xGoal;
    results(trial_number).xFail = xFail;
    results(trial_number).quiescent_period_duration = t_qp_threshold;
    results(trial_number).stimulus_duration = cursor_trajectory(end,1);
    results(trial_number).cursor_trajectory = cursor_trajectory;
    results(trial_number).result = trial_result;
    results(trial_number).ts = ts;
    results(trial_number).screen_indicator = screen_indicator;
    results(trial_number).BMI_counts = BMI_counts;
    results(trial_number).BMI_counts_integ = BMI_counts_integ;

    % ITI (Store results section & ITI section flipped after 230811)
    %------------------------------------------------------------
    iti = generate_iti;
    fprintf('  - Waiting an ITI of %.3f s\n', iti);
    results(trial_number).iti = iti;
    pause(iti);
    

end
%%
a.stop_behavior_clock;
a.set_screen_ttl(0);
screen.hide_cursor;

% Save results to file

timestamp = datestr(now, 'yymmdd-HHMMSS');
results_filename = sprintf('Results_BMI_1Arm_%s.mat', timestamp);
save(results_filename, 'results', 'params', 'num_trials','screen');

screen.hide_cursor;
