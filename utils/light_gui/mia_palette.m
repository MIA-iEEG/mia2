function p = mia_palette()
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
% DESCRIPTION :
%   MIA colour palette, as Matlab RGB triplets in [0 1].
%
%   Single source of truth for the look of the MIA windows, mirroring the
%   custom properties of the website stylesheet (website/assets/css/style.css)
%   so both stay recognisably the same product. Update them together.
%
% USAGE :
%       p = mia_palette();
%       uibutton(..., 'BackgroundColor', p.primary, 'FontColor', p.onPrimary);
%
% ========================================================================

    p.primary      = hex2rgb('c8310a');   % terracotta, main action
    p.primaryDark  = hex2rgb('a02607');   % pressed / hovered
    p.primaryLight = hex2rgb('fdeae3');   % tint behind primary content
    p.onPrimary    = [1 1 1];

    p.gold         = hex2rgb('fce8a0');   % group-level actions
    p.goldDark     = hex2rgb('f4d472');
    p.onGold       = hex2rgb('7a4800');

    p.text         = hex2rgb('1a0a00');
    p.textMuted    = hex2rgb('7a6050');

    p.background   = hex2rgb('fdf6ee');   % window background, warm cream
    p.backgroundAlt= hex2rgb('f7ebdc');   % secondary buttons, alternate rows
    p.surface      = [1 1 1];             % tables, panels
    p.border       = hex2rgb('e8ddc8');
end


function rgb = hex2rgb(hex)
    rgb = double([hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))]) / 255;
end
