function Hd = multirate_filter_design
%MULTI-RATE_FILTER_DESIGN Returns a multirate filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.10 and DSP System Toolbox 9.12.
% Generated on: 10-Feb-2025 13:27:10

intf = 32;  % Interpolation Factor

Hd = dsp.FIRInterpolator( ...
    'Numerator', [0.03125 0.0625 0.09375 0.125 0.15625 0.1875 0.21875 ...
    0.25 0.28125 0.3125 0.34375 0.375 0.40625 0.4375 0.46875 0.5 0.53125 ...
    0.5625 0.59375 0.625 0.65625 0.6875 0.71875 0.75 0.78125 0.8125 ...
    0.84375 0.875 0.90625 0.9375 0.96875 1 0.96875 0.9375 0.90625 0.875 ...
    0.84375 0.8125 0.78125 0.75 0.71875 0.6875 0.65625 0.625 0.59375 ...
    0.5625 0.53125 0.5 0.46875 0.4375 0.40625 0.375 0.34375 0.3125 0.28125 ...
    0.25 0.21875 0.1875 0.15625 0.125 0.09375 0.0625 0.03125], ...
    'InterpolationFactor', intf);

% [EOF]
