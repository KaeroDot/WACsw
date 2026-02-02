# WACsw Development Guide

## Project Overview

WACsw is a **quantum metrology system** for wideband AC voltage calibration using Programmable Josephson Voltage Standard (PJVS) technology, operating up to 100 kHz. The project combines LabVIEW control software with MATLAB/Octave data processing for precision AC voltage measurements.

**Project context:** Developed under EPM project 23RPT01 WAC - Wideband AC quantum traceability. See [project page](https://www.cem.es/es/WAC).

## Measurement Types Explained

1. **FR (Frequency Response):** Calibrates digitizer amplitude/phase response across bandwidth using AC-AC transfer. Long measurement (~2GB data), run infrequently.

2. **CE (Cable Error):** Corrects for cable impedance effects by comparing short vs. PJVS cable paths. Fast measurement (~8MB), run before/after SS measurements.

3. **SS (Sub-Sampling):** PJVS-based DUT calibration using sub-sampling with quantum voltage steps. Requires PJVS hardware + switch.

## Measurement Workflow

- First a FR measurement is performed to characterize the digitizer.
- Next a CE measurement is performed to characterize the cable error. FR results are needed to calculate results of CE.
- Next a SS measurement is performed to calibrate the DUT. Both FR and CE results are needed to calculate results of SS.

## Software architecture: Two Subsystems

### Control Software (`control_software/`)

- **Language:** LabVIEW
- **Purpose:** Real-time measurement control and hardware interfacing
- **Key components:**
  - `LV_source/WACsw.lvproj` - Main LabVIEW project file
  - LV_source/Main GUI/GUI main.vi - Main GUI, starting point of the controll software.
  - Hardware drivers: General AC source, General DC meter, General PJVS driver
  - Integration with TWM (TracePQM WattMeter) for digitizer sampling
- **Builds:** Versioned releases in `WACsw builds/`

### Data Processing (`data_processing/`)

- **Language:** MATLAB/GNU Octave (compatible with both)
- **Purpose:** Post-measurement analysis and calibration calculations
- **Key workflow:** Three measurement types, each with G (Generator), P (Processor) functions:
  - **FR (Frequency Response):** `G_FR.m` generates simulated data, `P_FR.m` processes real measurements
  - **CE (Cable Error):** `G_CE.m` generates simulated cable error, `P_CE.m` calculates corrections
  - **SS (Sub-Sampling):** `G_SS.m` simulates PJVS sampling, `P_SS.m` applies FR/CE corrections
- **Testing:** Each subsystem has `selftest_*.m` scripts (e.g., `selftest_FR.m`, `selftest_CE.m`)

### Function Naming Pattern for Data Processing

- **G_XX:** Data generator/simulator (e.g., `G_FR`, `G_CE`, `G_SS`)
- **P_XX:** Data processor (e.g., `P_FR`, `P_CE`, `P_SS`)
- **M_XX:** Measurement data structure (e.g., `M_FR`, `M_CE`, `M_SS`)

## Data Structures in Data Processing

- All measurement functions use structured data. Each data represents structure with `.v` (value), `.u` (uncertainty) fields.
- FR measurement use structure `M_FR` that contains Frequency Response measurement or simulated data.
- CE measurement use structure `M_CE` that contains Cable Error measurement or simulated data.
- SS measurement use structure `M_SS` that contains Sub-Sampling measurement or simulated data.

Structures are initialized with `check_gen_*.m` helper functions.

### *_fit Structures (Calibration Results) in Data Processing

Processing functions return fit structures for correction application:

- `FR_fit` - Frequency response fit, used by `piecewise_FR_evaluate()`
- `CE_fit` - Cable error fit, used by `CE_fit_evaluate()`

### MATLAB/Octave Compatibility

- Use `isOctave()` helper function (see `check_environment.m`) for conditional code
- Avoid MATLAB-only functions; avoid GNU Octave only functions; avoid Octave code extensions to keep compatibility with Matlab

### Verbosity Control in Data Processing

All major functions accept `verbose` parameter (0/1 or false/true):

## External Dependencies

- **QWTB:** Quantum measurement toolbox for uncertainty analysis. [qwtb.github.io](https://qwtb.github.io/qwtb/)
- **TWM (TracePQM WattMeter):** Digitizer interface, must run as server. [GitHub: smaslan/TWM](https://github.com/smaslan/TWM)
- Some TWM functions copied locally (e.g., `correction_interp_table.m`, `correction_load_table.m`)
