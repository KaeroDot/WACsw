% This script will process measured data in xlx files and calculate the
% frequency response of the digitizer and the AC source stability. The results
% will be saved in a .mat file as reference data for simualtion.

addpath('../../');
check_and_set_environment();

clear all; close all
M_FR = read_M_FR_from_spreadsheet('2026-02-24 K2182 GrdDisGnd digit ch2 50 kHz.xlsx', 1);
M_FR.no_fit_regions.v = 60;
[f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, 'acdc_standard_data/F792temelin/Fluke792temelin_range_2.2.info', 1);

clear all; close all
M_FR = read_M_FR_from_spreadsheet('2026-02-24 K2182 GrdDisGnd digit ch2 500 kHz.xlsx', 1);
M_FR.no_fit_regions.v = 60;
[f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, 'acdc_standard_data/F792temelin/Fluke792temelin_range_2.2.info', 1);

clear all; close all
M_FR = read_M_FR_from_spreadsheet('2026-02-24 K2182 GrdDisGnd digit ch2 4 MHz.xlsx', 1);
M_FR.no_fit_regions.v = 60;
[f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, 'acdc_standard_data/F792temelin/Fluke792temelin_range_2.2.info', 1);

clear all; close all
M_FR = read_M_FR_from_spreadsheet('2026-02-24 K2182 GrdDisGnd digit ch2 10 MHz.xlsx', 1);
M_FR.no_fit_regions.v = 60;
[f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, 'acdc_standard_data/F792temelin/Fluke792temelin_range_2.2.info', 1);

clear all; close all
M_FR = read_M_FR_from_spreadsheet('2026-02-24 K2182 GrdDisGnd digit ch2 15 MHz.xlsx', 1);
M_FR.no_fit_regions.v = 60;
[f, digitizer_FR, ac_source_stability, FR_fit] = P_FR(M_FR, 'acdc_standard_data/F792temelin/Fluke792temelin_range_2.2.info', 1);
