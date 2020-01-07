function d = configure_mcc_daq()

d = DaqFind;
err = DaqDConfigPort(d,0,0); % port A as input
err = DaqDConfigPort(d,1,1); % port B as output

DaqDOut(d,0,1); % clear existing high voltages