clc
clear all
%% Collect all relevant info from .json files in a folder 
pathToCells = 'D:\MATLAB\ELL_em\cells';
%pathToPre = strcat(pathToCells,'\presynaptic');
cell_list = dir(fullfile(pathToCells,'*cell_*.json')); % find all jsons starting with cell
unlinkedAnno = 0;

includePre = 1;

for i = 1:numel(cell_list)
    % suggested naming system cell_segmentID_type_celltypename (more after)
    
    %cell_list(i).isPost = strcmp(cell_list(i).folder,pathToPre);
        
    str = split(cell_list(i).name(1:end-5), '_');
    cell_list(i).id = str2num(str{2}); % location of SegmentID
    cell_list(i).type = str{4}; %location of type assignment
    
    data = jsondecode(fileread(fullfile(cell_list(i).folder,cell_list(i).name)));
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
                        disp(sprintf('CELL: %d  CONTAINS SYNAPSE WITH NO LINKED SEGMENT',cell_list(i).id));
                        unlinkedAnno = unlinkedAnno + 1;
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
                       disp(sprintf('CELL: %d  CONTAINS SYNAPSE WITH NO LINKED SEGMENT',cell_list(i).id));
                       unlinkedAnno = unlinkedAnno + 1;
                    end
                end
            end
        end
        if includePre == 1
            if strcmp(data.layers{j}.type,'annotation') && strcmp(data.layers{j}.name,'pre_axon')
                if isa(data.layers{j}.annotations, 'cell')
                    cell_list(i).preAxon_partner_segments = [];
                    for k = 1:numel(data.layers{j}.annotations)
                        if isfield(data.layers{j}.annotations{k}, 'segments')
                            preAxon_partner_segment= [cellfun(@str2num, data.layers{j}.annotations{k}.segments{1})];
                            cell_list(i).preAxon_partner_segments = [cell_list(i).preAxon_partner_segments; preAxon_partner_segment];
                        else
                            noLinkedpreAxonCount = noLinkedpreAxonCount+1;
                            cell_list(i).noPreCount = noLinkedPreCount;
                            disp('NO PRE-SEGMENT LINKED TO THIS POINT');
                            unlinkedAnno = unlinkedAnno + 1;
                        end
                    end
                elseif isa(data.layers{j}.annotations, 'struct')
                    cell_list(i).preAxon_partner_segments = [];
                    for k = 1:numel(data.layers{j}.annotations)
                        if isfield(data.layers{j}.annotations(k), 'segments')
                            preAxon_partner_segment= [cellfun(@str2num, data.layers{j}.annotations(k).segments{1})];
                            cell_list(i).preAxon_partner_segments = [cell_list(i).preAxon_partner_segments; preAxon_partner_segment];
                        else
                            noLinkedpreAxonCount = noLinkedpreAxonCount+1;
                            cell_list(i).noPreCount = noLinkedpreAxonCount;
                            disp('NO PRE-SEGMENT LINKED TO THIS POINT');
                            unlinkedAnno = unlinkedAnno + 1;
                        end
                    end
                end
            end
        end
    end    
    if isempty(cell_list(i).segments)
        disp(sprintf('WARNING: NO SEGMENTS FOUND FOR CELL %d',cell_list(i).id));
    end
end
%% find duplicate cells

arb = 200;           % arbitrary overlap line indicating duplicates vs bad reconstruction
duplicates = [];
possErrors = [];
for i = 1:(length(cell_list)-1)
    for j = (i+1):length(cell_list)
        if sum(ismember(cell_list(i).segments,cell_list(j).segments)) > 0
            dupAlength = length(cell_list(i).segments);
            dupBlength = length(cell_list(j).segments);
            if sum(ismember(cell_list(i).segments,cell_list(j).segments)) < arb
                possErrors(end+1,:) = [i,j];
            else
                if dupBlength > dupAlength
                    duplicates(end+1,:) = [j,i,sum(ismember(cell_list(i).segments,cell_list(j).segments)),dupBlength-dupAlength];
                else
                    duplicates(end+1,:) = [i,j,sum(ismember(cell_list(i).segments,cell_list(j).segments)),dupAlength-dupBlength];
                end
            end
        end
    end
end

if ~isempty(duplicates)
    for i = 1:length(duplicates(:,1))
        
        scoreCard = zeros(3,2);
        scoreCard(1,1:2) = [length(cell_list(duplicates(i,1)).ps_partner_segments),length(cell_list(duplicates(i,2)).ps_partner_segments)];
        scoreCard(2,1:2) = [length(cell_list(duplicates(i,1)).preAxon_partner_segments),length(cell_list(duplicates(i,2)).preAxon_partner_segments)];

        newSegments = unique([cell_list(duplicates(i,1)).segments;cell_list(duplicates(i,2)).segments]);     
        
        if scoreCard(1,2) > scoreCard(1,1)
            newPsPartners = cell_list(duplicates(i,2)).ps_partner_segments;
            usingPSpartners = cell_list(duplicates(i,2)).id;
        else
            newPsPartners = cell_list(duplicates(i,1)).ps_partner_segments;
            usingPSpartners = cell_list(duplicates(i,1)).id;
        end
        if scoreCard(2,2) > scoreCard(2,1)
            newPreAxonPartners = cell_list(duplicates(i,2)).preAxon_partner_segments;
            usingPreAxonpartners = cell_list(duplicates(i,2)).id;
        else
            newPreAxonPartners = cell_list(duplicates(i,1)).preAxon_partner_segments;
            usingPreAxonpartners = cell_list(duplicates(i,1)).id;
        end
        
        SegGains = length(newSegments)-length(cell_list(duplicates(i,1)).segments);
        
        cell_list(duplicates(i,1)).segments = newSegments;
        cell_list(duplicates(i,1)).ps_partner_segments = newPsPartners;
        cell_list(duplicates(i,1)).preAxon_partner_segments = newPreAxonPartners;
        
        fprintf(' \n');
        fprintf('cell %d and %d are duplicates (%s cell), combining data... \n', cell_list(duplicates(i,1)).id, cell_list(duplicates(i,2)).id, cell_list(duplicates(i,2)).type);
        fprintf('cell %d gains %d segments, using synapses from %d (%d)... \n',cell_list(duplicates(i,1)).id,SegGains,usingPSpartners,length(newPsPartners));
        fprintf('using Pre-Axon synapses from %d (%d)... \n',usingPreAxonpartners,length(newPreAxonPartners));
        
        
        if isempty(cell_list(duplicates(i,1)).ps_partner_segments) && ~isempty(cell_list(duplicates(i,2)).ps_partner_segments)
            tackOn = cell_list(duplicates(i,1));
            tackOn.OrigIx = duplicates(i,1);
            duplicateList(i) = tackOn;
            %cell_list(duplicates(i,1)) = [];
        else
            tackOn = cell_list(duplicates(i,2));
            tackOn.OrigIx = duplicates(i,2);
            duplicateList(i) = tackOn;
            %cell_list(duplicates(i,2)) = [];
        end
    end
end

cell_list([duplicateList(:).OrigIx]) = [];
%%
% Find the ps_partner_id (postsynaptic partner SegmentID) and 
% the ps_partner_ix (the index within cell_list structure which belongs to
% that ps_partner

for i = 1:numel(cell_list)
    if ~isempty(cell_list(i).ps_partner_segments)
        cell_list(i).ps_partner_ix = [];
        cell_list(i).ps_partner_id = [];
        cell_list(i).ps_unassigned = [];
        cell_list(i).ps_assigned = [];
        % check the segment against each cell to see which contains it
        % (could be made to run faster)
        for j = 1:numel(cell_list(i).ps_partner_segments)
            assigned = 0;
            for ix = 1:numel(cell_list)
                if ismember(cell_list(i).ps_partner_segments(j), cell_list(ix).segments)
                   cell_list(i).ps_partner_ix = [cell_list(i).ps_partner_ix; ix];
                   cell_list(i).ps_partner_id = [cell_list(i).ps_partner_id; cell_list(ix).id];
                   cell_list(i).ps_assigned = [cell_list(i).ps_assigned; cell_list(i).ps_partner_segments(j)];
                   assigned = 1;
                   break;
                end
            end
            if assigned == 0
                cell_list(i).ps_unassigned = [cell_list(i).ps_unassigned; cell_list(i).ps_partner_segments(j)];
            end
        end
    end
    if includePre == 1
        if ~isempty(cell_list(i).preAxon_partner_segments)
            cell_list(i).preAxon_partner_ix = [];
            cell_list(i).preAxon_partner_id = [];
            cell_list(i).preAxon_unassigned = [];
            % check the segment against each cell to see which contains it
            % (could be made to run faster)
            for j = 1:numel(cell_list(i).preAxon_partner_segments)
                assigned = 0;
                for ix = 1:numel(cell_list)
                    if ismember(cell_list(i).preAxon_partner_segments(j), cell_list(ix).segments)
                        cell_list(i).preAxon_partner_ix = [cell_list(i).preAxon_partner_ix; ix];
                        cell_list(i).preAxon_partner_id = [cell_list(i).preAxon_partner_id; cell_list(ix).id];
                        assigned = 1;
                    end
                end
                if assigned == 0
                    cell_list(i).preAxon_unassigned = [cell_list(i).preAxon_unassigned; cell_list(i).preAxon_partner_segments(j)];
                end
            end
        end
    end
end

%% error checks:
% 1) report self-synapses, print cell ID and annotation coordinates

%% Turn cell_list into a table (instead of struct) and order by cell type
%  Also rename cells to type-Letter

%reorder everything based on cell type
cell_listTable = struct2table(cell_list);
[sorted_list,sorted_list.origIx] = sortrows(cell_listTable,'type'); %,{'descend'});

conndata = zeros(height(sorted_list),height(sorted_list));
cellnameKey = [];

for i = 1:height(sorted_list)
    
    cellnameKey{i,1} = sorted_list.name{i};
    cellnameKey{i,2} = sorted_list.type{i};
    cellnameKey{i,3} = sorted_list.id(i);    
    
    if ~isempty(sorted_list.ps_partner_ix{i})
        for j = 1:length(sorted_list.ps_partner_ix{i})
            partnerMatrixIndex = find(sorted_list.origIx == sorted_list.ps_partner_ix{i}(j));
            conndata(i,partnerMatrixIndex) = conndata(i,partnerMatrixIndex) + 1;
        end
    end
    
end

% assign letter values to key name for each cell
cellnameKey{1,2} = [cellnameKey{1,2} '-A'];
sorted_list.newName{1} = cellnameKey{1,2};
cell_list(sorted_list.origIx(1)).newName = cellnameKey{1,2};
letterval = 65;
for i = 2:length(cellnameKey)
    if strcmpi(cellnameKey{i-1,2}(1:end-2),cellnameKey{i,2})
        letterval = letterval+1;
    else
        letterval = 65;
    end
    cellnameKey{i,2} = [cellnameKey{i,2} '-' char(letterval)];
    sorted_list.newName{i} = cellnameKey{i,2};
    cell_list(sorted_list.origIx(i)).newName = cellnameKey{i,2};
end

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
%node_names = string([cell_list.id]);
node_names = string({cell_list.newName});
G = digraph(presynapticNodes', postsynapticNodes', weights, node_names);
figure
plot(G,'Layout','force')
title('Node numbers correspond to segmentIDs')

%% Visualization 2
% use imagesc to heatmap

% use function: connectivityMap(conndata,cellnameKey,celltypeBorders,varargin)
% where
% conndata == matrix of connectivity data 
% cellnameKey == three column matrix of full cell name, letter-indexed
% name, and segment ID (must be aligned with order of conndata)

% variable args: 
% 'names' can be set to 'id,' 'segmentid' or 'segid' to use segment ID as 
% name in plot, default (any other arg) will use the key name
% 'unconnected' can be set to true to remove unconnected cells from plot
% 'include' can be set to include specific cell types, format must be as a
% set of strings in a cell: {'LG','LF','MG1','MG2'} default is all types.

fhandle = figure;
conndataInc = connectivityMap(conndata,cellnameKey,'names','id','unconnected',true,'color','hot','include',{'LF','LG','MG1','MG2'});
%conndataInc = connectivityMap(conndata,cellnameKey,'names','id','unconnected',true,'color','white');
set(gca,'Position',[0.18 0.03 0.7 0.8]);

%conndataB = connectivityMap(conndata,cellnameKey,'names','key','unconnected',false);

%% other stats
% how many synapses total?
totalSynapses = 0;
totalConnectedSynapses = 0;
nameDex = {'MPG';'NS';'DF';'SZM';'CL';'JS';'RA'};
%nameDex = ["mpg","ns","df","szm","cl"];
typeDex = unique(cell_listTable.type);
typeDexExt = cell(length(typeDex),1);
for i = 1:length(typeDex)
    typeDexExt(i,1) = {strcat(typeDex{i},'-seg')};
end
typeDexExt(end+1:end+2) = {'synapses';'connected synapses'};

nameStats = zeros(length(nameDex)+1,(length(typeDex)*2)+2);
%vartypes = 
%nameStatsTable = table('Size',[length(nameDex)+1 length(typeDex)],'VariableTypes',varTypes,'VariableNames',[('reconstructor');typeDex(:)]);

for i = 1:height(cell_listTable)
        
        % stats by user?
        assigned = 0;
        for j = 1:length(nameDex)
            if contains(cell_listTable.name{i}(end-7:end-5),nameDex{j},'IgnoreCase',true)
                rowname = j;
                assigned = 1;
            end    
        end
        if assigned == 0
            rowname = length(nameDex) + 1;
        end
        [logi,loca] = ismember(cell_listTable.type{i},typeDex);
        nameStats(rowname,loca) = nameStats(rowname,loca) + 1;
        nameStats(rowname,length(typeDex)+loca) = nameStats(rowname,length(typeDex)+loca) + length(cell_listTable.segments{i});
        
    if ~isempty(cell_listTable.ps_partner_segments{i})
        currSynNum = length(cell_listTable.ps_partner_segments{i});
        nameStats(rowname,(length(typeDex)*2)+1) = nameStats(rowname,(length(typeDex)*2)+1) + currSynNum;
        nameStats(rowname,(length(typeDex)*2)+2) = nameStats(rowname,(length(typeDex)*2)+2) + length(cell_listTable.ps_partner_ix{i});
        totalSynapses = totalSynapses + currSynNum;
        totalConnectedSynapses = totalConnectedSynapses + length(cell_listTable.ps_partner_ix{i});
    end 
end
%nameStats(nameStats == 0) = [];
fullnames = [typeDex;typeDexExt];
nameStatsTable = array2table(nameStats,'VariableNames',fullnames);
nameStatsTable.Reconstructor = [nameDex(:);('Unknown')];
nameStatsTable = movevars(nameStatsTable,'Reconstructor','Before',typeDex{1});
%%
% set(gca,'Position',[0.17 0.04 0.71 0.82]);
% text(-6.5,-2,sprintf('$\\frac{connected}{total synapses} = \\frac{%.f}{%.f}$',totalConnectedSynapses,totalSynapses),'Interpreter','latex','FontSize',18);
%% get interconnectedness level?
%  find reciprocal connections?
pairs = [];
for i = 1:length(conndata)
    currcell = conndata(i,:);
    if sum(currcell(:)) > 0
        connects = find(currcell);
        for j = 1:length(connects)
            checker = conndata(connects(j),:);
            if sum(checker(:)) > 0
                backcheck = find(checker);
                if ismember(i,backcheck)
                    pairs(end+1,1:2) = [i,connects(j)];
                    checkdoubles = sum(pairs(:,:) == [pairs(end,2),pairs(end,1)],2);
                    if max(checkdoubles) > 1
                        pairs(end,:) = [];
                    end
                end
            end
        end
    end
end
%
for i = 1:length(pairs)
    interconnections(i).cellA = sorted_list.id(pairs(i,1));
    interconnections(i).typeA = sorted_list.type(pairs(i,1));
    interconnections(i).segA = sorted_list.segments{pairs(i,1)};
    
    interconnections(i).cellB = sorted_list.id(pairs(i,2));
    interconnections(i).typeB = sorted_list.type(pairs(i,2));
    interconnections(i).segB = sorted_list.segments{pairs(i,2)};
end
%%

% what do do with the pre-synaptic labels?
