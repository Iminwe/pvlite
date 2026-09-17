# Multi-year Simulation and Automatic Degradation

## Overview

A default PVlite run simulates one year. `mainMultiYear.m` wraps that same
8760-hour calculation in a loop over the whole project lifetime, so the results
account for equipment aging instead of repeating an identical year:

- the PV generator loses a fraction of its nominal power every year;
- the battery carries its State of Health from one year to the next, and is
  replaced when it reaches its end of life;
- energy, fuel and dumped-energy totals are accumulated over the lifetime;
- the economic analysis at the end uses the same `Project_Lifetime`.

The entry point is independent: `pvlite.m` does **not** call `mainMultiYear.m`.
To run a multi-year simulation, run `mainMultiYear.m` in MATLAB instead of
`pvlite.m`.

## Key features

### 1. PV module degradation

Photovoltaic modules lose a small percentage of their nominal power every year,
typically between 0.5% and 1%. The loop applies that loss compounding, relative
to the original nameplate power:

```matlab
PVnom = PVnom_initial * ((1 - PV_Degradation_Rate) ^ (current_year - 1));
```

`PVnom_initial` is captured once, before the loop, so year 1 always runs at the
nameplate value and the degradation never accumulates on top of an already
degraded figure. `PV_Degradation_Rate` is a fraction, not a percentage: 0.005
means 0.5% per year.

The degraded `PVnom` feeds `Irradiances`, `Temperatures` and `PVpower`
(or `PVpower_delta` for `Mounting == 2`), which are regenerated at the start of
every year.

### 2. Battery cycle life and replacement

With the Modified Kinetic Battery Model (MKBM) active, the battery keeps its
aging state between years. `BatParams.SOH` is not reset when a new year starts,
so capacity fade, power fade, cycling aging and calendar aging carry over.

Before each year, the loop checks whether the battery survived the previous one:

```matlab
if exist('BatParams', 'var') && BatParams.SOH < 0.80
    battery_replacements = battery_replacements + 1;
    replacement_years = [replacement_years, current_year];
    ResetBattery = 1;
else
    ResetBattery = 0;
end
```

The trigger is the State of Health alone: a replacement happens when `SOH` drops
below 80%, the usual end-of-life threshold. Cycle counts are not a separate
trigger; they influence `SOH` through the energy-throughput aging model
described in `README_MKBM.md`.

`ResetBattery = 1` makes the dispatcher rebuild `BatParams` from scratch via
`InitBatteryMKBM.m`, restoring full capacity, full power limits and `SOH = 1`.
The replacement is logged with the year in which it takes effect, and the check
runs before the year is simulated, so a replacement recorded at year *N* means
the battery entered year *N* below 80%.

Applications without a battery dispatch (grid-connected and pumping) never set
`BatParams`, so the check is skipped and no replacement is ever counted.

### 3. Multi-year flow

```matlab
for current_year = 1:Project_Lifetime
    % 1. Degrade PVnom
    % 2. Regenerate irradiance, temperature and PV power
    % 3. Check battery end of life, set ResetBattery
    % 4. Dispatch the application
    if (Application==1)
        mainGrid;
    elseif (Application==2)
        mainSA;
    elseif (Application==3 || Application==4)
        mainHybrid;
    elseif (Application==5)
        mainPump;
    end
    % 5. Append SOH_mat to SOH_history, track replacement segments
    % 6. Accumulate yearly energy, fuel and dump totals
end
```

`ReadInputData` runs once, before the loop, so the configuration file is read a single
time. Each iteration reuses the same site, load and component data.

### 4. Degradation history

Two variables are built up across the loop for post-processing:

| Variable | Content |
|---|---|
| `SOH_history` | Column vector with every sample of `SOH_mat` from every year, in order |
| `bat_segment_starts` | Sample indices at which each battery unit begins its life; the first unit starts at sample 1 |

When a replacement occurs, the index of the first sample of the new unit is
appended to `bat_segment_starts` before that year's SOH is added to the history.
`PlotBatteryDegradation.m` uses both to plot the whole lifetime in years, mark
each replacement with a vertical dashed line and restart the calendar-aging
counter at every segment. See `README_MKBM.md`.

### 5. Graphics in multi-year mode

Sankey diagrams are single-year graphics. `mainSA.m` and `mainHybrid.m` guard
them with:

```matlab
if ~exist('Project_Lifetime', 'var') || Project_Lifetime == 1
    SankeySA;               % or SankeyHybrid_DCbus / SankeyHybrid_ACbus
end
```

With `Project_Lifetime = 25` the diagrams are skipped, which keeps a lifetime
run from opening dozens of figures. To inspect the energy flows of a single
year, set `Project_Lifetime` to 1 and run `pvlite.m`, or use
`CompareBatteryModels`.

Results are printed to the Command Window and remain available as workspace variables.

## Usage

Configure the two parameters in the `Options` sheet of the input file.
The shipped templates already contain both rows:

| Row | Column A | Column B | Column C | Column D | Value in the templates |
|---|---|---|---|---|---|
| 10 | 7 | `Project_Lifetime` | 25 | years | 25 |
| 11 | 8 | `PV_Degradation_Rate` | 0 | — | 0 |

Internally `ReadInputData.m` reads them as `NUMERIC(7,3)` and `NUMERIC(8,3)`,
which correspond to rows 10 and 11 in the current sheet layout. Both are
optional:

| Parameter | Default when the row is missing or empty |
|---|---|
| `Project_Lifetime` | 1 (a single-year run) |
| `PV_Degradation_Rate` | 0 (no degradation) |

With `PV_Degradation_Rate = 0`, as shipped, every year produces the same PV
output and only battery aging changes the results. Set it to the annual loss
fraction declared in the module datasheet to model a realistic decline.

Then run in MATLAB:

```matlab
mainMultiYear
```

Select the input file when prompted. The Command Window prints the progress of
each year, the degraded `PVnom`, and any battery replacement event.

## Results

At the end of the loop `mainMultiYear.m` prints a summary block:

```text
==================================================
MULTI-YEAR SIMULATION RESULTS (25 YEARS)
==================================================
Total Ideal PV Energy (EPV0a): ... kWh
Total Gross PV Energy (EPV2a, before regulation): ... kWh
Total PV Energy (EPVa, after regulation): ... kWh
Total Genset Energy (EGENa): ... kWh
Total Energy Produced (PV+genset+wind): ... kWh
Total Load Demand (ELOADa): ... kWh
Total Energy Served (EACa): ... kWh
Total Fuel Consumed: ... liters          (Applications 3 and 4 only)
Total Dumped/Excess Energy (EDUMPa): ... kWh   (Applications 3 and 4 only)
Total Battery Replacements: N
Replacement Years: ...
Final Battery SOH at Year 25: ... %
==================================================
```

The accumulated variables are also left in the workspace:

| Variable | Content |
|---|---|
| `total_pv_energy_ideal` | Sum of `EPV0a`: ideal PV energy, no losses and no curtailment |
| `total_pv_energy_gross` | Sum of `EPV2a`: PV energy after temperature and DC wiring losses, before regulation |
| `total_pv_energy` | Sum of `EPVa`: PV energy after losses and regulation |
| `total_genset_energy` | Sum of `EGENa` |
| `total_wind_energy` | Sum of `EWINDa` |
| `total_energy_produced` | PV plus genset plus wind |
| `total_load_energy` | Sum of `ELOADa` |
| `total_ac_energy` | Sum of `EACa`: energy actually served to the load |
| `total_fuel_consumed` | Sum of `FUEL` [liters] |
| `total_dump_energy` | Sum of `EDUMPa`: energy that could not be used |
| `pv_energy_by_year` | `EPVa` of each year |
| `genset_energy_by_year` | `EGENa` of each year |
| `dump_energy_by_year` | `EDUMPa` of each year |
| `fuel_by_year` | Fuel of each year [liters] |
| `battery_replacements` | Number of replacements |
| `replacement_years` | Years in which a replacement took effect |
| `SOH_history` | Full-lifetime SOH samples |
| `bat_segment_starts` | Start sample of each battery unit |

Every accumulation is guarded with `exist`, so applications that do not produce
a given variable (a grid-connected system has no genset, fuel or dump) simply
skip it.

`EDUMPa` reaches the summary through `DailyParameters.m`, `MonthlyParameters.m`
and `YearlyParameters.m`, which aggregate `PDUMP` for hybrid applications when
the MKBM dispatchers define it.

## Economic analysis

`mainMultiYear.m` ends with a call to `EconomicsCalculations`, so the lifetime
results feed directly into the economic analysis. `Project_Lifetime` is the
horizon used there for the present-value factor, the capital recovery factor,
the net present cost, the annualized cost, the fuel NPC and the discounted
battery replacements. A multi-year run and its economic summary are therefore
consistent: the same `Project_Lifetime` drives the number of
simulated years and the discounting period.

Battery replacements counted by the loop are the physical events; their cost is
handled by the economic module. See `README_Economics.md`.

## Notes

- `mainMultiYear.m` clears the workspace at the start unless the variable
  `run_as_test` is set, which the test suite uses to keep its own context.
- Each year regenerates the irradiance and temperature series from the same
  meteorological input, so the multi-year run models a repeated typical
  meteorological year with aging equipment. It does not use a different weather
  year per simulated year.
- The battery replacement threshold (80% SOH) is fixed in the code and is not an
  input parameter.
- Running 25 years of hourly dispatch takes roughly 25 times a single-year run.
  A coarser `Simulation step` in the `Options` sheet reduces the cost
  proportionally.

## Author

Itahisa Hernández Fumero - 2026  
Instituto de Energía Solar, Universidad Politécnica de Madrid
