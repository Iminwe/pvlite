%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HasDatabaseHeader.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = HasDatabaseHeader(RAW)
%HASDATABASEHEADER Detect whether an Excel sheet uses the new database header.
%   TF = HasDatabaseHeader(RAW) returns true when a 'Use_Database' label appears
%   near the top of the xlsread RAW cell array. Per-sheet variants
%   ('Use_Database_PV', 'Use_Database_Inv', 'Use_Database_GridInv',
%   'Use_Database_Bat') are accepted; NormalizeSheetLabel strips underscores.
%   Old sheets lack these labels and are treated as legacy/manual layouts.

    tf = false;

    if ~iscell(RAW) || isempty(RAW)
        return;
    end

    nRows = min(size(RAW, 1), 10);
    nCols = min(size(RAW, 2), 4);

    for r = 1:nRows
        for c = 1:nCols
            lab = NormalizeSheetLabel(RAW{r, c});
            % Matches 'usedatabase'
            if strncmp(lab, 'usedatabase', 11)
                tf = true;
                return;
            end
        end
    end
end
