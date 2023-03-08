
%% function to generate connectivity map

% conndata == matrix of connectivity data 
% cellnameKey == three column matrix of full cell name, letter-indexed
% name, and segment ID (must be aligned with order of conndata)

% variable args: 
% 'names' can be set to 'id,' 'segmentid' or 'segid' to use segment ID as 
% name in plot, default (any other arg) will use the key name
% 'unconnected' can be set to true to remove unconnected cells from plot
% 'include' can be set to include specific cell types, format must be as a
% set of strings in a cell: {'LG','LF','MG1','MG2'} default is all types.

function conndataInc = connectivityMap(conndata,cellnameKey,varargin)


s.names = 'index';
s.unconnected = false;
s.color = 'hot';
s.include = {'all'};

if exist('varargin', 'var'); for i = 1:2:length(varargin); s.(varargin{i}) = varargin{i+1}; end; end

if s.unconnected
    conndataInc = [];
    cellnameKeyInc = {};
    remGroup = [];
    removeColumns = [];
    for i = 1:length(conndata)
        if sum(conndata(i,:)) ~= 0 || sum(conndata(:,i)) ~= 0
            conndataInc(end+1,:) = conndata(i,:);
            cellnameKeyInc(end+1,:) = cellnameKey(i,:);
        else
            removeColumns(end+1) = i;
%             if i < length(conndata)
%                 remGroup(end+1) = min(celltypeBorders(celltypeBorders > i));
%             end
        end
    end
    conndataInc(:,removeColumns) = [];
%     celltypeBordersInc = celltypeBorders(1:end) - (sum(remGroup(:) == celltypeBorders(1)));
%     for i = 2:length(celltypeBorders)
%         celltypeBordersInc(i:end) = celltypeBordersInc(i:end) - (sum(remGroup(:) == celltypeBorders(i)));
%     end
%     
    conndata = conndataInc;
    cellnameKey = cellnameKeyInc;
    
end

%%

if ~strcmpi(s.include{1},'all')
    
    conndataInc = [];
    cellnameKeyInc = {};
    remGroup = [];
    removeColumns = [];
    
    for i = 1:length(cellnameKey)
        
        if sum(strcmpi(cellnameKey{i,2}(1:end-2),s.include)) > 0
            conndataInc(end+1,:) = conndata(i,:);
            cellnameKeyInc(end+1,:) = cellnameKey(i,:);
        else
            removeColumns(end+1) = i;
        end
        
    end
    conndataInc(:,removeColumns) = [];

    conndata = conndataInc;
    cellnameKey = cellnameKeyInc;
     
end


%%
%get shortest name
shortestNameLength = length(cellnameKey{1,2});
for i = 2:length(cellnameKey)
    if length(cellnameKey{i,2}) < shortestNameLength
        shortestNameLength = length(cellnameKey{i,2});
    end
end
tail = shortestNameLength - 2;

celltypeBorders = [];
for i = 2:length(cellnameKey)
    if ~strcmpi(cellnameKey{i-1,2}(1:end-tail),cellnameKey{i,2}(1:end-tail))
        celltypeBorders(end+1) = i;
    end
end

%%

if strcmpi(s.names,'id') || strcmpi(s.names,'segmentid') || strcmpi(s.names,'segid')
    useName = string([cellnameKey{:,3}]);
else
    useName = cellnameKey(:,2);
end

x = [1 length(cellnameKey)];
y = [1 length(cellnameKey)];

if strcmpi(s.color,'cool') || strcmpi(s.color,'inverse') || strcmpi(s.color,'white')
    colormap(flipud(hot(max(max(conndata)) + 1)));
    lineCol = [0 0 0];   
else
    colormap((hot(max(max(conndata)) + 1)));
    lineCol = [0.7 0.7 0.7];
end

imagesc(x,y,conndata);

for i = 1:length(celltypeBorders)
    hold on;
    plot([celltypeBorders(i)-0.5 celltypeBorders(i)-0.5],[0.5 length(cellnameKey) + 0.5],'Color',lineCol); 
    hold on;
    plot([0.5 length(cellnameKey) + 0.5],[celltypeBorders(i)-0.5 celltypeBorders(i)-0.5],'Color',lineCol); 
end

xticks(1:length(useName));
yticks(1:length(useName));
xticklabels(useName);
yticklabels(useName);
set(gca,'XAxisLocation','top')
box off;
colorbar;
h = colorbar('Ticks',[0 max(max(conndata))]);
titl = 'Connectivity map';

h.Label.String = 'Number of synapses';
%xlabel('post-synaptic partner')
%ylabel('pre-synaptic partner')
yp1 = -2.5;

if strcmpi(s.names,'id') || strcmpi(s.names,'segmentid') || strcmpi(s.names,'segid')
    L2 = {cellnameKey{1,2}(1:end-tail)};
    for i = 1:length(celltypeBorders)
        L2(end+1) = {cellnameKey{celltypeBorders(i),2}(1:end-tail)};
    end
    % Positions for text
    xp1 = -7;
    yp1 = -7;
    
    set(gca,'Position',[0.18 0.03 0.7 0.8]); % Make space for labels
    % Insert text labels
    text((((celltypeBorders(1)-1)+1)/2),yp1,L2(1),'HorizontalAlignment','center');
    text(xp1,(((celltypeBorders(1)-1)+1)/2),L2(1));
    for i = 2:length(L2)-1
        text((((celltypeBorders(i)-1)+celltypeBorders(i-1))/2),yp1,L2(i),'HorizontalAlignment','center');
        text(xp1,(((celltypeBorders(i)-1)+celltypeBorders(i-1))/2),L2(i));
    end
    text(((length(conndata)+celltypeBorders(end))/2),yp1,L2(end),'HorizontalAlignment','center');
    text(xp1,((length(conndata)+celltypeBorders(end))/2),L2(end));
    
    
end

set(gca,'Position',[0.18 0.03 0.7 0.8]);
text((length(conndata)+1)/2,yp1-2,titl,'FontSize',12,'FontWeight','bold','HorizontalAlignment','center');

end

