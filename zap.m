function zap
% Zafar's audio player (Zap) graphical user interface (GUI).
%
%   Zap implements a simple audio player as a Matlab programmatic GUI. The 
%   user can open a WAV or MP3 file, play/stop the audio, select/drag a 
%   region to play, and zoom and pan on the axes. The code is 
%   self-explanatory, heavily commented, and fully modular. Parts of the 
%   code can be helpful for other GUIs, especially the playaudiotool 
%   function which displays a playback line as the playback is in progress 
%   and the selectaudiotool function which allows the user to create a 
%   selection line or region on the audio to play.
%   
%   Toolbar's toggle buttons:
%   
%   - Open:
%       - Select a WAVE or MP3 to open (the audio can be multichannel).
%       - Display the audio signal and the audio spectrogram (in dB); the 
%       horizontal limits of the signal and spectrogram axes will be 
%       synchronized (and will stay synchronized if a zoom or pan is 
%       applied on any of the axes).
%   
%   - Play/Stop:
%       - Play the audio if the playback is not in progress; stop the audio 
%       if the playback is in progress; a playback line will be displayed 
%       as the playback is in progress.
%       - If there is no selection line or region, the audio will be played 
%       from the start to the end; if there is a selection line, the audio 
%       will be played from the selection line to the end of the audio; if 
%       there is a selection region, the audio will be played from the 
%       start to the end of the selection region.
%   
%   - Select/Drag:
%       - If a left mouse click is done on the signal axes, a selection 
%       line is created; the audio will be played from the selection line 
%       to the end of the audio.
%       - If a left mouse click and drag is done on the signal axes or on a 
%       selection line, a selection region is created; the audio will be 
%       played from the start to the end of the selection region.
%       - If a left mouse click and drag is done on the left or right 
%       boundary of a selection region, the selection region is resized.
%       - If a right mouse click is done on the signal axes, any selection 
%       line or region is removed.
%       
%   - Zoom:
%       - Turn zooming on or off or magnify by factor 
%       (see https://mathworks.com/help/matlab/ref/zoom.html)
%       - If used on the signal axes, zoom horizontally only; the 
%       horizontal limits of the signal and spectrogram axes will stay 
%       synchronized.
%   
%   - Pan:
%       - Pan view of graph interactively 
%       (see https://www.mathworks.com/help/matlab/ref/pan.html)
%       - If used on the signal axes, pan horizontally only; the horizontal 
%       limits of the signal and spectrogram axes will stay synchronized.
%   
%   Author:
%       Zafar Rafii
%       zafarrafii@gmail.com
%       http://zafarrafii.com
%       https://github.com/zafarrafii
%       https://www.linkedin.com/in/zafarrafii/
%       08/28/18

% Get screen size
screen_size = get(0,'ScreenSize');

% Create figure window
figure_object = figure( ...
    'Visible','off', ...
    'Position',[screen_size(3:4)/4+1,screen_size(3:4)/2], ...
    'Name','Zafar''s Audio Player', ...
    'NumberTitle','off', ...
    'MenuBar','none');

% Create toolbar on figure
toolbar_object = uitoolbar(figure_object);

% Create open and play toggle buttons on toolbar
open_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('file_open.png'), ...
    'TooltipString','Open', ...
    'Enable','on', ...
    'ClickedCallback',@openclickedcallback);
play_toggle = uitoggletool(toolbar_object, ...
    'CData',playicon, ...
    'TooltipString','Play', ...
    'Enable','off');

% Create pointer, zoom, and hand toggle buttons on toolbar
select_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',iconread('tool_pointer.png'), ...
    'TooltipString','Select', ...
    'Enable','off', ...
    'ClickedCallBack',@selectclickedcallback);
zoom_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_zoom_in.png'), ...
    'TooltipString','Zoom', ...
    'Enable','off', ...
    'ClickedCallBack',@zoomclickedcallback);
pan_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_hand.png'), ...
    'TooltipString','Pan', ...
    'Enable','off', ...
    'ClickedCallBack',@panclickedcallback);

% Create signal and spectrogram axes
signal_axes = axes( ...
    'OuterPosition',[0,0.8,1,0.2], ...
    'Visible','off');
spectrogram_axes = axes( ...
    'OuterPosition',[0,0,1,0.8], ...
    'Visible','off');

% Synchronize the x-axis limits of the signal and spectrogram axes
linkaxes([signal_axes,spectrogram_axes],'x')

% Change the pointer when the mouse moves over the signal axes
enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
iptSetPointerBehavior(signal_axes,enterFcn);
iptPointerManager(figure_object);

% Make the figure visible
figure_object.Visible = 'on';
    
    % Clicked callback function for the open toggle button
    function openclickedcallback(~,~)
        
        % Change toggle button state to off
        open_toggle.State = 'off';
        
        % Open file selection dialog box; return if cancel
        [audio_name,audio_path] = uigetfile({'*.wav';'*.mp3'}, ...
            'Select WAVE or MP3 File to Open');
        if isequal(audio_name,0)
            return
        end
        
        % Build full file name
        audio_file = fullfile(audio_path,audio_name);

        % Read audio file and return sample rate in Hz
        [audio_signal,sample_rate] = audioread(audio_file);
        
        % Number of samples
        number_samples = size(audio_signal,1);

        % Window length in samples (audio stationary around 40 ms and power 
        % of 2 for fast FFT and constant overlap-add)
        window_length = 2.^nextpow2(0.04*sample_rate);

        % Window function ('periodic' Hamming window for constant 
        % overlap-add)
        window_function = hamming(window_length,'periodic');

        % Step length (half the (even) window length for constant 
        % overlap-add)
        step_length = window_length/2;
        
        % Magnitude spectrogram without DC component and mirrored 
        % frequencies
        audio_spectrogram = spectrogram(mean(audio_signal,2),window_function,window_length-step_length);
        audio_spectrogram = abs(audio_spectrogram(2:end,:));
        
        % Number of time frames
        number_times = size(audio_spectrogram,2);
        
        % Plot the audio signal and make it unable to capture mouse clicks
        plot(signal_axes,1/sample_rate:1/sample_rate:number_samples/sample_rate,audio_signal, ...
            'PickableParts','none');
        
        % Update the signal axes properties
        signal_axes.XLim = [1,number_samples]/sample_rate;
        signal_axes.YLim = [-1,1];
        signal_axes.XGrid = 'on';
        signal_axes.Title.String = audio_name;
        signal_axes.Title.Interpreter = 'None';
        signal_axes.XLabel.String = 'Time (s)';
        signal_axes.Layer = 'top';
        
        % Display the audio spectrogram (in dB)
        imagesc(spectrogram_axes, ...
            [1,number_times]/number_times*number_samples/sample_rate, ...
            [1,window_length/2]/window_length*sample_rate, ...
            db(audio_spectrogram))
        
        % Update the spectrogram axes properties
        spectrogram_axes.Colormap = jet;
        spectrogram_axes.YDir = 'normal';
        spectrogram_axes.XGrid = 'on';
        spectrogram_axes.Title.String = 'Spectrogram (dB)';
        spectrogram_axes.XLabel.String = 'Time (s)';
        spectrogram_axes.YLabel.String = 'Frequency (Hz)';
        
        % Create object for playing audio
        audio_player = audioplayer(audio_signal,sample_rate);
        
        % Store the sample range in the user data of the audio player
        audio_player.UserData = [1,number_samples];
        
        % Add close request callback function to the figure object
        figure_object.CloseRequestFcn = {@figurecloserequestfcn,audio_player};
        
        % Add clicked callback function to the play toggle button
        play_toggle.ClickedCallback = {@playclickedcallback,audio_player};
        
        % Set a play line and a select line on the signal axes using the 
        % audio player
        playline(signal_axes,audio_player,play_toggle);
        selectline(signal_axes,audio_player)
        
        % Enable the play, select, zoom, and pan toggle buttons
        play_toggle.Enable = 'on';
        select_toggle.Enable = 'on';
        zoom_toggle.Enable = 'on';
        pan_toggle.Enable = 'on';
        
        % Change the select toggle button states to on
        select_toggle.State = 'on';
        
    end

    % Clicked callback function for the select toggle button
    function selectclickedcallback(~,~)
        
        % Keep the select toggle button state to on and change the zoom and 
        % pan toggle button states to off
        select_toggle.State = 'on';
        zoom_toggle.State = 'off';
        pan_toggle.State = 'off';
        
        % Turn the zoom off
        zoom off
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the zoom toggle button
    function zoomclickedcallback(~,~)
        
        % Keep the zoom toggle button state to on and change the select and 
        % pan toggle button states to off
        select_toggle.State = 'off';
        zoom_toggle.State = 'on';
        pan_toggle.State = 'off';
        
        % Make the zoom enable on the current figure
        zoom_object = zoom(gcf);
        zoom_object.Enable = 'on';
        
        % Set the zoom for the x-axis only in the signal axes
        setAxesZoomConstraint(zoom_object,signal_axes,'x');
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the pan toggle button
    function panclickedcallback(~,~)
        
        % Keep the pan toggle button state to on and change the select and 
        % zoom toggle button states to off
        select_toggle.State = 'off';
        zoom_toggle.State = 'off';
        pan_toggle.State = 'on';
        
        % Turn the zoom off
        zoom off
        
        % Make the pan enable on the current figure
        pan_object = pan(gcf);
        pan_object.Enable = 'on';
        
        % Set the pan for the x-axis only in the signal axes
        setAxesPanConstraint(pan_object,signal_axes,'x');
        
    end

end

% Create play icon
function image_data = playicon

    % Create the upper-half of a black play triangle with NaN's everywhere 
    % else
    image_data = [nan(2,16);[nan(6,3),kron(triu(nan(6,5)),ones(1,2)),nan(6,3)]];

    % Make the whole black play triangle image
    image_data = repmat([image_data;image_data(end:-1:1,:)],[1,1,3]);

end
 
% Create stop icon
function image_data = stopicon

    % Create a black stop square with NaN's everywhere else
    image_data = nan(16,16);
    image_data(4:13,4:13) = 0;

    % Make the black stop square an image
    image_data = repmat(image_data,[1,1,3]);

end

% Read icon from Matlab
function image_data = iconread(icon_name)

    % Read icon image from Matlab ([16x16x3] 16-bit PNG) and also return 
    % its transparency ([16x16] AND mask)
    [image_data,~,image_transparency] ...
        = imread(fullfile(matlabroot,'toolbox','matlab','icons',icon_name),'PNG');

    % Convert the image to double precision (in [0,1])
    image_data = im2double(image_data);

    % Convert the 0's to NaN's in the image using the transparency
    image_data(image_transparency==0) = NaN;

end

% Close request callback function for the figure
function figurecloserequestfcn(~,~,audio_player)

% If the playback is in progress
if isplaying(audio_player)
    
    % Stop the audio
    stop(audio_player)
    
end

% Delete the current figure
delete(gcf)

end

% Clicked callback function for the play toggle button
function playclickedcallback(object_handle,~,audio_player)

% Change the toggle button state to off
object_handle.State = 'off';

% If the playback of the audio player is in progress
if isplaying(audio_player)
    
    % Stop the playback
    stop(audio_player)
    
else
    
    % Get the sample range of the audio player from its user data 
    sample_range = audio_player.UserData;
    
    % Play the audio given the sample range
    play(audio_player,sample_range)
    
end

end

% Set a play line on the signal axes using the audio player
function playline(signal_axes,audio_player,play_toggle)

% Add callback functions to the audio player
audio_player.StartFcn = @audioplayerstartfcn;
audio_player.StopFcn = @audioplayerstopfcn;
audio_player.TimerFcn = @audioplayertimerfcn;

% Sample rate in Hz from the audio player
sample_rate = audio_player.SampleRate;

% Initialize the play line as an empty array
play_line = [];

    % Function to execute one time when the playback starts
    function audioplayerstartfcn(~,~)
        
        % Change the play toggle button icon to a stop icon and the tool 
        % tip text to 'Stop'
        play_toggle.CData = stopicon;
        play_toggle.TooltipString = 'Stop';
        
        % Get the sample range of the audio player from its user data
        sample_range = audio_player.UserData;
        
        % Create a play line on the audio signal axes
        play_line = line(signal_axes,sample_range(1)/sample_rate*[1,1],[-1,1]);
        
    end
    
    % Function to execute one time when playback stops
    function audioplayerstopfcn(~,~)
        
        % Change the play toggle button icon to a play icon and the tool 
        % tip text to 'Play'
        play_toggle.CData = playicon;
        play_toggle.TooltipString = 'Play';
        
        % Delete the play line
        delete(play_line)
        
    end
    
    % Function to execute repeatedly during playback
    function audioplayertimerfcn(~,~)
        
        % Current sample and sample range from the audio player
        current_sample = audio_player.CurrentSample;
        sample_range = audio_player.UserData;
        
        % Make sure the current sample is greater than the start sample (to
        % prevent the play line from showing up at the start at the end)
        if current_sample > sample_range(1)
        
            % Update the play line
            play_line.XData = current_sample/sample_rate*[1,1];
            
        end
        
    end

end

% Set a select tool on the signal axes using the audio player
function selectline(signal_axes,audio_player)

% Add mouse-click callback function to the signal axes
signal_axes.ButtonDownFcn = @signalaxesbuttondownfcn;

% Initialize the select line as an array for graphic objects (two lines and 
% one patch)
select_line = gobjects(3,1);

    % Mouse-click callback function for the signal axes
    function signalaxesbuttondownfcn(~,~)
        
        % Location of the mouse pointer
        current_point = signal_axes.CurrentPoint;
        
        % Minimum and maximum x and y-axis limits
        x_lim = signal_axes.XLim;
        y_lim = signal_axes.YLim;
        
        % If the current point is out of the axis limits, return
        if current_point(1,1) < x_lim(1) || current_point(1,1) > x_lim(2) || ...
                current_point(1,2) < y_lim(1) || current_point(1,2) > y_lim(2)
            return
        end
        
        % Current figure handle
        figure_object = gcf;
        
        % Mouse selection type
        selection_type = figure_object.SelectionType;
        
        % Sample rate and number of samples from the audio player
        sample_rate = audio_player.SampleRate;
        number_samples = audio_player.TotalSamples;
        
        % If click left mouse button
        if strcmp(selection_type,'normal')
            
            % If not empty, delete the select line
            if ~isempty(select_line)
                delete(select_line)
            end
            
            % Create a first line on the signal axes
            color_value1 = 0.5*[1,1,1];
            select_line(1) = line(signal_axes,current_point(1,1)*[1,1],[-1,1],'Color',color_value1);
            
            % Create a second line and a patch with different colors
            color_value2 = 0.75*[1,1,1];
            select_line(2) = line(signal_axes, ...
                current_point(1,1)*[1,1],[-1,1],'Color',color_value2);
            select_line(3) = patch(signal_axes, ...
                current_point(1)*[1,1,1,1],[-1,1,1,-1],color_value2,'LineStyle','none');
            
            % Move the second line and the patch at the bottom of the 
            % current stack
            uistack(select_line(2),'bottom')
            uistack(select_line(3),'bottom')
            
            % Add mouse-click callback functions to the lines
            select_line(1).ButtonDownFcn = @selectlinebuttondownfcn;
            select_line(2).ButtonDownFcn = @selectlinebuttondownfcn;
            
            % Make the patch not able to capture mouse clicks
            select_line(3).PickableParts = 'none';
            
            % Change the pointer to a hand when the mouse moves over the 
            % lines on the audio signal axes
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
            iptSetPointerBehavior(select_line(1),enterFcn);
            iptSetPointerBehavior(select_line(2),enterFcn);
            iptSetPointerBehavior(signal_axes,enterFcn);
            iptPointerManager(figure_object);
            
            % Add window button motion and up callback functions to the 
            % figure
            figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,select_line(1)};
            figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
            
            % Update the start sample of the audio player in its user data 
            audio_player.UserData(1) = round(current_point(1,1)*sample_rate);
            
        % If click right mouse button
        elseif strcmp(selection_type,'alt')
            
            % If not empty, delete the select line
            if ~isempty(select_line)
                delete(select_line)
            end
            
            % Update the sample range of the audio player in its user data 
            audio_player.UserData = [1,number_samples];
            
        end
        
        % Mouse-click callback function for the lines
        function selectlinebuttondownfcn(object_handle,~)
            
            % Mouse selection type
            selection_type = figure_object.SelectionType;
            
            % If click left mouse button
            if strcmp(selection_type,'normal')
                
                % Change the pointer to a hand when the mouse moves over
                % the signal axes
                enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
                iptSetPointerBehavior(signal_axes,enterFcn);
                iptPointerManager(figure_object);
                
                % Add window button motion and up callback functions to 
                % the figure
                figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,object_handle};
                figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
                
            % If click right mouse button
            elseif strcmp(selection_type,'alt')
                
                % Delete the select line
                delete(select_line)
                
                % Update the sample range of the audio player in its user 
                % data
                audio_player.UserData = [1,number_samples];
                
            end
            
        end
        
        % Window button motion callback function for the figure
        function figurewindowbuttonmotionfcn(~,~,select_linei)
            
            % Location of the mouse pointer
            current_point = signal_axes.CurrentPoint;
            
            % If the current point is out of the x-axis limits, return
            if current_point(1,1) < x_lim(1) || current_point(1,1) > x_lim(2)
                return
            end
            
            % Update the coordinates of the line that has been clicked and 
            % the coordinates of the patch
            select_linei.XData = current_point(1,1)*[1,1];
            select_line(3).XData = [select_line(1).XData,select_line(2).XData];
            
            % If the two lines are at different coordinates and the patch 
            % is a full rectangle
            if select_line(1).XData(1) ~= select_line(2).XData(1)
                
                % Change the color of the first line to match the color of 
                % the second line and the patch, and move it at the bottom 
                % the current stack
                select_line(1).Color = color_value2;
                uistack(select_line(1),'bottom')
                
            % If the two lines are at the same coordinates and the patch is 
            % a vertical line
            else
                
                % Change the color of the first line back, and move it at 
                % the top of the current stack
                select_line(1).Color = color_value1;
                uistack(select_line(1),'top')
                
            end
            
        end
        
        % Window button up callback function for the figure
        function figurewindowbuttonupfcn(~,~)
            
            % Change the pointer to a ibeam when the mouse moves over the 
            % signal axes in the figure
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
            iptSetPointerBehavior(signal_axes,enterFcn);
            iptPointerManager(figure_object);
            
            % Coordinates of the two lines
            x_value1 = select_line(1).XData(1);
            x_value2 = select_line(2).XData(1);
            
            % Update the sample range of the audio player in its user data 
            % depending if the two lines have the same or diffferent 
            % coordinates
            if x_value1 == x_value2
                audio_player.UserData = [round(x_value1*sample_rate),number_samples];
            elseif x_value1 < x_value2
                audio_player.UserData = round([x_value1,x_value2]*sample_rate);
            else
                audio_player.UserData = round([x_value2,x_value1]*sample_rate);
                
            end
            
            % Remove the window button motion and up callback functions of
            % the figure
            figure_object.WindowButtonMotionFcn = '';
            figure_object.WindowButtonUpFcn = '';
            
        end
        
    end

end

