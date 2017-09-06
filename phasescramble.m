function scram = phasescramble(fname)
loading = load(fname);
arr = loading.frames;
LY = (size(arr,1)-1)/2;
LX = (size(arr,2)-1)/2;
LZ = (size(arr,3)-1)/2;
Farr = fftn(arr);
disp('FT complete')
randphase1 = exp(2*pi*1j*rand(2*LY,2*LX,LZ));
randphase = complex(ones(2*LY+1,2*LX+1,2*LZ+1));
randphase(1+(1:2*LY),1+(1:2*LX),1+(1:LZ)) = randphase1;
randphase(1+(2*LY:-1:1),1+(2*LX:-1:1),LZ+1+(LZ:-1:1)) = conj(randphase1);
disp('random phase array constructed')
scram = cast(ifftn(Farr.*randphase),class(arr));
disp('phase scrambled movie complete')
save(strrep(fname,'.mat','_scrambled.mat'),'-v7.3','scram')
