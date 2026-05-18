function varargout = process_mia_channel_concat( varargin )
% PROCESS_MIA_CHANNEL_CONCAT: Concatenate the channels from several
% subjects to a single one
%
% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c) University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: A.-Sophie Dubarry, Dewmith Weerasena

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'MIA: Concatenate Channels';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Standardize';
    sProcess.Index       = 306;
    sProcess.Description = '';

    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'import'};
    sProcess.OutputTypes = {'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 0;

    % === SUBJECT NAME
    sProcess.options.subjectname.Comment = 'New subject name:';
    sProcess.options.subjectname.Type    = 'text';
    sProcess.options.subjectname.Value   = 'COREG';

    % === SUBJECT TO SKIP
    sProcess.options.subskip.Comment = 'Subjects to skip:';
    sProcess.options.subskip.Type    = 'text';
    sProcess.options.subskip.Value   = '';

    % === FOLDER KEYWORD (OPTIONNAL)
    sProcess.options.locfolder.Comment = 'Localisation Folder Name (optional)';
    sProcess.options.locfolder.Type    = 'text';
    sProcess.options.locfolder.Value   = '';

    % === HELP TEXT AT THE BOTTOM
    sProcess.options.label1.Comment = [ ...
        '<BR>Copies the channels from multiple subject files into a single matrix and creates a new subject.<BR>' ...
        'Subjects which need to be skipped can be listed separated by commas.' ...
    ];
    sProcess.options.label1.Type = 'label';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    % ===== GET OPTIONS =====
    % Get subject name
    NewSubjectName = file_standardize(sProcess.options.subjectname.Value);
    if isempty(NewSubjectName) 
        bst_report('Error', sProcess, sInputs, 'Subject name is empty.');
        return
    end

    % Get subjects in protocol 
    subs = bst_get('ProtocolSubjects');

    % Split the name of loc folder 
    LocFolder= strtrim(str_split(sProcess.options.locfolder.Value, ',;'));

    % Check if only one folder in keyword (several not supported yet)
    if length(LocFolder)>1
        bst_report('Error', sProcess, sInputs, 'Several folders for localisation is not supported, use only one keyword');
        return
    end

    % Split the name of sujets to skip (using , or ;)
    SubSkip= strtrim(str_split(sProcess.options.subskip.Value, ',;'));

    % Get the names of all the subjects into an array
    SubNames = {subs.Subject.Name};

    % If the Subject to create alreay exist raise a error and stop
    if ismember(NewSubjectName,SubNames)
               bst_report('Error', sProcess, sInputs, 'The subject you are creating already exist.');
        return

    end

    % Initialize channel structure
    chanstruct.Channel = [];
    
    % Currently loaded protocol:
    prot = bst_get('ProtocolInfo'); 
    
    % Data and anatomy directories:
    datadir = prot.STUDIES;
    anatdir = prot.SUBJECTS;
    
    % coregsubidx = find(cellfun(@(x) strcmp(x, 'COREG'), SubName));
    % if isempty(coregsubidx)
    %     error('Add a new subject to the protol names ''COREG'', with a copy of the ICBM152 MRI and cortex');
    % end
    % 
    % % Find the MRI file for COREG (expects this to already exist):
    % mrifileidx = find(cellfun(@(x) contains(x, {'MRI', 'T1'}), {subs.Subject(coregsubidx).Anatomy.FileName}));
    % if (length(mrifileidx) ~= 1)
    %     error('Please add a subject named ''%s'' with ICBM152 MRI and cortex.', COREG_SUBJECT_NAME);
    % end
    
    % Load COREG MRI once
    %coregmridata = load(fullfile(anatdir, subs.Subject(coregsubidx).Anatomy(mrifileidx).FileName));
    
    SubIdxs = find(~ismember(SubNames,SubSkip)) ; 

    % Then for all other subjects (excpetect the ones we skip)
    for iSubj = 1:length(SubIdxs)
        
        % Load current subject's Implantation channel 
        sStudy = bst_get('StudyWithSubject', subs.Subject(SubIdxs(iSubj)).FileName) ; 
       
        % If no channel file for this subject: skip it
        if isempty(sStudy) ; fprintf(strcat('Skipping : ', subs.Subject(SubIdxs(iSubj)).FileName,'\n')) ; continue ; end 
       
        % If the user wants to select specifically a foler in the database
        % (e.g. "Implantation")
        if isempty(LocFolder)
            chanfilename = sStudy(1).Channel.FileName; 
        else
            % Keyword was used, check if ONE and only ONE occurence of the
            % folder exist, otherwise skip the subject
            if sum(contains({sStudy.Name},LocFolder))~=1 
                fprintf(sprintf('Subject %s has no or more than one folder %s... skip \n',subs.Subject(SubIdxs(iSubj)).FileName,cell2mat(LocFolder)));
                continue ;
            end
            chanfilename = sStudy(contains({sStudy.Name},LocFolder)).Channel.FileName;
        end
        
        %chanfilename = sStudy(find(contains({sStudy.Name},'rawsub'),1)).Channel.FileName; 
        chandata = load(fullfile(datadir, chanfilename));
        
        % % Find current subject's MRI file (expects 1 and only 1):
        % mrifileidx = find(cellfun(@(x) contains(x, {'subjectimage_s'})&~contains(x, {'volct'}), {subs.Subject(SubIdxs(iSubj)).Anatomy.FileName})); 
        % % Note that criteria for finding MRI file may change depending on your own naming conventions and the names of files that were imported in BST
        % % Alternative looking for MRI file that has been renamed for each subject as SubX_MRI
        % % mrifileidx = find(cellfun(@(x) contains(x, {'_MRI'}), {subs.Subject(SubIdxs(iSubj)).Anatomy.Comment}));
        % 
        % % Skip if no MRI found
        % if isempty(mrifileidx); continue ; end 
        % 
        % if (length(mrifileidx) ~= 1)
        %     error('Either no or multiple MRI files found for subject %s - cannot proceed', subs.Subject(SubIdxs(iSubj)).Name);
        % end
        % 
        % mrifilename = subs.Subject(SubIdxs(iSubj)).Anatomy(mrifileidx).FileName;
        % mridata = load(fullfile(anatdir, mrifilename));
        % 
    
        % Prefix electrode names with subject name
        for k = 1:length(chandata.IntraElectrodes)
            chandata.IntraElectrodes(k).Name = strcat(subs.Subject(SubIdxs(iSubj)).Name, '__', chandata.IntraElectrodes(k).Name);
        end
    
        % Accumulate IntraElectrodes
        if iSubj==1
            chanstruct = chandata ; chanstruct.Channel = [] ; 
            % chanstruct.IntraElectrodes = chandata.IntraElectrodes; % initializae at first patient
        else 
            chanstruct.IntraElectrodes = cat(2,chanstruct.IntraElectrodes,chandata.IntraElectrodes); % concatenates the other ones
        end
        
        % Iterate through each channel:
        temp =chandata.Channel(strcmp({chandata.Channel.Type},'SEEG')) ; 

        for iChan = 1:length(temp)
            temp(iChan).Comment = subs.Subject(SubIdxs(iSubj)).Name ;  
            temp(iChan).Name = strcat(subs.Subject(SubIdxs(iSubj)).Name, '__',temp(iChan).Name) ;
            temp(iChan).Group= subs.Subject(SubIdxs(iSubj)).Name ;
            % 
            % % Get MNI coordinates:
            % temp(iChan).Loc = cs_convert(mridata, 'scs', 'mni', temp(iChan).Loc')';
            % 
            % % Convert to local coordinates of ICBM152:
            % temp(iChan).Loc = cs_convert(coregmridata, 'mni', 'scs', temp(iChan).Loc')';
            % 
       end
        fprintf(sprintf('\n%d electrodes found for Subject %s', size(temp,2),subs.Subject(SubIdxs(iSubj)).Name));
        % % Add these channels:
        chanstruct.Channel = [chanstruct.Channel, temp]; 
        
    end

if isempty(chanstruct.Channel)
     bst_report('Error', sProcess, sInputs, 'No channel found in the data');
        return
end

% Rename the Channel
chanstruct.Comment = sprintf('Grand Subject (%d)',size(chanstruct.Channel,2));

% Create a new subject in Brainstorm 
[sSubject, iSubject] = db_add_subject(NewSubjectName, [], 0, 0) ; 

% Process: Simulate generic signals
sFilesSimul = bst_process('CallProcess', 'process_simulate_matrix', [], [], ...
    'subjectname', NewSubjectName, ...
    'condition',   '', ...
    'samples',     10, ...
    'srate',       1000, ...
    'matlab',      [sprintf('Data(1,:) = sin(2*pi*t); \nData(%d,:) = cos(pi*t) + 1;',size(chanstruct.Channel,2))]);

% Import the simulated signal (with correct number of electrodes) in BST
OutputFiles = import_raw(bst_fullfile(datadir,sFilesSimul.FileName),'BST-MATRIX',iSubject);

% Save combined channel file: 
bst_save(fullfile(fileparts(OutputFiles{1}),'channel.mat'), chanstruct, 'v7');

% Get the path that BST expects (e.g. 'COREG_new/@rawmatrix_sim_260513_1358/data_0raw_matrix_sim_260513_1358.mat'
parts = strsplit(OutputFiles{1}, filesep); idx = find(strcmp(parts, NewSubjectName), 1); relativePath = strjoin(parts(idx:end), filesep);

% Process: Import MEG/EEG: Time
sFilesNew = bst_process('CallProcess', 'process_import_data_time', relativePath, [], ...
    'subjectname',   NewSubjectName, ...
    'condition',     '', ...
    'timewindow',    [0, 0.009], ...
    'split',         0, ...
    'ignoreshort',   1, ...
    'usectfcomp',    1, ...
    'usessp',        1, ...
    'freq',          [], ...
    'baseline',      [], ...
    'blsensortypes', 'MEG, EEG');

% Delete the file from Brainstorm's database AND disk
sFiles = bst_process('CallProcess', 'process_delete', sFilesSimul.FileName, [], ...
    'target', 2);  % Delete folders
sFiles = bst_process('CallProcess', 'process_delete', relativePath, [], ...
    'target', 2);  % Delete folders

%% Color Code by Patient
% % Replace all data in dat.F with a patient-based color code
% dat.F = repmat(idx, 1, size(dat.F, 2));
% 
% % Add a comment in dat
% dat.dat = sprintf('Patients. Number of patients = %d (Custom colormap)', length(unique_vals));
% Load data structure 
sRaw = in_bst_data(sFilesNew.FileName);

% Get unique patient IDs and map them to sequential integers
[unique_vals, ~, idx] = unique({chanstruct.Channel.Comment});

% Replace all data in dat.F with a patient-based color code
sRaw.F = repmat(idx, 1, size(sRaw.F, 2));

% Add a comment in dat
sRaw.Comment = sprintf('Patients. Number of patients = %d (Custom colormap)', length(unique_vals));

% Save channel structure (with photocell)
bst_save(file_fullpath(sFilesNew.FileName), sRaw, 'v6', 1);

panel_protocols('UpdateTree');

end