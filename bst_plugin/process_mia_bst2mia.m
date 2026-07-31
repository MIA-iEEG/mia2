function varargout = process_mia_bst2mia(varargin)
% process_mia_bst2mia: Run mia_bst2mia from the Brainstorm pipeline.
%
% Drop the condition folders of several subjects in Process1: every distinct
% condition found in the selection is converted to MIA format, averaged over
% the dropped subjects, and saved as a "matrix" file under the group analysis
% subject (Group_analysis), in a folder named after the condition.
%
% Those files are what process_mia_group_gui expects: select them in Process1
% and run "MIA: Visualize Averages" to open mia_group_gui on them.
%
% Options:
%   Labeling table   - Full path to the TSV labeling table
%   Channel subject  - Subject whose channel.mat describes the group montage
%   ROI column       - Name of the TSV column holding the anatomical labels
%   Subjects to skip - Comma-separated subject names to exclude
%

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
% GetDescription: Define the Brainstorm process options and UI elements
% This function configures how the plugin appears and functions within Brainstorm's process pipeline
function sProcess = GetDescription() %#ok<DEFNU>
    % === BASIC PROCESS METADATA ===
    sProcess.Comment     = 'MIA: Export data to MIA2';  % Display name in Brainstorm menu
    sProcess.Category    = 'Custom';                       % Category in process list
    sProcess.SubGroup    = 'File';                          % Sub-category grouping
    sProcess.Index       = 983;                             % Menu index/ordering
    sProcess.Description = 'https://github.com/MIA-iEEG/mia2';  % Link to documentation

    % === PROCESS I/O CONFIGURATION ===
    sProcess.InputTypes  = {'data'};        % Input type: recordings dropped in Process1
    sProcess.OutputTypes = {'matrix'};      % Output type: matrix data structure
    sProcess.nInputs     = 1;               % Number of inputs required
    sProcess.nMinFiles   = 1;               % Require at least one dropped file/folder in Process1

    % === TSV LABELING TABLE FILE BROWSER ===
    % File browser to select the channel/electrode labeling table
    SelectTSV = { ...
    '', ...                  % Default path (empty = current directory)
    'files', ...             % Selection mode: files only
    { ...
        '(*.tsv) TSV files (*.tsv)', '*.tsv'; ...    % File filter for TSV files
        'All files (*.*)', '*.*' ...                 % Allow any file type
    }, ...
    'DataIn'};               % Starting directory (data input folder)

    sProcess.options.tsvfile.Comment = 'Labeling table (TSV): ';  % Label
    sProcess.options.tsvfile.Type    = 'filename';               % UI element type
    sProcess.options.tsvfile.Value   = SelectTSV;                % File browser configuration

    % === SUBJECT USED TO RESOLVE GROUP CHANNEL FILE ===
    % Left blank, the group subject is detected automatically: it is the one
    % holding a channel file whose contacts are named Subject__Contact (see
    % process_mia_channel_concat), and the most recent one wins.
    % A 'subjectname' dropdown cannot help here: Brainstorm forces it to the
    % subject of the dropped files, which is never the group subject.
    sProcess.options.channelsubject.Comment = ...
        'Channel subject (blank = last group subject created): ';
    sProcess.options.channelsubject.Type    = 'text';
    sProcess.options.channelsubject.Value   = '';

    % === ATLAS COLUMN OF THE LABELING TABLE ===
    % Free text rather than a dropdown: the available columns depend on the
    % TSV picked above, which is not known when this description is built.
    sProcess.options.atlas.Comment = 'Name of the column to define ROI: ';
    sProcess.options.atlas.Type    = 'text';
    sProcess.options.atlas.Value   = 'localisation_lectrodes';

    % === SUBJECT EXCLUSION LIST INPUT ===
    % Text field for specifying subjects to skip during conversion
    sProcess.options.excludesubs.Comment = ...
        'Subjects to exclude (comma-separated, leave blank = use all): ';  % Label with usage hint
    sProcess.options.excludesubs.Type  = 'text';     % UI element type
    sProcess.options.excludesubs.Value = '';         % Default: empty (process all subjects)

    % === HELP TEXT AT THE BOTTOM
    sProcess.options.label1.Comment = [ ...
        '<BR>Drop the condition folders of several subjects: every distinct condition is converted. <BR>' ...
        'Results are saved as matrix files under Group_analysis, one folder per condition, <BR>' ...
        'ready to be selected and displayed with "MIA: Visualize Averages". <BR>' ...
        'Leave "Channel subject" blank to use the group channel file created by "MIA: Concatenate channels"; <BR>' ...
        'name a subject only to override that choice. Provide the matching .tsv labelling table. <BR>' ...
        'The ROI column is the header of the .tsv column holding the anatomical labels. <BR>' ...
        'Subjects to exclude can be listed separated by commas. <BR>' ...
    ];

    sProcess.options.label1.Type = 'label';

end


%% ===== FORMAT COMMENT =====
% FormatComment: Return the process display name
% This function is called by Brainstorm to get the text displayed in the process list
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Simply return the process comment/name defined in GetDescription
    Comment = sProcess.Comment;
end


%% ===== RUN =====
% Run: Main execution function called by Brainstorm pipeline
% Reads user inputs, validates them, and executes the MIA conversion
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};  % Initialize empty output (will be populated if successful)

    % === STEP 1: EXTRACT USER-SELECTED OPTIONS FROM BRAINSTORM GUI ===
    % Subjects and conditions both come from what was dropped in Process1:
    % the user can select condition folders from several subjects at once.
    prot = bst_get('ProtocolInfo');
    ProtocolName = strtrim(prot.Comment);
    condList = unique(strtrim({sInputs.Condition}),   'stable');
    subjList = unique(strtrim({sInputs.SubjectName}), 'stable');
    TSVFile    = sProcess.options.tsvfile.Value{1};                % Path to TSV labeling table
    Atlas      = strtrim(sProcess.options.atlas.Value);            % TSV column holding the ROI labels
    ExcludeRaw = strtrim(sProcess.options.excludesubs.Value);      % Comma-separated subject list

    % Blank field: look for the group channel file across the whole protocol,
    % which is what the user wants right after running the concatenation.
    %
    % Brainstorm remembers option values across sessions, so this field can
    % still hold a stale name. Group_analysis in particular is the subject MIA
    % writes its own results into: it never holds a channel file, so treat it
    % as if the field were empty.
    ChannelSubject = strtrim(sProcess.options.channelsubject.Value);
    if strcmpi(ChannelSubject, bst_get('NormalizedSubjectName'))
        ChannelSubject = '';
    end

    ChanFile = '';
    if ~isempty(ChannelSubject)
        ChanFile = resolve_subject_channel_file(prot, ChannelSubject);
        if isempty(ChanFile)
            bst_report('Warning', sProcess, [], sprintf( ...
                ['No channel file under subject "%s": falling back on the last ' ...
                 'group channel file created.'], ChannelSubject));
            ChannelSubject = '';
        end
    end
    if isempty(ChanFile)
        [ChanFile, ChannelSubject] = find_group_channel_file(sProcess, prot);
    end

    % === STEP 2: VALIDATE ALL MANDATORY INPUTS ===
    % Check that required parameters are provided and accessible
    if isempty(ProtocolName)
        bst_report('Error', sProcess, [], 'Protocol name is empty.');
        return  % Exit early if validation fails
    end
    condList(cellfun(@isempty, condList)) = [];
    if isempty(condList)
        bst_report('Error', sProcess, [], 'No condition found in the dropped files.');
        return  % Exit early if validation fails
    end
    % mia_group_gui joins condition names with '-' and splits them back, so a
    % name containing '-' would be torn apart when visualizing the results.
    isBadName = contains(condList, '-');
    if any(isBadName)
        bst_report('Error', sProcess, [], sprintf( ...
            ['Condition names must not contain "-", which MIA uses to separate\n' ...
             'conditions when visualizing them: %s'], strjoin(condList(isBadName), ', ')));
        return
    end
    if isempty(TSVFile) || ~exist(TSVFile, 'file')
        bst_report('Error', sProcess, [], 'TSV labeling table not found.');
        return  % Exit early if validation fails
    end
    if isempty(Atlas)
        bst_report('Error', sProcess, [], ...
            'Name of the column to define ROI is empty.');
        return
    end
    if isempty(ChanFile) || ~exist(ChanFile, 'file')
        if isempty(ChannelSubject)
            bst_report('Error', sProcess, [], ...
                ['No group channel file found in this protocol. Run ' ...
                 '"MIA: Concatenate channels" first, or name the subject ' ...
                 'holding the channel file in the options.']);
        else
            bst_report('Error', sProcess, [], ...
                sprintf('Channel file not found for subject "%s".', ChannelSubject));
        end
        return  % Exit early if validation fails
    end
    bst_report('Info', sProcess, [], sprintf('Group channel file: %s', ChanFile));

    % === STEP 3: PARSE SUBJECT EXCLUSION LIST ===
    % Convert comma-separated string into a cell array for processing
    if isempty(ExcludeRaw)
        % If no subjects specified, process all subjects
        SubjectsToSkip = {};
    else
        % Split on commas and remove whitespace from each subject name
        SubjectsToSkip = strtrim(strsplit(ExcludeRaw, ','));
        % Remove any empty entries that may have been created
        SubjectsToSkip(cellfun(@isempty, SubjectsToSkip)) = [];
    end

    % Log the subjects being skipped to Brainstorm report
    bst_report('Info', sProcess, [], ...
        sprintf('Subjects to skip: %s', strjoin(SubjectsToSkip, ', ')));

    bst_report('Info', sProcess, [], sprintf('Subjects to process: %s', ...
        strjoin(setdiff(subjList, SubjectsToSkip, 'stable'), ', ')));

    % === STEP 4: CONVERT EACH DROPPED CONDITION ===
    % Signature: mia_bst2mia(Condition, ProtocolName, LabelingTable, GroupChannelFile, ...)
    % followed by optional name-value pairs ('Subjects', 'SubjectsToSkip', 'Atlas').
    % One condition failing must not cancel the others, hence the try/catch
    % inside the loop.
    for iCond = 1:numel(condList)
        Condition = condList{iCond};

        try
            rois = mia_bst2mia( ...
                Condition, ...           % Experimental condition to process
                ProtocolName, ...        % Brainstorm protocol name
                TSVFile, ...             % Path to labeling/electrode table
                ChanFile, ...            % Path to group channel file
                'Subjects', subjList, ...             % Subjects taken from the drop
                'SubjectsToSkip', SubjectsToSkip, ... % Subjects to exclude
                'Atlas', Atlas);         % TSV column holding the ROI labels

        catch ME
            bst_report('Error', sProcess, [], sprintf( ...
                'mia_bst2mia failed on condition "%s": %s', Condition, ME.message));
            continue  % Move on to the next condition
        end

        % === STEP 5: SAVE THE RESULT UNDER THE GROUP ANALYSIS SUBJECT ===
        NewFile = save_group_rois(sProcess, rois, Condition);
        if ~isempty(NewFile)
            OutputFiles{end+1} = NewFile; %#ok<AGROW>
            bst_report('Info', sProcess, [], sprintf( ...
                'Condition "%s": %d ROI(s) saved.', Condition, numel(rois)));
        end
    end
end


%% ===== SAVE ROIS AS A GROUP MATRIX FILE =====
% Store the MIA ROI structure as a Brainstorm "matrix" file, in a condition
% named after the MIA condition, under the group analysis subject. The full
% MIA structure travels in the mia_rois field so process_mia_group_gui can
% read it back untouched; Value/Time/Description only exist so the file can
% also be displayed with the standard Brainstorm viewers.
function OutputFile = save_group_rois(sProcess, rois, Condition)
    OutputFile = '';

    if isempty(rois)
        bst_report('Warning', sProcess, [], sprintf( ...
            'Condition "%s" produced no ROI: nothing was saved.', Condition));
        return
    end

    % Group analysis subject, created on the fly if this protocol has none yet
    SubjectName = bst_get('NormalizedSubjectName');
    sProtocolSubjects = bst_get('ProtocolSubjects');
    knownSubjects = {};
    if ~isempty(sProtocolSubjects) && ~isempty(sProtocolSubjects.Subject)
        knownSubjects = {sProtocolSubjects.Subject.Name};
    end
    if ~ismember(SubjectName, knownSubjects)
        db_add_subject(SubjectName, [], 1, 1);
    end

    % Returns the existing study when the condition is already there
    iStudy = db_add_condition(SubjectName, Condition, 0);
    if isempty(iStudy)
        bst_report('Error', sProcess, [], sprintf( ...
            'Could not create condition "%s" under %s.', Condition, SubjectName));
        return
    end
    sStudy = bst_get('Study', iStudy);

    % One row per (ROI, subject): signmoy is nTime x nSubject
    Value = [];
    Description = {};
    for iRoi = 1:numel(rois)
        r = rois{iRoi};

        if numel(r.namePt) ~= size(r.signmoy, 2)
            bst_report('Error', sProcess, [], sprintf( ...
                ['ROI "%s": %d subject name(s) for %d averaged signal(s). ' ...
                 'Refusing to save a misaligned file.'], ...
                r.name, numel(r.namePt), size(r.signmoy, 2)));
            return
        end

        Value = cat(1, Value, r.signmoy');
        for iSubj = 1:numel(r.namePt)
            Description{end+1, 1} = sprintf('%s | %s', r.name, r.namePt{iSubj}); %#ok<AGROW>
        end
    end

    sMat = db_template('matrixmat');
    sMat.Value         = Value;
    sMat.Time          = rois{1}.t;
    sMat.Description   = Description;
    sMat.Comment       = sprintf('MIA ROIs | %s', Condition);
    sMat.mia_rois      = rois;        % full MIA structure, read back as is
    sMat.mia_condition = Condition;

    OutputFile = bst_process('GetNewFilename', ...
        bst_fileparts(sStudy.FileName), 'matrix_mia_rois');
    bst_save(OutputFile, sMat, 'v6');
    db_add_data(iStudy, OutputFile, sMat);
    panel_protocols('UpdateNode', 'Study', iStudy);
end


% Find the group channel file anywhere in the protocol, without knowing which
% subject holds it. Group files are the ones naming their contacts
% Subject__Contact, written by process_mia_channel_concat; when several exist
% (the concatenation was run more than once) the most recent one wins, which
% is the subject the user has just created.
function [ChanFile, SubjectName] = find_group_channel_file(sProcess, prot)
    ChanFile = '';
    SubjectName = '';

    if isempty(prot) || ~isfield(prot, 'STUDIES') || isempty(prot.STUDIES)
        return
    end

    candidates = dir(fullfile(prot.STUDIES, '*', '*', 'channel.mat'));
    candidates = candidates(~[candidates.isdir]);

    isGroup = false(1, numel(candidates));
    for iFile = 1:numel(candidates)
        chan = load(fullfile(candidates(iFile).folder, candidates(iFile).name), 'Channel');
        isGroup(iFile) = isfield(chan, 'Channel') && ~isempty(chan.Channel) && ...
            any(contains({chan.Channel.Name}, '__'));
    end
    candidates = candidates(isGroup);

    if isempty(candidates)
        return
    end

    % Most recently written first
    [~, iSort] = sort([candidates.datenum], 'descend');
    candidates = candidates(iSort);

    ChanFile = fullfile(candidates(1).folder, candidates(1).name);

    % <STUDIES>/<subject>/<condition>/channel.mat: the subject is two levels up
    SubjectName = get_path_part(candidates(1).folder, 2);

    if numel(candidates) > 1
        others = arrayfun(@(c) get_path_part(c.folder, 2), candidates(2:end), ...
            'UniformOutput', false);
        bst_report('Warning', sProcess, [], sprintf( ...
            ['Several group channel files found: using the most recent one, from ' ...
             'subject "%s".\nOther candidates: %s\nName a subject in the options ' ...
             'to pick another one.'], SubjectName, strjoin(others, ', ')));
    end
end


% Name of the folder situated nLevels above a full path
function name = get_path_part(fullPath, nLevels)
    name = fullPath;
    for iLevel = 1:nLevels-1
        name = fileparts(name);
    end
    [~, name] = fileparts(name);
end


% Find the group channel.mat of the selected subject inside the current
% protocol studies directory.
%
% Any study folder of the subject may hold a channel.mat, and several usually
% do: the one we want is the group file written by process_mia_channel_concat,
% recognisable because it names its contacts Subject__Contact. The others hold
% the generic channels of the simulated signal (s1, s2, s3...), which match
% nothing. Folder names cannot be relied on: import_raw names them after the
% simulated file and the @rawmatrix folder is deleted at the end of the
% concatenation.
function ChanFile = resolve_subject_channel_file(prot, subjectName)
    ChanFile = '';

    if isempty(subjectName) || isempty(prot) || ~isfield(prot, 'STUDIES') || isempty(prot.STUDIES)
        return
    end

    subjectStudyDir = fullfile(prot.STUDIES, subjectName);
    if ~exist(subjectStudyDir, 'dir')
        return
    end

    channelMatches = dir(fullfile(subjectStudyDir, '*', 'channel.mat'));
    channelMatches = channelMatches(~[channelMatches.isdir]);

    for iFile = 1:numel(channelMatches)
        candidate = fullfile(channelMatches(iFile).folder, channelMatches(iFile).name);

        % Keep the first one found, so a hand-made channel file stays usable
        if isempty(ChanFile)
            ChanFile = candidate;
        end

        chan = load(candidate, 'Channel');
        if isfield(chan, 'Channel') && ~isempty(chan.Channel) && ...
                any(contains({chan.Channel.Name}, '__'))
            ChanFile = candidate;
            return
        end
    end
end