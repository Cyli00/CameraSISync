clc;
clear all;

load D:\LAB-share\Member-LCY\Data\20231222-syy\filt_00007.mat;
fs = 2000;

eeg = data_filt(:,1);
emg = data_filt(:,2);

% index = find(data_filt(:,4) == 2); % NREM 1 == value 2

l = height(data_filt);
tvec = 1:length(eeg);

movingwin=[4 4]; % set the moving window dimensions
movingwin_l = movingwin(1,2);
 
params.Fs=fs; % sampling frequency
params.fpass=[0.5 20]; % frequencies of interest
params.tapers=[4 3]; % tapers
params.trialave=1; % average over trials
params.err=0; 

[s,t,f] = mtspecgramc(eeg,movingwin,params);

PowerDelta = sum(s(:,0.5<f&f<4),2);           % you can modify the power band limit here. 
PowerTheta = sum(s(:,4<f&f<8),2);
PowerAlpha = sum(s(:,8<f&f<13),2);
PowerBeta = sum(s(:,13<f&f<20),2);
PowerSum = sum([PowerDelta PowerTheta PowerAlpha PowerBeta],2);  
% PowerSum = sum(S1(:,0.5<f&f<32),2);            % you can modify the power band limit here. 
Prevalence = [PowerDelta';PowerTheta';PowerAlpha';PowerBeta']./transpose(repmat(PowerSum,1,4));
Prevalence_save = [t' Prevalence'];
RawPower = [t' PowerDelta PowerTheta PowerAlpha PowerBeta];

x_min = 0;
x_max = l/fs;


%% plot

figure;

subplot(511)
plot_matrix(s,t,f);
xlabel([]); % plot spectrogram
colormap('jet')
ylabel('Frequency')
xlim([0 x_max])
ylim([0.5 20]);


subplot(512)
bar(t',Prevalence', 'stacked'), colormap('jet');
title('Spectrum Bar', 'fontsize', 10);
legend('0.5-4Hz','4-8Hz','8-13Hz','13-20Hz');
ylabel('Prevalence');
xlim([0 x_max])
ylim([0 1])

subplot(513)
plot(t',Prevalence')
ylabel('Prevalence')
legend('0.5-4Hz','4-8Hz','8-13Hz','13-20Hz');
xlim([0 x_max])
ylim([0 1])
% savefig(strcat(csvname,'_fig'))


% subplot(514)
% hold on
% plot(tvec./fs,eeg)
% 
% % 获取当前y轴的限制
% ylim([-0.05 0.03])
% current_ylim = get(gca, 'YLim');
% for i = 1:length(index)
%     start_idx = max(index(i)-2*fs, 1);
%     end_idx = min(index(i)+2*fs-1, length(data_filt));
%     start_time = start_idx/fs;
%     end_time = end_idx/fs;
%     % 画一个粉色半透明矩形
%     h = fill([start_time start_time end_time end_time], [current_ylim(1) current_ylim(2) current_ylim(2) current_ylim(1)], 'm', 'FaceAlpha', 0.3);
%     text(start_time + (end_time - start_time)/2, current_ylim(2), 'NR', ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
%         'BackgroundColor', 'none', 'Margin', 1, 'FontSize', 6);
% end
% hold off
% ylabel('EEG')
% xlim([0 x_max])
% 
% subplot(515)
% plot(tvec./fs,emg)
% hold on
% for i = 1:length(index)
%     start_idx = max(index(i)-2*fs, 1);
%     end_idx = min(index(i)+2*fs-1, length(data_filt));
%     start_time = start_idx/fs;
%     end_time = end_idx/fs;
%     % 画一个粉色半透明矩形
%     h = fill([start_time start_time end_time end_time], [current_ylim(1) current_ylim(2) current_ylim(2) current_ylim(1)], 'm', 'FaceAlpha', 0.3);
%     text(start_time + (end_time - start_time)/2, current_ylim(2), 'NR', ...
%         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
%         'BackgroundColor', 'none', 'Margin', 1, 'FontSize',6);
% end
% hold off
% ylabel('EMG')
% xlim([0 x_max])
% ylim([-0.05 0.03])

