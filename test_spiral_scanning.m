%%
d = daq.createSession('ni');
d.addAnalogOutputChannel('Dev2','ao0','Voltage');
d.addAnalogOutputChannel('Dev2','ao1','Voltage');
ch0 = d.addAnalogInputChannel('Dev2','ai0','Voltage');
ch1 = d.addAnalogInputChannel('Dev2','ai1','Voltage');
% ch0.Range = [-50,50];
% ch1.Range = [-50,50];
%%
dc_offset = 5;
warmup = 30;
duration = 10;
radAmp = 5;
radFreq = 1;
azFreq = 4;
samplingRate = 1.25e5;
d.Rate = samplingRate;
[x,y] = spiral_scan_dpm(radAmp,radFreq,azFreq,samplingRate);
X = [dc_offset+repmat(x,floor(duration*radFreq),1)];
Y = [dc_offset+repmat(y,floor(duration*radFreq),1)];
% X = [linspace(0,dc_offset,samplingRate*warmup)'; dc_offset+repmat(x,floor(duration*radFreq),1)];
% Y = [linspace(0,dc_offset,samplingRate*warmup)'; dc_offset+repmat(x,floor(duration*radFreq),1)];
queueOutputData(d,[X Y]);
data = startForeground(d);

%%
t = 0:1/samplingRate:(numel(X)-1)/samplingRate;
subplot(1,2,1)
plot(t,data(:,2))
xlabel('t (s)')
ylabel('Monitor voltage (V)')
rg = 3000000+(1:1500);
subplot(1,2,2)
plot(t(rg),data(rg,2))
xlabel('t (s)')
ylabel('Monitor voltage (V)')
%%
figure;
t = 0:1/samplingRate:(numel(X)-1)/samplingRate;
subplot(1,2,1)
plot(t,Y)
xlabel('t (s)')
ylabel('Monitor voltage (V)')
rg = 3000000+(1:1500);
subplot(1,2,2)
plot(t(rg),Y(rg))
xlabel('t (s)')
ylabel('Monitor voltage (V)')