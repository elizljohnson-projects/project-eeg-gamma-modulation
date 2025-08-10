function power_analysis(session, sid)
% POWER_ANALYSIS - compute change in gamma power (40 Hz) from the pre- to
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
% power_analysis('baseline', 'AB')
%
% Copyright (c) 2019
% EL Johnson, PhD

clearvars -except session sid

% set directories
pth = pwd;
datdir = fullfile(pth, session, sid);
savdir = fullfile(datdir, 'gamma');
mkdir(savdir);

% load data
load(fullfile(datdir, 'data_clean'), 'data');

% run analysis
cfg = [];
cfg.method = 'mtmconvol'; % TFR
cfg.taper = 'dpss'; % multitaper
cfg.foi = 40; % center frequency
cfg.tapsmofrq = 5; % half-band around center frequency
cfg.t_ftimwin = ones(length(cfg.foi),1).*0.3; % 300-ms sliding window
cfg.toi = data.time{1}(1):0.01:data.time{1}(end); % full trial in 10-ms res
cfg.pad = 10; % 10-s pad
cfg.output = 'pow'; % power
cfg.keeptrials = 'no';

data = ft_freqanalysis(cfg, data);

% baseline correction
cfg = [];
cfg.baseline = [-0.25 -0.05];
cfg.baselinetype = 'relchange'; % relative change

data = ft_freqbaseline(cfg, data);

% select time window
cfg = [];
cfg.latency = [-0.05 1.5];

data = ft_selectdata(cfg, data);

% save
save(fullfile(savdir, 'power'), 'data');

end