# WACsw - software for Wideband AC quantum tracebility

Software and documentation for measurement method using Programmable Josephson Voltage Standard to calibrate AC voltage up to 100 kHz.
Developed in the scope of EPM project *23RPT01 WAC - Wideband AC quantum traceability*

[https://www.cem.es/es/WAC](https://www.cem.es/es/WAC)

## Links

[QWTB](https://qwtb.github.io/qwtb/)

[TWM](https://github.com/smaslan/TWM)

[TWM builds](https://github.com/smaslan/TWM-builds)

## Parts
### Filter function meter
*FFmeter* measures transfer function of a digitizer using AC-AC transfer method.

[Builds are here](https://github.com/KaeroDot/WACsw/tree/master/control_software/Filter%20function%20meter%20builds)

[How to install and run](https://github.com/KaeroDot/WACsw/blob/master/control_software/Filter%20function%20meter%20builds/How%20to%20install%20and%20run%20FFmeter.md)

### Data processing scheme
Scheme is in a [separate document](https://github.com/KaeroDot/WACsw/blob/master/doc/WACsw_requirements.md)

## Status of the project
Yet to do:

Type | Task | status
-----|------|--------
FFmeter | basic structure | ✔
FFmeter | schematics, templates | ✔
FFmeter | measurement tests | ✔
FFmeter | documentation | ½ (tooltips ok, how to ok, video missing)
FFmeter | add calibrator Fluke 5720A | ✔
FFmeter | add calibrator Fluke 5730A | ✔
FFmeter | add source AFG3110C | ½ (not yet tested)
FFmeter | add AC/DC standard corrections | ½ (works in script, missing in template)
FFmeter | start result calculation from GUI (using script) | ❌
FFmeter | finalize fitting of frequency response - find out best method | ❌
FFmeter | ❗suggestion - alternate sampling and dc measurement instead of simultaneous | must be thought out
FFmeter | ❗suggestion - measurement of sensitivity at the start | must be thought out
processing frequency response | simulator | ✔
processing frequency response | simulator documentation | ❌
processing frequency response | processing | ✔
processing frequency response | processing documentation | ❌
processing frequency response | test | ✔
processing frequency response | test documentation | ❌
processing cable error | simulator | ❌
processing cable error | simulator documentation | ❌
processing cable error | processing | ❌
processing cable error | processing documentation | ❌
processing cable error | test | ❌
processing cable error | test documentation | ❌
processing subsampling | simulator | ✔
processing subsampling | simulator documentation  | ❌
processing subsampling | processing | ½ (seems to be working, needs more tests)
processing subsampling | processing documentation  | ❌
processing subsampling | test | ½ (seems to be working)
processing subsampling | test documentation  | ❌
