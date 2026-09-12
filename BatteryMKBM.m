%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BatteryMKBM.m
% Copyright: Itahisa Hernández Fumero. 2026.
% Instituto de Energía Solar. Universidad Politécnica de Madrid.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [SOC_new, Q1_new, Q2_new, Pbat_actual, Eloss] = BatteryMKBM(Pbat_req, dt, Q1, Q2, BatParams)
%BATTERYMKBM Modified Kinetic Battery Model for lithium-ion batteries
%
% Two-tank KiBaM/MKBM. Exact closed form for a constant-power step dt:
%   dQ1/dt = E/dt - k*c*(1-c)*u
%   dQ2/dt =       + k*c*(1-c)*u
%   u = Q1/c - Q2/(1-c),  Qt = Q1 + Q2
%   Qt' = Qt + E
%   u'  = u*exp(-k*dt) + E*(1-exp(-k*dt))/(c*k*dt)
%   Q1' = c*Qt' + c*(1-c)*u'
%   Q2' = Qt' - Q1'
% E is the net energy [kWh] into the tanks (positive = charge), limited
% BEFORE the update so no energy is destroyed. What cannot be accepted is
% not requested; the caller makes it curtailment or unmet load.
% Q1 = available tank (extractable now), Q2 = bound tank (converts slowly).
%
% INPUTS:
%   Pbat_req    - Requested battery power [kW] (positive=charge, negative=discharge)
%   dt          - Time step [hours]
%   Q1          - Available energy tank [kWh]
%   Q2          - Bound energy tank [kWh]
%   BatParams   - Structure with battery parameters:
%       .Qmax       - Maximum battery capacity [kWh]
%       .c          - Capacity ratio (available tank / total) [0-1]
%       .k          - Rate constant [1/h] (diffusion between tanks)
%       .SOCmax     - Maximum state of charge [0-1]
%       .SOCmin     - Minimum state of charge [0-1]
%       .eta_ch     - Charging efficiency [0-1]
%       .eta_dis    - Discharging efficiency [0-1]
%       .Pmax_ch    - Maximum charging power [kW] (optional)
%       .Pmax_dis   - Maximum discharging power [kW] (optional)
%       .SelfDischargeRate - self-discharge, fraction per hour (optional)
%
% OUTPUTS:
%   SOC_new     - New state of charge [0-1], always (Q1_new+Q2_new)/Qmax
%   Q1_new      - New available energy [kWh]
%   Q2_new      - New bound energy [kWh]
%   Pbat_actual - Actual battery power at the terminals [kW]
%   Eloss       - Losses [kWh]: efficiency + self-discharge + energy
%                 regularised away when Qmax shrinks with capacity fade

% Extract parameters
Qmax = BatParams.Qmax;
c = BatParams.c;
k = BatParams.k;
SOCmax = BatParams.SOCmax;
SOCmin = BatParams.SOCmin;
eta_ch = BatParams.eta_ch;
eta_dis = BatParams.eta_dis;

% Optional power limits
if isfield(BatParams, 'Pmax_ch')
    Pmax_ch = BatParams.Pmax_ch;
else
    Pmax_ch = Qmax / dt; % Default: can charge full capacity in one time step
end

if isfield(BatParams, 'Pmax_dis')
    Pmax_dis = BatParams.Pmax_dis;
else
    Pmax_dis = Qmax / dt; % Default: can discharge full capacity in one time step
end

% Initialise outputs
Eloss = 0;
Pbat_actual = 0;

% Degenerate guard: no valid step
if dt <= 0 || ~isfinite(Qmax) || Qmax <= 0
    Q1_new = max(0, Q1);
    Q2_new = max(0, Q2);
    SOC_new = (Q1_new + Q2_new) / max(Qmax, eps);
    return;
end

% Physical windows for this step
Qmin_total = SOCmin * Qmax;
Qmax_total = SOCmax * Qmax;
Q1cap = c * Qmax_total;
Q2cap = (1 - c) * Qmax_total;
tolQ = 1e-9 * max(1, Qmax);

%% Regularise the incoming state
% Qmax shrinks with fade, so the previous state can exceed the new window.
% The excess is removed and counted as a loss, not destroyed by per-tank clamps.
Q_total = Q1 + Q2;
if Q_total > Qmax_total
    excess = Q_total - Qmax_total;
    if Q_total > 0
        scale = Qmax_total / Q_total;
        Q1 = Q1 * scale;
        Q2 = Q2 * scale;
    else
        Q1 = 0;
        Q2 = 0;
    end
    Q_total = Qmax_total;
    Eloss = Eloss + excess;
end
if Q_total < 0
    Q_total = 0;
    Q1 = 0;
    Q2 = 0;
end

% Project the tank split onto the feasible interval; the total is not modified
lower1_in = max(0, Q_total - Q2cap);
upper1_in = min(Q1cap, Q_total);
if lower1_in <= upper1_in
    Q1 = min(max(Q1, lower1_in), upper1_in);
    Q2 = Q_total - Q1;
else
    Q1 = c * Q_total;
    Q2 = (1 - c) * Q_total;
end

%% Closed-form coefficients (Q1(E) = A1 + B1*E is exact for this step)
valid_c = (c > 1e-12) && (c < 1 - 1e-12);
valid_k = isfinite(k) && (k >= 0);

if valid_c && valid_k
    kdt = k * dt;
    exp_kdt = exp(-kdt);
    if kdt > 1e-8
        relax_coef = (1 - exp_kdt) / (c * kdt);
    else
        % Series expansion, avoids 0/0 when k*dt -> 0
        relax_coef = (1 - kdt/2 + kdt^2/6) / c;
    end
    u = Q1 / c - Q2 / (1 - c);
    A1 = c * Q_total + c * (1 - c) * u * exp_kdt;
    B1 = c + c * (1 - c) * relax_coef;
else
    exp_kdt = 1; %#ok<NASGU>
    relax_coef = 0;
    u = 0;
    if c <= 1e-12
        A1 = 0;       B1 = 0;   % no available tank
    elseif c >= 1 - 1e-12
        A1 = Q_total; B1 = 1;   % single tank
    else
        A1 = Q1;      B1 = 1;   % no diffusion: everything flows through Q1
    end
end
A2 = Q_total - A1;
B2 = 1 - B1;

%% Feasible interval for the energy exchanged in this step
E_min = Qmin_total - Q_total;
E_max = Qmax_total - Q_total;

if B1 > 1e-12
    E_min = max(E_min, (-A1 - tolQ) / B1);
    E_max = min(E_max, (Q1cap - A1 + tolQ) / B1);
elseif B1 < -1e-12
    E_min = max(E_min, (Q1cap - A1 + tolQ) / B1);
    E_max = min(E_max, (-A1 - tolQ) / B1);
else
    if A1 < -tolQ || A1 > Q1cap + tolQ
        E_min = max(E_min, 0);
        E_max = min(E_max, 0);
    end
end

if B2 > 1e-12
    E_min = max(E_min, (-A2 - tolQ) / B2);
    E_max = min(E_max, (Q2cap - A2 + tolQ) / B2);
elseif B2 < -1e-12
    E_min = max(E_min, (Q2cap - A2 + tolQ) / B2);
    E_max = min(E_max, (-A2 - tolQ) / B2);
else
    if A2 < -tolQ || A2 > Q2cap + tolQ
        E_min = max(E_min, 0);
        E_max = min(E_max, 0);
    end
end

if E_min > E_max
    % Numerically empty window: do nothing this step
    E_min = 0;
    E_max = 0;
end

%% Requested energy, limited by power and by the feasible window
if Pbat_req > 0
    % CHARGE. eta_ch and Pmax_ch apply to the power that reaches the tanks
    E_req = Pbat_req * eta_ch * dt;
    E_req = min(E_req, Pmax_ch * dt);
    E_req = max(0, E_req);
    E_step = min(E_req, max(E_max, 0));
    if eta_ch > 0
        Pbat_actual = E_step / (dt * eta_ch);
    else
        Pbat_actual = 0;
    end
    Eloss = Eloss + Pbat_actual * dt - E_step;
elseif Pbat_req < 0
    % DISCHARGE. Tank draw limited by Pmax_dis*dt; the load receives it times eta_dis
    if eta_dis > 0
        E_rem_req = abs(Pbat_req) * dt / eta_dis;
    else
        E_rem_req = 0;
    end
    E_rem_req = min(E_rem_req, Pmax_dis * dt);
    E_rem_req = max(0, E_rem_req);
    E_rem = min(E_rem_req, max(-E_min, 0));
    E_step = -E_rem;
    E_to_load = E_rem * eta_dis;
    Pbat_actual = -E_to_load / dt;
    Eloss = Eloss + E_rem - E_to_load;
else
    E_step = 0;
end

%% Exact state update
Q_total_new = Q_total + E_step;
if valid_c && valid_k
    u_new = u * exp_kdt + E_step * relax_coef;
    Q1_new = c * Q_total_new + c * (1 - c) * u_new;
    Q2_new = Q_total_new - Q1_new;
else
    Q1_new = A1 + B1 * E_step;
    Q2_new = Q_total_new - Q1_new;
end

% Numerical safety: project the split, never the total
lower1 = max(0, Q_total_new - Q2cap - tolQ);
upper1 = min(Q1cap + tolQ, Q_total_new);
if lower1 <= upper1
    Q1_new = min(max(Q1_new, lower1), upper1);
    Q2_new = Q_total_new - Q1_new;
else
    Q1_new = c * Q_total_new;
    Q2_new = (1 - c) * Q_total_new;
end
if Q1_new < 0 && Q1_new > -tolQ
    Q1_new = 0;
    Q2_new = Q_total_new;
end
if Q2_new < 0 && Q2_new > -tolQ
    Q2_new = 0;
    Q1_new = Q_total_new;
end

%% Self-discharge (fraction per hour), proportional and fully accounted
if isfield(BatParams, 'SelfDischargeRate') && BatParams.SelfDischargeRate > 0
    lost_fraction = min(1, BatParams.SelfDischargeRate * dt);
    Q_after = Q1_new + Q2_new;
    if Q_after > 0
        energy_lost_sd = Q_after * lost_fraction;
        % Never fall below the minimum SOC window
        energy_lost_sd = min(energy_lost_sd, max(0, Q_after - Qmin_total));
        if energy_lost_sd > 0
            scale_sd = 1 - energy_lost_sd / Q_after;
            Q1_new = Q1_new * scale_sd;
            Q2_new = Q2_new * scale_sd;
            Eloss = Eloss + energy_lost_sd;
        end
    end
end

%% New SOC, always consistent with the tanks
SOC_new = (Q1_new + Q2_new) / Qmax;

end
