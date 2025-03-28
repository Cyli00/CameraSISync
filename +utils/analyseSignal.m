function analyseSignal(raw,fs,analyseWin,f0,f1)
h = height(raw);
tvec = h-analyseWin*fs+1:h;

eeg = raw.Dev1_ai0(tvec);
emg = raw.Dev1_ai1(tvec);

eeg = filtfilt(f0,eeg);
emg = filtfilt(f1,emg);
l = analyseWin*fs;

% rmsratio
rmsratio = getRMSratio(emg,fs,l);
% spectrogram
params = struct;
params.Fs = fs;
params.fpass = [0 40];
params.tapers = [3 5];
params.pad = -1;
winstep = analyseWin;

eeg = eeg(1:(length(eeg)-mod(length(eeg),l)));
[s, t, f] = mtspecgramc(eeg, [window, winstep], params);
end

