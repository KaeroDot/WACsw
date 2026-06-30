% Function checks if the code is running in GNU Octave or Matlab. Function use
% persistent variable to speed up repeated calls.

function retval = isOctave() %<<<2
% checks if GNU Octave or Matlab
% according https://www.gnu.org/software/octave/doc/v4.0.1/How-to-distinguish-between-Octave-and-Matlab_003f.html
    persistent cacheval;  % speeds up repeated calls
    if isempty (cacheval)
        cacheval = (exist ('OCTAVE_VERSION', 'builtin') > 0);
    end
    retval = cacheval;
end % function isOctave

