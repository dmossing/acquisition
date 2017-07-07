function ct = labjack_get_ctr(ljudObj, ljhandle)
[ljerror, ct] = ljudObj.eGet(ljhandle, LabJack.LabJackUD.IO.GET_COUNTER, 1, 0, 0);