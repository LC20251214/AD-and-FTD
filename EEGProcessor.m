classdef EEGProcessor < matlab.apps.AppBase
    
    
    properties (Access = public)
        
        UIFigure            matlab.ui.Figure
        
        
        LeftPanel           matlab.ui.container.Panel
        ControlGrid         matlab.ui.container.GridLayout
        FilePanel           matlab.ui.container.Panel
        ProcessPanel        matlab.ui.container.Panel
        FeaturePanel        matlab.ui.container.Panel
        ResultPanel         matlab.ui.container.Panel
        
       
        RightPanel          matlab.ui.container.Panel
        DisplayGrid         matlab.ui.container.GridLayout
        
        
        LoadButton          matlab.ui.control.Button
        SegmentButton       matlab.ui.control.Button
        AnalyzeButton       matlab.ui.control.Button
        ExtractButton       matlab.ui.control.Button
        DetectButton        matlab.ui.control.Button  
        LoadModelButton     matlab.ui.control.Button  
        
       
        FsEditField         matlab.ui.control.NumericEditField
        SegmentTimeEdit     matlab.ui.control.NumericEditField
        WaveletDropDown     matlab.ui.control.DropDown
        LevelDropDown       matlab.ui.control.DropDown
        
       
        FileInfoText        matlab.ui.control.Label
        ModelInfoText       matlab.ui.control.Label  
        ResultText          matlab.ui.control.Label  
        ResultLegend        matlab.ui.control.Label  
        
        
        OriginalAxes        matlab.ui.control.UIAxes
        SegmentedAxes       matlab.ui.control.UIAxes
        RhythmAxes1         matlab.ui.control.UIAxes  % Delta
        RhythmAxes2         matlab.ui.control.UIAxes  % Theta
        RhythmAxes3         matlab.ui.control.UIAxes  % Alpha
        RhythmAxes4         matlab.ui.control.UIAxes  % Beta
        RhythmAxes5         matlab.ui.control.UIAxes  % Gamma
        
        
        FeatureTable        matlab.ui.control.Table
        
        % 数据
        OriginalData        double
        TimeVector          double
        Fs                  double = 256
        SegmentedData       double
        SegmentedTime       double
        WaveletCoeffs       cell
        RhythmNames         cell
        Features            table
        
        % 模型
        TrainedModel        struct  
        IsModelLoaded       logical = false  
    end
    
    methods (Access = private)
        
        function createComponents(app)
            % 创建主窗口
            app.UIFigure = uifigure('Position', [50 50 1400 800], ...
                'Name', '脑电信号分析系统 | EEG Signal Analysis System', ...
                'Resize', 'on');
            
         
            mainGrid = uigridlayout(app.UIFigure, [1 2]);
            mainGrid.ColumnWidth = {'0.3x', '0.7x'};
            mainGrid.RowHeight = {'1x'};
            mainGrid.BackgroundColor = [0.96 0.96 0.96];
            
            %% 左侧控制面板
            app.LeftPanel = uipanel(mainGrid);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.BackgroundColor = [0.98 0.98 0.98];
            app.LeftPanel.BorderType = 'none';
            
            
            app.ControlGrid = uigridlayout(app.LeftPanel, [5 1]);  
            app.ControlGrid.RowHeight = {140, 220, '1x', 100, 90};  
            app.ControlGrid.ColumnWidth = {'1x'};
            app.ControlGrid.RowSpacing = 10;
            app.ControlGrid.Padding = [15 15 15 15];
            
            
            app.FilePanel = uipanel(app.ControlGrid, ...
                'Title', '📁 文件操作 | File Operation', ...
                'FontWeight', 'bold', ...
                'FontSize', 12);
            app.FilePanel.Layout.Row = 1;
            
            fileGrid = uigridlayout(app.FilePanel, [5 1]);  % 改为5行
            fileGrid.RowHeight = {35, 35, 30, 30, 30};
            fileGrid.ColumnWidth = {'1x'};
            fileGrid.RowSpacing = 8;
            fileGrid.Padding = [10 10 10 10];
            
            app.LoadButton = uibutton(fileGrid, 'push', ...
                'Text', '加载CSV文件 | Load CSV File', ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.3 0.6 0.9], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', createCallbackFcn(app, @loadCSVFile, true));
            app.LoadButton.Layout.Row = 1;
            
            app.LoadModelButton = uibutton(fileGrid, 'push', ...  
                'Text', '加载模型文件 | Load Model', ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.6 0.3 0.8], ...
                'FontColor', 'white', ...
                'ButtonPushedFcn', createCallbackFcn(app, @loadModelFile, true));
            app.LoadModelButton.Layout.Row = 2;
            
            app.FileInfoText = uilabel(fileGrid, ...
                'Text', '等待加载文件... | Waiting for file...', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'center', ...
                'WordWrap', 'on');
            app.FileInfoText.Layout.Row = 3;
            
            app.ModelInfoText = uilabel(fileGrid, ...  
                'Text', '未加载模型 | No model loaded', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'center', ...
                'WordWrap', 'on', ...
                'FontColor', [0.8 0.2 0.2]);
            app.ModelInfoText.Layout.Row = 4;
            
            fsGrid = uigridlayout(fileGrid, [1 2]);
            fsGrid.Layout.Row = 5;
            fsGrid.ColumnWidth = {'1x', '1x'};
            
            fsLabel = uilabel(fsGrid, ...
                'Text', '采样率 | Sampling Rate:', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'center');
            fsLabel.Layout.Row = 1;
            fsLabel.Layout.Column = 1;
            
            app.FsEditField = uieditfield(fsGrid, 'numeric', ...
                'Value', 256, ...
                'Limits', [1 10000], ...
                'ValueDisplayFormat', '%.0f Hz', ...
                'FontSize', 11);
            app.FsEditField.Layout.Row = 1;
            app.FsEditField.Layout.Column = 2;
            
            % 处理参数面板 
            app.ProcessPanel = uipanel(app.ControlGrid, ...
                'Title', '⚙️ 处理参数 | Processing Parameters', ...
                'FontWeight', 'bold', ...
                'FontSize', 12);
            app.ProcessPanel.Layout.Row = 2;
            
            processGrid = uigridlayout(app.ProcessPanel, [7 2]);  
            processGrid.RowHeight = {30, 30, 30, 35, 35, 35, 40}; 
            processGrid.ColumnWidth = {'1x', '1x'};
            processGrid.RowSpacing = 6;                          
            processGrid.ColumnSpacing = 8;
            processGrid.Padding = [10 8 10 8];                   
            
            % 截取时间设置
            segTimeLabel = uilabel(processGrid, ...
                'Text', '预处理 | Preprocessed:', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'left');
            segTimeLabel.Layout.Row = 1;
            segTimeLabel.Layout.Column = 1;
            
            app.SegmentTimeEdit = uieditfield(processGrid, 'numeric', ...
                'Value', 30, ...
                'Limits', [1 300], ...
                'ValueDisplayFormat', '%.0f s', ...
                'FontSize', 11);
            app.SegmentTimeEdit.Layout.Row = 1;
            app.SegmentTimeEdit.Layout.Column = 2;
            
            % 小波类型选择
            waveletLabel = uilabel(processGrid, ...
                'Text', '小波类型 | Wavelet Type:', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'left');
            waveletLabel.Layout.Row = 2;
            waveletLabel.Layout.Column = 1;
            
            app.WaveletDropDown = uidropdown(processGrid, ...
                'Items', {'db4', 'db8', 'sym4', 'coif4', 'bior3.5'}, ...
                'Value', 'db4', ...
                'FontSize', 11);
            app.WaveletDropDown.Layout.Row = 2;
            app.WaveletDropDown.Layout.Column = 2;
            
            % 分解层数选择
            levelLabel = uilabel(processGrid, ...
                'Text', '分解层数 | Decomposition Level:', ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'left');
            levelLabel.Layout.Row = 3;
            levelLabel.Layout.Column = 1;
            
            app.LevelDropDown = uidropdown(processGrid, ...
                'Items', {'3', '4', '5', '6', '7'}, ...
                'Value', '5', ...
                'FontSize', 11);
            app.LevelDropDown.Layout.Row = 3;
            app.LevelDropDown.Layout.Column = 2;
            
            % 处理按钮 
            app.SegmentButton = uibutton(processGrid, 'push', ...
                'Text', '✂️ 预处理 | Preprocessed', ...
                'FontSize', 10.5, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.2 0.7 0.4], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', createCallbackFcn(app, @segmentSignal, true));
            app.SegmentButton.Layout.Row = 4;
            app.SegmentButton.Layout.Column = 1;
            
            app.AnalyzeButton = uibutton(processGrid, 'push', ...
                'Text', '🌀 DWT分解 | DWT Decomposition', ...
                'FontSize', 10.5, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.4 0.4 0.8], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', createCallbackFcn(app, @analyzeRhythms, true));
            app.AnalyzeButton.Layout.Row = 4;
            app.AnalyzeButton.Layout.Column = 2;
            
            % 特征提取按钮 
            app.ExtractButton = uibutton(processGrid, 'push', ...
                'Text', '📊 特征提取 | Feature Extraction', ...
                'FontSize', 10.5, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.8 0.5 0.2], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...
                'ButtonPushedFcn', createCallbackFcn(app, @extractFeatures, true));
            app.ExtractButton.Layout.Row = 5;     
            app.ExtractButton.Layout.Column = 1;   
            
            % 检测按钮
            app.DetectButton = uibutton(processGrid, 'push', ...
                'Text', '🔍 检测 | Detect', ...
                'FontSize', 10.5, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.9 0.2 0.2], ...
                'FontColor', 'white', ...
                'Enable', 'off', ...  
                'ButtonPushedFcn', createCallbackFcn(app, @detectDisease, true));
            app.DetectButton.Layout.Row = 5;      
            app.DetectButton.Layout.Column = 2;   
            
            % 特征显示面板
            app.FeaturePanel = uipanel(app.ControlGrid, ...
                'Title', '📋 特征结果 | Feature Results', ...
                'FontWeight', 'bold', ...
                'FontSize', 12);
            app.FeaturePanel.Layout.Row = 3;
            
            featureGrid = uigridlayout(app.FeaturePanel, [1 1]);
            featureGrid.RowHeight = {'1x'};
            featureGrid.ColumnWidth = {'1x'};
            featureGrid.Padding = [10 10 10 10];
            
            app.FeatureTable = uitable(featureGrid);
            app.FeatureTable.Layout.Row = 1;
            app.FeatureTable.Layout.Column = 1;
            app.FeatureTable.FontSize = 11;
            app.FeatureTable.ColumnName = {'节律 | Rhythm', '排列组合熵 | PE', '奇异谱熵 | SSE', '样本熵 | SE'};
            app.FeatureTable.ColumnWidth = {150, 80, 80, 80};
            
            %% 检测结果面板 - 新增
            app.ResultPanel = uipanel(app.ControlGrid, ...
                'Title', '🔬 检测结果 | Detection Result', ...
                'FontWeight', 'bold', ...
                'FontSize', 12);
            app.ResultPanel.Layout.Row = 4;
            
            resultGrid = uigridlayout(app.ResultPanel, [3 1]);
            resultGrid.RowHeight = {35, 35, 30};
            resultGrid.ColumnWidth = {'1x'};
            resultGrid.RowSpacing = 5;
            resultGrid.Padding = [10 5 10 5];
            
            resultTitle = uilabel(resultGrid, ...
                'Text', '疾病检测结果 | Disease Detection Result', ...
                'FontSize', 11, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
            resultTitle.Layout.Row = 1;
            
            app.ResultText = uilabel(resultGrid, ...
                'Text', '等待检测... | Waiting for detection...', ...
                'FontSize', 14, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', ...
                'FontColor', [0.5 0.5 0.5]);
            app.ResultText.Layout.Row = 2;
            
            app.ResultLegend = uilabel(resultGrid, ...
                'Text', '1:阿尔茨海默症AD | 2:健康Healthy Control | 3:额颞叶痴呆FTD', ...
                'FontSize', 9, ...
                'FontColor', [0.4 0.4 0.4], ...
                'HorizontalAlignment', 'center', ...
                'WordWrap', 'on');
            app.ResultLegend.Layout.Row = 3;
            
            %% 信息面板
            infoPanel = uipanel(app.ControlGrid, ...
                'Title', '💡 使用说明 | Instructions', ...
                'FontWeight', 'bold', ...
                'FontSize', 12);
            infoPanel.Layout.Row = 5;
            
            infoGrid = uigridlayout(infoPanel, [2 1]);
            infoGrid.RowHeight = {'1x', '1x'};
            infoGrid.ColumnWidth = {'1x'};
            infoGrid.RowSpacing = 2;
            infoGrid.Padding = [5 5 5 5];
            
            infoText1 = uilabel(infoGrid, ...
                'Text', '步骤: 1.加载数据 2.加载模型 3.提取特征 4.检测', ...
                'FontSize', 12, ...
                'FontColor', [0.3 0.3 0.3], ...
                'HorizontalAlignment', 'left', ...
                'WordWrap', 'on');
            infoText1.Layout.Row = 1;
            
            infoText2 = uilabel(infoGrid, ...
                'Text', 'Steps: 1. Load Data 2. Load Model 3. Extract Features 4. Detect', ...
                'FontSize', 12, ...
                'FontColor', [0.3 0.3 0.3], ...
                'HorizontalAlignment', 'left', ...
                'WordWrap', 'on');
            infoText2.Layout.Row = 2;
            
            %% 右侧显示面板
            app.RightPanel = uipanel(mainGrid);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            app.RightPanel.BackgroundColor = 'white';
            app.RightPanel.BorderType = 'none';
            
            app.DisplayGrid = uigridlayout(app.RightPanel, [2 1]);
            app.DisplayGrid.RowHeight = {'2x', '1x'};  % 上2/3，下1/3
            app.DisplayGrid.ColumnWidth = {'1x'};
            app.DisplayGrid.RowSpacing = 10;
            app.DisplayGrid.Padding = [15 15 15 15];
                        
            topGrid = uigridlayout(app.DisplayGrid, [1 2]);
            topGrid.Layout.Row = 1;
            topGrid.RowHeight = {'1x'};
            topGrid.ColumnWidth = {'1x', '1x'};
            topGrid.ColumnSpacing = 10;
            
            % 原始信号坐标轴
            app.OriginalAxes = uiaxes(topGrid);
            app.OriginalAxes.Layout.Row = 1;
            app.OriginalAxes.Layout.Column = 1;
            app.OriginalAxes.XGrid = 'on';
            app.OriginalAxes.YGrid = 'on';
            app.OriginalAxes.Box = 'on';
            app.OriginalAxes.FontSize = 10;
            title(app.OriginalAxes, '原始脑电信号 | Original EEG Signal');
            xlabel(app.OriginalAxes, '时间 (秒) | Time (s)');
            ylabel(app.OriginalAxes, '幅度 (μV) | Amplitude (μV)');
            
            % 截取信号坐标轴
            app.SegmentedAxes = uiaxes(topGrid);
            app.SegmentedAxes.Layout.Row = 1;
            app.SegmentedAxes.Layout.Column = 2;
            app.SegmentedAxes.XGrid = 'on';
            app.SegmentedAxes.YGrid = 'on';
            app.SegmentedAxes.Box = 'on';
            app.SegmentedAxes.FontSize = 10;
            title(app.SegmentedAxes, '预处理脑电信号 | Preprocessed EEG Signal');
            xlabel(app.SegmentedAxes, '时间 (秒) | Time (s)');
            ylabel(app.SegmentedAxes, '幅度 (μV) | Amplitude (μV)');
                       
            bottomGrid = uigridlayout(app.DisplayGrid, [1 5]);
            bottomGrid.Layout.Row = 2;
            bottomGrid.RowHeight = {'1x'};
            bottomGrid.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            bottomGrid.ColumnSpacing = 10;
            
            % Delta节律
            app.RhythmAxes1 = uiaxes(bottomGrid);
            app.RhythmAxes1.Layout.Row = 1;
            app.RhythmAxes1.Layout.Column = 1;
            app.RhythmAxes1.XGrid = 'on';
            app.RhythmAxes1.YGrid = 'on';
            app.RhythmAxes1.Box = 'on';
            app.RhythmAxes1.FontSize = 9;
            title(app.RhythmAxes1, 'Delta (0.5-4 Hz) δ波 | Delta Rhythm');
            xlabel(app.RhythmAxes1, '时间 (秒) | Time (s)');
            ylabel(app.RhythmAxes1, '幅度 | Amplitude');
            
            % Theta节律
            app.RhythmAxes2 = uiaxes(bottomGrid);
            app.RhythmAxes2.Layout.Row = 1;
            app.RhythmAxes2.Layout.Column = 2;
            app.RhythmAxes2.XGrid = 'on';
            app.RhythmAxes2.YGrid = 'on';
            app.RhythmAxes2.Box = 'on';
            app.RhythmAxes2.FontSize = 9;
            title(app.RhythmAxes2, 'Theta (4-8 Hz) θ波 | Theta Rhythm');
            xlabel(app.RhythmAxes2, '时间 (秒) | Time (s)');
            ylabel(app.RhythmAxes2, '幅度 | Amplitude');
            
            % Alpha节律
            app.RhythmAxes3 = uiaxes(bottomGrid);
            app.RhythmAxes3.Layout.Row = 1;
            app.RhythmAxes3.Layout.Column = 3;
            app.RhythmAxes3.XGrid = 'on';
            app.RhythmAxes3.YGrid = 'on';
            app.RhythmAxes3.Box = 'on';
            app.RhythmAxes3.FontSize = 9;
            title(app.RhythmAxes3, 'Alpha (8-13 Hz) α波 | Alpha Rhythm');
            xlabel(app.RhythmAxes3, '时间 (秒) | Time (s)');
            ylabel(app.RhythmAxes3, '幅度 | Amplitude');
            
            % Beta节律
            app.RhythmAxes4 = uiaxes(bottomGrid);
            app.RhythmAxes4.Layout.Row = 1;
            app.RhythmAxes4.Layout.Column = 4;
            app.RhythmAxes4.XGrid = 'on';
            app.RhythmAxes4.YGrid = 'on';
            app.RhythmAxes4.Box = 'on';
            app.RhythmAxes4.FontSize = 9;
            title(app.RhythmAxes4, 'Beta (13-30 Hz) β波 | Beta Rhythm');
            xlabel(app.RhythmAxes4, '时间 (秒) | Time (s)');
            ylabel(app.RhythmAxes4, '幅度 | Amplitude');
            
            % Gamma节律
            app.RhythmAxes5 = uiaxes(bottomGrid);
            app.RhythmAxes5.Layout.Row = 1;
            app.RhythmAxes5.Layout.Column = 5;
            app.RhythmAxes5.XGrid = 'on';
            app.RhythmAxes5.YGrid = 'on';
            app.RhythmAxes5.Box = 'on';
            app.RhythmAxes5.FontSize = 9;
            title(app.RhythmAxes5, 'Gamma (>30 Hz) γ波 | Gamma Rhythm');
            xlabel(app.RhythmAxes5, '时间 (秒) | Time (s)');
            ylabel(app.RhythmAxes5, '幅度 | Amplitude');
        end
        
      
        function loadCSVFile(app, ~)
            [file, path] = uigetfile({'*.csv', 'CSV Files (*.csv)'}, ...
                '选择脑电信号CSV文件 | Select EEG CSV File');
            
            if isequal(file, 0)
                return;
            end
            
            try
                fullpath = fullfile(path, file);
                
                data = readmatrix(fullpath);
                
                if size(data, 2) < 1
                    error('CSV文件需要至少包含一列数据 | CSV file needs at least one column of data');
                end
                
                app.Fs = app.FsEditField.Value;
                
                if size(data, 2) >= 2
                    app.TimeVector = data(:, 1);
                    app.OriginalData = data(:, 2);
                    if length(app.TimeVector) > 1
                        dt = mean(diff(app.TimeVector));
                        if dt > 0
                            app.Fs = 1/dt;
                            app.FsEditField.Value = app.Fs;
                        end
                    end
                else
                    app.OriginalData = data(:, 1);
                    app.TimeVector = (0:length(app.OriginalData)-1)' / app.Fs;
                end
                
                app.FileInfoText.Text = sprintf('文件 | File: %s\n点数 | Points: %d\n时长 | Duration: %.1fs\n采样率 | Sampling Rate: %.1f Hz', ...
                    file, length(app.OriginalData), app.TimeVector(end), app.Fs);
                
                cla(app.OriginalAxes);
                plot(app.OriginalAxes, app.TimeVector, app.OriginalData, 'b-', 'LineWidth', 0.5);
                title(app.OriginalAxes, sprintf('原始脑电信号 | Original EEG Signal (Fs = %.0f Hz)', app.Fs));
                xlabel(app.OriginalAxes, '时间 (秒) | Time (s)');
                ylabel(app.OriginalAxes, '幅度 (μV) | Amplitude (μV)');
                grid(app.OriginalAxes, 'on');
                
                app.SegmentButton.Enable = 'on';
                
                % 重置检测结果
                app.ResultText.Text = '等待检测... | Waiting for detection...';
                app.ResultText.FontColor = [0.5 0.5 0.5];
                
            catch ME
                errordlg(sprintf('读取文件失败 | Failed to read file: %s', ME.message), ...
                    '文件错误 | File Error');
            end
        end
        
        % 加载模型文件 
        function loadModelFile(app, ~)
            [file, path] = uigetfile({'*.mat', 'MAT Files (*.mat)'}, ...
                '选择训练好的SCC模型文件 | Select Trained SCC Model File');
            
            if isequal(file, 0)
                return;
            end
            
            try
                fullpath = fullfile(path, file);
                
                % 加载MAT文件
                fprintf('\n=== 加载模型文件: %s ===\n', file);
                loadedData = load(fullpath);
                
                % 检查加载的数据结构
                fprintf('加载的变量: %s\n', strjoin(fieldnames(loadedData), ', '));
                
               
                if isfield(loadedData, 'model')
                    app.TrainedModel = loadedData.model;
                    modelType = 'SCC相似度模型';
                    modelSource = 'model字段';
               
                elseif isfield(loadedData, 'TrainedModel')
                    app.TrainedModel = loadedData.TrainedModel;
                    modelType = 'SCC相似度模型';
                    modelSource = 'TrainedModel字段';
                else
                  
                    fieldNames = fieldnames(loadedData);
                    for i = 1:length(fieldNames)
                        fieldName = fieldNames{i};
                        
                        if ~strcmp(fieldName, '__header__') && ~strcmp(fieldName, '__version__') && ...
                           ~strcmp(fieldName, '__globals__')
                            app.TrainedModel = loadedData.(fieldName);
                            modelType = 'SCC相似度模型';
                            modelSource = sprintf('%s字段', fieldName);
                            break;
                        end
                    end
                end
                
                % 验证模型结构
                fprintf('验证模型结构...\n');
                
                % 检查必需字段
                requiredFields = {'templates', 'classLabels'};
                for i = 1:length(requiredFields)
                    if ~isfield(app.TrainedModel, requiredFields{i})
                        error('模型缺少必需字段: %s', requiredFields{i});
                    end
                end
                
                % 检查模板维度
                [numTemplates, templateDim] = size(app.TrainedModel.templates);
                numClasses = length(app.TrainedModel.classLabels);
                
                if numTemplates ~= numClasses
                    error('模板数量(%d)与类别标签数量(%d)不匹配', numTemplates, numClasses);
                end
                
                if templateDim ~= 3
                    error('模板维度应为1×3，但实际为1×%d', templateDim);
                end
                
             
                for i = 1:numTemplates
                    fprintf('类别 %d (标签 %d): [%.6f, %.6f, %.6f]\n', ...
                        i, app.TrainedModel.classLabels(i), ...
                        app.TrainedModel.templates(i, 1), ...
                        app.TrainedModel.templates(i, 2), ...
                        app.TrainedModel.templates(i, 3));
                end
                fprintf('========================\n');
                
                % 更新界面显示
                app.IsModelLoaded = true;
                
                if isfield(app.TrainedModel, 'accuracy')
                    accuracyStr = sprintf('准确率: %.1f%%', app.TrainedModel.accuracy * 100);
                else
                    accuracyStr = '准确率: 未知';
                end
                
                app.ModelInfoText.Text = sprintf('✓ SCC模型已加载\n%s\n%d个类别 | 3维特征', ...
                    file, numTemplates);
                app.ModelInfoText.FontColor = [0.2 0.6 0.2];
                
                % 如果特征已提取，启用检测按钮
                if ~isempty(app.Features)
                    app.DetectButton.Enable = 'on';
                end
                
                % 显示加载成功消息
                msg = sprintf('SCC模型加载成功！\n文件: %s\n类型: %s\n模板数量: %d\n特征维度: 1×3\n%s', ...
                    file, modelType, numTemplates, accuracyStr);
                uialert(app.UIFigure, msg, '模型加载成功 | Model Loaded', ...
                    'Icon', 'success', 'Modal', false);
                
            catch ME
                app.IsModelLoaded = false;
                app.ModelInfoText.Text = '✗ 模型加载失败';
                app.ModelInfoText.FontColor = [0.8 0.2 0.2];
                errordlg(sprintf('加载模型失败: %s', ME.message), ...
                    '模型错误 | Model Error');
            end
        end
        

        function segmentSignal(app, ~)
            try
                segmentTime = app.SegmentTimeEdit.Value;
                idx = find(app.TimeVector <= segmentTime, 1, 'last');
                
                if isempty(idx)
                    error('数据长度不足%.0f秒 | Data length is less than %.0f seconds', segmentTime, segmentTime);
                end
                
                app.SegmentedTime = app.TimeVector(1:idx);
                app.SegmentedData = app.OriginalData(1:idx);
                
                cla(app.SegmentedAxes);
                plot(app.SegmentedAxes, app.SegmentedTime, app.SegmentedData, 'r-', 'LineWidth', 0.5);
                title(app.SegmentedAxes, sprintf('预处理脑电信号 | Preprocessed EEG Signal'));
                xlabel(app.SegmentedAxes, '时间 (秒) | Time (s)');
                ylabel(app.SegmentedAxes, '幅度 (μV) | Amplitude (μV)');
                grid(app.SegmentedAxes, 'on');
                
                app.AnalyzeButton.Enable = 'on';
                
            catch ME
                errordlg(ME.message, '截取错误 | Segmentation Error');
            end
        end
        
        % DWT分解
        function analyzeRhythms(app, ~)
            try
                wavelet = app.WaveletDropDown.Value;
                level = str2double(app.LevelDropDown.Value);
                
                if level < 5
                    error('分解层数至少为5才能得到5个节律 | Decomposition level must be at least 5 to get 5 rhythms');
                end
                
                [C, L] = wavedec(app.SegmentedData, level, wavelet);
                
                app.WaveletCoeffs = cell(5, 1);
                app.RhythmNames = {'Delta (0.5-4 Hz) δ波 | Delta Rhythm', ...
                                  'Theta (4-8 Hz) θ波 | Theta Rhythm', ...
                                  'Alpha (8-13 Hz) α波 | Alpha Rhythm', ...
                                  'Beta (13-30 Hz) β波 | Beta Rhythm', ...
                                  'Gamma (>30 Hz) γ波 | Gamma Rhythm'};
                
                % 提取5个节律
                rhythmAxes = {app.RhythmAxes1, app.RhythmAxes2, app.RhythmAxes3, ...
                             app.RhythmAxes4, app.RhythmAxes5};
                
                for i = 1:5
                    rhythmSignal = wrcoef('d', C, L, wavelet, i);
                    app.WaveletCoeffs{i} = rhythmSignal;
                    
                    ax = rhythmAxes{i};
                    cla(ax);
                    plot(ax, app.SegmentedTime, rhythmSignal, 'Color', [0.2 0.4 0.8], 'LineWidth', 0.5);
                    title(ax, app.RhythmNames{i});
                    xlabel(ax, '时间 (秒) | Time (s)');
                    ylabel(ax, '幅度 | Amplitude');
                    grid(ax, 'on');
                end
                
                app.ExtractButton.Enable = 'on';
                
            catch ME
                errordlg(ME.message, 'DWT分解错误 | DWT Decomposition Error');
            end
        end
        
        % 特征提取
        function extractFeatures(app, ~)
            try
                if isempty(app.WaveletCoeffs)
                    error('请先进行DWT分解 | Please perform DWT decomposition first');
                end
                
                features = zeros(5, 3);  % 5个节律，3个特征
                
                for i = 1:5
                    signal = app.WaveletCoeffs{i};
                    
                    % 1. 排列组合熵 PE
                    m = 3; tau = 1;
                    N = length(signal);
                    if N >= 10
                        patterns = zeros(1, factorial(m));
                        for k = 1:N-m*tau
                            segment = signal(k:tau:k+m*tau-1);
                            [~, idx] = sort(segment);
                            pattern = idx;
                            pattern_index = 0;
                            for j = 1:m
                                pattern_index = pattern_index + (pattern(j)-1) * factorial(m-j);
                            end
                            patterns(pattern_index+1) = patterns(pattern_index+1) + 1;
                        end
                        patterns = patterns(patterns > 0);
                        p = patterns / sum(patterns);
                        if any(p == 0)
                            features(i, 1) = 0;
                        else
                            features(i, 1) = -sum(p .* log(p)) / log(factorial(m));
                        end
                    else
                        features(i, 1) = 0;
                    end
                    
                    % 2. 奇异谱熵 SSE
                    L = min(50, floor(N/3));
                    if L >= 2
                        K = N - L + 1;
                        X = zeros(L, K);
                        for k = 1:K
                            X(:, k) = signal(k:k+L-1);
                        end
                        [~, S, ~] = svd(X, 'econ');
                        sv = diag(S);
                        sv = sv(sv > eps);
                        p = sv / sum(sv);
                        if any(p == 0)
                            features(i, 2) = 0;
                        else
                            features(i, 2) = -sum(p .* log(p));
                        end
                    else
                        features(i, 2) = 0;
                    end
                    
                    % 3. 样本熵 SE
                    m_se = 2; r = 0.2;
                    if N > m_se+1
                        signal_norm = (signal - mean(signal)) / std(signal);
                        r_val = r * std(signal_norm);
                        count_m = 0;
                        count_mp1 = 0;
                        for k = 1:N-m_se
                            for j = k+1:N-m_se
                                if max(abs(signal_norm(k:k+m_se-1) - signal_norm(j:j+m_se-1))) <= r_val
                                    count_m = count_m + 1;
                                    if j <= N-m_se-1 && max(abs(signal_norm(k:k+m_se) - signal_norm(j:j+m_se))) <= r_val
                                        count_mp1 = count_mp1 + 1;
                                    end
                                end
                            end
                        end
                        if count_m > 0 && count_mp1 > 0
                            features(i, 3) = -log(count_mp1 / count_m);
                        else
                            features(i, 3) = 0;
                        end
                    else
                        features(i, 3) = 0;
                    end
                end
                
                rhythmNames = app.RhythmNames';
                app.Features = table(rhythmNames, features(:,1), features(:,2), features(:,3), ...
                    'VariableNames', {'Rhythm', 'PE', 'SSE', 'SE'});
                
                % 更新左侧特征表格
                app.FeatureTable.Data = app.Features;
                
                % 输出Beta节律特征
                betaFeatures = features(4, :);
                fprintf('\n=== 特征提取完成 ===\n');
                fprintf('Beta节律特征 (1×3):\n');
                fprintf('排列组合熵(PE):  %.6f\n', betaFeatures(1));
                fprintf('奇异谱熵(SSE):   %.6f\n', betaFeatures(2));
                fprintf('样本熵(SE):      %.6f\n', betaFeatures(3));
                fprintf('========================\n');
                
                % 启用检测按钮
                if app.IsModelLoaded
                    app.DetectButton.Enable = 'on';
                    app.ResultText.Text = '已准备检测 | Ready for detection';
                    app.ResultText.FontColor = [0.2 0.6 0.2];
                else
                    app.DetectButton.Enable = 'off';
                    app.ResultText.Text = '请先加载模型 | Please load model first';
                    app.ResultText.FontColor = [0.8 0.2 0.2];
                end
                
            catch ME
                errordlg(ME.message, '特征提取错误 | Feature Extraction Error');
            end
        end
        
       % 疾病检测 - 使用SCC相似度模型
function detectDisease(app, ~)
    try
        if ~app.IsModelLoaded
            error('请先加载SCC模型文件 | Please load SCC model file first');
        end
        
        if isempty(app.Features)
            error('请先提取特征 | Please extract features first');
        end
        
        % 获取Beta节律的特征向量（第4个节律）
        betaFeatures = table2array(app.Features(4, 2:4));  % 1×3特征矩阵
        
        fprintf('\n=== SCC模型检测开始 ===\n');
        fprintf('输入特征矩阵 (Beta节律 1×3):\n');
        fprintf('排列组合熵(PE):   %.6f\n', betaFeatures(1));
        fprintf('奇异谱熵(SSE):    %.6f\n', betaFeatures(2));
        fprintf('样本熵(SE):       %.6f\n', betaFeatures(3));
        
         % 获取模型
                model = app.TrainedModel;
                
                % 验证模型结构
                if ~isfield(model, 'templates') || ~isfield(model, 'classLabels')
                    error('SCC模型缺少必要字段: templates 或 classLabels');
                end
                
                % 确保输入特征维度正确
                if length(betaFeatures) ~= 3
                    error('特征向量必须是1×3向量 | Feature vector must be 1×3');
                end
                
                % 获取模型参数
                templates = model.templates;
                classLabels = model.classLabels;
                numClasses = length(classLabels);
                
                % 检查模板维度
                [numTemplates, templateDim] = size(templates);
                if numTemplates ~= numClasses
                    error('模板数量(%d)与类别数量(%d)不匹配', numTemplates, numClasses);
                end
                if templateDim ~= 3
                    error('模板维度应为1×3，但实际为1×%d', templateDim);
                end
                
                % 计算与每个模板的SCC相似度
                similarityScores = zeros(1, numClasses);
                
                fprintf('\n相似度计算:\n');
                for cls = 1:numClasses
                    template = templates(cls, :);
                    
                    % SCC相似度计算：相关系数的绝对值
                    % 将向量转换为列向量以计算相关系数
                    vec1 = betaFeatures(:);
                    vec2 = template(:);
                    
                    % 计算相关系数
                    corrMatrix = corrcoef(vec1, vec2);
                    if size(corrMatrix, 1) == 2 && ~isnan(corrMatrix(1,2))
                        similarity = abs(corrMatrix(1,2));
                    else
                        similarity = 0;
                    end
                    
                    similarityScores(cls) = similarity;
                    
                    fprintf('类别 %d (标签 %d): 相似度 = %.6f\n', ...
                        cls, classLabels(cls), similarity);
                    
                    % 显示模板值
                    fprintf('  模板: [%.6f, %.6f, %.6f]\n', ...
                        template(1), template(2), template(3));
                end
                
                % 找到最高相似度的类别
                [maxScore, predictedClass] = max(similarityScores);
                predictedLabel = classLabels(predictedClass);
                
                % 如果最高相似度过低，添加阈值判断
                similarityThreshold = 0.1;  % 可根据需要调整
                if maxScore < similarityThreshold
                    warningMsg = sprintf('警告: 最高相似度(%.4f)低于阈值(%.2f)，结果可能不可靠', ...
                        maxScore, similarityThreshold);
                    fprintf('⚠ %s\n', warningMsg);
                    
                    % 显示警告对话框（可选）
                    uialert(app.UIFigure, warningMsg, '检测警告 | Detection Warning', ...
                        'Icon', 'warning', 'Modal', false);
                end
                
                           
                fprintf('\n预测结果: 类别 %d, 标签 %d\n', predictedClass, predictedLabel);
                fprintf('检测结束 ===\n\n');
                
                % 更新界面显示
                updateResultDisplay(app, predictedLabel, betaFeatures, similarityScores);
                
            catch ME
                errordlg(sprintf('检测失败 | Detection failed: %s', ME.message), ...
                    '检测错误 | Detection Error');
            end
        end
        % 更新结果显示
        function updateResultDisplay(app, result, betaFeatures, similarityScores)
            % 根据结果获取疾病信息
            [diseaseName, color, description, advice] = getDiseaseInfo(app, result);
            
            % 计算置信度
            if ~isempty(similarityScores)
                maxScore = max(similarityScores);
                if maxScore > 0.7
                    confidenceLevel = '高';
                    confidenceColor = [0.2 0.7 0.2];
                elseif maxScore > 0.4
                    confidenceLevel = '中';
                    confidenceColor = [0.9 0.6 0.1];
                else
                    confidenceLevel = '低';
                    confidenceColor = [0.8 0.2 0.2];
                end
            else
                confidenceLevel = '未知';
                confidenceColor = [0.5 0.5 0.5];
                maxScore = 0;
            end
            
            % 更新结果文本
            resultText = sprintf('检测结果: %d\n%s\n置信度: %s (%.2f)', ...
                result, diseaseName, confidenceLevel, maxScore);
            app.ResultText.Text = resultText;
            app.ResultText.FontColor = color;
            
            % 构建详细结果信息
            detailInfo = sprintf('SCC模型检测结果\n\n预测标签: %d\n疾病类型: %s\n置信度: %s (%.4f)', ...
                result, diseaseName, confidenceLevel, maxScore);
            
            % 添加相似度信息
            if ~isempty(similarityScores)
                detailInfo = sprintf('%s\n\n相似度得分:', detailInfo);
                for i = 1:length(similarityScores)
                    diseaseInfo = getDiseaseInfo(app, i);
                    detailInfo = sprintf('%s\n类别 %d (%s): %.4f', ...
                        detailInfo, i, diseaseInfo{1}, similarityScores(i));
                end
            end
            
            % 添加特征信息
            detailInfo = sprintf('%s\n\nBeta节律特征:\n排列组合熵(PE):   %.6f\n奇异谱熵(SSE):    %.6f\n样本熵(SE):       %.6f', ...
                detailInfo, betaFeatures(1), betaFeatures(2), betaFeatures(3));
            
            % 添加描述和建议
            detailInfo = sprintf('%s\n\n描述: %s\n\n建议: %s', ...
                detailInfo, description, advice);
            
            % 如果模型有准确率信息，添加
            if isfield(app.TrainedModel, 'accuracy')
                detailInfo = sprintf('%s\n\n模型训练准确率: %.2f%%', ...
                    detailInfo, app.TrainedModel.accuracy * 100);
            end
            
            % 显示详细信息对话框
            uialert(app.UIFigure, detailInfo, 'SCC模型检测结果 | SCC Model Detection Result', ...
                'Icon', 'success', 'Modal', true);
            
            % 在控制台输出更详细的结果
            fprintf('\n=== 检测结果详情 ===\n');
            fprintf('预测标签: %d\n', result);
            fprintf('疾病类型: %s\n', diseaseName);
            fprintf('置信度: %s (%.4f)\n', confidenceLevel, maxScore);
            fprintf('相似度得分: [%.4f, %.4f, %.4f]\n', ...
                similarityScores(1), similarityScores(2), similarityScores(3));
            if isfield(app.TrainedModel, 'accuracy')
                fprintf('模型训练准确率: %.2f%%\n', app.TrainedModel.accuracy * 100);
            end
            fprintf('========================\n\n');
        end
        
        % 根据结果获取疾病信息
        function [diseaseName, color, description, advice] = getDiseaseInfo(app, result)
            switch result
                case 1
                    diseaseName = '阿尔茨海默症 | Alzheimer''s Disease (AD)';
                    color = [0.8 0.2 0.2];  % 红色
                case 2
                    diseaseName = '健康 | Healthy Control';
                    color = [0.2 0.6 0.2];  % 绿色
                case 3
                    diseaseName = '额颞叶痴呆 | Frontotemporal Dementia (FTD)';
                    color = [0.9 0.6 0.1];  % 橙色
                otherwise
                    diseaseName = sprintf('未知结果 | Unknown Result (%d)', result);
                    color = [0.5 0.5 0.5];  % 灰色
            end
        end
    end
    
    methods (Access = public)
        function app = EEGProcessor
            createComponents(app);
            
            % 初始化所有数据
            app.OriginalData = [];
            app.TimeVector = [];
            app.SegmentedData = [];
            app.SegmentedTime = [];
            app.WaveletCoeffs = {};
            app.RhythmNames = {};
            app.Features = table();
            app.TrainedModel = struct();
            app.IsModelLoaded = false;

        end
    end
end