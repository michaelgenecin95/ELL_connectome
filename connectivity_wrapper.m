clc
clear all
%% Collect all relevant info from .json files in a folder 
pathToCells = 'D:\MATLAB\ELL_em\cells\';
cell_list = dir(fullfile(pathToCells,'*cell_*.json')); % find all jsons starting with cell

for i = 1: numel(cell_list)
    % suggested naming system cell_segmentID_type_celltypename (more after)
    str = split(cell_list(i).name(1:end-5), '_');
    cell_list(i).id = str2num(str{2}); % location of SegmentID
    cell_list(i).type = str{4}; %location of type assignment
    
    data = jsondecode(fileread(fullfile(pathToCells,cell_list(i).name)));
    noLinkedSegmentCount = 0;
    for j = 1:numel(data.layers)
        % collect the segments that belong to this cell (all .json files
        % have this info). We might want to rename base_seg_220930 to
        % 'cell' or similar. To distinguish between multiple segmentation
        % layers 
        if strcmp(data.layers{j}.type,'segmentation') && strcmp(data.layers{j}.name,'base_seg_220930')
            cell_list(i).segments = [cellfun(@str2num, data.layers{j}.segments)];
        end
        % collect the segments from postsynaptic partners (only some .jsons
        % have this info. Look for a "synapses" annotation layer. 
        if strcmp(data.layers{j}.type,'annotation') && strcmp(data.layers{j}.name,'synapses')
            % synapse annotations with associated segments are a cell array 
            % type and if they don't have associated segments the annotation 
            % layer is a struct type
            
            if isa(data.layers{j}.annotations, 'cell')
                cell_list(i).ps_partner_segments = [];
                for k = 1:numel(data.layers{j}.annotations)
                    if isfield(data.layers{j}.annotations{k}, 'segments')
                        ps_partner_segment= [cellfun(@str2num, data.layers{j}.annotations{k}.segments{1})];
                        cell_list(i).ps_partner_segments = [cell_list(i).ps_partner_segments; ps_partner_segment];
                    else
                        noLinkedSegmentCount = noLinkedSegmentCount+1;
                        cell_list(i).noSegCount = noLinkedSegmentCount;
                        disp('NO SEGMENT LINKED TO THIS POINT');
                    end
                end
            elseif isa(data.layers{j}.annotations, 'struct')
                cell_list(i).ps_partner_segments = [];
                for k = 1:numel(data.layers{j}.annotations)
                    if isfield(data.layers{j}.annotations(k), 'segments')
                        ps_partner_segment= [cellfun(@str2num, data.layers{j}.annotations(k).segments{1})];
                        cell_list(i).ps_partner_segments = [cell_list(i).ps_partner_segments; ps_partner_segment];
                    else
                       noLinkedSegmentCount = noLinkedSegmentCount+1;
                       cell_list(i).noSegCount = noLinkedSegmentCount;
                       disp('NO SEGMENT LINKED TO THIS POINT'); 
                    end
                end
            end
            
        end
    end    
end
%%
% Find the ps_partner_id (postsynaptic partner SegmentID) and 
% the ps_partner_ix (the index within cell_list structure which belongs to
% that ps_partner

for i = 1:numel(cell_list)
    if ~isempty(cell_list(i).ps_partner_segments)
        cell_list(i).ps_partner_ix = [];
        cell_list(i).ps_partner_id = [];
        % check the segment against each cell to see which contains it
        % (could be made to run faster)
        for j = 1:numel(cell_list(i).ps_partner_segments)
            for ix = 1:numel(cell_list)
                if ismember(cell_list(i).ps_partner_segments(j), cell_list(ix).segments)
                   cell_list(i).ps_partner_ix = [cell_list(i).ps_partner_ix; ix];
                   cell_list(i).ps_partner_id = [cell_list(i).ps_partner_id; cell_list(ix).id]; 
                end
            end           
        end
    end
end
%% error checks:
% 1) report self-synapses, print cell ID and annotation coordinates
% 2) double check any segment overlaps to eliminate duplicate cells




%% Visualization
% make a graph of directed edges 
presynapticNodes = [];
postsynapticNodes = [];

for i = 1:numel(cell_list)
    postsynaptic_ix = cell_list(i).ps_partner_ix;
    presynaptic_ix = ones(size(postsynaptic_ix))*i;
    postsynapticNodes = [postsynapticNodes; postsynaptic_ix(:)];
    presynapticNodes = [presynapticNodes; presynaptic_ix(:)];        
end


G = digraph(presynapticNodes', postsynapticNodes');
figure
plot(G,'Layout','force')
title('Node numbers correspond to index in cell list')

weights = ones(size(presynapticNodes'));
node_names = string([cell_list.id]);
G = digraph(presynapticNodes', postsynapticNodes', weights, node_names);
figure
plot(G,'Layout','force')
title('Node numbers correspond to segmentIDs')

%% Visualization 2
% make matrix size cell-list by cell-list

%reorder everything based on cell type
cell_listTable = struct2table(cell_list);
[sorted_list,sorted_list.origIx] = sortrows(cell_listTable,'type'); %,{'descend'});

conndata = zeros(height(sorted_list),height(sorted_list));
cellnameKey = [];

for i = 1:height(sorted_list)
    
    cellnameKey{i,1} = sorted_list.name{i};
    cellnameKey{i,2} = sorted_list.type{i};
    
    if ~isempty(sorted_list.ps_partner_ix{i})
        for j = 1:length(sorted_list.ps_partner_ix{i})
            partnerMatrixIndex = find(sorted_list.origIx == sorted_list.ps_partner_ix{i}(j));
            conndata(i,partnerMatrixIndex) = conndata(i,partnerMatrixIndex) + 1;
        end
    end
    
end
%conndata = conndata.';
cellnameKey{1,2} = [cellnameKey{1,2} '-A'];
letterval = 65;
celltypeBorders = [];
for i = 2:length(cellnameKey)
    if strcmpi(cellnameKey{i-1,2}(1:end-2),cellnameKey{i,2})
        letterval = letterval+1;
    else
        celltypeBorders(end+1) = i;
        letterval = 65;
    end
    cellnameKey{i,2} = [cellnameKey{i,2} '-' char(letterval)];
end

%% use heatmap function to heatmap (not as nice)
figure;
xvals = cellnameKey(:,2);
yvals = cellnameKey(:,2);
h = heatmap(xvals,yvals,conndata);
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';


%% use imagesc to heatmap

x = [1 length(cellnameKey)];
y = [1 length(cellnameKey)];
figure;
colormap(flipud(hot(max(max(conndata)) + 1)));
imagesc(x,y,conndata);

for i = 1:length(celltypeBorders)
    hold on;
    plot([celltypeBorders(i)-0.5 celltypeBorders(i)-0.5],[0.5 25.5],'-k'); 
    hold on;
    plot([0.5 25.5],[celltypeBorders(i)-0.5 celltypeBorders(i)-0.5],'-k'); 
end

xticks(1:length(cellnameKey));
yticks(1:length(cellnameKey));
xticklabels(cellnameKey(:,2));
yticklabels(cellnameKey(:,2));
set(gca,'XAxisLocation','top')
box off;
colorbar;
h = colorbar('Ticks',[0 max(max(conndata))]);

h.Label.String = 'Number of synapses';
xlabel('post-synaptic partner')
ylabel('pre-synaptic partner')
%%
% run heatmap again with unconnected cells removed








