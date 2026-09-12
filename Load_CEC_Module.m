%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load_CEC_Module.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PVnom, CVPT, NOCT] = Load_CEC_Module(module_name)
    % Reads CEC Modules.csv and returns the parameters of one module

    [script_dir, ~, ~] = fileparts(mfilename('fullpath'));
    db_path = fullfile(script_dir, 'ddbb', 'CEC_Modules.csv');
    if ~isfile(db_path)
        error('CEC Modules.csv not found in ddbb folder.');
    end

    % Read CSV as table, skipping the first 2 units/metadata lines
    opts = detectImportOptions(db_path);
    opts.DataLines = [4 Inf];
    opts.VariableNamesLine = 1;
    opts.PreserveVariableNames = true;

    db = readtable(db_path, opts);

    % Find module by name, trimming leading/trailing whitespace
    module_name = strtrim(module_name);
    idx = find(strcmp(strtrim(db.Name), module_name));

    if isempty(idx)
        error(['Module ''', module_name, ''' not found in the CEC database.']);
    end

    % If multiple match, warn the user and take the first one
    if numel(idx) > 1
        warning('Load_CEC_Module:duplicateName', ...
            'Found %d entries named "%s" in the CEC database. Using the first one.', ...
            numel(idx), module_name);
    end
    idx = idx(1);

    % Extract CEC CSV parameters; reject missing values
    stc = db.STC(idx);
    if isnan(stc)
        error(['Module ''', module_name, ''' has no STC power in the CEC database.']);
    end
    noct = db.T_NOCT(idx);
    if isnan(noct)
        error(['Module ''', module_name, ''' has no T_NOCT value in the CEC database.']);
    end
    gamma = db.gamma_pmp(idx);
    if isnan(gamma)
        error(['Module ''', module_name, ''' has no gamma_pmp value in the CEC database.']);
    end

    PVnom = stc / 1000; % Convert W to kW for PVlite compatibility
    NOCT = noct;

    % CVPT = abs(gamma_pmp); CSV gamma_pmp is in %/K
    CVPT = abs(gamma);
end
