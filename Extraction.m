
        
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
