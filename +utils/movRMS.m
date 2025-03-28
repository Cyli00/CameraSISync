function emg_rms = movRMS(emg, k)
% 计算信号的每个元素的平方
emg_squared = emg.^2;
% 创建一个滑动窗口。这里使用了一个均匀窗口
window = ones(k, 1) / (k);
% 对平方后的信号应用滑动平均（卷积）
% 'same' 选项确保输出与原始信号具有相同的长度
emg_smoothed = conv(emg_squared, window, 'same');
% 对结果取平方根得到移动 RMS
emg_rms = sqrt(emg_smoothed);
end