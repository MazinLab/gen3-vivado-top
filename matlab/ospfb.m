
% -----------------------------------------------------------------------------
%  (c) Copyright - Commonwealth Scientific and Industrial Research Organisation
%  (CSIRO) - 2019
% 
%  All Rights Reserved.
% 
%  Restricted Use.
% 
%  Copyright protects this code. Except as permitted by the Copyright Act, you
%  may only use the code as expressly permitted under the terms on which the
%  code was licensed to you.
% 
% -----------------------------------------------------------------------------
%    File Name:             os_pfb_8_lane.m
%    Type:                  Matlab function
%    Contributing authors:  J. Tuthill, J. Smith
%    Updated:               Tue  Jan 2020
% 
%    Title:                 Oversampled polyphase filterbank 512-point x
%                           8-lane mixed-radix implementation
%    Description:           Matlab function implements an oversampled
%                           4096-path polyphase filterbank realised as
%                           eight lanes of 512.
%
%    Inputs:                x - filterbank input time series
%                           h - filterbank prototype impulse response
%                           M - total number of filterbank paths (transform length)
%                           OS - oversampling ratio
%                           fft_shifts - a vector defining the circular
%                             shift into the FFT for each new block update.
%
% -----------------------------------------------------------------------------
clear

%% DEFINE IMPORTANT PARAMETERS %%
lanes = 16;
fs = 4096e6;            % sampling frequency
load prot_filt_eqrip;   % loads 4096x8 = 32,768 tap filter coeficients into workspace variable 'c'
M = 4096;               % total fft size
baseFFTlen = 256;       % fft size on each lane
K = M*lanes;            % length of filter (total number of taps)
taps = ceil(length(ht)/M);
D = 2048;               % deimation
num = 2;                % numerator of reduced fraction M/D
den = 1;                % denominator of reduced fraction M/D
ovlp = M-D;             % overlap per frame
h = ht;                 % filter
h = [h zeros(1,taps*M - length(h))]; % appd. 0's to filt if needed
fft_shifts = mod((0:num-1)*(M-D),M);

%% DATA CREATION %%
N=1000*K;                     % length of input data
N = floor(N/D)*D;             % truncate data
t = (0:N-1)/fs;               % time vec    

fvec=[-190, 180, 185, 175]*1e6;      % frequencies pick between +/- M/2 = 2048
avec=[1,1,1,1];                      % amplitudes
snr = 10;                            % signal-to-noise ratio

a_noise = 10^((20*log10(1/sqrt(2)) - snr)/10);
in_noise = sqrt(a_noise)*(randn(1,N) + 1i*randn(1,N));


% create data vector
x=zeros(length(fvec), length(t));
for row = 1:length(fvec)
    x(row,:)=avec(row)*exp(t*fvec(row)*pi*2*1i);
end

% need to add analog BP filter

x=sum(x,1)+in_noise; % input data

%% PROCESS AND PLOT INPUT DATA VIA NORMAL FFT %%
in_spect = fftshift(20*log10(abs(fft(x))));
in_spect = in_spect - max(in_spect);
freq_ax = (-N/2:N/2-1)/N*fs;
figure(1);
clf
plot(freq_ax/1e6,in_spect(1:length(freq_ax)))
xlabel('Frequency (MHz)')
ylabel('Magnitude (dB)')
title('Input Spectrum')
%% PROCESS INPUT DATA VIA MULTILANE FFT %%

% partition filter into 16 lanes
sixteen_lane_fir = reshape(h,16,baseFFTlen*taps);
lane_1_pfb = reshape(sixteen_lane_fir(1,:),baseFFTlen,taps);
lane_2_pfb = reshape(sixteen_lane_fir(2,:),baseFFTlen,taps);
lane_3_pfb = reshape(sixteen_lane_fir(3,:),baseFFTlen,taps);
lane_4_pfb = reshape(sixteen_lane_fir(4,:),baseFFTlen,taps);
lane_5_pfb = reshape(sixteen_lane_fir(5,:),baseFFTlen,taps);
lane_6_pfb = reshape(sixteen_lane_fir(6,:),baseFFTlen,taps);
lane_7_pfb = reshape(sixteen_lane_fir(7,:),baseFFTlen,taps);
lane_8_pfb = reshape(sixteen_lane_fir(8,:),baseFFTlen,taps);
lane_9_pfb = reshape(sixteen_lane_fir(9,:),baseFFTlen,taps);
lane_10_pfb = reshape(sixteen_lane_fir(10,:),baseFFTlen,taps);
lane_11_pfb = reshape(sixteen_lane_fir(11,:),baseFFTlen,taps);
lane_12_pfb = reshape(sixteen_lane_fir(12,:),baseFFTlen,taps);
lane_13_pfb = reshape(sixteen_lane_fir(13,:),baseFFTlen,taps);
lane_14_pfb = reshape(sixteen_lane_fir(14,:),baseFFTlen,taps);
lane_15_pfb = reshape(sixteen_lane_fir(15,:),baseFFTlen,taps);
lane_16_pfb = reshape(sixteen_lane_fir(16,:),baseFFTlen,taps);


% partition data into 16 downsampled lanes
sample_blocks = ceil(length(x)/16);            % number of 16-sample sets in the input sequence (rounded up)
x = [x zeros(1,sample_blocks*16 - length(x))]; % zero-pad the input sequence if required
lane_data = reshape(x,16,sample_blocks);

lane_1_data = lane_data(1,:);
lane_2_data = lane_data(2,:);
lane_3_data = lane_data(3,:);
lane_4_data = lane_data(4,:);
lane_5_data = lane_data(5,:);
lane_6_data = lane_data(6,:);
lane_7_data = lane_data(7,:);
lane_8_data = lane_data(8,:);
lane_9_data = lane_data(9,:);
lane_10_data = lane_data(10,:);
lane_11_data = lane_data(11,:);
lane_12_data = lane_data(12,:);
lane_13_data = lane_data(13,:);
lane_14_data = lane_data(14,:);
lane_15_data = lane_data(15,:);
lane_16_data = lane_data(16,:);

blocks = floor((length(x)-length(h))/D);
laneStride = baseFFTlen/(num/den);
y = zeros(blocks,M);


for blk = 0:blocks-1
    
    % cycle blocks of data through the sixteen separate filterbank lanes
    
    filt_block_1 = lane_1_pfb.*reshape(lane_1_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_2 = lane_2_pfb.*reshape(lane_2_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_3 = lane_3_pfb.*reshape(lane_3_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_4 = lane_4_pfb.*reshape(lane_4_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_5 = lane_5_pfb.*reshape(lane_5_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_6 = lane_6_pfb.*reshape(lane_6_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_7 = lane_7_pfb.*reshape(lane_7_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_8 = lane_8_pfb.*reshape(lane_8_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_9 = lane_9_pfb.*reshape(lane_9_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_10 = lane_10_pfb.*reshape(lane_10_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_11 = lane_11_pfb.*reshape(lane_11_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_12 = lane_12_pfb.*reshape(lane_12_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_13 = lane_13_pfb.*reshape(lane_13_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_14 = lane_14_pfb.*reshape(lane_14_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_15 = lane_15_pfb.*reshape(lane_15_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    filt_block_16 = lane_16_pfb.*reshape(lane_16_data(1+laneStride*blk:(baseFFTlen*taps)+laneStride*blk),baseFFTlen,taps);
    
    % compute the sixteen filterbank lane outputs (256 branches per lane)
    fb_out_1 = sum(filt_block_1,2).';
    fb_out_2 = sum(filt_block_2,2).';
    fb_out_3 = sum(filt_block_3,2).';
    fb_out_4 = sum(filt_block_4,2).';
    fb_out_5 = sum(filt_block_5,2).';
    fb_out_6 = sum(filt_block_6,2).';
    fb_out_7 = sum(filt_block_7,2).';
    fb_out_8 = sum(filt_block_8,2).';
    fb_out_9 = sum(filt_block_9,2).';
    fb_out_10 = sum(filt_block_10,2).';
    fb_out_11 = sum(filt_block_11,2).';
    fb_out_12 = sum(filt_block_12,2).';
    fb_out_13 = sum(filt_block_13,2).';
    fb_out_14 = sum(filt_block_14,2).';
    fb_out_15 = sum(filt_block_15,2).';
    fb_out_16 = sum(filt_block_16,2).';
    
    % do the circular shift on the FFT input data to compensate for oversampling
    shift_indx = fft_shifts(mod(blk,length(fft_shifts))+1)/16;
    
    seq_1 = [fb_out_1(shift_indx+1:end) fb_out_1(1:shift_indx)];
    seq_2 = [fb_out_2(shift_indx+1:end) fb_out_2(1:shift_indx)];
    seq_3 = [fb_out_3(shift_indx+1:end) fb_out_3(1:shift_indx)];
    seq_4 = [fb_out_4(shift_indx+1:end) fb_out_4(1:shift_indx)];
    seq_5 = [fb_out_5(shift_indx+1:end) fb_out_5(1:shift_indx)];
    seq_6 = [fb_out_6(shift_indx+1:end) fb_out_6(1:shift_indx)];
    seq_7 = [fb_out_7(shift_indx+1:end) fb_out_7(1:shift_indx)];
    seq_8 = [fb_out_8(shift_indx+1:end) fb_out_8(1:shift_indx)];
    seq_9 = [fb_out_9(shift_indx+1:end) fb_out_9(1:shift_indx)];
    seq_10 = [fb_out_10(shift_indx+1:end) fb_out_10(1:shift_indx)];
    seq_11 = [fb_out_11(shift_indx+1:end) fb_out_11(1:shift_indx)];
    seq_12 = [fb_out_12(shift_indx+1:end) fb_out_12(1:shift_indx)];
    seq_13 = [fb_out_13(shift_indx+1:end) fb_out_13(1:shift_indx)];
    seq_14 = [fb_out_14(shift_indx+1:end) fb_out_14(1:shift_indx)];
    seq_15 = [fb_out_15(shift_indx+1:end) fb_out_15(1:shift_indx)];
    seq_16 = [fb_out_16(shift_indx+1:end) fb_out_16(1:shift_indx)];

    % interleave the outputs into correct order for FFT
    fullseq=zeros(1,baseFFTlen*lanes);
    
    fullseq(1:16:end)=seq_1;
    fullseq(2:16:end)=seq_2;
    fullseq(3:16:end)=seq_3;
    fullseq(4:16:end)=seq_4;
    fullseq(5:16:end)=seq_5;
    fullseq(6:16:end)=seq_6;
    fullseq(7:16:end)=seq_7;
    fullseq(8:16:end)=seq_8;
    fullseq(9:16:end)=seq_9;
    fullseq(10:16:end)=seq_10;
    fullseq(11:16:end)=seq_11;
    fullseq(12:16:end)=seq_12;
    fullseq(13:16:end)=seq_13;
    fullseq(14:16:end)=seq_14;
    fullseq(15:16:end)=seq_15;
    fullseq(16:16:end)=seq_16;
    
    % take 4096 point FFT
    spect=fft(fullseq);
    y(blk+1,1:M)= spect;
  
clear fullseq seq_* filt_block_*
end

clear lane_* fb_out_* in_noise t x

OS = num/den;
data = y.';
clear y
N = length(data);

%% PLOT MULTI-LANE PFB RESULT WITHOUT OVERLAP %%

% non-overlapping bin indicies
novlp_start_idx = ceil((OS-1)/(2*OS)*N);
novlp_stop_idx = novlp_start_idx + floor(1/OS*N);
plt_len = novlp_stop_idx-novlp_start_idx+1;
plot_sb_overlap = 1;

% preallocate for speed
xax_t = zeros(1,plt_len*M);
yax_t = zeros(1,plt_len*M);
idxstart=1;
idxstop=plt_len;
    
for lp = 1:M
    plt_var = 20*log10(abs(fft(data(lp,:))));

    xax_J = (lp-1) + ((0:plt_len-1)/plt_len - 0.5);
    tmp = fftshift(plt_var);
    yax_J = tmp(novlp_start_idx:novlp_stop_idx);
    
    xax_t(idxstart:idxstop) = xax_J;
    yax_t(idxstart:idxstop) = yax_J;
    
    idxstart=idxstart+plt_len;
    idxstop=idxstop+plt_len;
end

% shift the negative frequency components back to the correct place
xax_t = xax_t - M/2;
yax_t = fftshift(yax_t);

% normalize
max_val = max(yax_t);
yax_t = yax_t - max_val;
figure(2)
clf
plot(xax_t, yax_t)

xlabel('Frequency (MHz)')
ylabel('Magnitude (dB)')
title('Output from 16-Lane, 2x Oversample OSPFB')


bwidx = length(yax_t)/M;
figure(3)
clf
for bin = 2220:2238  % plot whichever bin values you like (1 to 4096)
    xplt = xax_t(bwidx*(bin-1)+1:bwidx*(bin));
    yplt = yax_t(bwidx*(bin-1)+1:bwidx*(bin));
    plot(xplt, yplt)
    hold on
end
xlabel('Frequency (MHz)')
ylabel('Magnitude (dB)')
title('Output from 16-Lane, 2x Oversample OSPFB Bin-Wise')


%% PLOT MULTI-LANE PFB RESULT WITH OVERLAP %%

% preallocate for speed
xax_t_ovlp = zeros(1,M*N);
yax_t_ovlp = zeros(1,M*N);
idxstart=1;
idxstop=N;

for lp = 1:M
    plt_var = 20*log10(abs(fft(data(lp,:))));
    xax_ovlp = (lp-1) + ((0:N-1)/N - 0.5)*OS;
    yax_ovlp = fftshift(plt_var); 
    
    
    xax_t_ovlp(idxstart:idxstop) = xax_ovlp;
    yax_t_ovlp(idxstart:idxstop) = yax_ovlp;
    
    idxstart=idxstart+N;
    idxstop=idxstop+N;
end

% shift negative frequency components back to the correct place
xax_t_ovlp = xax_t_ovlp - M/2;
yax_t_ovlp = fftshift(yax_t_ovlp);

% normalize 
max_val_ovlp = max(yax_t_ovlp);
yax_t_ovlp = yax_t_ovlp - max_val_ovlp;
bwidx = length(yax_t_ovlp)/M;

figure(4)
clf
for bin = 2220:2238  % plot whichever bin values you like (1 to 4096)
    xplt_ovlp = xax_t_ovlp(bwidx*(bin-1)+2:bwidx*(bin));
    yplt_ovlp = yax_t_ovlp(bwidx*(bin-1)+2:bwidx*(bin));
    plot(xplt_ovlp, yplt_ovlp)
    hold on
end
xlabel('Frequency (MHz)')
ylabel('Magnitude (dB)')
title('Output from 16-Lane, 2x Oversample OSPFB Bin-Wise (Overlapped)')
