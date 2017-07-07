function labjack_close(ljudObj, ljhandle)
%Reset all pin assignments to factory default condition.
ljudObj.ePut(ljhandle, LabJack.LabJackUD.IO.PIN_CONFIGURATION_RESET, 0, 0, 0);