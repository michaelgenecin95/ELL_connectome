%%%%%%%%%%%%%%%%%% READ THE SEGMENTS FROM THE RECONSTRUCTED CREST FILES
%%%%%%%%%%%%%%%%%%

filepath = ('C:\Users\EngertLab\Dropbox\U19_zebrafish\EMfullres\LateralLineCurlDetector\CREST\left_MON\');
cells = dir([filepath,'cell_*.json']); % find all jsons starting with cell
% get the ids
ids = [];
for i = 1:length(cells)
    filename = strsplit(cells(i).name,'_');
    ids(i) = str2num(filename{3});
end
unique_ids = unique(ids);

CREST_cell_info = struct;

for i = 1:length(unique_ids)
    idx = find(ids == unique_ids(i));
    jsons_for_this_id = cells(idx);
    timestamps = datetime();
    for j = 1:length(idx)
        fields = strsplit(cells(idx(j)).name,'_');
        s = fields{end};
        timestamps(j) = datetime(s(1:end-5),'InputFormat','yyyy-MM-dd HH.mm.ss');
    end
    [~, j] = max(timestamps);
    CREST_cell_info(i).seg_id = unique_ids(i);
    CREST_cell_info(i).path = [filepath,cells(idx(j)).name];
    
    data = jsondecode(fileread(CREST_cell_info(i).path));
    
    fields = fieldnames(data.base_segments);
    if length(fields)>1
        CREST_cell_info(i).base_segs = cellfun(@str2num, [data.base_segments.unknown; ...
            data.base_segments.axon; data.base_segments.cellBody;...
            data.base_segments.dendrite]);
    else
        CREST_cell_info(i).base_segs = cellfun(@str2num, data.base_segments.unknown);
        
    end
end