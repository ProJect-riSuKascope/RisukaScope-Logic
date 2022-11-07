% CIC and CIC Compensation Filter Designer
% CIC parameters
samplerate = 20000000; % Sample rate
ratio = 16; % Decimator factor
delay = 2;  % Differential delay
stages = 5;  % Filter Stages

% Compensation filter parameters
order = 16;         % Compensation filter order
freq_pass = samplerate * 0.5 / (ratio * 2);   % Passband frequency
freq_pass_given = samplerate * 0.8 / (ratio * 2);
freq_stop = samplerate / (ratio * 2);  % Stopband frequency
attn_pass = 0.1;    % Passband attenuation
attn_stop = 40;     % Stopband attenuation

fraction_bits = 16; % Fraction bits
filename = 'compansation_16.mem';

% Calculation
cic_filter = dsp.CICDecimator(ratio, delay, stages);
cic_comp_filter = dsp.CICCompensationDecimator(cic_filter, ...
    'DecimationFactor', 1, ...
    'StopbandFrequency', freq_stop, ...
    'SampleRate', samplerate / ratio, ...
    'DesignForMinimumOrder', false, ...
    'FilterOrder', order - 1);
%{
cic_comp_filter = dsp.CICCompensationDecimator(cic_filter, ...
    'DecimationFactor', 1, ...
    'PassbandFrequency', freq_pass, ...
    'StopbandFrequency', freq_stop, ...
    'SampleRate', samplerate / ratio, ...
    'DesignForMinimumOrder', true);
%}

% Order
disp(info(cic_comp_filter));

% Quant
comp_coe_float = coeffs(cic_comp_filter).Numerator;
comp_coe_fixed = round(comp_coe_float * 2^fraction_bits);
comp_coe_hex = [dec2hex(comp_coe_fixed)];

% Save
full_path = mfilename('fullpath');
[path, ~] = fileparts(full_path);
path = strrep(path, '\script', '\data\');
fptr = fopen([path filename], 'w');
for i = 1:length(comp_coe_fixed) - 1
    fprintf(fptr, '%s\n', comp_coe_hex(i, end - 3 : end));
end
fclose(fptr);

% Display filter
fvtool(cic_filter, cic_comp_filter, ...
    cascade(cic_filter, cic_comp_filter), ...
    'ShowReference', 'off', ...
    'Fs', [samplerate samplerate / ratio samplerate]);
legend('CIC Decimator', 'CIC Compensator', 'Cascaded Filter');