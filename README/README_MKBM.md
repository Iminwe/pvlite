# Modified Kinetic Battery Model (MKBM)

## Description

The **Modified Kinetic Battery Model (MKBM)** extends the Kinetic Battery Model (KiBaM). It replaces the single-tank, ideal battery of the original PVlite dispatch with two coupled energy tanks, allowing lead-acid and lithium-ion banks to be simulated with rate-dependent capacity, recovery, losses, operating limits and aging.

MKBM is used only by the applications that dispatch a battery:

| Application | Dispatcher when `BatteryModel == 2` |
|---|---|
| 2 — Stand-alone | `PowerCalculations_MKBM.m` |
| 3 — Hybrid, DC bus | `PowerCalculationsHybrid_MKBM.m` |
| 4 — Hybrid, AC bus | `PowerCalculationsHybrid_MKBM_ACbus.m` |

Grid-connected (1) and pumping (5) systems do not dispatch a battery and are not affected by this model.

`mainSA.m` selects the stand-alone dispatcher:

```matlab
if exist('BatteryModel', 'var') && BatteryModel == 2
    PowerCalculations_MKBM;      % MKBM
else
    PowerCalculations;           % original simple model
end
```

`mainHybrid.m` applies the same `BatteryModel == 2` test and chooses the DC- or AC-bus MKBM dispatcher according to `Application`.

## Two-tank model

The battery is represented by two energy tanks:

- **Q1 (available energy)**: energy that can be extracted immediately.
- **Q2 (bound energy)**: energy that diffuses into `Q1` at a finite rate.

Only `Q1` feeds the load directly. `Q2` replenishes `Q1` through a diffusion term:

```matlab
u = Q1 / c - Q2 / (1 - c);
```

This split reproduces two effects that the simple model cannot:

1. **Rate-capacity effect**: the higher the current, the less energy can be extracted before `SOCmin` is reached.
2. **Recovery effect**: during rest periods or low-current intervals, part of the bound energy diffuses back into `Q1` and becomes usable again.

The remaining MKBM features are independent charge and discharge efficiencies, explicit power limits, chemistry-specific defaults, temperature windows, self-discharge and aging.

## Files

### Added files

| File | Role |
|---|---|
| `BatteryMKBM.m` | One MKBM time step: closed-form two-tank update, efficiencies, power limits, self-discharge |
| `InitBatteryMKBM.m` | Builds `BatParams` and the initial tank split from `BatteryType` plus optional overrides |
| `ReadBatteryMKBM.m` | Reads the `BatteryMKBM` sheet in manual or database mode |
| `PowerCalculations_MKBM.m` | Stand-alone dispatch with MKBM |
| `PowerCalculationsHybrid_MKBM.m` | Hybrid DC-bus dispatch with MKBM |
| `PowerCalculationsHybrid_MKBM_ACbus.m` | Hybrid AC-bus dispatch with MKBM |
| `PlotBatteryDegradation.m` | Post-processing: SOH, degradation breakdown, capacity and power fade |
| `CompareBatteryModels.m` | Post-processing: runs the simple model and MKBM back to back and plots the differences |

### Modified files

| File | Change |
|---|---|
| `ReadInputData.m` | Calls `ReadBatteryMKBM` once the rest of the input data is loaded |
| `mainSA.m` | Selects `PowerCalculations_MKBM` when `BatteryModel == 2` |
| `mainHybrid.m` | Selects `PowerCalculationsHybrid_MKBM` (Application 3) or `PowerCalculationsHybrid_MKBM_ACbus` (Application 4) when `BatteryModel == 2` |
| `SankeySA.m` | Adds a `Battery losses` branch when MKBM is active |
| `SankeyHybrid_DCbus.m` | Adds a `Battery losses` branch when MKBM is active |
| `SankeyHybrid_ACbus.m` | Adds a `Battery losses` branch when MKBM is active |
| `DailyParameters.m` | Aggregates `PDUMP` into `EDUMPd` for hybrid applications when `PDUMP` exists |
| `MonthlyParameters.m` | Aggregates `EDUMPd` into `EDUMPm` |
| `YearlyParameters.m` | Aggregates `EDUMPm` into `EDUMPa` |

`PDUMP` is produced only by the two hybrid MKBM dispatchers. `PowerCalculations_MKBM.m` does not define it, and the aggregation scripts fall back to zeros when the variable is absent.

## Supported battery types

`InitBatteryMKBM.m` assigns a default parameter set from `BatteryType`. The `BatteryMKBM` worksheet and the battery database can override individual values. An invalid `BatteryType`, outside 1–5, raises an error.

| `BatteryType` | Chemistry | c | k [1/h] | eta_ch | eta_dis | Crate_ch | Crate_dis |
|---|---|---|---|---|---|---|---|
| 1 | Lead-acid | 0.315 | 0.43 | 0.85 | 0.85 | 0.2 | 0.5 |
| 2 | Li-ion LFP | 0.85 | 2.0 | 0.95 | 0.95 | 1.0 | 2.0 |
| 3 | Li-ion NMC | 0.90 | 3.0 | 0.96 | 0.96 | 1.0 | 3.0 |
| 4 | Li-ion LTO | 0.95 | 5.0 | 0.97 | 0.97 | 4.0 | 10.0 |
| 5 | Custom | 0.80 | 1.0 | 0.90 | 0.90 | 1.0 | 1.0 |

The lead-acid reference values (`c = 0.315`, `k = 0.43`) come from Manwell and McGowan (1993). Type 5 is a neutral starting point; the expectation is that the user supplies the custom parameters explicitly.

### MKBM parameters

- **c (capacity ratio)**: fraction of the total energy that sits in the available tank, in the range 0–1.
  - High values give a better response to high currents.
  - Typical lithium-ion: 0.85–0.95.
  - Typical lead-acid: 0.30–0.40.
- **k (rate constant)**: diffusion rate between tanks, in 1/h.
  - High values give faster recovery.
  - Typical lithium-ion: 2–5 1/h.
  - Typical lead-acid: 0.3–0.5 1/h.
- **eta_ch / eta_dis**: charge and discharge efficiencies, entered as fractions in the range 0–1. `0.95` means 95%; these cells are not percentages.
- **Pmax_ch / Pmax_dis**: maximum charge and discharge power in kW. When they are omitted, `InitBatteryMKBM.m` derives them from the chemistry C-rate:

  ```matlab
  Pmax_ch  = CBAT * Crate_ch;
  Pmax_dis = CBAT * Crate_dis;
  ```

## Initialization

Each dispatcher initializes the battery once per battery life:

```matlab
if ~exist('BatParams', 'var') || (exist('ResetBattery', 'var') && ResetBattery == 1)
    [Q1_prev, Q2_prev, BatParams] = InitBatteryMKBM(CBAT, SOCmax, SOCmin, BatteryType, ...);
end
```

The guard means the battery state is reused across years unless `ResetBattery` is set to 1. `mainMultiYear.m` uses that flag after an end-of-life replacement, and `CompareBatteryModels.m` clears `BatParams`, `Q1_prev` and `Q2_prev` before forcing a fresh MKBM run.

The initial state of charge defaults to `SOCmax` and is split at equilibrium:

```matlab
Q_total_init = SOCinit * CBAT;
Q1_init = c * Q_total_init;
Q2_init = (1 - c) * Q_total_init;
```

`BatParams` carries `Qmax`, `c`, `k`, `SOCmax`, `SOCmin`, `eta_ch`, `eta_dis`, `Pmax_ch`, `Pmax_dis`, `BatteryType` and `TypeName`. The dispatchers add the aging, temperature and self-discharge fields described below.

If `BatteryType` is not defined when a dispatcher runs, it defaults to 2 (Li-ion LFP) and prints a notice. This dispatcher-level fallback is separate from the `BatteryType = 1` fallback used by `ReadBatteryMKBM.m` when the worksheet is missing.

## The MKBM time step

`BatteryMKBM.m` advances one constant-power step `dt` using the exact closed form of the two-tank system:

```text
dQ1/dt = E/dt - k*c*(1-c)*u
dQ2/dt =        k*c*(1-c)*u
u  = Q1/c - Q2/(1-c)          Qt = Q1 + Q2
Qt' = Qt + E
u'  = u*exp(-k*dt) + E*(1-exp(-k*dt))/(c*k*dt)
Q1' = c*Qt' + c*(1-c)*u'
Q2' = Qt' - Q1'
```

`E` is the net energy in kWh that enters the tanks during the step, positive for charge. The requested power uses the opposite sign convention from the stored-energy variable:

- `Pbat_req > 0` — charge.
- `Pbat_req < 0` — discharge.

The function signature is:

```matlab
[SOC_new, Q1_new, Q2_new, Pbat_actual, Eloss] = BatteryMKBM(Pbat_req, dt, Q1, Q2, BatParams)
```

### Charge

The energy that reaches the tanks is the requested power times the charging efficiency, capped by the power limit and by the feasible window:

```matlab
E_req = Pbat_req * eta_ch * dt;
E_req = min(E_req, Pmax_ch * dt);
E_step = min(E_req, E_max);
Pbat_actual = E_step / (dt * eta_ch);
Eloss = Eloss + Pbat_actual * dt - E_step;
```

`Pbat_actual` is the power measured at the terminals, so the difference between what the terminals absorb and what the tanks store is counted as a loss.

### Discharge

The tanks supply the demand divided by the discharge efficiency, again capped by the power limit and by the available energy:

```matlab
E_rem_req = abs(Pbat_req) * dt / eta_dis;
E_rem_req = min(E_rem_req, Pmax_dis * dt);
E_rem = min(E_rem_req, -E_min);
E_to_load = E_rem * eta_dis;
Pbat_actual = -E_to_load / dt;
Eloss = Eloss + E_rem - E_to_load;
```

Energy that cannot be accepted or cannot be supplied is limited **before** the state update, so no energy is destroyed inside the function. The caller turns the shortfall into curtailment or unmet load.

### Feasible window and state regularisation

The feasible interval for `E` accounts for the total SOC window (`SOCmin * Qmax` to `SOCmax * Qmax`) and for the per-tank caps (`c * Qmax_total` and `(1 - c) * Qmax_total`). Because `Qmax` shrinks as the battery ages, the state inherited from the previous step can fall outside the new window; the excess is removed proportionally from both tanks and added to `Eloss` rather than being clamped away.

Degenerate cases (`dt <= 0`, non-finite or non-positive `Qmax`, `c` at 0 or 1, `k*dt` near zero) are handled with series expansions or single-tank fallbacks so the step does not produce `NaN`.

### Self-discharge

The dispatchers convert `MKBM_SelfDischarge`, entered as a percentage per month, to a fraction per hour using a 30-day month:

```matlab
BatParams.SelfDischargeRate = (MKBM_SelfDischarge / 100) / (30 * 24);
```

When `BatParams.SelfDischargeRate` is present and positive, `BatteryMKBM.m` removes the same fraction from both tanks after the state update and adds the energy to `Eloss`. The bleed never pushes the battery below `SOCmin * Qmax`:

```matlab
lost_fraction = min(1, BatParams.SelfDischargeRate * dt);
energy_lost_sd = min(Q_after * lost_fraction, max(0, Q_after - Qmin_total));
```

The new state of charge is always consistent with the tanks:

```matlab
SOC_new = (Q1_new + Q2_new) / Qmax;
```

## Power and temperature limits

`Pmax_ch` and `Pmax_dis` are power limits in kW. In manual mode they are used exactly as entered. In database mode the CSV values are per unit and are multiplied by `N_Batteries`. When no explicit value is available, `InitBatteryMKBM.m` derives the limit from the chemistry C-rate. If a `Pmax` field were absent from `BatParams`, `BatteryMKBM.m` would fall back to `Qmax / dt`, but the dispatchers normally provide both fields.

Before each call to `BatteryMKBM.m`, the dispatcher copies the aged and temperature-checked limits into `BatParams.Pmax_ch` and `BatParams.Pmax_dis`.

The four temperature limits `MKBM_MinChargeTemp`, `MKBM_MaxChargeTemp`, `MKBM_MinDischargeTemp` and `MKBM_MaxDischargeTemp` are compared against the ambient temperature `Ta(h,d)`. When a limit is violated, the corresponding power limit is set to zero for that step:

```matlab
if isfield(BatParams, 'MinChargeTemp') && Ta(h,d) < BatParams.MinChargeTemp
    current_Pmax_ch = 0;
end
```

Charge and discharge are limited independently, so a cold night can block charging while the battery still supplies the load, and a hot afternoon can block discharge while charging remains allowed. Omitting a row leaves that direction unrestricted. Setting `MKBM_MinChargeTemp = 0`, for example, reproduces the common manufacturer restriction on charging lithium-ion cells below 0 °C.

## Aging

Aging is computed in the dispatchers (`PowerCalculations_MKBM.m`, `PowerCalculationsHybrid_MKBM.m`, `PowerCalculationsHybrid_MKBM_ACbus.m`), not inside `BatteryMKBM.m`. Both cycling and calendar aging are calibrated so that the specified life corresponds to 80% SOH, i.e. a 20% capacity fade.

### Cycling aging

`MKBM_LifeCycles` and `MKBM_LifeDoD` are a specification pair: the number of cycles the battery survives at a given depth of discharge. They are converted into a total energy throughput:

```matlab
BatParams.TotalEnergyThroughput = BatParams.Qmax * BatParams.LifeCycles * BatParams.LifeDoD;
```

When either value is missing or `NaN`, the dispatchers use 6000 cycles at 80% DoD. During discharge, the delivered energy is accumulated:

```matlab
BatParams.EnergyDischarged = BatParams.EnergyDischarged + abs(Pbat_actual) * dt;
```

The cycling contribution to SOH is:

```matlab
SOH = 1.0 - 0.2 * (EnergyDischarged / TotalEnergyThroughput) - CalendarFadeAccumulated;
```

### Calendar aging

If `MKBM_CalendarLife` is given in years, an hourly fade is derived:

```matlab
BatParams.CalendarFadePerHour = 0.2 / (BatParams.CalendarLife * 365 * 24);
```

Otherwise `CalendarFadePerHour` is 0 and there is no calendar aging. The accumulator advances every step:

```matlab
BatParams.CalendarFadeAccumulated = BatParams.CalendarFadeAccumulated + BatParams.CalendarFadePerHour * dt;
```

Both mechanisms add up in the same `SOH` variable, which is clamped at 0.

### Capacity fade and power fade

`SOH` acts directly on the physical limits of the battery:

```matlab
BatParams.Qmax = BatParams.Qmax_initial * BatParams.SOH;
current_Pmax_ch  = BatParams.Pmax_ch_initial  * BatParams.SOH;
current_Pmax_dis = BatParams.Pmax_dis_initial * BatParams.SOH;
```

Capacity fade shrinks the usable energy window. Power fade models the rise of internal resistance with age: an old battery cannot deliver or accept the same power even when its state of charge is high.

### End-of-life warning

At the end of a single-year run, each MKBM dispatcher prints a performance summary with battery losses, discharged energy, final SOH, final capacity and power limits, and event counts. Hybrid dispatchers also report fuel use and genset hours. If `SOH < 0.80`, the dispatcher prints an end-of-life warning. Reaching that threshold inside one year points to an undersized bank or a very aggressive duty cycle.

In a multi-year run, `mainMultiYear.m` checks the same threshold after each year, increments `battery_replacements`, records `replacement_years`, and sets `ResetBattery = 1` so the next year starts from a fresh battery. See `README_MultiYear.md`.

## The `BatteryMKBM` worksheet

All five shipped input templates contain the `BatteryMKBM` sheet. Applications 1 and 5 keep it for a uniform workbook layout, but their dispatchers do not use it. Column A holds a sequence number, column B the parameter name, column C the value, column D the units and column E a short description.

Example values from `inputdata_standalone.xlsx`; the other templates currently carry the same `BatteryMKBM` values:

| Row | Parameter | Example value | Units |
|---|---|---|---|
| 1 | Sheet title | `BATTERY MKBM (Stand-alone PV systems)` | — |
| 3 | Header row | `Parameter` / `Value` / `Units` / `Description` | — |
| 4 | `Use_Database_Bat` | 2 | — |
| 5 | `Battery_Name` | `Pylontech US2000C` | — |
| 6 | `N_Batteries` | 4 | — |
| 7 | `BatteryModel` | 2 | — |
| 8 | `BatteryType` | 2 | — |
| 9 | `MKBM_c` | 0.85 | — |
| 10 | `MKBM_k` | 2.5 | 1/h |
| 11 | `MKBM_eta_ch` | 0.95 | — |
| 12 | `MKBM_eta_dis` | 0.95 | — |
| 13 | `MKBM_Pmax_ch` | 8 | kW |
| 14 | `MKBM_Pmax_dis` | 8 | kW |
| 15 | `MKBM_LifeCycles` | 6000 | — |
| 16 | `MKBM_LifeDoD` | 0.8 | — |
| 17 | `MKBM_CalendarLife` | 10 | years |
| 18 | `MKBM_MinChargeTemp` | 0 | °C |
| 19 | `MKBM_MaxChargeTemp` | 45 | °C |
| 20 | `MKBM_MinDischargeTemp` | -20 | °C |
| 21 | `MKBM_MaxDischargeTemp` | 60 | °C |
| 22 | `MKBM_SelfDischarge` | 3 | %/month |

Every row has a fallback, but manual MKBM operation requires `BatteryModel = 2`. Empty `BatteryModel` and empty `BatteryType` default to 1. Empty `MKBM_*` cells are skipped, so the corresponding chemistry defaults from `InitBatteryMKBM.m` remain. In database mode, `Battery_Name` is mandatory.

`BatteryModel` values:

- 1 = simple model, original PVlite behaviour.
- 2 = MKBM.

### Legacy workbooks

Older workbooks have no database header. `HasDatabaseHeader.m` looks for a normalized `Use_Database*` label in the first ten rows and first four columns of the raw sheet; `NormalizeSheetLabel` strips underscores before the comparison. When no such label is found, `ReadBatteryMKBM.m` applies `batOffset = 0` and reads the original compact layout from `NUMERIC` rows 1 to 16. Those rows contain the same parameters, in the same order, as visible rows 7 to 22 of the current layout.

Legacy workbooks have no `Use_Database_Bat`, `Battery_Name` or `N_Batteries` rows, so they always run in manual mode with a single unit.

### Manual mode and database mode

`Use_Database_Bat` selects where the MKBM parameters come from:

- **1 — manual, default**. Parameters are read from the rows below in the same sheet. `Battery_Name` and `N_Batteries` are forced to `''` and 1.
- **2 — database**. `Battery_Name` (row 5, column C) must match an entry in `ddbb/PVlite_Batteries.csv` exactly after trimming surrounding whitespace. An empty name raises an error. `N_Batteries` (row 6, column C) is the number of units in parallel.

In database mode, `ReadBatteryMKBM.m` delegates to `Load_PVlite_Battery.m`; see [README_Database.md](README/README_Database.md) for the CSV layout, name matching and duplicate-name behaviour. The loader returns one battery row, and `ReadBatteryMKBM.m` applies it as follows:

- `BatteryModel` is set to 2, so selecting a database battery always runs MKBM.
- `BatteryType` comes from the CSV.
- The nominal capacity overrides the value read from the `Battery` sheet:

  ```matlab
  CBAT = BatDB.NominalCapacity * N_Batteries;
  ```

- The power limits scale with the number of units:

  ```matlab
  MKBM_Pmax_ch  = BatDB.MKBM_Pmax_ch  * N_Batteries;
  MKBM_Pmax_dis = BatDB.MKBM_Pmax_dis * N_Batteries;
  ```

- The remaining MKBM parameters (`c`, `k`, efficiencies, cycle life, calendar life, temperature limits and self-discharge) are intensive properties and are taken per unit, without scaling.
- Empty CSV cells are read as `NaN` and rejected, so the chemistry defaults from `InitBatteryMKBM.m` apply instead.

`SOCmax` and `SOCmin` are always taken from the main `Battery` sheet, in both modes.

### Missing sheet

If the workbook has no `BatteryMKBM` sheet, `ReadBatteryMKBM.m` prints a warning and falls back to the original behaviour:

```matlab
warning('BatteryMKBM sheet not found in input file. Using default values.');
Use_Database_Bat = 1;
Battery_Name = '';
N_Batteries = 1;
BatteryModel = 1;  %Use simple model by default for backward compatibility
BatteryType = 1;   %Lead-acid by default
```

The `catch` block is broad: it also intercepts other failures while reading the worksheet or the battery database and reports the same message before applying this fallback.

## Additional results

The MKBM dispatchers add these variables to the workspace:

| Variable | Description |
|---|---|
| `Q1_mat` | Energy in the available tank [kWh], `Nsteps × Ndays` |
| `Q2_mat` | Energy in the bound tank [kWh], `Nsteps × Ndays` |
| `ELOSS_BAT` | Battery losses per step [kWh]: efficiency, self-discharge and regularisation |
| `SOH_mat` | State of Health per step [0–1] |
| `BatParams` | Structure with the model parameters and aging state, including `SOH`, `Qmax`, `Qmax_initial`, `Pmax_ch_initial`, `Pmax_dis_initial`, `EnergyDischarged`, `LifeCycles`, `LifeDoD`, `TotalEnergyThroughput`, `CalendarFadePerHour` and `CalendarFadeAccumulated` |
| `PDUMP` | Dumped or excess power [kW]; hybrid MKBM dispatchers only |

`SOC`, `PBAT`, `Cuse`, `OVC`, `OVD` and `LLH` keep their usual meaning. `PBAT` is the power at the battery terminals, positive for charge.

### Sankey diagrams

`SankeySA.m`, `SankeyHybrid_DCbus.m` and `SankeyHybrid_ACbus.m` add a `Battery losses` branch when MKBM is active:

```matlab
if exist('BatteryModel', 'var') && BatteryModel == 2
    p_bat = sum(sum(ELOSS_BAT));      % SankeySA divides this sum by PVnom
    Text_bat = 'Battery losses';
end
```

With the simple model the branch is zero and the diagram keeps its original shape. `SankeyGrid.m` and `SankeyPump.m` have no battery branch.

Sankey diagrams are drawn only for single-year runs. `mainSA.m` and `mainHybrid.m` guard them with:

```matlab
if ~exist('Project_Lifetime', 'var') || Project_Lifetime == 1
```

Since the shipped templates set `Project_Lifetime = 25`, the diagrams are skipped in a default run. Set `Project_Lifetime` to 1, or run `CompareBatteryModels`, to draw them.

### Visualizing degradation

After a run with MKBM active, type in the MATLAB Command Window:

```matlab
PlotBatteryDegradation
```

The script needs `SOH_mat` and `BatParams` in the workspace; otherwise it prints an error message and does nothing. It produces two figures:

1. **Battery Degradation Analysis** — top subplot with the SOH evolution, bottom subplot with a stacked area separating calendar aging from cycling aging.
2. **Capacity and Power Fade** — dual-axis plot with `Qmax` [kWh] on the left and `Pmax_ch` / `Pmax_dis` [kW] on the right.

The script detects whether a full lifetime history is available (`SOH_history` longer than `SOH_mat`) and switches branch:

- **Single-year branch**: the time axis is in hours, built from `Stepph` (steps per hour), and the title reports the fraction of the end-of-year degradation attributable to each mechanism.
- **Multi-year branch**: the time axis is in years, battery replacements are marked with vertical dashed lines using `bat_segment_starts` (or `replacement_years` as a fallback), and the calendar counter restarts at each segment so the breakdown stays meaningful after a replacement.

### Comparing both models

To compare the original battery model with MKBM on the same input data, run `pvlite` first so the inputs are loaded, then:

```matlab
CompareBatteryModels
```

The script requires `Application` in the workspace and only works for stand-alone (2), hybrid DC (3) and hybrid AC (4) systems. It runs the simple model with `BatteryModel = 1`, then regenerates the PV series with `PVpower` or `PVpower_delta` according to `Mounting`, clears `BatParams`, `Q1_prev` and `Q2_prev`, sets `ResetBattery = 1`, and runs MKBM with `BatteryModel = 2` so the second simulation starts from a fresh battery.

It produces:

1. Two Sankey diagrams, named `Sankey Diagram - BASIC MODEL` and `Sankey Diagram - MKBM MODEL`, showing where the battery losses sit in the energy flow.
2. **Degradation Comparison** — SOH of both models over the year. The basic model is a flat line at 100% because it has no aging.
3. **Capacity Comparison** — `Qmax` of both models. The basic model stays fixed at `CBAT`.
4. **SOC Behavior Comparison** — the first week of January (hours 1 to 168, scaled by `Stepph`), where round-trip losses and self-discharge make the MKBM battery deplete faster than the ideal one.

## Compatibility

- If `BatteryModel` is undefined or equals 1, the original simple model runs.
- `PowerCalculations.m` is not modified. The basic hybrid dispatchers use the corrected renewable-side balance `Req_RE = PBAT + PDC - PGEN`; neither performs an MKBM dispatch.
- MKBM supplies the `SOH` used by `mainMultiYear.m` for replacements, and the `SOH_history` / `bat_segment_starts` consumed by `PlotBatteryDegradation.m`. See `README_MultiYear.md`.

## Author

Itahisa Hernández Fumero - 2026  
Instituto de Energía Solar, Universidad Politécnica de Madrid
