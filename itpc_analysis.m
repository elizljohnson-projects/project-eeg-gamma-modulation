function itpc_analysis(session, sid)
% ITPC_ANALYSIS - compute gamma inter-trial phase coherence (ITPC; 40 Hz) 
% over the post-stimulus epoch.
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
% itpc_analysis('baseline', 'AB')
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
cfg.output = 'fourier'; % complex values
cfg.keeptrials = 'yes';

data = ft_freqanalysis(cfg, data);

% select time window
cfg = [];
cfg.latency = [-0.05 1.5];

data = ft_selectdata(cfg, data);

% compute ITPC
F = data.fourierspctrm;
data = rmfield(data,'fourierspctrm');
data.dimord = 'chan_time';
data.itpc = sum(F,1)./sum(abs(F),1);
data.itpc = squeeze(abs(data.itpc));

% save
save(fullfile(savdir, 'itpc'), 'data');

end
