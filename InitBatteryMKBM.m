%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% InitBatteryMKBM.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Q1_init, Q2_init, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, varargin)
%INITBATTERYMKBM Initialize battery parameters for MKBM model
%
% INPUTS:
%   CBAT        - Battery nominal capacity [kWh]
%   SOCmax      - Maximum state of charge [0-1]
%   SOCmin      - Minimum state of charge [0-1]
%   BatteryType - 1 = lead-acid (default KiBaM), 2 = Li-ion LFP,
%                 3 = Li-ion NMC, 4 = Li-ion LTO, 5 = custom
%   varargin    - Optional name-value pairs:
%                 'c'       - Capacity ratio [0-1]
%                 'k'       - Rate constant [1/h]
%                 'eta_ch'  - Charging efficiency [0-1]
%                 'eta_dis' - Discharging efficiency [0-1]
%                 'Pmax_ch' - Maximum charging power [kW]
%                 'Pmax_dis'- Maximum discharging power [kW]
%                 'SOCinit' - Initial SOC [0-1] (default: SOCmax)
%
% OUTPUTS:
%   Q1_init     - Initial available energy tank [kWh]
%   Q2_init     - Initial bound energy tank [kWh]
%   BatParams   - Structure with all battery parameters for BatteryMKBM
%
% Reference c / k (lead-acid has strong rate-capacity effects, Li-ion does not):
%   Lead-acid:  c = 0.315, k = 0.43 (Manwell & McGowan, 1993)
%   Li-ion LFP: c = 0.85,  k = 2.0
%   Li-ion NMC: c = 0.90,  k = 3.0
%   Li-ion LTO: c = 0.95,  k = 5.0

% Parse optional inputs
p = inputParser;
addParameter(p, 'c', []);
addParameter(p, 'k', []);
addParameter(p, 'eta_ch', []);
addParameter(p, 'eta_dis', []);
addParameter(p, 'Pmax_ch', []);
addParameter(p, 'Pmax_dis', []);
addParameter(p, 'SOCinit', SOCmax);
parse(p, varargin{:});
opts = p.Results;

% Default parameters based on battery type
switch BatteryType
    case 1 % Lead-acid
        c_default = 0.315;      % Capacity ratio (typical for lead-acid)
        k_default = 0.43;       % Rate constant [1/h]
        eta_ch_default = 0.85;  % Charging efficiency
        eta_dis_default = 0.85; % Discharging efficiency
        Crate_ch = 0.2;         % Max charge rate [C]
        Crate_dis = 0.5;        % Max discharge rate [C]
        
    case 2 % Lithium-ion LFP (Lithium Iron Phosphate)
        c_default = 0.85;       % Higher capacity ratio (better rate capability)
        k_default = 2.0;        % Higher rate constant
        eta_ch_default = 0.95;  % Higher efficiency
        eta_dis_default = 0.95;
        Crate_ch = 1.0;         % Can charge at 1C
        Crate_dis = 2.0;        % Can discharge at 2C
        
    case 3 % Lithium-ion NMC (Nickel Manganese Cobalt)
        c_default = 0.90;       % Very good rate capability
        k_default = 3.0;        % Fast diffusion
        eta_ch_default = 0.96;  % High efficiency
        eta_dis_default = 0.96;
        Crate_ch = 1.0;
        Crate_dis = 3.0;        % Can discharge at 3C
        
    case 4 % Lithium-ion LTO (Lithium Titanate)
        c_default = 0.95;       % Excellent rate capability
        k_default = 5.0;        % Very fast diffusion
        eta_ch_default = 0.97;  % Excellent efficiency
        eta_dis_default = 0.97;
        Crate_ch = 4.0;         % Can fast charge at 4C
        Crate_dis = 10.0;       % Can discharge at 10C
        
    case 5 % Custom - all parameters must be provided
        c_default = 0.8;
        k_default = 1.0;
        eta_ch_default = 0.90;
        eta_dis_default = 0.90;
        Crate_ch = 1.0;
        Crate_dis = 1.0;
        
    otherwise
        error('Invalid BatteryType. Use 1-5.');
end

% Use provided parameters or defaults; NaN (empty CSV cells) rejected
if ~isempty(opts.c) && ~isnan(opts.c)
    c = opts.c;
else
    c = c_default;
end

if ~isempty(opts.k) && ~isnan(opts.k)
    k = opts.k;
else
    k = k_default;
end

if ~isempty(opts.eta_ch) && ~isnan(opts.eta_ch)
    eta_ch = opts.eta_ch;
else
    eta_ch = eta_ch_default;
end

if ~isempty(opts.eta_dis) && ~isnan(opts.eta_dis)
    eta_dis = opts.eta_dis;
else
    eta_dis = eta_dis_default;
end

% Maximum power limits
if ~isempty(opts.Pmax_ch) && ~isnan(opts.Pmax_ch)
    Pmax_ch = opts.Pmax_ch;
else
    Pmax_ch = CBAT * Crate_ch; % Based on C-rate
end

if ~isempty(opts.Pmax_dis) && ~isnan(opts.Pmax_dis)
    Pmax_dis = opts.Pmax_dis;
else
    Pmax_dis = CBAT * Crate_dis; % Based on C-rate
end

% Build parameter structure
BatParams.Qmax = CBAT;
BatParams.c = c;
BatParams.k = k;
BatParams.SOCmax = SOCmax;
BatParams.SOCmin = SOCmin;
BatParams.eta_ch = eta_ch;
BatParams.eta_dis = eta_dis;
BatParams.Pmax_ch = Pmax_ch;
BatParams.Pmax_dis = Pmax_dis;
BatParams.BatteryType = BatteryType;

% Store type name for display
typeNames = {'Lead-acid', 'Li-ion LFP', 'Li-ion NMC', 'Li-ion LTO', 'Custom'};
BatParams.TypeName = typeNames{BatteryType};

% Initial tank energies at equilibrium: Q1 = c*Q_total, Q2 = (1-c)*Q_total
SOCinit = opts.SOCinit;
Q_total_init = SOCinit * CBAT;
Q1_init = c * Q_total_init;
Q2_init = (1-c) * Q_total_init;

% Display initialization info
fprintf('Battery MKBM initialized:\n');
fprintf('  Type: %s\n', BatParams.TypeName);
fprintf('  Capacity: %.2f kWh\n', CBAT);
fprintf('  Capacity ratio (c): %.3f\n', c);
fprintf('  Rate constant (k): %.3f 1/h\n', k);
fprintf('  Charge efficiency: %.1f%%\n', eta_ch*100);
fprintf('  Discharge efficiency: %.1f%%\n', eta_dis*100);
fprintf('  Max charge power: %.2f kW (%.1fC)\n', Pmax_ch, Pmax_ch/CBAT);
fprintf('  Max discharge power: %.2f kW (%.1fC)\n', Pmax_dis, Pmax_dis/CBAT);
fprintf('  SOC range: %.0f%% - %.0f%%\n', SOCmin*100, SOCmax*100);
fprintf('  Initial SOC: %.0f%%\n', SOCinit*100);

end