classdef CameraSync_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        AdvancedButton              matlab.ui.control.StateButton
        ScanimageButton             matlab.ui.control.StateButton
        OperationTimeListLabel      matlab.ui.control.Label
        ExportButton                matlab.ui.control.Button
        TimeList                    matlab.ui.control.ListBox
        CallSignalAcquisition       matlab.ui.control.Button
        StartButton                 matlab.ui.control.Button
        StopButton                  matlab.ui.control.Button
        VideoFileIndexSpinner       matlab.ui.control.Spinner
        VideoFileIndexSpinnerLabel  matlab.ui.control.Label
        StatusLabel                 matlab.ui.control.Label
        Lamp                        matlab.ui.control.Lamp
        CameraPreviewButton         matlab.ui.control.Button
        CameraConnectButton         matlab.ui.control.Button
        FolderSelectButton          matlab.ui.control.Button
        FilePathEditField           matlab.ui.control.EditField
        FilePathEditFieldLabel      matlab.ui.control.Label
    end

    
    properties (Access = private)
        DialogApp; % Dialog box app
        acqAbortListener;
        acqDoneListener;
        stopTriggerPressed = 0;
        timetableExported = 0;
        timeTable; % 存储所有操作的时间和衍生文件名
        timer; % 存储多对tic toc
    end
    
    properties (Access = public)
        cameraObj; % 相机
        hSI = scanimage.SI.empty; % Scanimage 工作区变量
    end
    
    methods (Access = private)

        %% UI 控制
        function disableUI(app)
            app.FilePathEditField.Editable = "off";
            app.CameraPreviewButton.Enable = "off";
            app.FolderSelectButton.Enable = "off";
            app.VideoFileIndexSpinner.Enable="off";
            app.VideoFileIndexSpinner.Editable ="off";
            app.ScanimageButton.Enable="off";
            app.StartButton.Enable = "off";
        end

        function enableUI(app)
            app.CameraPreviewButton.Enable = 'on';
            app.FolderSelectButton.Enable = "on";
            app.FilePathEditField.Enable = "on";
            app.VideoFileIndexSpinner.Enable="on";
            app.VideoFileIndexSpinner.Editable ="on";
            app.ScanimageButton.Enable="on";
            app.AdvancedButton.Enable = 'on';
            app.CameraConnectButton.Enable = "on";
        end

        function acqDoneUI(app)
            app.Lamp.Color = [0.00,1.00,0.00];
            app.StatusLabel.Text = "Ready For Grabing";
            app.StartButton.Enable = "on";
            app.StopButton.Enable = "off";
        end
        
        %% 同步控制
        function acqDoneCallback(app,~,~)
            % 用于自动采集结束的情况
            if app.hSI.acqState == "grab" && app.hSI.extTrigEnable
                % grab正常结束触发，focus结束不触发 && 只有开启external trigger才触发 &&
                % 没有主动点击stop acq才触发
                app.tableRefresh('syncstop');
                % ui update
                app.acqDoneUI();
            end

        end

        function acqAbortCallback(app,~,~)
            % 用于手动Abort的情况
            if app.hSI.acqState == "grab" && app.hSI.extTrigEnable
                % 避免grab 正常结束也触发（grab正常结束是idle，只有中途abort才是grab）  &&
                % 只有开启external trigger才触发 && 没有主动点击stop acq才触发
                app.tableRefresh('camstop');
                % ui update
                app.acqDoneUI();
            end

        end
        
        function tableRefresh(app, opt)
            % Process specific operations first
            switch opt
                case {'camstop', 'syncstop'}
                    operate = app.timeTable.optNum + 1;
                    framesAq = app.cameraObj.FramesAcquired;
                    t = toc(app.timer.start);
                    stop(app.cameraObj);
                    % Only stop marker in syncstop case
                    if strcmp(opt, 'syncstop') && isequal(app.CallSignalAcquisition.Enable, "off")
                        app.DialogApp.stopMarker();
                    end
                    close(app.cameraObj.DiskLogger);
                    
                    % Set operation name based on option
                    if strcmp(opt, 'camstop')
                        app.timeTable.list{operate,1} = '采集中途终止';
                    else % syncstop
                        app.timeTable.list{operate,1} = '同步采集停止';
                    end
                    % Update stop counter based on operation type
                    app.timeTable.stopTimes = app.timeTable.stopTimes + 1;
                    
                    % Update table and UI in one go
                    moviename = sprintf("file_%05d.mp4", app.VideoFileIndexSpinner.Value);
                    app.timeTable.list{operate,2} = moviename;
                    app.timeTable.list{operate,3} = t;
                    app.timeTable.list{operate,4} = framesAq;
                    
                    % Update list display
                    str = [app.timeTable.list{operate,1}, sprintf('%d', app.timeTable.stopTimes)];
                    app.TimeList.Items{operate} = sprintf('%s: %f', str, t);
                    
                    % Update spinners and counters - do this only once
                    app.VideoFileIndexSpinner.Value = app.VideoFileIndexSpinner.Value + 1;
                    if app.ScanimageButton.Value
                        app.hSI.hScan2D.logFileCounter = app.VideoFileIndexSpinner.Value;
                    end
                    
                case 'grabstart'
                    app.timer.start = tic;
                    if isequal(app.CallSignalAcquisition.Enable, "off")
                        app.DialogApp.startMarker();
                    end
            end
        end


    end
    
    methods (Access = public)
        
        function camInitial(app)
            videoName_part = sprintf("file_%05d.mp4",app.VideoFileIndexSpinner.Value);
            fullFileName = fullfile(app.FilePathEditField.Value,videoName_part);

            while exist(fullFileName,"file")
                app.VideoFileIndexSpinner.Value = app.VideoFileIndexSpinner.Value+1;
                videoName_part = sprintf("file_%05d.mp4",app.VideoFileIndexSpinner.Value);
                fullFileName = fullfile(app.FilePathEditField.Value,videoName_part);
            end

            if app.ScanimageButton.Value
                app.hSI.hScan2D.logFileCounter = app.VideoFileIndexSpinner.Value;
            end
            videoWriterObj = VideoWriter(fullFileName,'MPEG-4');
            app.cameraObj.DiskLogger = videoWriterObj;

            % 开启快门
            start(app.cameraObj);
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            currentPosition=app.UIFigure.Position;
            app.UIFigure.Position = [currentPosition(1), currentPosition(2), 428, currentPosition(4)];
            app.disableUI();
            %% 初始化部分统计参数
            app.timeTable.optNum = 0;
        end

        % Value changed function: ScanimageButton
        function ScanimageButtonValueChanged(app, event)
            % Scanimage 控制
            value = app.ScanimageButton.Value;
            if value
                % 获取scanimage hSI变量
                try
                    app.hSI = evalin('base', 'hSI');
                    app.VideoFileIndexSpinner.Value = app.hSI.hScan2D.logFileCounter;
                    app.acqDoneListener = addlistener(app.hSI.hUserFunctions,'acqDone', @app.acqDoneCallback);
                    app.acqAbortListener = addlistener(app.hSI.hUserFunctions, 'acqAbort', @app.acqAbortCallback); 
                    app.FilePathEditField.Value = app.hSI.hScan2D.logFilePath; 
                catch ME
                    uialert(app.UIFigure,ME.message ...
                    ,'Warning','Icon','warning');
                    return;
                end
            else
                delete(app.acqDoneListener);
                delete(app.acqAbortListener);
                app.hSI = scanimage.SI.empty;
            end
        end

        % Button pushed function: CameraConnectButton
        function CameraConnectButtonPushed(app, event)
            try
                % process bar
                progressDlg = uiprogressdlg(app.UIFigure,'Title','Connecting',...
        'Indeterminate','on');

                % connect to camera
                app.cameraObj = videoinput("winvideo","1","MJPG_1280x960", ...
                "LoggingMode","disk", ...
                "ReturnedColorSpace","grayscale", ...
                "ROIPosition",[280 0 720 720]);
                app.cameraObj.FramesPerTrigger = Inf;
                triggerconfig(app.cameraObj,"manual");

            catch ME
                uialert(app.UIFigure,ME.message ...
                    ,'Warning','Icon','warning');
                
                % close the dialog box
                close(progressDlg);
                return;
            end
            
            % close the dialog box
            close(progressDlg);

            % Enable CameraPreviewButton
            app.CameraPreviewButton.Enable = 'on';
            app.Lamp.Color = [0.00,1.00,0.00];
            app.StatusLabel.Text = "Ready for Grabing";
            app.enableUI();
            app.StartButton.Enable = "on";
            app.StopButton.Enable = "off";
        end

        % Button pushed function: FolderSelectButton
        function FolderSelectButtonPushed(app, event)
            % 选择文件夹路径
            dir_pre = app.FilePathEditField.Value;
            folder = uigetdir(dir_pre,"选择存储数据的文件夹");
            if folder == 0
                uialert(app.UIFigure,'未选择文件夹' ...
                    ,'Warning','Icon','warning');
                return;
            end

            videoName_part = sprintf("file_%05d.mp4",app.VideoFileIndexSpinner.Value);
            fullFileName = fullfile(folder,videoName_part);

            % 寻找不存在的最大编号文件编号数
            while exist(fullFileName,"file")
                app.VideoFileIndexSpinner.Value = app.VideoFileIndexSpinner.Value+1;
                videoName_part = sprintf("file_%05d.mp4",app.VideoFileIndexSpinner.Value);
                fullFileName = fullfile(folder,videoName_part);
                
            end

            app.FilePathEditField.Value = folder;

            if app.ScanimageButton.Value
                app.hSI.hScan2D.logFilePath = folder;
                app.hSI.hScan2D.logFileCounter = app.VideoFileIndexSpinner.Value;
            end
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            if ~isrunning(app.cameraObj)
                camInitial(app);
            end
            waitfor(app.cameraObj,"Running","on");
            %% 同步关键步骤2：相机连接、scanimage连接并处于grab状态，执行trigIssueSoftwareAcq()触发成像，grabstart(app)同步开启相机，并更新操作时间
            if app.hSI.acqState == "grab"
                app.hSI.hScan2D.trigIssueSoftwareAcq();
                trigger(app.cameraObj);
            else
                uialert(app.UIFigure,'Scanimage 请打开Ext Triggering，并点击Grab，Ready for Trigger' ...
                    ,'Warning','Icon','warning');
                return;
            end
            % 更新操作时间
            % 脑电采集
            app.tableRefresh('grabstart;')

            % ui update
            app.StatusLabel.Text = "Grabing";
            app.Lamp.Color = [1.00,0.00,0.00];
            app.StartButton.Enable = 'off';
            app.StopButton.Enable = 'on';
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            if app.ScanimageButton.Value && app.hSI.acqState == "grab"
                uialert(app.UIFigure,'点击Scanimage的Abort停止录制' ...
                    ,'Warning','Icon','warning');
                return;
            else
            % 中途停止录制
                camStop(app);
            end

            % ui update
            app.Lamp.Color = [0.00,1.00,0.00];
            app.StatusLabel.Text = "Ready For Grabing";
            app.StartButton.Enable = "on";
            app.StopButton.Enable = "off";
        end

        % Button pushed function: CameraPreviewButton
        function CameraPreviewButtonPushed(app, event)
            preview(app.cameraObj);
        end

        % Value changed function: AdvancedButton
        function AdvancedButtonValueChanged(app, event)
            value = app.AdvancedButton.Value;
            currentPosition=app.UIFigure.Position;
            if value
                app.UIFigure.Position = [currentPosition(1), currentPosition(2), 676, currentPosition(4)];
            else
                app.UIFigure.Position = [currentPosition(1), currentPosition(2), 428,currentPosition(4)];
            end
        end

        % Button pushed function: CallSignalAcquisition
        function CallSignalAcquisitionButtonPushed(app, event)
            % Disable Plot Options button while dialog is open
            app.CallSignalAcquisition.Enable = "off";

            % Call dialog box with input values
            app.DialogApp = SignalAcquisition(app);
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            timetable = app.timeTable.list;

            T = cell2table(timetable,"VariableNames",["Operation Type","Filename","Duration","Frames acquired"]);
            [filename, pth]= uiputfile('*.csv','Save as a csv file','timetable.csv');
            t_file = [pth, filename];

            % 分解filename
            [~,name,~] = fileparts(filename);
            mat_file = [pth, name, '.mat'];

            writetable(T,t_file,'Encoding','GB2312');
            save(mat_file,'timetable');

            % 记录路径是否保存
            app.timetableExported = 1;
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            if ~app.timetableExported && app.timeTable.grabTimes
                title = "Confirm Save";
                msg = "操作时间序列还未导出为表格,是否保存?";
                selection = uiconfirm(app.UIFigure,msg,title, ...
                    "Options",{'Save','Cancel'}, ...
                    "DefaultOption",1,"CancelOption",2);
                switch selection
                    case 'Save'
                        ExportButtonPushed(app);
                end
            end
            
            if ~isempty(app.cameraObj)
                % disconnect video
                delete(app.cameraObj);
            end

            % 删除回调函数
            delete(app.acqDoneListener);
            delete(app.acqAbortListener);
            app.hSI = scanimage.SI.empty;

            % Delete both apps
            delete(app.DialogApp);
            delete(app);
        end

        % Value changed function: VideoFileIndexSpinner
        function VideoFileIndexSpinnerValueChanged(app, event)
            value = app.VideoFileIndexSpinner.Value;
            if app.ScanimageButton.Value
                app.hSI.hScan2D.logFileCounter = value;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 676 250];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create FilePathEditFieldLabel
            app.FilePathEditFieldLabel = uilabel(app.UIFigure);
            app.FilePathEditFieldLabel.Position = [35 199 53 22];
            app.FilePathEditFieldLabel.Text = 'File Path';

            % Create FilePathEditField
            app.FilePathEditField = uieditfield(app.UIFigure, 'text');
            app.FilePathEditField.Editable = 'off';
            app.FilePathEditField.HorizontalAlignment = 'right';
            app.FilePathEditField.Position = [103 199 268 22];
            app.FilePathEditField.Value = 'D:\';

            % Create FolderSelectButton
            app.FolderSelectButton = uibutton(app.UIFigure, 'push');
            app.FolderSelectButton.ButtonPushedFcn = createCallbackFcn(app, @FolderSelectButtonPushed, true);
            app.FolderSelectButton.Position = [383 199 28 23];
            app.FolderSelectButton.Text = '...';

            % Create CameraConnectButton
            app.CameraConnectButton = uibutton(app.UIFigure, 'push');
            app.CameraConnectButton.ButtonPushedFcn = createCallbackFcn(app, @CameraConnectButtonPushed, true);
            app.CameraConnectButton.Position = [34 160 106 23];
            app.CameraConnectButton.Text = 'Camera Connect';

            % Create CameraPreviewButton
            app.CameraPreviewButton = uibutton(app.UIFigure, 'push');
            app.CameraPreviewButton.ButtonPushedFcn = createCallbackFcn(app, @CameraPreviewButtonPushed, true);
            app.CameraPreviewButton.Enable = 'off';
            app.CameraPreviewButton.Position = [271 159 101 23];
            app.CameraPreviewButton.Text = 'Camera Preview';

            % Create Lamp
            app.Lamp = uilamp(app.UIFigure);
            app.Lamp.Position = [42 83 20 20];
            app.Lamp.Color = [1 0 0];

            % Create StatusLabel
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.Position = [73 82 155 22];
            app.StatusLabel.Text = 'Waiting for ...';

            % Create VideoFileIndexSpinnerLabel
            app.VideoFileIndexSpinnerLabel = uilabel(app.UIFigure);
            app.VideoFileIndexSpinnerLabel.Position = [35 122 94 22];
            app.VideoFileIndexSpinnerLabel.Text = 'Video File Index ';

            % Create VideoFileIndexSpinner
            app.VideoFileIndexSpinner = uispinner(app.UIFigure);
            app.VideoFileIndexSpinner.ValueChangedFcn = createCallbackFcn(app, @VideoFileIndexSpinnerValueChanged, true);
            app.VideoFileIndexSpinner.Position = [273 122 102 22];
            app.VideoFileIndexSpinner.Value = 1;

            % Create StopButton
            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [0.502 0.502 0.502];
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.Enable = 'off';
            app.StopButton.Position = [329 82 43 23];
            app.StopButton.Text = 'Stop';

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Enable = 'off';
            app.StartButton.Position = [272 82 43 23];
            app.StartButton.Text = 'Start';

            % Create CallSignalAcquisition
            app.CallSignalAcquisition = uibutton(app.UIFigure, 'push');
            app.CallSignalAcquisition.ButtonPushedFcn = createCallbackFcn(app, @CallSignalAcquisitionButtonPushed, true);
            app.CallSignalAcquisition.Position = [150 38 109 23];
            app.CallSignalAcquisition.Text = 'Signal Acquisition';

            % Create TimeList
            app.TimeList = uilistbox(app.UIFigure);
            app.TimeList.Items = {};
            app.TimeList.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TimeList.Position = [433 27 224 179];
            app.TimeList.Value = {};

            % Create ExportButton
            app.ExportButton = uibutton(app.UIFigure, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.VerticalAlignment = 'top';
            app.ExportButton.FontSize = 9;
            app.ExportButton.Position = [612 209 45 18];
            app.ExportButton.Text = 'Export';

            % Create OperationTimeListLabel
            app.OperationTimeListLabel = uilabel(app.UIFigure);
            app.OperationTimeListLabel.Position = [433 204 109 23];
            app.OperationTimeListLabel.Text = 'Operation Time List';

            % Create ScanimageButton
            app.ScanimageButton = uibutton(app.UIFigure, 'state');
            app.ScanimageButton.ValueChangedFcn = createCallbackFcn(app, @ScanimageButtonValueChanged, true);
            app.ScanimageButton.Text = 'Link Scanimage';
            app.ScanimageButton.Position = [31 38 109 23];

            % Create AdvancedButton
            app.AdvancedButton = uibutton(app.UIFigure, 'state');
            app.AdvancedButton.ValueChangedFcn = createCallbackFcn(app, @AdvancedButtonValueChanged, true);
            app.AdvancedButton.Text = 'Advanced  >>';
            app.AdvancedButton.Position = [271 38 100 23];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = CameraSync_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end