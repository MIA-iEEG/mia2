function varargout = process_mia_group_gui(varargin)
% process_mia_group_gui: Launch mia_group_gui from Brainstorm ROI files.
%
% Select in Process1 the matrix files produced by "MIA: Convert from BST to
% MIA" (they live under Group_analysis, one folder per condition) and run
% this process: mia_group_gui opens with one tab per selected condition.
%
% Nothing is written: this process only displays existing results, and hands
% its inputs back so it can be chained.

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    sProcess.Comment     = 'MIA: Visualize Averages';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'File';
    sProcess.Index       = 911;
    sProcess.Description = 'https://github.com/MIA-iEEG/mia2';

    % Input: the matrix files written by process_mia_bst2mia. Brainstorm
    % itself handles the selection, so this process needs no subject list.
    sProcess.InputTypes  = {'matrix'};
    sProcess.OutputTypes = {'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;

    sProcess.options.label1.Comment = [ ...
        '<BR>Select the MIA ROI files to visualize, under Group_analysis. <BR>' ...
        'They are produced by "MIA: Convert from BST to MIA", one per condition. <BR>' ...
        'Selecting several conditions opens one tab per condition, plus a Group tab <BR>' ...
        'comparing them: this requires all of them to hold the same ROIs. <BR>'];
    sProcess.options.label1.Type = 'label';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Pass the inputs through: this process displays, it does not create files
    OutputFiles = {sInputs.FileName};

    nCond = numel(sInputs);
    roisList  = cell(1, nCond);
    condNames = cell(1, nCond);
    filePaths = cell(1, nCond);

    % === STEP 1: LOAD THE MIA STRUCTURE OUT OF EACH SELECTED FILE ===
    for iCond = 1:nCond
        filePaths{iCond} = file_fullpath(sInputs(iCond).FileName);
        sMat = in_bst_matrix(filePaths{iCond});

        if ~isfield(sMat, 'mia_rois') || isempty(sMat.mia_rois)
            bst_report('Error', sProcess, sInputs(iCond), sprintf( ...
                ['This file holds no MIA ROI structure: %s\n' ...
                 'Only files produced by "MIA: Convert from BST to MIA" can be ' ...
                 'displayed here.'], sInputs(iCond).FileName));
            OutputFiles = {};
            return
        end

        roisList{iCond} = sMat.mia_rois;

        % The condition name is stored at conversion time; fall back on the
        % Brainstorm folder name for files written by an older version.
        if isfield(sMat, 'mia_condition') && ~isempty(sMat.mia_condition)
            condNames{iCond} = sMat.mia_condition;
        else
            condNames{iCond} = sInputs(iCond).Condition;
        end
    end

    % === STEP 2: CHECK THAT THE CONDITIONS SHARE THE SAME ROIS ===
    % mia_group_gui stacks the ROI arrays with vertcat, and
    % mia_display_table_rois then indexes rois_cond(:, selectedRows): column i
    % must be the same ROI in every condition, so differing ROI sets would
    % silently compare unrelated regions.
    errMsg = check_roi_alignment(roisList, condNames);
    if ~isempty(errMsg)
        bst_report('Error', sProcess, [], errMsg);
        OutputFiles = {};
        return
    end

    % === STEP 3: OPEN THE MIA GROUP INTERFACE ===
    % mia_group_gui expects its last argument as a single string, which it
    % splits back on '-' to title one tab per condition.
    assignin('base', 'mia_visualize_roi_paths',  filePaths);
    assignin('base', 'mia_visualize_conditions', condNames);

    mia_group_gui(roisList{:}, strjoin(condNames, '-'));

    bst_report('Info', sProcess, [], sprintf( ...
        'Opened MIA visualization for: %s', strjoin(condNames, ', ')));
end


%% ===== ROI ALIGNMENT CHECK =====
% Return an empty string when every condition holds the same ROIs in the same
% order, and a message describing the mismatch otherwise.
function errMsg = check_roi_alignment(roisList, condNames)
    errMsg = '';

    if numel(roisList) < 2
        return
    end

    refNames = roi_names(roisList{1});

    for iCond = 2:numel(roisList)
        curNames = roi_names(roisList{iCond});

        missing = setdiff(refNames, curNames, 'stable');
        extra   = setdiff(curNames, refNames, 'stable');

        if ~isempty(missing) || ~isempty(extra)
            errMsg = sprintf( ...
                ['Conditions "%s" and "%s" do not hold the same ROIs, they cannot ' ...
                 'be compared.\n'], condNames{1}, condNames{iCond});
            if ~isempty(missing)
                errMsg = [errMsg sprintf('Missing from "%s": %s\n', ...
                    condNames{iCond}, strjoin(missing, ', '))]; %#ok<AGROW>
            end
            if ~isempty(extra)
                errMsg = [errMsg sprintf('Only in "%s": %s\n', ...
                    condNames{iCond}, strjoin(extra, ', '))]; %#ok<AGROW>
            end
            errMsg = [errMsg 'Re-run the conversion on the same subjects for every condition.'];
            return

        elseif ~isequal(refNames, curNames)
            errMsg = sprintf( ...
                ['Conditions "%s" and "%s" hold the same ROIs but in a different ' ...
                 'order, which would compare unrelated regions.\n"%s": %s\n"%s": %s'], ...
                condNames{1}, condNames{iCond}, ...
                condNames{1},     strjoin(refNames, ', '), ...
                condNames{iCond}, strjoin(curNames, ', '));
            return
        end
    end
end


% Names of the ROIs held by one condition, in storage order
function names = roi_names(rois)
    names = cellfun(@(r) r.name, rois, 'UniformOutput', false);
end
