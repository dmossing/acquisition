function burn_path_with_imaging_laser(H_Scanbox,dirn,total,rise,step,wait)

%%
if rise > 0
    zdir = 'z+';
else
    zdir = 'z-';
end
nstep = uint8(round(total/step));
zstep = sprintf('%1.1f',step*abs(rise)/(step*nstep));
for i=1:nstep
    fprintf(H_Scanbox,['P' dirn num2str(step)])
    fprintf(H_Scanbox,['P' zdir '6'])
    pause(wait)
end

