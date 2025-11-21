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
WACsw | basic structure | ✔
WACsw | schematics, templates | ✔
WACsw | measurement tests | ✔
WACsw | documentation | ½ (tooltips ok, how to ok, video missing)
WACsw | add calibrator Fluke 5720A | ✔
WACsw | add calibrator Fluke 5730A | ✔
WACsw | add source AFG3110C | ½ (not yet tested)
WACsw | add AC/DC standard corrections | ½ (works in script, missing in template)
WACsw | start result calculation from GUI (using script) | ✔
WACsw | finalize fitting of frequency response - find out best method | ✔ - splines
WACsw | ❗suggestion - alternate sampling and dc measurement instead of simultaneous | must be thought out
WACsw | ❗suggestion - measurement of sensitivity at the start | must be thought out
WACsw | ❗suggestion - implement K2182A nanovoltmeter | needed for PMJTC
WACsw | FR testing | ✔
WACsw | FR validation | ongoing
WACsw | CE testing | ✔
WACsw | CE validation | ongoing
WACsw | SS testing | ❌ - missing PJVS
WACsw | SS validation | ❌ - missing PJVS
processing FR | simulator | ✔
processing FR | simulator documentation | ❌
processing FR | processing | ✔
processing FR | processing documentation | ❌
processing FR | test | ✔
processing FR | test documentation | ❌
processing CE | simulator | ✔
processing CE | simulator documentation | ❌
processing CE | processing | ✔
processing CE | processing documentation | ❌
processing CE | test | ✔
processing CE | test documentation | ❌
processing SS | simulator | ✔
processing SS | simulator documentation  | ❌
processing SS | processing | ✔
processing SS | processing documentation  | ❌
processing SS | test | ✔
processing SS | test documentation  | ❌
