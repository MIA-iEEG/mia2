function start_brainstorm(mode)
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
% ------------------------------------------------------------------------
%
% DESCRIPTION :
%   Launch the Brainstorm version bundled with this repository
%   (mia2/brainstorm3), and NOT any other Brainstorm installation that may
%   be present elsewhere on the disk / MATLAB path.
%
%   The path is resolved relative to this file, so it works wherever the
%   repository is cloned. Any other Brainstorm found on the MATLAB path is
%   removed first, so the project version is the one that runs.
%
%   brainstorm3/ is deliberately NOT versioned (see .gitignore): each user
%   drops their own copy at the root of the repository.
%
% USAGE :
%   Make sure the repository root is the current folder or on the MATLAB
%   path, then run:
%       start_brainstorm            % with the interface (default)
%       start_brainstorm('nogui')   % hidden interface: faster for batch
%                                   % scripts (no Java redraw), same database
%       start_brainstorm('server')  % completely headless
%
%   'nogui' is worth using for long DB-writing runs (e.g. mia_s1_extract_
%   bst_data); keep the default when you want to browse the protocol or
%   display files.
%
% SEE ALSO : show_brainstorm
%
% ========================================================================

if nargin < 1 || isempty(mode)
    mode = 'gui';
end

thisDir = fileparts(mfilename('fullpath'));
bstDir  = fullfile(thisDir, 'brainstorm3');

% 0. Put MIA on the path (root + subfolders) so its functions and the
%    bst_plugin processes are reachable from anywhere. Done first, before
%    any early return below, so it always applies.
addpath(genpath(thisDir));

% 1. Check the bundled Brainstorm is actually installed here.
if ~exist(fullfile(bstDir, 'brainstorm.m'), 'file')
    error('MIA:start_brainstorm:notFound', ...
        ['Brainstorm not found at:\n  %s\nDownload it from ' ...
         'https://neuroimage.usc.edu/bst/download.php and unzip it there.'], bstDir);
end

% 2. If a Brainstorm is already running, do not launch a second one.
isRunning = (exist('brainstorm', 'file') == 2) && brainstorm('status');
if isRunning
    runningDir = fileparts(which('brainstorm'));
    if strcmp(runningDir, bstDir)
        fprintf('Project Brainstorm is already running:\n  %s\n', bstDir);
    else
        warning('MIA:start_brainstorm:otherRunning', ...
            ['A DIFFERENT Brainstorm is already running from:\n  %s\n' ...
             'Close it (brainstorm stop) before launching the project version.'], ...
            runningDir);
    end
else
    % 3. Remove any OTHER Brainstorm installation from the MATLAB path so the
    %    wrong version can't be picked, then prepend the project one.
    entries = strsplit(path, pathsep);
    isBst   = contains(lower(entries), 'brainstorm');
    isOurs  = strncmp(entries, bstDir, numel(bstDir));   % bstDir and its subfolders
    other   = entries(isBst & ~isOurs);
    if ~isempty(other)
        warning('MIA:start_brainstorm:removingOther', ...
            'Removing %d other Brainstorm path entry/entries from the MATLAB path.', ...
            numel(other));
        rmpath(other{:});
    end

    % 4. Launch the project Brainstorm, in the requested mode.
    addpath(bstDir);
    fprintf('Starting project Brainstorm (%s) from:\n  %s\n', mode, bstDir);
    switch lower(mode)
        case 'gui'
            brainstorm;
        case 'nogui'
            brainstorm nogui;      % hidden interface, for batch scripts
        case 'server'
            brainstorm server;     % completely headless
        otherwise
            error('MIA:start_brainstorm:badMode', ...
                'Unknown mode "%s": use ''gui'', ''nogui'' or ''server''.', mode);
    end
end

% 5. Never auto-update: this project runs a pinned Brainstorm version.
%    Applied whether or not we launched it here.
bst_set('AutoUpdates', 0);

end
