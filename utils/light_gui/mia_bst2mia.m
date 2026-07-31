function [rois, varargout] = mia_bst2mia(Condition, ProtocolName, LabelingTable, GroupChannelFile, varargin)
% mia_bst2mia: Extracts and processes ROI data from Brainstorm database.
%
% Copyright (C) 2025 Anne-Sophie Dubarry
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%
% Inputs (mandatory):
%   Condition        - String, condition name (e.g. 'D_LOOMING_bipolar_2')
%   ProtocolName     - String, Brainstorm protocol name (e.g. 'EXPRESSONINTRA')
%   LabelingTable    - String, full path to TSV labeling table
%   GroupChannelFile - String, full path to group channel MAT file
%
% Optional name-value pairs (via varargin):
%   'Subjects'       - Cell array of subject names to process (default: all found)
%   'SubjectsToSkip' - Cell array of subject names to exclude (default: none).
%                      Applied after 'Subjects', so both can be combined.
%   'Atlas'          - Name of the label column to read in the TSV table
%                      (default: 'localisation_lectrodes', which is how
%                      Matlab reads back the header "localisation electrodes')
%
% Outputs:
%   rois    - ROI data structure processed from Brainstorm data
%   varargout{1} - groupChanTable (channel info table)
%   varargout{2} - groupFdata (aggregated data matrix)
%   varargout{3} - stat (statistics structure from averaging)
%
% Example call:
%   rois = bst2mia( ...
%       'MY_CONDITION', ...
%       'MY_PROTOCOL', ...
%       '/path/to/labeling_table.tsv', ...
%       '/path/to/channel.mat' ...
%       );

% Input parsing for optional parameters
p = inputParser;
addRequired(p, 'Condition', @ischar);
addRequired(p, 'ProtocolName', @ischar);
addRequired(p, 'LabelingTable', @ischar);
addRequired(p, 'GroupChannelFile', @ischar);
addParameter(p, 'Subjects', {}, @(x) iscell(x) || isempty(x));
addParameter(p, 'SubjectsToSkip', {}, @(x) iscell(x) || isempty(x));
addParameter(p, 'Atlas', 'localisation_lectrodes', @ischar);
parse(p, Condition, ProtocolName, LabelingTable, GroupChannelFile, varargin{:});

Subjects = p.Results.Subjects;
SubjectsToSkip = p.Results.SubjectsToSkip;
Atlas = p.Results.Atlas;

% -------------------------------------------------------------------------
% Set Brainstorm protocol
iProtocol = bst_get('Protocol', ProtocolName);
bst_set('iProtocol', iProtocol);

% Get all subjects in current BST protocol
bstSubjects = bst_get('ProtocolSubjects');
subjectNames = {bstSubjects.Subject.Name};

% Remove group analysis and coreg subjects
subjectNames(contains(subjectNames,'Group')) = [];
subjectNames(contains(subjectNames,'COREG')) = [];

% Restrict to selected subjects if provided
if ~isempty(Subjects)
    subjectNames = subjectNames(ismember(subjectNames, Subjects));
end

% Then drop the subjects explicitly excluded
if ~isempty(SubjectsToSkip)
    subjectNames = subjectNames(~ismember(subjectNames, SubjectsToSkip));
end

if isempty(subjectNames)
    error('mia_bst2mia:noSubject', ...
        'No subject left to process in protocol "%s" after applying Subjects/SubjectsToSkip.', ...
        ProtocolName);
end

% Read labeling table (TSV) through the shared MIA reader. Passing the atlas
% and no patient keeps it silent (no selection dialog) and returns one entry
% per patient found in the table.
tsvOPTIONS.patients = subjectNames;
tsvOPTIONS.atlas    = Atlas;
[struct_table, tsvStatus, tsvMessage] = mia_read_loc_tsv_table(LabelingTable, tsvOPTIONS);

if tsvStatus == -1
    error('mia_bst2mia:badLabelingTable', '%s', tsvMessage);
elseif tsvStatus == 0
    warning('mia_bst2mia:duplicateContacts', ...
        'Some contacts are listed twice in %s:%s', LabelingTable, tsvMessage);
end

chanStruct = load(GroupChannelFile);

% Flatten the per-patient structures into the n x 5 MIA table:
% {subject, electrode name, contact number, laterality, ROI label}
mTable = cell(0,5);
coregChannelNames = {};

for iPt = 1:numel(struct_table)
    s = struct_table{iPt};

    % Keep only subjects present in BST database
    if ~ismember(s.pt, subjectNames)
        continue;
    end

    nContact = numel(s.elec);
    block = cell(nContact, 5);
    block(:,1) = {s.pt};

    % Extract alpha characters and numbers from contact names
    for iC = 1:nContact
        label = s.elec{iC};
        block{iC,2} = label(~isstrprop(label, 'digit'));
        block{iC,3} = str2double(label(isstrprop(label, 'digit')));
    end

    block(:,4) = s.lat;
    block(:,5) = s.roi;

    mTable = cat(1, mTable, block);

    % Double underscore: this is how process_mia_channel_concat names the
    % contacts of the group channel file (Subject__Contact). The single
    % underscore used further down is a different convention, for the bipolar
    % montage names built from each subject's own data.
    coregChannelNames = cat(1, coregChannelNames, strcat(s.pt, '__', s.elec));
end

% Remove rows with empty ROI labels
isEmptyRoi = cellfun(@isempty, mTable(:,5));
mTable(isEmptyRoi, :) = [];
coregChannelNames(isEmptyRoi) = [];

% Find matching channels between coreg and chanStruct
chanNames = {chanStruct.Channel.Name};
[lia, lib] = ismember(coregChannelNames, chanNames);

% Nothing matched at all: this is a naming problem, not a missing contact.
% Show both sides so the culprit is obvious instead of silently producing an
% empty group result.
if ~any(lia)
    error('mia_bst2mia:noChannelMatch', ...
        ['None of the %d contacts of the labeling table were found in the ' ...
         'channel file.\nExpected names of the form Subject__Contact.\n' ...
         'Labeling table: %s ...\nChannel file  : %s ...\n' ...
         'A channel file holding names such as s1, s2, s3 is the simulated ' ...
         'signal, not the group file written by "MIA: Concatenate channels".'], ...
        numel(coregChannelNames), ...
        strjoin(coregChannelNames(1:min(3,end)), ', '), ...
        strjoin(chanNames(1:min(3,end)), ', '));
end

% Warn if some channels missing
if any(lib == 0)
    warning('Some coreg electrodes not found in channel file:');
    disp(coregChannelNames(lib == 0));
end

fprintf('Found %d matching channels (coreg labels in BST) out of %d total\n', sum(lia), length(coregChannelNames));

% Generate bipolar montage table (exclusive = 1)
bipolarTable = generate_bipolar_table(mTable, 1);

% Time window edges for analysis
xMax = 0.6;
xMin = -0.3;

% Initialize containers for aggregated data
groupChanTable = [];
groupFdata = [];

% Loop over subjects to gather data
for iSubj = 1:length(subjectNames)
    % Select data files for this subject and condition
    sFiles = bst_process('CallProcess', 'process_select_files_data', [], [], ...
        'subjectname', subjectNames{iSubj}, ...
        'condition', Condition, ...
        'tag', 'MIA', ...
        'includebad', 0, ...
        'includeintra', 0, ...
        'includecommon', 0);

    if isempty(sFiles)
        continue;
    end

    % Compute average over selected files
    [stat, ~, ~, ~] = bst_avg_files({sFiles.FileName}, [], 'mean', 0, 0, 0, 0, 1);

    % Select time indices within desired window
    timeMask = (stat.Time < xMax) & (stat.Time > xMin);

    % Get channel info for current study
    channelFile = bst_get('ChannelFileForStudy', sFiles(1).FileName);
    sChannel = in_bst_channel(channelFile);

    chanInData = strcat(subjectNames{iSubj}, '_', {sChannel.Channel.Name});

    % Find indices of bipolar table channels present in this data
    [lia1, locb1] = ismember(bipolarTable(:, 6), chanInData);

    % Subset bipolar table to channels present in data
    bipolarTableSub = bipolarTable(lia1, :);

    % Append channel info and data for this subject
    groupChanTable = cat(1, groupChanTable, bipolarTableSub);
    groupFdata = cat(1, groupFdata, stat.mean(locb1(locb1 ~= 0), timeMask));
end

% Define options for ROI extraction and analysis
options.freq = 1;           % Frequency ID for Morlet or Hilbert
options.nPt = 1;            % Minimum number of points per ROI (GUI filtering)
options.signifmode = 0;     % Mode for significant activity (0 = none)
options.signmode = 'signed'; % 'signed' or 'abs'

% Create zero mask for significance
significanceMask = zeros(size(groupFdata));

% Generate ROI data structure
rois = mia_get_roi_bst(groupChanTable, stat.Time(timeMask), groupFdata, significanceMask, {'freqs'}, options);

% Assign optional outputs if requested
if nargout > 1
    varargout{1} = groupChanTable;
end
if nargout > 2
    varargout{2} = groupFdata;
end
if nargout > 3
    varargout{3} = stat;
end

end
