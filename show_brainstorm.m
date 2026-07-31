function show_brainstorm()
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
%   Bring the Brainstorm main window back to the front.
%
%   Brainstorm's GUI is a Java Swing frame launched from MATLAB. On macOS
%   these Java windows integrate poorly with Mission Control / the Dock's
%   "Show All Windows", so the Brainstorm window can slip behind others and
%   become hard to find. Running `show_brainstorm` raises it again.
%
% USAGE :
%       show_brainstorm
%
% SEE ALSO : start_brainstorm
%
% ========================================================================

jf = bst_get('BstFrame');
if isempty(jf)
    error('MIA:show_brainstorm:noFrame', ...
        'No Brainstorm window found -- is Brainstorm running? (run start_brainstorm)');
end

jf.setVisible(true);
jf.setState(java.awt.Frame.NORMAL);   % de-minimise if it was iconified

% Toggling setAlwaysOnTop is the reliable way to force a background Java
% window to the very front on macOS (toFront alone is often ignored).
jf.setAlwaysOnTop(true);
jf.toFront();
jf.requestFocus();
jf.setAlwaysOnTop(false);

end
