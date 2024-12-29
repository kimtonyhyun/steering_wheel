classdef ScreenPTB < handle
    % Tony Hyun Kim
    % kimth@stanford.edu
    %
    % Notes:
    % - 12/29/2024: Built with Psychotoolbox 3.0.19.16 on Matlab 2024b
    properties (SetAccess=private)
        width
        height
        ifi
    end

    properties (Access=private)
        cursor_texture
        cursor_rect
        cursor_ypos

        indicator
        indicator_rect

        white
        black
        window

        waitframes
        last_vbl
    end

    methods
        function obj = ScreenPTB()
            % Basic Psychtoolbox setup
            sca;
            PsychDefaultSetup(2);

            screens = Screen('Screens');
            screen_number = max(screens);

            obj.white = WhiteIndex(screen_number);
            obj.black = BlackIndex(screen_number);

            obj.window = PsychImaging('OpenWindow', screen_number, obj.black);
            [obj.width, obj.height] = Screen('WindowSize', obj.window);
            obj.ifi = Screen('GetFlipInterval', obj.window);
            fprintf('Found %d x %d display operating at %.2f Hz\n',...
                obj.width, obj.height, 1/obj.ifi);

            cursor = Gratings_sine;
            obj.cursor_texture = Screen('MakeTexture', obj.window, cursor);
            [h, w] = size(cursor);
            obj.cursor_rect = [0 0 w h]; % Format: [top-left-x top-left-y bottom-right-x bottom-right-y]
            obj.cursor_ypos = obj.height / 4;

            obj.indicator = false;
            ind_size = 100; % pixels
            obj.indicator_rect = [0 obj.height-ind_size ind_size obj.height];

            % obj.waitframes is a KEY parameter for Psychtoolbox. It
            % determines the number of frames that must be drawn for a
            % given Flip call, before subsequent Flip calls will be made
            %------------------------------------------------------------
            obj.waitframes = 1;

            % Display initial screen
            %------------------------------------------------------------
            Screen('TextFont', obj.window, 'Arial');
            Screen('TextSize', obj.window, 64);
            DrawFormattedText(obj.window, 'Screen is ready', 'center', 'center', obj.white);

            obj.last_vbl = Screen('Flip', obj.window);
        end

        function delete(~)
            sca;
        end

        function draw_blank(obj)
            Screen('FillRect', obj.window, obj.black);

            obj.last_vbl = Screen('Flip', obj.window,...
                obj.last_vbl + (obj.waitframes - 0.5) * obj.ifi);

            obj.indicator = false;
        end

        function draw_cursor_at(obj, x)
            % X coordinate ranges from -1 to 1 --> Map to screen width
            x_pos = obj.width/2 * (x + 1);
            centered_rect = CenterRectOnPointd(obj.cursor_rect, x_pos, obj.cursor_ypos);
            Screen('DrawTexture', obj.window, obj.cursor_texture, [], centered_rect, 0);

            % Display indicator on first and every other frame
            obj.indicator = ~obj.indicator;
            if obj.indicator
                Screen('FillRect', obj.window, obj.white, obj.indicator_rect);
            end

            obj.last_vbl = Screen('Flip', obj.window,...
                obj.last_vbl + (obj.waitframes - 0.5) * obj.ifi);
        end
    end % methods
end