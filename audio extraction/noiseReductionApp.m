classdef noiseReductionApp < matlab.apps.AppBase

    properties (Access = public)
        UIFigure         matlab.ui.Figure
        LoadButton       matlab.ui.control.Button
        ProcessButton    matlab.ui.control.Button
        PlayOrigButton   matlab.ui.control.Button
        PlayCleanButton  matlab.ui.control.Button
        StopButton       matlab.ui.control.Button
        SaveButton       matlab.ui.control.Button
        AlphaField       matlab.ui.control.NumericEditField
        AlphaLabel       matlab.ui.control.Label
        InputAxes        matlab.ui.control.UIAxes
        OutputAxes       matlab.ui.control.UIAxes

        % Data
        inputFile
        y_orig
        fs
        y_clean
    end

    methods (Access = private)

        function LoadButtonPushed(app, ~)
            [file, path] = uigetfile({'*.wav;*.mp3;*.m4a;*.mp4;*.flac;*.ogg;*.au', 'All Supported Audio Files'}, 'Select noisy audio file');
            if isequal(file, 0), return; end
            app.inputFile = fullfile(path, file);
            [app.y_orig, app.fs] = audioread(app.inputFile);
            if size(app.y_orig,2) > 1
                app.y_orig = mean(app.y_orig, 2);
            end
            plot(app.InputAxes, app.y_orig);
            title(app.InputAxes, 'Input (Noisy) Waveform');
        end

        function ProcessButtonPushed(app, ~)
            if isempty(app.inputFile)
                uialert(app.UIFigure, 'Please load a file first.', 'No File');
                return;
            end
            alpha = app.AlphaField.Value;
            [app.y_clean, app.fs] = spectralSubtraction(app.inputFile, alpha);
            plot(app.OutputAxes, app.y_clean);
            title(app.OutputAxes, 'Output (Cleaned) Waveform');
        end

        function PlayOrigButtonPushed(app, ~)
            if ~isempty(app.y_orig)
                try
                    sound(app.y_orig, app.fs);
                catch
                    uialert(app.UIFigure, 'Your system does not support direct audio playback in MATLAB. Please use the "Save Output" button and listen to the file on your computer.', 'Audio Device Unavailable');
                end
            end
        end

        function PlayCleanButtonPushed(app, ~)
            if ~isempty(app.y_clean)
                try
                    sound(app.y_clean, app.fs);
                catch
                    uialert(app.UIFigure, 'Your system does not support direct audio playback in MATLAB. Please use the "Save Output" button and listen to the file on your computer.', 'Audio Device Unavailable');
                end
            end
        end

        function StopButtonPushed(app, ~)
            clear sound;
        end

        function SaveButtonPushed(app, ~)
            if isempty(app.y_clean)
                uialert(app.UIFigure, 'Nothing to save yet -- process a file first.', 'No Output');
                return;
            end
            [file, path] = uiputfile('cleaned_output.wav', 'Save cleaned audio');
            if isequal(file, 0), return; end
            audiowrite(fullfile(path, file), app.y_clean, app.fs);
        end
    end

    methods (Access = public)
        function app = noiseReductionApp
            createComponents(app);
        end
    end

    methods (Access = private)
        function createComponents(app)
            app.UIFigure = uifigure('Name', 'Noise Removal Tool', 'Position', [100 100 700 400]);

            % Input column
            app.LoadButton = uibutton(app.UIFigure, 'Text', 'Load Audio File', ...
                'Position', [40 340 150 30], 'ButtonPushedFcn', @(src,evt) LoadButtonPushed(app));
            app.InputAxes = uiaxes(app.UIFigure, 'Position', [30 150 300 150]);
            app.PlayOrigButton = uibutton(app.UIFigure, 'Text', 'Play Original', ...
                'Position', [40 100 150 30], 'ButtonPushedFcn', @(src,evt) PlayOrigButtonPushed(app));
            app.StopButton = uibutton(app.UIFigure, 'Text', 'Stop Audio', ...
                'Position', [40 60 150 30], 'FontColor', [0.8 0 0], 'FontWeight', 'bold', 'ButtonPushedFcn', @(src,evt) StopButtonPushed(app));

            % Output column
            app.OutputAxes = uiaxes(app.UIFigure, 'Position', [370 150 300 150]);
            app.PlayCleanButton = uibutton(app.UIFigure, 'Text', 'Play Cleaned', ...
                'Position', [380 100 150 30], 'ButtonPushedFcn', @(src,evt) PlayCleanButtonPushed(app));
            app.SaveButton = uibutton(app.UIFigure, 'Text', 'Save Output', ...
                'Position', [380 60 150 30], 'ButtonPushedFcn', @(src,evt) SaveButtonPushed(app));

            % Center controls
            app.AlphaLabel = uilabel(app.UIFigure, 'Text', 'Alpha (subtraction factor):', ...
                'Position', [270 340 160 22]);
            app.AlphaField = uieditfield(app.UIFigure, 'numeric', 'Value', 2, ...
                'Position', [430 340 60 22]);
            app.ProcessButton = uibutton(app.UIFigure, 'Text', 'Process', ...
                'Position', [300 290 100 35], 'FontWeight', 'bold', ...
                'ButtonPushedFcn', @(src,evt) ProcessButtonPushed(app));
        end
    end
end
