#How to install FFmeter

1. Install [LabVIEW Runtime engine for Windows, 2020 SP-1, 32-bit](https://www.ni.com/en/support/downloads/software-products/download.labview-runtime.html#369481).
1. Install [TWM-version 1.10.0-full](https://github.com/smaslan/TWM-builds/tree/master/builds).
1. Install either Matlab or GNU Octave. In the case of [GNU Octave, use version 6.2.0, because higher versions are inexplicably slow in Windows](https://mirror.kumi.systems/gnu/octave/windows/) (e.g. octave-6.2.0-w64-64-installer.exe).
1. Download latest version of [FFmeter from Github](https://github.com/KaeroDot/WACsw/tree/master/control_software/Filter%20function%20meter%20builds).

#How to run FFmeter
1. Run TWM. Setup Digitizer and Matlab/GNU Octave.
1. Start TWM server.
1. Run FFmeter. Setup AC Source, TWM, DC Meter. Load Example template, or make your own.
1. Start Measurement.
1. Check that DC meter values are filled into the template.
1. Check that rms values measured by TWM are filled into the template - optionally you can switch off the calculation of the rms value, do only sampling, and calculate values later.

