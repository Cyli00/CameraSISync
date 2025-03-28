function plotSignal(raw,eegAxes,emgAxes,rmsAxes,fs,timeWindow,f0,f1)
h = height(raw);
current = h/fs;
if current-timeWindow <= 0
    tvec = 1:h;
    x = 1/fs:1/fs:h/fs;
    y0 = raw.Dev1_ai0(tvec);
    y1 = raw.Dev1_ai1(tvec);
    xlim = [0,timeWindow];
else
    tvec = h-timeWindow*fs+1:h;
    x = (h/fs-timeWindows+1/fs):1/fs:h/fs;
    y0 = raw.Dev1_ai0(tvec);
    y1 = raw.Dev1_ai1(tvec);
    xlim = [current-timeWindow,current];
end

y0_filt = filtfilt(f0,y0);
y1_filt = filtfilt(f1,y1);
rms_ratio = getRMSratio(y1_filt,fs,h);

plot(eegAxes,x,y0_filt);
plot(emgAxes,x,y1_filt);
plot(rmsAxes,x,rms_ratio);
text(eegAxes,"Units","normalized","Position",[1,1],"String",sprintf('%0.1f',current));

eegAxes.XLim = xlim;
emgAxes.XLim = xlim;
rmsAxes.XLim = xlim;
drawnow limitrate nocallbacks;
end
