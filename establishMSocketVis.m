function [sockVis,sockEphys] = establishMSocketVis(ipEphys)

% sockVis has address 3000, sockEphys has address 4000

if nargin < 1
    ipEphys = '128.32.173.24';
end

%%
function go_up(d)
DaqDOut(d,0,0);
DaqDOut(d,0,255);

function go_down(d)
DaqDOut(d,0,0);
DaqDOut(d,0,255);

function wait_for_up(d)
handshook = false;
while ~handshook
    TTLin = DaqDIn(d);
    handshook = TTLin(end)>=128;
end

function wait_for_down(d)
handshook = false;
while ~handshook
    TTLin = DaqDIn(d);
    handshook = TTLin(end)<128;
end

%%

d = configure_mcc_daq;

%%

go_up(d)

%%

wait_for_up(d)

%%

% set up msocket

srvsock = mslisten(3000);
sockVis = msaccept(srvsock);
msclose(srvsock);
disp('Vis->Ephys socket established')

%%

wait_for_down(d)

%%

go_down(d)

%%

wait_for_up(d)

%%

go_up(d)

%%
sockEphys = msconnect(ipEphys,4000);
disp('Ephys->Vis socket established')

%%

go_down(d)


%%

wait_for_down(d)
