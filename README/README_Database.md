# Component Database Integration

## Overview

PVlite can read component parameters from CSV databases instead of requiring every electrical parameter to be typed manually into the configuration workbook. The databases are plain-text files stored in the `ddbb/` folder:

- `CEC_Modules.csv`: commercial PV modules in the California Energy Commission (CEC) format distributed with NREL SAM.
- `CEC_Inverters.csv`: commercial inverters in the same CEC/SAM format.
- `PVlite_Batteries.csv`: PVlite-specific battery records for the Modified Kinetic Battery Model (MKBM).

The loaders resolve `ddbb/` relative to their own script location using `mfilename('fullpath')`, so PVlite can be started from a different working directory. They are MATLAB code based on `readtable`, `detectImportOptions` and `xlsread`; Octave compatibility is not claimed.

Each worksheet that supports database lookup contains a `Use_Database_*` selector in row 4, column C:

| Selector value | Behavior |
|---|---|
| 2 | Database mode. The component is looked up by name in the corresponding CSV file. |
| 1, empty, or any other value | Manual mode. The parameters are read from the worksheet. |

The distributed templates use `1` for manual input. In database mode, the selector, the component name and, where present, the number of units are still read from the worksheet; the manual electrical-parameter cells are ignored. Sheet configuration unrelated to the component record, such as mounting, inclination, orientation and `PV_DC_share`, is read as usual.

## CSV structure and name matching

All three CSV files use the three-line header structure exported by SAM:

1. Line 1: variable names.
2. Line 2: units.
3. Line 3: SAM alias names.
4. Line 4 onward: component records.

The loaders therefore set:

```matlab
opts = detectImportOptions(db_path);
opts.VariableNamesLine = 1;
opts.DataLines = [4 Inf];
opts.PreserveVariableNames = true;
```

The requested component name is compared with the CSV `Name` column using a case-sensitive exact match after `strtrim` is applied to both sides. If the name is absent, the loader stops with an error. If the same name appears more than once, the loader issues a `duplicateName` warning and uses the first match.

## PV module database

```matlab
[PVnom, CVPT, NOCT] = Load_CEC_Module(module_name)
```

The first output is the nominal power of one module in kWp. `ReadInputData.m` receives it as `PVnom_module` and multiplies it by the number of modules.

| CSV field | PVlite output | Conversion |
|---|---|---|
| `Name` | lookup key | exact string match |
| `STC` | per-module `PVnom` | `STC / 1000`, converted from W to kWp |
| `T_NOCT` | `NOCT` | used directly, in °C |
| `gamma_pmp` | `CVPT` | `abs(gamma_pmp)`, in %/K |

Mandatory fields: `STC`, `T_NOCT` and `gamma_pmp`.

When `Use_Database_PV = 2`, `ReadInputData.m` executes:

```matlab
module_name = RAW{5, 3};
N_modules = NUMERIC(3, 3);
[PVnom_module, CVPT, NOCT] = Load_CEC_Module(module_name);
PVnom = PVnom_module * N_modules;
Rth = (NOCT - 20) / 800;
```

In manual mode, `module_name` is set to `''`, `N_modules` to `1`, and `PVnom`, `CVPT`, `NOCT` and `Rth` are read from the worksheet.

## Inverter database

```matlab
[PInom, PImax, k0, k1, k2] = Load_CEC_Inverter(inverter_name, role)
```

The same loader serves both inverter sheets:

- `role = 'battery'` is used for the `Inverter` sheet. If the CSV contains the `CEC_hybrid` column and the selected record is not `'Y'`, the loader issues `Load_CEC_Inverter:typeMismatch`.
- `role = 'grid'` is used for the `GridInverter` sheet. No hybrid-inverter warning is issued.

| CSV field | Use |
|---|---|
| `Name` | lookup key |
| `Paco` | nominal AC output power, W |
| `Pdco` | DC input power at nominal AC output, W |
| `Pso` | self-consumption / startup power, W |
| `C0` | Sandia model coefficient |
| `CEC_hybrid` | battery-role warning only |

Mandatory fields: `Paco`, `Pdco`, `Pso` and `C0`. `C2` is read but not used in the final calculation because the corresponding term disappears at nominal DC voltage. `C1` and `C3` are not used.

Nominal powers:

```matlab
PInom = Paco / 1000;  % W -> kW
PImax = PInom;
```

The Sandia model is sampled at five normalized AC loads:

```matlab
p_ac_norm = [0.1; 0.25; 0.5; 0.75; 1.0];
```

At nominal DC voltage, the Sandia relation is solved for the required DC input power using:

```matlab
A = C0;
B = Paco/(Pdco-Pso) - C0*(Pdco-Pso);
```

For each AC point `Pac`:

```matlab
x = (2 * Pac) / (B + sqrt(B^2 + 4*A*Pac));  % rationalized positive root
Pdc = x + Pso;
eff = 100 * Pac / Pdc;
```

If `abs(A) < 1e-12`, the linear solution `x = Pac / B` is used. Efficiency points above 99% are capped at 99%; negative points are replaced by 50%.

The five points are then fitted to PVlite's native quadratic efficiency model:

```matlab
Efficiency = 100 * p0 / (p0 + k0 + k1*p0 + k2*p0^2)
```

The fit rearranges the model as `y = p0 * (100/Efficiency - 1)` and solves `y = k0 + k1*p0 + k2*p0^2` by ordinary least squares using normal equations, without the Curve Fitting Toolbox. If the fitted `k0` is negative, it is replaced by `0.005`; if the fitted `k2` is negative, it is replaced by `0.01`. `k1` is not clamped.

## PVlite battery database

The loader is declared as:

```matlab
function BatParams = Load_PVlite_Battery(battery_name)
```

Although the formal output is named `BatParams`, the function returns a CSV record rather than the runtime battery state. `ReadBatteryMKBM.m` assigns that record to `BatDB`; the workspace variable `BatParams` remains reserved for the state created by `InitBatteryMKBM.m`.

Every record has `BatteryModel = 2` because entries in this database are intended for MKBM simulations. Mandatory fields: `BatteryType` and `NominalCapacity_kWh`. The 14 MKBM fields are optional, and an empty cell is imported as `NaN`.

The CSV has 19 columns. The first five are `Name`, `Manufacturer`, `Technology`, `BatteryType` and `NominalCapacity_kWh`. Columns 6–19 are the 14 `MKBM_*` fields, in the same order as rows 9–22 of the `BatteryMKBM` sheet; the two power columns are named `MKBM_Pmax_ch_kW` and `MKBM_Pmax_dis_kW` in the CSV. The loader renames those three fields in the returned struct:

```matlab
NominalCapacity <- NominalCapacity_kWh
MKBM_Pmax_ch    <- MKBM_Pmax_ch_kW
MKBM_Pmax_dis   <- MKBM_Pmax_dis_kW
```

### Batteries included

| Name | Technology | Type | Capacity (kWh) | Life cycles | Life DoD | Calendar life (years) | Self-discharge (%/month) |
|---|---|---:|---:|---:|---:|---:|---:|
| Pylontech US2000C | Li-ion LFP | 2 | 2.4 | 6000 | 0.8 | 10 | 3 |
| Tesla Powerwall 2 | Li-ion NMC | 3 | 13.5 | 3200 | 1.0 | 10 | 3 |
| BYD Battery-Box HVS 5.1 | Li-ion LFP | 2 | 5.12 | 6000 | 0.8 | 10 | 3 |
| LG Chem RESU10H | Li-ion NMC | 3 | 9.8 | 4000 | 0.8 | 10 | 3 |
| Trojan T-105 | Lead-acid | 1 | 1.35 | 1200 | 0.5 | 5 | 10 |
| Rolls Surrette S-550 | Lead-acid | 1 | 2.57 | 1500 | 0.5 | 7 | empty |
| SonnenBatterie eco 8.0 | Li-ion LFP | 2 | 8.0 | 10000 | 1.0 | 10 | 3 |

Empty temperature or self-discharge cells are deliberate when no reliable datasheet or literature value was available; they follow the optional-field rule described above.

## Worksheet layout and row indexing

The current input templates use the database-style layout. Labels are placed in column B and values in column C. Because `xlsread` returns only numeric cells in `NUMERIC`, the first three text rows are skipped, so the visible row is the `NUMERIC` row plus 3. Text values, such as component names, are read from `RAW` using the visible row and column directly.

### `PVgen` sheet

| Row | Column B | Read as | Use |
|---|---|---|---|
| 4 | `Use_Database_PV` | `NUMERIC(1,3)` | database selector |
| 5 | `Module_Name` | `RAW{5,3}` | exact name from `CEC_Modules.csv` |
| 6 | `N_Modules` | `NUMERIC(3,3)` | number of modules in the array |
| 7 | `PVnom` | `NUMERIC(4,3)` | manual array nominal power, kWp |
| 8 | `CVPT` | `NUMERIC(5,3)` | manual temperature coefficient, %/K |
| 9 | `NOCT` | `NUMERIC(6,3)` | manual nominal operating cell temperature, °C |
| 10 | `Rth` | `NUMERIC(7,3)` | manual thermal resistance |
| 12 | `Mounting` | `NUMERIC(9,3)` | mounting-structure selector |
| 15 | `Inclination` | `NUMERIC(12,3)` | static structure inclination |
| 16 | `Orientation` | `NUMERIC(13,3)` | static structure orientation |
| 19 | `Inclination` | `NUMERIC(16,3)` | delta structure inclination |
| 22 | `Inclination` | `NUMERIC(19,3)` | azimuthal tracker inclination |
| 24 | `PV_DC_share` | `NUMERIC_PV(21,3)` | AC-bus PV share; only present in `inputdata_hybridAC.xlsx` |

Rows 7–10 are used only in manual mode. `PV_DC_share` defaults to `0.5` when missing and is forced to `1.0` for every application except Application 4, the hybrid AC bus.

### `Inverter` and `GridInverter` sheets

`GridInverter` is required only for Application 4 and exists in `inputdata_hybridAC.xlsx`. The two sheets use the same row positions:

| Row | `Inverter` | `GridInverter` | Read as |
|---|---|---|---|
| 4 | `Use_Database_Inv` | `Use_Database_GridInv` | `NUMERIC(1,3)` |
| 5 | `Inverter_Name` | `Grid_Inverter_Name` | `RAW{5,3}` |
| 6 | `PInom` | `PGInom` | `NUMERIC(3,3)` |
| 7 | `PImax` | `PGImax` | `NUMERIC(4,3)` |
| 8 | `InverterCurve` | `GridInverterCurve` | `NUMERIC(5,3)` |
| 10 | `k0` | `k0_g` | `NUMERIC(7,3)` |
| 11 | `k1` | `k1_g` | `NUMERIC(8,3)` |
| 12 | `k2` | `k2_g` | `NUMERIC(9,3)` |
| 15–20 | efficiency points | efficiency points | `NUMERIC(12:17,2)` and `NUMERIC(12:17,3)` |

In manual mode, a curve selector equal to `1` reads the three coefficients directly; any other value fits the six load/efficiency points through `InverterParameters` or `GridInverterParameters`. In database mode, the calls are:

```matlab
[PInom, PImax, k0, k1, k2] = Load_CEC_Inverter(inverter_name, 'battery');
[PGInom, PGImax, k0_g, k1_g, k2_g] = Load_CEC_Inverter(grid_inverter_name, 'grid');
```

### `BatteryMKBM` sheet

The current layout uses rows 4–22:

| Row | Column B | Read as | CSV column | Unit / meaning |
|---|---|---|---|---|
| 4 | `Use_Database_Bat` | `NUMERIC(1,3)` | — | database selector |
| 5 | `Battery_Name` | `RAW{5,3}` | `Name` | exact battery name |
| 6 | `N_Batteries` | `NUMERIC(3,3)` | — | number of parallel batteries |
| 7 | `BatteryModel` | `NUMERIC(4,3)` | — | model selector |
| 8 | `BatteryType` | `NUMERIC(5,3)` | `BatteryType` | chemistry selector |
| 9 | `MKBM_c` | `NUMERIC(6,3)` | `MKBM_c` | available-tank capacity ratio |
| 10 | `MKBM_k` | `NUMERIC(7,3)` | `MKBM_k` | inter-tank rate constant, 1/h |
| 11 | `MKBM_eta_ch` | `NUMERIC(8,3)` | `MKBM_eta_ch` | charge efficiency, fraction 0–1 |
| 12 | `MKBM_eta_dis` | `NUMERIC(9,3)` | `MKBM_eta_dis` | discharge efficiency, fraction 0–1 |
| 13 | `MKBM_Pmax_ch` | `NUMERIC(10,3)` | `MKBM_Pmax_ch_kW` | charge power, kW |
| 14 | `MKBM_Pmax_dis` | `NUMERIC(11,3)` | `MKBM_Pmax_dis_kW` | discharge power, kW |
| 15 | `MKBM_LifeCycles` | `NUMERIC(12,3)` | `MKBM_LifeCycles` | cycle life at reference DoD |
| 16 | `MKBM_LifeDoD` | `NUMERIC(13,3)` | `MKBM_LifeDoD` | reference depth of discharge |
| 17 | `MKBM_CalendarLife` | `NUMERIC(14,3)` | `MKBM_CalendarLife` | calendar life, years |
| 18 | `MKBM_MinChargeTemp` | `NUMERIC(15,3)` | `MKBM_MinChargeTemp` | minimum charging temperature, °C |
| 19 | `MKBM_MaxChargeTemp` | `NUMERIC(16,3)` | `MKBM_MaxChargeTemp` | maximum charging temperature, °C |
| 20 | `MKBM_MinDischargeTemp` | `NUMERIC(17,3)` | `MKBM_MinDischargeTemp` | minimum discharging temperature, °C |
| 21 | `MKBM_MaxDischargeTemp` | `NUMERIC(18,3)` | `MKBM_MaxDischargeTemp` | maximum discharging temperature, °C |
| 22 | `MKBM_SelfDischarge` | `NUMERIC(19,3)` | `MKBM_SelfDischarge` | self-discharge rate, % per month |

`BatteryModel` uses `1` for the simple model and `2` for MKBM. `BatteryType` uses `1` for lead-acid, `2` for LFP, `3` for NMC, `4` for LTO and `5` for custom.

In manual mode, an empty `BatteryModel` or `BatteryType` cell defaults to `1`. Each optional MKBM parameter is assigned only when the corresponding cell contains a number; empty cells leave the chemistry defaults defined in `InitBatteryMKBM.m` in force.

In database mode, `ReadBatteryMKBM.m` performs the following steps:

1. Reads `Battery_Name` from row 5, column C. An empty name stops execution with an error.
2. Reads `N_Batteries` from row 6, column C; the default is 1.
3. Calls `Load_PVlite_Battery` and stores the CSV record in `BatDB`.
4. Overwrites the model, chemistry and bank capacity:

   ```matlab
   BatteryModel = BatDB.BatteryModel;
   BatteryType  = BatDB.BatteryType;
   CBAT         = BatDB.NominalCapacity * N_Batteries;
   ```

5. Assigns each MKBM parameter only when the CSV value is not `NaN`.
6. Scales only the two power limits by `N_Batteries`:

   ```matlab
   MKBM_Pmax_ch  = BatDB.MKBM_Pmax_ch  * N_Batteries;
   MKBM_Pmax_dis = BatDB.MKBM_Pmax_dis * N_Batteries;
   ```

Cycle life, reference DoD, calendar life, temperature limits and self-discharge are properties of the selected battery model and are not multiplied by `N_Batteries`.

`ReadInputData.m` reads the capacity from the main `Battery` sheet before calling `ReadBatteryMKBM`, so the database value of `CBAT` replaces the capacity entered in that sheet.

If the `BatteryMKBM` sheet is absent or cannot be read, PVlite warns and falls back to:

```matlab
Use_Database_Bat = 1;
Battery_Name = '';
N_Batteries = 1;
BatteryModel = 1;
BatteryType = 1;
```

## Legacy workbooks

Older input files that do not contain a `Use_Database_*` row are still supported. `HasDatabaseHeader.m` scans the first 10 rows and 4 columns of the worksheet for a label whose normalized form begins with `usedatabase`. `NormalizeSheetLabel.m` converts the label to lowercase alphanumeric text, so `Use_Database_PV`, `Use_Database_Inv`, `Use_Database_GridInv` and `Use_Database_Bat` are all recognized.

When no database header is found, the manual offsets are zero and the selectors default to manual input:

| Sheet | Legacy offset | Current database-style offset |
|---|---:|---:|
| `PVgen` | `pvOffset = 0` | `pvOffset = 3` |
| `Inverter` | `invOffset = 0` | `invOffset = 2` |
| `BatteryMKBM` | `batOffset = 0` | `batOffset = 3` |

These offsets are row displacements used when selecting manual parameters. They are distinct from the visible-row-to-`NUMERIC` shift caused by the three initial text rows.

The legacy `BatteryMKBM` manual parameters occupy `NUMERIC` rows 1–16 and use the same parameter order as visible rows 7–22 of the current layout. `GridInverter` has no legacy-layout fallback: Application 4 expects the current database-style structure, and a missing or malformed sheet stops execution.

The distributed `inputdata_*.xlsx` templates already include the database rows, so they do not need to be modified.

## Error and warning behavior

| Situation | Behavior |
|---|---|
| CSV file missing from `ddbb/` | error |
| Component name not found | error |
| Duplicate component name | warning; first match used |
| Mandatory field missing in the selected CSV record | error; required fields are listed in each loader section |
| Inverter selected for `role = 'battery'` without `CEC_hybrid = 'Y'` | warning |
| Empty optional MKBM CSV field | `NaN`; parameter not assigned, so the default or no-restriction behavior applies |
| `Use_Database_Bat = 2` with an empty `Battery_Name` | error |
| `BatteryMKBM` sheet absent or unreadable | warning; simple lead-acid fallback shown above |
| `GridInverter` sheet absent or malformed in Application 4 | warning followed by error |

## Example component names

The names must be copied exactly from the corresponding CSV file.

### PV modules

- `Ablytek 6MN6A275`
- `Advance Power API-P210`

### Inverters

- `Ginlong Technologies Co - Ltd : Solis-1P8K-4G-US [240V]`
- `Shenzhen Growatt New Energy Co - Ltd : GROWATT 8000MTLP-US [240V]`

### Hybrid/bidirectional inverter

- `Afore New Energy Technology (Shanghai) Co - Ltd : AF6K-DH [240V]`

The seven battery names available in `PVlite_Batteries.csv` are listed in the battery table above.

## Author

Itahisa Hernández Fumero - 2026  
Instituto de Energía Solar, Universidad Politécnica de Madrid
