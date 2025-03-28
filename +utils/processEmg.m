function [processedEmg] = processEmg(emg,fs,epochLen)
% truncate emg to a multiple of SR
samplesPerEpoch = fs*epochLen;
emg = emg(1:(length(emg)-mod(length(emg), samplesPerEpoch)));

% calculate log(rms) in each time window
% we can do this faster if the number of samples per epoch is an integer
if samplesPerEpoch == floor(samplesPerEpoch)
    processedEmg = log(rms(reshape(emg,samplesPerEpoch,length(emg)/samplesPerEpoch)));
else
    processedEmg = zeros(1,floor(length(emg)/samplesPerEpoch));
    for i = 1:length(processedEmg)
        processedEmg(i)=log(rms(emg(floor((i-1)*samplesPerEpoch + 1):floor(i*samplesPerEpoch))));
    end
end
