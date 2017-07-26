function trialwise = trialize(data,frm,extra_before,extra_after)
% realign data into rows (or columns for more than one time series) aligned
% to trial onsets
if size(data,1)>1 && size(data,2)>1
    signo = size(data,1);
else
    signo = 1;
    data = data(:)';
end
stimlen = min(diff(frm,1,2));
tracelen = stimlen+extra_before+extra_after;
trialno = size(frm,1);
trialwise = zeros(signo,trialno,tracelen);
for j=1:signo
    for i=1:trialno
        trialwise(j,i,:) = data(j,frm(i,1)-extra_before+1:frm(i,1)+stimlen+extra_after);
    end
end
trialwise = squeeze(trialwise);
end