# WACsw Development Guide

## Project Overview

WACsw is a **quantum metrology system** for wideband AC voltage calibration using Programmable Josephson Voltage Standard (PJVS) technology, operating up to 100 kHz. The project combines LabVIEW control software with MATLAB/GNU Octave data processing for precision AC voltage measurements.

**Project context:** Developed under EPM project 23RPT01 WAC - Wideband AC quantum traceability. See [project page](https://www.cem.es/es/WAC).

## Measurement Types Explained

Calibration consists of three measurement types.

1. **FR (Frequency Response):** Measurement is used to estimate digitizer amplitude response across digitizer bandwidth using AC-AC transfer method. FR response is used to correct sub-sampling measurements. FR is time consuming measurement, generates 100 MB to 2GB of data. FR measurement is run infrequently but FR results are needed for every CE and SS measurement.

2. **CE (Cable Error):** Measurent is used to estiamte cable impedance by comparing short vs. PJVS cable paths. CE is used to correct for cable errors. It is fast measurement, generates tenths of MB of data. CE measurement is run before and optionally also after every SS measurement.

3. **SS (Sub-Sampling):** Measurement is used to calibrate Device Under Test (DUT) amplitude using sub-sampling and PJVS as a voltage reference. It is fast measurement, generates tenths of MB of data. SS measurement requires results from CE and FR.

## Measurement Workflow

- First a FR measurement is performed to characterize the digitizer. This measurement can be run once because FR of a digitizer is quite stable.
- CE measurement is performed to characterize the cable error. FR results are needed to calculate results of CE.
- Next a SS measurement is performed to calibrate the DUT. Both FR and CE results are needed to calculate results of SS.
- Optionally second CE measurement is performed right after SS.

## Software architecture: Two Subsystems

### Control Software

- **Language:** LabVIEW
- **Purpose:** Real-time measurement control and hardware interfacing
- **Key components:**
  - `LV_source/WACsw.lvproj` - Main LabVIEW project file
  - LV_source/Main GUI/GUI main.vi - Main GUI, starting point of the controll software.
  - Hardware drivers: General AC source, General DC meter, General PJVS driver
  - Integration with TWM (TracePQM WattMeter) for digitizer sampling
- **Builds:** Versioned releases in `WACsw builds/`

### Data Processing

- **Language:** MATLAB/GNU Octave (must be compatible with both)
- **Purpose:** Post-measurement analysis and calibration calculations
- **Key workflow:** Three measurement types, each with G (Generator), P (Processor) functions:
  - **FR (Frequency Response):** `G_FR.m` generates simulated data, `P_FR.m` processes real measurements
  - **CE (Cable Error):** `G_CE.m` generates simulated cable error, `P_CE.m` calculates corrections
  - **SS (Sub-Sampling):** `G_SS.m` simulates PJVS sampling, `P_SS.m` applies FR/CE corrections
- **Testing:** Each subsystem has `selftest_*.m` scripts (e.g., `selftest_FR.m`, `selftest_CE.m`)
- **Data:** Example and testing data are stored in `example_data` directory.
- **Evaluation:** Functions to evaluate impact of various properties or calculation methods on final result of sub-sampling measurement.

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

- Use `isOctave()` helper function (see `check_and_set_environment.m`) for conditional code
- Avoid MATLAB-only functions; avoid GNU Octave only functions; avoid Octave code extensions to keep compatibility with Matlab,

### Verbosity Control in Data Processing

All major functions accept `verbose` parameter (0/1 or false/true):

## External Dependencies

- **QWTB:** Quantum measurement toolbox for uncertainty analysis. [qwtb.github.io](https://qwtb.github.io/qwtb/)
- **TWM (TracePQM WattMeter):** Digitizer interface, must run as server. [GitHub: smaslan/TWM](https://github.com/smaslan/TWM)
- Some TWM functions copied locally (e.g., `correction_interp_table.m`, `correction_load_table.m`)
