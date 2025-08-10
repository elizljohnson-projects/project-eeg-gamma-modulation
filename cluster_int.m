function cluster_int(metric, epoch)
% CLUSTER_INT - compute 2 (baseline vs. stimulation) x 2 (sham vs. 
% tACS/tDCS) interactions by first subtracting baseline from stimulation, 
% and then running an independent-samples t-test on the difference by 
% stimulation type, multiple comparison-corrected with nonparametric 
% cluster-based permutations. Also saves grand average data.
%
% Ensure FieldTrip is correcty added to the MATLAB path:
%   addpath <path to fieldtrip home directory>
%   ft_defaults
%
% Inputs:
% metric = 'prestim'/'power'/'itpc'/'amplcorr'/'plv'/'pac' metric to test, 
%   i.e., 'prestim' for pre-stimulus gamma power, 'power' for post-stimulus
%   gamma power, 'itpc' for gamma ITPC, 'amplcorr' for amplitude-based
%   gamma network, 'plv' for phase-based gamma network, or 'pac' for 
%   alpha-gamma PAC
% epoch = 'sound_on'/'sound_off' for all metrics except 'prestim'
%
% Example:
% cluster_int('prestim')
% cluster_int('power', 'sound_on')
%
% Copyright (c) 2019
% EL Johnson, PhD

clearvars -except metric epoch

% set directories
pth = pwd;
datdir = pth;
savdir = fullfile(datdir, metric);
mkdir(savdir);

% set data field
if strcmp(metric, 'prestim') || strcmp(metric, 'power')
    param = 'powspctrm';
elseif strcmp(metric, 'itpc')
    param = 'itpc';
elseif strcmp(metric, 'amplcorr') || strcmp(metric, 'plv')
    param = 'degrees';
elseif strcmp(metric, 'pac')
    param = 'z';
end

% get subject lists
s_tacs = dir(fullfile(datdir, 'tacs'));
s_tacs = s_tacs(3:end);

s_tdcs = dir(fullfile(datdir, 'tdcs'));
s_tdcs = s_tdcs(3:end);

s_sham = dir(fullfile(datdir, 'sham'));
s_sham = s_sham(3:end);

% load tACS data and compile grand average
for s = 1:length(s_tacs)
    % load data for baseline and stimulation sessions
    if strcmp(metric, 'prestim') || strcmp(metric, 'power') || strcmp(metric, 'itpc')
        post = load(fullfile(datdir, 'tacs', s_tacs(s).name, 'gamma', metric));
        pre = load(fullfile(datdir, 'baseline', s_tacs(s).name, 'gamma', metric));
    elseif strcmp(metric, 'amplcorr') || strcmp(metric, 'plv')
        post = load(fullfile(datdir, 'tacs', s_tacs(s).name, 'gamma', metric, 'network')); 
        pre = load(fullfile(datdir, 'baseline', s_tacs(s).name, 'gamma', metric, 'network')); 
    elseif strcmp(metric, 'pac')
        post = load(fullfile(datdir, 'tacs', s_tacs(s).name, 'pac', ['mi_' epoch])); 
        pre = load(fullfile(datdir, 'baseline', s_tacs(s).name, 'pac', ['mi_' epoch])); 
    end
    
    % initialize data structure
    if s == 1
        tacs = [];
        tacs.time = post.data.time;
        tacs.dimord = 'subj_chan_time';
        tacs.label = {'AFz', 'F4', 'Fz', 'F3', 'FCz', 'C4', 'Cz', 'C3', 'CPz', ...
            'P4', 'Pz', 'P3', 'POz', 'Oz'}; % all channels
        tacs.individual = nan(length(s_tacs), length(tacs.label), length(tacs.time));
            % for stimulation - baseline data in standard fieldtrip grand
            % average field name
        tacs.post = tacs.individual; % for input data
        tacs.pre = tacs.individual;
    end
    
    % make temporary variables
    tmp_post = post.data.(param);
    tmp_pre = pre.data.(param);
    
    % normalize graph network by number of channels in graph
    if strcmp(metric, 'amplcorr') || strcmp(metric, 'plv')
        tmp_post = tmp_post ./ length(post.label);
        tmp_pre = tmp_pre ./ length(pre.label);
    end
        
    % index data channels and populate data matrix
    chan = intersect(post.label, pre.label);
    idx = ismember(post.label, chan);
    tmp_post = tmp_post(idx==1,:);
    idx = ismember(pre.label, chan);
    tmp_pre = tmp_pre(idx==1,:);
    idx = ismember(tacs.label, chan);

    tacs.individual(s,idx==1,:) = tmp_post - tmp_pre; % stimulation - baseline
    tacs.post(s,idx==1,:) = tmp_post;
    tacs.pre(s,idx==1,:) = tmp_pre;
    
    clear tmp* idx post pre
end

% load tDCS data and compile grand average
for s = 1:length(s_tdcs)
    % load data for baseline and stimulation sessions
    if strcmp(metric, 'prestim') || strcmp(metric, 'power') || strcmp(metric, 'itpc')
        post = load(fullfile(datdir, 'tdcs', s_tdcs(s).name, 'gamma', metric));
        pre = load(fullfile(datdir, 'baseline', s_tdcs(s).name, 'gamma', metric));
    elseif strcmp(metric, 'amplcorr') || strcmp(metric, 'plv')
        post = load(fullfile(datdir, 'tdcs', s_tdcs(s).name, 'gamma', metric, 'network')); 
        pre = load(fullfile(datdir, 'baseline', s_tdcs(s).name, 'gamma', metric, 'network')); 
    elseif strcmp(metric, 'pac')
        post = load(fullfile(datdir, 'tdcs', s_tdcs(s).name, 'pac', ['mi_' epoch])); 
        pre = load(fullfile(datdir, 'baseline', s_tdcs(s).name, 'pac', ['mi_' epoch])); 
    end
    
    % initialize data structure
    if s == 1
        tdcs = [];
        tdcs.time = tacs.time;
        tdcs.dimord = tacs_dimord;
        tdcs.label = tacs.label;
        tdcs.individual = nan(size(tacs.individual));
        tdcs.post = tdcs.individual;
        tdcs.pre = tdcs.individual;
    end
    
    % make temporary variables
    tmp_post = post.data.(param);
    tmp_pre = pre.data.(param);
    
    % normalize graph network by number of channels in graph
    if strcmp(metric, 'amplcorr') || strcmp(metric, 'plv')
        tmp_post = tmp_post ./ length(post.label);
        tmp_pre = tmp_pre ./ length(pre.label);
    end
        
    % index data channels and populate data matrix
    chan = intersect(post.label, pre.label);
    idx = ismember(post.label, chan);
    tmp_post = tmp_post(idx==1,:);
    idx = ismember(pre.label, chan);
    tmp_pre = tmp_pre(idx==1,:);
    idx = ismember(tdcs.label, chan);

    tdcs.individual(s,idx==1,:) = tmp_post - tmp_pre; % stimulation - baseline
    tdcs.post(s,idx==1,:) = tmp_post;
    tdcs.pre(s,idx==1,:) = tmp_pre;
    
    clear tmp* idx post pre
end

% load sham data and compile grand average
for s = 1:length(s_sham)
    % load data for baseline and stimulation sessions
    if strcmp(metric, 'prestim') || strcmp(metric, 'power') || strcmp(metric, 'itpc')
        post = load(fullfile(datdir, 'sham', s_sham(s).name, 'gamma', metric));
        pre = load(fullfile(datdir, 'baseline', s_sham(s).name, 'gamma', metric));
    elseif strcmp(metric, 'amplcorr') || strcmp(metric, 'plv')
        post = load(fullfile(datdir, 'sham', s_sham(s).name, 'gamma', metric, 'network')); 
        pre = load(fullfile(datdir, 'baseline', s_sham(s).name, 'gamma', metric, 'network')); 
    elseif strcmp(metric, 'pac')
        post = load(fullfile(datdir, 'sham', s_sham(s).name, 'pac', ['mi_' epoch])); 
        pre = load(fullfile(datdir, 'baseline', s_sham(s).name, 'pac', ['mi_' epoch])); 
    end
    
    % initialize data structure
    if s == 1
        sham = [];
        sham.time = tacs.time;
        sham.dimord = tacs_dimord;
        sham.label = tacs.label;
        sham.individual = nan(size(tacs.individual));
        sham.post = sham.individual;
        sham.pre = sham.individual;
    end
    
    % make temporary variables
    tmp_post = post.data.(param);
    tmp_pre = pre.data.(param);
    
    % normalize graph network by number of channels in graph
    if strcmp(metric, 'amplcorr') || strcmp(metric, 'plv')
        tmp_post = tmp_post ./ length(post.label);
        tmp_pre = tmp_pre ./ length(pre.label);
    end
        
    % index data channels and populate data matrix
    chan = intersect(post.label, pre.label);
    idx = ismember(post.label, chan);
    tmp_post = tmp_post(idx==1,:);
    idx = ismember(pre.label, chan);
    tmp_pre = tmp_pre(idx==1,:);
    idx = ismember(sham.label, chan);

    sham.individual(s,idx==1,:) = tmp_post - tmp_pre; % stimulation - baseline
    sham.post(s,idx==1,:) = tmp_post;
    sham.pre(s,idx==1,:) = tmp_pre;
    
    clear tmp* idx post pre
end

% save grand average data
save(fullfile(savdir, ['grandavg_tacs_' epoch]), 'tacs');
save(fullfile(savdir, ['grandavg_tdcs_' epoch]), 'tdcs');
save(fullfile(savdir, ['grandavg_sham_' epoch]), 'sham');

% set up cluster stats
cfg = [];
cfg.method = 'montecarlo'; % nonparametric Monte Carlo method
cfg.numrandomization = 1000; % number of permutations
cfg.statistic = 'ft_statfun_indepsamplesT'; % independent-samples t-test
cfg.parameter = 'individual'; % name of field with data
cfg.tail = 1; % tACS/tDCS > sham
cfg.correcttail = 'prob';
cfg.correctm = 'cluster'; % cluster correction for multiple comparisons
cfg.clusterstatistic = 'maxsize'; % maximum size criterion

% define neighbors for spatial clustering
cfg.neighbours(1).label = 'AFz';
cfg.neighbours(1).neighblabel = {'Fz','F3','F4'};
cfg.neighbours(2).label = 'Fz';
cfg.neighbours(2).neighblabel = {'AFz','FCz','F3','F4'};
cfg.neighbours(3).label = 'FCz';
cfg.neighbours(3).neighblabel = {'Fz','Cz','F3','F4','C3','C4'};
cfg.neighbours(4).label = 'Cz';
cfg.neighbours(4).neighblabel = {'FCz','CPz','C3','C4'};
cfg.neighbours(5).label = 'CPz';
cfg.neighbours(5).neighblabel = {'Cz','Pz','C3','C4','P3','P4'};
cfg.neighbours(6).label = 'Pz';
cfg.neighbours(6).neighblabel = {'CPz','POz','P3','P4'};
cfg.neighbours(7).label = 'POz';
cfg.neighbours(7).neighblabel = {'Pz','Oz','P3','P4'};
cfg.neighbours(8).label = 'Oz';
cfg.neighbours(8).neighblabel = {'POz'};
cfg.neighbours(9).label = 'F3';
cfg.neighbours(9).neighblabel = {'Fz','C3','AFz','FCz'};
cfg.neighbours(10).label = 'F4';
cfg.neighbours(10).neighblabel = {'Fz','C4','AFz','FCz'};
cfg.neighbours(11).label = 'C3';
cfg.neighbours(11).neighblabel = {'F3','P3','FCz','Cz','CPz'};
cfg.neighbours(12).label = 'C4';
cfg.neighbours(12).neighblabel = {'F4','P4','FCz','Cz','CPz'};
cfg.neighbours(13).label = 'P3';
cfg.neighbours(13).neighblabel = {'C3','CPz','Pz','POz'};
cfg.neighbours(14).label = 'P4';
cfg.neighbours(14).neighblabel = {'C4','CPz','Pz','POz'};

% set time window
if strcmp(metric, 'prestim')
    cfg.avgovertime = 'yes';
elseif ~strcmp(metric, 'pac')
    if strcmp(epoch, 'sound_on')
        cfg.latency = [0 0.5];
    elseif strcmp(epoch, 'sound_off')
        cfg.latency = [0.7 1.2];
    end
end

% run stats
cfg.design = cat(2, ones(1,size(tacs.individual,1)), zeros(1,size(sham.individual,1)));
stat_tacs = ft_timelockstatistics(cfg, tacs, sham);

cfg.design = cat(2, ones(1,size(tdcs.individual,1)), zeros(1,size(sham.individual,1)));
stat_tdcs = ft_timelockstatistics(cfg, tdcs, sham);

% save stats
save(fullfile(savdir, ['stat_tacs_' epoch]), 'stat_tacs');
save(fullfile(savdir, ['stat_tdcs_' epoch]), 'stat_tdcs');

end
