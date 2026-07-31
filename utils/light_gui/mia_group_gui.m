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
% This function creates a user interface to visualize sEEG data per regions
% of interest (ROI)
%
% USAGE :
%   mia_group_gui(rois1, rois2, ..., 'cond1-cond2-...')
%
%   One ROI structure per condition, then the condition names as a single
%   string joined with '-'. Requires R2020a or later (menus on uifigure).

function [] = mia_group_gui(varargin)

roisList  = varargin(1:nargin-1);
Condition = varargin{end};

rois_cond = vertcat(roisList{:});

MIA = mia_palette();

% Create UIFigure
UIFigure = uifigure('Name', sprintf('MIA GAnalysis : %s',Condition), ...
                    'Units','normalized', ...
                    'Position', [0.1 0 0.29 0.9], ...
                    'HandleVisibility', 'on', ...
                    'Color', MIA.background);

% ---- Menu bar ----
buildMenus(UIFigure);

% Set a layout manager on the whole figure
UIFigureLayout = uigridlayout(UIFigure, [1, 1]);
UIFigureLayout.RowHeight = {'1x'};
UIFigureLayout.ColumnWidth = {'1x'};
UIFigureLayout.BackgroundColor = MIA.background;

% Place the TabGroup inside the layout
TabGroup = uitabgroup(UIFigureLayout);
TabGroup.Layout.Row = 1;
TabGroup.Layout.Column = 1;

Condition = strsplit(Condition,'-');

% Prepare one tab per condition extracted
for iCond=1:size(rois_cond,1)

    % ---- Create one Tab per condition ----
    UITab = uitab(TabGroup, 'Title', Condition{iCond});

    % Create a main grid layout in the tab: 2 rows (table + buttons)
    MainLayout = uigridlayout(UITab, [2, 1]);
    MainLayout.RowHeight = {'1x', 50};  % Table fills, button row is 50px
    MainLayout.ColumnWidth = {'1x'};
    MainLayout.BackgroundColor = MIA.background;
    UITab.BackgroundColor = MIA.background;

    mia_display_table_rois(MainLayout, rois_cond(iCond,:), Condition{iCond})

end

% ---- Create a Tab with all group of tabs ----
UITab = uitab(TabGroup, 'Title', 'Group');

% Create a main grid layout in the tab: 2 rows (table + buttons)
MainLayout = uigridlayout(UITab, [2, 1]);
MainLayout.RowHeight = {'1x', 50};  % Table fills, button row is 50px
MainLayout.ColumnWidth = {'1x'};
MainLayout.BackgroundColor = MIA.background;
UITab.BackgroundColor = MIA.background;

mia_display_table_rois(MainLayout, rois_cond, Condition)


%% ===== MENUS =====
    function buildMenus(fig)
        m = uimenu(fig, 'Text', 'File');
        uimenu(m, 'Text', 'Load ROI structure...', ...
                  'MenuSelectedFcn', @(~,~) loadRoiStructure());
        % Figures opened from the tables are closed by the "Close figs" button
        % of each tab, which only touches the ones it opened itself.
        uimenu(m, 'Text', 'Close this window', 'Separator', 'on', ...
                  'MenuSelectedFcn', @(~,~) delete(fig));

        m = uimenu(fig, 'Text', 'Tools');
        uimenu(m, 'Text', 'Open the MIA interface', ...
                  'MenuSelectedFcn', @(~,~) openMiaInterface());

        m = uimenu(fig, 'Text', 'Help');
        uimenu(m, 'Text', 'Online tutorials', ...
                  'MenuSelectedFcn', @(~,~) web('https://mia-ieeg.github.io/mia2/tutorial/', '-browser'));
        uimenu(m, 'Text', 'Github repository', ...
                  'MenuSelectedFcn', @(~,~) web('https://github.com/MIA-iEEG/mia2', '-browser'));
        uimenu(m, 'Text', 'About MIA', 'Separator', 'on', ...
                  'MenuSelectedFcn', @(~,~) uialert(UIFigure, sprintf( ...
                      ['MIA %s\nMulti-patient Intracranial EEG Analysis\n\n' ...
                       'Copyright (C) 2012-2026 CNRS - Universite Aix-Marseille\n' ...
                       'Distributed under the GNU GPL v3.'], miaVersion()), ...
                      'About MIA', 'Icon', 'info'));
    end


%% ===== LOAD ANOTHER ROI STRUCTURE =====
% Add a condition to the window from a file on disk: either a plain .mat
% holding a "rois" variable, or a Brainstorm matrix file written by
% process_mia_bst2mia, which carries the same structure in mia_rois.
    function loadRoiStructure()
        [fileName, filePath] = uigetfile( ...
            {'*.mat', 'MIA ROI structure (*.mat)'}, 'Load a ROI structure');
        if isequal(fileName, 0)
            return
        end
        fullName = fullfile(filePath, fileName);

        loaded = load(fullName);
        if isfield(loaded, 'mia_rois')
            newRois = loaded.mia_rois;
        elseif isfield(loaded, 'rois')
            newRois = loaded.rois;
        else
            uialert(UIFigure, sprintf( ...
                ['This file holds neither a "rois" nor a "mia_rois" variable:\n%s\n\n' ...
                 'Expected a ROI structure saved by MIA.'], fullName), ...
                'Unusable file');
            return
        end

        if isempty(newRois)
            uialert(UIFigure, 'This file holds no ROI.', 'Empty structure');
            return
        end

        % Name the new condition after the file, unless it carries its own
        if isfield(loaded, 'mia_condition') && ~isempty(loaded.mia_condition)
            newName = loaded.mia_condition;
        else
            [~, newName] = fileparts(fileName);
        end
        % '-' separates conditions in the window title, so it cannot appear
        newName = strrep(newName, '-', '_');

        % The tables are compared column by column: same ROIs, same order
        refNames = cellfun(@(r) r.name, roisList{1}, 'UniformOutput', false);
        newNames = cellfun(@(r) r.name, newRois,     'UniformOutput', false);
        if ~isequal(refNames, newNames)
            missing = setdiff(refNames, newNames, 'stable');
            extra   = setdiff(newNames, refNames, 'stable');
            msg = sprintf(['The ROIs of this file do not match the conditions ' ...
                           'already displayed, they cannot be compared.\n\n']);
            if ~isempty(missing)
                msg = [msg sprintf('Missing: %s\n', strjoin(missing, ', '))];
            end
            if ~isempty(extra)
                msg = [msg sprintf('Only in the file: %s\n', strjoin(extra, ', '))];
            end
            if isempty(missing) && isempty(extra)
                msg = [msg 'Same ROIs, but stored in a different order.'];
            end
            uialert(UIFigure, msg, 'ROIs do not match');
            return
        end

        % Rebuild the window with the extra condition
        newCondition = strjoin([Condition, {newName}], '-');
        delete(UIFigure);
        mia_group_gui(roisList{:}, newRois, newCondition);
    end


%% ===== OPEN THE HISTORICAL MIA INTERFACE =====
% MIA used to be driven by its own main window; MIA2 goes through Brainstorm
% instead. That window still ships with this toolbox, for users who prefer it.
    function openMiaInterface()
        if isempty(which('mia'))
            uialert(UIFigure, ...
                ['The MIA interface was not found on the Matlab path.' newline ...
                 'Run start_brainstorm, which adds the whole toolbox to the path.'], ...
                'Interface not found');
            return
        end
        mia;
    end


%% ===== VERSION STRING, WITHOUT FAILING IF UNAVAILABLE =====
    function v = miaVersion()
        try
            v = mia_get_version();
        catch
            v = '(version unknown)';
        end
    end

end
