

clear; clc; close all;


%% 参数设置
samplingRate = 500;          % 采样率(Hz)
waveletName = 'db4';         % 使用的小波基
numLevels = 5;               % DWT分解层数
numChannels = 19;            % 通道数量

% 文件夹路径
sourceFolder = 'D:\LNCD\DATA\CSV_Output';
outputFolder = 'D:\LNCD\RESULT';



% 创建输出文件夹
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end


%% 获取所有CSV文件
fileList = dir(fullfile(sourceFolder, '*.csv'));
numFiles = length(fileList);

%% 处理每个CSV文件（截取中间1/3）
for fileIdx = 50:numFiles
    try
        fprintf('处理文件 %d/%d: %s\n', fileIdx, numFiles, fileList(fileIdx).name);
        
        % 读取CSV文件，跳过第一行（标题）
        filePath = fullfile(sourceFolder, fileList(fileIdx).name);
        
        % 检查文件大小
        fileInfo = dir(filePath);
        if fileInfo.bytes == 0
            fprintf('文件 %s 为空，跳过处理\n', fileList(fileIdx).name);
            continue;
        end
        
        % 读取数据，跳过第一行
        data = readmatrix(filePath, 'NumHeaderLines', 1);
        
        % 检查数据大小
        if size(data, 2) < 20
            fprintf('文件 %s 列数不足，跳过处理\n', fileList(fileIdx).name);
            continue;
        end
        
        % 第一列是时间，第2-20列是19个通道的EEG信号
        timeData = data(:, 1);
        eegSignals = data(:, 2:20); % 19个通道
        
        % 计算中间三分之一的索引
        totalSamples = size(eegSignals, 1);
        startIdx = round(totalSamples* (9/20)) + 1;
        endIdx = round( totalSamples * (10/20));
        
        fprintf('总样本数: %d, 截取范围: %d-%d\n', totalSamples, startIdx, endIdx);
        
        % 截取中间三分之一数据
        middleThirdEEG = eegSignals(startIdx:endIdx, :);
        
        % 为所有通道创建特征存储
        allFeatures = cell(numChannels, 1);
        
        % 处理每个通道
        for ch = 1:numChannels
            fprintf('  处理通道 %d/%d\n', ch, numChannels);
            
            % 提取当前通道的中间三分之一EEG信号
            channelSignal = middleThirdEEG(:, ch);
            
            % 提取特征
            allFeatures{ch} = extractFeatures(channelSignal, samplingRate, waveletName, numLevels);
        end
        
        % 保存到MAT文件
        baseFileName = strrep(fileList(fileIdx).name, '.csv', '');
        outputFile = fullfile(outputFolder, [baseFileName, '_middle_third_features.mat']);
        
        % 保存所有通道的特征矩阵
        save(outputFile, 'allFeatures');
        fprintf('已保存文件: %s\n', outputFile);
        
    catch ME
        fprintf('处理文件 %s 时出错: %s\n', fileList(fileIdx).name, ME.message);
        continue;
    end
end

fprintf('所有文件处理完成！\n');

%% 特征提取函数
function featureMatrix = extractFeatures(eegSignal, samplingRate, waveletName, numLevels)
    % 使用EEG信号提取特征
    
    % 确保信号是行向量
    if iscolumn(eegSignal)
        eegSignal = eegSignal';
    end
    
    % 检查信号长度是否足够进行DWT分解
    minLength = 2^numLevels + 1;
    if length(eegSignal) < minLength
        fprintf('信号长度不足，无法进行%d层DWT分解\n', numLevels);
        featureMatrix = NaN(5, 5);
        return;
    end
    
    try
        % DWT分解为5个节律
        [C, L] = wavedec(eegSignal, numLevels, waveletName);
        gamma = wrcoef('d', C, L, waveletName, 1);
        beta  = wrcoef('d', C, L, waveletName, 2);
        alpha = wrcoef('d', C, L, waveletName, 3);
        theta = wrcoef('d', C, L, waveletName, 4);
        delta = wrcoef('a', C, L, waveletName, 4);
        
        rhythms = {delta, theta, alpha, beta, gamma};
        rhythmNames = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
        featureMatrix = zeros(5, 5); % 5节律 × 5熵
        
        % 为每个节律计算5种熵
        for r = 1:5
            rhythmSignal = rhythms{r};
            
            % 确保每个节律信号是行向量
            if iscolumn(rhythmSignal)
                rhythmSignal = rhythmSignal';
            end
            
            % 检查节律信号长度
            if length(rhythmSignal) < 100
                fprintf('节律 %s 信号长度不足，跳过熵计算\n', rhythmNames{r});
                featureMatrix(r, :) = NaN(1, 5);
                continue;
            end
            
            % 按照您提供的格式调用熵函数
            try
                featureMatrix(r, 1) = FuzzyEntropy(rhythmSignal, 2, 0.15, 2, 1);
            catch ME
                fprintf('FuzzyEntropy 计算错误: %s\n', ME.message);
                featureMatrix(r, 1) = NaN;
            end
            
            try
                featureMatrix(r, 2) = SampleEntropy(rhythmSignal);
            catch ME
                fprintf('SampleEntropy 计算错误: %s\n', ME.message);
                featureMatrix(r, 2) = NaN;
            end
            
            try
                featureMatrix(r, 3) = PermutationEntropy(rhythmSignal);
            catch ME
                fprintf('PermutationEntropy 计算错误: %s\n', ME.message);
                featureMatrix(r, 3) = NaN;
            end
            
            try
                featureMatrix(r, 4) = SingularSpectrumEntropy(rhythmSignal, 2, 1);
            catch ME
                fprintf('SingularSpectrumEntropy 计算错误: %s\n', ME.message);
                featureMatrix(r, 4) = NaN;
            end
            
            try
                featureMatrix(r, 5) = SpectrumEntropy(rhythmSignal, samplingRate);
            catch ME
                fprintf('SpectrumEntropy 计算错误: %s\n', ME.message);
                featureMatrix(r, 5) = NaN;
            end
        end
        
    catch ME
        fprintf('特征提取出错: %s\n', ME.message);
        featureMatrix = NaN(5, 5);
    end
end