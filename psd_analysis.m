function psd_analysis(session, sid)
% PSD_ANALYSIS - compute power spectral density (PSD; 3-50 Hz) over the
% post-stimulus epoch.
%
% Ensure FieldTrip is correcty added to the MATLAB path:
%   addpath <path to fieldtrip home directory>
%   ft_defaults
%
% Inputs:
% session = 'baseline'/'tacs'/'tdcs'/'sham' experimental session
% sid = subject ID (e.g., 'AB')
%
% Example:
% psd_analysis('baseline', 'AB')
%
% Copyright (c) 2019
% EL Johnson, PhD

clearvars -except session sid

% set directories
pth = pwd;
datdir = fullfile(pth, session, sid);
savdir = fullfile(datdir, 'psd');
mkdir(savdir);

% load data
load(fullfile(datdir, 'data_clean'), 'data');

% select time window
cfg	= [];
cfg.latency = [-0.25 1.75];

data = ft_selectdata(cfg, data);

% run analysis
cfg = [];
cfg.method = 'mtmfft'; % FFT
cfg.taper = 'dpss'; % multitaper
cfg.foi = 3:1:50; % center frequencies
cfg.tapsmofrq = max(2,ceil(cfg.foi./6)); % frequency-dependent half-band
cfg.pad = 10; % 10-s pad
cfg.output = 'pow'; % power
cfg.keeptrials = 'no';

data = ft_freqanalysis(cfg, data);

% save
save(fullfile(savdir, 'psd'), 'data');

end
