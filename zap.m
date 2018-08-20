function zap
% Zafar's audio player (Zap) graphical user interface (GUI).
%
%   Toolbar:
%       Open Mixture:               Open mixture file (.wav or .mp3)
%       Play Mixture:               Play/stop selected mixture audio
%       Select:                     Select/deselect on signal axes (left/right mouse click)
%       Zoom:                       Zoom in/out on any axes (left/right mouse click)
%       Pan:                        Pan on any axes
%   Axes:
%       Mixture signal axes:        Display mixture signal
%       Mixture spectrogram axes:   Display mixture spectrogram
%   
%   Author:
%       Zafar Rafii
%       zafarrafii@gmail.com
%       http://zafarrafii.com
%       https://github.com/zafarrafii
%       https://www.linkedin.com/in/zafarrafii/
%       08/20/18

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
    'TooltipString','Open Mixture', ...
    'Enable','on', ...
    'ClickedCallback',@openclickedcallback);
play_toggle = uitoggletool(toolbar_object, ...
    'CData',playicon, ...
    'TooltipString','Play Mixture', ...
    'Enable','off');

% Create pointer, zoom, and hand toggle buttons on toolbar
select_toggle = uitoggletool(toolbar_object, ...
    'Separator','On', ...
    'CData',iconread('tool_pointer.png'), ...
    'TooltipString','Select', ...
    'Enable','off');
zoom_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_zoom_in.png'), ...
    'TooltipString','Zoom', ...
    'Enable','off');
pan_toggle = uitoggletool(toolbar_object, ...
    'CData',iconread('tool_hand.png'), ...
    'TooltipString','Pan', ...
    'Enable','off');

% Create signal and spectrogram axes
signal_axes = axes( ...
    'Units','normalized', ...
    'Position',[0.05,0.85,0.9,0.1], ...
    'XTick',[], ...
    'YTick',[], ...
    'Box','on');
spectrogram_axes = axes( ...
    'Units','normalized', ...
    'Position',[0.05,0.05,0.9,0.7], ...
    'XTick',[], ...
    'YTick',[], ...
    'Box','on');

% Synchronize the x-axis limits of the signal and spectrogram axes
linkaxes([signal_axes,spectrogram_axes],'x')

% Change the pointer to a hand when the mouse moves over the signal axes
enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
iptSetPointerBehavior(signal_axes,enterFcn);
iptPointerManager(figure_object);

% Make the figure visible
figure_object.Visible = 'on';
    
    % Clicked callback function for the open toggle button
    function openclickedcallback(~,~)
        
        % Change toggle button state to off
        open_toggle.State = 'off';
        
        % Open file selection dialog box
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
        
        % Matlab's spectrogram
        audio_spectrogram = spectrogram(mean(audio_signal,2),window_function,window_length-step_length);
        
        % Number of time frames
        number_times = size(audio_spectrogram,2);
        
        % Magnitude spectrogram without DC component and mirrored 
        % frequencies
        audio_spectrogram = abs(audio_spectrogram(2:end,:));
        
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
        spectrogram_axes.Title.String = 'Audio Spectrogram';
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
        
        % Set a play audio tool on the signal axes using the audio player
        playaudiotool(signal_axes,audio_player,play_toggle);
        
        % Set a select audio tool on the signal axes using the audio player
        selectaudiotool(signal_axes,audio_player)
        
        % Add clicked callback functions to the select, zoom, and pan 
        % toggle buttons
        select_toggle.ClickedCallback = @selectclickedcallback;
        zoom_toggle.ClickedCallback = @zoomclickedcallback;
        pan_toggle.ClickedCallback = @panclickedcallback;
        
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
        
        % Change the zoom and pan toggle button states to off
        zoom_toggle.State = 'off';
        pan_toggle.State = 'off';
        
        % Turn the zoom off
        zoom off
        
        % Turn the pan off
        pan off
        
    end

    % Clicked callback function for the zoom toggle button
    function zoomclickedcallback(~,~)
        
        % Change the select and pan toggle button states to off
        select_toggle.State = 'off';
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
        
        % Change the select and zoom toggle button states to off
        select_toggle.State = 'off';
        zoom_toggle.State = 'off';
        
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

% Set a play audio tool on the signal axes using the audio player
function playaudiotool(signal_axes,audio_player,play_toggle)

% Add callback functions to the audio player
audio_player.StartFcn = @audioplayerstartfcn;
audio_player.StopFcn = @audioplayerstopfcn;
audio_player.TimerFcn = @audioplayertimerfcn;

% Sample rate in Hz from the audio player
sample_rate = audio_player.SampleRate;

% Initialize the audio line
audio_line = [];

    % Function to execute one time when the playback starts
    function audioplayerstartfcn(~,~)
        
        % Change the play audio toggle button icon to a stop icon
        play_toggle.CData = stopicon;
        
        % Sample range in samples from the audio player
        sample_range = audio_player.UserData;
        
        % Create an audio line on the audio signal axes
        audio_line = line(signal_axes,sample_range(1)/sample_rate*[1,1],[-1,1]);
        
    end
    
    % Function to execute one time when playback stops
    function audioplayerstopfcn(~,~)
        
        % Change the play audio toggle button icon to a play icon
        playaudio_toggle.CData = playicon;
        
        % Delete the audio line
        delete(audio_line)
        
    end
    
    % Function to execute repeatedly during playback
    function audioplayertimerfcn(~,~)
        
        % Current sample and sample range from the audio player
        current_sample = audio_player.CurrentSample;
        sample_range = audio_player.UserData;
        
        % Make sure the current sample is greater than the start sample (to
        % prevent the audio line from showing up at the start at the end)
        if current_sample > sample_range(1)
        
            % Update the audio line
            audio_line.XData = current_sample/sample_rate*[1,1];
            
        end
        
    end

end

% Set a select audio tool on a audio signal axes using an audio player
function selectaudiotool(audiosignal_axes,audio_player)

% Add mouse-click callback function to the audio signal axes
audiosignal_axes.ButtonDownFcn = @audiosignalaxesbuttondownfcn;

% Initialize the audio line and the audio patch with its two audio lines
audio_line = [];
audio_patch = [];
audio_line1 = [];
audio_line2 = [];

    % Mouse-click callback function for the audio signal axes
    function audiosignalaxesbuttondownfcn(~,~)
        
        % Location of the mouse pointer
        current_point = audiosignal_axes.CurrentPoint;
        
        % Minimum and maximum x and y-axis limits
        x_lim = audiosignal_axes.XLim;
        y_lim = audiosignal_axes.YLim;
        
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
            
            % If not empty, delete the audio line
            if ~isempty(audio_line)
                delete(audio_line)
            end
            
            % If not empty, delete the audio patch and its two audio lines
            if ~isempty(audio_patch)
                delete(audio_line1)
                delete(audio_line2)
                delete(audio_patch)
            end
            
            % Create an audio line on the audio signal axes
            audio_line = line(audiosignal_axes,current_point(1,1)*[1,1],[-1,1]);
            
            % Make the audio line not able to capture mouse clicks
            audio_line.PickableParts  = 'none';
            
            % Create an audio patch with two audio lines
            color_value = 0.75*[1,1,1];
            audio_patch = patch(audiosignal_axes, ...
                current_point(1)*[1,1,1,1],[-1,1,1,-1],color_value,'LineStyle','none');
            audio_line1 = line(audiosignal_axes, ...
                current_point(1,1)*[1,1],[-1,1],'Color',color_value);
            audio_line2 = line(audiosignal_axes, ...
                current_point(1,1)*[1,1],[-1,1],'Color',color_value);
            
            % Shift the patch and its two audio lines under the audio 
            % signal axes and 
            uistack(audio_patch,'bottom')
            uistack(audio_line1,'bottom')
            uistack(audio_line2,'bottom')
            
            % Make the audio patch not able to capture mouse clicks
            audio_patch.PickableParts = 'none';
            
            % Add mouse-click callback function to the two audio lines of
            % the audio patch
            audio_line1.ButtonDownFcn = @audiolinebuttondownfcn;
            audio_line2.ButtonDownFcn = @audiolinebuttondownfcn;
            
            % Change the pointer to a hand when the mouse moves over the 
            % audio lines of the audio patch and the audio signal axes
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
            iptSetPointerBehavior(audio_line1,enterFcn);
            iptSetPointerBehavior(audio_line2,enterFcn);
            iptSetPointerBehavior(audiosignal_axes,enterFcn);
            iptPointerManager(figure_object);
            
            % Add window button motion and up callback functions to the 
            % figure
            figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,audio_line2};
            figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
            
            % Update the start sample of the audio player in its user data 
            audio_player.UserData(1) = round(current_point(1,1)*sample_rate);
            
        % If click right mouse button
        elseif strcmp(selection_type,'alt')
            
            % If not empty, delete the audio line
            if ~isempty(audio_line)
                delete(audio_line)
            end
            
            % If not empty, delete the audio patch and its two audio lines
            if ~isempty(audio_patch)
                delete(audio_line1)
                delete(audio_line2)
                delete(audio_patch)
            end
            
            % Update the sample range of the audio player in its user data 
            audio_player.UserData = [1,number_samples];
            
        end
        
        % Mouse-click callback function for the audio lines of the audio
        % patch
        function audiolinebuttondownfcn(object_handle,~)
            
            % Mouse selection type
            selection_type = figure_object.SelectionType;
            
            % If click left mouse button
            if strcmp(selection_type,'normal')
                
                % Change the pointer to a hand when the mouse moves over
                % the audio signal axes
                enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','hand');
                iptSetPointerBehavior(audiosignal_axes,enterFcn);
                iptPointerManager(figure_object);
                
                % Add window button motion and up callback functions to 
                % the figure
                figure_object.WindowButtonMotionFcn = {@figurewindowbuttonmotionfcn,object_handle};
                figure_object.WindowButtonUpFcn = @figurewindowbuttonupfcn;
                
            % If click right mouse button
            elseif strcmp(selection_type,'alt')
                
                % Delete the audio line and the audio patch with its two 
                % audio lines
                delete(audio_line)
                delete(audio_line1)
                delete(audio_line2)
                delete(audio_patch)
                
                % Update the sample range of the audio player in its user 
                % data
                audio_player.UserData = [1,number_samples];
                
            end
            
        end
        
        % Window button motion callback function for the figure
        function figurewindowbuttonmotionfcn(~,~,audio_linei)
            
            % Location of the mouse pointer
            current_point = audiosignal_axes.CurrentPoint;
            
            % If the current point is out of the x-axis limits, return
            if current_point(1,1) < x_lim(1) || current_point(1,1) > x_lim(2)
                return
            end
            
            % Update the coordinates of the audio line of the audio patch 
            % that has been clicked and the coordinates of the audio patch
            audio_linei.XData = current_point(1,1)*[1,1];
            audio_patch.XData = [audio_line1.XData,audio_line2.XData];
            
            % If the two audio lines of the audio patch are at different 
            % coordinates and the audio patch is a full rectangle
            if audio_line1.XData(1) ~= audio_line2.XData(1)
                
                % Hide the audio line without deleting it
                audio_line.Visible = 'off';
                
            % If the two audio lines of the audio patch are at the same 
            % coordinates and the audio patch is a vertical line
            else
                
                % Update the coordinates of the audio line and display it
                audio_line.XData = current_point(1,1)*[1,1];
                audio_line.Visible = 'on';
                
            end
            
        end
        
        % Window button up callback function for the figure
        function figurewindowbuttonupfcn(~,~)
            
            % Change the pointer to a ibeam when the mouse moves over the 
            % audio signal axes in the figure
            enterFcn = @(figure_handle, currentPoint) set(figure_handle,'Pointer','ibeam');
            iptSetPointerBehavior(audiosignal_axes,enterFcn);
            iptPointerManager(figure_object);
            
            % Coordinates of the two audio lines of the audio patch
            x_value1 = audio_line1.XData(1);
            x_value2 = audio_line2.XData(1);
            
            % If the two audio lines of the audio patch are at the same
            % coordinates
            if x_value1 == x_value2
                
                % Update the sample range of the audio player in its user
                % data
                audio_player.UserData = [round(x_value1*sample_rate),number_samples];
                
            % If audio_line1 is on the left side of audio_line2
            elseif x_value1 < x_value2
                
                % Update the sample range of the audio player in its user
                % data
                audio_player.UserData = round([x_value1,x_value2]*sample_rate);
            
            % If audio_line1 is on the right side of audio_line2
            else
                
                % Update the sample range of the audio player in its user
                % data (reversed)
                audio_player.UserData = round([x_value2,x_value1]*sample_rate);
                
            end
            
            % Remove the window button motion and up callback functions of
            % the figure
            figure_object.WindowButtonMotionFcn = '';
            figure_object.WindowButtonUpFcn = '';
            
        end
        
    end

end
