# PVlite Simulator (extended version)

PVlite is a simulator for Photovoltaic (PV) system applications, developed at the
Instituto de Energía Solar, Universidad Politécnica de Madrid (IES-UPM).

This repository extends the original **PVlite 2.3** (Javier Muñoz Cano) with AC-bus
hybrid architectures, a Modified Kinetic Battery Model (MKBM) with degradation
tracking, component databases, multi-year simulation and an economic analysis module.

> **Official PVlite resources**
> This repository extends the original PVlite 2.3 software. For the original source
> code, the modelling descriptions and the official **User Manual v2.3**, visit the
> [PVlite software page by Javier Muñoz (IES-UPM)](https://blogs.upm.es/javiermunoz/software/).

## What this version adds

| Feature | Main files | Documentation |
|---|---|---|
| Hybrid AC bus and mixed DC/AC node | `PowerCalculationsHybrid_ACbus.m`, `PowerCalculationsHybrid_MKBM_ACbus.m`, `ACpowerGridInverter.m`, `GridInverterParameters.m`, `GridInverterOFF.m`, `SankeyHybrid_ACbus.m` | [README_ACbus.md](README/README_ACbus.md) |
| Component databases (CEC modules, CEC inverters, PVlite batteries) | `Load_CEC_Module.m`, `Load_CEC_Inverter.m`, `Load_PVlite_Battery.m`, `HasDatabaseHeader.m`, `NormalizeSheetLabel.m`, `ddbb/*.csv` | [README_Database.md](README/README_Database.md) |
| MKBM battery model: cycling and calendar ageing, temperature limits, self-discharge | `BatteryMKBM.m`, `InitBatteryMKBM.m`, `ReadBatteryMKBM.m`, `PowerCalculations_MKBM.m`, `PowerCalculationsHybrid_MKBM.m`, `PowerCalculationsHybrid_MKBM_ACbus.m` | [README_MKBM.md](README/README_MKBM.md) |
| Multi-year simulation with PV degradation and battery replacement | `mainMultiYear.m` | [README_MultiYear.md](README/README_MultiYear.md) |
| Economic analysis: CAPEX, OPEX, NPC, annualized cost and charts | `EconomicsCalculations.m`, `PlotEconomics.m` | [README_Economics.md](README/README_Economics.md) |
| Data folders resolved from the script location, not from the current folder | `ReadInputData.m`, `Load_CEC_Module.m`, `Load_CEC_Inverter.m`, `Load_PVlite_Battery.m`, `ReadTMYPVGIS.m`, `ReadTMY3.m` | see [Getting started](#getting-started) |
| Pumping without the Curve Fitting Toolbox | `PumpingModel.m` | see [Requirements](#requirements-and-known-warnings) |

## Repository layout

```text
pvlite/
├── pvlite.m                                              single-year entry point
├── mainMultiYear.m                                       multi-year entry point (not called by pvlite.m)
├── mainGrid.m                                            Application 1 driver
├── mainSA.m                                              Application 2 driver
├── mainHybrid.m                                          Applications 3 and 4 driver
├── mainPump.m                                            Application 5 driver
├── ReadInputData.m                                       reads the whole input workbook
├── ReadBatteryMKBM.m                                     reads the BatteryMKBM sheet
├── HasDatabaseHeader.m                                   detects the database rows in a sheet
├── NormalizeSheetLabel.m                                 normalizes sheet labels before matching
├── Load_CEC_Module.m                                     module lookup in ddbb/CEC_Modules.csv
├── Load_CEC_Inverter.m                                   inverter lookup in ddbb/CEC_Inverters.csv
├── Load_PVlite_Battery.m                                 battery lookup in ddbb/PVlite_Batteries.csv
├── PowerCalculations.m                                   stand-alone dispatch, basic battery model
├── PowerCalculations_MKBM.m                              stand-alone dispatch, MKBM
├── PowerCalculationsHybrid_DCbus.m                       hybrid DC bus, basic model
├── PowerCalculationsHybrid_ACbus.m                       hybrid AC bus, basic model
├── PowerCalculationsHybrid_MKBM.m                        hybrid DC bus, MKBM
├── PowerCalculationsHybrid_MKBM_ACbus.m                  hybrid AC bus, MKBM
├── ACpower.m                                             battery inverter power and losses
├── ACpowerGridInverter.m                                 grid inverter power, losses and saturation
├── InverterParameters.m                                  k0-k2 fit for the battery inverter
├── GridInverterParameters.m                              k0-k2 fit for the grid inverter
├── InverterOFF.m                                         zero-power state of the battery inverter
├── GridInverterOFF.m                                     zero-power state of the grid inverter
├── BatteryMKBM.m                                         two-tank battery step
├── InitBatteryMKBM.m                                     chemistry defaults and parameter validation
├── PumpingModel.m                                        pump and motor model, no Curve Fitting Toolbox
├── EconomicsCalculations.m                               economic analysis (CAPEX/OPEX/NPC)
├── PlotEconomics.m                                       CAPEX breakdown and cost evolution figures
├── PlotBatteryDegradation.m                              battery degradation figures
├── CompareBatteryModels.m                                basic model vs MKBM comparison
├── SankeyGrid.m, SankeySA.m, SankeyHybrid_DCbus.m,
│   SankeyHybrid_ACbus.m, SankeyPump.m, drawSankey.m      Sankey diagrams
├── DailyParameters.m, MonthlyParameters.m,
│   YearlyParameters.m                                    energy aggregation per period
├── inputdata/                                            example input workbooks (*.xlsx)
├── ddbb/                                                 CSV databases and TMY weather files
├── README/                                               topic documentation
└── exercises/                                            Exercise_1..5.m from the original PVlite distribution
```

The `exercises/` folder is not referenced by the simulator code; it contains the
original teaching scripts (`Exercise_1.m` to `Exercise_5.m`) shipped with the PVlite
distribution. The solar geometry, irradiance and synthetic weather generators
(`SunPosition.m`, `Irradiances.m`, `Temperatures.m`, `PerezModel.m`,
`SyntheticGeneration_Aguiar.m` and the rest) are unchanged from PVlite 2.3 and are
not listed above.

## Supported applications

The `Application` value in the `Options` sheet selects the driver script:

| `Application` | System | Driver | Notes |
|---:|---|---|---|
| 1 | Grid-connected PV | `mainGrid.m` | |
| 2 | Stand-alone PV | `mainSA.m` | battery bank required |
| 3 | Hybrid PV, DC bus | `mainHybrid.m` | genset and/or wind, `PowerCalculationsHybrid_DCbus.m` or `_MKBM.m` |
| 4 | Hybrid PV, AC bus | `mainHybrid.m` | `GridInverter` sheet required, `PV_DC_share` optional, `PowerCalculationsHybrid_ACbus.m` or `_MKBM_ACbus.m` |
| 5 | PV pumping | `mainPump.m` | `PumpingModel.m`, `ACpowerPump.m`, `PumpingCalculations_Iterative.m` |

For Application 4 the `GridInverter` sheet is mandatory: if it is missing or cannot
be read, `ReadInputData.m` warns and stops the simulation. `PV_DC_share` is optional
and defaults to `0.5` when the cell is absent.

## Getting started

Interactive run:

1. Run `pvlite` in MATLAB.
2. A file dialog opens on the `inputdata/` folder **next to `ReadInputData.m`**
   (it is anchored with `fileparts(mfilename('fullpath'))`, so the current MATLAB
   folder does not matter for input selection).
3. Select a workbook. `ReadInputData.m` reads every sheet, then `Irradiances`,
   `Temperatures` and `PVpower`/`PVpower_delta` build the time series.
4. The driver selected by `Application` runs, and `EconomicsCalculations.m` prints
   the economic summary at the end.

Programmatic or automated run:

```matlab
run_as_test = true;                     % prevents the leading `clear` from wiping file1
file1 = 'C:\full\path\inputdata\inputdata_hybridAC.xlsx';   % use an absolute path
pvlite
```

`pvlite.m` and `mainMultiYear.m` both start with
`if ~exist('run_as_test','var') || ~run_as_test, clear; end`, so `run_as_test`
must be set **before** the call and `file1` should be an absolute path (a relative
`file1` is resolved against the current MATLAB folder, not against the project).

## Multi-year simulations

For a lifetime analysis, set `Project_Lifetime` and `PV_Degradation_Rate` in the
`Options` sheet and run `mainMultiYear` instead of `pvlite`. `pvlite.m` does not
call it: it only dispatches `mainGrid`, `mainSA`, `mainHybrid` or `mainPump`
according to `Application`, so `mainMultiYear.m` is a separate entry point that
performs its own input reading. It loops year by year, applies PV degradation,
replaces the battery when its state of health drops below 80%, accumulates the
lifetime energy and fuel totals, and finishes with the same economic analysis.
Details: [README_MultiYear.md](README/README_MultiYear.md).

The five shipped workbooks set `Project_Lifetime = 25`. Two consequences follow
when they are run as they are:

- `pvlite` simulates a single year but `EconomicsCalculations.m` discounts over the
  full 25-year horizon, since `Project_Lifetime` drives `PVA_factor`, `CRF`, `NPC`
  and `Annualized_Cost`.
- The Sankey diagrams are not drawn, because the four single-year drivers guard them
  with `if ~exist('Project_Lifetime','var') || Project_Lifetime == 1`. Set
  `Project_Lifetime` to `1` in the `Options` sheet to get them back.

## Input workbook

`ReadInputData.m` reads the following sheets (plus `BatteryMKBM`, read by
`ReadBatteryMKBM.m`):

| Sheet | Read for | Content |
|---|---|---|
| `Site` | always | latitude, longitude, altitude, standard longitude (time zone = longitude / 15) |
| `Meteo` | always | irradiance/temperature input mode, monthly values or TMY file selection |
| `Options` | always | `Application`, soiling, diffuse model and fraction, ground reflectance, simulation step, `Project_Lifetime`, `PV_Degradation_Rate` |
| `PVgen` | always | PV array: database flag, module name, number of modules, `PVnom`, `CVPT`, `NOCT`, `Rth`, mounting, inclination/orientation, `PV_DC_share` (Application 4) |
| `Inverter` | always | battery inverter: database flag, name, `PInom`, `PImax`, curve type, `k0`-`k2` or efficiency points |
| `GridInverter` | Application 4 | grid/bidirectional inverter, same structure as `Inverter`; only `inputdata_hybridAC.xlsx` ships this sheet |
| `Battery` | always | `CBAT`, `SOCmax`, `SOCmin` |
| `BatteryMKBM` | always (defaults if absent) | battery model and type, `N_Batteries`, and the 14 MKBM parameters, or a database name |
| `Wiring` | always | DC and AC wiring losses |
| `Load` | always | monthly load profile, annual demand, load shape |
| `Genset` | Applications 3-4 | diesel genset data |
| `Wind` | Applications 3-4 | wind turbine data |
| `Pumping` | Application 5 | pump, motor and water demand data |
| `Economics` | always (defaults to 0 if absent) | the nine cost parameters |

Three conventions are worth knowing before editing a workbook:

1. **The reader is positional, not label-driven.** Values are taken from fixed
   row/column positions (column C in most sheets). Labels in column B are for the
   reader's benefit only.
2. **Visible Excel rows are not internal row indices.** `xlsread` drops leading
   text rows from its `NUMERIC` output, so internal indices are smaller than the
   visible row numbers. Example: `Project_Lifetime` is visible row 10 in the
   current templates and is read as `NUMERIC(7,3)`.
3. **Old and new layouts are both supported.** `HasDatabaseHeader.m` looks for a
   `Use_Database*` label in the first rows of `PVgen`, `Inverter` and
   `BatteryMKBM`; when found, the reader applies `pvOffset = 3`, `invOffset = 2`
   and `batOffset = 3`. Legacy workbooks without that header keep working with
   offset 0. `GridInverter` has no legacy offset and expects the current layout.

## Component databases and the `Use_Database` flags

| Sheet | Variable | Default | Database mode | Manual mode |
|---|---|---:|---|---|
| `PVgen` | `Use_Database_PV` | `1` | value is exactly `2` | any other value, including `1` |
| `Inverter` | `Use_Database_Inv` | `1` | value is exactly `2` | any other value, including `1` |
| `BatteryMKBM` | `Use_Database_Bat` | `1` | value is exactly `2` | any other value, including `1` |
| `GridInverter` | `Use_Database_GridInv` | `1` | value is exactly `2` | any other value, including `1` |

The defaults apply when the flag cell exists but is empty or not numeric. If the
whole `BatteryMKBM` sheet is missing, `ReadBatteryMKBM.m` warns and sets
`Use_Database_Bat = 1`, `BatteryModel = 1` and `BatteryType = 1`, so the simulation
falls back to the basic battery model.

The databases live in `ddbb/`: `CEC_Modules.csv`, `CEC_Inverters.csv` and
`PVlite_Batteries.csv`, plus the two bundled TMY weather files. Details, loader
behaviour and the full flag audit of the shipped workbooks:
[README_Database.md](README/README_Database.md).

## Outputs

- **Console**: input summary, energy balances and the economic results.
- **On-screen figures**: Sankey diagrams and battery/economics plots. Sankey
  diagrams are drawn only for single-year runs, i.e. when `Project_Lifetime` is 1
  or not defined (`mainGrid.m`, `mainSA.m`, `mainHybrid.m`, `mainPump.m`).
- **Economic charts**: `PlotEconomics.m` runs when `PlotEconomicsFlag` is set and
  produces one figure with two subplots, but only if `CAPEX > 0`; with every cost
  parameter at zero it prints the "No CAPEX data" placeholder instead.
- **Degradation charts**: `PlotBatteryDegradation.m` needs `SOH_mat` and `BatParams`
  in the workspace, so it is available only after a run with `BatteryModel = 2`.

## Post-processing

After a `pvlite` run, with the workspace still loaded:

```matlab
CompareBatteryModels     % reruns the case with the basic model and with MKBM
PlotEconomics            % CAPEX breakdown and cost evolution
```

After a `mainMultiYear` run, with the workspace still loaded:
```matlab
PlotBatteryDegradation   % degradation figures (multi-year)
PlotEconomics            % CAPEX breakdown and cost evolution
```

`CompareBatteryModels.m` only works for Applications 2, 3 and 4 and requires a
previous `pvlite` run so that `Application` exists in the workspace.
`PlotBatteryDegradation.m` after a `mainMultiYear` run uses `SOH_history` and
`bat_segment_starts` to show the whole lifetime and mark the replacement points.

## Requirements and known warnings

- Developed and validated with **MATLAB R2024a**. Octave compatibility was a design
  goal of the original PVlite code, but this extension has not been validated on
  Octave; do not assume it works there. The database loaders in particular rely on
  `readtable` with `detectImportOptions`.
- The **Curve Fitting Toolbox is not required** by the current code path: the
  inverter efficiency fit and the pump/motor fit use plain least squares, and
  `PumpingModel.m` guards the motor fit when the toolbox is absent.
- Excel input is read with `xlsread`, which MATLAB R2024a reports as deprecated.
  The warnings are harmless and the read results are unaffected.
- `Load_CEC_Inverter.m` warns when a battery-side inverter is not flagged as hybrid
  (`CEC_hybrid ~= 'Y'`); the simulation continues.
- A missing `Economics` sheet does not stop the run: `ReadInputData.m` prints
  `Warning: Could not read Economics sheet. Defaulting economic parameters to 0.`
  and every cost is set to zero.

## Documentation

- [README_ACbus.md](README/README_ACbus.md) — hybrid AC bus, grid inverter and mixed DC/AC node.
- [README_Database.md](README/README_Database.md) — CEC and PVlite databases, loaders and flag conventions.
- [README_MKBM.md](README/README_MKBM.md) — Modified Kinetic Battery Model and degradation.
- [README_MultiYear.md](README/README_MultiYear.md) — lifetime simulation, degradation and replacements.
- [README_Economics.md](README/README_Economics.md) — CAPEX, OPEX, NPC and annualized cost.

## Notes on removed and legacy files

- `PumpingData.m` has been **removed**. The active pumping model is
  `PumpingModel.m`, which fits the pump and motor curves with plain least squares
  instead of the Curve Fitting Toolbox.
- `Exercise_1.m` to `Exercise_5.m` were **moved** to `exercises/` unchanged. They
  are teaching scripts from the original distribution and are never called by the
  simulator.
- **Legacy PVlite 2.3 workbooks are still readable.** `HasDatabaseHeader.m` detects
  whether a sheet carries the new `Use_Database*` rows and the reader applies the
  corresponding offset, so manual parameters are found in their original rows. The
  only sheet without a legacy layout is `GridInverter`, which did not exist in
  PVlite 2.3 and always uses the current structure.

## Authorship

```text
Original PVlite 2.3          Javier Muñoz Cano, Instituto de Energía Solar, UPM
Extensions (AC bus, MKBM,    Itahisa Hernández Fumero, Instituto de Energía Solar, UPM
databases, multi-year,
economics)
Version                      3.0.0, 2026
```
