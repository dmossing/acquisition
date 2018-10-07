function run_scanimage_client
d = daq.createSession('ni');
%%
[sockSI2Ephys,sockEphys2SI] = establishMSocketSI(d);
socks.sockSI2Ephys = sockSI2Ephys;
socks.sockEphys2SI = sockEphys2SI;
socks.d = d;
%%
keepGoing = 1;
%%
while keepGoing
    %%
    incoming = receiveMSocket(sockEphys2SI,d);
    if ~iscell(incoming)
        incoming = {};
    end
    exptType = incoming{1};
    if numel(incoming)>1
        exptParams = incoming{2};
    else
        exptParams = {};
    end
    
    switch exptType
        case 'requestVanillaHolos'
            requestVanillaHolos(socks,exptParams{:});
        case 'runLoopedAcquisition'
            runLoopedAcquisition(socks,exptParams{:});
        case 'lookAdLib'
            lookAdLib(exptParams{:});
    end
end