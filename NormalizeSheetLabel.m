%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NormalizeSheetLabel.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = NormalizeSheetLabel(x)
%NORMALIZESHEETLABEL Normalize an Excel cell label for robust comparison.
%   S = NormalizeSheetLabel(X) returns lowercase alphanumeric text; punctuation
%   is removed, so 'Use_Database' and 'Use Database' both become 'usedatabase'.

    if iscell(x)
        if isempty(x)
            s = '';
        else
            s = NormalizeSheetLabel(x{1});
        end
        return;
    end

    if ~ischar(x)
        s = '';
        return;
    end

    s = lower(strtrim(x));
    s = regexprep(s, '[^a-z0-9]', '');
end
