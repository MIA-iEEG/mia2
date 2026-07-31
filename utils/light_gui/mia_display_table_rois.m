% ========================================================================
% This file is part of MIA.
% 
% MIA is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% MIA is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%  
% Copyright (C) 2012-2026 CNRS - Universite Aix-Marseille
%
% ========================================================================
% This software was developed by
%       Anne-Sophie Dubarry (CNRS Universite Aix-Marseille)
% 
    
function mia_display_table_rois(varargin)
% MIA GAnalysis UI in function form instead of App class
MainLayout = varargin{1};

rois = varargin{2};
Condition = varargin{3};
rois_cond = [];
if size(rois,1) ~= 1
    rois_cond = rois;
    rois = rois(1,:);
end

% Store ROIs data
if isstruct(rois)
    roisData = {rois};
else
    roisData = rois;
end

hdispAll = [];  % Store all figure handles to be closed later

% === Create UITable in first row of MainLayout ===
MIA = mia_palette();

% Header order must follow the order the columns are filled in below:
% name, number of patients, number of electrodes, then the two correlations.
% Setting ColumnName here overrides the VariableNames given to the table, so
% the two lists have to agree.
UITable = uitable(MainLayout, ...
    'ColumnName', {'ROI Name', 'Npt', 'Nelec', 'Rp', 'Rc'}, ...
    'ColumnEditable', false(1,5), ...
    'ColumnWidth', {'auto', 70, 70, 80, 80}, ...
    'RowStriping', 'on', ...
    'MultiSelect', 'on', ...
    'ForegroundColor', MIA.text, ...
    'BackgroundColor', [MIA.surface; MIA.background]);

UITable.Layout.Row = 1;
UITable.Layout.Column = 1;

% === Create button layout in second row of MainLayout ===
ButtonLayout = uigridlayout(MainLayout, [1, 5]);  % 1 row, 5 columns
ButtonLayout.Layout.Row = 2;
ButtonLayout.Layout.Column = 1;
ButtonLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};

% Populate Table
if ~isempty(roisData)
    numROIs = length(roisData);
    tableData = cell(numROIs, 5);
    for i = 1:numROIs
        tableData{i,1} = roisData{i}.name;
        tableData{i,2} = length(roisData{i}.namePt);
        tableData{i,3} = size(roisData{i}.Fmask,2);
        tableData{i,4} = roisData{i}.corrPt;
        tableData{i,5} = roisData{i}.corrChan;
    end
    UITable.Data = cell2table(tableData, 'VariableNames', {'ROI Name', 'Npt', 'Nelec','Rp', 'Rc'});
    UITable.ColumnSortable = true;
end

% Callback for selection
UITable.CellSelectionCallback = @(src, event) selectRows(src, event);

% --- Create Buttons ---
% Terracotta for the main action, warm cream for the secondary ones, gold for
% the action that compares conditions: colour tells the actions apart instead
% of decorating them.
ROIButton = uibutton(ButtonLayout, 'Text', 'ROI panel', ...
    'FontSize', 12, ...
    'Enable', 'on', ...
    'BackgroundColor', MIA.primary, 'FontColor', MIA.onPrimary, ...
    'ButtonPushedFcn', @(btn, event) showROIInfo());

ROIavgButton = uibutton(ButtonLayout, 'Text', 'ROIs Gd Ave', ...
    'FontSize', 12, ...
    'BackgroundColor', MIA.backgroundAlt, 'FontColor', MIA.text, ...
    'ButtonPushedFcn', @(btn, event) showROIavg());

ROIVariousCondButton = uibutton(ButtonLayout, 'Text', 'Group ROI:Timeseries', ...
    'FontSize', 12, ...
    'Enable', 'off', ...
    'BackgroundColor', MIA.gold, 'FontColor', MIA.onGold, ...
    'ButtonPushedFcn', @(btn, event) display_various_conditions());

CloseAllButton = uibutton(ButtonLayout, 'Text', 'Close figs', ...
    'FontSize', 12, ...
    'BackgroundColor', MIA.backgroundAlt, 'FontColor', MIA.textMuted, ...
    'ButtonPushedFcn', @(btn, event) closeFigures());

if ~isempty(rois_cond)
     % set(ROIAvgCondButton, 'Enable', 'on');
     set(ROIVariousCondButton, 'Enable', 'on');
 end

% --- Callback Functions ---
function selectRows(src, event)
    if ~isempty(event.Indices)
        selectedRows = unique(event.Indices(:,1));
        numColumns = size(UITable.Data, 2);
        UITable.Selection = cell2mat(arrayfun(@(row) [row * ones(numColumns,1), (1:numColumns)'], selectedRows, 'UniformOutput', false));
    end
end

function closeFigures()
    if ~isempty(hdispAll)
        validHandles = isgraphics(hdispAll, 'figure');
        close(hdispAll(validHandles));
        hdispAll = [];  % Clear the list after closing
    end
end

function showROIInfo()
    idx = UITable.Selection;
    if isempty(idx)
        uialert(UITable, 'Please select at least one ROI from the table.', 'No Selection');
        return;
    end
    selectedRows = unique(idx(:,1));

    if ~isempty(rois_cond)
        selectedROIs = mia_n_to_one_roi(rois_cond(:,selectedRows), strjoin(Condition, '-'));
        dOPTIONS.Condition = strjoin(Condition, '-');
    else
         selectedROIs = cell(1, length(selectedRows));
         dOPTIONS.Condition = Condition;
   
    end
     for i = 1:length(selectedRows)
        selectedROIs{i} = roisData{selectedRows(i)};
    end
    maxNbPt = max(cellfun(@(x) max(x.idPt), roisData));
    dOPTIONS.clr = jet(maxNbPt);
    dOPTIONS.win_noedges = [-0.2, 0.6];
    h = mia_display_roi(selectedROIs, dOPTIONS);
    hdispAll = [hdispAll; h(:)];
end

function showROIavg()
    idx = UITable.Selection;
    if isempty(idx)
        uialert(UITable, 'Please select at least one ROI from the table.', 'No Selection');
        return;
    end
    selectedRows = unique(idx(:,1));
    selectedROIs = cell(1, length(selectedRows));
    for i = 1:length(selectedRows)
        selectedROIs{i} = roisData{selectedRows(i)};
    end
    dOPTIONS.clr = jet(length(selectedRows));
    dOPTIONS.win_noedges = [-0.2, 0.6];
    pOPTIONS.thresh = 1.96;
    pOPTIONS.threshdisp = 1.96;
    pOPTIONS.nsub = 1;
    pOPTIONS.title = '';
    [~, ~] = mia_display_summary_roi(selectedROIs, pOPTIONS);
end

function display_avg_conditions()
    idx = UITable.Selection;
    if isempty(idx)
        uialert(UITable, 'Please select at least one ROI from the table.', 'No Selection');
        return;
    end
    selectedRows = unique(idx(:,1));
    selectedROIs = mia_n_to_one_roi(rois_cond(:,selectedRows), strjoin(Condition, '-'));
    dOPTIONS.Condition = strjoin(Condition, '-');
    maxNbPt = max(cellfun(@(x) max(x.idPt), roisData));
    dOPTIONS.clr = jet(maxNbPt);
    dOPTIONS.win_noedges = [-0.2, 0.6];
    h = mia_display_roi(selectedROIs, dOPTIONS);
    hdispAll = [hdispAll; h(:)];
end

function display_various_conditions()
    idx = UITable.Selection;
    if isempty(idx)
        uialert(UITable, 'Please select at least one ROI from the table.', 'No Selection');
        return;
    end
    selectedRows = unique(idx(:,1));
    selectedROIs = mia_n_to_one_roi(rois_cond(:,selectedRows), strjoin(Condition, '-'));
    maxCond = size(selectedROIs{1}.signmoyAll, 1);
    dOPTIONS.clr = jet(maxCond);
    dOPTIONS.win_noedges = [-0.2, 0.6];
    dOPTIONS.Condition = strjoin(Condition, '-');
    h = mia_display_roi_conditions(selectedROIs, dOPTIONS);
    hdispAll = [hdispAll; h(:)];
end

end

