function run_alignment(foldname,lookfor)
    if ~exist(lookfor,'var') || isempty(lookfor)
        lookfor = '';
    end
    d = dir([foldname '/*' lookfor '*.sbx'])
    for i=1:numel(d)
        fname = d(i).name;
        filebase = strsplit(fname,'.sbx');
        filebase = filebase{1};
        load(filebase,'info')
        sbxAlignmaster(filebase,[],info.rect);
    end
end
