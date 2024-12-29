classdef ScreenPTB < handle
    properties (SetAccess=private)
        width
        height
        ifi
    end

    properties (Access=private)
        white
        black
        window
        last_vbl
    end

    methods
        function obj = ScreenPTB()
            sca;
            PsychDefaultSetup(2);

            screens = Screen('Screens');
            screen_number = max(screens);

            obj.white = WhiteIndex(screen_number);
            obj.black = BlackIndex(screen_number);

            [obj.window, windowRect] = PsychImaging('OpenWindow', screen_number, obj.black);
            [obj.width, obj.height] = Screen('WindowSize', obj.window);
            obj.ifi = Screen('GetFlipInterval', obj.window);
            fprintf('Found %d x %d display operating at %.2f Hz\n',...
                obj.width, obj.height, 1/obj.ifi);

            % Display initial screen
            %------------------------------------------------------------
            Screen('TextFont', obj.window, 'Arial');
            Screen('TextSize', obj.window, 64);
            DrawFormattedText(obj.window, 'Screen is ready', 'center', 'center', obj.white);

            obj.last_vbl = Screen('Flip', obj.window);
        end

        function draw_blank(obj)

        end

        function draw_cursor_at(obj)

        end
    end % methods
end