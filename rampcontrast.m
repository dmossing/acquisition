function ramped = rampcontrast(frames,cRamp)
% assumes arr is a XxYxN movie, cRamp has length N
ramped = frames;
for i=1:size(ramped,3)
    temp = 0.5+(double(frames(:,:,i))/double(intmax(class(frames)))-0.5)*cRamp(i);
    ramped(:,:,i) = cast(double(intmax(class(frames)))*temp,class(frames));
end