classdef Screen < handle
    properties (SetAccess=private)
        h_fig
        h_ax
        h_cursor
        h_cursor_indicator
        h_cursor_indicator_BG % newly added. Shortens reaction time of the iPad screen brightness sensor
        
        cursor_x
        cursor_image % newly added 230609
    end
    
    properties (Constant)
        % Pixel resolution of the iPad screen
        %------------------------------------------------------------
        Width = 2048;
        Height = 1536;
        
        % Cursor visual parameters
        %------------------------------------------------------------
        % Scaled to the axis range where:
        %   - X ranges from [-1 to 1]
        %   - Y ranges from Screen.Height/Width*[-1 1] = [-0.75 0.75]
        cursor_scale = 1.3;
        cursor_y_offset = 0.35;
    end
    
    methods
        function obj = Screen()
            % The figure setup assumes that the iPad screen:
            %   - is the SECONDARY screen, located to the RIGHT of the
            %     PRIMARY screen;
            %   - does NOT have the Windows taskbar;
            %   - does NOT have Windows scaling (i.e. set to 100% scaling)
                      
            % Figure fills the iPad screen
%             primary_screen_offset = 1920;
%             obj.h_fig = figure('MenuBar', 'none',...
%                 'Position',... % [Left Bottom Width Height]
%                 [primary_screen_offset 0 Screen.Width Screen.Height]);
            obj.h_fig = figure('MenuBar', 'none');
            
            % Fill the figure
            obj.h_ax = subplot('Position', [0 0 1 1]);
%             obj.h_ax = subplot('Position', [0.1 0.1 0.8 0.8]); % For debug -- can see axes
            
            % Set up visual cursor and indicator elements
            cursor_image = Gratings_sine;  obj.cursor_image=cursor_image;
            obj.cursor_x = Screen.cursor_scale * linspace(-0.5, 0.5, size(cursor_image,2));
            y = Screen.cursor_scale * linspace(-0.5, 0.5, size(cursor_image,1));
            obj.h_cursor = imagesc(obj.cursor_x, y + Screen.cursor_y_offset, cursor_image);
            set(obj.h_ax, 'YDir', 'normal');
            set(obj.h_ax, 'CLim', [0 1]);
            
            %YS ADDED on Jul 14, 2022
            % remove the green element
            Gray_ex_G = gray;
            Gray_ex_G(:,2) = 0;
            colormap(Gray_ex_G);% not gray
            %colormap gray;
            
            xlim([-1 1]);
            ylim([-0.75 0.75]);
            set(obj.h_ax, 'TickLength', [0 0]);
            set(obj.h_ax, 'Color', 'k');
            
            cursor_indicator_size = 0.2;
            obj.h_cursor_indicator_BG = rectangle(...
                'Position', [-1 -0.75 cursor_indicator_size cursor_indicator_size],...
                'FaceColor', [1 1 1]*0.55, 'EdgeColor', 'none');
                        
            obj.h_cursor_indicator = rectangle(...
                'Position', [-1 -0.75 cursor_indicator_size cursor_indicator_size],...
                'FaceColor', [1 1 1]*0.8, 'EdgeColor', 'none');

            obj.hide_cursor;
        end
        
        function hide_cursor(obj)
            obj.h_cursor.Visible = 'off';
            obj.h_cursor_indicator.Visible = 'off';
        end
        
        function show_cursor(obj)
            obj.h_cursor.Visible = 'on';
            obj.h_cursor_indicator.Visible = 'on';
        end
        
        function set_cursor_position(obj, x_center)
            obj.h_cursor.XData = x_center + obj.cursor_x;
        end
    end % methods
end