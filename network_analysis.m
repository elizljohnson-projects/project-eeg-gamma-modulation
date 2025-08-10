function network_analysis(session, sid, method)
% NETWORK_ANALYSIS - compute gamma network (40 Hz) node degrees, using
% amplitude-based (i.e., amplitude correlation) or phase-based (i.e., 
% phase-locking value) connectivity data over the post-stimulus epoch.
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
datdir = fullfile(pth, session, sid, 'gamma', method); % output of connect_analysis
savdir = datdir;

% load data
load(fullfile(datdir, 'connect'), 'data');

% compute node degrees
cfg = [];
cfg.method = 'degrees';
cfg.parameter = strcat(method, 'spctrm');
cfg.threshold = 0.65; % threshold for 'connection'

data = ft_networkanalysis(cfg, data);

% save
save(fullfile(savdir, 'network'), 'data');

end
