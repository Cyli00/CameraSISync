function rmsratio = getRMSratio(emg,fs,l)
rmsL = 0.1*fs; % 100 ms rms window
emg_rms = movRMS(emg,rmsL);
emg_sorted = sort(emg_rms,'ascend');
rms_baseline = mean(emg_sorted(0.1*l+1:0.3*l));
rmsratio = (emg_rms - rms_baseline)./ rms_baseline;
end