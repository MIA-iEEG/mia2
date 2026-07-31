function [struct_table, status, message] = mia_read_loc_tsv_table(filename, OPTIONS)
% -------------------------------------------------------------------------
% DESCRIPTION
%   Reads a Brainstorm iEEG atlas table (.tsv)
%
% Inputs :
%         filename : Name of the iEEG atlas table (filename.tsv)
%         OPTIONS  : structure with fields
%             .patients : cell array of patient names offered in the dialog
%             .patient  : (optional) patient name
%             .atlas    : (optional) name of the atlas column to read
%
%           When .patient AND .atlas are both provided, the selection dialog
%           is skipped entirely. This lets scripts and Brainstorm processes
%           call this function without any window popping up. Otherwise the
%           dialog is displayed and .patients is used to fill it.
%
% Output:   status  : integrity of table (-1 if doublons exist ; 1
% otherwise)
%           message : string output message containing doublons
%
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

% Init output variables 
message = '' ; 
struct_table = [];
status = 1 ; 

% Read the tsv file
T = readtable(filename,'FileType','text','ReadVariableNames',true) ;
% This throw a warning message due to semi column present in some headers 
% (e.g. cortex_148917V:Schaefer_100_17net) Matlab replaces with _
% 

% Two table layouts are supported :
%   - Brainstorm iEEG atlas export : one patient per file, contacts in a
%     'Channel' column, laterality read from the label text ('Left', ' R'...)
%   - MIA coregistration table     : several patients per file, columns
%     'Subject' and 'Contact', laterality read from the sign of X
isCoregTable = all(ismember({'Subject','Contact'}, T.Properties.VariableNames)) ;

% Get table column headers
atlases = T.Properties.VariableNames ;

if isCoregTable
    % Drop identifiers, coordinates and probability columns. The duplicated
    % 'Prob' header of these tables is read back by Matlab as Prob/Prob_1,
    % hence the case-insensitive match.
    atlases = atlases(~contains(lower(atlases),'prob')) ;
    atlases = atlases(~ismember(atlases, ...
                    {'Subject','Electrode','Contact','X','Y','Z','Tissue'})) ;

    % Anatomical labels are text : this drops numeric atlas indices (e.g. DK)
    atlases = atlases(varfun(@(c) ~isnumeric(c), T(:,atlases), ...
                             'OutputFormat','uniform')) ;
else
    % Excludes _prob and coordinates
    atlases = atlases(~contains(atlases,'_prob')) ;
    atlases = atlases(~ismember(atlases,'Channel')&...
                        ~ismember(atlases,'SCS')&...
                        ~ismember(atlases,'MNI')&...
                        ~ismember(atlases,'World')) ;
end

if isempty(atlases)
    status = -1 ;
    message = sprintf('No anatomical label column found in %s.',filename) ;
    return ;
end

% Coregistration tables carry their own patient names ; Brainstorm exports
% do not, so the caller has to say which patient the file belongs to.
if isCoregTable
    filePatients = unique(T.Subject,'stable') ;
else
    filePatients = OPTIONS.patients ;
end

hasAtlas   = isfield(OPTIONS,'atlas')   && ~isempty(OPTIONS.atlas) ;
hasPatient = isfield(OPTIONS,'patient') && ~isempty(OPTIONS.patient) ;

% Skip the selection dialog when the caller already knows what it wants.
% For coregistration tables .atlas alone is enough : leaving .patient out
% then returns every patient of the file, which is what batch callers need.
if hasAtlas && (hasPatient || isCoregTable)

    atlas = OPTIONS.atlas ;
    if hasPatient ; ptname = OPTIONS.patient ; else ; ptname = [] ; end

    % Fail explicitly here rather than returning an empty table further down
    if ~ismember(atlas,atlases)
        status = -1 ;
        message = sprintf('Atlas "%s" not found in %s.\nAvailable atlases : %s', ...
                            atlas, filename, strjoin(atlases,', ')) ;
        return ;
    end

else
    [ptname,atlas]=mia_inputdialog(filePatients,atlases) ;

    if isempty(ptname)||isempty(atlas) ; status =2 ; return ; end
end


% Get region labels
roi = T.(atlas);

if isCoregTable
    % Laterality comes from the coordinate : these tables carry labels that
    % do not name a side (e.g. "amygdale"), so the text heuristic used for
    % Brainstorm exports would discard every row.
    lat = cell(height(T),1) ;
    lat(T.X > 0) = {'R'} ;
    lat(T.X < 0) = {'L'} ;

    isKept = ~cellfun(@isempty,lat) ;
    elecAll = T.Contact ;
    ptAll   = T.Subject ;
else
    idx_left = contains(roi,' L') | contains(roi,'Left') ;
    idx_right = contains(roi,' R') | contains(roi,'Right') ;

    lat = cell(numel(roi),1) ;
    lat(idx_left) = {'L'}; lat(idx_right) = {'R'};

    % Only keeps data for which we have a lateraltiy (exclude de facto N/A)
    isKept = idx_left|idx_right ;
    elecAll = T.Channel ;

    % A Brainstorm export holds a single patient, named by the caller
    ptAll = repmat({ptname},numel(roi),1) ;
end

% Drop the rows we could not lateralize
roi  = roi(isKept) ;
lat  = lat(isKept) ;
elec = elecAll(isKept) ;
ptAll = ptAll(isKept) ;

% Removes any anoying character. Contact names read from a coregistration
% table are matched against the Brainstorm channel file, and SEEG labels use
% the prime notation (A'1 is not A1), so the apostrophe must survive there.
elec = strrep(elec,',',''); elec = strrep(elec,'"','');
if ~isCoregTable
    elec = strrep(elec,'''','');
end

% Restrict to the requested patient(s) : empty ptname means "all of them",
% which only happens for coregistration tables read without a dialog.
if isempty(ptname)
    u_pt = unique(ptAll,'stable') ;
else
    u_pt = {ptname} ;
end

% One entry per patient, as mia_read_loc_table does for .xlsx tables
for iPt=1:length(u_pt)

    idxPt = strcmp(u_pt{iPt},ptAll) ;

    struct_table{iPt}.pt = u_pt{iPt};
    struct_table{iPt}.lat = lat(idxPt) ;
    struct_table{iPt}.elec = elec(idxPt);
    struct_table{iPt}.roi= roi(idxPt);
    struct_table{iPt}.atlas= atlas;

    % Report contacts listed twice for the same patient
    contacts = strcat(struct_table{iPt}.elec,'(',struct_table{iPt}.lat,')') ;
    [uContacts,~,ic] = unique(contacts) ;
    doublons = uContacts(histc(ic,unique(ic))>=2) ;
    if ~isempty(doublons)
        message = sprintf('%s\n %s : %s',message,u_pt{iPt},sprintf('%s, ',doublons{:}));
        status = 0;
    end

end
end

function [opt1,opt2]=mia_inputdialog(opt_list1,opt_list2)

% Create dialog box with two scroll down menus 
hfig=figure('CloseRequestFcn',@close_req_fun,'menu','none','Units','Normalized', ...
    'Position', [.5, .5, .1, .1],...
    'Name','Select patient and atlas',...
    'menu','none',...
    'NumberTitle','off');

opt1= [] ; opt2  =[] ;

dropdown1=uicontrol('Style', 'popupmenu', 'String', opt_list1, ...
    'Fontsize',12,...
    'Parent',hfig,'Units','Normalized', ...
    'Position',  [.1, .65, .8, .15]);
dropdown2=uicontrol('Style', 'popupmenu', 'String', opt_list2, ...
    'Fontsize',12,...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.1, .4, .8, .15]);
uicontrol('Style', 'pushbutton', 'String', 'OK', ...
    'Parent',hfig,'Units','Normalized', ...
    'Fontsize',12,...
    'Position', [.1 .1 .35 .2],...
    'Callback','close(gcbf)');
cancel=uicontrol('Style', 'pushbutton', 'String', 'cancel', ...
    'Fontsize',12,...
    'Parent',hfig,'Units','Normalized', ...
    'Position', [.55 .1 .35 .2],...
    'Tag','0','Callback',@cancelfun);

% Wait for figure being closed (with OK button or window close)
uiwait(hfig)

% Figure is now closing
if strcmp(cancel.Tag,'0')%not canceled, get actual inputs
    opt1=opt_list1{dropdown1.Value};
    opt2=opt_list2{dropdown2.Value};
end

% Actually close the figure
delete(hfig)

end
function cancelfun(h,~)
set(h,'Tag','1')
uiresume
end
function close_req_fun(~,~)
uiresume
end