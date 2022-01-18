% -----------------------------------------------------------------------------
%
%    File Name:             ssrfft_testbench.m
%    Type:                  Matlab Script
%    Author:                J. Smith
%    Updated:               Fri Feb 2020
% 
%    Description:           Produce and format test data and compare 
%                           MATLAB software FFT output with Xilinx SSR FFT
%
%    Inputs:                fs    - Sampling frequency
%                           NFFT  - Number of points in FFT
%                           SSR   - Number of parallel inputs/outputs
%
%    Notes:                 Used to verify axi-wraping and packing IQ 
%                           values as ufix32_0
%                           
% -----------------------------------------------------------------------------

%% GENERATE TEST DATA %%

fs = 1024e6;            % sampling frequency
NFFT = 4096;            % FFT Size
SSR = 16;               % Super Sample Rate
binbw = fs/NFFT *1e-6;  % BW in MHz in a single bin
N = NFFT*16;            % length of time vector
t = (1:N)/fs;           % time vector
a_sig_1 = 1/1024;       % tone 1 amplitude
f_sig_1 = (100)*1e6;    % test tone frequency (band-centred)
snr = 30;               % signal-to-noise ratio
a_noise = 10^((20*log10(a_sig_1/sqrt(2)) - snr)/10);
in_noise = sqrt(a_noise)*randn(1,N);

% complex data
%in_complex = a_sig_1*exp(1i*2*pi*f_sig_1*t) + in_noise;
load('gen3-opfb\data\pypfb_fp16.mat')
in_complex=in_complex(1:N);
in_complex = circshift( in_complex , -96 ) ;

real_sig = real(in_complex);
imag_sig = imag(in_complex);

%% DATA PROCESSED VIA MATLAB FFT (SOFTWARE) %%

x_sw = in_complex(1:NFFT);
in_spect_lin = fftshift((abs(fft(x_sw)))); % lin scale
in_spect_log = fftshift(20*log10(abs(fft(x_sw)))); % log scale
in_spect_log = in_spect_log - max(in_spect_log); % normalize log scale
freq_ax = ((-NFFT/2:(NFFT/2)-1)/NFFT)*fs;
figure(1)
subplot(2,1,1);
plot(freq_ax/1e6,in_spect_lin(1:NFFT))
ylabel('Magnitude (lin)')
title('Input Spectrum (Software FFT)')
subplot(2,1,2);
plot(freq_ax/1e6,in_spect_log(1:NFFT))
ylabel('Magnitude (dB)')
xlabel('Frequency (MHz)')

%% DATA PROCESSED VIA SSR FFT (FPGA SIMULATION) %%

samp_t = numerictype(1, 16, 25); % each sample is an signed 16_15 fixed point object 
iq_t   = numerictype(0, 32, 0);  % iq value is an unsigned 32_0 fixed point object 

% input to simulation (first column is time vec, next SSR columns are ufix32_0 IQ objects)
len_arr  = N/SSR;
sim_time = linspace(0,len_arr-1,len_arr)';
imag_arr = reshape(imag_sig,SSR,len_arr).';    % double
imag_arr_fi = fi(imag_arr, samp_t);            % signed 16_15
real_arr    = reshape(real_sig,SSR,len_arr).'; % double
real_arr_fi = fi(real_arr, samp_t);            % signed 16_15

IQ = bitconcat(imag_arr_fi, real_arr_fi); % concat QI and cast as ufix32_0 (real = I imag = Q)
iqin.signals.values = IQ;                 % make into a struct
iqin.signals.dimensions = SSR;            % SSR samples in per clock
iqin.time = sim_time;                     % create time series field

valid_in = ones(len_arr,SSR+1);           % set input valid always high
valid_in(:,1) = sim_time;

sim('ssrfft_16x4096_axis.slx', 1073);    % run the model with minimum sim time to get full spectrum 

% reinterpret output data
iq_out32_0 = fi(iq_out, iq_t);                % recreate fixed point object
q_out_fi   = bitsliceget(iq_out32_0, 32, 17); % slice out high q bits
i_out_fi   = bitsliceget(iq_out32_0, 16, 1);  % slice out low i bits

i_out_fi = reinterpretcast(i_out_fi, samp_t); % recast to approproate signed 16_15 dtype
q_out_fi = reinterpretcast(q_out_fi, samp_t);

i_out = double(i_out_fi);                     % convert to normal dtype (double) for computational convinience 
q_out = double(q_out_fi);
outealarr = i_out;
outimagarr = q_out;

% check for overflow
if max(overflow)~=0
    disp('Overflow!')
end 

% report latency
latency = find(valid_out.data~=0, 1, 'first');
fprintf('%d x %d SSR FFT Latency: %d clocks \n', NFFT, SSR, latency);

% extract valid data and make it a line
valid_complex = i_out(latency:end,:)+q_out(latency:end,:)*1j;
valid_complex = reshape((valid_complex).',1,(size(valid_complex,1)*size(valid_complex,2)));

% plot SSR FFT Output
x_hw = valid_complex(1:NFFT);
out_spect_lin = fftshift((abs(x_hw)));
out_spect_log = fftshift(20*log10(abs(x_hw)));
out_spect_log = out_spect_log - max(out_spect_log); % optional normlaization
freq_ax = ((-NFFT/2:(NFFT/2)-1)/NFFT)*fs;
figure(2)
subplot(2,1,1);
plot(freq_ax/1e6,out_spect_lin(1:NFFT))
ylabel('Magnitude (lin)')
title('Output Spectrum (SSRFFT Simulation)')
subplot(2,1,2);
plot(freq_ax/1e6,out_spect_log(1:NFFT))
ylabel('Magnitude (log)')
xlabel('Frequency (MHz)')


figure(3)
subplot(2,1,1);
plot(freq_ax/1e6,in_spect_log(1:NFFT), 'LineWidth', 2)
ylabel('Magnitude (dB)')
xlabel('Frequency (MHz)')
title('Input Spectrum (Software FFT)')
set(gca, 'FontSize', 16)
subplot(2,1,2);
plot(freq_ax/1e6,out_spect_log(1:NFFT), 'LineWidth', 2)
ylabel('Magnitude (dB)')
xlabel('Frequency (MHz)')
title('Output Spectrum (SSRFFT Simulation)')
set(gca, 'FontSize', 16)



