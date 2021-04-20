function monitor_led_commands()
%vis_stim

function H_Stim = udp_open()
vis_stim_ip = '128.32.173.24';
stim_port = 21000;
H_Stim = udp(vis_stim_ip, 'RemotePort', stim_port, ...
    'LocalPort', stim_port,'BytesAvailableFcn',@process_stim_input);
fopen(H_Stim);

function udp_close(H_Stim)
fclose(H_Stim);
delete(H_Stim);

function [done] = process_stim_input(a) %,DAQ)
level = fread(a,'double');
fwrite(s)
