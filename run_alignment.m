function run_alignment(foldname,lookfor)
    if ~exist('lookfor','var') || isempty(lookfor)
        lookfor = '';
    end
    lookfor
    d = dir([foldname '/*' lookfor '*.sbx'])
    for i=1:numel(d)
        fname = d(i).name
        filebase = strsplit(fname,'.sbx');
        filebase = filebase{1};
        load([foldname '/' filebase],'info')
        %if info.scanmode==0
        %    info.recordsPerBuffer = info.recordsPerBuffer*2;
        %end
        which sbxAlignmaster
        if isfield(info,'rect')
            sbxAlignmaster([foldname '/' filebase],[],info.rect);
        else
            sbxAlignmaster([foldname '/' filebase]);
            which sbxComputeci
        	sbxComputeci([foldname '/' filebase]);
        end
        %which sbxComputeci
        %sbxComputeci([foldname '/' filebase],[],info.rect);
    end
end
