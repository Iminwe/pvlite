# AC Bus & Mixed Node Implementation for PVlite

## Overview

PVlite supports hybrid systems with an **AC bus** (`Application == 4`). In this
configuration the generators meet on the AC side and a bidirectional inverter manages
the battery, instead of every source feeding a DC bus first.

A **mixed DC/AC node** is also supported: part of the PV array is connected to the DC
bus through an MPPT controller, while the rest is connected to the AC bus through a
grid-tied inverter. The split is controlled by the `PV_DC_share` parameter.

## Files involved

### Grid inverter

- **`GridInverterParameters.m`**: computes the $k_0, k_1, k_2$ efficiency parameters of
  the grid-tied inverter from a set of efficiency points, using Schmid's model and a
  plain least-squares fit.
- **`ACpowerGridInverter.m`**: converts the AC-coupled PV power into the power actually
  delivered to the AC bus. It applies the inverter efficiency curve, the AC wiring
  losses `WAC`, and the saturation limits `PGImax` and `PGInom`; the result is `PAC_g`.
- **`GridInverterOFF.m`**: sets the grid inverter powers to zero when the effective
  irradiance falls below the start-up threshold (`Gef < Gth`).
- **`ReadInputData.m`**: reads the `GridInverter` sheet **only** when
  `Application == 4`, so legacy stand-alone workbooks are unaffected. In that case the
  sheet is mandatory: if it is missing or malformed, the reader warns
  (`Worksheet 'GridInverter' not found or incorrectly formatted`) and stops the
  simulation with `error('Simulation stopped: Missing GridInverter data for Application=4')`.

### Power calculations

- **`PowerCalculationsHybrid_ACbus.m`**: hourly dispatch for the AC-bus topology with
  the basic battery model.
- **`PowerCalculationsHybrid_MKBM_ACbus.m`**: the same dispatch with the Modified
  Kinetic Battery Model (MKBM), selected automatically by `mainHybrid.m` when
  `BatteryModel == 2`.
- **`SankeyHybrid_ACbus.m`**: draws the Sankey diagram of the AC-bus system, including
  the conversion losses of the bidirectional inverter.
- **`DailyParameters.m`, `MonthlyParameters.m`, `YearlyParameters.m`**: aggregate the
  dumped energy reported by the MKBM variant.

## Energy balance on the AC bus

The dispatch in `PowerCalculationsHybrid_ACbus.m` works as follows:

- The PV generation is split according to `PV_DC_share`:

  $$PPV\_AC = PPV \cdot (1 - PV\_DC\_share), \qquad PPV\_DC = PPV \cdot PV\_DC\_share$$

- `ACpowerGridInverter.m` turns `PPV_AC` into `PAC_g`, the AC power available after
  efficiency and wiring losses.
- Total generation on the AC bus:

  $$P_{TOT} = P_{AC\_g} + P_{GEN} + P_{WIND}$$

- The balance against the load is `P_AC_NET = PTOT - PLOAD`:
  - **Excess** (`P_AC_NET > 0`): the surplus flows through the bidirectional inverter
    acting as a rectifier and charges the battery, together with whatever the DC-coupled
    PV contributes (`PBAT = PBAT_from_AC + PPV_DC`).
  - **Deficit** (`P_AC_NET < 0`): the battery discharges through the same inverter to
    cover the AC demand. If the battery cannot supply the requested power,
    `InverterOFF` is called, the loss of load supply flag `LLH` is set, and the
    DC-coupled PV is curtailed to the power the battery can still accept.

### Regulation when the battery is full

The curtailment order is **AC saturation first, then wind, then total PV**:

1. The AC-coupled share is limited inside `ACpowerGridInverter.m`, where the grid
   inverter saturates at `PGImax` and `PPV_AC` is recomputed downwards.
2. The remaining excess charges the battery. When the battery reaches `SOCmax`, the
   charge power is capped and the overcharge branch recalculates the renewable
   requirement as `Req_RE = PBAT + PDC - PGEN`.
3. If `Req_RE <= 0`, both `PPV` and `PWIND` are set to zero. If `PPV > Req_RE`, the
   total PV output is clipped to `Req_RE` and the wind power is zeroed. Otherwise the
   wind power absorbs what is left: `PWIND = Req_RE - PPV`.

So the renewable that absorbs the curtailment is the wind: PV keeps priority and is
only clipped when it alone exceeds `Req_RE`, and in that case `PWIND` is already zero.
There is no separate DC-first stage: and there is no separate DC-first stage: the DC/AC
split happens before regulation, and the overcharge branch acts on the total PV. The
MKBM variant follows the same order and reports the unusable excess in
`PDUMP`, split into AC saturation, battery refusal and DC-side curtailment.

## Mixed node topology (DC/AC split)

- **`PV_DC_share`**: fraction of the PV power routed to the DC bus.
  - Configured in the `PVgen` sheet, under the `Mixed structure` header: label in
    column B, value in column C of **visible row 24**. The reader sees it as
    `NUMERIC_PV(21,3)`, because `xlsread` drops the three leading text rows of the
    sheet.
  - If the cell is missing or empty, the default is `0.5` (50% DC / 50% AC). The
    shipped `inputdata_hybridAC.xlsx` template uses `0.5`.
  - For `Application ~= 4` the value is forced to `1.0` (100% DC), preserving the
    behaviour of stand-alone, DC-hybrid and pumping systems.
  - `PowerCalculationsHybrid_ACbus.m` re-applies the `0.5` default if the variable is
    not present in the workspace.

## The `GridInverter` sheet

Only `inputdata_hybridAC.xlsx` ships this sheet; the other four templates do not
contain it. Structure (labels in column B, values in column C):

| Visible row | Internal index | Label | Content |
|---:|---:|---|---|
| 4 | 1 | `Use_Database_GridInv` | `1` manual, `2` read from `CEC_Inverters.csv` |
| 5 | — | `Grid_Inverter_Name` | exact name from the CEC database (read from `RAW{5,3}`) |
| 6 | 3 | `PGInom` | nominal output power, kW |
| 7 | 4 | `PGImax` | maximum output power, kW |
| 8 | 5 | `GridInverterCurve` | `1` use `k0_g`-`k2_g`, otherwise fit from points |
| 10-12 | 7-9 | `k0_g`, `k1_g`, `k2_g` | efficiency curve parameters |
| 15-20 | 12-17 | `pac` / `Efficiency [%]` | six efficiency points, fitted by `GridInverterParameters.m` |

The sheet has no legacy layout: it did not exist in PVlite 2.3, so `HasDatabaseHeader.m`
offsets do not apply to it.

## Execution

To run an AC bus simulation:

1. Set `Application = 4` in the `Options` sheet.
2. Provide a `GridInverter` sheet in the workbook. Without it the simulation stops.
3. Optionally set `PV_DC_share` in the `PVgen` sheet (default `0.5`).
4. Run `pvlite` for a single year, or `mainMultiYear` for a lifetime analysis.
5. `SankeyHybrid_ACbus.m` is called by `mainHybrid.m` only when `Project_Lifetime` is 1
   or undefined, so multi-year runs produce no Sankey figures.

## Author

Itahisa Hernández Fumero - 2026  
Instituto de Energía Solar, Universidad Politécnica de Madrid
