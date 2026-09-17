# Economic Analysis (CAPEX & OPEX)

## Overview

PVlite includes an economic post-processing script, `EconomicsCalculations.m`, that converts the simulated system configuration and energy results into cost indicators. It is a script rather than a function, so it uses the variables already present in the MATLAB workspace at the end of the simulation.

The script calculates:

- Total initial CAPEX (capital expenditure).
- Annual OPEX (operational expenditure).
- Net Present Cost (NPC) over the project lifetime.
- Annualized Cost.
- Discounted battery-replacement cost, when multi-year battery replacements are reported.
- Discounted genset fuel cost, when fuel consumption is available.

## When the calculations run

`EconomicsCalculations.m` is executed at the end of both entry points:

```matlab
pvlite.m
mainMultiYear.m
```

No additional command is required after a normal simulation. The results are printed to the MATLAB console, and the economic figure is generated when `PlotEconomicsFlag` is enabled.

`PlotEconomicsFlag` is hardcoded to `1` in `ReadInputData.m`; it is not a workbook parameter.

## Excel configuration

The economic parameters are defined in the input files, for example `inputdata_grid.xlsx` or `inputdata_hybridAC.xlsx`. The workbook must contain a sheet named exactly **`Economics`**.

The current sheet layout is:

| Excel row | Column A | Column B | Column C | Column D | Column E |
|---:|---|---|---:|---|---|
| 1 | | `ECONOMICS` | | | |
| 2 | | | | | |
| 3 | | `Parameter` | `Value` | `Units` | `Description` |
| 4 | 1 | `PV_Module_Cost` | 0.30 | EUR/Wp | PV modules specific cost |
| 5 | 2 | `Inverter_Cost` | 0.15 | EUR/W | Inverter specific cost |
| 6 | 3 | `Battery_Cost` | 200 | EUR/kWh | Battery bank specific cost |
| 7 | 4 | `Genset_Cost` | 300 | EUR/kW | Backup genset specific cost |
| 8 | 5 | `Wind_Cost` | 0 | EUR/kW | Wind turbine specific cost |
| 9 | 6 | `Fuel_Cost` | 1.5 | EUR/L | Genset fuel cost |
| 10 | 7 | `Fixed_Installation_Cost` | 1000 | EUR | Fixed installation and permitting costs |
| 11 | 8 | `Opex_Factor` | 0.01 | — | Annual OPEX as a fraction of CAPEX |
| 12 | 9 | `Discount_Rate` | 0.05 | — | Annual real discount rate for NPC |

The values in column C above are the ones distributed with `inputdata_hybridAC.xlsx`. Other templates may use different values; for example, applications without a genset may set `Genset_Cost` to zero.

The labels in the current templates are `ECONOMICS` and `Parameter`, without a leading semicolon.

`ReadInputData.m` reads the nine parameters from `NUMERIC(1,3)` through `NUMERIC(9,3)`. Because the first three rows are text, the visible row is the numeric row plus 3.

`Project_Lifetime` is not read from the `Economics` sheet. It is read from the `Options` sheet, row 10, as `NUMERIC(7,3)`. The distributed templates set:

```text
Project_Lifetime = 25
```

## Missing or incomplete data

If the `Economics` sheet cannot be read, `ReadInputData.m` prints:

```text
Warning: Could not read Economics sheet. Defaulting economic parameters to 0.
```

and sets all nine economic parameters to zero. The simulation continues; this is not a fatal error.

If the sheet exists but an individual cell is empty or non-numeric, only that parameter defaults to zero.

## CAPEX calculation

CAPEX starts from the fixed installation cost and adds the component costs that are present in the workspace:

```matlab
CAPEX = Fixed_Installation_Cost;
```

### PV array

```matlab
PV_Total_Cost = PV_Cost_Power * 1000 * PV_Module_Cost;
```

`PV_Cost_Power` is chosen in this order:

1. `PVnom_initial`, when running `mainMultiYear.m`;
2. `PVnom`, for a single-year run;
3. `0`, if neither variable exists.

Using `PVnom_initial` means that the investment cost is based on the installed nameplate power, not on the degraded power of the final simulated year.

### Inverter

```matlab
Inverter_Total_Cost = PInom * 1000 * Inverter_Cost;
```

This term is added when `PInom` exists. `PInom` is in kW and `Inverter_Cost` is in EUR/W.

### Battery

```matlab
Battery_Total_Cost = CBAT * Battery_Cost;
```

`CBAT` is in kWh and `Battery_Cost` is in EUR/kWh. When the MKBM battery database is used, `CBAT` has already been overwritten by:

```matlab
CBAT = NominalCapacity_kWh * N_Batteries
```

### Genset

```matlab
Genset_Total_Cost = PGENnom * Genset_Cost;
```

`PGENnom` is in kW and `Genset_Cost` is in EUR/kW. The term is added when `PGENnom` exists.

### Wind turbine

```matlab
Wind_Total_Cost = PWnom * Wind_Cost;
```

The wind term is added only when `PWnom` exists, is non-empty, is greater than zero, and `Wind_Cost` exists.

## OPEX calculation

Annual OPEX is a fixed fraction of the initial CAPEX:

```matlab
OPEX_Annual = CAPEX * Opex_Factor;
```

For example, `Opex_Factor = 0.01` means 1% of the initial investment per year. OPEX is not escalated with inflation and is not increased after a battery replacement.

## Battery replacement cost

Multi-year MKBM simulations can report:

```matlab
battery_replacements
replacement_years
```

When at least one replacement occurs, each replacement is valued at the initial battery bank cost and discounted to present value:

```matlab
Battery_Replacement_NPC = Battery_Replacement_NPC + ...
    Battery_Total_Cost / ((1 + Discount_Rate) ^ rep_year);
```

Only replacements with `rep_year <= Project_Lifetime` are counted. The result is added to the NPC, not to the initial CAPEX. No inflation or future price change is applied.

## Fuel cost

If `Fuel_Cost` is greater than zero, the script calculates the genset fuel cost from one of two sources.

### Multi-year simulations

`mainMultiYear.m` provides `fuel_by_year`. In that case:

```matlab
Annual_Fuel_Cost = mean(fuel_by_year) * Fuel_Cost;
```

and each year is discounted separately:

```matlab
Fuel_Cost_NPC = Fuel_Cost_NPC + fuel_by_year(yy) * Fuel_Cost / ((1 + Discount_Rate)^yy);
```

This captures the extra fuel burned in later years as the PV field degrades.

### Single-year simulations

If `fuel_by_year` is absent but the hourly `FUEL` matrix exists, the annual fuel cost is:

```matlab
Annual_Fuel_Cost = sum(sum(FUEL)) * Fuel_Cost;
```

The same annual amount is then repeated over the project lifetime using the present-value annuity factor.

If `Discount_Rate = 0`, fuel costs are summed without discounting.

## NPC and annualized cost

When `Project_Lifetime` exists and is greater than zero, the present-value annuity factor is:

```matlab
PVA_factor = (1 - (1 + Discount_Rate)^(-Project_Lifetime)) / Discount_Rate;
```

If `Discount_Rate = 0`, then:

```matlab
PVA_factor = Project_Lifetime;
```

The NPC is:

```matlab
NPC = CAPEX + OPEX_Annual * PVA_factor + Battery_Replacement_NPC + Fuel_Cost_NPC;
```

The capital recovery factor is:

```matlab
CRF = (Discount_Rate * (1 + Discount_Rate)^Project_Lifetime) / ...
      ((1 + Discount_Rate)^Project_Lifetime - 1);
```

and the annualized cost is:

```matlab
Annualized_Cost = NPC * CRF;
```

If `Discount_Rate = 0`, the annualized cost is simply:

```matlab
Annualized_Cost = NPC / Project_Lifetime;
```

If `Project_Lifetime` is missing or non-positive, the script uses the fallback:

```matlab
NPC = CAPEX + OPEX_Annual + Battery_Replacement_NPC + Fuel_Cost_NPC;
Annualized_Cost = NPC;
```

## Console report

The script prints a report with the following structure:

```text
==================================================
ECONOMIC ANALYSIS
==================================================
PV Array Cost:           € ...
Inverter Cost:           € ...
Battery Bank Cost:       € ...
Genset Cost:             € ...
Wind Turbine Cost:       € ...
Fixed Installation Cost: € ...
--------------------------------------------------
Total Initial CAPEX:     € ...
Annual OPEX:             € .../year
Battery Replacements:    ... (year(s): ...)
Battery Replacement Cost (NPC): € ...
Genset Fuel Cost (NPC):  € ...
Project Lifetime:        ... years
Discount Rate:           ...%
Net Present Cost (NPC):  € ...
Annualized Cost:         € .../year
==================================================
```

The PV array cost and fixed installation cost are always printed. The inverter, battery, genset, wind, battery-replacement and fuel lines are printed only when the corresponding cost is greater than zero.

## Economic figure

If `PlotEconomicsFlag == 1`, `EconomicsCalculations.m` calls:

```matlab
PlotEconomics;
```

The figure is generated only when:

```matlab
CAPEX > 0
```

It contains two subplots side by side.

### CAPEX breakdown

The left subplot is a pie chart with the non-zero CAPEX components:

- PV array
- inverter
- battery bank
- genset
- wind turbine
- fixed installation

Each slice is labeled in the legend with its percentage of total CAPEX.

### Cost evolution

The right subplot is a bar chart of cumulative nominal cost from year 0 to `Project_Lifetime`:

```matlab
cumulative_cost(1) = CAPEX;
cumulative_cost(y) = cumulative_cost(y-1) + OPEX_Annual + Annual_Fuel_Cost;
```

Year 0 is also marked with a black dot. A dashed horizontal line shows the NPC.

The bars are nominal, undiscounted cumulative costs, while the NPC line is a discounted value. The two quantities are related but not directly comparable year by year.

If `Project_Lifetime` is missing or non-positive, the subplot displays `Lifetime not defined` instead of a chart.

## Multi-year interaction

`mainMultiYear.m` supplies the variables that make the economic analysis lifetime-aware:

```matlab
PVnom_initial
fuel_by_year
battery_replacements
replacement_years
```

It also accumulates lifetime energy totals before calling `EconomicsCalculations.m`.

The distributed templates set `Project_Lifetime = 25` and `PV_Degradation_Rate = 0`. Therefore, even a single-year run through `pvlite.m` uses a 25-year economic horizon for OPEX and fuel discounting, although it simulates only one representative year of energy production.

## Assumptions and limitations

The current economic model:

- uses constant real prices;
- does not apply inflation to OPEX, fuel or battery replacements;
- does not include residual value, taxes, subsidies or financing fees;
- does not include revenue from exported energy;
- values every battery replacement at the initial battery bank cost;
- calculates OPEX as a fixed fraction of the initial CAPEX;
- discounts future costs using the real discount rate from the `Economics` sheet.

These assumptions should be kept in mind when comparing NPC or Annualized Cost between designs.

## Author

Itahisa Hernández Fumero - 2026  
Instituto de Energía Solar, Universidad Politécnica de Madrid
