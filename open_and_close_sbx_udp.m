%%
sb_ip = '128.32.173.30'; % SCANBOX ONLY: for UDP
sb_port = 7000; % SCANBOX ONLY: for UDP
H_Scanbox = udp(sb_ip, 'RemotePort', sb_port); % create udp port handle
fopen(H_Scanbox);
%%
fclose(H_Scanbox)