%% 1. download data

% from: https://drive.google.com/drive/folders/1oHMnHdX7h10AstfWZrPvY3IP1pOW7U-X?usp=drive_link 

%% 2. run subject-level analyses

sessions = {'baseline','sham','tacs','tdcs'};

for x = 1:length(sessions)
    sbj = dir(fullfile(pwd, sessions{x}));
    sbj = sbj(3:end);
    
    % run functions in order
    for s = 1:length(sbj)      
        psd_analysis(sessions{x}, sbj(s).name);

        prestim_analysis(sessions{x}, sbj(s).name);
        power_analysis(sessions{x}, sbj(s).name);
        
        itpc_analysis(sessions{x}, sbj(s).name);

        connect_analysis(sessions{x}, sbj(s).name, 'amplcorr');
        network_analysis(sessions{x}, sbj(s).name, 'amplcorr');
        connect_analysis(sessions{x}, sbj(s).name, 'plv');
        network_analysis(sessions{x}, sbj(s).name, 'plv');
        
        pac_analysis(sessions{x}, sbj(s).name);
    end
end

%% 3. run group-level statistics

cluster_int('prestim');

cluster_int('power', 'sound_on');
cluster_int('power', 'sound_off');

cluster_int('itpc', 'sound_on');
cluster_int('itpc', 'sound_off');

cluster_int('amplcorr', 'sound_on');
cluster_int('amplcorr', 'sound_off');

cluster_int('plv', 'sound_on');
cluster_int('plv', 'sound_off');

cluster_int('pac', 'sound_on');
cluster_int('pac', 'sound_off');
        