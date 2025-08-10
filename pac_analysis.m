function pac_analysis(session, sid)
% PAC_ANALYSIS - compute phase-amplitude coupling (PAC) between alpha phase
% (10 Hz) and gamma amplitude (40 Hz) using the modulation index,
% z-scored by randomly permuting amplitudes. Split the post-stimulus epoch
% into sound-on and sound-off epochs.
%
% Modulation index analysis described in: Tort et al. Measuring 
% phase-amplitude coupling between neuronal oscillations of different 
% frequencies. Journal of Neurophysiology 104 (2010).
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
% pac_analysis('baseline', 'AB')
%
% Copyright (c) 2019
% EL Johnson, PhD

clearvars -except session sid

% set directories
pth = pwd;
datdir = fullfile(pth, session, sid);
savdir = fullfile(datdir, 'pac');
mkdir(savdir);

% set number of permutations
nperm = 1000;

% load data
load(fullfile(datdir, 'data_clean'), 'data');

% subtract ERP
cfg = [];
cfg.avgoverrpt = 'yes';

erp = ft_selectdata(cfg, data);

for r = 1:length(data.trial)
    data.trial{r} = data.trial{r} - erp.trial{1};
end
clear erp

% set up hilbert-bandpass filter
cfg = [];
cfg.bpfilter = 'yes';
cfg.padding = 10; % same padding as multitaper analyses

% set up step to convert outputs from ft_preprocessing structure to
% ft_timelockanalysis structure
cfgt = [];
cfgt.keeptrials = 'yes';
cfgt.vartrllength = 2;

% extract alpha phase and gamma amplitude
cfg.bpfreq = [8 12]; % 10 Hz canonical alpha
cfg.hilbert = 'angle'; % output phase from complex number

ph = ft_preprocessing(cfg, data);
ph = ft_timelockanalysis(cfgt, ph);

cfg.bpfreq = [40-6 40+6]; % 40 Hz center with upper bounds of alpha range
cfg.hilbert = 'abs'; % output amplitude from complex number

amp = ft_preprocessing(cfg, data);
amp = ft_timelockanalysis(cfgt, amp);

% set up modulation index
nbin = 18; % 0-360 degrees in 18 bins
position = zeros(1,nbin); % beginning of each bin in radians
winsize = 2*pi/nbin;
for j = 1:nbin
    position(j) = -pi+(j-1)*winsize;
end
phase_center = position+winsize/2;

% initialize modulation index structures
mi1 = [];
mi1.dimord = 'chan_time';
mi1.label = data.label;
mi1.phase = phase_center;
mi1.time = 0.25; % midpoint sound on

mi2 = mi1;
mi2.time = 0.95; % midpoint sound off

% loop through 2 time windows
cfg = [];
for t = 1:2
    % initialize matrices
    raw = nan(length(data.label), 1);
    phdist = nan(length(data.label), length(phase_center));
    perm = nan(nperm, length(data.label));

    if t == 1
        cfg.latency = [0 0.5]; % sound on
    elseif t == 2
        cfg.latency = [0.7 1.2]; % sound off
    end
    
    tmp_ph = ft_selectdata(cfg, ph); % cut to epoch
    tmp_amp = ft_selectdata(cfg, amp);
    
    tmp_ph = tmp_ph.trial; % actual data
    tmp_amp = tmp_amp.trial;
    
    % loop through channels
    for e = 1:length(data.label)
        x_tmp_ph = squeeze(tmp_ph(:,e,:)); % select channel
        x_tmp_amp = squeeze(tmp_amp(:,e,:));
        
        x_tmp_ph = x_tmp_ph(:); % pool data
        xx_tmp_amp = x_tmp_amp(:);
        
        % compute the mean amplitude in each phase bin
        MeanAmp = zeros(1,nbin);
        for j = 1:nbin
            I = x_tmp_ph < position(j)+winsize & x_tmp_ph >= position(j);
            MeanAmp(j) = mean(xx_tmp_amp(I));
        end
        clear xx*
            
        phdist(e,:) = MeanAmp; % raw histogram
            
        % quantify amplitude modulation using normalized entropy index
        raw(e) = (log(nbin) - (-sum((MeanAmp/sum(MeanAmp)) .* ...
            log((MeanAmp/sum(MeanAmp)))))) / log(nbin);
        clear MeanAmp
            
        % run permutations
        for z = 1:nperm
            r = randperm(size(data.trialinfo, 1));
            xx_tmp_amp = squeeze(x_tmp_amp(r,:));
            xx_tmp_amp = xx_tmp_amp(:);
            
            % compute the mean amplitude in each phase bin
            MeanAmp = zeros(1,nbin);
            for j = 1:nbin
                I = x_tmp_ph < position(j)+winsize & x_tmp_ph >= position(j);
                MeanAmp(j) = mean(xx_tmp_amp(I)); % permuted amplitudes
            end
            
            % quantify amplitude modulation using normalized entropy index
            perm(z,e) = (log(nbin) - (-sum((MeanAmp/sum(MeanAmp)) .* ...
                log((MeanAmp/sum(MeanAmp)))))) / log(nbin);
            clear MeanAmp xx* r
        end
        
        clear x*
    end
    clear tmp*
    
    % populate structures
    if t == 1
        mi1.raw = raw;
        mi1.phdist = phdist;
        mi1.perm = perm;
    elseif t == 2
        mi2.raw = raw;
        mi2.phdist = phdist;
        mi2.perm = perm;
    end
    clear raw phdist perm
    
end
clear data ph amp

% compute z-scores
mi1.z = (mi1.raw - nanmean(mi1.perm)') ./ nanstd(mi1.perm)';
mi2.z = (mi2.raw - nanmean(mi1.perm)') ./ nanstd(mi2.perm)';

% save
data = mi1;
save(fullfile(savdir, 'mi_sound_on'), 'data');
data = mi2;
save(fullfile(savdir, 'mi_sound_off'), 'data');

end
