% FFT window Designer
fraction_bits = 16; % Fraction bits
window_len = 1024;
filename = 'fft_window_hamming.mem';

% Quant
window_float = hamming(window_len);
window_fixed = round(window_float * 2^fraction_bits);
comp_coe_hex = [dec2hex(window_fixed)];

% Save
full_path = mfilename('fullpath');
[path, ~] = fileparts(full_path);
path = strrep(path, '\script', '\data\');
fptr = fopen([path filename], 'w');
for i = 1:length(window_fixed) - 1
    fprintf(fptr, '%s\n', comp_coe_hex(i, end - 3 : end));
end
fclose(fptr);