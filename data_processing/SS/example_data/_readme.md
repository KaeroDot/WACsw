# Example data of a subsampling measurement, by PTB

## 5922 filter function measurement
Files:

- `relative f 4 MSa_s filter ppm.txt`
- `relative f 10 MSa_s filter ppm.txt`
- `relative f 15 MSa_s filter ppm.txt`

The first column is the frequency relative to the sampling rate.
The second column is the gain deviation from nominal value in ppm after adjustment at the lowest frequency.

PXI settings: 10 V range, 48-tap filter function, for 4, 10 and 15  MSa/s.

## A cable error measurement. 
Files:

- `Cable error simple readout_352.txt`

The first column is the frequency.
The second column is the measured relative difference to the lowest frequency (500 Hz) in ppm.
The third column is the type-A uncertainty for the 2nd column.

## Subsampling measurement
## Files with sampled data:

- `All recorded points .txt`   -  2 repetitions (2 rows)
- `All recorded points _1.txt` -  2 repetitions (2 rows)
- `All recorded points _2.txt` - 11 repetitions (11 rows)

Every row in a file is a single record.

PXI setting: 4 MSa/s, 10 V range, Auto offset, Gain = 1.000152, 40 periods 

Calibrator:  100 kHz, 1 V nom which is about 110 ppm low at 1 kHz

## File with PJVS waveform:

- `1 V amplitude 70 dreieck 40 samples.txt`

First column: the start of the steps for 1 period related to the frequency (1 kHz in this case). Can be ignored. 
Second column: reference voltages of the PJVS array.

PJVS setting: 40 steps, triangular waveform, 20 Hz.

## Testing of the software
For testing of the software, the data are saved as follows:
- First record from file `All recorded points .txt` is saved as `example_record.mat`.
- Data from file `1 V amplitude 70 dreieck 40 samples.txt` is saved as `example_pjvs_voltages.txt`.
- Data from file `Cable error simple readout_352.txt` is saved as `example_cable_error.txt`.
- Data from file `relative f 4 MSa_s filter ppm.txt` is saved as `example_digitizer_rf.txt`.
- These files are part of the repository on github: `https://github.com/KaeroDot/WACsw/tree/master/data_processing/SS/example_data`
- The result can be calulated by running `/data_processing/SS/test_example_data` in GNU Octave/Matlab environment.
