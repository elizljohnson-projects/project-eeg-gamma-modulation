function connect_analysis(session, sid, method)
% CONNECT_ANALYSIS - compute gamma connectivity (40 Hz) based on amplitude
% (i.e., amplitude correlation) or phase (i.e., phase-locking value) over
% the post-stimulus epoch.
%
% Ensure FieldTrip is correcty added to the MATLAB path:
%   addpath <path to fieldtrip home directory>
%   ft_defaults
%
% Inputs:
% session = 'baseline'/'tacs'/'tdcs'/'sham' experimental session
% sid = subject ID (e.g., 'AB')
% method = 'amplcorr'/'plv' connectivity method, i.e., 'amplcorr' for 
%   amplitude correlation or 'plv' for phase-locking value (e.g., 'amplcorr')
%
% Example:
% connect_analysis('baseline', 'AB', 'amplcorr')
%
% Copyright (c) 2019
% EL Johnson, PhD

clearvars -except session sid method

% set directories
pth = pwd;
datdir = fullfile(pth, session, sid);
savdir = fullfile(datdir, 'gamma', method);
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
cfg.output = 'fourier'; % complex values
cfg.keeptrials = 'yes';

data = ft_freqanalysis(cfg, data);

% select time window
cfg = [];
cfg.latency = [-0.05 1.5];

data = ft_selectdata(cfg, data);

% compute connectivity
cfg = [];
cfg.method = method;

data = ft_connectivityanalysis(cfg, data);

% save
save(fullfile(savdir, 'connect'), 'data');

end
